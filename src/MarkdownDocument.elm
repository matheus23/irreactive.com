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


foldFunction2 : env -> Scaffolded.Block (env -> view) -> Scaffolded.Block view
foldFunction2 environment block =
    Scaffolded.foldFunction block environment


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
