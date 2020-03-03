module MarkdownComponents.Carousel exposing (..)

import Browser.Dom exposing (Viewport)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Ports
import Result.Extra as Result
import Task


type alias Model =
    { scrollPosition : Float }


type Msg
    = NoOp
    | OnScroll
    | GetViewport Viewport
    | ScrollTo Float


init : Model
init =
    { scrollPosition = 0 }


update : String -> Msg -> Model -> ( Model, Cmd Msg )
update carouselId msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        OnScroll ->
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

        ScrollTo percentage ->
            ( model
            , Ports.smoothScrollToPercentage carouselId { left = Just percentage, top = Nothing }
            )


view : (Msg -> msg) -> String -> Model -> List (Html msg) -> Html msg
view liftMsg carouselId model children =
    let
        lastIndex =
            toFloat (List.length children - 1)

        amountChildren =
            toFloat (List.length children)

        scrolledItem =
            model.scrollPosition * lastIndex

        irrelevancy index =
            (toFloat index - scrolledItem)
                |> abs
                |> clamp 0 1

        color index =
            String.concat
                [ "rgba(146,131,116,"
                , String.fromFloat (1 - irrelevancy index)
                , ")"
                ]

        viewDot index =
            Html.div
                [ Attr.class "dot"
                , Attr.style "background-color" (color index)
                , Events.onClick <| liftMsg <| ScrollTo <| toFloat index / amountChildren
                ]
                []
    in
    Html.section [ Attr.class "carousel-container" ]
        [ Html.div
            [ Attr.class "carousel"
            , Attr.id carouselId
            , Events.on "scroll" (Decode.succeed (liftMsg OnScroll))
            ]
            children
        , Html.div [ Attr.class "dots" ]
            (List.indexedMap (\index _ -> viewDot index) children)
        ]
