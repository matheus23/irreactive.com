module Markdown.BlockStructure exposing
    ( BlockStructure(..), map
    , renderToHtml, extractText
    , fromRenderer, toRenderer
    , parameterized
    , validating
    , extractingText
    )

{-|

@docs BlockStructure, map


# Example Renderers

@docs renderToHtml, extractText


# Conversions

@docs fromRenderer, toRenderer


# Transformations

@docs parameterized
@docs validating
@docs extractingText

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer exposing (Renderer)
import Result.Extra as Result


{-| A datatype that enumerates all possible ways markdown could wrap some children.

This does not include Html tags.

It has a type parameter `children`, which is supposed to be filled with `String`,
`Html msg` or similar.

-}
type BlockStructure children
    = Heading { level : Block.HeadingLevel, rawText : String, children : List children }
    | Paragraph (List children)
    | BlockQuote (List children)
    | Text String
    | CodeSpan String
    | Strong (List children)
    | Emphasis (List children)
    | Link { title : Maybe String, destination : String, children : List children }
    | Image { alt : String, src : String, title : Maybe String }
    | UnorderedList { items : List (Block.ListItem children) }
    | OrderedList { startingIndex : Int, items : List (List children) }
    | CodeBlock { body : String, language : Maybe String }
    | HardLineBreak
    | ThematicBreak


{-| Transform each child of a `BlockStructure` using the given function.
-}
map : (a -> b) -> BlockStructure a -> BlockStructure b
map f markdown =
    case markdown of
        Heading { level, rawText, children } ->
            Heading { level = level, rawText = rawText, children = List.map f children }

        Paragraph children ->
            Paragraph (List.map f children)

        BlockQuote children ->
            BlockQuote (List.map f children)

        Text content ->
            Text content

        CodeSpan content ->
            CodeSpan content

        Strong children ->
            Strong (List.map f children)

        Emphasis children ->
            Emphasis (List.map f children)

        Link { title, destination, children } ->
            Link { title = title, destination = destination, children = List.map f children }

        Image imageInfo ->
            Image imageInfo

        UnorderedList { items } ->
            UnorderedList
                { items =
                    List.map
                        (\(Block.ListItem task children) ->
                            Block.ListItem task (List.map f children)
                        )
                        items
                }

        OrderedList { startingIndex, items } ->
            OrderedList { startingIndex = startingIndex, items = List.map (List.map f) items }

        CodeBlock codeBlockInfo ->
            CodeBlock codeBlockInfo

        HardLineBreak ->
            HardLineBreak

        ThematicBreak ->
            ThematicBreak


{-| There are two ways of thinking about this function:

1.  Render a `BlockStructure` using the given elm-markdown `Renderer`.
2.  Extract a function of type `(BlockStructure view -> view)` out of
    the elm-markdown `Renderer`. This is useful if you want to make use
    of the utilities present in this library.

For the opposite function, take a look at [`toRenderer`](#toRenderer).

-}
fromRenderer : Renderer view -> BlockStructure view -> view
fromRenderer renderer markdown =
    case markdown of
        Heading info ->
            renderer.heading info

        Paragraph children ->
            renderer.paragraph children

        BlockQuote children ->
            renderer.blockQuote children

        Text content ->
            renderer.text content

        CodeSpan content ->
            renderer.codeSpan content

        Strong children ->
            renderer.strong children

        Emphasis children ->
            renderer.emphasis children

        Link { title, destination, children } ->
            renderer.link { title = title, destination = destination } children

        Image imageInfo ->
            renderer.image imageInfo

        UnorderedList { items } ->
            renderer.unorderedList items

        OrderedList { startingIndex, items } ->
            renderer.orderedList startingIndex items

        CodeBlock info ->
            renderer.codeBlock info

        HardLineBreak ->
            renderer.hardLineBreak

        ThematicBreak ->
            renderer.thematicBreak


{-| Convert a function that works with `BlockStructure` to a `Renderer` for use with
elm-markdown.

For the opposite, take a look at [`fromRenderer`](#fromRenderer)

(The second parameter is a [`Markdown.Html.Renderer`](/packages/dillonkearns/elm-markdown/3.0.0/Markdown-Html#Renderer))

-}
toRenderer :
    { renderMarkdown : BlockStructure view -> view
    , renderHtml : Markdown.Html.Renderer (List view -> view)
    }
    -> Renderer view
toRenderer { renderMarkdown, renderHtml } =
    { heading = Heading >> renderMarkdown
    , paragraph = Paragraph >> renderMarkdown
    , blockQuote = BlockQuote >> renderMarkdown
    , html = renderHtml
    , text = Text >> renderMarkdown
    , codeSpan = CodeSpan >> renderMarkdown
    , strong = Strong >> renderMarkdown
    , emphasis = Emphasis >> renderMarkdown
    , hardLineBreak = HardLineBreak |> renderMarkdown
    , link =
        \{ title, destination } children ->
            Link { title = title, destination = destination, children = children }
                |> renderMarkdown
    , image = Image >> renderMarkdown
    , unorderedList =
        \items ->
            UnorderedList { items = items }
                |> renderMarkdown
    , orderedList =
        \startingIndex items ->
            OrderedList { startingIndex = startingIndex, items = items }
                |> renderMarkdown
    , codeBlock = CodeBlock >> renderMarkdown
    , thematicBreak = ThematicBreak |> renderMarkdown
    }


{-| -}
renderToHtml : BlockStructure (Html msg) -> Html msg
renderToHtml markdown =
    case markdown of
        Heading { level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.h2 [] children

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children

        Paragraph children ->
            Html.p [] children

        BlockQuote children ->
            Html.blockquote [] children

        Text content ->
            Html.text content

        CodeSpan content ->
            Html.code [] [ Html.text content ]

        Strong children ->
            Html.strong [] children

        Emphasis children ->
            Html.em [] children

        Link link ->
            case link.title of
                Just title ->
                    Html.a
                        [ Attr.href link.destination
                        , Attr.title title
                        ]
                        link.children

                Nothing ->
                    Html.a [ Attr.href link.destination ] link.children

        Image imageInfo ->
            case imageInfo.title of
                Just title ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        , Attr.title title
                        ]
                        []

                Nothing ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        ]
                        []

        UnorderedList { items } ->
            Html.ul []
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Block.NoTask ->
                                                    Html.text ""

                                                Block.IncompleteTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked False
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    Html.li [] (checkbox :: children)
                        )
                )

        OrderedList { startingIndex, items } ->
            Html.ol
                (case startingIndex of
                    1 ->
                        [ Attr.start startingIndex ]

                    _ ->
                        []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li []
                                itemBlocks
                        )
                )

        CodeBlock { body } ->
            Html.pre []
                [ Html.code []
                    [ Html.text body
                    ]
                ]

        HardLineBreak ->
            Html.br [] []

        ThematicBreak ->
            Html.hr [] []


{-| TODO: What does `extractText` mean in terms of Paragraphs, lists and code blocks?
-}
extractText : BlockStructure String -> String
extractText markdown =
    case markdown of
        Heading { children } ->
            children
                |> String.concat

        Paragraph children ->
            children
                |> List.intersperse "\n\n"
                |> String.concat

        BlockQuote children ->
            children
                |> String.concat

        Text content ->
            content

        CodeSpan content ->
            content

        Strong children ->
            children
                |> String.concat

        Emphasis children ->
            children
                |> String.concat

        Link link ->
            link.children
                |> String.concat

        Image _ ->
            ""

        UnorderedList { items } ->
            items
                |> List.map
                    (\item ->
                        case item of
                            Block.ListItem _ children ->
                                children
                                    |> String.concat
                    )
                |> String.concat

        OrderedList { items } ->
            items
                |> List.map String.concat
                |> String.concat

        CodeBlock _ ->
            ""

        HardLineBreak ->
            " "

        ThematicBreak ->
            " "



-- TRANSFORMATIONS


{-| Use this function if you want to parameterize your view by an environment.

Another way of thinking about this usecase is, use this if you want to 'render to
functions'.

Examples for such environments are:

  - A `Model`, for rendering to `Model -> Html Msg` for `view`.
  - Templating information, in case you want to use markdown as templates and want to
    render to a function that expects templating parameters.

Usually, for the above usecases you would have to define a function of type

    renderTemplate :
        BlockStructure (TemplateInfo -> Html msg)
        -> (TemplateInfo -> Html msg)

for example, so that you can turn it back into a `Renderer (Template Info -> Html msg)`
for elm-markdown.

If you were to define such a function, you would have to pass around the `TemplateInfo`
parameter a lot. This function will take care of that for you.

-}
parameterized :
    (BlockStructure view -> environment -> view)
    -> (BlockStructure (environment -> view) -> (environment -> view))
parameterized collapser markdown env =
    collapser
        (map (\expectingEnv -> expectingEnv env) markdown)
        env


{-| This transform enables validating the content of your `BlockStructure` before
rendering.

This function's most prominent usecases are linting markdown files, so for example:

  - Make sure all your code snippets are specified only with valid languages
    ('elm', 'javascript', 'js', 'html' etc.)
  - Make sure all your links are `https://` links
  - Generate errors/warnings on typos or words not contained in a dictionary
  - Disallow `h1` (alternatively, consider bumping the heading level)

But it might also be possible that your `view` type can't _always_ be collapsed from a
`BlockStructure view` to a `view`, so you need to generate an error in these cases.

-}
validating :
    (BlockStructure view -> Result error view)
    -> (BlockStructure (Result error view) -> Result error view)
validating collapser markdown =
    markdown
        |> collapseResults
        |> Result.andThen collapser


collapseResults : BlockStructure (Result error view) -> Result error (BlockStructure view)
collapseResults markdown =
    case markdown of
        Heading { level, rawText, children } ->
            children
                |> Result.combine
                |> Result.map
                    (\chdr ->
                        Heading { level = level, rawText = rawText, children = chdr }
                    )

        Paragraph children ->
            children
                |> Result.combine
                |> Result.map Paragraph

        BlockQuote children ->
            children
                |> Result.combine
                |> Result.map BlockQuote

        Text content ->
            Text content
                |> Ok

        CodeSpan content ->
            CodeSpan content
                |> Ok

        Strong children ->
            children
                |> Result.combine
                |> Result.map Strong

        Emphasis children ->
            children
                |> Result.combine
                |> Result.map Emphasis

        Link { title, destination, children } ->
            children
                |> Result.combine
                |> Result.map
                    (\chdr ->
                        Link { title = title, destination = destination, children = chdr }
                    )

        Image imageInfo ->
            Image imageInfo
                |> Ok

        UnorderedList { items } ->
            items
                |> List.map
                    (\(Block.ListItem task children) ->
                        children
                            |> Result.combine
                            |> Result.map (Block.ListItem task)
                    )
                |> Result.combine
                |> Result.map (\itms -> UnorderedList { items = itms })

        OrderedList { startingIndex, items } ->
            items
                |> List.map Result.combine
                |> Result.combine
                |> Result.map
                    (\itms ->
                        OrderedList { startingIndex = startingIndex, items = itms }
                    )

        CodeBlock codeBlockInfo ->
            CodeBlock codeBlockInfo
                |> Ok

        HardLineBreak ->
            HardLineBreak
                |> Ok

        ThematicBreak ->
            ThematicBreak
                |> Ok


{-| This function allows your renderer to access the raw text inside of your markdown
while rendering.

This can be useful for generating `title` attributes or heading slugs.

-}
extractingText :
    (BlockStructure view -> String -> view)
    -> (BlockStructure { rawText : String, view : view } -> { rawText : String, view : view })
extractingText collapser markdown =
    let
        rawText =
            extractText (map .rawText markdown)
    in
    { view = collapser (map .view markdown) rawText
    , rawText = rawText
    }



-- TODO: Make staticHttpRenderer work on BlockStructure instead of Markdown.Renderer
{-
    import Pages.StaticHttp as StaticHttp

    allStaticHttp : List (StaticHttp.Request a) -> StaticHttp.Request (List a)
    allStaticHttp =
        List.foldl (StaticHttp.map2 (::)) (StaticHttp.succeed [])

   staticHttpRenderer : Renderer view -> Renderer (StaticHttp.Request view)
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
                   combineListItemResults (Block.ListItem task results) =
                       results
                           |> allStaticHttp
                           |> StaticHttp.map (Block.ListItem task)
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

-}
