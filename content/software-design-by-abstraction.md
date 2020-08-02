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
* Maybe just split this post into two: The description describes quite something different than the content (???)


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
