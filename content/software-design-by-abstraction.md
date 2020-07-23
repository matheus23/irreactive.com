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
