module Index exposing (view)

import Html exposing (Html)
import Metadata exposing (Metadata)
import Pages
import Pages.PagePath exposing (PagePath)
import View


view : List ( PagePath Pages.PathKey, Metadata ) -> Html msg
view pages =
    View.articleList []
        (List.concatMap viewOnlyArticles pages)


viewOnlyArticles : ( PagePath Pages.PathKey, Metadata ) -> List (Html msg)
viewOnlyArticles ( path, metadata ) =
    case metadata of
        Metadata.Article meta ->
            if meta.draft then
                []

            else
                [ View.postPreview ( path, meta ) ]

        _ ->
            []
