module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Language.InteractiveJs as InteractiveJs
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
            >> Result.andThen checkCodeSnippets
            >> Result.andThen (Markdown.render customHtmlRenderer)
    }


{-| Extracts only "js interactive" snippets as of yet
-}
extractCodeSnippets : List Markdown.Block.Block -> List String
extractCodeSnippets =
    List.concatMap
        (\block ->
            case block of
                Markdown.Block.CodeBlock info ->
                    case info.language of
                        Just "js interactive" ->
                            [ info.body ]

                        _ ->
                            []

                Markdown.Block.HtmlBlock (Markdown.Block.HtmlElement _ _ children) ->
                    extractCodeSnippets children

                _ ->
                    []
        )


checkCodeSnippets : List Markdown.Block.Block -> Result String (List Markdown.Block.Block)
checkCodeSnippets blocks =
    extractCodeSnippets blocks
        |> Result.combineMap checkCodeSnippet
        |> Result.map (always blocks)


checkCodeSnippet : String -> Result String ()
checkCodeSnippet str =
    InteractiveJs.parse str
        |> Result.map (always ())


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


customHtmlRenderer : Markdown.Renderer (Html Msg)
customHtmlRenderer =
    Scaffolded.toRenderer
        { renderHtml =
            Markdown.Html.oneOf
                [ -- anythingCaptioned "img" []
                  -- , anythingCaptioned "video" [ Attr.controls True ]
                  -- , carousel
                  -- , markdownEl
                  -- TODO Implement carousel, etc. with custom elements
                  dummy "imgcaptioned"
                , dummy "videocaptioned"
                , dummy "carousel"
                , dummy "markdown"
                ]
        , renderMarkdown = View.markdown []
        }


dummy tagName =
    Markdown.Html.tag tagName
        (\_ _ _ children ->
            Html.div [] children
        )
        |> Markdown.Html.withOptionalAttribute "src"
        |> Markdown.Html.withOptionalAttribute "alt"
        |> Markdown.Html.withOptionalAttribute "id"


anythingCaptioned : String -> List (Html.Attribute msg) -> Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
anythingCaptioned tagName attributes =
    Markdown.Html.tag (tagName ++ "captioned")
        (\src alt idAttrs children model ->
            Html.figure idAttrs
                [ Html.node tagName (Attr.src src :: Attr.alt alt :: attributes) []
                , Html.figcaption [] (applyModel model children)
                ]
        )
        |> Markdown.Html.withAttribute "src"
        |> Markdown.Html.withAttribute "alt"
        |> withOptionalIdTag



-- carousel : Markdown.Html.Renderer (List (Model -> Html Msg) -> Model -> Html Msg)


carousel =
    Markdown.Html.tag "carousel"
        (\identifier children model ->
            Carousel.view (CarouselMsg identifier)
                identifier
                (MarkdownComponents.init Carousel.init identifier model.carousels)
                (applyModel model children)
        )
        |> Markdown.Html.withAttribute "id"



-- markdownEl : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)


markdownEl =
    Markdown.Html.tag "markdown"
        (\idAttrs children model ->
            Html.div
                (Attr.class "markdown" :: idAttrs)
                (applyModel model children)
        )
        |> withOptionalIdTag


withOptionalIdTag : Markdown.Html.Renderer (List (Html.Attribute msg) -> view) -> Markdown.Html.Renderer view
withOptionalIdTag rend =
    rend
        |> Markdown.Html.map
            (\continue maybeId ->
                case maybeId of
                    Just id ->
                        continue [ Attr.id id ]

                    Nothing ->
                        continue []
            )
        |> Markdown.Html.withOptionalAttribute "id"
