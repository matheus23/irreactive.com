module Components.CodeInteractiveElm exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import Json.Decode as Decode
import Language.Block as Block exposing (Block)
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
                |> Result.withDefault (Superimposed "Error parsing..." { elements = [], tail = "" } "")
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
                (viewExpression example)
            ]
        ]


viewExpression : Expression -> List (Html Msg)
viewExpression expression =
    case expression of
        Superimposed t1 list t2 ->
            List.concat
                [ [ text t1 ]
                , viewExpressionList list
                , [ text t2 ]
                ]

        Moved t1 x t2 y t3 e t4 ->
            List.concat
                [ [ text t1
                  , text (String.fromInt x)
                  , text t2
                  , text (String.fromInt y)
                  , text t3
                  ]
                , viewExpression e
                , [ text t4 ]
                ]

        Filled t1 col t2 shape t3 ->
            List.concat
                [ [ text t1
                  , text ("\"" ++ Common.colorName col ++ "\"")
                  , text t2
                  ]
                , viewShape shape
                , [ text t3 ]
                ]

        Outlined t1 col t2 shape t3 ->
            List.concat
                [ [ text t1
                  , text ("\"" ++ Common.colorName col ++ "\"")
                  , text t2
                  ]
                , viewShape shape
                , [ text t3 ]
                ]


viewExpressionList : ExpressionList -> List (Html Msg)
viewExpressionList { elements, tail } =
    List.concatMap viewListItem elements
        ++ [ text tail ]


viewListItem : { prefix : String, expression : Expression } -> List (Html Msg)
viewListItem { prefix, expression } =
    text prefix :: viewExpression expression


viewShape : Shape -> List (Html Msg)
viewShape shape =
    case shape of
        Circle t1 r t2 ->
            [ text t1
            , text (String.fromInt r)
            , text t2
            ]

        Rectangle t1 w t2 h t3 ->
            [ text t1
            , text (String.fromInt w)
            , text t2
            , text (String.fromInt h)
            , text t3
            ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
