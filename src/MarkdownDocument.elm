module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Loop
import Markdown.Block exposing (ListItem(..))
import Markdown.Html
import Markdown.Parser as Markdown
import Markdown.Renderer as Markdown exposing (defaultHtmlRenderer, withoutValidation)
import MarkdownComponents.Carousel as Carousel
import MarkdownComponents.Helper as MarkdownComponents
import Metadata exposing (Metadata)
import Pages.Document
import Pages.StaticHttp as StaticHttp
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


document : ( String, Pages.Document.DocumentHandler Metadata (StaticHttp.Request (Model -> Html Msg)) )
document =
    Pages.Document.parser
        { extension = "md"
        , metadata = Metadata.decoder
        , body =
            Markdown.parse
                >> Result.mapError deadEndsToString
                >> Result.andThen
                    (Markdown.render
                        (withoutValidation customHtmlRenderer)
                        (Markdown.Html.oneOf
                            [ anythingCaptioned "img" []
                            , anythingCaptioned "video" [ Attr.controls True ]
                            , carousel
                            , markdownEl
                            ]
                            |> htmlOverStaticHttp
                        )
                    )
                >> Result.map
                    (allStaticHttp
                        >> StaticHttp.map
                            (\children model ->
                                applyModel model children
                                    |> Html.main_ [ Attr.class "content" ]
                            )
                    )
        }


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


allStaticHttp : List (StaticHttp.Request a) -> StaticHttp.Request (List a)
allStaticHttp =
    List.foldl (StaticHttp.map2 (::)) (StaticHttp.succeed [])


customHtmlRenderer : Markdown.Renderer (StaticHttp.Request (Model -> Html Msg))
customHtmlRenderer =
    defaultHtmlRenderer
        |> bumpHeadings 1
        |> rendererReader
        |> staticHttpRenderer


staticHttpRenderer : Markdown.Renderer view -> Markdown.Renderer (StaticHttp.Request view)
staticHttpRenderer renderer =
    { heading =
        \{ level, rawText, children } ->
            allStaticHttp children
                |> StaticHttp.map
                    (\actualChildren ->
                        renderer.heading { level = level, rawText = rawText, children = actualChildren }
                    )
    , paragraph = allStaticHttp >> StaticHttp.map renderer.paragraph
    , hardLineBreak = renderer.hardLineBreak |> StaticHttp.succeed
    , blockQuote = allStaticHttp >> StaticHttp.map renderer.blockQuote
    , strong = allStaticHttp >> StaticHttp.map renderer.strong
    , emphasis = allStaticHttp >> StaticHttp.map renderer.emphasis
    , codeSpan = renderer.codeSpan >> StaticHttp.succeed
    , link = \link -> allStaticHttp >> StaticHttp.map (renderer.link link)
    , image = renderer.image >> StaticHttp.succeed
    , text = renderer.text >> StaticHttp.succeed
    , unorderedList =
        \items ->
            let
                combineListItemResults (ListItem task results) =
                    results
                        |> allStaticHttp
                        |> StaticHttp.map (ListItem task)
            in
            items
                |> List.map combineListItemResults
                |> allStaticHttp
                |> StaticHttp.map renderer.unorderedList
    , orderedList =
        \startingIndex items ->
            items
                |> List.map allStaticHttp
                |> allStaticHttp
                |> StaticHttp.map (renderer.orderedList startingIndex)
    , codeBlock = renderer.codeBlock >> StaticHttp.succeed
    , thematicBreak = renderer.thematicBreak |> StaticHttp.succeed
    }


rendererReader :
    Markdown.Renderer view
    -> Markdown.Renderer (r -> view)
rendererReader renderer =
    { heading =
        \{ level, rawText, children } r ->
            renderer.heading { level = level, rawText = rawText, children = applyModel r children }
    , paragraph = \children r -> renderer.paragraph (applyModel r children)
    , text = \text _ -> renderer.text text
    , codeSpan = \text _ -> renderer.codeSpan text
    , strong = \children r -> renderer.strong (applyModel r children)
    , emphasis = \children r -> renderer.emphasis (applyModel r children)
    , link = \info children r -> renderer.link info (applyModel r children)
    , image = \info _ -> renderer.image info
    , unorderedList =
        \listItems r ->
            renderer.unorderedList
                (List.map (\(ListItem task children) -> ListItem task (applyModel r children)) listItems)
    , orderedList = \num children r -> renderer.orderedList num (List.map (applyModel r) children)
    , codeBlock = \info _ -> renderer.codeBlock info
    , thematicBreak = \_ -> renderer.thematicBreak
    , blockQuote = \children r -> renderer.blockQuote (applyModel r children)
    , hardLineBreak = \_ -> renderer.hardLineBreak
    }


bumpHeadings : Int -> Markdown.Renderer view -> Markdown.Renderer view
bumpHeadings by renderer =
    { renderer
        | heading =
            \info ->
                renderer.heading { info | level = Loop.for by bumpHeadingLevel info.level }
    }


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


htmlOverStaticHttp :
    Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
    -> Markdown.Html.Renderer (List (StaticHttp.Request (model -> Html msg)) -> StaticHttp.Request (model -> Html msg))
htmlOverStaticHttp renderer =
    Debug.todo "Dude :D"


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
