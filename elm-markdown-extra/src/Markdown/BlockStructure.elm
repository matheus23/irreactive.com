module Markdown.BlockStructure exposing (BlockStructure(..), renderToHtml, fromRenderer)

{-|

@docs BlockStructure, renderToHtml, fromRenderer

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Renderer as Renderer exposing (Renderer)


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


{-| -}
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


{-| -}
renderToHtml : BlockStructure (Html msg) -> Html msg
renderToHtml markdown =
    case markdown of
        Heading { level, rawText, children } ->
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

        CodeBlock { body, language } ->
            Html.pre []
                [ Html.code []
                    [ Html.text body
                    ]
                ]

        HardLineBreak ->
            Html.br [] []

        ThematicBreak ->
            Html.hr [] []
