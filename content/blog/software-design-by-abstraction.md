---
{
  "type": "blog",
  "author": "Philipp Krüger",
  "title": "Software Design by Abstraction",
  "description": "There is a lot of literature about Object Oriented Software Design, usually thick books with lots of guidelines. In comparison, there is very little literature about Software Design of Functional Programs. Often people ask about the 'Patterns' of Functional Programming, but I believe the solutions is to stop pressing your Programs to adhere to patterns, but instead evolve your own patterns for your domain.",
  "image": "/images/article-covers/mountain.jpg",
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
