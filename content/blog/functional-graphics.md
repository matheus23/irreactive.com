---
{
  "type": "blog",
  "author": "Philipp Krüger",
  "title": "Declarative and Composable Graphics",
  "description": "A draft. (TODO CHANGE THIS)",
  "image": "/images/article-covers/mountains.jpg",
  "draft": true,
  "published": "2019-11-20",
}
---

When I first learned programming I always wanted to create games. There was just something fascinating about something moving on screen that you could interact with. To this day I believe that the human interface to computers is one of the most important parts of software. It has to be deliberate and elaborate and thought-through, doesn't it? You might argue that some applications don't demand much human interaction and imagine something like a command line interface that simply reports back an answer. But what if that program fails? How will you find out about the problem? Once you create black boxes you'll have to resort to other means of interacting with the computer that are much more complex.

Creating a good architecture for complex applications is really hard, though. After some experience using Swing/AWT, JavaFX and being frustrated with only the existence of built-in, rigid widgets that would never quite do what you wanted to, I was looking in the direction of the browser: There, lots of different, experimental user interfaces were created. And I believe it's the composable, and declarative nature of HTML elements (and the wide adoption and web standardisation process) that made it possible to create more of what one imagines. 

But even though the Web seemed to me like the most flexible UI platform, it is still pretty much impossible to create a solid rich text editor easily. (Trust me, I earned money for trying! That includes trying to find solid, existing solutions.) Once you start working with a deeper level of the web: Selected text, cursor position, etc. you'll quickly hit the Web's limitations.

What the Web increasingly improved upon was one direction I am much in favor of pursuing: Building GUIs in a functional and declarative way instead of an imperative, mutable-state, side-effect driven way. I really think designs like React's or Elm's are moving in the right direction. Away from mutable state `Component` classes like in most widget UI libraries like JavaFX, Qt or Gtk.

When I was pursuing this direction for myself, from a lower-level point, so that I could improve on the lower-level deficiencies of the browser (like for example not supporting measuring the height of text), I was thinking: What is the right design for creating graphics that is composable and declarative?

Today I will only focus on the lower-level of graphical user interfaces: Creating graphics. I am sorry for not delving into the details of event handling, layout or state management, yet, but stay tuned for the upcoming blog posts, if you're also interested in that.

## Graphics in Functional Programming Languages

What I have learned over the years is that ideas are rarely unique or original. There are many attempts at creating a graphics library in a functional programming language, the results are almost always declarative and composable in some way. I want to highlight some solutions I found out about when first researching this topic:

### Elm's collages

...

### Racket's Picts

Racket's picts are a library not for creating graphics for a real-world use case, but for education. The [racket tutorial](https://docs.racket-lang.org/quick/) uses them to introduce newcomers to the language or even programming itself.

...

### Haskell's Diagrams

...

### My DeclarativeGraphics

...

## Education

How about using this in education? ElmJr, Racket picts, Universität tübingen?

## What is the right way to do it?

All of them.

(Example: Drawing lines between elements in a diagram (rendering Trees, rendering connections in racket, etc.)
Example: Doing something like Drawing Dynamic Visualisations (!!).
Example: Having multiple layers but still be able to do 'besides' in what ever layer I want.)

Next blog post: All the different ways of composing monoids!
