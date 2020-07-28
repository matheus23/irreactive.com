---
{
  "type": "blog",
  "title": "Improving Declarative APIs for Graphics with Types",
  "description": "Declarative APIs are the future. Types make them much easier and fun to work with. Read more to get an intuition for types in this usecase!",
  "image": "images/declarative-apis/thumbnail.jpg",
  "draft": false,
  "published": "2020-07-28",
}
---

Graphics and user interface programming APIs are rapidly changing nowadays with framworks like Elm, React, Vuejs, Flutter, SwiftUI and more surfacing within the last 8 years. They're moving towards immutability and declarativity. More and more often user interfaces are programmed using 'DOM-Models' like HTML and CSS with state management not via classes and objects, but with something similar to reducers and immutable state in React/Redux. HTML is declarative, which I believe is the right direction to move in, but there's still a lot to improve.

Today I'll explain why I spend way too much of my free time thinking about declarative APIs and how to improve them even further with types. But before I get into that, first let's look at an imperative API such as this one for creating graphics:

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

**The code part is interactive**: You can **click on lines** to enable/disable them, go play with it!

Were you surprised by what happened when you turned off some lines? Now imagine a beginner dipping their toes into computer graphics for the first time. What would they stumble upon?

* No shapes appear unless there is a call to `fill` or `stroke`, even if there are calls to `circle` or `rectangle`.
* What's the default color if there was no call to `setColor`? Let's hope it's not transparent.
* Shapes are placed at the position of the last `moveTo` call if there hasn't been a `moveTo` call in between.
* What happens if you draw two shapes at the same position? Which one comes out at the top?

The order and existence of statements plays a huge role in the outcome, but you can delete and re-order statements without getting an error.

I find it helpful to understand the shortcomings of alternatives to understand the strengths of declarative APIs.

So let's look at a declarative API.

# A Declarative API

The imperative API is modeled after a real-world analogy of a person with a pencil, who is instructed what to do:

* "Move your pencil to 100, 100."
* "Use the red pencil."
* "Sketch a circle with radius 20."
* "Outline your sketch."
* "Move your pencil to 200, 100."
* "Use the blue pencil."
* "Sketch a rectangle with width 50 and height 30."
* "Fill in your sketch."

The analogy of the declarative API works more like a higher-level explanation of a picture:

"The picture consists of two objects on top of each other:
* At 200, 100, a blue filled rectangle with width 50 and height 30 and
* at 100, 100, a red outlined circle with radius 20."

<in-margin>
<info title="Info: About the programming language in following code examples.">
I'll be using ML-style syntax for my examples in functional programming languages. Other languages with this style are for example:

* Haskell
* Elm
* Standard ML

If you're familiar with any of these languages, skip ahead!

If not, here's a short crash-course:

```elm
-- a list (array) of the numbers 1, 2, 3, 4:
[1, 2, 3, 4]

-- a function call, like to sin(10):
sin 10

-- a function call, like arcTan2(100, 20):
arcTan2 100 20

-- you can group arguments (expressions)
-- with parenthesis:
arcTan2 (sin 50) 10
-- is like arcTan2(sin(50),10)
```
(Please ignore confusing syntax highlighting.)

Everything in these languages is an expression. What does this mean exactly?

* All functions return a value. There is nothing similar to a `void` return type.
* There are no statements. Statements discard return values, but _return values are the only thing you get_ from functions in functional programming languages. So instead, you can only assign return values to names (constants) for use later in the program.

Other than that, it's not a _real_ programming language. My code examples should be interpreted as pseudo-code.
</info>
</in-margin>

The declarative code that is the equivalent of the first (imperative) code sample looks like this:

```elm interactive
superimposed
    [ moved 200 100
        (filled "blue" (rectangle 50 30))
    , moved 100 100
        (outlined "red" (circle 20))
    ]
```

Again, this is an interactive code example. You can click on things to toggle them on or off. What you'll notice is:

* If you disable a `moved`, whatever was wrapped with that `moved` is somewhere else.
* If you change a color, whatever was wrapped with that `filled` or `outlined` call has another color.
* If you disable an element from the list of elements in `superimposed` (click on `[` or `,`), it'll disappear from the image.

What's different to before is that no other elements on the screen were affected by these changes. Every change has local effects.

The defining characteristic of declarative APIs is that they're _expression-based_. Every item is an expression, like `cicle 20`, or something that wraps expressions and becomes an expression by itself, like `moveTo 100 100`.

# Types and Declarative APIs

Something I skipped, but you might have noticed: In the above interactive example it's possible to trigger a type error by disabling `filled` or `outlined`. The ability to guide a user towards correct code using types is what takes declarative APIs to another level.

The reason we get a type error in some cases is that we plugged two expressions together, which don't fit to each other. Let's embrace this metaphore of 'fitting together'. Let's imagine, every expression is like a Lego brick. But unlike Lego, they're kind of elastic and can be stretched and squeezed. Other than that, they only fit together when their 'connectors' fit into each other.

<VideoCaptioned
  id="expression-block-shapes"
  src="declarative-apis/expression-block-shapes.mp4"
  alt="Expression Block Shapes Transformation"
  loop=""
>
How code and its Lego Brick version correspond.
</VideoCaptioned>

This might remind you of code in an educational programming platform called '[Scratch](https://scratch.mit.edu/)'. And indeed, it is quite similar, especially if you look at the individual blocks one by one:

<ImgCaptioned
  id="expression-blocks"
  src="images/declarative-apis/expression-blocks.svg"
  alt="All Expression Blocks one by one"
  width="362px"
>
All different expression types imagined as Lego bricks, one by one. Round bricks are of type stencil, pointy bricks of type picture and half-circle connectors are for lists.
</ImgCaptioned>

And I think this trick is very effective at creating an intuition for types, so I'm using it here. You can clearly see how a `circle` expression could not fit cleanly into a `moveTo` expression, but into an `outlined` expression.

So, going back to our original example, we have two important types at play:
* **Stencil**s: Something like `circle 20` is a stencil, something that doesn't yet have a defined color or exact shape (filled or outlined or with a pattern?).
* **Picture**s: Something that's visually defined and could be rendered to screen immediately.

Therefore, if we disable `filled`, we plug `rectangle 50 30` into a `moveTo`, which can't handle that. `rectangle 50 30` has type `Stencil`, but `moveTo` can't handle moving `Stencil`s, it expects `Picture`s.

<ImgCaptioned
  id="expression-blocks-dont-fit"
  src="images/declarative-apis/expression-blocks-dont-fit.svg"
  alt="Expression Blocks that don't fit"
  width="324px"
>
A type error in the Lego-brick- or Scratch-like analogy.
</ImgCaptioned>

Without type checking, we have to

* throw an error ("exception") at runtime, when `moveTo` is faced with something it doesn't expect or
* let `moveTo` ignore anything that's not a `Picture`.

In the case of browsers - due to having to be as error-forgiving as possible - they went with the second option.

* You can create HTML `tr` tags anywhere, even though they're meant to be used in `table` or `tbody`.
* You can apply the CSS property `flex-grow` to any HTML element, whether it's a child of a `display: flex` (flexbox) element, or not.
* You can apply the CSS property `position: sticky` on a `tr` tag, but it won't do anything.

But if all the browser is doing is _nothing_, then you're left wondering why your code doesn't have any effect!

And this type analysis happens at _compile time_, so you'll know there's something wrong _before_ you run your code with actual data.

The above list is by no means exhaustive. There's lots and lots of examples and exceptions about when certain elements, attributes or CSS styles work and it's hard to know about all edge cases.

While HTML and CSS are declarative, they're not typed. The declarative-ness is awesome: You can take some HTML and its associated styling and plug it somewhere else!
But it might not be styled as you expected, because you missed a property on a wrapping element.

Types can allow you to be explicit about these kinds of wrapper- to wrapped element relationships. By having these types you document and enforce the relationships and reduce the amount of head-scratching-inducing code that is deemed valid by a linter (i.e. a compiler/interpreter).

**Declarative APIs are only half as effective if you're not using types.**

# One more thing

Usually, when we're writing functional programs, we don't use tools that are as visual as these Lego- or Scratch-like blocks.
But when you're used to reading type declarations, you'll see that the same information can be obtained:

```elm
-- read ':' as 'has type'
rectangle 50 30 : Stencil
circle 20       : Stencil
-- '->' is the function arrow.
-- read it as 'from X to Y'
filled "blue"  : Stencil -> Picture
outlined "red" : Stencil -> Picture
moved 100 100  : Picture -> Picture
```

Types are therefore not only a tool for preventing mistakes, but also a documentation tool for discovering the previously hidden 'rules' of a particular declarative API.

# Going further

The points in this blog post go beyond just _graphics_ APIs. Expression-based programming with types (a.k.a. _functional programming!_) can be applied widely. Nonetheless, I'm personally very interested in finding good solutions for graphics APIs and especially user interface programming, so I want to take this principle further:

* What about responsive pictures? Layout? Tables? Grids?
* What about interaction? Clicking things, click regions, focus? State?
* What about animation?

There is still much to (dis)cover. If you want to jump into the rabbit hole of what's been discovered already, see some of these awesome resources:

* [Phil Freeman's blog](https://blog.functorial.com/) about state management in purely functional graphical applications
* The Paper [Monoids: Themes and Variations](https://repository.upenn.edu/cgi/viewcontent.cgi?article=1773&context=cis_papers) with some answers to the questions above (and something my future posts are going to be based upon).

Now, if you've come this far and feel like this article is worth sharing, please consider [tweeting a link](https://twitter.com/intent/tweet?text=I%20just%20read%20this%3A%20https%3A%2F%2Firreactive.com%2Fdeclarative-apis).

Oh, and if you want to discover these topics together with me, you can follow [me on twitter](https://twitter.com/matheusdev23) or use the E-Mail form below. Thanks!
