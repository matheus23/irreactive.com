---
{
  "type": "blog",
  "title": "Software Design by Abstraction",
  "description": "There is a lot of literature about Object Oriented Software Design, usually thick books with lots of guidelines. In comparison, there is very little literature about Software Design of Functional Programs. Often people ask about the 'Patterns' of Functional Programming, but I believe the solutions is to stop pressing your Programs to adhere to patterns, but instead evolve your own patterns for your domain.",
  "image": "images/other/hello.jpg",
  "draft": true,
  "published": "2019-11-28",
}
---

When writing functional programs in statically typed programming languages, we work with types _a lot_. It is common practice to extract out useful functions into top-level definitions, and then give these top-level definitions a type signature. Additionally, in a project of mine, I analized what percentage of definitions (in some open-source Elm projects) are type-definitions (not counting type annotations!), and which are ordinary definitions. It turned out that about 20% of definitions are types (though, these definitions tend to be smaller than ordinary definitions).

When I think about what I miss from say, Elm or Haskell, in other programming languages, I'm always thinking of two things: Immutable values (managing side-effects!) and types.

To me, types are central to the benefits of functional programming languages.

Now, why do we write out types so much, actually? Why do we force ourselves to annotate every top-level definition with a type, when many of today's functional, statically-typed programming languages have type interference, so they figure out the type of an expression by analizing it. No need for type annotations.

At first, it might seem that the benefit of types is just to prevent us from runtime crashes. For example, when we're trying to access some field which doesn't exist:

```javascript
const person = {
  id: '102049',
  metadata: {
    name: 'Philipp',
    age: 23,
  },
};

console.log(person.name);
```

And indeed, types would absolutely prevent us from making this mistake and causing a runtime failure.

However, why should we annotate the type? Annotating the type is not neccessary to prevent that runtime failure. Simply check that file with typescript, and you'll get an error:

```
error TS2339: Property 'name' does not exist on type
'{ id: string; metadata: { name: string; age: number; }; }'.
```

Sweet. The same goes for Haskell, Elm and other statically typed programming languages with a type inferencer (most have them). So why are we annotating types again?

# Types are Specifications

I could have also said that 'types are documentation', which is a very common expression, but I think it goes further than that. When I say 'documentation' that wouldn't imply the consistency by which types actually specify the definitions.

Let's make an example. Let's say, we're working on some website. Let me come up with something totally unrelated, real quick. Yeah, what about a blog?

In this blog, I'm writing my blog posts as markdown files, but the resulting datastructure is not ascii markdown, but html. However, it's more complicated than `String -> Html msg` (TODO: explain `msg`):

* Parsing markdown can fail (that's not the case for every parser, but in my case, it is)
* 

It's type is this:

```elm
render : String -> Result String (Model -> List (Html Msg))
render markdown = ...
```

This type annotation tells us a lot of information!

---

Let's imagine: You think your thoughts are _oh so valueable_, so you decide to create a blog. You write your blog posts in markdown and generate Html for them by writing your own code.

You decide: Writing your own markdown parser is a bad idea. You take a look at what parsers are out there.

You also decide to use elm, so that your blog post _\<insert title here\>_ can show example code in elm.

There are two libraries that expose markdown parsing. The data structure that these libraries parse markdown to is essentially the same. We'll call that `Markdown.Block`. Such a markdown block represents a single markdown paragraph or other object. A markdown file usually consists of multiple of these, each of them separated with two or more newlines from the others.

```markdown
This is the first markdown block.

`this` is a keyword in java and another markdown block.

* A list of things is
* also a markdown block
* pretty succinct and clear
```

To decide, which library you'll use, you take a look at the types of their `parse` function:

```elm
-- Markdown library 1:
parse : String -> Result String (List Markdown.Block)

-- Markdown library 2:
parse : String -> List (Result String Markdown.Block)
```

Which one will you choose?

# The power of types

These two types are not equivalent. Wait, _what are equivalent types?_

```elm
mathFunction1 : Int -> Int -> Int
mathFunction2 : (Int, Int) -> Int
```

Those two are equivalent. My argument as to why is simple. If you had either function, you can 'derive' the other:

```elm
mathFunction1is2 : (Int -> Int -> Int) -> ((Int, Int) -> Int)
mathFunction1is2 mathFunction1 =
    \(x, y) -> mathFunction1 x y

mathFunction2is1 : ((Int, Int) -> Int) -> (Int -> Int -> Int)
mathFunction2is1 mathFunction2 =
    \x y -> mathFunction2 (x, y)
```

So, generally, I'll say two types `A` and `B` are equal, when there exists a function `A -> B` and `B -> A`. If we replace `A` with `Int -> Int -> Int` and `B` with `(Int, Int) -> Int` you'll get the two type signatures above.

I'd like to convince you to think of this definition for equality as useful. Say you're in a position where you'd have to choose between `mathFunction1` or `mathFunction2`. **The choice wouldn't matter**.

* If you choose `mathFunciton1` you can derive `mathFunction2` just by writing your own `mathFunction1is2`.
* If you choose `mathFunction2` you can derive `mathFunction1` just by writing your own `mathFunction2is1`.

So from a standpoint of someone who needs to choose a function (or library), this doesn't seem so interesting. However, from the library author standpoint, if she notices that her functions are in a way of _equivalent power_, she can safely ignore the 'power' of her functions and focus on other things like _performance_ or _simplicity_.

<in-margin>
Sidenote: Here's a real world example, albeit a little complex. Feel free to skip this.

Here are two functions in `elm-community/result-extra`:

```elm
combine :
    List (Result x a)
    -> Result x (List a)

combineMap :
    (a -> Result x b)
    -> List a
    -> Result x (List b)
```

Both solve the same problem: You have individual failues (`Result`s) and want to handle a whole list of them.

Both are equivalently powerful:

```elm
combineMapIsCombine f list =
  combine (List.map f list)

combineIsCombineMap results =
  combineMap identity results
```

However, `combineMapIsCombine` roughly 2x slower than `combineIsCombineMap`, because both `combine` and `List.map` loop over the list, while `combineIsCombineMap` only uses `combineMap`, which loops over the list once.

At the same time, `combineMap` is a little more complex: The function takes another parameter and also has an additional type parameter (`b`) compared to `combine`.

Therefore, if a user only had `combine` available and didn't want to accept a performance penalty, she'd have to write the `combine` logic herself, even though `combine` and `combineMap` are 'equivalent'.
---
</in-margin>

---

I feel like there's two orthogonal points in this:
1. We need to evolve functional programs organically, via basic abstraction and refactoring.
2. We can reason about code very effectively by looking at the type's 'power'.

Reason about the power of types: the 'algebra' in algebraic datatypes. Subtyping.

Reason about types via the amount of values they describe:
* We want to describe the exact amount of values that should be allowed (make illegal states impossible)
* What if you only had multiplication, variables and scalars???
  - Geometrical analogy: Try to come up with a volume of an L-shape of width x, cutoff at width c, height of (2*h), cutoff at h.
    It would be impossible to describe this only using multiplication! `2*x*h` captures a whole rectangle, not the L shape.
    Only sum types make this possible: `h * x + h * c = h * (x + c)`!

More refactoring through static types.

Maybe a simpler form of arguing the L-shaped thing is this by using the 'remotedata' thing from this post:
  https://wiktor.toporek.me/blog/tailor-made-union-types
(The `{ loaded : Bool, error : Bool }` thing).

Just show the connections: Types = Algebra = Squares (This is the hook!)

## Can we subtract types?

Not really, no. But we can abstract out a type variable that we set to 0: `Never`.

What is this post title? What does this have to do with abstraction exactly? Other ideas:
* Algebraic Design of State
* Algebraic Design of Data
* Maybe just split this post into two: The description describes quite something different than the content


# 27. Jul

Type equalities: Let's FIGHT

a -> Maybe (b -> c)
VS.
a -> b -> Maybe c

Recursion:
Why?
* Because we need more layers to scale!
* Because we can re-use the same principle for _each layer_! That's simpler!

Types can become very complicated. How do you come up with them?
* You abstract out one by one.
* How do you deal with choices of abstraction? Think about the power of the resulting type. Does that power make sense for that usecase?

Honerable mention: Structural vs. Nomintal typing.

# 29. Jul

Blog post points/ideas:

* Types can be more powerful / equally powerful than each other
* Powerful types are a double-edged sword:
  - Too powerful and you can't use it in less powerful contexts (e.g. contexts where you'll statically analize your result)
  - Not powerful enough and you'll need to resort to other means of implementing. Your interface is not general enough for all usecases.
* The power of types can also kind of be visualized with tables / diagrams.
* You want precise control over the 'power' of your types. Custom (union) types allow you to have more control: L-shaped things become possible.
* Parametricity gives you theorems for free. When you abstract types, your function becomes less powerful, but at the same time more general. You can reason about it much much better.
* Recursion is better than explicit layers (??)

Title ideas:

* Don't do patterns! Program by gauging (/managin/controlling/judging) the power of types.
* You need to know about the power of types to effectively program functionally.
* You need to know about the power of types to design functional programs.
* X things to know to judge the power of types.
* X steps to working effectively with types

# Interesting Types to look at

```elm
parse : String -> Result String (List Markdown.Block)
parse : String -> List (Result String Markdown.Block)

render : String -> Maybe (Model -> Html Msg)
render : String -> Model -> Maybe (Html Msg)

generate : a -> List a
generate : Int -> List Int

testHtmlClick : { x : Int, y : Int } -> Html msg -> Maybe msg
viewHeader : Html msg
viewHeader : Html Msg
viewForm : { onSubmit : { name : String, email : String } -> msg } -> Html msg


type alias PageInfo = ...
type alias Metadata = ...

pageInformation :
    List { path : String, frontmatter : Metadata }
    -> StaticHttp.Request ({ path : String } -> PageInfo)


elmPagesApp :
    { ...
    , view :
          List ( PagePath pathKey, metadata )
          -> { path : PagePath pathKey
             , frontmatter : metadata
             }
          -> StaticHttp.Request
                 { view :
                       model
                       -> view
                       -> { title : String
                          , body : Html msg
                          }
                 , head : List (Tag pathKey)
                 }
    , ...
    }
    -> Builder pathKey model msg metadata view
-- Builder can be transformed into elm's 'main'
```
