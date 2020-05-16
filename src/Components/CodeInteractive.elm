module Components.CodeInteractive exposing (main)

import Browser
import Color
import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import List.Extra as List
import Maybe.Extra as Maybe
import Parser
import Svg exposing (Svg, svg)
import TypedSvg.Attributes as SvgA
import TypedSvg.Attributes.InPx as SvgPx
import TypedSvg.Core as Svg
import TypedSvg.Types as Svg


type alias Flags =
    { language : Maybe String
    , code : String
    }


type alias Model =
    List { enabled : Bool, statement : Statement }


type Msg
    = ToggleLine Int


type Statement
    = Stroke
    | Fill
    | MoveTo Int Int
    | SetFillStyle Color
    | Circle Int
    | Rectangle Int Int


type Shape
    = ShapeCircle { x : Int, y : Int, radius : Int }
    | ShapeRect { x : Int, y : Int, width : Int, height : Int }


type Color
    = Red
    | Green
    | Blue
    | Purple
    | Yellow
    | Aqua
    | Orange
    | Magic


interpret : List Statement -> List (Svg msg)
interpret statements =
    let
        strokeOrFill { color, fill } =
            if fill then
                [ SvgA.fill <| colorToPaint color ]

            else
                [ SvgA.stroke (colorToPaint color)
                , SvgPx.strokeWidth 8
                , SvgA.fill Svg.PaintNone
                ]

        finalizeShape fillOptions shape =
            case shape of
                ShapeCircle { x, y, radius } ->
                    Svg.circle
                        ([ SvgPx.cx (toFloat x)
                         , SvgPx.cy (toFloat y)
                         , SvgPx.r (toFloat radius)
                         ]
                            ++ strokeOrFill fillOptions
                        )
                        []

                ShapeRect { x, y, width, height } ->
                    Svg.rect
                        ([ SvgPx.x (toFloat x)
                         , SvgPx.y (toFloat y)
                         , SvgPx.width (toFloat width)
                         , SvgPx.height (toFloat height)
                         ]
                            ++ strokeOrFill fillOptions
                        )
                        []

        interpretStatement statement state =
            case statement of
                Stroke ->
                    { state
                        | currentShapes = []
                        , finalizedShapes =
                            state.finalizedShapes
                                ++ List.map
                                    (finalizeShape
                                        { color = state.color
                                        , fill = False
                                        }
                                    )
                                    state.currentShapes
                    }

                Fill ->
                    { state
                        | currentShapes = []
                        , finalizedShapes =
                            state.finalizedShapes
                                ++ List.map
                                    (finalizeShape
                                        { color = state.color
                                        , fill = True
                                        }
                                    )
                                    state.currentShapes
                    }

                MoveTo px py ->
                    { state
                        | x = px
                        , y = py
                    }

                SetFillStyle c ->
                    { state | color = c }

                Circle r ->
                    { state
                        | currentShapes =
                            state.currentShapes
                                ++ [ ShapeCircle
                                        { x = state.x
                                        , y = state.y
                                        , radius = r
                                        }
                                   ]
                    }

                Rectangle w h ->
                    { state
                        | currentShapes =
                            state.currentShapes
                                ++ [ ShapeRect
                                        { x = state.x
                                        , y = state.y
                                        , width = w
                                        , height = h
                                        }
                                   ]
                    }
    in
    List.foldl interpretStatement
        { x = 0
        , y = 0
        , color = Magic
        , currentShapes = []
        , finalizedShapes = []
        }
        statements
        |> .finalizedShapes



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( [ { enabled = True, statement = MoveTo 100 100 }
      , { enabled = True, statement = SetFillStyle Red }
      , { enabled = True, statement = Circle 20 }
      , { enabled = True, statement = Stroke }
      , { enabled = True, statement = MoveTo 200 100 }
      , { enabled = True, statement = SetFillStyle Blue }
      , { enabled = True, statement = Rectangle 50 30 }
      , { enabled = True, statement = Fill }
      ]
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg statements =
    case msg of
        ToggleLine lineIndex ->
            ( List.updateAt lineIndex
                (\{ enabled, statement } ->
                    { enabled = not enabled
                    , statement = statement
                    }
                )
                statements
            , Cmd.none
            )



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : Model -> Html Msg
view statements =
    div [ class "mt-4" ]
        [ svg
            [ attribute "class" "bg-gruv-gray-10"
            , SvgA.width (Svg.Percent 100)
            , SvgA.viewBox 0 0 500 200
            ]
            (interpret
                (List.filterMap
                    (\{ enabled, statement } ->
                        if enabled then
                            Just statement

                        else
                            Nothing
                    )
                    statements
                )
            )
        , pre
            [ classes
                [ "py-6 px-8"
                , "overflow-y-auto"
                , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                ]
            ]
            [ code []
                (List.indexedMap viewStatement statements)
            ]
        ]


viewStatement : Int -> { enabled : Bool, statement : Statement } -> Html Msg
viewStatement index { enabled, statement } =
    let
        attributes =
            [ Events.onClick (ToggleLine index) ]

        clss =
            [ "cursor-pointer select-none" ]
    in
    case statement of
        Stroke ->
            viewFunction clss attributes enabled "stroke" []

        Fill ->
            viewFunction clss attributes enabled "fill" []

        MoveTo x y ->
            viewFunction clss attributes enabled "moveTo" [ viewInt enabled x, viewInt enabled y ]

        SetFillStyle col ->
            viewFunction clss attributes enabled "setFillStyle" [ viewColor enabled col ]

        Circle r ->
            viewFunction clss attributes enabled "circle" [ viewInt enabled r ]

        Rectangle w h ->
            viewFunction clss attributes enabled "rectangle" [ viewInt enabled w, viewInt enabled h ]


viewFunction : List String -> List (Attribute Msg) -> Bool -> String -> List (Html Msg) -> Html Msg
viewFunction clss attributes enabled name parameters =
    [ [ text name
      , text "("
      ]
    , List.intersperse (text ", ") parameters
    , [ text ");"
      ]
    ]
        |> List.concat
        |> div
            (classes
                (ifEnabledColor enabled "text-gruv-gray-12"
                    :: clss
                )
                :: attributes
            )


viewInt : Bool -> Int -> Html Msg
viewInt enabled i =
    span [ class (ifEnabledColor enabled "text-gruv-blue-l") ] [ text (String.fromInt i) ]


viewColor : Bool -> Color -> Html Msg
viewColor enabled color =
    let
        name =
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

                Magic ->
                    "magic"
    in
    span
        [ class (ifEnabledColor enabled "text-gruv-green-l") ]
        [ text "\""
        , text name
        , text "\""
        ]


colorToPaint : Color -> Svg.Paint
colorToPaint color =
    Svg.Paint <|
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

            Magic ->
                Color.rgb255 254 128 25


ifEnabledColor : Bool -> String -> String
ifEnabledColor enabled color =
    if enabled then
        color

    else
        "text-gruv-gray-6"



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
