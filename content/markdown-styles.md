---
{
  "type": "blog",
  "title": "Markdown Styles",
  "description": "A test file with lots of different markdown features for testing styling.",
  "image": "images/article-covers/typography.jpg",
  "draft": false,
  "published": "2020-05-14",
}
---

A paragraph of Text! Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.

# Heading 1

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.

## Heading 2

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.

### Heading 3

Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam.

#### Heading 4

Let's write some code.

---

```elm
renderMarkdown
  : Scaffolded.Block (AnchorValidation.Validated (Html Msg))
  -> AnchorValidation.Validated (Html Msg)
renderMarkdown block =
    case block of
        Scaffolded.Heading _ ->
            handleHeading block

        Scaffolded.Link { destination } ->
            handleLink block destination

        _ ->
            handleOther block

-- For headings we generate anchors with
-- `mapWithGeneratedAnchor`
handleHeading block =
    block
        |> AnchorValidation.fold
        |> AnchorValidation.mapWithGeneratedAnchor
            (\anchor -> Scaffolded.foldHtml [ Attr.id anchor ])

-- For links we validate, that their links are fine.
-- validateLink would generate an error otherwise.
-- validateLink also only validates links that start with "#".
handleLink block destination =
    block
        |> AnchorValidation.fold
        |> AnchorValidation.validateLink destination
        |> AnchorValidation.map (Scaffolded.foldHtml [])

-- Anything else just propagates the validation,
-- but doesn't do anything special
handleOther block =
    block
        |> AnchorValidation.fold
        |> AnchorValidation.map (Scaffolded.foldHtml [])
```

This code has some problems:

1. It's just way too much code horizontally for me to handle
2. Does it have any styling so far?
3. I'd love to have a computer assist me in understanding this abstract wall of text.
