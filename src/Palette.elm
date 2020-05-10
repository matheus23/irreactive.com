module Palette exposing (..)

import Date
import Html exposing (Html)
import Html.Attributes as Attr
import Metadata


color : { primary : String, secondary : String }
color =
    { primary = "rgb(5,117,230)"
    , secondary = "rgb(0,242,96)"
    }


viewArticleMetadata : Metadata.ArticleMetadata -> Html msg
viewArticleMetadata { author, published } =
    Html.section [ Attr.class "meta" ]
        [ Html.text author
        , Html.text " • "
        , Html.time [] [ Html.text (published |> Date.format "MMMM ddd, yyyy") ]
        ]
