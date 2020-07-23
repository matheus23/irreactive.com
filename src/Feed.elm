module Feed exposing (fileToGenerate, path)

import Metadata exposing (Metadata(..))
import Pages
import Pages.PagePath as PagePath exposing (PagePath)
import Rss


path : List String
path =
    [ "feed.xml" ]


fileToGenerate :
    { siteTagline : String
    , siteUrl : String
    }
    ->
        List
            { path : PagePath Pages.PathKey
            , frontmatter : Metadata
            , body : String
            }
    ->
        { path : List String
        , content : String
        }
fileToGenerate config siteMetadata =
    { path = path
    , content = generate config siteMetadata
    }


generate :
    { siteTagline : String
    , siteUrl : String
    }
    ->
        List
            { path : PagePath Pages.PathKey
            , frontmatter : Metadata
            , body : String
            }
    -> String
generate { siteTagline, siteUrl } siteMetadata =
    Rss.generate
        { title = "Irreactive"
        , description = siteTagline
        , url = "https://irreactive.com"
        , lastBuildTime = Pages.builtAt
        , generator = Just "elm-pages"
        , items = siteMetadata |> List.filterMap metadataToRssItem
        , siteUrl = siteUrl
        }


metadataToRssItem :
    { path : PagePath Pages.PathKey
    , frontmatter : Metadata
    , body : String
    }
    -> Maybe Rss.Item
metadataToRssItem page =
    case page.frontmatter of
        Article article ->
            if article.draft then
                Nothing

            else
                Just
                    { title = article.title
                    , description = article.description
                    , url = PagePath.toString page.path
                    , categories = []
                    , author = "Philipp Krüger"
                    , pubDate = Rss.Date article.published
                    , content = Nothing
                    }

        _ ->
            Nothing
