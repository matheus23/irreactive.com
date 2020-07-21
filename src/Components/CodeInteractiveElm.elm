module Components.CodeInteractiveElm exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class)
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
    { expression : PartialExpression }


type Msg
    = ToggleExpression (List Int)
    | ToggleListElement (List Int) Int


interpret : PartialExpression -> Svg msg
interpret =
    cataPartial (activeOnly interpretAlg)


interpretAlg : ExpressionF (Svg msg) -> Svg msg
interpretAlg expression =
    case expression of
        Superimposed _ _ e _ ->
            e

        ListOf _ expressions _ ->
            -- this basically can only be used in 'superimposed',
            -- so we already know what to do with it
            expressions
                |> expressionListToList
                |> List.reverse
                |> Svg.g []

        Moved _ _ x _ y _ e _ ->
            Svg.g
                [ SvgA.transform [ Svg.Translate (toFloat x) (toFloat y) ] ]
                [ e ]

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

        EmptyStencil _ _ ->
            Svg.g [] []

        EmptyPicture _ _ ->
            Svg.g [] []


type Type
    = Stencil
    | Picture
    | ListOfPictures


type alias TypeError =
    { expectedType : Type
    , actualType : Type
    , path : List Int
    }


typeErrors : PartialExpression -> List TypeError
typeErrors expression =
    indexedCataPartial
        (\path active constructor ->
            activeOnly
                (typeErrorsAlg path)
                active
                constructor
        )
        []
        expression
        Picture


typeErrorsAlg : List Int -> ExpressionF (Type -> List TypeError) -> Type -> List TypeError
typeErrorsAlg path constructor expectedType =
    let
        checkType typeOfThis =
            if typeOfThis /= expectedType then
                [ { expectedType = expectedType
                  , actualType = typeOfThis
                  , path = path
                  }
                ]

            else
                []
    in
    case constructor of
        Superimposed _ _ e _ ->
            e ListOfPictures
                ++ checkType Picture

        ListOf _ expressionList _ ->
            List.concatMap
                (\expectType ->
                    expectType
                        Picture
                )
                (expressionListToList expressionList)
                ++ checkType ListOfPictures

        Moved _ _ _ _ _ _ e _ ->
            e Picture
                ++ checkType Picture

        Filled _ _ _ _ shape _ ->
            shape Stencil
                ++ checkType Picture

        Outlined _ _ _ _ shape _ ->
            shape Stencil
                ++ checkType Picture

        Circle _ _ _ _ ->
            checkType Stencil

        Rectangle _ _ _ _ _ _ ->
            checkType Stencil

        EmptyStencil _ _ ->
            checkType Stencil

        EmptyPicture _ _ ->
            checkType Picture



-- INIT


init : String -> Result String Model
init code =
    code
        |> parse
        |> Result.map enableAll
        |> Result.map
            (\result -> { expression = result })



-- UPDATE


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleExpression path ->
            { model
                | expression =
                    indexedCataPartial (toggleExpression path) [] model.expression
            }

        ToggleListElement path index ->
            { model
                | expression =
                    indexedCataPartial (toggleListElement path index) [] model.expression
            }


toggleExpression : List Int -> List Int -> Bool -> ExpressionF PartialExpression -> PartialExpression
toggleExpression togglePath currentPath active constructor =
    PartialExpression
        (xor active (togglePath == currentPath))
        constructor


toggleListElement : List Int -> Int -> List Int -> Bool -> ExpressionF PartialExpression -> PartialExpression
toggleListElement togglePath toggleIndex currentPath active constructor =
    if togglePath == currentPath then
        case constructor of
            ListOf t0 elements t1 ->
                PartialExpression
                    active
                    (ListOf
                        t0
                        (List.indexedMap
                            (\currentIndex listElement ->
                                { listElement
                                    | active = xor listElement.active (currentIndex == toggleIndex)
                                }
                            )
                            elements
                        )
                        t1
                    )

            _ ->
                PartialExpression active constructor

    else
        PartialExpression active constructor



-- VIEW


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


view : Model -> Html Msg
view model =
    let
        computedErrors =
            typeErrors model.expression
    in
    div [ class "mt-4" ]
        [ div [ class "bg-gruv-gray-10 relative" ]
            (case computedErrors of
                [] ->
                    [ svg
                        [ SvgA.width (Svg.Percent 100)
                        , SvgA.viewBox 0 0 500 200
                        ]
                        [ interpret model.expression ]
                    ]

                errors ->
                    [ svg
                        [ SvgA.width (Svg.Percent 100)
                        , SvgA.viewBox 0 0 500 200
                        ]
                        []
                    , div
                        [ classes
                            [ "absolute w-full h-full top-0"
                            , "bg-gruv-gray-0 opacity-50"
                            , "text-gruv-gray-12 font-code"
                            , "p-4 whitespace-pre"
                            ]
                        ]
                        (let
                            typeToString typ =
                                case typ of
                                    Picture ->
                                        "Picture"

                                    Stencil ->
                                        "Stencil"

                                    ListOfPictures ->
                                        "List of Pictures"

                            renderError { expectedType, actualType } =
                                [ text "Expected type: "
                                , text (typeToString expectedType)
                                , text "\n"
                                , text "  Actual type: "
                                , text (typeToString actualType)
                                , text "\n\n"
                                ]
                         in
                         text "The code has errors:\n"
                            :: List.concatMap renderError errors
                        )
                    ]
            )
        , pre
            [ classes
                [ "py-6 px-8"
                , "overflow-y-auto"
                , "select-none"
                , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                ]
            ]
            [ code []
                (viewExpression computedErrors model.expression)
            ]
        ]


viewExpression : List TypeError -> PartialExpression -> List (Html Msg)
viewExpression errors expression =
    indexedCataPartial (viewExpressionAlg errors) [] expression True


viewExpressionAlg :
    List TypeError
    -> List Int
    -> Bool
    -> ExpressionF (Bool -> List (Html Msg))
    -> Bool
    -> List (Html Msg)
viewExpressionAlg errors path active expression parentActive =
    let
        existsErrorOnThis =
            List.any
                (\error -> error.path == path)
                errors

        possiblyAddErrorIndicator htmls =
            if existsErrorOnThis then
                [ span [ class "has-type-error" ] htmls ]

            else
                htmls
    in
    possiblyAddErrorIndicator <|
        case expression of
            Superimposed t0 t1 e t2 ->
                List.concat
                    [ [ viewOther (active && parentActive) t0
                      , viewFunctionName path (active && parentActive) "superimposed"
                      , text t1
                      ]
                    , e (active && parentActive)
                    , [ viewOther (active && parentActive) t2 ]
                    ]

            ListOf t0 elements t1 ->
                List.concat
                    [ [ viewOther (active && parentActive) t0 ]
                    , (List.foldl (viewListItem (active && parentActive) path)
                        { prefixedActive = False, index = 0, items = [] }
                        elements
                      ).items
                    , [ viewOther (active && parentActive) t1 ]
                    ]

            Moved t0 t1 x t2 y t3 e t4 ->
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
                    [ [ viewOther (active && parentActive) t0
                      , viewFunctionName path (active && parentActive) "filled"
                      , text t1
                      , viewColorLiteral (active && parentActive) col
                      , text t2
                      ]
                    , shape parentActive
                    , [ viewOther (active && parentActive) t3 ]
                    ]

            Outlined t0 t1 col t2 shape t3 ->
                List.concat
                    [ [ viewOther (active && parentActive) t0
                      , viewFunctionName path (active && parentActive) "outlined"
                      , text t1
                      , viewColorLiteral (active && parentActive) col
                      , text t2
                      ]
                    , shape parentActive
                    , [ viewOther (active && parentActive) t3 ]
                    ]

            Circle t0 t1 r t2 ->
                if active then
                    [ viewOther parentActive t0
                    , viewFunctionName path parentActive "circle"
                    , text t1
                    , viewIntLiteral parentActive r
                    , viewOther parentActive t2
                    ]

                else
                    [ viewFunctionName path parentActive "emptyStencil" ]

            Rectangle t0 t1 w t2 h t3 ->
                if active then
                    [ viewOther parentActive t0
                    , viewFunctionName path parentActive "rectangle"
                    , text t1
                    , viewIntLiteral parentActive w
                    , text t2
                    , viewIntLiteral parentActive h
                    , viewOther parentActive t3
                    ]

                else
                    [ viewFunctionName path parentActive "emptyStencil" ]

            EmptyStencil t0 t1 ->
                [ viewOther parentActive t0
                , viewOther parentActive "emptyStencil"
                , viewOther parentActive t1
                ]

            EmptyPicture t0 t1 ->
                [ viewOther parentActive t0
                , viewOther parentActive "emptyPicture"
                , viewOther parentActive t1
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


viewListItem :
    Bool
    -> List Int
    -> ListElement (Bool -> List (Html Msg))
    -> { prefixedActive : Bool, index : Int, items : List (Html Msg) }
    -> { prefixedActive : Bool, index : Int, items : List (Html Msg) }
viewListItem parentActive path { prefix, expression, active } { prefixedActive, index, items } =
    { prefixedActive = active || prefixedActive
    , index = index + 1
    , items =
        List.concat
            [ items
            , [ viewListSyntax path
                    index
                    { recieveEvents = parentActive
                    , renderActive =
                        parentActive
                            && ((if prefixedActive then
                                    active

                                 else
                                    False
                                )
                                    || index
                                    == 0
                               )
                    }
                    prefix
              ]
            , expression (parentActive && active)
            ]
    }


viewListSyntax : List Int -> Int -> { recieveEvents : Bool, renderActive : Bool } -> String -> Html Msg
viewListSyntax path index { recieveEvents, renderActive } content =
    span
        (List.concat
            [ [ classes
                    [ "hover:bg-gruv-gray-3 cursor-pointer"
                    , if renderActive then
                        ""

                      else
                        "text-gruv-gray-6"
                    ]
              ]
            , if recieveEvents then
                [ Events.onClick (ToggleListElement path index) ]

              else
                []
            ]
        )
        [ text content ]
