---
{
  "type": "blog",
  "title": "Building this Blog",
  "description": "Behind the scenes: The tech and process behind this blog. The classic introduction of a tech person's blog of itself.",
  "image": "images/article-covers/mountains.jpg",
  "draft": true,
  "published": "2020-07-17",
}
---

Is it a meme that every tech person's blog gets a 'how it was built' introduction? Well, I don't really care. I haven't gotten sick of them, yet. I bet there's some pretty interesting one's I've read.

# The looks

First of all, I want to say that I've recently (about a year ago) gotten very interested in designing user interfaces before building them. Why do this? Well, when you're using design tools like Figma, Sketch, Adobe XD, Photoshop, etc. you can iterate *very quickly*. I personally work with Figma.

<ImgCaptioned
  id="figma-screenshot"
  src="/images/building-this-blog/figma-screenshot.png"
  title="A Screenshot this Blog's Figma File"
  alt="A Screenshot of this Blog's Figma File"
  link="true"
>
Click to enlarge. A screenshot of this blog's figma file. Look at a [read-only version](https://www.figma.com/file/pfzSos2PrxlvaijsfYMDoI/Blog?node-id=0%3A1).
</ImgCaptioned>

Let me go through it clearly:

* You want to have something aesthetically pleasing. 
* For that you need lots of iterations. **Your first attempt will look bad**. You won't choose the right spacing, the right layout, the right colors, the right font size, the right font, etc.
* You can't change the colors, fonts, spacing and especially layout quickly in code. Code is way more abstract: You don't code 1 Layout, you code an infinite amount. You don't code one layout at 1280px screen width, but a layout that works across many screen sizes at once. That's way more difficult and takes time and scaffolding.

Naturally, my eyes were opened as soon as I started incorporating an explicit designing step before writing code. I was also designing previously. You're always designing when you're making something visual, but it used to be intertwined with finding a good architecture in your code, all while being slow.

---

I also thought quite a bit about the visual identity this site should have. At the time I got bored by this 'clean' kind of look that many websites have.

A look dominated by

* Cool colors: Blue, cyan, teal
* Soft shadows
* Lots of _literal_ white space

So I wanted to create something refreshing. A little more playful and easy on your eyes. To be honest, after working countless hours designing, coding and writing this blog, I _can't stand_ looking at it anymore.

But the first time I got somewhere with it, I liked it.

This blog's color palette is based (almost exclusively) on gruvbox, which is a popular [syntax highlighting theme](https://github.com/morhetz/gruvbox).

<ImgCaptioned
  id="gruvbox-theme"
  title="A Figma Community File for ease of use of Gruvbox"
  alt="A Figma Community File for ease of use of Gruvbox"
  src="/images/building-this-blog/gruvbox-palette.png"
  link="true"
>
The 'gruvbox' color palette used for this blog. I've created a [figma community file](https://www.figma.com/community/file/840895380520234275), so you can use it in your figma designs, if you want to!
</ImgCaptioned>

# The works

This site was built in elm. It's the language I enjoy writing code in most. An essential piece of the puzzle is [elm-pages](https://elm-pages.com/) by Dillon Kearns: It allows my website to be rendered on the server side into neat html pages, which are 'hydrated' once the client's javascript is loaded.

I'm writing the individual blog posts as markdown files. I'm using (also Dillon Kearn's) [elm-markdown](https://github.com/dillonkearns/elm-markdown/) for parsing these files. It also allows for quite some customization of your markdown via html elements. The above palette picture with it's subscript was written like this:

```html
<ImgCaptioned
  id="gruvbox-theme"
  title="A Figma Community File for ease of use of Gruvbox"
  alt="A Figma Community File for ease of use of Gruvbox"
  src="/images/building-this-blog/gruvbox-palette.png"
  link="true"
>
The 'gruvbox' color palette used for this blog. I've
created a [figma community file]
(https://www.figma.com/community/file/840895380520234275),
so you can use it in your figma designs, if you want to!
</ImgCaptioned>
```

This `ImgCaptioned` is then interpreted by my elm code:

```elm
imgCaptioned : Markdown.Html.Renderer (List (Html msg) -> Html msg)
imgCaptioned =
    Markdown.Html.tag "imgcaptioned"
        (\src alt maybeWidth idAttrs children ->
          Html.figure ... -- Code that produces Html
        )
        |> Markdown.Html.withAttribute "src"
        |> Markdown.Html.withAttribute "alt"
        |> withBooleanAttribute "link"
        |> Markdown.Html.withOptionalAttribute "width"
        |> withOptionalIdAttribute
```

I even have the children as rendered markdown available, so I can use markdown inside the html elements again (notice the link in the above example).

I've made extensive use of the ability to create custom elements for my markdown. The interactive elements on my blog posts are defined in elm.

