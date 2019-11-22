module MarkdownDocument exposing (..)

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Parser
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


document : ( String, Pages.Document.DocumentHandler Metadata (Element msg) )
document =
    Pages.Document.parser
        { extension = "md"
        , metadata = Metadata.decoder
        , body =
            render customHtmlRenderer
                >> Result.map
                    (\htmlBlocks ->
                        Html.div [] htmlBlocks
                            |> Element.html
                            |> List.singleton
                            |> Element.paragraph [ Element.spacing 12, Element.width Element.fill ]
                    )
        }


customHtmlRenderer : Markdown.Parser.Renderer (Html msg)
customHtmlRenderer =
    let
        centeredImage : { src : String } -> String -> Result String (Html msg)
        centeredImage { src } altText =
            Ok
                (Html.div
                    [ Attr.style "display" "flex"
                    , Attr.style "flex-direction" "column"
                    , Attr.style "align-items" "center"
                    , Attr.style "justify-content" "middle"
                    , Attr.style "width" "100%"
                    , Attr.style "margin" "0 20px"
                    ]
                    [ Html.img
                        [ Attr.src src
                        , Attr.alt altText
                        , Attr.style "border" "1px solid #ebebeb"
                        , Attr.style "box-shadow" "1px 3px 4px rgba(0, 0, 0, 0.2)"
                        ]
                        []
                    , Html.span
                        [ Attr.style "text-align" "center"
                        , Attr.style "font-size" "16px"
                        , Attr.style "color" "rgb(102, 102, 102)"
                        , Attr.style "margin-top" "10px"
                        ]
                        [ Html.text altText ]
                    ]
                )

        default =
            Markdown.Parser.defaultHtmlRenderer
    in
    { default
        | image = centeredImage
    }
