module Index exposing (view)

import Date
import Html exposing (Html)
import Html.Attributes as Attr
import Metadata exposing (Metadata)
import Pages
import Pages.PagePath as PagePath exposing (PagePath)


view : List ( PagePath Pages.PathKey, Metadata ) -> Html msg
view posts =
    Html.ul []
        (posts
            |> List.filterMap
                (\( path, metadata ) ->
                    case metadata of
                        Metadata.Page _ ->
                            Nothing

                        Metadata.Article meta ->
                            if meta.draft then
                                Nothing

                            else
                                Just ( path, meta )

                        Metadata.BlogIndex ->
                            Nothing
                )
            |> List.map postSummary
        )


postSummary : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postSummary ( postPath, post ) =
    linkToPost postPath (postPreview post)


linkToPost : PagePath Pages.PathKey -> List (Html msg) -> Html msg
linkToPost postPath =
    Html.a [ Attr.href (PagePath.toString postPath) ]


title : String -> Html msg
title text =
    Html.h2 []
        [ Html.text text ]


readMoreLink : Html msg
readMoreLink =
    Html.a [] [ Html.text "Continue reading >>" ]


postPreview : Metadata.ArticleMetadata -> List (Html msg)
postPreview post =
    [ title post.title
    , Html.section []
        [ Html.text post.author
        , Html.text "•"
        , Html.time [] [ Html.text (Date.format "MMMM ddd, yyyy" post.published) ]
        ]
    , Html.text post.description
    , readMoreLink
    ]
