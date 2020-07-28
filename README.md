# [Irreactive](https://irreactive.com)

This is the code and content of my personal blog.

For some information about the technology behind this repo, see the ['Building this Blog'](https://irreactive.com/building-this-blog) post.

This repository exists so that typos can be submitted as pull requests.

## Structure

* `content/` contains markdown files that describe blog posts
* `images/` contains media that gets optimized by `elm-pages`, including images for the blog posts
* `static/` contains videos, as they're not optimized by `elm-pages` (See [this issue](https://github.com/dillonkearns/elm-pages/issues/128))
* `src/` contains the source code of the html-generator for the webpage (what turns the markdown files to html)
* `gen/` contains generated source files from `elm-pages`
