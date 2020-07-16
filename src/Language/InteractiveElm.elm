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
    = Superimposed Bool String String (ExpressionList a) String
    | Moved Bool String String Int String Int String a String
    | Filled Bool String String Common.Color String a String
    | Outlined Bool String String Common.Color String a String
    | Circle Bool String String Int String
    | Rectangle Bool String String Int String Int String


type alias ExpressionList a =
    { elements : List (ListElement a)
    , tail : String
    }


type alias ListElement a =
    { prefix : String
    , expression : a
    , active : Bool
    }



-- RECURSION SCHEME STUFF


mapE : (a -> b) -> ExpressionF a -> ExpressionF b
mapE f constructor =
    case constructor of
        Superimposed a t0 t1 expressionList t3 ->
            Superimposed a t0 t1 (mapExpressionList f expressionList) t3

        Moved a t0 t1 x t2 y t3 e t4 ->
            Moved a t0 t1 x t2 y t3 (f e) t4

        Filled a t0 t1 col t2 shape t3 ->
            Filled a t0 t1 col t2 (f shape) t3

        Outlined a t0 t1 col t2 shape t3 ->
            Outlined a t0 t1 col t2 (f shape) t3

        Circle a t0 t1 r t2 ->
            Circle a t0 t1 r t2

        Rectangle a t0 t1 w t2 h t3 ->
            Rectangle a t0 t1 w t2 h t3


indexedMap : (Int -> a -> b) -> ExpressionF a -> ExpressionF b
indexedMap f constructor =
    case constructor of
        Superimposed a t0 t1 expressionList t3 ->
            Superimposed a t0 t1 (indexedMapExpressionList f expressionList) t3

        Moved a t0 t1 x t2 y t3 e t4 ->
            Moved a t0 t1 x t2 y t3 (f 0 e) t4

        Filled a t0 t1 col t2 shape t3 ->
            Filled a t0 t1 col t2 (f 0 shape) t3

        Outlined a t0 t1 col t2 shape t3 ->
            Outlined a t0 t1 col t2 (f 0 shape) t3

        Circle a t0 t1 r t2 ->
            Circle a t0 t1 r t2

        Rectangle a t0 t1 w t2 h t3 ->
            Rectangle a t0 t1 w t2 h t3


mapExpressionList : (a -> b) -> ExpressionList a -> ExpressionList b
mapExpressionList f { elements, tail } =
    { elements =
        List.map
            (\{ prefix, expression, active } ->
                { prefix = prefix
                , expression = f expression
                , active = active
                }
            )
            elements
    , tail = tail
    }


indexedMapExpressionList : (Int -> a -> b) -> ExpressionList a -> ExpressionList b
indexedMapExpressionList f { elements, tail } =
    { elements =
        List.indexedMap
            (\index { prefix, expression, active } ->
                { prefix = prefix
                , expression = f index expression
                , active = active
                }
            )
            elements
    , tail = tail
    }


expressionListToList : ExpressionList a -> List a
expressionListToList { elements } =
    List.concatMap
        (\{ expression, active } ->
            if active then
                [ expression ]

            else
                []
        )
        elements


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
        Superimposed a t0 t1 expressionList t3 ->
            Superimposed a (str ++ t0) t1 expressionList t3

        Moved a t0 t1 x t2 y t3 e t4 ->
            Moved a (str ++ t0) t1 x t2 y t3 e t4

        Filled a t0 t1 col t2 shape t3 ->
            Filled a (str ++ t0) t1 col t2 shape t3

        Outlined a t0 t1 col t2 shape t3 ->
            Outlined a (str ++ t0) t1 col t2 shape t3

        Circle a t0 t1 r t2 ->
            Circle a (str ++ t0) t1 r t2

        Rectangle a t0 t1 w t2 h t3 ->
            Rectangle a (str ++ t0) t1 w t2 h t3


mapActive : (Bool -> Bool) -> ExpressionF a -> ExpressionF a
mapActive f constructor =
    case constructor of
        Superimposed active t0 t1 expressionList t3 ->
            Superimposed (f active) t0 t1 expressionList t3

        Moved active t0 t1 x t2 y t3 e t4 ->
            Moved (f active) t0 t1 x t2 y t3 e t4

        Filled active t0 t1 col t2 shape t3 ->
            Filled (f active) t0 t1 col t2 shape t3

        Outlined active t0 t1 col t2 shape t3 ->
            Outlined (f active) t0 t1 col t2 shape t3

        Circle active t0 t1 r t2 ->
            Circle (f active) t0 t1 r t2

        Rectangle active t0 t1 w t2 h t3 ->
            Rectangle (f active) t0 t1 w t2 h t3



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
                [ succeed (Superimposed True "")
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
                , succeed (Filled True "")
                    |. token (Token "filled" "Expected 'filled' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'filled' function call"
                , succeed (Outlined True "")
                    |. token (Token "outlined" "Expected 'outlined' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'outlined' function call"
                , succeed (Circle True "")
                    |. token (Token "circle" "Expected 'circle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'circle' function call"
                , succeed (Rectangle True "")
                    |. token (Token "rectangle" "Expected 'rectangle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'rectangle' function call"
                , tokenAndWhitespace "("
                    |> andThen (\par -> parseExpression (par :: parens))
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
        |= succeed True
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
