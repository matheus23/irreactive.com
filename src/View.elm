module View exposing (..)

import App exposing (githubRepo, siteName)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, checked, class, disabled, for, height, href, id, method, name, placeholder, src, start, style, title, type_, value, width)
import Html.Events as Events
import Markdown.Block as Markdown
import Markdown.Scaffolded as Scaffolded
import Metadata
import Pages exposing (images, pages)
import Pages.ImagePath as ImagePath
import Pages.PagePath as PagePath exposing (PagePath)
import SyntaxHighlight


body : List (Attribute msg) -> List (Html msg) -> Html msg
body attributes children =
    div
        (class "flex flex-col min-h-screen text-base" :: attributes)
        children


document : (List (Attribute msg) -> List (Html msg) -> Html msg) -> String -> List (Html msg) -> Html msg
document html textColor children =
    main_
        [ classes
            [ "w-full h-full flex-grow z-10"
            , "bg-gruv-gray-12"
            , textColor
            ]
        ]
        [ html
            [ classes
                [ "container desktop:mx-auto desktop:px-0"
                , "flex flex-col"
                , "h-full mb-12 overflow-y-hidden"
                ]
            ]
            children
        ]



-- HEADER


header : PagePath Pages.PathKey -> Html msg
header currentPath =
    nav [ class "flex flex-row w-full bg-gruv-gray-12 z-30" ]
        [ a
            [ classes
                [ "flex-grow flex flex-col"
                , "hover:bg-gruv-gray-10 focus:bg-gruv-gray-10 outline-none"
                ]
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ classes
                    [ "font-title font-semibold text-3xl text-gruv-orange-d"
                    , "px-3 ml-auto"
                    ]
                ]
                [ text siteName ]
            , div [ class "h-1 mr-1 bg-gruv-gray-10" ] []
            ]
        , a
            [ classes
                [ "w-full max-w-nav-item flex-grow"
                , "flex flex-col"
                , "hover:bg-gruv-gray-10 focus:bg-gruv-gray-10 outline-none"
                ]
            , href (PagePath.toString pages.index)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "Posts" ]
            , div
                [ classes
                    [ "h-1 mx-1"
                    , if currentPath == pages.index then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        , a
            [ classes
                [ "w-full max-w-nav-item flex-grow"
                , "flex flex-col"
                , "hover:bg-gruv-gray-10 focus:bg-gruv-gray-10 outline-none"
                ]
            , href (PagePath.toString pages.about)
            ]
            [ span
                [ class "font-body italic text-base m-auto text-gruv-gray-4" ]
                [ text "About" ]
            , div
                [ classes
                    [ "h-1 ml-1"
                    , if currentPath == pages.about then
                        "bg-gruv-orange-m"

                      else
                        "bg-gruv-gray-10"
                    ]
                ]
                []
            ]
        , div
            [ class "flex-shrink-0 hidden desktop:flex flex-col h-fill"

            -- This item should be just as wide as the right page margin on desktop
            , style "width" "calc((100vw - 600px) / 2)"
            ]
            [ div [ class "h-1 ml-1 mt-auto bg-gruv-gray-10" ] [] ]
        ]


accentLine : Html msg
accentLine =
    div [ class "top-0 inset-x-0 h-2 bg-gruv-orange-m z-20 fixed" ] []



-- ARTICLE LIST


articleList : List (Attribute msg) -> List (Html msg) -> Html msg
articleList attributes children =
    ul (class "flex flex-col" :: attributes) children


postPreview : ( PagePath Pages.PathKey, Metadata.ArticleMetadata ) -> Html msg
postPreview ( postPath, post ) =
    li [ class "w-full mx-auto mt-12 px-5" ]
        [ date [] post.published
        , h2 [ class "font-title text-4xl text-center leading-tight text-gruv-gray-4" ]
            [ a [ class "link-effect", href (PagePath.toString postPath) ]
                [ text post.title ]
            ]
        , p [ class "text-justify mt-2" ]
            [ a [ class "link-effect", href (PagePath.toString postPath) ]
                [ text post.description ]
            ]
        , p [ class "font-title text-xl text-gruv-blue-d block text-center mt-2" ]
            [ a
                [ class "link-effect-purple"
                , href (PagePath.toString postPath)
                , class "visited:text-gruv-purple-d"
                ]
                [ text "Read More ..." ]
            ]
        , hairline [ "mt-12" ]
        ]


date : List String -> Date -> Html msg
date clss d =
    time [ classes ("text-gruv-gray-4 italic text-base-sm text-center block" :: clss) ]
        [ text (Date.format "MMMM ddd, yyyy" d) ]



-- FOOTER


footer :
    { onSubmit : msg
    , onInput : String -> msg
    , model : String
    , errorText : String
    , submitSuccess : Bool
    }
    -> Html msg
footer { onSubmit, onInput, model, errorText, submitSuccess } =
    Html.footer [ class "flex flex-col bg-gruv-gray-0 sticky bottom-0 inset-x-0" ]
        [ form
            [ name "email-subscription"
            , method "POST"
            , attribute "data-netlify" "true"
            , Events.onSubmit onSubmit
            , class "container desktop:mx-auto py-6 px-3"
            ]
            [ p []
                [ label [ for "email", class "font-code text-gruv-gray-11" ]
                    [ text "Get an "
                    , span [ class "text-gruv-orange-l" ] [ text "E-Mail" ]
                    , text " for every new Post:"
                    ]
                ]
            , p [ class "flex flex-row mt-2" ]
                [ input
                    [ classes
                        [ "bg-gruv-gray-3"
                        , "border-2 border-r-0 border-gruv-gray-5 rounded-l-md"
                        , "font-code text-gruv-gray-11"
                        , "flex-shrink flex-grow min-w-0 py-auto py-1 px-2"
                        , "focus:border-gruv-gray-7"
                        ]
                    , style "transform" "translate(0, -4px)"
                    , style "box-shadow" "0 4px 0 0 rgba(102,92,84,1)"
                    , id "email"
                    , type_ "email"
                    , name "email"
                    , placeholder "your e-mail"
                    , Events.onInput onInput
                    , value model
                    ]
                    []
                , button
                    [ classes [ "call-to-action inline flex-shrink-0 px-4 py-2 font-semibold tracking-widest" ]
                    , type_ "submit"
                    ]
                    [ text "Get Notified" ]
                ]
            , p
                [ classes
                    [ "font-code text-gruv-yellow-l mt-2"
                    , when (String.isEmpty errorText) "hidden"
                    ]
                ]
                [ text errorText ]
            , p
                [ classes
                    [ "font-code mt-2"
                    , unless submitSuccess "hidden"
                    ]
                , style "color" "#49d27e"
                ]
                [ text "Thanks for subscribing!" ]
            ]
        ]



-- ARTICLES


decorateArticle :
    { path : PagePath Pages.PathKey
    , metadata : Metadata.ArticleMetadata
    , content : List (Html msg)
    }
    -> List (Html msg)
decorateArticle { path, metadata, content } =
    List.concat
        [ [ img
                [ class "desktop:mt-6"
                , src (ImagePath.toString metadata.image)

                -- TODO We don't want generic alt texts. How about defining the alt-text in the post?
                , alt "Post cover photo"
                ]
                []
          , date [ "mt-5 mb-3" ] metadata.published
          , h1 [ class "font-title text-4xl leading-tight text-gruv-orange-d text-center font-semibold" ]
                [ text metadata.title ]
          ]
        , content
        , [ githubEditLink path ]
        ]


githubEditLink : PagePath Pages.PathKey -> Html msg
githubEditLink path =
    paragraph []
        [ text "Found a typo? "
        , link []
            { destination = githubRepo ++ "/blob/master/content/" ++ PagePath.toString path ++ ".md"
            , title = Just "Link to editing this page on Github"
            , children = [ text "Edit this page GitHub." ]
            }
        ]



-- MARKDOWN


markdown : List (Attribute msg) -> Scaffolded.Block (Html msg) -> Html msg
markdown attributes block =
    case block of
        Scaffolded.Heading { level, children } ->
            case level of
                Markdown.H1 ->
                    div [ class "flex flex-row mt-8" ]
                        [ div [ class "w-3 self-stretch bg-gruv-orange-m" ] []
                        , h2 (class "flex-grow px-5 font-title text-3xl" :: attributes) children
                        ]

                Markdown.H2 ->
                    div [ class "flex flex-row mt-8" ]
                        [ div [ class "w-3 self-stretch bg-gruv-gray-3" ] []
                        , h3 (class "flex-grow px-5 font-title text-2xl" :: attributes) children
                        ]

                Markdown.H3 ->
                    div [ class "flex flex-row mt-6" ]
                        [ div [ class "w-3 self-stretch bg-gruv-gray-6" ] []
                        , h4 (class "flex-grow px-5 font-title text-xl" :: attributes) children
                        ]

                -- We only support up to h4
                _ ->
                    div [ class "flex flex-row mt-6" ]
                        [ div [ class "w-3 self-stretch bg-gruv-gray-10" ] []
                        , h5 (class "flex-grow px-5 font-title text-xl" :: attributes) children
                        ]

        Scaffolded.Paragraph children ->
            paragraph attributes children

        Scaffolded.BlockQuote children ->
            blockquote attributes children

        Scaffolded.Text content ->
            text content

        Scaffolded.CodeSpan content ->
            code (class "text-gruv-orange-d text-base-sm" :: attributes) [ text content ]

        Scaffolded.Strong children ->
            strong attributes children

        Scaffolded.Emphasis children ->
            em attributes children

        Scaffolded.Link info ->
            link attributes info

        Scaffolded.Image imageInfo ->
            let
                addTitle attrs =
                    imageInfo.title
                        |> Maybe.map (\t -> title t :: attrs)
                        |> Maybe.withDefault attrs

                addSizeProps attrs =
                    if imageInfo.src == ImagePath.toString images.me then
                        class "rounded-lg my-6 mx-auto"
                            :: width 200
                            :: height 200
                            :: attrs

                    else
                        attrs
            in
            img
                (src imageInfo.src
                    :: alt imageInfo.alt
                    :: addSizeProps (addTitle attributes)
                )
                []

        Scaffolded.UnorderedList { items } ->
            ul attributes
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Markdown.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Markdown.NoTask ->
                                                    text ""

                                                Markdown.IncompleteTask ->
                                                    input
                                                        [ disabled True
                                                        , checked False
                                                        , type_ "checkbox"
                                                        ]
                                                        []

                                                Markdown.CompletedTask ->
                                                    input
                                                        [ disabled True
                                                        , checked True
                                                        , type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    li [] (checkbox :: children)
                        )
                )

        Scaffolded.OrderedList { startingIndex, items } ->
            ol
                (case startingIndex of
                    1 ->
                        start startingIndex :: attributes

                    _ ->
                        attributes
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            li []
                                itemBlocks
                        )
                )

        Scaffolded.CodeBlock info ->
            let
                wrap renderedCode =
                    pre
                        (classes
                            [ "mt-4 py-6 px-8"
                            , "overflow-y-auto"
                            , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                            ]
                            :: attributes
                        )
                        [ code [] renderedCode ]

                findHighlighter string =
                    case string of
                        "elm" ->
                            Just SyntaxHighlight.elm

                        "js" ->
                            Just SyntaxHighlight.javascript

                        _ ->
                            Nothing
            in
            case info.language |> Maybe.andThen findHighlighter of
                Just syntaxHighlight ->
                    case syntaxHighlight info.body of
                        Ok highlightedCode ->
                            let
                                styled clss content =
                                    span [ class clss ] [ text content ]
                            in
                            wrap
                                (SyntaxHighlight.toCustom
                                    { noOperation = div []
                                    , highlight = div []
                                    , addition = div []
                                    , deletion = div []
                                    , default = text
                                    , comment = styled "text-gruv-gray-8 italic"

                                    -- numbers
                                    , style1 = styled "text-gruv-blue-l"

                                    -- Literal string, attribute value
                                    , style2 = styled "text-gruv-green-l"

                                    -- Keyword, tag, operator symbols
                                    , style3 = styled "text-gruv-gray-12"

                                    -- Keyword 2, group symbols, type signature
                                    , style4 = styled "text-gruv-gray-12"

                                    -- Function, attribute name
                                    , style5 = styled "text-gruv-yellow-l"

                                    -- Literal keyword, capitalized types
                                    , style6 = styled "text-gruv-green-l"

                                    -- argument, parameter
                                    , style7 = styled "text-gruv-gray-12"
                                    }
                                    highlightedCode
                                )

                        Err _ ->
                            wrap [ text info.body ]

                _ ->
                    wrap [ text info.body ]

        Scaffolded.HardLineBreak ->
            br attributes []

        Scaffolded.ThematicBreak ->
            hairline [ "mt-6 mb-3" ]

        _ ->
            Scaffolded.foldHtml attributes block


link :
    List (Attribute msg)
    ->
        { title : Maybe String
        , destination : String
        , children : List (Html msg)
        }
    -> Html msg
link attributes info =
    let
        addTitle attrs =
            info.title
                |> Maybe.map (\t -> title t :: attrs)
                |> Maybe.withDefault attrs
    in
    a
        (href info.destination
            :: class "link-effect-purple text-gruv-blue-d visited:text-gruv-purple-d"
            :: addTitle attributes
        )
        info.children


paragraph : List (Attribute msg) -> List (Html msg) -> Html msg
paragraph attributes children =
    p (class "mt-4 px-3" :: attributes) children



-- UTILITIES


hairline : List String -> Html msg
hairline clss =
    hr
        [ style "height" "2px"
        , classes ("self-stretch mx-16 bg-gruv-gray-9" :: clss)
        ]
        []


classes : List String -> Attribute msg
classes list =
    class (String.join " " list)


when : Bool -> String -> String
when condition classNames =
    if condition then
        classNames

    else
        ""


unless : Bool -> String -> String
unless condition =
    when (not condition)
