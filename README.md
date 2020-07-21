# Irreactive

## TODO

* Type error redlines in `CodeInteractiveElm`.
  * Extract the active boolean out. This way logic can be separated: I often have 'ignore inactive elements' logic. By having two ASTs: one with and one without activity, I can transform between them.
  * Both generate a list of type errors and another AST that has type errors annotated to the nodes they appeared on and render that one.
* Write the rest of 'Building this Blog'.
* Write customized emails for subscriptions
* Fix domain addresses...

## Structure

* `content/` contains markdown files that describe blog posts
* `images/` contains media that gets optimized by `elm-pages`, including images for the blog posts
* `src/` contains the source code of the html-generator for the webpage (what turns the markdown files to html)
* `gen/` contains generated source files from `elm-pages`
* `elm-markdown/` is my fork of `elm-markdown`, so I can depend on my experiments.
