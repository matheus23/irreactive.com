module Language.InteractiveElm exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser exposing (..)
import Result.Extra as Result


languageId =
    "elm interactive"


type Expression
    = Superimposed (List Expression)
    | Moved Int Int Expression
    | Filled Common.Color Shape
    | Outlined Common.Color Shape


type Shape
    = Circle Int
    | Rectangle Int Int


example =
    Superimposed
        [ Moved 200 100 (Filled Common.Blue (Rectangle 50 30))
        , Moved 100 100 (Outlined Common.Red (Circle 20))
        ]



-- PARSING


parse : String -> Result String Expression
parse str =
    Ok (Superimposed [])


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
