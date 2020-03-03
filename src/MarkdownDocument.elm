module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Loop
import Markdown.Block exposing (ListItem(..))
import Markdown.BlockStructure as BlockStructure exposing (BlockStructure)
import Markdown.Html
import Markdown.Parser as Markdown
import Markdown.Renderer as Markdown
import MarkdownComponents.Carousel as Carousel
import MarkdownComponents.Helper as MarkdownComponents
import Metadata exposing (Metadata)
import Pages.Document
import Result.Extra as Result
import String.Extra as String


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"



-- TODO: Remove the Html rendering of markdown error messages.
{-
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
-}
-- TODO: Do link checking at some point via StaticHttp.Request, but do this as a
-- pass before rendering, and keep rendering having a (Model -> Html Msg) type


document : ( String, Pages.Document.DocumentHandler Metadata (Model -> Html Msg) )
document =
    Pages.Document.parser
        { extension = "md"
        , metadata = Metadata.decoder
        , body =
            Markdown.parse
                >> Result.mapError deadEndsToString
                >> Result.andThen (Markdown.render customHtmlRenderer)
                >> Result.map
                    (\children model ->
                        applyModel model children
                            |> Html.main_ [ Attr.class "content" ]
                    )
        }


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


customHtmlRenderer : Markdown.Renderer (Model -> Html Msg)
customHtmlRenderer =
    BlockStructure.toRenderer
        { renderHtml =
            Markdown.Html.oneOf
                [ anythingCaptioned "img" []
                , anythingCaptioned "video" [ Attr.controls True ]
                , carousel
                , markdownEl
                ]
        , renderMarkdown =
            (\blockStructure _ ->
                blockStructure
                    |> bumpHeadings 1
                    |> BlockStructure.renderToHtml
            )
                |> BlockStructure.parameterized
        }


bumpHeadings : Int -> BlockStructure view -> BlockStructure view
bumpHeadings by markdown =
    case markdown of
        BlockStructure.Heading info ->
            BlockStructure.Heading { info | level = Loop.for by bumpHeadingLevel info.level }

        other ->
            other


bumpHeadingLevel : Markdown.Block.HeadingLevel -> Markdown.Block.HeadingLevel
bumpHeadingLevel level =
    case level of
        Markdown.Block.H1 ->
            Markdown.Block.H2

        Markdown.Block.H2 ->
            Markdown.Block.H3

        Markdown.Block.H3 ->
            Markdown.Block.H4

        Markdown.Block.H4 ->
            Markdown.Block.H5

        Markdown.Block.H5 ->
            Markdown.Block.H6

        Markdown.Block.H6 ->
            Markdown.Block.H6


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


carousel : Markdown.Html.Renderer (List (Model -> Html Msg) -> Model -> Html Msg)
carousel =
    Markdown.Html.tag "carousel"
        (\identifier children model ->
            Carousel.view (CarouselMsg identifier)
                identifier
                (MarkdownComponents.init Carousel.init identifier model.carousels)
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
