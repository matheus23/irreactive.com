---
{
  "type": "blog",
  "author": "Philipp Krüger",
  "title": "Boxes of Higher Order",
  "description": "Exploring graphical visualisations for code, especially for functional programming, inspired by category theory visualisations.",
  "image": "images/article-covers/mountains.jpg",
  "draft": true,
  "published": "2020-03-03",
}
---

SETUP:
* I wanted to create graphical programming for a long time
* Always dismissed node based approaches
* I took a look at fancade
  - A Node programming model, again
  - Looks nice
  - Interesting runtime
  - has "let" blocks (wormholes). Somehow I've never seen them elsewhere
* When working on an expression-based graphical language
  - Also had 'let'
  - Let rendered connections between dependent values
  - We noticed a graph was built: Everything non-recursive has an acyclic dependency graph.
    - refactors are often just changing the way we 'view' this graph
* Back in the day I loved working with Logisim
  - I Loved being able to define the way my blocks looked
  - I used registers in logisim, they have a nice viz
  - This viz disappears when you abstract it out of your block
  - I replaced the register with connections out of my block back into it again
  - I could put back the register on the outside: Nice visualisation. This kind of slot you could put your block in.

'CONFLICT': IDEA:
* Functions are blocks
* Higher order functions have holes in them
* -> You can see the signature of blocks
* 