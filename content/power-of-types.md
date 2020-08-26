---
{
  "type": "blog",
  "title": "Control the Power of your Types",
  "description": "TODO There is a lot of literature about Object Oriented Software Design, usually thick books with lots of guidelines. In comparison, there is very little literature about Software Design of Functional Programs. Often people ask about the 'Patterns' of Functional Programming, but I believe the solutions is to stop pressing your Programs to adhere to patterns, but instead evolve your own patterns for your domain.",
  "image": "images/power-of-types/thumbnail.jpg",
  "draft": true,
  "published": "2019-11-28",
}
---

Let's imagine: You think your thoughts are _oh so valueable_, so you decide to create a blog. You write your blog posts in markdown and generate Html for them by writing your own code.

In the process, you need to decide which library you'll use for markdown parsing. You take a look at the types of their `parse` function:

```elm
-- Markdown library 1:
parse : String -> Result String (List Markdown.Block)

-- Markdown library 2:
parse : String -> List (Result String Markdown.Block)
```

Which one will you choose?




# The power of types

You choose the powerful one of course! You see, those two types for `parse` are not equivalent.

Wait, _what are equivalent types?_

```elm
sum1 : Int -> Int -> Int
sum2 : (Int, Int) -> Int
```

The types of `sum1` and `sum2` _are_ equivalent. My argument as to why is simple: If you had a value of one of the types, you could 'derive' a value of the other type:

```elm
sum1isSum2 : (Int -> Int -> Int) -> ((Int, Int) -> Int)
sum1isSum2 sum1 =
    \(x, y) -> sum1 x y

sum2isSum1 : ((Int, Int) -> Int) -> (Int -> Int -> Int)
sum2isSum1 sum2 =
    \x y -> sum2 (x, y)
```

So, generally, I'll say two types `A` and `B` are equal when there exists a function `A -> B` and `B -> A`. If we replace `A` with `Int -> Int -> Int` and `B` with `(Int, Int) -> Int` you'll get the two type signatures above.

<ImgCaptioned
  id="equivalent-types-illustration"
  title="illustration of equivalent types"
  alt="illustration of equivalent types"
  src="images/power-of-types/equivalent-types.svg"
  width="75%"
>
Think of the equivalency like this. The bubbles represent the types and the arrows represent functions from one type to another.

If this forms a cycle, all the types in the cycle are equivalent.
</ImgCaptioned>

I'd like to convince you to think of this definition for equality as useful. Say, you're in a position where you'd have to choose between `sum1` or `sum2`. **The choice wouldn't matter**.

* If you choose `sum1` you can derive `sum2` just by writing your own `sum1isSum2`.
* If you choose `sum2` you can derive `sum1` just by writing your own `sum2isSum1`.

Now, if you ever notice that two function types are of _equivalent power_, you can focus on comparing other things like _performance_ or _simplicity_ instead.




# A 'Realworld' Example

Here are two functions from [`elm-community/result-extra`](https://package.elm-lang.org/packages/elm-community/result-extra/2.4.0/Result-Extra#combine):

```elm
combine :
    List (Result x a)
    -> Result x (List a)

combineMap :
    (a -> Result x b)
    -> List a
    -> Result x (List b)
```

Both solve the same problem: You have individual successes or failures ([Results](https://package.elm-lang.org/packages/elm/core/latest/Result#Result)) and want to handle a whole list of them. 

At the end you either want there to be success or failure _as a whole_, not per individual list item.

Both are equivalently powerful:

```elm
combineMapIsCombine f list =
  combine (List.map f list)

combineIsCombineMap results =
  combineMap identity results
```

However, `combineMapIsCombine` is roughly 2x slower than `combineIsCombineMap`, because both `combine` and `List.map` loop over the list, while `combineIsCombineMap` only uses `combineMap`, which loops over the list once.

At the same time, `combineMap` is a little more complex: The function takes another parameter and also has an additional type parameter (`b`) compared to `combine`.

Therefore, if a user only had `combine` available and didn't want to accept a performance penalty, she'd have to write the `combine` logic herself, even though `combine` and `combineMap` are 'equivalent'.



## Dissecting functions by type

However, we're not interested in types with equal power! After all, I said that the two `parse` types are not equally powerful.

Let's look at them more closely. One thing we can do with types is **imagine what the function is likely doing just by looking at the type signature.**


```markdown interactive
This is some example markdown.

It contains some _markdown_ blocks.

* Here's a 
* list of
* items
```

### Step 1: Imagine Inputs

The input type for both `parse` functions is `String`. Because of the context, we know it's likely going to be in markdown format, though! So, how about an example markdown?

```markdown
This is some example markdown.

It contains some _markdown_ blocks.

* Here's a 
* list of
* items
```

We might also want to include some ill-formed markdown, as that's also valid input, according to the type signature to `parse`. How about this?

```markdown
This is some example markdown.

It includes invalid _markdown blocks.

Damn. I didn't end that _italic_ it the last paragraph.
```

(Actually, there's no ill-formed markdown according to the spec. But let's assume we're working with nit-picky parsers that for example expect '`_`'s to be escaped, when not ment to be used for italics.)



### Step 2: Imagine Outputs

So now let's look at the two output types. Remember that we have to look at both, because they're different, unlike the input types.

```elm
parseOutput : Result String (List Markdown.Block)
```

* We can imagine that `parse` failures are going to be reported using the `Err` constructor of the `Result` type.
* We see that, if `parse` succeeds, it would probably give us a list of structured data about markdown, because of the `List Markdown.Block` part. That would then be wrapped in an `Ok` constructor due to the `Result` type around it.

For our first markdown example, which didn't contain an error, we would expect the following output:

<in-margin>
I'm omitting the definition of `Markdown.Block`, it's just a sensible definition for structured data about markdown in Elm.
</in-margin>

```elm
parseOutput : Result String (List Markdown.Block)
parseOutput =
    Ok
        [ Markdown.Paragraph
            [ Markdown.Text "This is some example markdown." ]
        , Markdown.Paragraph
            [ Markdown.Text "It contains some "
            , Markdown.Italic "markdown"
            , Markdown.Text " blocks."
            ]
        , Markdown.BulletList
            [ Markdown.Text "Here's a"
            , Markdown.Text "list of"
            , Markdown.Text "items"
            ]
        ]
```

What about the markdown example with an error? Well, errors likely mean that the `Result` will be the `Err` constructor. That one contains a `String`, so we guess that's the error message.

```elm
parseOutput : Result String (List Markdown.Block)
parseOutput =
    Err "Unfinished italic in input line 3"
```

Alright. What about the other `parse` function?

This time, the wrapping is done the other way around: `List` is wrapped around `Result`, not `Result` around `List`.

So no matter what input we provide to `parse`, it'll give us back a list of things. Any of these things can fail with an errormessage (`Err`) or be there (`Ok`).

Our first markdown example should only contain `Ok`, as it's syntax is correct.

```elm
parseOutput : List (Result String Markdown.Block)
parseOutput =
    [ Ok
        (Markdown.Paragraph
            [ Markdown.Text "This is some example markdown." ]
        )
    , Ok
        (Markdown.Paragraph
            [ Markdown.Text "It contains some "
            , Markdown.Italic "markdown"
            , Markdown.Text " blocks."
            ]
        )
    , Ok
        (Markdown.BulletList
            [ Markdown.Text "Here's a"
            , Markdown.Text "list of"
            , Markdown.Text "items"
            ]
        )
    ]
```

Pretty straight-forward. There's basically the same information as before, just wrapped differently.

What about the faulty markdown?

```elm
parseOutput : List (Result String Markdown.Block)
parseOutput =
    [ Ok
        (Markdown.Paragraph
            [ Markdown.Text "This is some example markdown." ]
        )
    , Err "Unfinished italic in this block line 1"
    , Ok
        (Markdown.Paragraph
            [ Markdown.Text "Damn. I didn't end that "
            , Markdown.Italic "italic"
            , Markdown.Text " it the last paragraph."
            ]
        )
    ]
```

Interestingly, this output contains more information than the previous one.

It still parses the other markdown blocks fine. I could have returned a list of only a single item, the error, yes, but why would I return a list of things then in the first place? For multiple errors? Obviously, the type doesn't tell the whole story. There could be many different ways this markdown parse function could have worked. The string in the `Err` doesn't even have to be an error message, its just common that it's that. Maybe it contained the source markdown instead?

What I presented is just one way the output of `parse` _could_ have looked like. But the fact that that output is possible alone means that this `parse` function is more powerful. However, I'm going to prove it with the same framework as I have proven equivalency before.



## Not all functions are created equal

So, the second parse function is more powerful. I'll just cut the chase and show you why:

```elm
parse1 : String -> Result String (List Markdown.Block)
parse2 : String -> List (Result String Markdown.Block)

parse2CanDoParse1 :
    (String -> List (Result String Markdown.Block))
    -> (String -> Result String (List Markdown.Block))
parse2CanDoparse1 parse2 =
    \source -> Result.Extra.combine (parse2 source)
```

Again, we can convert the second parsing function to the first parsing function. This in turn means that **`parse2` is at least as powerful, or more powerful than `parse1`**.

Now, they could be equally powerful. I have no way for you to guaruntee that `parse1` doesn't stand up to the challenge. But it can be reassuring that you can safely choose `parse2`, if you like it's features, because in the worst case, you can get what `parse1` promises, too.




# With great power also comes great responsibility




# ...

There's more ways of looking at types.

For example, looking at it more from the information-theoretic side of things: Your function output can only *depend on* information it gained in inputs (this gets fun when you're looking at higher order functions). Another way of saying that is your function output can't have more information than its inputs.

Or by counting the amount of observably different implementations a type can have. There is a page about this on the Elm guide, but there's more information in [this blog post](TODO). It's a mind-blowing fact that types and numbers work so similarily, but it fails in practice, because most types have infinite amounts of observably different values, so comparing their size doesn't work. The way I explained it above is more useful in my opinion: Even though both of your types might have infinite amounts of 'values', you can still see which one is bigger than the other by comparing their power. What you lose is a straight-forward recipe to analize types (no more counting), you have to come up with the functions to convert between one and the other, and when you think there doesn't exist a function in one way, you can never be absolutely sure.

<!--

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

combine : List (Result x a) -> Result x (List a)
combineMap : (a -> Result x b) -> List a -> Result x (List b)

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

-->