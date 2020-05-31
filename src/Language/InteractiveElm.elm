module Language.InteractiveElm exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser.Advanced exposing (..)
import Result.Extra as Result


languageId =
    "elm interactive"


type Expression
    = Superimposed String String ExpressionList String
    | Moved String String Int String Int String Expression String
    | Filled String String Common.Color String Shape String
    | Outlined String String Common.Color String Shape String


type alias ExpressionList =
    { elements : List ListElement
    , tail : String
    }


type alias ListElement =
    { prefix : String, expression : Expression }


type Shape
    = Circle String String Int String
    | Rectangle String String Int String Int String


example =
    Superimposed ""
        "\n    "
        elemList
        ""


elemList =
    { elements =
        [ { prefix = "[ "
          , expression =
                Moved ""
                    " "
                    200
                    " "
                    100
                    "\n        "
                    (Filled "("
                        " "
                        Common.Blue
                        " "
                        (Rectangle "(" " " 50 " " 30 ")")
                        ")"
                    )
                    ""
          }
        , { prefix = "\n    , "
          , expression =
                Moved ""
                    " "
                    100
                    " "
                    100
                    "\n        "
                    (Outlined "("
                        " "
                        Common.Red
                        " "
                        (Circle "(" " " 20 ")")
                        ")"
                    )
                    ""
          }
        ]
    , tail = "\n    ]"
    }


prefixExpressionWith : String -> Expression -> Expression
prefixExpressionWith str expression =
    case expression of
        Superimposed t0 t1 expressionList t3 ->
            Superimposed (str ++ t0) t1 expressionList t3

        Moved t0 t1 x t2 y t3 e t4 ->
            Moved (str ++ t0) t1 x t2 y t3 e t4

        Filled t0 t1 col t2 shape t3 ->
            Filled (str ++ t0) t1 col t2 shape t3

        Outlined t0 t1 col t2 shape t3 ->
            Outlined (str ++ t0) t1 col t2 shape t3


prefixShapeWith : String -> Shape -> Shape
prefixShapeWith str shape =
    case shape of
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
                    |> handleExpressionParens parens
                    |> inContext "a 'superimposed' function call"
                , succeed (Moved "")
                    |. token (Token "moved" "Expected 'moved' function call")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= parseExpression parens
                    |> handleExpressionParens parens
                    |> inContext "a 'moved' function call"
                , succeed (Filled "")
                    |. token (Token "filled" "Expected 'filled' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseShape []
                    |> handleExpressionParens parens
                    |> inContext "a 'filled' function call"
                , succeed (Outlined "")
                    |. token (Token "outlined" "Expected 'outlined' function call")
                    |= whitespace
                    |= Common.parseColor
                    |= whitespace
                    |= parseShape []
                    |> handleExpressionParens parens
                    |> inContext "a 'outlined' function call"
                , tokenAndWhitespace "("
                    |> andThen (\paren -> parseExpression (paren :: parens))
                ]


parseShape : ParenStack -> Common.Parser Shape
parseShape parens =
    lazy <|
        \_ ->
            oneOf
                [ succeed (Circle "")
                    |. token (Token "circle" "Expected 'circle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |> handleShapeParens parens
                    |> inContext "a 'circle' function call"
                , succeed (Rectangle "")
                    |. token (Token "rectangle" "Expected 'rectangle' function call")
                    |= whitespace
                    |= Common.parseInt
                    |= whitespace
                    |= Common.parseInt
                    |> handleShapeParens parens
                    |> inContext "a 'rectangle' function call"
                , tokenAndWhitespace "("
                    |> andThen (\paren -> parseShape (paren :: parens))
                ]


handleExpressionParens : ParenStack -> Common.Parser (String -> Expression) -> Common.Parser Expression
handleExpressionParens parens parser =
    parser
        |= parseCloseParens parens
        |> map
            (\expression ->
                prefixExpressionWith (String.concat (List.reverse parens)) expression
            )


handleShapeParens : ParenStack -> Common.Parser (String -> Shape) -> Common.Parser Shape
handleShapeParens parens parser =
    parser
        |= parseCloseParens parens
        |> map
            (\shape ->
                prefixShapeWith (String.concat (List.reverse parens)) shape
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


parseExpressionList : Common.Parser ExpressionList
parseExpressionList =
    loop { revElements = [], index = 1 } parseElementsHelp
        |> inContext "a list"


type alias ListState =
    { revElements : List ListElement
    , index : Int
    }


parseElementsHelp : ListState -> Common.Parser (Step ListState ExpressionList)
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


parseElement : Int -> Common.Parser ListElement
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
