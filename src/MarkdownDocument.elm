module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block exposing (ListItem(..))
import Markdown.Html
import Markdown.Parser as Markdown
import Markdown.Renderer as Markdown
import Markdown.Scaffolded as Scaffolded
import MarkdownComponents.Carousel as Carousel
import MarkdownComponents.Helper as MarkdownComponents
import Metadata exposing (Metadata)
import Result.Extra as Result
import String.Extra as String
import View


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"



-- TODO: Do link checking at some point via StaticHttp.Request, but do this as a
-- pass before rendering, and keep rendering having a (Model -> Html Msg) type


document =
    { extension = "md"
    , metadata = Metadata.decoder
    , body =
        Markdown.parse
            >> Result.mapError deadEndsToString
            >> Result.andThen (Markdown.render customHtmlRenderer)
    }


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


customHtmlRenderer : Markdown.Renderer (Model -> Html Msg)
customHtmlRenderer =
    Scaffolded.toRenderer
        { renderHtml =
            Markdown.Html.oneOf
                [ -- anythingCaptioned "img" []
                  -- , anythingCaptioned "video" [ Attr.controls True ]
                  -- , carousel
                  -- , markdownEl
                  -- TODO Implement carousel, etc. with custom elements
                  liftRenderer (dummy "imgcaptioned")
                , liftRenderer (dummy "videocaptioned")
                , liftRenderer (dummy "carousel")
                , liftRenderer (dummy "markdown")
                , liftRenderer removeElement
                , liftRenderer infoElement
                , liftRenderer marginParagraph
                ]
        , renderMarkdown =
            \block env ->
                Scaffolded.foldFunction block env
                    |> View.markdown []
        }


removeElement : Markdown.Html.Renderer (List (Html Msg) -> Html Msg)
removeElement =
    Markdown.Html.tag "remove" (View.removeCard [])
        |> Markdown.Html.withOptionalAttribute "reason"


infoElement : Markdown.Html.Renderer (List (Html Msg) -> Html Msg)
infoElement =
    Markdown.Html.tag "info" (View.infoCard [])
        |> Markdown.Html.withAttribute "title"


marginParagraph : Markdown.Html.Renderer (List (Html Msg) -> Html Msg)
marginParagraph =
    Markdown.Html.tag "in-margin" (View.marginParagraph [])


liftRenderer : Markdown.Html.Renderer (List a -> a) -> Markdown.Html.Renderer (List (env -> a) -> env -> a)
liftRenderer =
    Markdown.Html.map (\render children model -> render (applyModel model children))


dummy tagName =
    Markdown.Html.tag tagName
        (\_ _ _ children ->
            Html.div [] children
        )
        |> Markdown.Html.withOptionalAttribute "src"
        |> Markdown.Html.withOptionalAttribute "alt"
        |> Markdown.Html.withOptionalAttribute "id"
