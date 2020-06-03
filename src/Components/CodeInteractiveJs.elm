module Components.CodeInteractiveJs exposing (..)

import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import Json.Decode as Decode
import Language.Common as Common
import Language.InteractiveJs exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Svg exposing (Svg, svg)
import TypedSvg.Attributes as SvgA
import TypedSvg.Attributes.InPx as SvgPx
import TypedSvg.Core as Svg
import TypedSvg.Types as Svg


type alias Model =
    List { enabled : Bool, statement : Statement }


type Msg
    = ToggleLine Int
    | CycleColor Int


type Shape
    = ShapeCircle { x : Int, y : Int, radius : Int }
    | ShapeRect { x : Int, y : Int, width : Int, height : Int }


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
                    Svg.g [ SvgA.transform [ Svg.Translate (toFloat x) (toFloat y) ] ]
                        [ Svg.circle
                            (SvgPx.r (toFloat radius)
                                :: strokeOrFill fillOptions
                            )
                            []
                        ]

                ShapeRect { x, y, width, height } ->
                    Svg.g
                        [ SvgA.transform
                            [ Svg.Translate
                                (toFloat x + (toFloat width / 2))
                                (toFloat y + (toFloat height / 2))
                            ]
                        ]
                        [ Svg.rect
                            ([ SvgPx.x (toFloat -width / 2)
                             , SvgPx.y (toFloat -height / 2)
                             , SvgPx.width (toFloat width)
                             , SvgPx.height (toFloat height)
                             ]
                                ++ strokeOrFill fillOptions
                            )
                            []
                        ]

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

                SetColor c ->
                    { state | color = Just c }

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
        , color = Nothing
        , currentShapes = []
        , finalizedShapes = []
        }
        statements
        |> .finalizedShapes



-- INIT


init : String -> Result String Model
init code =
    code
        |> parse
        |> Result.map
            (List.map
                (\statement -> { enabled = True, statement = statement })
            )



-- UPDATE


update : Msg -> Model -> Model
update msg statements =
    case msg of
        ToggleLine lineIndex ->
            List.updateAt lineIndex
                (\{ enabled, statement } ->
                    { enabled = not enabled
                    , statement = statement
                    }
                )
                statements

        CycleColor lineIndex ->
            List.updateAt lineIndex
                (\{ enabled, statement } ->
                    { enabled = enabled
                    , statement =
                        case statement of
                            SetColor color ->
                                SetColor (Common.nextColor color)

                            _ ->
                                statement
                    }
                )
                statements



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
            (linearGradient
                :: interpret
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

        SetColor col ->
            viewFunction clss
                attributes
                enabled
                "setColor"
                [ viewColor
                    (if enabled then
                        [ Events.custom "click"
                            (Decode.succeed
                                { message = CycleColor index
                                , stopPropagation = True
                                , preventDefault = True
                                }
                            )
                        ]

                     else
                        []
                    )
                    enabled
                    col
                ]

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


viewColor : List (Attribute Msg) -> Bool -> Common.Color -> Html Msg
viewColor attributes enabled color =
    span
        (class (ifEnabledColor enabled "text-gruv-green-l")
            :: attributes
        )
        [ text "\""
        , text (Common.colorName color)
        , text "\""
        ]


colorToPaint : Maybe Common.Color -> Svg.Paint
colorToPaint color =
    case color of
        Just col ->
            Svg.Paint (Common.colorToRGB col)

        Nothing ->
            Svg.Reference "rainbow"


ifEnabledColor : Bool -> String -> String
ifEnabledColor enabled color =
    if enabled then
        color

    else
        "text-gruv-gray-6"


linearGradient : Svg msg
linearGradient =
    Svg.defs []
        [ Svg.linearGradient
            [ SvgA.id "rainbow"
            , SvgPx.x1 -40
            , SvgPx.y1 -40
            , SvgPx.x2 40
            , SvgPx.y2 40
            , SvgA.gradientUnits Svg.CoordinateSystemUserSpaceOnUse
            ]
            [ Svg.stop [ SvgA.offset "0.135417", SvgA.stopColor "#40F6F6", SvgA.stopOpacity (Svg.Opacity 0.84375) ] []
            , Svg.stop [ SvgA.offset "0.296875", SvgA.stopColor "#24F6B7" ] []
            , Svg.stop [ SvgA.offset "0.421875", SvgA.stopColor "#A9F829" ] []
            , Svg.stop [ SvgA.offset "0.557292", SvgA.stopColor "#FCFEB2" ] []
            , Svg.stop [ SvgA.offset "0.703125", SvgA.stopColor "#F8E85E" ] []
            , Svg.stop [ SvgA.offset "0.838542", SvgA.stopColor "white" ] []
            , Svg.stop [ SvgA.offset "1", SvgA.stopColor "#AAD0F2" ] []
            ]
        , Svg.animate
            [ SvgA.xlinkHref "rainbow"
            ]
            []
        ]
