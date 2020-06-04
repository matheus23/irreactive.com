module Components.CodeInteractiveElm exposing (..)

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


type alias Model =
    { expression : Expression }


type Msg
    = ToggleExpression (List Int)


interpret : Expression -> Svg msg
interpret =
    cata interpretAlg


interpretAlg : ExpressionF (Svg msg) -> Svg msg
interpretAlg expression =
    case expression of
        Superimposed active _ _ expressions _ ->
            if active then
                expressions.elements
                    |> List.map .expression
                    |> List.reverse
                    |> Svg.g []

            else
                Svg.g [] []

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


init : String -> Result String Model
init code =
    code
        |> parse
        |> Result.map
            (\result -> { expression = result })



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleExpression path ->
            { model
                | expression =
                    indexedCata (toggleExpression path) [] model.expression
            }


toggleExpression : List Int -> List Int -> ExpressionF Expression -> Expression
toggleExpression togglePath currentPath constructor =
    let
        toggleActive active =
            xor active (togglePath == currentPath)
    in
    Expression <|
        case constructor of
            Superimposed active t0 t1 list t2 ->
                Superimposed (toggleActive active) t0 t1 list t2

            Moved active t0 t1 x t2 y t3 e t4 ->
                Moved (toggleActive active) t0 t1 x t2 y t3 e t4

            _ ->
                constructor



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
viewExpression expression =
    indexedCata viewExpressionAlg [] expression True


viewExpressionAlg : List Int -> ExpressionF (Bool -> List (Html Msg)) -> Bool -> List (Html Msg)
viewExpressionAlg path expression parentActive =
    case expression of
        Superimposed active t0 t1 list t2 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "superimposed"
                  , text t1
                  ]
                , list
                    -- |> reverseExpressionList
                    |> viewExpressionList (active && parentActive)
                , [ viewOther (active && parentActive) t2 ]
                ]

        Moved active t0 t1 x t2 y t3 e t4 ->
            List.concat
                [ [ viewOther (active && parentActive) t0
                  , viewFunctionName path (active && parentActive) "moved"
                  , text t1
                  , viewIntLiteral (active && parentActive) x
                  , text t2
                  , viewIntLiteral (active && parentActive) y
                  , text t3
                  ]
                , e parentActive
                , [ viewOther (active && parentActive) t4 ]
                ]

        Filled t0 t1 col t2 shape t3 ->
            List.concat
                [ [ viewOther parentActive t0
                  , viewFunctionName path parentActive "filled"
                  , text t1
                  , viewColorLiteral parentActive col
                  , text t2
                  ]
                , shape parentActive
                , [ viewOther parentActive t3 ]
                ]

        Outlined t0 t1 col t2 shape t3 ->
            List.concat
                [ [ viewOther parentActive t0
                  , viewFunctionName path parentActive "outlined"
                  , text t1
                  , viewColorLiteral parentActive col
                  , text t2
                  ]
                , shape parentActive
                , [ viewOther parentActive t3 ]
                ]

        Circle t0 t1 r t2 ->
            [ viewOther parentActive t0
            , viewFunctionName path parentActive "circle"
            , text t1
            , viewIntLiteral parentActive r
            , viewOther parentActive t2
            ]

        Rectangle t0 t1 w t2 h t3 ->
            [ viewOther parentActive t0
            , viewFunctionName path parentActive "rectangle"
            , text t1
            , viewIntLiteral parentActive w
            , text t2
            , viewIntLiteral parentActive h
            , viewOther parentActive t3
            ]


viewFunctionName : List Int -> Bool -> String -> Html Msg
viewFunctionName path active name =
    span
        [ if active then
            class "hover:bg-gruv-gray-3 cursor-pointer"

          else
            class "hover:bg-gruv-gray-3 cursor-pointer text-gruv-gray-6"
        , Events.onClick (ToggleExpression path)
        ]
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


viewExpressionList : Bool -> ExpressionList (Bool -> List (Html Msg)) -> List (Html Msg)
viewExpressionList active { elements, tail } =
    List.concatMap (viewListItem active) elements
        ++ [ viewOther active tail ]


viewListItem : Bool -> { prefix : String, expression : Bool -> List (Html Msg) } -> List (Html Msg)
viewListItem active { prefix, expression } =
    viewOther active prefix :: expression active
