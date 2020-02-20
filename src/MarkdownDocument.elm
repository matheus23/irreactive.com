module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Html
import Markdown.Parser exposing (ListItem(..), defaultHtmlRenderer)
import MarkdownComponents.Carusel as Carusel
import MarkdownComponents.Helper as MarkdownComponents
import Metadata exposing (Metadata)
import Pages.Document
import Parser
import Parser.Advanced
import Result.Extra as Result
import String.Extra as String



-- TODO: Remove the Html rendering of markdown error messages.


render : Markdown.Parser.Renderer (Model -> Html Msg) -> String -> Result String (List (Model -> Html Msg))
render renderer markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapBoth
            (renderDeadEnds markdown >> Ok)
            (Markdown.Parser.render renderer)
        |> Result.merge


renderDeadEnds : String -> List (Parser.Advanced.DeadEnd String Parser.Problem) -> List (Model -> Html Msg)
renderDeadEnds input =
    let
        inputLines =
            String.split "\n" input
    in
    List.map (\deadEnd _ -> renderDeadEnd inputLines deadEnd)


renderDeadEnd : List String -> Parser.Advanced.DeadEnd String Parser.Problem -> Html msg
renderDeadEnd input { row, problem } =
    let
        linesPadding =
            2

        relevantLines =
            input
                |> List.drop (List.length input - row - linesPadding)
                |> List.take (linesPadding * 2 + 1)
    in
    Html.div []
        [ Html.pre []
            [ Html.text (String.concat (List.intersperse "\n" relevantLines)) ]
        , Html.text (Debug.toString problem)
        ]


document : ( String, Pages.Document.DocumentHandler Metadata (Model -> Html Msg) )
document =
    Pages.Document.parser
        { extension = "md"
        , metadata = Metadata.decoder
        , body =
            render customHtmlRenderer
                >> Result.map
                    (\children model ->
                        Html.main_ [ Attr.class "content" ]
                            (applyModel model children)
                    )
        }


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


customHtmlRenderer : Markdown.Parser.Renderer (Model -> Html Msg)
customHtmlRenderer =
    defaultHtmlRenderer
        |> bumpHeadings 1
        |> rendererReader
            (Markdown.Html.oneOf
                [ anythingCaptioned "img" []
                , anythingCaptioned "video" [ Attr.controls True ]
                , carusel
                , markdownEl
                ]
            )
            (\link content ->
                Ok <|
                    \r ->
                        Html.a [ Attr.href link.destination ] (applyModel r content)
            )


type alias LinkRenderer view =
    { title : Maybe String
    , destination : String
    }
    -> List view
    -> Result String view


rendererReader :
    Markdown.Html.Renderer (List (r -> view) -> r -> view)
    -> LinkRenderer (r -> view)
    -> Markdown.Parser.Renderer view
    -> Markdown.Parser.Renderer (r -> view)
rendererReader htmlRenderer linkRenderer renderer =
    { heading =
        \{ level, rawText, children } r ->
            renderer.heading { level = level, rawText = rawText, children = applyModel r children }
    , raw = \children r -> renderer.raw (applyModel r children)
    , html = htmlRenderer
    , plain = \text _ -> renderer.plain text
    , code = \text _ -> renderer.code text
    , bold = \text _ -> renderer.bold text
    , italic = \text _ -> renderer.italic text
    , link = linkRenderer
    , image =
        \info description ->
            renderer.image info description
                |> Result.map always
    , unorderedList =
        \listItems r ->
            renderer.unorderedList
                (List.map (\(ListItem task children) -> ListItem task (applyModel r children)) listItems)
    , orderedList = \num children r -> renderer.orderedList num (List.map (applyModel r) children)
    , codeBlock = \info _ -> renderer.codeBlock info
    , thematicBreak = \_ -> renderer.thematicBreak
    , blockQuote = \children r -> renderer.blockQuote (applyModel r children)
    }


bumpHeadings : Int -> Markdown.Parser.Renderer view -> Markdown.Parser.Renderer view
bumpHeadings by renderer =
    { renderer | heading = \info -> renderer.heading { info | level = info.level + by } }


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


carusel : Markdown.Html.Renderer (List (Model -> Html Msg) -> Model -> Html Msg)
carusel =
    Markdown.Html.tag "carusel"
        (\identifier children model ->
            Carusel.view (CaruselMsg identifier)
                identifier
                (MarkdownComponents.init Carusel.init identifier model.carusels)
                (applyModel model children)
        )
        |> Markdown.Html.withAttribute "id"


markdownEl : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
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
