module Index exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr exposing (class)
import Metadata exposing (Metadata)
import Pages
import Pages.PagePath as PagePath exposing (PagePath)
import Palette


view : List ( PagePath Pages.PathKey, Metadata ) -> Html msg
view pages =
    Html.ul [ class "posts-list" ]
        (List.concatMap viewOnlyArticles pages)


viewOnlyArticles : ( PagePath Pages.PathKey, Metadata ) -> List (Html msg)
viewOnlyArticles ( path, metadata ) =
    case metadata of
        Metadata.Article meta ->
            if meta.draft then
                []

            else
                [ postPreview ( path, meta ) ]

        _ ->
            []


postLinked : PagePath Pages.PathKey -> List (Html msg) -> Html msg
postLinked postPath =
    Html.a [ Attr.href (PagePath.toString postPath) ]


postPreview : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postPreview ( postPath, post ) =
    Html.li [ class "post-preview" ]
        [ Html.h2 [] [ postLinked postPath [ Html.text post.title ] ]
        , Palette.viewArticleMetadata post
        , Html.p [ class "description" ] [ postLinked postPath [ Html.text post.description ] ]
        , Html.p [ class "read-more" ] [ postLinked postPath [ Html.text "Read More" ] ]
        ]
