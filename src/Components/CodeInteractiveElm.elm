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
import Result.Extra as Result
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
                -- An error should never happen.
                |> Result.unpack (Superimposed "" " " { elements = [], tail = "[]\n" }) identity
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


reverseExpressionList : ExpressionList -> ExpressionList
reverseExpressionList list =
    let
        prefixes =
            List.map .prefix list.elements

        expressions =
            List.map .expression list.elements
    in
    { list
        | elements = List.map2 ListElement prefixes (List.reverse expressions)
    }


viewExpression : Expression -> List (Html Msg)
viewExpression expression =
    case expression of
        Superimposed t0 t1 list t2 ->
            List.concat
                [ [ text t0
                  , viewFunctionName "superimposed"
                  , text t1
                  ]
                , viewExpressionList list
                , [ text t2 ]
                ]

        Moved t0 t1 x t2 y t3 e t4 ->
            List.concat
                [ [ text t0
                  , viewFunctionName "moved"
                  , text t1
                  , viewIntLiteral x
                  , text t2
                  , viewIntLiteral y
                  , text t3
                  ]
                , viewExpression e
                , [ text t4 ]
                ]

        Filled t0 t1 col t2 shape t3 ->
            List.concat
                [ [ text t0
                  , viewFunctionName "filled"
                  , text t1
                  , viewColorLiteral col
                  , text t2
                  ]
                , viewShape shape
                , [ text t3 ]
                ]

        Outlined t0 t1 col t2 shape t3 ->
            List.concat
                [ [ text t0
                  , viewFunctionName "outlined"
                  , text t1
                  , viewColorLiteral col
                  , text t2
                  ]
                , viewShape shape
                , [ text t3 ]
                ]


viewFunctionName : String -> Html Msg
viewFunctionName name =
    span [ class "hover:bg-gruv-gray-3 cursor-pointer" ] [ text name ]


viewIntLiteral : Int -> Html Msg
viewIntLiteral i =
    span [ class "text-gruv-blue-l" ] [ text (String.fromInt i) ]


viewColorLiteral : Common.Color -> Html Msg
viewColorLiteral col =
    span [ class "text-gruv-green-l" ] [ text ("\"" ++ Common.colorName col ++ "\"") ]


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
        Circle t0 t1 r t2 ->
            [ text t0
            , viewFunctionName "circle"
            , text t1
            , viewIntLiteral r
            , text t2
            ]

        Rectangle t0 t1 w t2 h t3 ->
            [ text t0
            , viewFunctionName "rectangle"
            , text t1
            , viewIntLiteral w
            , text t2
            , viewIntLiteral h
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
