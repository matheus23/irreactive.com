module Language.Block exposing (..)

{-| Adapted from [elm-format's Box.hs].

[elm-format's Box.hs]: https://github.com/avh4/elm-format/blob/0dd802913811f9b896a1df853d93e13539454094/src/Box.hs

-}

import List.NonEmpty as NonEmpty exposing (NonEmpty)
import Result.Extra as Result


{-| Atomic parts of text. Invariant: Doesn't contain newlines.
-}
type Atom
    = -- Anything except spaces, tabs and newlines
      Text String
      -- A space
    | Space
      -- Aligns to the nearest multiple of `spacesPerTab`
    | Tab


{-| Only ever a single line of text
-}
type alias Line =
    NonEmpty Atom


{-| A Block contains at least 1 line of text (it can't be empty).
-}
type Block
    = -- A single line
      SingleLine Line
      -- Two or more lines stacked
    | Stack Line Line (List Line)


spacesPerTab : Int
spacesPerTab =
    4



-- STACKING


stack : NonEmpty Block -> Block
stack =
    NonEmpty.foldr1 stackTwo


stackTwo : Block -> Block -> Block
stackTwo first second =
    let
        ( line1, firstRest ) =
            destructure first

        ( line2, lineRest ) =
            nonEmptyAppend firstRest (destructure second)
    in
    Stack line1 line2 lineRest


destructure : Block -> NonEmpty Line
destructure block =
    case block of
        SingleLine line ->
            ( line, [] )

        Stack first second rest ->
            ( first, second :: rest )


nonEmptyAppend : List a -> NonEmpty a -> NonEmpty a
nonEmptyAppend inFront ( first, rest ) =
    case inFront of
        [] ->
            ( first, rest )

        firstFront :: firstRest ->
            ( firstFront, firstRest ++ first :: rest )



-- TRANSFORMING


mapLines : { first : Line -> Line, other : Line -> Line } -> Block -> Block
mapLines { first, other } block =
    case block of
        SingleLine line ->
            SingleLine (first line)

        Stack firstL second rest ->
            Stack (first firstL) (other second) (List.map other rest)


indent : Block -> Block
indent block =
    mapLines
        { first = \line -> NonEmpty.cons Tab line
        , other = \line -> NonEmpty.cons Tab line
        }
        block


ensureSingleLine : Block -> Result Block Line
ensureSingleLine block =
    case block of
        SingleLine line ->
            Ok line

        _ ->
            Err block


ensureAllSingleLine : List Block -> Result (List Block) (List Line)
ensureAllSingleLine blocks =
    blocks
        |> Result.combineMap ensureSingleLine
        |> Result.mapError (\_ -> blocks)



-- BUILDING
-- RENDERING


render : Block -> String
render block =
    case block of
        SingleLine line ->
            String.trimRight (renderLine 0 line) ++ "\n"

        Stack first second rest ->
            String.join "\n"
                (List.map (String.trimRight << renderLine 0)
                    (first :: second :: rest)
                )


renderLine : Int -> Line -> String
renderLine startColumn line =
    line
        |> NonEmpty.foldl
            (\atom ( currentText, currentColumn ) ->
                let
                    atomText =
                        renderAtom currentColumn atom
                in
                ( currentText ++ atomText
                , currentColumn + String.length atomText
                )
            )
            ( ""
            , startColumn
            )
        |> Tuple.first


renderAtom : Int -> Atom -> String
renderAtom startColumn atom =
    case atom of
        Text text ->
            text

        Space ->
            " "

        Tab ->
            String.repeat (modBy spacesPerTab startColumn) " "



-- UTILITIES


endColumn : Int -> Line -> Int
endColumn startColumn line =
    line
        |> NonEmpty.foldl
            (\atom ( currentSize, currentColumn ) ->
                let
                    width =
                        atomWidth currentColumn atom
                in
                ( currentSize + width
                , currentColumn + width
                )
            )
            ( 0
            , startColumn
            )
        |> Tuple.second


atomWidth : Int -> Atom -> Int
atomWidth startColumn atom =
    case atom of
        Text str ->
            String.length str

        Space ->
            1

        Tab ->
            -- The amount of spaces needed to get
            -- to the next multiple of `spacesPerTab`
            spacesPerTab - modBy spacesPerTab startColumn
