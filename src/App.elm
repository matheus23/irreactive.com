module App exposing (..)

import Http
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
    { subscriptionEmail : String }


init : ( Model, Cmd Msg )
init =
    ( Model "", Cmd.none )


type Msg
    = SubmitEmailSubscription
    | SubscribeEmailAddressChange String
    | SubscriptionEmailSubmitted (Result Http.Error ())
    | NoOp


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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
