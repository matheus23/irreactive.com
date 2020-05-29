module Components.CodeInteractiveElm exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (attribute, class)
import Html.Events as Events
import Json.Decode as Decode
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
                [ text "Expect code to show up here." ]
            ]
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
