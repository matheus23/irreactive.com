module App exposing (..)

import Dict exposing (Dict)
import Http
import MarkdownComponents.Carusel as Carusel
import MarkdownComponents.Helper as MarkdownComponent
import Url.Builder as Url


{-| Name Ideas:

  - Mighty Monoid?

  - something using:
    Explorable? Interactive? Compositional?
    Monoid? Reactive? Applicative?

-}
siteName : String
siteName =
    "Irreactive"


siteTagline : String
siteTagline =
    "A Blog About Graphics and Functional Programming"


type alias Model =
    { subscriptionEmail : String
    , carusels : Dict String Carusel.Model
    }


init : ( Model, Cmd Msg )
init =
    ( { subscriptionEmail = ""
      , carusels = Dict.empty
      }
    , Cmd.none
    )


type Msg
    = NoOp
    | SubmitEmailSubscription
    | SubscribeEmailAddressChange String
    | SubscriptionEmailSubmitted (Result Http.Error ())
    | CaruselMsg String Carusel.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SubmitEmailSubscription ->
            ( model
            , Http.request
                { method = "POST"
                , headers = [ Http.header "Content-Type" "application/x-www-form-urlencoded" ]
                , url =
                    Url.relative []
                        [ Url.string "form-name" "email-subscription"
                        , Url.string "email" model.subscriptionEmail
                        ]
                , body = Http.emptyBody
                , expect = Http.expectWhatever SubscriptionEmailSubmitted
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        SubscribeEmailAddressChange subscriptionEmail ->
            ( { model | subscriptionEmail = subscriptionEmail }, Cmd.none )

        SubscriptionEmailSubmitted _ ->
            ( { model | subscriptionEmail = "" }, Cmd.none )

        CaruselMsg caruselId caruselMsg ->
            let
                ( caruselsUpdated, cmds ) =
                    MarkdownComponent.update
                        Carusel.init
                        caruselId
                        (Carusel.update caruselMsg)
                        model.carusels
            in
            ( { model | carusels = caruselsUpdated }
            , Cmd.map (CaruselMsg caruselId) cmds
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
