module Language.Common exposing (..)

import Color
import List.Extra as List
import Parser.Advanced exposing (..)


type Color
    = Red
    | Green
    | Blue
    | Purple
    | Yellow
    | Aqua
    | Orange


nextColor : Color -> Color
nextColor color =
    case color of
        Red ->
            Green

        Green ->
            Blue

        Blue ->
            Purple

        Purple ->
            Yellow

        Yellow ->
            Aqua

        Aqua ->
            Orange

        Orange ->
            Red


colorToRGB : Color -> Color.Color
colorToRGB color =
    case color of
        Red ->
            Color.rgb255 251 73 52

        Green ->
            Color.rgb255 184 187 38

        Blue ->
            Color.rgb255 131 165 152

        Purple ->
            Color.rgb255 211 134 155

        Yellow ->
            Color.rgb255 250 189 47

        Aqua ->
            Color.rgb255 142 192 124

        Orange ->
            Color.rgb255 254 128 25


colorName : Color -> String
colorName color =
    case color of
        Red ->
            "red"

        Green ->
            "green"

        Blue ->
            "blue"

        Purple ->
            "purple"

        Yellow ->
            "yellow"

        Aqua ->
            "aqua"

        Orange ->
            "orange"



-- PARSE


type alias Parser a =
    Parser.Advanced.Parser String String a


parseColor : Parser Color
parseColor =
    succeed identity
        |. symbol (Token "\"" "Expecting start of string")
        |= oneOf
            [ succeed Red
                |. backtrackable (token (Token "red" "Expected valid color name"))
            , succeed Green
                |. backtrackable (token (Token "green" "Expected valid color name"))
            , succeed Blue
                |. backtrackable (token (Token "blue" "Expected valid color name"))
            , succeed Purple
                |. backtrackable (token (Token "purple" "Expected valid color name"))
            , succeed Yellow
                |. backtrackable (token (Token "yellow" "Expected valid color name"))
            , succeed Aqua
                |. backtrackable (token (Token "aqua" "Expected valid color name"))
            , succeed Orange
                |. backtrackable (token (Token "orange" "Expected valid color name"))
            ]
        |. symbol (Token "\"" "Expecting end of string")


parseInt : Parser Int
parseInt =
    int "Expected integer" "Invalid number"


explainErrors : String -> List (DeadEnd String String) -> String
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
                        (List.repeat (lineLength + 1) " ")
                        errors
                        |> String.concat
                        |> String.append "    "
                    ]

        showLineWithErrors index line =
            ("    " ++ line) :: showErrorsInLine (index + 1) (String.length line)

        listError { row, col, problem, contextStack } =
            String.concat
                [ "  * "
                , "("
                , String.fromInt row
                , ":"
                , String.fromInt col
                , ") "
                , problem
                , " in "
                , String.join ", in " (List.map .context contextStack)
                ]
    in
    String.join "\n" <|
        "Failed parsing this 'elm interactive' code:"
            :: ""
            :: (List.concat (List.indexedMap showLineWithErrors sourceLines)
                    ++ List.map listError deadEnds
               )
