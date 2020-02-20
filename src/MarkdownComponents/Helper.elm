module MarkdownComponents.Helper exposing (..)

import Dict exposing (Dict)


init : model -> String -> Dict String model -> model
init default id =
    Dict.get id >> Maybe.withDefault default


update :
    model
    -> String
    -> (model -> ( model, Cmd msg ))
    -> Dict String model
    -> ( Dict String model, Cmd msg )
update default id updater dict =
    let
        model =
            Maybe.withDefault default (Dict.get id dict)

        ( newModel, command ) =
            updater model
    in
    ( Dict.insert id newModel dict, command )
