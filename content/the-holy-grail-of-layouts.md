---
{
  "type": "blog",
  "title": "The Holy Grail of Layouts",
  "description": "A draft. (TODO CHANGE THIS)",
  "image": "images/article-covers/fittslist.png",
  "draft": true,
  "published": "2019-11-21",
}
---

* There are many kinds of layouts:
  - Flexbox
  - Css grid / Windows 10 grid layouts
  - display: block, inline-block, float
  - Figma Auto-Layout
  - SwiftUI layouts
  - UiKit layouts
  - Grid layouts
  - HBox / VBox in JavaFX / Gtk

* Spending a lot of time with Web layouts (which is not extensible) and JavaFX's way of extending layouts I've wondered what the most general way to create an abstraction for Layouts is.

* The most general layout is a function `Bounds -> Image`. All of the above layouts can be implemented in this way at the application boundary.

* However: This doesn't mean that there are no more open questions about layouts. I'm now confident that, given this runtime boundary, I won't make any layouts that would be desirable impossible to create, **but**: The individual layouts itself need to be implemented still. Why? `Bounds -> Image` is a bad type for layouts in general. If we force every UI element to have type `Bounds -> Image` and try to compose multiple of them, for example via `horizontalBox :: [Bounds -> Image] -> Bounds -> Image`, we won't have enough information to create a flexbox-style layout in `horizontalBox`.

* Still, this is not a bad start. Let's try improving on this. We noticed `horizontalBox` doesn't have enough information to distribute space unevenly, for example. What if one component wants to occupy 50% of the space and two other components should each get 25%.

* We could attach this information to each element by toupling a number that specifies the fraction it should take up (similar to css grid column fractions):

```purescript
type Bounds = (Number, Number)

horizontalBox :: [(Number, Bounds -> Image)] -> Bounds -> Image
horizontalBox elements (totalWidth, totalHeight) =
  let
    total = sum (map fst elements)
    renderElement (proportion, element) =
      element (totalWidth * proportion / total, totalHeight)
  in
  placeImagesBesides (map renderElement elements)
```

* This is great, but I'm still not happy with it. Something I have noticed with Web layouts is that they don't compose that well in depth. You always need to adjust your html element nesting to your layout needs. Let me illustrate:

```purescript
-- say we started development with this code:
-- Our goal is to create a form that basically displays two columns
-- that take up 50% of the space: A label and an input like this:
--   First name: [           ]
personForm :: Bounds -> Image
personForm =
  horizontalBox [ (0.5, firstNameLabel), (0.5, textInput) ]

firstNameLabel :: Bounds -> Image
firstNameLabel =
  (0.5, text "First Name:") -- 'text' is built-in

textInput :: Bounds -> Image
textInput = ...
```

* Now, we have a brilliant design idea: We add some kind of icon that displays that the given form input is required. We want it to sit on the right of our text input.

```purescript
-- Our goal is to create this layout:
--   First name: [           ] <icon>
personForm :: Bounds -> Image
personForm =
  horizontalBox [ (0.4, firstNameLabel), (0.4, textInput), (0.2, isRequiredIcon)]
```

* You notice that you use this kind of 'required text input'-pattern a lot around your code base. So you want to abstract this into its own component: A text input that automatically checks whether the text input has any text inside it and if not, renders the 'required' icon. (Of course, we haven't yet introduced a text input that actually renders anything, yet. As of now these are all only responsive images, but nothing that stores state. I'll get to that in another blog post. Let's keep it simple and focused for now. Where were we? Ah yes - our abstracted component:)

```purescript
personForm :: Bounds -> Image
personForm =
  horizontalBox [ (1.0, firstNameLabel), requiredTextInput ]

requiredTextInput :: ???
requiredTextInput =
  horizontalBox [ (1.0, textInput), (0.0, isRequiredIcon) ] -- TODO: Introduce a FlexLayout before. Otherwise these layouts don't make sense ;)
```

* It is not clear, what type `requiredTextInput` is supposed to have. The type that would be inferred form its *use site* in `personForm` would be `(Number, Bounds -> Image)`, but we would like to use `horizontalBox` in the *definition site* of `requiredTextInput`, which produces something of type `(Number, Bounds -> Image)`!

* Luckily, it's quite easy to fix this issue: Let's fix the return type of `horizontalBox` to return the additional `Number`. After all, we produce a number `total :: Number` in its definition that we immediately discard after using it! Instead, let's just return it:

```purescript
horizontalBox :: [(Number, Bounds -> Image)] -> (Number, Bounds -> Image)
horizontalBox elements (totalWidth, totalHeight) =
  let
    total = sum (map fst elements)
  in
  ( total
  , \(totalWidth, totalHeight) ->
    let
      renderElement (proportion, element) =
        element (totalWidth * proportion / total, totalHeight)
    in
    placeImagesBesides (map renderElement elements)
  )
```

* Hm. If you look at this, you'll see that we can beta-reduce (inline, whatever you want to call it) the usage of `requiredTextInput` in `personForm`:

```purescript
personForm :: Bounds -> Image
personForm =
  horizontalBox [ (1.0, firstNameLabel), horizontalBox [ (1.0, textInput), (0.0, isRequiredIcon) ] ]
```

* And we get two `horizontalBox`es wrapped inside each other. But it should be the same as this, right?

```purescript
personForm :: Bounds -> Image
personForm =
  horizontalBox [ (1.0, firstNameLabel), (1.0, textInput), (0.0, isRequiredIcon) ]
```

* And indeed, it is. So the wrapping lists inside lists is quite arbitrary. Hm. Can we get rid of this arbitrary-ness? Yes we can. In fact, lets simplify `horizontalBox` to just take 2 components as input and rename it to `besideHoriz`:

```purescript
besideHoriz :: (Number, Bounds -> Image) -> (Number, Bounds -> Image) -> (Number, Bounds -> Image)
besideHoriz (leftProp, left) (rightProp, right) =
  let
    totalProp = letProp + rightProp
  in
  ( totalProp
  , \(totalWidth, totalHeight) ->
    placeImagesBesides
      [ left  ( leftProp / totalProp, totalHeight)
      , right (rightProp / totalProp, totalWidth )
      ]
    )
```

* Our usage site now looks like this:

```purescript
personForm :: Bounds -> Image
personForm =
  snd ((1.0, firstNameLabel) `besideHoriz` requiredTextInput)

requiredTextInput :: (Number, Bounds -> Image)
requiredTextInput =
  (1.0, textInput) `besideHoriz` (0.0, isRequiredIcon)
```

* (Here, we use `besideHoriz` with the quotes, making it an infix binary operator.)
* The result is that we don't use any lists as intermediate data structure any more at all! Also: Look at `besideHoriz`: It forms a `Semigroup`! If we combine that with a neutral element:

  ```purescript
  neutralBeside :: (Number, Bounds -> Image)
  neutralBeside = (0.0, \_ -> zeroSizeImage)
  ```

  We get the more commonly known structure: A monoid! `neutralBeside` and `besideHoriz` form a monoid that respect the monoid laws (given that `placeImagesBesides` and `zeroSizeImage` form a lawful monoid).

Great! Now what have we learned?
* We can recreate layouts from within the language as long as we have functions, datatypes and a runtime boundary like `Bounds -> Image` (unlike CSS, which doesn't support this).
  At this point I should note that those kinds of layouts are also possible in JavaFX and other 