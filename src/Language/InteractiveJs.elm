module Language.InteractiveJs exposing (..)

import Language.Common as Common
import List.Extra as List
import Parser.Advanced exposing (..)
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
        |> run (parseStatements |. end "Expected end of input")
        |> Result.mapError (Common.explainErrors str)


parseStatement : Common.Parser Statement
parseStatement =
    oneOf
        [ succeed Stroke
            |. backtrackable (token (Token "stroke" "Expected valid function name"))
            |. symbol (Token "()" "Expected parenthesis")
        , succeed Fill
            |. backtrackable (token (Token "fill" "Expected valid function name"))
            |. symbol (Token "()" "Expected parenthesis")
        , succeed MoveTo
            |. backtrackable (token (Token "moveTo" "Expected valid function name"))
            |. symbol (Token "(" "Expected start of function, an opening parenthesis")
            |= Common.parseInt
            |. symbol (Token ", " "Expected comma and another argument")
            |= Common.parseInt
            |. symbol (Token ")" "Expected end of arguments, a closing parenthesis")
        , succeed SetColor
            |. backtrackable (token (Token "setColor" "Expected valid function name"))
            |. symbol (Token "(" "Expected start of function, an opening parenthesis")
            |= Common.parseColor
            |. symbol (Token ")" "Expected end of arguments, a closing parenthesis")
        , succeed Circle
            |. backtrackable (token (Token "circle" "Expected valid function name"))
            |. symbol (Token "(" "Expected start of function, an opening parenthesis")
            |= Common.parseInt
            |. symbol (Token ")" "Expected end of arguments, a closing parenthesis")
        , succeed Rectangle
            |. backtrackable (token (Token "rectangle" "Expected valid function name"))
            |. symbol (Token "(" "Expected start of function, an opening parenthesis")
            |= Common.parseInt
            |. symbol (Token ", " "Expected comma and another argument")
            |= Common.parseInt
            |. symbol (Token ")" "Expected end of arguments, a closing parenthesis")
        ]


parseStatements : Common.Parser (List Statement)
parseStatements =
    loop [] parseStatementsHelp


parseStatementsHelp : List Statement -> Common.Parser (Step (List Statement) (List Statement))
parseStatementsHelp reverseStatements =
    oneOf
        [ succeed (\stmt -> Loop (stmt :: reverseStatements))
            |= parseStatement
            |. spaces
            |. symbol (Token ";" "Expected end of statement with a semicolon")
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse reverseStatements))
        ]
