module Components.MarkdownInteractive exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events as Events


type alias Model =
    { source : String
    }


type Msg
    = OnInput String


init : String -> Result String Model
init source =
    Ok { source = source }


update : Msg -> Model -> Model
update msg model =
    case msg of
        OnInput new ->
            { model | source = new }


view : Model -> Html Msg
view model =
    let
        enforceLastNewlineByDummyElement lines =
            lines ++ [ span [ class "whitespace-pre" ] [ text " " ] ]
    in
    pre
        [ class "mt-4 py-6 px-8 relative"
        , class "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-1"
        ]
        [ textarea
            [ class "bg-gruv-gray-1 absolute z-10"
            , style "left" "32px"
            , style "right" "32px"
            , style "top" "24px"
            , style "bottom" "24px"
            , style "width" "calc(100% - 64px)"
            , style "height" "calc(100% - 48px)"
            , style "resize" "none"
            , Events.onInput OnInput
            ]
            [ text model.source ]
        , div [ class "whitespace-pre-wrap" ]
            (model.source
                |> String.split "\n"
                |> List.map text
                |> List.intersperse (br [] [])
                |> enforceLastNewlineByDummyElement
            )
        ]
