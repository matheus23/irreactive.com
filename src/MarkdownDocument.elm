module MarkdownDocument exposing (..)

import App exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Html
import Markdown.Parser exposing (defaultHtmlRenderer)
import Metadata exposing (Metadata)
import Pages.Document


render renderer markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError deadEndsToString
        |> Result.andThen (\ast -> Markdown.Parser.render renderer ast)


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.Parser.deadEndToString
        |> String.join "\n"


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
                            (applyModel children model)
                    )
        }


applyModel : List (m -> a) -> m -> List a
applyModel ls m =
    List.map ((|>) m) ls


customHtmlRenderer : Markdown.Parser.Renderer (Model -> Html Msg)
customHtmlRenderer =
    defaultHtmlRenderer
        |> bumpHeadings 1
        |> rendererReader
            (Markdown.Html.oneOf
                [ imgCaptioned, carusel, markdownEl ]
            )
            (\link content ->
                Ok <|
                    \r ->
                        Html.a [ Attr.href link.destination ] (applyModel content r)
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
            renderer.heading { level = level, rawText = rawText, children = applyModel children r }
    , raw = \children r -> renderer.raw (applyModel children r)
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
    , list = \children r -> renderer.list (applyModel children r)
    , codeBlock = \info _ -> renderer.codeBlock info
    , thematicBreak = \_ -> renderer.thematicBreak
    }


bumpHeadings : Int -> Markdown.Parser.Renderer view -> Markdown.Parser.Renderer view
bumpHeadings by renderer =
    { renderer | heading = \info -> renderer.heading { info | level = info.level + by } }


imgCaptioned : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
imgCaptioned =
    Markdown.Html.tag "ImgCaptioned"
        (\src alt children model ->
            Html.figure []
                [ Html.img [ Attr.src src, Attr.alt alt ] []
                , Html.figcaption [] (applyModel children model)
                ]
        )
        |> Markdown.Html.withAttribute "src"
        |> Markdown.Html.withAttribute "alt"


carusel : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
carusel =
    Markdown.Html.tag "Carusel"
        (\children model ->
            Html.ul [ Attr.class "carusel" ]
                (applyModel children model)
        )


markdownEl : Markdown.Html.Renderer (List (model -> Html msg) -> model -> Html msg)
markdownEl =
    Markdown.Html.tag "Markdown"
        (\children model -> Html.div [ Attr.class "markdown" ] (applyModel children model))
