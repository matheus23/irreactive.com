# Irreactive

## TODO

* Type error redlines in `CodeInteractiveElm`.
  * Remove context from type errors (hehe)
  * Add the path of the error expression to the type errors
  * Render redlines in view code when there's a type error at the same position
* Write the rest of 'Building this Blog'.
* Write customized emails for subscriptions
* Fix domain addresses...

## Structure

* `content/` contains markdown files that describe blog posts
* `images/` contains media that gets optimized by `elm-pages`, including images for the blog posts
* `src/` contains the source code of the html-generator for the webpage (what turns the markdown files to html)
* `gen/` contains generated source files from `elm-pages`
* `elm-markdown/` is my fork of `elm-markdown`, so I can depend on my experiments.
