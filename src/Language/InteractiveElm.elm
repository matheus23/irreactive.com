module Language.InteractiveElm exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser.Advanced exposing (..)
import Result.Extra as Result


languageId =
    "elm interactive"



-- CONCRETE SYNTAX TREE


type Expression
    = Expression (ExpressionF Expression)


type ExpressionF a
    = Superimposed String String (ExpressionList a) String
    | Moved Bool String String Int String Int String a String
    | Filled String String Common.Color String a String
    | Outlined String String Common.Color String a String
    | Circle String String Int String
    | Rectangle String String Int String Int String


type alias ExpressionList a =
    { elements : List (ListElement a)
    , tail : String
    }


type alias ListElement a =
    { prefix : String, expression : a }



-- RECURSION SCHEME STUFF


mapE : (a -> b) -> ExpressionF a -> ExpressionF b
mapE f constructor =
    case constructor of
        Superimposed t0 t1 expressionList t3 ->
            Superimposed t0 t1 (mapExpressionList f expressionList) t3

        Moved b t0 t1 x t2 y t3 e t4 ->
            Moved b t0 t1 x t2 y t3 (f e) t4

        Filled t0 t1 col t2 shape t3 ->
            Filled t0 t1 col t2 (f shape) t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined t0 t1 col t2 (f shape) t3

        Circle t0 t1 r t2 ->
            Circle t0 t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle t0 t1 w t2 h t3


indexedMap : (Int -> a -> b) -> ExpressionF a -> ExpressionF b
indexedMap f constructor =
    case constructor of
        Superimposed t0 t1 expressionList t3 ->
            Superimposed t0 t1 (indexedMapExpressionList f expressionList) t3

        Moved b t0 t1 x t2 y t3 e t4 ->
            Moved b t0 t1 x t2 y t3 (f 0 e) t4

        Filled t0 t1 col t2 shape t3 ->
            Filled t0 t1 col t2 (f 0 shape) t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined t0 t1 col t2 (f 0 shape) t3

        Circle t0 t1 r t2 ->
            Circle t0 t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle t0 t1 w t2 h t3


mapExpressionList : (a -> b) -> ExpressionList a -> ExpressionList b
mapExpressionList f { elements, tail } =
    { elements =
        List.map
            (\{ prefix, expression } ->
                { prefix = prefix
                , expression = f expression
                }
            )
            elements
    , tail = tail
    }


indexedMapExpressionList : (Int -> a -> b) -> ExpressionList a -> ExpressionList b
indexedMapExpressionList f { elements, tail } =
    { elements =
        List.indexedMap
            (\index { prefix, expression } ->
                { prefix = prefix
                , expression = f index expression
                }
            )
            elements
    , tail = tail
    }


cata : (ExpressionF a -> a) -> Expression -> a
cata algebra (Expression expression) =
    expression
        |> mapE (cata algebra)
        |> algebra


indexedCata : (List Int -> ExpressionF a -> a) -> List Int -> Expression -> a
indexedCata algebra pathSoFar (Expression expression) =
    expression
        |> indexedMap (\index -> indexedCata algebra (index :: pathSoFar))
        |> algebra pathSoFar



--


prefixExpressionWith : String -> ExpressionF a -> ExpressionF a
prefixExpressionWith str expression =
    case expression of
        Superimposed t0 t1 expressionList t3 ->
            Superimposed (str ++ t0) t1 expressionList t3

        Moved b t0 t1 x t2 y t3 e t4 ->
            Moved b (str ++ t0) t1 x t2 y t3 e t4

        Filled t0 t1 col t2 shape t3 ->
            Filled (str ++ t0) t1 col t2 shape t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined (str ++ t0) t1 col t2 shape t3

        Circle t0 t1 r t2 ->
            Circle (str ++ t0) t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle (str ++ t0) t1 w t2 h t3



-- PARSING


parse : String -> Result String Expression
parse str =
    str
        |> run (parseExpression [] |. end "Expecting end of input")
        |> Result.mapError (Common.explainErrors str)


type alias ParenStack =
    List String


parseExpression : ParenStack -> Common.Parser Expression
parseExpression parens =
    lazy <|
        \_ ->
            oneOf
                [ succeed (Superimposed "")
                    |. token (Token "superimposed" "Expected 'superimposed' function call")
                    |= whitespace
                    |= parseExpressionList
                    |> handleParens parens
                    |> inContext "a 'superimposed' function call"
                , succeed (Moved True "")
                    |. token (Token "moved" "Expected 'moved' function call")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'moved' function call"
                , succeed (Filled "")
                    |. token (Token "filled" "Expected 'filled' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'filled' function call"
                , succeed (Outlined "")
                    |. token (Token "outlined" "Expected 'outlined' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'outlined' function call"
                , succeed (Circle "")
                    |. token (Token "circle" "Expected 'circle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'circle' function call"
                , succeed (Rectangle "")
                    |. token (Token "rectangle" "Expected 'rectangle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'rectangle' function call"
                , tokenAndWhitespace "("
                    |> andThen (\paren -> parseExpression (paren :: parens))
                ]


handleParens : ParenStack -> Common.Parser (String -> ExpressionF Expression) -> Common.Parser Expression
handleParens parens parser =
    parser
        |= parseCloseParens parens
        |> map
            (\expression ->
                prefixExpressionWith (String.concat (List.reverse parens)) expression
                    |> Expression
            )


parseCloseParens : ParenStack -> Common.Parser String
parseCloseParens stack =
    lazy <|
        \_ ->
            case stack of
                [] ->
                    whitespace

                _ :: remaining ->
                    succeed (++)
                        |= whitespaceAndToken ")"
                        |= parseCloseParens remaining


parseExpressionList : Common.Parser (ExpressionList Expression)
parseExpressionList =
    loop { revElements = [], index = 1 } parseElementsHelp
        |> inContext "a list"


type alias ListState =
    { revElements : List (ListElement Expression)
    , index : Int
    }


parseElementsHelp : ListState -> Common.Parser (Step ListState (ExpressionList Expression))
parseElementsHelp { revElements, index } =
    oneOf
        [ backtrackable
            (parseElement index
                |> map
                    (\elem ->
                        Loop
                            { revElements = elem :: revElements
                            , index = index + 1
                            }
                    )
            )
        , tokenAndWhitespace "]"
            |> map
                (\tail ->
                    Done
                        { elements = List.reverse revElements
                        , tail = tail
                        }
                )
        ]


parseElement : Int -> Common.Parser (ListElement Expression)
parseElement index =
    succeed ListElement
        |= (if index == 1 then
                tokenAndWhitespace "["

            else
                tokenAndWhitespace ","
           )
        |= parseExpression []
        |> inContext ("the " ++ String.fromInt index ++ ". list element")


tokenAndWhitespace : String -> Common.Parser String
tokenAndWhitespace shouldStartWith =
    succeed (\ws -> shouldStartWith ++ ws)
        |. token (Token shouldStartWith ("Expected '" ++ shouldStartWith ++ "'"))
        |= whitespace


whitespaceAndToken : String -> Common.Parser String
whitespaceAndToken shouldEndWith =
    succeed (\ws -> ws ++ shouldEndWith)
        |= whitespace
        |. token (Token shouldEndWith ("Expected whitespace ending with '" ++ shouldEndWith ++ "'"))


whitespace : Common.Parser String
whitespace =
    chompWhile (\c -> c == ' ' || c == '\n')
        |> getChompedString
