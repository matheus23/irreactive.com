module Main exposing (main)

import App exposing (..)
import Color
import Date
import Feed
import Head
import Head.Seo as Seo
import Html exposing (Html)
import IrreactiveSitemap
import MarkdownDocument
import Metadata exposing (Metadata)
import Pages exposing (images, pages)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import View


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just (Color.rgb255 249 245 215)
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = siteName ++ " - " ++ siteTagline
    , iarcRatingId = Nothing
    , name = siteName
    , themeColor = Just (Color.rgb255 214 93 14)
    , startUrl = pages.index
    , shortName = Just siteName
    , sourceIcon = images.icons.favicon
    }


type alias PageView =
    Model -> List (Html Msg)


main : Pages.Platform.Program Model Msg Metadata PageView
main =
    Pages.Platform.init
        { init = \_ -> init
        , view =
            \siteMetadata page ->
                StaticHttp.succeed
                    { view = \model viewDocument -> pageView siteMetadata page viewDocument model
                    , head = head page.frontmatter
                    }
        , update = update
        , subscriptions = subscriptions
        , documents = [ MarkdownDocument.document ]
        , onPageChange = Nothing
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , internals = Pages.internals
        }
        |> Pages.Platform.withFileGenerator generateFiles
        |> Pages.Platform.toProgram


generateFiles :
    List
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        , body : String
        }
    ->
        StaticHttp.Request
            (List
                (Result String
                    { path : List String
                    , content : String
                    }
                )
            )
generateFiles siteMetadata =
    StaticHttp.succeed
        [ Feed.fileToGenerate { siteTagline = siteTagline, siteUrl = canonicalSiteUrl } siteMetadata |> Ok
        , IrreactiveSitemap.build { siteUrl = canonicalSiteUrl } siteMetadata |> Ok
        ]


pageView :
    List ( PagePath Pages.PathKey, Metadata )
    -> { path : PagePath Pages.PathKey, frontmatter : Metadata }
    -> PageView
    -> Model
    -> { title : String, body : Html Msg }
pageView siteMetadata page content model =
    case page.frontmatter of
        Metadata.Page metadata ->
            { title = metadata.title
            , body =
                View.body []
                    [ View.header page.path
                    , View.accentLine
                    , View.document Html.article "text-gruv-gray-1" (content model)
                    , viewFooter model
                    , View.gotEmailNotification
                        { state = model.gotEmailNotificationActive
                        , onClickDismiss = DismissGotEmailNotification
                        }
                    ]
            }

        Metadata.Article metadata ->
            { title = metadata.title
            , body =
                View.body []
                    [ View.header page.path
                    , View.accentLine
                    , View.document Html.article
                        "text-gruv-gray-1"
                        (View.decorateArticle
                            { path = page.path
                            , metadata = metadata
                            , content = content model
                            }
                        )
                    , viewFooter model
                    , View.gotEmailNotification
                        { state = model.gotEmailNotificationActive
                        , onClickDismiss = DismissGotEmailNotification
                        }
                    ]
            }

        Metadata.BlogIndex ->
            { title = siteName
            , body =
                View.body []
                    [ View.header page.path
                    , View.accentLine
                    , siteMetadata
                        |> articleList
                        |> List.map View.postPreview
                        |> View.document Html.ul "text-gruv-gray-6"
                    , viewFooter model
                    , View.gotEmailNotification
                        { state = model.gotEmailNotificationActive
                        , onClickDismiss = DismissGotEmailNotification
                        }
                    ]
            }


articleList : List ( PagePath Pages.PathKey, Metadata ) -> List ( PagePath Pages.PathKey, Metadata.ArticleMetadata )
articleList =
    let
        filterArticle ( path, metadata ) =
            case metadata of
                Metadata.Article meta ->
                    if meta.draft then
                        Nothing

                    else
                        Just ( path, meta )

                _ ->
                    Nothing
    in
    List.filterMap filterArticle
        >> List.sortBy
            (\( _, article ) ->
                article.published |> Date.toRataDie |> negate
            )


viewFooter : Model -> Html Msg
viewFooter model =
    View.footer
        { onSubmit = SubmitEmailSubscription
        , onInput = SubscribeEmailAddressChange
        , model = model.subscriptionEmail
        , errorText =
            case model.emailStatus of
                SubmitSuccessful ->
                    ""

                NotSubmittedYet ->
                    ""

                EmailMissing ->
                    "Whoops! You need to enter an E-Mail address."

                SubmitNoNetwork ->
                    "Hmm. We couldn't connect to our servers. Are you perhaps offline?"

                SubmitBadStatus code ->
                    "Oh, here seems to be something wrong with our servers (status code: " ++ String.fromInt code ++ ")"

                SubmitInternalError ->
                    "Oh, there was some internal error. Please tell me about it."
        , submitSuccess = model.emailStatus == SubmitSuccessful
        }


{-| <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
<https://htmlhead.dev>
<https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
<https://ogp.me/>
-}
head : Metadata -> List (Head.Tag Pages.PathKey)
head metadata =
    List.concat
        [ [ Head.rssLink ("/" ++ String.join "/" Feed.path)
          , Head.sitemapLink "/sitemap.xml"
          ]
        , metadataHeadTags metadata
        ]


metadataHeadTags : Metadata -> List (Head.Tag Pages.PathKey)
metadataHeadTags metadata =
    case metadata of
        Metadata.Page meta ->
            Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = siteName
                , image =
                    { url = images.icons.faviconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = siteName ++ " - " ++ meta.title
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
                    { url = images.icons.faviconPng
                    , alt = siteName ++ " logo"
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = siteTagline
                , locale = Nothing
                , title = siteName ++ " - all posts"
                }
                |> Seo.website
