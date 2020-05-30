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
        ""



-- PARSING


parse : String -> Result String Expression
parse str =
    Ok example


explainErrors : String -> List DeadEnd -> String
explainErrors sourceCode deadEnds =
    let
        sourceLines =
            String.split "\n" sourceCode

        showErrorsInLine lineNum lineLength =
            case List.filter (\{ row } -> row == lineNum) deadEnds of
                [] ->
                    []

                errors ->
                    [ List.foldl
                        (\{ col } errorLine ->
                            List.setAt (col - 1) "^" errorLine
                        )
                        (List.repeat lineLength " ")
                        errors
                        |> String.concat
                        |> String.append "    "
                    ]

        showLineWithErrors index line =
            ("    " ++ line) :: showErrorsInLine (index + 1) (String.length line)
    in
    String.join "\n" <|
        "I had a problem understanding this 'elm interactive' code:"
            :: ""
            :: List.concat (List.indexedMap showLineWithErrors sourceLines)
