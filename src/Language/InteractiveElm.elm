module Language.InteractiveElm exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser.Advanced exposing (..)
import Result.Extra as Result


languageId =
    "elm interactive"


type Expression
    = Superimposed String ExpressionList String
    | Moved String Int String Int String Expression String
    | Filled String Common.Color String Shape String
    | Outlined String Common.Color String Shape String
    | Unparsed String


type alias ExpressionList =
    { elements : List ListElement
    , tail : String
    }


type alias ListElement =
    { prefix : String, expression : Expression }


type Shape
    = Circle String Int String
    | Rectangle String Int String Int String


example =
    Superimposed "superimposed\n    "
        elemList
        ""


elemList =
    { elements =
        [ { prefix = "[ "
          , expression =
                Moved "moved "
                    200
                    " "
                    100
                    "\n        "
                    (Filled "(filled "
                        Common.Blue
                        " "
                        (Rectangle "(rectangle " 50 " " 30 ")")
                        ")"
                    )
                    ""
          }
        , { prefix = "\n    , "
          , expression =
                Moved "moved "
                    100
                    " "
                    100
                    "\n        "
                    (Outlined "(outlined "
                        Common.Red
                        " "
                        (Circle "(circle " 20 ")")
                        ")"
                    )
                    ""
          }
        ]
    , tail = "\n    ]"
    }



-- PARSING


parse : String -> Result String Expression
parse str =
    str
        |> run (parseExpression |. end "Expecting end of input")
        |> Result.mapError (Common.explainErrors str)


parseExpression : Common.Parser Expression
parseExpression =
    oneOf
        [ succeed Superimposed
            |= tokenAndWhitespace "superimposed"
            |= parseExpressionList
            |= whitespace
        ]


parseExpressionList : Common.Parser ExpressionList
parseExpressionList =
    loop [] parseElementsHelp


parseElementsHelp : List ListElement -> Common.Parser (Step (List ListElement) ExpressionList)
parseElementsHelp revElements =
    oneOf
        [ parseElement
            |> map (\elem -> Loop (elem :: revElements))
        , tokenAndWhitespace "]"
            |> map
                (\tail ->
                    Done
                        { elements = List.reverse revElements
                        , tail = tail
                        }
                )
        ]


parseElement : Common.Parser ListElement
parseElement =
    succeed ListElement
        |= oneOf
            [ tokenAndWhitespace "["
            , tokenAndWhitespace ","
            ]
        |= mapChompedString
            (\str _ -> Unparsed str)
            (chompWhile (\c -> c /= ',' || c /= ']'))


tokenAndWhitespace : String -> Common.Parser String
tokenAndWhitespace shouldStartWith =
    succeed (\ws -> shouldStartWith ++ ws)
        |. token (Token shouldStartWith ("Expected " ++ shouldStartWith))
        |= whitespace


whitespaceAndToken : String -> Common.Parser String
whitespaceAndToken shouldEndWith =
    succeed (\ws -> ws ++ shouldEndWith)
        |= whitespace
        |. token (Token shouldEndWith ("Expected whitespace ending with " ++ shouldEndWith))


whitespace : Common.Parser String
whitespace =
    chompWhile (\c -> c == ' ' || c == '\n')
        |> getChompedString
