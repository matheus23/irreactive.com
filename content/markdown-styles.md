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

How about some inlines? **Bold Text** and _italics_? Should look nice! Also, I'm pretty sure I'll use `code spans` a lot.

---

# H1
## H2
### H3
#### H4


Let's write some code.

---

### Phantom Types

```elm
{-| Shows how to create a phantom type
-}
type Unit a
    = Unit Int


{-| When adding two units, the type parameter must be the same.
-}
addUnit : Unit a -> Unit a -> Unit a
addUnit (Unit first) (Unit second) =
    Unit (first + second)


{-| A type to be used with the above Unit type
-}
type Meter
    = Meter


{-| A second type to be used with the above Unit type
-}
type Gram
    = Gram


twoMeters : Unit Meter
twoMeters =
    Unit 2


threeMeters : Unit Meter
threeMeters =
    Unit 3


fewGrams : Unit Gram
fewGrams =
    Unit 21


someMeters : Unit Meter
someMeters =
    -- This works because the two units match
    addUnit twoMeters threeMeters


{- This value will throw an error if uncommented
   impossibleAdd : Unit Meter
   impossibleAdd =
       -- This doesn't work because the types don't match
       addUnit fewGrams someMeters
-}
```

<in-margin>
Like this text in the margin for example.
</in-margin>

Sometimes I want to explain something with some information attached to the side. This is then inside the margin on wider screens and in the flow of the text on smaller screens.

<in-margin>
<info title="Here's an interactive code example">
You can

* Click on lines to enable/disable them
* Click on colors to cycle through them

```js interactive
moveTo(100, 100);
setColor("red");
circle(20);
stroke();
moveTo(200, 100);
setColor("blue");
rectangle(50, 30);
fill();
```
</info>
</in-margin>

But it can also be way more complicated things. For example interactive code examples in information boxes.

Code works fine. We get it. How about ordered lists?

This code has some problems:

1. It's just way too much code horizontally for me to handle
2. Does it have any styling so far?
3. I'd love to have a computer assist me in understanding this abstract wall of text.

You know, that's fine and dandy and all, but what about lists that don't start at 1? Also, they might get multi-digit!

9. It's a pretty high number, crazy right?
10. Even higher.

<remove reason="Remove because this is just too cheesy writing. Damn.">
Studies showed, sometimes numbers are just too much. Let's go for dots:

* This is a dot
* And this one as well.
- Here, our dots begin again. Imagine!
- It's amazing.

---

Our dot's should look pretty nice when aligning to code:

* we mark our code beginning with dots

```js
moveTo(100, 100);
setColor("red");
circle(20);
stroke();
moveTo(200, 100);
setColor("blue");
rectangle(50, 30);
fill();
```

* And now we mark it as done. Point.
</remove>