module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Language.InteractiveElm as InteractiveElm
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


type CodeSnippet
    = JsInteractive String
    | ElmInteractive String


{-| Extracts "interactive" snippets
-}
extractCodeSnippets : List Markdown.Block.Block -> List CodeSnippet
extractCodeSnippets =
    List.concatMap
        (\block ->
            case block of
                Markdown.Block.CodeBlock info ->
                    case info.language of
                        Just "js interactive" ->
                            [ JsInteractive info.body ]

                        Just "elm interactive" ->
                            [ ElmInteractive info.body ]

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


checkCodeSnippet : CodeSnippet -> Result String ()
checkCodeSnippet snippet =
    let
        discard =
            Result.map (\_ -> ())
    in
    case snippet of
        JsInteractive str ->
            discard (InteractiveJs.parse str)

        ElmInteractive str ->
            discard (InteractiveElm.parse str)


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
                , removeElement
                , infoElement
                , marginParagraph
                ]
        , renderMarkdown = View.markdown []
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


dummy tagName =
    Markdown.Html.tag tagName
        (\_ _ _ children ->
            Html.div [] children
        )
        |> Markdown.Html.withOptionalAttribute "src"
        |> Markdown.Html.withOptionalAttribute "alt"
        |> Markdown.Html.withOptionalAttribute "id"
