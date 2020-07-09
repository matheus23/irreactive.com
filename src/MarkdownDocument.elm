module MarkdownDocument exposing (..)

import App exposing (..)
import Components.CodeHighlighted as CodeHighlighted
import Components.CodeInteractiveElm as CodeInteractiveElm
import Components.CodeInteractiveJs as CodeInteractiveJs
import Dict
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
import Maybe.Extra as Maybe
import Metadata exposing (Metadata)
import Result.Extra as Result
import String.Extra as String
import View


type alias View =
    List Int -> Result String (Model -> Html Msg)


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
            >> Result.andThen finalizeView
    }


finalizeView : List View -> Result String (Model -> List (Html Msg))
finalizeView content =
    content
        |> List.indexedMap (\index view -> view [ index ])
        |> Result.combine
        |> Result.map (\views model -> applyModel model views)


customHtmlRenderer : Markdown.Renderer View
customHtmlRenderer =
    Scaffolded.toRenderer
        { renderHtml =
            Markdown.Html.oneOf
                [ liftRendererPlain (anythingCaptioned "video" [ Attr.controls True ])
                , liftRendererPlain (anythingCaptioned "img" [])
                , liftRendererPlain markdownEl
                , liftRendererPlain removeElement
                , liftRendererPlain infoElement
                , liftRendererPlain marginParagraph
                , liftRendererWithModel carousel
                ]
        , renderMarkdown = reduceMarkdown
        }


reduceMarkdown : Scaffolded.Block View -> View
reduceMarkdown block path =
    case block of
        Scaffolded.CodeBlock code ->
            case code.language of
                Just "js interactive" ->
                    CodeInteractiveJs.init code.body
                        |> Result.map
                            (\init model ->
                                model.interactiveJs
                                    |> Dict.get (pathToId path)
                                    |> Maybe.withDefault init
                                    |> CodeInteractiveJs.view
                                    |> Html.map (InteractiveJsMsg (pathToId path) init)
                            )

                Just "elm interactive" ->
                    CodeInteractiveElm.init code.body
                        |> Result.map
                            (\init model ->
                                model.interactiveElm
                                    |> Dict.get (pathToId path)
                                    |> Maybe.withDefault init
                                    |> CodeInteractiveElm.view
                                    |> Html.map (InteractiveElmMsg (pathToId path) init)
                            )

                _ ->
                    Ok <| \_ -> CodeHighlighted.view code

        _ ->
            block
                |> foldFunction2 path
                |> Scaffolded.foldResults
                |> Result.map
                    (\resultBlock model ->
                        resultBlock
                            |> foldFunction2 model
                            |> View.markdown []
                    )



-- PLAIN ELEMENTS


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


markdownEl : Markdown.Html.Renderer (List (Html msg) -> Html msg)
markdownEl =
    Markdown.Html.tag "markdown"
        (\idAttrs children ->
            Html.div (Attr.class "markdown" :: idAttrs) children
        )
        |> withOptionalIdAttribute


anythingCaptioned : String -> List (Html.Attribute msg) -> Markdown.Html.Renderer (List (Html msg) -> Html msg)
anythingCaptioned tagName attributes =
    Markdown.Html.tag (tagName ++ "captioned")
        (\src alt shouldLoop idAttrs children ->
            View.figureWithCaption idAttrs
                { figure =
                    Html.node tagName
                        ((Attr.src src :: Attr.alt alt :: attributes)
                            ++ (if shouldLoop then
                                    [ Attr.loop True ]

                                else
                                    []
                               )
                        )
                        []
                , caption = children
                }
        )
        |> Markdown.Html.withAttribute "src"
        |> Markdown.Html.withAttribute "alt"
        |> withBooleanAttribute "loop"
        |> withOptionalIdAttribute



-- ELEMENTS WITH MODEL


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



-- ELEMENT LIFTING


liftRendererPlain :
    Markdown.Html.Renderer (List (Html Msg) -> Html Msg)
    -> Markdown.Html.Renderer (List View -> View)
liftRendererPlain =
    Markdown.Html.map
        (\render children path ->
            children
                |> List.indexedMap (\index view -> view (index :: path))
                |> Result.combine
                |> Result.map
                    (\views model ->
                        applyModel model views
                            |> render
                    )
        )


liftRendererWithModel :
    Markdown.Html.Renderer (List (Model -> Html Msg) -> Model -> Html Msg)
    -> Markdown.Html.Renderer (List View -> View)
liftRendererWithModel =
    Markdown.Html.map
        (\render children path ->
            children
                |> List.indexedMap (\index view -> view (index :: path))
                |> Result.combine
                |> Result.map render
        )


withOptionalIdAttribute : Markdown.Html.Renderer (List (Html.Attribute msg) -> view) -> Markdown.Html.Renderer view
withOptionalIdAttribute rend =
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


withBooleanAttribute : String -> Markdown.Html.Renderer (Bool -> view) -> Markdown.Html.Renderer view
withBooleanAttribute attributeName rend =
    rend
        |> Markdown.Html.map
            (\continue maybeAttribute ->
                Maybe.isJust maybeAttribute |> continue
            )
        |> Markdown.Html.withOptionalAttribute attributeName



-- UTILS


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"


applyModel : m -> List (m -> a) -> List a
applyModel m =
    List.map ((|>) m)


foldFunction2 : env -> Scaffolded.Block (env -> view) -> Scaffolded.Block view
foldFunction2 environment block =
    Scaffolded.foldFunction block environment
