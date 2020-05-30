module Language.Common exposing (..)

import Color
import List.Extra as List
import Parser exposing (..)


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


parseColor : Parser Color
parseColor =
    succeed identity
        |. symbol "\""
        |= oneOf
            [ succeed Red |. backtrackable (token "red")
            , succeed Green |. backtrackable (token "green")
            , succeed Blue |. backtrackable (token "blue")
            , succeed Purple |. backtrackable (token "purple")
            , succeed Yellow |. backtrackable (token "yellow")
            , succeed Aqua |. backtrackable (token "aqua")
            , succeed Orange |. backtrackable (token "orange")
            ]
        |. symbol "\""


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
        "Failed parsing this 'elm interactive' code:"
            :: ""
            :: List.concat (List.indexedMap showLineWithErrors sourceLines)
