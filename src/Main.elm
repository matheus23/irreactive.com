module Main exposing (main)

import App exposing (..)
import Color
import Date
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import MarkdownDocument
import Metadata exposing (Metadata)
import Pages exposing (images, pages)
import Pages.ImagePath as ImagePath
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath as PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import View


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


main : Pages.Platform.Program Model Msg Metadata (List (Html Msg))
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
        |> Pages.Platform.toProgram


pageView :
    List ( PagePath Pages.PathKey, Metadata )
    -> { path : PagePath Pages.PathKey, frontmatter : Metadata }
    -> List (Html Msg)
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
                    , View.document Html.article content
                    , viewFooter model
                    ]
            }

        Metadata.Article metadata ->
            { title = metadata.title
            , body =
                View.body []
                    [ View.header page.path
                    , View.accentLine
                    , View.document Html.article
                        (List.concat
                            [ [ Html.h1 [ Attr.class "post-title" ] [ Html.text metadata.title ]
                              , Html.section [ Attr.class "header" ]
                                    [ View.articleMetadata metadata
                                    , Html.img
                                        [ Attr.src (ImagePath.toString metadata.image)
                                        , Attr.alt "Post cover photo"
                                        ]
                                        []
                                    ]
                              ]
                            , content
                            , [ viewGithubEditLink page.path ]
                            ]
                        )
                    , viewFooter model
                    ]
            }

        Metadata.BlogIndex ->
            { title = siteName
            , body =
                View.body []
                    [ View.header page.path
                    , View.accentLine
                    , siteMetadata
                        |> filterArticles
                        |> List.map View.postPreview
                        |> View.document Html.ul
                    , viewFooter model
                    ]
            }


filterArticles : List ( PagePath Pages.PathKey, Metadata ) -> List ( PagePath Pages.PathKey, Metadata.ArticleMetadata )
filterArticles =
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


viewFooter : Model -> Html Msg
viewFooter model =
    View.blogFooter
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


viewGithubEditLink : PagePath Pages.PathKey -> Html msg
viewGithubEditLink path =
    Html.section [ Attr.class "edit-on-github" ]
        [ Html.text "Found a typo? "
        , Html.a
            [ Attr.style "text-decoration" "underline"

            -- , Attr.style "color" Palette.color.primary
            , Attr.href (githubRepo ++ "/blob/master/content/" ++ PagePath.toString path ++ ".md")
            ]
            [ Html.text "Edit this page GitHub." ]
        ]


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
