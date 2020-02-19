module MarkdownDocument exposing (..)

import App exposing (..)
import Dict
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Markdown.Html
import Markdown.Parser exposing (defaultHtmlRenderer)
import Metadata exposing (Metadata)
import Pages.Document
import Parser
import Parser.Advanced
import Result.Extra as Result
import String.Extra as String


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
                , numberedList
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
    , unorderedList = \children r -> renderer.unorderedList (List.map (applyModel r) children)
    , orderedList = \num children r -> renderer.orderedList num (List.map (applyModel r) children)
    , codeBlock = \info _ -> renderer.codeBlock info
    , thematicBreak = \_ -> renderer.thematicBreak
    }


bumpHeadings : Int -> Markdown.Parser.Renderer view -> Markdown.Parser.Renderer view
bumpHeadings by renderer =
    { renderer | heading = \info -> renderer.heading { info | level = info.level + by } }


anythingCaptioned : String -> List (Html.Attribute msg) -> Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
anythingCaptioned tagName attributes =
    Markdown.Html.tag (String.toTitleCase tagName ++ "Captioned")
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
    Markdown.Html.tag "Carusel"
        (\identifier children model ->
            let
                caruselModel =
                    model.carusels
                        |> Dict.get identifier
                        |> Maybe.withDefault { scrollPosition = 0.0 }

                scrolledItem =
                    caruselModel.scrollPosition * toFloat (List.length children - 1)
            in
            Html.section [ Attr.class "carusel-container" ]
                [ Html.div
                    [ Attr.class "carusel"
                    , Attr.id identifier
                    , Events.on "scroll" (Decode.succeed (CaruselOnScroll identifier))
                    ]
                    (applyModel model children)
                , Html.div [ Attr.class "dots" ]
                    (children
                        |> List.indexedMap
                            (\index _ ->
                                let
                                    irrelevancy =
                                        (toFloat index - scrolledItem)
                                            |> abs
                                            |> clamp 0 1
                                in
                                Html.div
                                    [ Attr.class "dot"
                                    , Attr.style "background-color"
                                        (String.concat
                                            [ "rgba(146,131,116,"
                                            , String.fromFloat (1 - irrelevancy)
                                            , ")"
                                            ]
                                        )
                                    ]
                                    []
                            )
                    )
                ]
        )
        |> Markdown.Html.withAttribute "id"


markdownEl : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
markdownEl =
    Markdown.Html.tag "Markdown"
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


numberedList : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
numberedList =
    Markdown.Html.tag "NumberedList"
        (\children model ->
            Html.ol []
                (applyModel model children
                    |> List.indexedMap
                        (\index el ->
                            Html.li []
                                [ Html.text (String.fromInt (index + 1) ++ ". ")
                                , el
                                ]
                        )
                )
        )
