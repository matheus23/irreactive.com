module Main exposing (main)

import Color
import Date
import Element exposing (Element)
import Element.Border
import Element.Font as Font
import Element.Region
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Index
import MarkdownDocument
import Metadata exposing (Metadata)
import Pages exposing (images, pages)
import Pages.Directory as Directory exposing (Directory)
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform exposing (Page)
import Palette


siteName : String
siteName =
    "Philipp Krüger's Blog"


siteTagline : String
siteTagline =
    "Graphics and Functional Programming"


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = siteName ++ " - " ++ siteTagline
    , iarcRatingId = Nothing
    , name = siteName
    , themeColor = Just Color.white
    , startUrl = pages.index
    , shortName = Just siteName
    , sourceIcon = images.iconPng
    }


type alias Rendered =
    Element Msg



-- the intellij-elm plugin doesn't support type aliases for Programs so we need to use this line
-- main : Platform.Program Pages.Platform.Flags (Pages.Platform.Model Model Msg Metadata Rendered) (Pages.Platform.Msg Msg Metadata Rendered)


main : Pages.Platform.Program Model Msg Metadata Rendered
main =
    Pages.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , documents = [ MarkdownDocument.document ]
        , head = head
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        }


type alias Model =
    { subscriptionEmail : String }


init : ( Model, Cmd Msg )
init =
    ( Model "", Cmd.none )


type Msg
    = SubmitEmailSubscription
    | SubscribeEmailAddressChange String
    | SubscriptionEmailSubmitted (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmitEmailSubscription ->
            ( model
            , Http.request
                { method = "POST"
                , headers = [ Http.header "Content-Type" "application/x-www-form-urlencoded" ]
                , url = "/?form-name=email-subscription&email=" ++ model.subscriptionEmail
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


view : Model -> List ( PagePath Pages.PathKey, Metadata ) -> Page Metadata Rendered Pages.PathKey -> { title : String, body : Html Msg }
view model siteMetadata page =
    let
        { title, body } =
            pageView model siteMetadata page
    in
    { title = title
    , body =
        body
            |> Element.layout
                [ Element.width Element.fill
                , Font.size 20
                , Font.family [ Font.typeface "Roboto" ]
                , Font.color (Element.rgba255 0 0 0 0.8)
                ]
    }


pageView : Model -> List ( PagePath Pages.PathKey, Metadata ) -> Page Metadata Rendered Pages.PathKey -> { title : String, body : Element Msg }
pageView model siteMetadata page =
    let
        renderGithubEditLink path =
            [ Element.row [ Font.size 16, Font.color (Element.rgb 0.4 0.4 0.4) ]
                [ Element.text "Found a typo? "
                , Element.link [ Font.underline, Font.color Palette.color.primary ]
                    { label = Element.text "Edit this page GitHub."
                    , url = githubRepo ++ "/edit/master/content" ++ PagePath.toString path ++ ".md"
                    }
                ]
            ]
    in
    case page.metadata of
        Metadata.Page metadata ->
            { title = metadata.title
            , body =
                [ header page.path
                , Element.column
                    [ Element.padding 50
                    , Element.spacing 60
                    , Element.Region.mainContent
                    ]
                    [ page.view
                    ]
                ]
                    |> Element.textColumn
                        [ Element.width Element.fill
                        ]
            }

        Metadata.Article metadata ->
            { title = metadata.title
            , body =
                Element.column [ Element.width Element.fill ]
                    [ header page.path
                    , Element.column
                        [ Element.padding 30
                        , Element.spacing 40
                        , Element.Region.mainContent
                        , Element.width (Element.fill |> Element.maximum 800)
                        , Element.centerX
                        ]
                        (Element.row
                            [ Element.spacing 10
                            , Element.centerX
                            , Font.size 16
                            , Font.color (Element.rgb 0.4 0.4 0.4)
                            ]
                            [ Element.text metadata.author
                            , Element.text "•"
                            , Element.text (metadata.published |> Date.format "MMMM ddd, yyyy")
                            ]
                            :: Palette.blogHeading metadata.title
                            :: articleImageView metadata.image
                            :: page.view
                            :: renderGithubEditLink page.path
                        )
                    , footer model
                    ]
            }

        Metadata.BlogIndex ->
            { title = siteName
            , body =
                Element.column [ Element.width Element.fill ]
                    [ header page.path
                    , Element.column [ Element.padding 20, Element.centerX ] [ Index.view siteMetadata ]
                    , footer model
                    ]
            }


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.image [ Element.width Element.fill ]
        { src = ImagePath.toString articleImage
        , description = "Article cover photo"
        }


header : PagePath Pages.PathKey -> Element msg
header currentPath =
    Element.column [ Element.width Element.fill ]
        [ Element.row
            [ Element.paddingXY 25 4
            , Element.spaceEvenly
            , Element.width Element.fill
            , Element.Region.navigation
            , Element.Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Element.Border.color (Element.rgba255 40 80 40 0.4)
            ]
            [ Element.link []
                { url = "/"
                , label =
                    Element.row [ Font.size 30, Element.spacing 16 ]
                        [ Element.text siteName
                        ]
                }
            , Element.row [ Element.spacing 15 ]
                [ githubRepoLink
                , highlightableLink currentPath pages.blog.directory "All Posts"
                ]
            ]
        ]


footer : Model -> Element Msg
footer model =
    Element.el
        [ Element.padding 20
        , Element.Region.footer
        , Element.width (Element.fill |> Element.maximum 800)
        , Element.centerX
        ]
        (Element.html
            (Html.form
                [ Attr.name "email-subscription"
                , Attr.method "POST"
                , Attr.attribute "data-netlify" "true"
                , Events.onSubmit SubmitEmailSubscription
                ]
                [ Html.p []
                    [ Html.label [ Attr.for "email" ]
                        [ Html.text "Get an E-Mail for every new Post:" ]
                    ]
                , Html.p []
                    [ Html.input
                        [ Attr.type_ "email"
                        , Attr.name "email"
                        , Attr.placeholder "your email address"
                        , Events.onInput SubscribeEmailAddressChange
                        , Attr.value model.subscriptionEmail
                        ]
                        []
                    , Html.button [ Attr.type_ "submit" ] [ Html.text "Get Notified" ]
                    ]
                ]
            )
        )


highlightableLink :
    PagePath Pages.PathKey
    -> Directory Pages.PathKey Directory.WithIndex
    -> String
    -> Element msg
highlightableLink currentPath linkDirectory displayName =
    let
        isHighlighted =
            currentPath |> Directory.includes linkDirectory
    in
    Element.link
        (if isHighlighted then
            []

         else
            [ Font.underline
            , Font.color Palette.color.primary
            ]
        )
        { url = linkDirectory |> Directory.indexPath |> PagePath.toString
        , label = Element.text displayName
        }


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : Metadata -> List (Head.Tag Pages.PathKey)
head metadata =
    case metadata of
        Metadata.Page meta ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = images.iconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = meta.title
                }
                |> Seo.website

        Metadata.Article meta ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = meta.image
                    , alt = meta.description
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = meta.description
                , locale = Nothing
                , title = meta.title
                }
                |> Seo.article
                    { tags = []
                    , section = Nothing
                    , publishedTime = Just (Date.toIsoString meta.published)
                    , modifiedTime = Nothing
                    , expirationTime = Nothing
                    }

        Metadata.BlogIndex ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = images.iconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = siteName ++ " - all posts"
                }
                |> Seo.website


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://TODO.netlify.com/"


githubRepo : String
githubRepo =
    "https://github.com/matheus23/website"


githubRepoLink : Element msg
githubRepoLink =
    Element.newTabLink []
        { url = githubRepo
        , label =
            Element.image
                [ Element.width (Element.px 22)
                , Font.color Palette.color.primary
                ]
                { src = ImagePath.toString Pages.images.github, description = "Github repo" }
        }
