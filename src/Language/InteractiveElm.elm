module Language.InteractiveElm exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser exposing (..)
import Result.Extra as Result


languageId =
    "elm interactive"


type Expression
    = Superimposed String ExpressionList String
    | Moved String Int String Int String Expression String
    | Filled String Common.Color String Shape String
    | Outlined String Common.Color String Shape String


type alias ExpressionList =
    { elements : List { prefix : String, expression : Expression }
    , tail : String
    }


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
        |> run parseExpression
        |> Result.mapError (Common.explainErrors str)


parseExpression : Parser Expression
parseExpression =
    oneOf
        [ succeed Superimposed
            |= tokenAndWhitespace "superimposed"
            |= succeed { elements = [], tail = "[]" }
            |= succeed ""
        ]


tokenAndWhitespace : String -> Parser String
tokenAndWhitespace shouldStartWith =
    succeed (\ws -> shouldStartWith ++ ws)
        |. token shouldStartWith
        |= spacesAndNewlines


spacesAndNewlines : Parser String
spacesAndNewlines =
    chompWhile (\c -> c == ' ' || c == '\n')
        |> getChompedString
