module Components.Ama exposing (Model, Msg, init, update, view)

import Html exposing (Html)


type alias Model =
    {}


type Msg
    = Msg


init : Model
init =
    {}


update : Msg -> Model -> Model
update _ m =
    m


view : (Msg -> msg) -> Model -> List (Html msg) -> Html msg
view produceMsg children model =
    Html.div [] [ Html.text "Put your question here" ]
