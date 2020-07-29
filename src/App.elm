module App exposing (..)

import Animator
import Animator.Css
import Components.Ama as Ama
import Components.CodeInteractiveElm as CodeInteractiveElm
import Components.CodeInteractiveJs as CodeInteractiveJs
import Dict exposing (Dict)
import Http
import MarkdownComponents.Carousel as Carousel
import MarkdownComponents.Helper as MarkdownComponent
import Ports
import Time
import Url.Builder as Url


siteName : String
siteName =
    "Irreactive"


siteTagline : String
siteTagline =
    "A Blog about User Interface- and Functional Programming"


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://irreactive.com/"


githubRepo : String
githubRepo =
    "https://github.com/matheus23/irreactive.com"


type alias Model =
    { subscriptionEmail : String
    , emailStatus : SubscriptionStatus
    , gotEmailNotificationActive : Animator.Timeline Bool
    , carousels : Dict String Carousel.Model
    , interactiveJs : Dict String CodeInteractiveJs.Model
    , interactiveElm : Dict String CodeInteractiveElm.Model
    , ama : Ama.Model
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
      , gotEmailNotificationActive = Animator.init False
      , carousels = Dict.empty
      , interactiveJs = Dict.empty
      , interactiveElm = Dict.empty
      , ama = Ama.init
      }
    , Cmd.none
    )


animator : Animator.Animator Model
animator =
    Animator.animator
        |> Animator.Css.watching
            .gotEmailNotificationActive
            (\newGotEmailNotificationActive model ->
                { model | gotEmailNotificationActive = newGotEmailNotificationActive }
            )


type Msg
    = NoOp
    | SubmitEmailSubscription
    | SubscribeEmailAddressChange String
    | SubscriptionEmailSubmitted (Result Http.Error ())
    | DismissGotEmailNotification
      -- Component Msgs
    | CarouselMsg String Carousel.Msg
    | InteractiveJsMsg String CodeInteractiveJs.Model CodeInteractiveJs.Msg
    | InteractiveElmMsg String CodeInteractiveElm.Model CodeInteractiveElm.Msg
    | AmaMsg Ama.Msg
      -- Animator
    | AnimatorTick Time.Posix


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
                        , gotEmailNotificationActive =
                            model.gotEmailNotificationActive
                                |> Animator.go Animator.slowly True
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

        DismissGotEmailNotification ->
            ( { model
                | gotEmailNotificationActive =
                    model.gotEmailNotificationActive
                        |> Animator.go Animator.slowly False
              }
            , Cmd.none
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

        InteractiveJsMsg elementId subInit subMsg ->
            let
                interactiveJsUpdated =
                    Dict.update elementId
                        (\subModel ->
                            subModel
                                |> Maybe.withDefault subInit
                                |> CodeInteractiveJs.update subMsg
                                |> Just
                        )
                        model.interactiveJs
            in
            ( { model | interactiveJs = interactiveJsUpdated }
            , Cmd.none
            )

        InteractiveElmMsg elementId subInit subMsg ->
            let
                interactiveElmUpdated =
                    Dict.update elementId
                        (\subModel ->
                            subModel
                                |> Maybe.withDefault subInit
                                |> CodeInteractiveElm.update subMsg
                                |> Just
                        )
                        model.interactiveElm
            in
            ( { model | interactiveElm = interactiveElmUpdated }
            , Cmd.none
            )

        AmaMsg amaMsg ->
            ( { model | ama = Ama.update amaMsg model.ama }
            , Cmd.none
            )

        AnimatorTick newTime ->
            ( Animator.update newTime animator model
            , Cmd.none
            )


pathToId : List Int -> String
pathToId path =
    path
        |> List.map String.fromInt
        |> String.join ","


subscriptions : Model -> Sub Msg
subscriptions model =
    Animator.toSubscription AnimatorTick model animator
