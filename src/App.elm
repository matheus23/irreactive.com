module App exposing (..)

import Dict exposing (Dict)
import Http
import MarkdownComponents.Carousel as Carousel
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
    , carousels : Dict String Carousel.Model
    }


init : ( Model, Cmd Msg )
init =
    ( { subscriptionEmail = ""
      , carousels = Dict.empty
      }
    , Cmd.none
    )


type Msg
    = NoOp
    | SubmitEmailSubscription
    | SubscribeEmailAddressChange String
    | SubscriptionEmailSubmitted (Result Http.Error ())
    | CarouselMsg String Carousel.Msg


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

        CarouselMsg carouselId carouselMsg ->
            let
                ( carouselsUpdated, cmds ) =
                    MarkdownComponent.update
                        Carousel.init
                        carouselId
                        (Carousel.update carouselId carouselMsg)
                        model.carousels
            in
            ( { model | carousels = carouselsUpdated }
            , Cmd.map (CarouselMsg carouselId) cmds
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
