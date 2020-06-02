module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Decode exposing (Decoder)
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


type alias View =
    List Int -> Model -> Html Msg


document :
    { extension : String
    , metadata : Decoder Metadata
    , body : String -> Result String (Model -> List (Html Msg))
    }
document =
    { extension = "md"
    , metadata = Metadata.decoder
    , body =
        Markdown.parse
            >> Result.mapError deadEndsToString
            >> Result.andThen (Markdown.render customHtmlRenderer)
            >> Result.map finalizeView
    }


finalizeView : List View -> Model -> List (Html Msg)
finalizeView content model =
    content
        |> List.indexedMap
            (\index view -> view [ index ] model)


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


customHtmlRenderer : Markdown.Renderer View
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
        , renderMarkdown = reduceMarkdown
        }


reduceMarkdown : Scaffolded.Block View -> View
reduceMarkdown block path model =
    Scaffolded.foldFunction
        (Scaffolded.foldFunction block path)
        model
        |> View.markdown []


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


liftRenderer :
    Markdown.Html.Renderer (List (Html Msg) -> Html Msg)
    -> Markdown.Html.Renderer (List View -> View)
liftRenderer =
    Markdown.Html.map
        (\render children path model ->
            children
                |> List.indexedMap
                    (\index view ->
                        view (index :: path) model
                    )
                |> render
        )


dummy tagName =
    Markdown.Html.tag tagName
        (\_ _ _ children ->
            Html.div [] children
        )
        |> Markdown.Html.withOptionalAttribute "src"
        |> Markdown.Html.withOptionalAttribute "alt"
        |> Markdown.Html.withOptionalAttribute "id"


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"
