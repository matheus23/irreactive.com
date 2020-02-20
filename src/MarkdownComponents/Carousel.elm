module MarkdownComponents.Carousel exposing (..)

import Browser.Dom exposing (Viewport)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Result.Extra as Result
import Task


type alias Model =
    { scrollPosition : Float }


type Msg
    = NoOp
    | OnScroll String
    | GetViewport Viewport


init : Model
init =
    { scrollPosition = 0 }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OnScroll carouselId ->
            ( model
            , Browser.Dom.getViewportOf carouselId
                |> Task.attempt
                    (Result.mapBoth (always NoOp) GetViewport >> Result.merge)
            )

        GetViewport { scene, viewport } ->
            ( { model
                | scrollPosition = viewport.x / (scene.width - viewport.width)
              }
            , Cmd.none
            )


view : (Msg -> msg) -> String -> Model -> List (Html msg) -> Html msg
view liftMsg identifier model children =
    let
        scrolledItem =
            model.scrollPosition * toFloat (List.length children - 1)
    in
    Html.section [ Attr.class "carousel-container" ]
        [ Html.div
            [ Attr.class "carousel"
            , Attr.id identifier
            , Events.on "scroll" (Decode.succeed (liftMsg (OnScroll identifier)))
            ]
            children
        , Html.div [ Attr.class "dots" ]
            (List.indexedMap (\index _ -> viewDot scrolledItem index) children)
        ]


viewDot : Float -> Int -> Html msg
viewDot scrolledItem index =
    let
        irrelevancy =
            (toFloat index - scrolledItem)
                |> abs
                |> clamp 0 1

        color =
            String.concat
                [ "rgba(146,131,116,"
                , String.fromFloat (1 - irrelevancy)
                , ")"
                ]
    in
    Html.div
        [ Attr.class "dot"
        , Attr.style "background-color" color
        ]
        []
