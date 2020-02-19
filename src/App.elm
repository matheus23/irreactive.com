module App exposing (..)

import Browser.Dom exposing (Viewport)
import Dict exposing (Dict)
import Http
import Result.Extra as Result
import Task
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
    , carusels : Dict String CaruselModel
    }


type alias CaruselModel =
    { scrollPosition : Float }


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
    | CaruselOnScroll String
    | CaruselGetViewport String Viewport


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

        CaruselOnScroll caruselId ->
            ( model
            , Browser.Dom.getViewportOf caruselId
                |> Task.attempt
                    (Result.mapBoth
                        -- Err
                        (\_ -> NoOp)
                        -- Ok
                        (CaruselGetViewport caruselId)
                        >> Result.merge
                    )
            )

        CaruselGetViewport caruselId { scene, viewport } ->
            ( updateCarusel caruselId
                (\_ -> { scrollPosition = viewport.x / (scene.width - viewport.width) })
                model
            , Cmd.none
            )


updateCarusel : String -> (CaruselModel -> CaruselModel) -> Model -> Model
updateCarusel id updater model =
    { model
        | carusels =
            model.carusels
                |> Dict.update id
                    (\caruselModel ->
                        caruselModel
                            |> Maybe.withDefault { scrollPosition = 0 }
                            |> updater
                            |> Just
                    )
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
