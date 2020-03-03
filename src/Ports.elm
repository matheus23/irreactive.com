port module Ports exposing (smoothScrollToPercentage)

import Json.Encode as Encode


optionalField : String -> (a -> Encode.Value) -> Maybe a -> List ( String, Encode.Value ) -> List ( String, Encode.Value )
optionalField field encoder value =
    case value of
        Just x ->
            \fields -> fields ++ [ ( field, encoder x ) ]

        Nothing ->
            \fields -> fields


port smoothScrollToPercentagePort : Encode.Value -> Cmd msg


smoothScrollToPercentage : String -> { left : Maybe Float, top : Maybe Float } -> Cmd msg
smoothScrollToPercentage domId { left, top } =
    [ ( "domId", Encode.string domId ) ]
        |> optionalField "left" Encode.float left
        |> optionalField "top" Encode.float top
        |> Encode.object
        |> smoothScrollToPercentagePort
