---
{
  "type": "blog",
  "title": "Declarative and Composable Graphics",
  "description": "A draft. (TODO CHANGE THIS)",
  "image": "images/article-covers/mountains.jpg",
  "draft": false,
  "published": "2019-11-20",
}
---

[Let's test this link!](#mathematics)

Have you seen what creating 2D graphics looks like in Cairo, Java AWT, Processing or the Web Canvas? What you'll see is an imperative API along the lines of this:

```js
moveTo(100, 100);
setFillStyle("red");
circle(20);
stroke();
moveTo(200, 100);
setFillStyle("blue");
rectangle(50, 30);
fill();
```

My subjective experience seems to be that more and more people are building a functional interface on top of this imperative API. The comparable pseudo-code looks like this:

```hs
scene =
  superimposed
    (moved 200 100
      (filled "blue" (rectangle 50 30))
    (moved 100 100
      (stroked "red" (circle 20)))
```
(superimpose == put one above the other)

Notice that I used ML-style syntax for this statement, so syntax similar to Haskell, OCaml and Elm: Using spaces for function application; multiple arguments are applied with multiple spaces; you can parenthesise an expression to group it and apply it as a single argument. The equivalent in javascript syntax would look like this:

```js
const scene =
  superimposed(
    move(200, 100,
      filled("blue", rectangle(50, 30))),
    move(100, 100,
      stroked("red", circle(20))
  );
```

Think of such an API as having immutable objects for graphical primitives like circles, rectangles, etc. It is then possible to wrap these objects in wrappers that then represent translated or colored objects (without modifying the original graphic). The result of all functional drawing will then be a single object that represents all of your graphical scene, composed of wrappers of wrappers of primitive objects, similar to a scene graph, if that means something to you.

So, I mentioned my subjective experience is that more and more programmers are switching to this kind of functional interface. Why would they do that extra work?

The new interface has concrete advantages:

1. Code modification has a very clear scope: Imagine you're only allowed to change the last line of our example (the second argument to `superimposed`). It will be impossible to change the color of the rectangle! In general, you can only change graphics by wrapping them. Combining two graphics will not change the appearance of either one. This is not the case with the imperative API. Take a look at these two functions:

```js
function myCircle() {
  translate(100, 100);
  setFillStyle("red");
  circle(20);
  stroke();
}
function myRectangle() {
  translate(200, 100);
  rectangle(50, 30);
  fill();
}

myCircle();
myRectangle();
```

You might expect that removing the `myCircle()` call would just remove the circle from our picture, but that is wrong! Unfortunately, `translate` has these mutable semantics: It will change any drawing calls in the future! The same is true for `setFillStyle`. However, `translate` is quite useful: If you used it everywhere, then you can specify the position of elements from outside their definition, and therefore re-use a graphic-generating function for the same scene at two different positions.

Generally it is nice to have these guaruntees like *'removing a call to a graphical primitive only removes it from the scene and has no other effects'*: In bigger codebases, you'll want to know exactly what effect removing or adding a line of code can have. If it is possible that removing a line of code has a side-effect on the rest of your project, it becomes hard to maintain.

2. Abstraction is easier: Let's abstract out a combinator that puts two graphics next to each other 100 pixels apart:

```hs
besides left right =
  superimpose left (move 100 0 right)

scene =
  move 100 100
    (besides
      (filled "blue" (rectangle 50 30))
      (stroked "red" (circle 20)))
```

It is nice to be able to define 'combinators' like `besides`. Sometimes we want to abstract (= give names to) a *way of changing* graphics, not only particular graphics themselves.

I think this advantage is mostly practically true, but not theoretically: It is possible to abstract statements in javascript for example, by passing functions. However, in languages like Java or C++ this used to be harder, as only objects could be passed as a parameter to functions, not functions themselves (functions are said to not be *first class*).


# Mathematics

We'll now shift up a gear. The following sections require some familiarity with ML-style programming languages.

What follows next is an introduction to monoids, an abstraction from mathematics often used in haskell and similar languages. I would love to leave the boring introductory bit out, but it's crucial to understand almost everything I'm going to write on this blog. Let me at least motivate them, before I introduce the definition.

These two points are supposed to convice you of the utility of monoids:
* Monoids are one essence of composition: they capture the ability to combine multiple elements into another element that can be combined again.
* Monoids are everywhere in functional programming. There are countless monoid instances across the haskell ecosystem and many abstractions are built on top of monoids.
Now let's get to the definition!

Our graphics are in a way actually like numbers. 'What?' you might say, but hear me out! They have something simple in common: You can merge/combine multiple into one. In haskell, we can define a datatype for everything that is a Monoid:

```hs
data Monoid a = Monoid
  { empty :: a
  , combine :: a -> a -> a
  }
```

(This is the definition of something like the type of a struct or record. `a` is a generic type parameter, the `::` is read as `has type`. The `->` is called the 'function arrow'. `Int -> Int -> Int` is the type of a function that takes two integers as arguments and returns an integer.)

As you can see, monoids also include a reference to an `empty` element. This element is what you'd get if you combine 0 things. It is supposed to not have any effect if combined with other elements.

Multiple numbers can be combined into one number in infinitely many ways. Two very important ones are sums and products, let's declare two values of type `Monoid Int` for these two respectively.

```hs
sumMonoid :: Monoid Int
sumMonoid = Monoid
  { empty = 0
  , combine = (+)
  }

productMonoid :: Monoid Int
productMonoid = Monoid
  { empty = 0
  , combine = (*)
  }
```

Speaking of many ways to combine many numbers into one, many of these don't form monoids. The mathematical definition requires two laws:
* The `empty` element must not have an effect when `combined` with an element: for any `x`, `combine x empty == x` and `combine empty x == x`.
* Parenthesis around multiple `combine` expressions must not matter:

  for any `a`, `b` and `c`, ``a `combine` (b `combine` c) == (a `combine` b) `combine` c``

This is true for sums and products, but not for `(-)`, for example. Also notice that monoids don't require that you're able to swap the order of arguments to `combine`! Even though sums and products fulfill that law, this commutativity law is not required for monoids.

I promised this post would be about graphics so here's a monoid declaration for graphics:

```hs
data Graphic = ...

superimposingMonoid :: Monoid Graphic
superimposingMonoid = Monoid
  { empty = emptyGraphic
  , combine = superimpose
  }
```

This definition checks all checkmarks for the monoid laws:
* Identity: The `empty` graphic shouldn't have an effect on another graphic if `combine`d (superimposed) on top of or below it.
* Associativity: This is hard to explain in text. Imagine each graphic as a sheet of cardboard. It doesn't matter what graphics we 'glue together' first, as long as the order of graphics is the same.
(Aside: Graphic superimposition doesn't fulfill the aforementioned commutativity law, unlike sums and products!)

Now what? We defined this `Monoid a` type and inhabit it with some values, but what gives?

Let's define a function that combines multiple monoidal values into one, given a monoid:

```hs
combineAll :: Monoid a -> List a -> a
combineAll (Monoid empty combine) list = foldl' combine empty list
```

(We are re-using haskell's `foldl'` function here that folds over a list and combines elements using the first argument. In javascript and many other languages this function is called `reduce`.)

Now that we have this definition, we can combine a list of `Graphics` into one via `atopAll graphics = combineAll superimposingMonoid graphics`. We could use `combineAll` for sums and products as well, but that would be boring, so let's create another instance of monoids. Let me introduce our next guest:

## Sized Graphics

```hs
-- invariant: width and height must be non-negative
data Size = Size { width :: Double, height :: Double }

data Form = Form
  { graphic :: Graphic
  , size :: Size
  }
```

We use the short-hand `Form` to mean a graphic that has a size attached to it, because `SizedGraphic` is a mouthful in type signatures. The name is an hommage to [Elm's original graphics library](https://package.elm-lang.org/packages/evancz/elm-graphics/latest/Collage#Form) (although similar, Elm's `Form`s shouldn't be confused with ours. They are more like our `Graphic`s).

First of all, `Size`s are monoids!

```hs
maxSizeMonoid :: Monoid Size
maxSizeMonoid = Monoid
  { empty = Size 0 0
  , combine = \(Size widthA heightA) (Size widthB heightB) ->
      Size (max widthA widthB) (max heightA heightB)
  }
```

Now our `Form`s consist of two monoids: `size :: Size` is a monoid via `maxSizeMonoid` and `graphic :: Graphic` is a monoid via `superimposingMonoid`. If we have a structure of two things that are monoids, the resulting structure is a monoid too:

```hs
formMonoid :: Monoid Form
formMonoid = Monoid
  { empty = Bounded (empty superimposingMonoid) (empty maxSizeMonoid)
  , combine = \(Bounded graphicA sizeA) (Bounded graphicB sizeB) ->
      Bounded
        (combine superimposingMonoid graphicA graphicB)
        (combine maxSizeMonoid sizeA sizeB)
  }
```

> TODO: Insert Demo to play with monoids

What is this `Form` thing we have now? If we combine two forms (which consist of sizes and graphics) we get a form that has combined graphics and combined sizes. So the idea is that these forms are paired with their actual size. This size could be used for various things:

* Check whether a click was within the bounding rectangle of a form
* Render a background or border to a form
* Place two forms side by side

Placing two forms side by side is again a way of combining forms, and - you guessed it - is another monoid on forms:

```hs
movedForm :: Double -> Double -> Form -> Form
movedForm translateX translateY (Bounded graphic size) =
  -- re-using `moved` for graphics.
  Bounded (moved translateX translateY graphic) size

besidesFormMonoid :: Monoid Form
besidesFormMonoid = Monoid
  { empty = empty formMonoid
  , combine = \formA formB ->
      combine formMonoid
        formA
        (movedForm (width (size formA)) 0 formB)
  }

besides forms = combineAll besidesFormMonoid forms
```

> Insert playground for 'besides': resizable circles and rectangles?

In this case we made quite some assumptions about how to combine forms side by side: We assume that
* forms are placed from left to right
* if two forms overlap (even though their sizes say they shouldn't), the left one is above the right one
* the forms are supposed to align at their top border
* there should be no gap between the forms when placed side by side.

It is possible to work around the last issue with our current abstraction by sandwiching an empty form with the size of the desired gap between two consecutive elements.

It would be interesting to provide more monoid definitions for forms that allow for different alignment, direction and order choices, but that's left as an exercise for the reader.

Racket-lang's pict library lives at this abstraction layer. Their `picts` are pretty much the same as our forms. They've also built a [library of combinators](https://docs.racket-lang.org/pict/Pict_Combiners.html) for their picts. These combinators allow you to also align on the center line, start or end.

I'm not much of a fan of a restricted set of options for things like this: There are infinite ways to align two forms placed side by side. Restricting the options creates problems:
* What if you want to align an image with the baseline of some text?
* What if you want to align an image with a visual baseline with the baseline of some text, as in [this SwiftUI demo](https://www.youtube.com/watch?v=u6ImPjD8dT4&feature=youtu.be&t=1110)?
* What if you want to align the top border of a form with the bottom border of a form?

Web's flexbox layouts have similar deficiencies: the allowed values for `align-items` are `flex-start`, `flex-end`, `center`, `baseline` and `stretch` (?).

Let's fix these deficiencies with our last guest:

## Bounded Graphics

```hs
data Bounds
  = Bounds
    { toLeft   :: Double
    , toRight  :: Double
    , toTop    :: Double
    , toBottom :: Double 
    }
  | Empty

data Diagram = Diagram
  { graphic :: Graphic
  , bounds :: Bounds
  }
```

Let me introduce `Diagram`s, which are graphics with bounds. These bounds are not like `Size`: Not only do they represent width and height, they also implicitly store position relative to an origin, by encoding size as distances to the 4 respective borders of a graphic.

Again, `Bounds` has a valid monoid definition:

```hs
maxBoundsMonoid :: Monoid Bounds
maxBoundsMonoid = Monoid
  { empty = Empty
  , combine = maxBounds
  }

maxBounds :: Bounds -> Bounds -> Bounds
maxBounds Empty a = a
maxBounds a Empty = a
maxBounds a b = Bounds
  { toLeft   = max (toLeft a)   (toLeft b)
  , toRight  = max (toRight a)  (toRight b)
  , toTop    = max (toTop a)    (toTop b)
  , toBottom = max (toBottom a) (toBottom b)
  }
```

And with this we have a boring monoid definition for superimposing our `Diagram`s using `superimposingMonoid` and `maxBoundsMonoid`. So let's instead work towards the definition for placing diagrams side by side. For that, we'll need to be able to translate diagrams, and that's not as straightforward as it was when we only stored a position-independent `Size`. This time, `Bounds` have to be translated, too:

```hs
movedBounds :: Double -> Double -> Bounds -> Bounds
movedBounds translateX translateY bounds =
  case bounds of
    Empty -> Empty
    (Bounds toLeft toRight toTop toBottom) -> Bounds
      { toLeft = toLeft + translateX
      , toRight = toRight - translateX
      , toTop = toTop + translateY
      , toBottom = toBottom - translateY
      }
```

* Go crazy with more monoids:
- Bounds (with origin: distance to top, left, right and bottom edge)
- Bounds as a function of a directional vector (maybe not.. :D )
* More monoids:
- Multiple layers?

* Write more about what the laws give us:
- Advantage of the definition of a Monoid: Get combinators that work across all monoids: concatting lists of monoid elements
- Advantages of the two laws of monoids:
- Associativity: Parenthesis doesn't matter! You'll always be able to abstract over a 'continuous' streak of monoids! (imagine a part of a list in an 'mconcat')
- Identity element: Imagine abstracting over something in the graphic: Putting empty in this graphic will always just remove it / have no effect!

# More power to our graphical primitives!

* More power to our graphics: Give them a size, and let them be placed side by side.
* More power to our graphics: Give them an origin to allow them to be placed besides with alignment! (and allow rendering lines between their origins!)
* More power to our graphics: Give them multiple layers! This will allow them to be be placed relative to each other but on different layers!

If you want to take a look at some actual implementations of these 'newer' APIs, here is an incomplete list of them:
* Elm's collages
* Racket's Picts
* Haskell's Diagrams






When I first learned programming I always wanted to create games. There was just something fascinating about something moving on screen that you could interact with. To this day I believe that the human interface to computers is one of the most important parts of software. It has to be deliberate and elaborate and thought-through, doesn't it? You might argue that some applications don't demand much human interaction and imagine something like a command line interface that simply reports back an answer. But what if that program fails? How will you find out about the problem? Once you create black boxes you'll have to resort to other means of interacting with the computer that are much more complex.

Creating a good architecture for complex applications is really hard, though. After some experience using Swing/AWT, JavaFX and being frustrated with only the existence of built-in, rigid widgets that would never quite do what you wanted to, I was looking in the direction of the browser: There, lots of different, experimental user interfaces were created. And I believe it's the composable, and declarative nature of HTML elements (and the wide adoption and web standardisation process) that made it possible to create more of what one imagines. 

But even though the Web seemed to me like the most flexible UI platform, it is still pretty much impossible to create a solid rich text editor easily. (Trust me, I earned money for trying! That includes trying to find solid, existing solutions.) Once you start working with a deeper level of the web: Selected text, cursor position, etc. you'll quickly hit the Web's limitations.

What the Web increasingly improved upon was one direction I am much in favor of pursuing: Building GUIs in a functional and declarative way instead of an imperative, mutable-state, side-effect driven way. I really think designs like React's or Elm's are moving in the right direction. Away from mutable state `Component` classes like in most widget UI libraries like JavaFX, Qt or Gtk.

When I was pursuing this direction for myself, from a lower-level point, so that I could improve on the lower-level deficiencies of the browser (like for example not supporting measuring the height of text), I was thinking: What is the right design for creating graphics that is composable and declarative?

Today I will only focus on the lower-level of graphical user interfaces: Creating graphics. I am sorry for not delving into the details of event handling, layout or state management, yet, but stay tuned for the upcoming blog posts, if you're also interested in that.

# Graphics in Functional Programming Languages

What I have learned over the years is that ideas are rarely unique or original. There are many attempts at creating a graphics library in a functional programming language, the results are almost always declarative and composable in some way. I want to highlight some solutions I found out about when first researching this topic:

## Elm's collages

...

## Racket's Picts

Racket's picts are a library not for creating graphics for a real-world use case, but for education. The [racket tutorial](https://docs.racket-lang.org/quick/) uses them to introduce newcomers to the language or even programming itself.

...

## Haskell's Diagrams

...

## My DeclarativeGraphics

...

# Education

How about using this in education? ElmJr, Racket picts, Universität tübingen?

# What is the right way to do it?

All of them.

(Example: Drawing lines between elements in a diagram (rendering Trees, rendering connections in racket, etc.)
Example: Doing something like Drawing Dynamic Visualisations (!!).
Example: Having multiple layers but still be able to do 'besides' in what ever layer I want.)

Next blog post: All the different ways of composing monoids!
