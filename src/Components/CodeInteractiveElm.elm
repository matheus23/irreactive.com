module Components.CodeInteractiveElm exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import Json.Decode as Decode
import Language.Common as Common
import Language.InteractiveElm exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
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
    { expression : Expression }


type alias Msg =
    Never


interpret : Expression -> List (Svg msg)
interpret expression =
    []



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { expression =
            flags.code
                |> parse
                |> Result.withDefault (Superimposed [])
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    never msg



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : Model -> Html Msg
view model =
    div [ class "mt-4" ]
        [ svg
            [ attribute "class" "bg-gruv-gray-10"
            , SvgA.width (Svg.Percent 100)
            , SvgA.viewBox 0 0 500 200
            ]
            (interpret model.expression)
        , pre
            [ classes
                [ "py-6 px-8"
                , "overflow-y-auto"
                , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                ]
            ]
            [ code []
                (viewExpression model.expression)
            ]
        ]


viewExpression : Expression -> List (Html Msg)
viewExpression expression =
    viewFunction
        { name = "superimposed"
        , thisLineParams = []
        , nextLinesParams =
            [ listOf
                [ viewFunction
                    { name = "moved"
                    , thisLineParams = [ text "200", text "100" ]
                    , nextLinesParams =
                        [ parens
                            (viewFunction
                                { name = "filled"
                                , thisLineParams =
                                    [ text ("\"" ++ Common.colorName Common.Blue ++ "\"")
                                    ]
                                , nextLinesParams =
                                    [ SingleLine [ text "rectangle 50 30" ] ]
                                }
                            )
                        ]
                    }
                , viewFunction
                    { name = "moved"
                    , thisLineParams = [ text "100", text "100" ]
                    , nextLinesParams = []
                    }
                ]
            ]
        }
        |> extractRendered


type alias FunctionConfig =
    { name : String
    , thisLineParams : List (Html Msg)
    , nextLinesParams : List Rendered
    }


type Rendered
    = SingleLine (List (Html Msg))
    | MultiLine (List (Html Msg)) (List Rendered)


extractRendered : Rendered -> List (Html Msg)
extractRendered rendered =
    case rendered of
        SingleLine elems ->
            elems

        MultiLine first elems ->
            first
                ++ List.concatMap
                    (\elem -> text "\n" :: extractRendered elem)
                    elems


indent : { first : String, other : String } -> Rendered -> Rendered
indent prefix rendered =
    case rendered of
        SingleLine elems ->
            SingleLine (text prefix.first :: elems)

        MultiLine first elems ->
            MultiLine
                (text prefix.first :: first)
                (List.map
                    (indent
                        -- Only the first line (first layor of recursion)
                        -- gets the "first" prefix.
                        { first = prefix.other
                        , other = prefix.other
                        }
                    )
                    elems
                )


viewFunction : FunctionConfig -> Rendered
viewFunction config =
    case config.nextLinesParams of
        [] ->
            SingleLine
                (text config.name
                    :: (config.thisLineParams
                            |> List.concatMap (\param -> [ text " ", param ])
                       )
                )

        _ ->
            MultiLine
                (text config.name
                    :: (config.thisLineParams
                            |> List.concatMap (\param -> [ text " ", param ])
                       )
                )
                config.nextLinesParams
                |> indent { first = "", other = "    " }


listOf : List Rendered -> Rendered
listOf elements =
    case elements of
        [] ->
            SingleLine [ text "[]" ]

        first :: rest ->
            MultiLine
                (indent
                    { first = "[ "
                    , other = "  "
                    }
                    first
                    |> extractRendered
                )
                (List.map
                    (indent
                        { first = ", "
                        , other = "  "
                        }
                    )
                    rest
                    ++ [ SingleLine [ text "]" ] ]
                )


parens : Rendered -> Rendered
parens rendered =
    case rendered of
        SingleLine elems ->
            SingleLine ([ text "(" ] ++ elems ++ [ text ")" ])

        MultiLine first rest ->
            MultiLine
                (text "(" :: first)
                (rest ++ [ SingleLine [ text ")" ] ])



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
