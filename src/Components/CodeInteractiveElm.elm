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


interpret : Expression -> Svg msg
interpret =
    cata interpretAlg


interpretAlg : ExpressionF (Svg msg) -> Svg msg
interpretAlg expression =
    case expression of
        Superimposed _ _ expressions _ ->
            expressions.elements
                |> List.map .expression
                |> List.reverse
                |> Svg.g []

        Moved active _ _ x _ y _ e _ ->
            if active then
                Svg.g
                    [ SvgA.transform [ Svg.Translate (toFloat x) (toFloat y) ] ]
                    [ e ]

            else
                e

        Filled _ _ color _ e _ ->
            Svg.g [ SvgA.fill (Svg.Paint (Common.colorToRGB color)) ]
                [ e ]

        Outlined _ _ color _ e _ ->
            Svg.g
                [ SvgA.stroke (Svg.Paint (Common.colorToRGB color))
                , SvgPx.strokeWidth 8
                , SvgA.fill Svg.PaintNone
                ]
                [ e ]

        Circle _ _ r _ ->
            Svg.circle
                [ SvgPx.r (toFloat r) ]
                []

        Rectangle _ _ wInt _ hInt _ ->
            let
                w =
                    toFloat wInt

                h =
                    toFloat hInt
            in
            Svg.rect
                [ SvgPx.width w
                , SvgPx.height h
                , SvgPx.x (-w / 2)
                , SvgPx.y (-h / 2)
                , SvgA.transform [ Svg.Translate (w / 2) (h / 2) ]
                ]
                []



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { expression =
            flags.code
                |> parse
                -- An error should never happen. This is validation-checked by MarkdownDocument.elm
                -- Should parsing only happen once in the renderer and the value be transferred directly?
                |> Result.unpack (Expression << Superimposed "" " " { elements = [], tail = "[]\n" }) identity
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
            [ interpret model.expression ]
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


reverseExpressionList : ExpressionList a -> ExpressionList a
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
viewExpression =
    cata viewExpressionAlg


viewExpressionAlg : ExpressionF (List (Html Msg)) -> List (Html Msg)
viewExpressionAlg expression =
    case expression of
        Superimposed t0 t1 list t2 ->
            List.concat
                [ [ text t0
                  , viewFunctionName True "superimposed"
                  , text t1
                  ]
                , list
                    -- |> reverseExpressionList
                    |> viewExpressionList
                , [ text t2 ]
                ]

        Moved active t0 t1 x t2 y t3 e t4 ->
            List.concat
                [ [ viewOther active t0
                  , viewFunctionName active "moved"
                  , text t1
                  , viewIntLiteral active x
                  , text t2
                  , viewIntLiteral active y
                  , text t3
                  ]
                , e
                , [ viewOther active t4 ]
                ]

        Filled t0 t1 col t2 shape t3 ->
            List.concat
                [ [ text t0
                  , viewFunctionName True "filled"
                  , text t1
                  , viewColorLiteral True col
                  , text t2
                  ]
                , shape
                , [ text t3 ]
                ]

        Outlined t0 t1 col t2 shape t3 ->
            List.concat
                [ [ text t0
                  , viewFunctionName True "outlined"
                  , text t1
                  , viewColorLiteral True col
                  , text t2
                  ]
                , shape
                , [ text t3 ]
                ]

        Circle t0 t1 r t2 ->
            [ text t0
            , viewFunctionName True "circle"
            , text t1
            , viewIntLiteral True r
            , text t2
            ]

        Rectangle t0 t1 w t2 h t3 ->
            [ text t0
            , viewFunctionName True "rectangle"
            , text t1
            , viewIntLiteral True w
            , text t2
            , viewIntLiteral True h
            , text t3
            ]


viewFunctionName : Bool -> String -> Html Msg
viewFunctionName active name =
    span
        (if active then
            [ class "hover:bg-gruv-gray-3 cursor-pointer" ]

         else
            [ class "hover:bg-gruv-gray-3 cursor-pointer text-gruv-gray-6" ]
        )
        [ text name ]


viewOther : Bool -> String -> Html msg
viewOther active content =
    span
        (if active then
            []

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text content ]


viewIntLiteral : Bool -> Int -> Html Msg
viewIntLiteral active i =
    span
        (if active then
            [ class "text-gruv-blue-l" ]

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text (String.fromInt i) ]


viewColorLiteral : Bool -> Common.Color -> Html Msg
viewColorLiteral active col =
    span
        (if active then
            [ class "text-gruv-green-l" ]

         else
            [ class "text-gruv-gray-6" ]
        )
        [ text ("\"" ++ Common.colorName col ++ "\"") ]


viewExpressionList : ExpressionList (List (Html Msg)) -> List (Html Msg)
viewExpressionList { elements, tail } =
    List.concatMap viewListItem elements
        ++ [ text tail ]


viewListItem : { prefix : String, expression : List (Html Msg) } -> List (Html Msg)
viewListItem { prefix, expression } =
    text prefix :: expression



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }
