module View exposing (..)

import Animator
import Animator.Css
import App exposing (githubRepo, siteName)
import Date exposing (Date)
import Feed
import Html exposing (..)
import Html.Attributes exposing (alt, attribute, checked, class, controls, disabled, for, height, href, id, method, name, placeholder, src, start, style, target, title, type_, value, width)
import Html.Events as Events
import Json.Encode as Encode
import List.Extra as List
import Markdown.Block as Markdown
import Markdown.Scaffolded as Scaffolded
import Metadata
import Pages exposing (allImages, images, pages)
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Pages.PagePath as PagePath exposing (PagePath)


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
                [ "max-w-desktop w-full desktop:mx-auto desktop:px-0"
                , "flex flex-col"
                , "h-full mb-12"
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
            [ class "flex-shrink-0 hidden desktop:flex flex-col"

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
            , class "max-w-desktop w-full desktop:mx-auto py-6 px-3"
            ]
            [ ul
                [ classes
                    [ "grid grid-cols-3 gap-4"
                    , "font-title w-full"
                    ]
                ]
                [ li []
                    [ ul []
                        [ li [ class "text-sm text-gruv-gray-9" ] [ text "READ" ]
                        , li []
                            [ link []
                                { title = Just "posts"
                                , destination = "/"
                                , children = [ text "posts" ]
                                }
                            ]
                        , li []
                            [ link []
                                { title = Just "about"
                                , destination = "/about"
                                , children = [ text "about" ]
                                }
                            ]
                        ]
                    ]
                , li []
                    [ ul []
                        [ li [ class "text-sm text-gruv-gray-9" ] [ text "FOLLOW" ]
                        , li []
                            [ link []
                                { title = Just "twitter"
                                , destination = "https://twitter.com/matheusdev23"
                                , children =
                                    [ smallIcon
                                        { src = images.icons.twitter
                                        , alt = "twitter"
                                        }
                                    , text "twitter"
                                    ]
                                }
                            ]
                        , li []
                            [ link []
                                { title = Just "github"
                                , destination = "https://github.com/matheus23"
                                , children =
                                    [ smallIcon
                                        { src = images.icons.github
                                        , alt = "github"
                                        }
                                    , text "github"
                                    ]
                                }
                            ]
                        , li []
                            [ link [ target "_blank" ]
                                { title = Just "rss feed"
                                , destination = Feed.path |> String.join "/"
                                , children =
                                    [ smallIcon
                                        { src = images.icons.rss
                                        , alt = "rss"
                                        }
                                    , text "rss feed"
                                    ]
                                }
                            ]
                        ]
                    ]
                , li []
                    [ ul []
                        [ li [ class "text-sm text-gruv-gray-9" ] [ text "INFO" ]
                        , li []
                            [ link []
                                { title = Just "imprint"
                                , destination = "/imprint"
                                , children = [ text "imprint" ]
                                }
                            ]
                        , li []
                            [ link []
                                { title = Just "privacy policy"
                                , destination = "/privacy-policy"
                                , children = [ text "privacy policy" ]
                                }
                            ]
                        ]
                    ]
                ]
            , p [ class "mt-4" ]
                [ label [ for "email", class "font-title text-xl text-gruv-gray-11" ]
                    [ text "Get an "
                    , span [ class "code-shadow highlighted-l" ] [ text "E-Mail" ]
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


smallIcon : { src : ImagePath pathKey, alt : String } -> Html msg
smallIcon info =
    img
        [ class "mr-2 inline-block text-white text-opacity-25"
        , src (ImagePath.toString info.src)
        , width 16
        , height 16
        , title info.alt
        , alt info.alt
        ]
        []


gotEmailNotification : { state : Animator.Timeline Bool, onClickDismiss : msg } -> Html msg
gotEmailNotification { state, onClickDismiss } =
    Animator.Css.div state
        [ Animator.Css.transform
            (\active ->
                Animator.Css.xy
                    { x = 0
                    , y =
                        if active then
                            0

                        else
                            250
                    }
            )
        , Animator.Css.opacity
            (\active ->
                (if active then
                    1

                 else
                    0
                )
                    |> Animator.at
                    |> Animator.leaveLate 0.5
            )
        ]
        [ class "fixed bottom-0 w-full z-50 pointer-events-none px-3" ]
        [ div
            [ classes
                [ "font-base text-base text-gruv-gray-12"
                , "max-w-notification mx-auto"
                , "pointer-events-auto"
                , "bg-gruv-gray-2 z-40"
                , "p-4 rounded-t-lg shadow-lg"
                ]
            ]
            [ div [ class "text-center" ]
                [ text "Great to see you’re interested!" ]
            , div [ class "flex flex-row mt-2" ]
                [ img
                    [ src (ImagePath.toString images.gotEmailIllustration)
                    , width 120
                    , height 120
                    , style "width" "120px"
                    , style "height" "120px"
                    ]
                    []
                , span [ class "ml-1 my-auto" ]
                    [ text "Check your inbox,\nI’ve sent you a link to confirm your subscription." ]
                ]
            , button
                [ classes
                    [ "font-code text-base-sm text-center text-gruv-gray-9"
                    , "w-full rounded bg-gruv-gray-4 p-1"
                    , "my-3"
                    ]
                , Events.onClick onClickDismiss
                ]
                [ text "Dismiss" ]
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
        [ [ date [ "mt-5 mb-3" ] metadata.published
          , h1 [ class "font-title text-4xl leading-tight text-gruv-orange-d text-center font-semibold" ]
                [ text metadata.title ]
          ]
        , content
        , [ githubEditLink path ]
        ]


githubEditLink : PagePath Pages.PathKey -> Html msg
githubEditLink path =
    paragraph [ class "text-center" ]
        [ hairline [ "mb-4" ]
        , text "Found a typo? "
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
            code (class "text-gruv-orange-d text-base-sm whitespace-no-wrap" :: attributes) [ text content ]

        Scaffolded.Strong children ->
            strong attributes children

        Scaffolded.Emphasis children ->
            em attributes children

        Scaffolded.Link info ->
            link attributes info

        Scaffolded.Image imageInfo ->
            let
                seemsLikeVideoPath path =
                    (path |> String.endsWith ".webm")
                        || (path |> String.endsWith ".mp4")
            in
            if seemsLikeVideoPath imageInfo.src then
                video attributes imageInfo

            else
                image attributes imageInfo

        Scaffolded.UnorderedList { items } ->
            ul
                (class "pl-8 pr-3 mt-4 mb-2 list-outside list-disc"
                    :: attributes
                )
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
                (class "pl-8 pr-3 mt-4 mb-2 list-outside list-decimal"
                    :: start startingIndex
                    :: attributes
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            li []
                                itemBlocks
                        )
                )

        Scaffolded.CodeBlock info ->
            pre
                [ classes
                    [ "mt-4 py-6 px-8"
                    , "overflow-y-auto"
                    , "font-code text-base-sm code-shadow text-gruv-gray-12 bg-gruv-gray-0"
                    ]
                ]
                [ code [] [ text info.body ] ]

        Scaffolded.HardLineBreak ->
            br attributes []

        Scaffolded.ThematicBreak ->
            hairline [ "mt-6 mb-3" ]

        _ ->
            Scaffolded.reduceHtml attributes block


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


video : List (Attribute msg) -> { alt : String, src : String, title : Maybe String } -> Html msg
video attributes info =
    Html.video
        (src info.src
            :: alt info.alt
            :: controls True
            :: attributes
        )
        []


image : List (Attribute msg) -> { alt : String, src : String, title : Maybe String } -> Html msg
image attributes info =
    let
        maybeTitle =
            info.title
                |> Maybe.map (title >> List.singleton)
                |> Maybe.withDefault []

        maybeSize =
            allImages
                |> List.find (\img -> ImagePath.toString img == info.src)
                |> Maybe.andThen ImagePath.dimensions
                |> Maybe.map
                    (\dimensions ->
                        [ width dimensions.width
                        , height dimensions.height
                        ]
                    )
                |> Maybe.withDefault []
    in
    -- TODO Don't open images in new tab, when fixed:
    -- https://github.com/dillonkearns/elm-pages/issues/105
    a [ target "_blank", href info.src ]
        [ img
            (List.concat
                [ [ src info.src
                  , alt info.alt
                  ]
                , maybeTitle
                , maybeSize
                , attributes
                ]
            )
            []
        ]



-- ARTICLE ELEMENTS


infoIcon : Maybe String -> Html msg
infoIcon infoText =
    img
        (class "mx-1 inline-block"
            :: src (ImagePath.toString images.icons.info)
            :: width 24
            :: height 24
            :: (case infoText of
                    Nothing ->
                        []

                    Just info ->
                        [ title info ]
               )
        )
        []


removeCard : List (Attribute msg) -> Maybe String -> List (Html msg) -> Html msg
removeCard attributes infoText children =
    let
        toBeRemovedIndicator =
            p
                [ classes
                    [ "mt-4 text-right"
                    , "font-code text-gruv-yellow-d"
                    ]
                ]
                [ text "Remove this?"
                , infoIcon infoText
                ]
    in
    section (class "mt-4 flex flex-row flex-shrink min-w-0 bg-gruv-yellow-l-25" :: attributes)
        [ div [ class "mb-4 align-stretch flex-grow flex-shrink min-w-0" ]
            (children ++ [ toBeRemovedIndicator ])
        , div [ class "align-stretch w-2 bg-gruv-yellow-l flex-grow-0 flex-shrink-0" ] []
        ]


infoCard : List (Attribute msg) -> String -> List (Html msg) -> Html msg
infoCard attributes infoText children =
    let
        infoIndicator =
            p [ class "px-3 mt-4 font-code text-gruv-aqua-d" ]
                [ infoIcon Nothing
                , text infoText
                ]
    in
    section (class "mt-4 flex flex-row flex-shrink min-w-0 bg-gruv-aqua-l-25" :: attributes)
        [ div [ class "align-stretch w-2 bg-gruv-aqua-l flex-grow-0 flex-shrink-0" ] []
        , div [ class "mb-4 flex-grow flex-shrink min-w-0" ]
            (infoIndicator :: children)
        ]


marginParagraph : List (Attribute msg) -> List (Html msg) -> Html msg
marginParagraph attributes children =
    div [ class "desktop-l:relative" ]
        [ div
            (class "desktop-l:absolute margin-paragraph"
                :: attributes
            )
            children
        ]


figureWithCaption : List (Attribute msg) -> { figure : { classes : String } -> Html msg, caption : List (Html msg) } -> Html msg
figureWithCaption attributes content =
    Html.figure (class "mt-4 py-6" :: attributes)
        [ content.figure { classes = "mx-auto" }
        , figcaption [ class "text-gruv-gray-4 text-s text-center" ] content.caption
        ]



-- UTILITIES


hairline : List String -> Html msg
hairline clss =
    hr
        [ classes ("h-2px self-stretch mx-16 bg-gruv-gray-9" :: clss) ]
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
