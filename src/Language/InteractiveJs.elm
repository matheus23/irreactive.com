module Language.InteractiveJs exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser exposing (..)
import Result.Extra as Result


languageId =
    "js interactive"


type Statement
    = Stroke
    | Fill
    | MoveTo Int Int
    | SetColor Common.Color
    | Circle Int
    | Rectangle Int Int



-- PARSING


parse : String -> Result String (List Statement)
parse str =
    str
        |> run (parseStatements |. end)
        |> Result.mapError (explainErrors str)


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
        "I had a problem understanding this 'js interactive' code:"
            :: ""
            :: List.concat (List.indexedMap showLineWithErrors sourceLines)


parseStatement : Parser Statement
parseStatement =
    oneOf
        [ succeed Stroke
            |. backtrackable (token "stroke")
            |. symbol "()"
        , succeed Fill
            |. backtrackable (token "fill")
            |. symbol "()"
        , succeed MoveTo
            |. backtrackable (token "moveTo")
            |. symbol "("
            |= int
            |. symbol ", "
            |= int
            |. symbol ")"
        , succeed SetColor
            |. backtrackable (token "setColor")
            |. symbol "("
            |= Common.parseColor
            |. symbol ")"
        , succeed Circle
            |. backtrackable (token "circle")
            |. symbol "("
            |= int
            |. symbol ")"
        , succeed Rectangle
            |. backtrackable (token "rectangle")
            |. symbol "("
            |= int
            |. symbol ", "
            |= int
            |. symbol ")"
        ]


parseStatements : Parser (List Statement)
parseStatements =
    loop [] parseStatementsHelp


parseStatementsHelp : List Statement -> Parser (Step (List Statement) (List Statement))
parseStatementsHelp reverseStatements =
    oneOf
        [ succeed (\stmt -> Loop (stmt :: reverseStatements))
            |= parseStatement
            |. spaces
            |. symbol ";"
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse reverseStatements))
        ]
