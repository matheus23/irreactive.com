module App exposing (..)

import Dict exposing (Dict)
import Http
import MarkdownComponents.Carousel as Carousel
import MarkdownComponents.Helper as MarkdownComponent
import Ports
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


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://philippkruegerblog.netlify.com/"


githubRepo : String
githubRepo =
    "https://github.com/matheus23/website"


type alias Model =
    { subscriptionEmail : String
    , emailStatus : SubscriptionStatus
    , carousels : Dict String Carousel.Model
    }


type SubscriptionStatus
    = NotSubmittedYet
    | EmailMissing
    | SubmitSuccessful
    | SubmitBadStatus Int
    | SubmitNoNetwork
    | SubmitInternalError


init : ( Model, Cmd Msg )
init =
    ( { subscriptionEmail = ""
      , emailStatus = NotSubmittedYet
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
            if model.subscriptionEmail |> String.isEmpty then
                ( { model
                    | emailStatus = EmailMissing
                  }
                , Ports.scrollToBottom ()
                )

            else
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
                    , timeout = Just 5000
                    , tracker = Nothing
                    }
                )

        SubscribeEmailAddressChange subscriptionEmail ->
            ( { model | subscriptionEmail = subscriptionEmail }, Cmd.none )

        SubscriptionEmailSubmitted result ->
            case result of
                Ok () ->
                    ( { model
                        | subscriptionEmail = ""
                        , emailStatus = SubmitSuccessful
                      }
                    , Ports.scrollToBottom ()
                    )

                Err httpErr ->
                    ( { model
                        | emailStatus =
                            case httpErr of
                                Http.BadStatus status ->
                                    SubmitBadStatus status

                                Http.Timeout ->
                                    SubmitNoNetwork

                                Http.NetworkError ->
                                    SubmitNoNetwork

                                Http.BadUrl _ ->
                                    SubmitInternalError

                                Http.BadBody _ ->
                                    SubmitInternalError
                      }
                    , Ports.scrollToBottom ()
                    )

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
