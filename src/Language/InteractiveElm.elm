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


{-| Partially active expressions:

Has a boolean attached to indicate whether an expression is
supposed to be 'enabled' or 'disabled'.

The meaning of that is dependent on what constructor it is.

-}
type PartialExpression
    = PartialExpression Bool (ExpressionF PartialExpression)


type ExpressionF a
    = Superimposed String String a String
    | ListOf String (List (ListElement a)) String
    | Moved String String Int String Int String a String
    | Filled String String Common.Color String a String
    | Outlined String String Common.Color String a String
    | Circle String String Int String
    | Rectangle String String Int String Int String
    | EmptyStencil String String
    | EmptyPicture String String


type alias ExpressionList a =
    { elements : List (ListElement a)
    , tail : String
    }


type alias ListElement a =
    { prefix : String
    , expression : a

    -- TODO: This cannot be extracted out - yet
    -- (at least I have no idea how to fit this to recursion
    -- schemes nicely for now)
    , active : Bool
    }


enableAll : Expression -> PartialExpression
enableAll =
    cata (PartialExpression True)



-- RECURSION SCHEME STUFF


mapE : (a -> b) -> ExpressionF a -> ExpressionF b
mapE f constructor =
    case constructor of
        Superimposed t0 t1 e t3 ->
            Superimposed t0 t1 (f e) t3

        ListOf t0 expressionList t1 ->
            ListOf t0 (mapExpressionList f expressionList) t1

        Moved t0 t1 x t2 y t3 e t4 ->
            Moved t0 t1 x t2 y t3 (f e) t4

        Filled t0 t1 col t2 shape t3 ->
            Filled t0 t1 col t2 (f shape) t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined t0 t1 col t2 (f shape) t3

        Circle t0 t1 r t2 ->
            Circle t0 t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle t0 t1 w t2 h t3

        EmptyStencil t0 t1 ->
            EmptyStencil t0 t1

        EmptyPicture t0 t1 ->
            EmptyPicture t0 t1


indexedMap : (Int -> a -> b) -> ExpressionF a -> ExpressionF b
indexedMap f constructor =
    case constructor of
        Superimposed t0 t1 e t3 ->
            Superimposed t0 t1 (f 0 e) t3

        ListOf t0 expressionList t1 ->
            ListOf t0 (indexedMapExpressionList f expressionList) t1

        Moved t0 t1 x t2 y t3 e t4 ->
            Moved t0 t1 x t2 y t3 (f 0 e) t4

        Filled t0 t1 col t2 shape t3 ->
            Filled t0 t1 col t2 (f 0 shape) t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined t0 t1 col t2 (f 0 shape) t3

        Circle t0 t1 r t2 ->
            Circle t0 t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle t0 t1 w t2 h t3

        EmptyStencil t0 t1 ->
            EmptyStencil t0 t1

        EmptyPicture t0 t1 ->
            EmptyPicture t0 t1


mapExpressionList : (a -> b) -> List (ListElement a) -> List (ListElement b)
mapExpressionList f elements =
    List.map
        (\{ prefix, expression, active } ->
            { prefix = prefix
            , expression = f expression
            , active = active
            }
        )
        elements


indexedMapExpressionList : (Int -> a -> b) -> List (ListElement a) -> List (ListElement b)
indexedMapExpressionList f elements =
    List.indexedMap
        (\index { prefix, expression, active } ->
            { prefix = prefix
            , expression = f index expression
            , active = active
            }
        )
        elements


expressionListToList : List (ListElement a) -> List a
expressionListToList elements =
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


cataPartial : (Bool -> ExpressionF a -> a) -> PartialExpression -> a
cataPartial algebra (PartialExpression active constructor) =
    constructor
        |> mapE (cataPartial algebra)
        |> algebra active


indexedCataPartial : (List Int -> Bool -> ExpressionF a -> a) -> List Int -> PartialExpression -> a
indexedCataPartial algebra pathSoFar (PartialExpression active constructor) =
    constructor
        |> indexedMap (\index -> indexedCataPartial algebra (index :: pathSoFar))
        |> algebra pathSoFar active


activeOnly : (ExpressionF a -> a) -> Bool -> ExpressionF a -> a
activeOnly algebra active constructor =
    if active then
        algebra constructor

    else
        case constructor of
            Superimposed t0 _ _ t1 ->
                algebra (EmptyPicture t0 t1)

            -- should we filter list elements out here?
            -- we don't right now
            ListOf t0 _ t1 ->
                algebra (ListOf t0 [] t1)

            Moved _ _ _ _ _ _ e _ ->
                e

            Filled _ _ _ _ e _ ->
                e

            Outlined _ _ _ _ e _ ->
                e

            Circle t0 _ _ t1 ->
                algebra (EmptyStencil t0 t1)

            Rectangle t0 _ _ _ _ t1 ->
                algebra (EmptyStencil t0 t1)

            -- we cannot disable these two any further
            EmptyStencil _ _ ->
                algebra constructor

            EmptyPicture _ _ ->
                algebra constructor



--


prefixExpressionWith : String -> ExpressionF a -> ExpressionF a
prefixExpressionWith str expression =
    case expression of
        Superimposed t0 t1 e t3 ->
            Superimposed (str ++ t0) t1 e t3

        ListOf t0 expressionList t1 ->
            ListOf (str ++ t0) expressionList t1

        Moved t0 t1 x t2 y t3 e t4 ->
            Moved (str ++ t0) t1 x t2 y t3 e t4

        Filled t0 t1 col t2 shape t3 ->
            Filled (str ++ t0) t1 col t2 shape t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined (str ++ t0) t1 col t2 shape t3

        Circle t0 t1 r t2 ->
            Circle (str ++ t0) t1 r t2

        Rectangle t0 t1 w t2 h t3 ->
            Rectangle (str ++ t0) t1 w t2 h t3

        EmptyStencil t0 t1 ->
            EmptyStencil (str ++ t0) t1

        EmptyPicture t0 t1 ->
            EmptyPicture (str ++ t0) t1



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
                    |. token (Token "superimposed" "Expected 'superimposed' expression")
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'superimposed' expression"
                , parseListOf
                    |> inContext "a list literal"
                , succeed (Moved "")
                    |. token (Token "moved" "Expected 'moved' expression")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'moved' expression"
                , succeed (Filled "")
                    |. token (Token "filled" "Expected 'filled' expression")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'filled' expression"
                , succeed (Outlined "")
                    |. token (Token "outlined" "Expected 'outlined' expression")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseExpression []
                    |> handleParens parens
                    |> inContext "a 'outlined' expression"
                , succeed (Circle "")
                    |. token (Token "circle" "Expected 'circle' expression")
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'circle' expression"
                , succeed (Rectangle "")
                    |. token (Token "rectangle" "Expected 'rectangle' expression")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |> handleParens parens
                    |> inContext "a 'rectangle' expression"
                , succeed (EmptyStencil "")
                    |. token (Token "emptyStencil" "Expected 'emptyStencil' expression")
                    |> handleParens parens
                    |> inContext "an 'emptyStencil' expression"
                , succeed (EmptyPicture "")
                    |. token (Token "emptyPicture" "Expected 'emptyPicture' expression")
                    |> handleParens parens
                    |> inContext "an 'emptyPicture' expression"
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


parseListOf : Common.Parser Expression
parseListOf =
    loop { revElements = [], index = 1 } parseElementsHelp
        |> inContext "a list"


type alias ListState =
    { revElements : List (ListElement Expression)
    , index : Int
    }


parseElementsHelp : ListState -> Common.Parser (Step ListState Expression)
parseElementsHelp { revElements, index } =
    oneOf
        [ backtrackable
            (parseElement index
                |> map
                    (\elem ->
                        { revElements = elem :: revElements
                        , index = index + 1
                        }
                            |> Loop
                    )
            )
        , tokenAndWhitespace "]"
            |> map
                (\tail ->
                    ListOf
                        ""
                        (List.reverse revElements)
                        tail
                        |> Expression
                        |> Done
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
