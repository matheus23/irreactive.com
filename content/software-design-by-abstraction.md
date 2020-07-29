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

RESEARCH:
Maybe interview 'expert functional programmers'?

Maybe a simpler form of arguing the L-shaped thing is this by using the 'remotedata' thing from this post:
  https://5e89068c6daf890006031b1d--hungry-darwin-eccd5b.netlify.com/blog/quiz-test
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