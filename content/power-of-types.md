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

I'm often confronted with a choice between programming libraries. In dynamic programming languages like javascript I have to either look at the documentation and/or run the code before I can assess it. In statically typed programming languages a quick look at the types is often enough to exclude certain choices. But how and why does that work?

Let's use an example. Say, you want to find a markdown parsing library for your custom implementation of a blog website. You look at the first candidate:

```elm
parse : String -> Html msg
```

It's a fairly simple type. You can't deduce what's going on inside, though. That makes sense, as a very small type can only convey a fairly small amount of information.

And also, `Html` is opaque, that means, you can't take it apart, only render it. So if you want to create a different html structure than what this library produces, you're out of luck.

```elm
parse : String -> List Markdown.Block
```

Awesome, this library will allow you to traverse each markdown block on your own, and you'll have full control over how html is rendered, as `Markdown.Block` is not opaque: You can take it apart and look at its structure.

However, you don't stop looking and find this:

```elm
parse : String -> Result String (List Markdown.Block)
```

Huh. Intriguing, you think. The `Result` type in the output of this parse function indicates that markdown parsing with this library _can fail_. Usually, markdown is parsed leniently, but from the type signature you deduce it must be stricter. Maybe a missing paranthesis in a link `[like](http://this` causes it to fail?
That would be a feature, as you could ensure you don't accidentally have broken markdown on your website.

Of course, markdown parser libraries are abundant and you find this one:

```elm
parse : String -> List (Result String Markdown.Block)
```

Hmm. Now the difference becomes more subtle. You have a feeling this library provides you more information than the last one, but you're not sure.

Let me show you how to analize functions by their type signature alone and actually be sure.



# The power of types

I'll loosely call 'how much information a function provides to the user' the _power_ of a function - or, because we're looking at their types - the _power of a type_. 'Power', in the sense of _empowering the user_ of a function.

Let's go a step back, and use a simpler example:

```elm
sum1 : Int -> Int -> Int
sum2 : (Int, Int) -> Int
```

Is one of these functions more empowering to a user? So, is one of their types more powerful?

Both functions seem to sum two numbers, none of these actually give you any more information than the other, it's just that the inputs are given in two different ways.

We can show that two functions are equally powerful by implementing each function given the other one:

```elm
sum1isSum2 : (Int -> Int -> Int) -> ((Int, Int) -> Int)
sum1isSum2 sum1 =
    \(x, y) -> sum1 x y

sum2isSum1 : ((Int, Int) -> Int) -> (Int -> Int -> Int)
sum2isSum1 sum2 =
    \x y -> sum2 (x, y)
```

Using this, it's really easy to argue why the choice between them wouldn't matter: If you had chosen `sum1`, but suddenly needed the type of `sum2`, you'd simply run it through `sum1IsSum2`, because `sum1IsSum2 sum1` behaves the same as `sum2`.

<in-margin>
(The choice _could_ still matter, but not purely from the observation of inputs and outputs. Given the same inputs, these functions produce the same outputs. There's no extra information that `sum1` provides over `sum2`. What _does_ still matter might be memory efficiency or performance. Converting between things is obviously not free.)
</in-margin>

Put more simply, you can convert `sum1` into `sum2` and vice versa.

And generally, two things of type `A` and `B` are equally powerful (in our sense), if there exist two functions `A -> B` and `B -> A` that form a so-called isomorphism.

<ImgCaptioned
  id="equivalent-types-illustration"
  title="illustration of equivalent types"
  alt="illustration of equivalent types"
  src="images/power-of-types/equivalent-types.svg"
  width="75%"
>
Think of the equivalency like this: The bubbles represent the types and the arrows represent functions from one type to another.

If this forms a cycle, all the types in the cycle are equivalently powerful.
</ImgCaptioned>

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



# The Empowering Parse Function

Let's come back to our original example and try to see whether the two parse functions are equivalently powerful.

Here are both their types again for reference:

```elm
-- option 1
parse : String -> Result String (List Markdown.Block)
-- option 2
parse : String -> List (Result String Markdown.Block)
```

If we want to assess their relative power, we need to think of implementing one function in terms of the other.

Let's try to implement option 1 in terms of option 2.

```elm
option2IsOption1 :
    (String
        -> List (Result String Markdown.Block)
    )
    -> String
    -> Result String (List Markdown.Block)
option2IsOption1 parse markdown =
    -- What do we do?
    -- Our first step can be applying the
    -- markdown string to the parse
    -- function given.
    -- (That's basically the only thing we
    -- can do using the inputs to this
    -- function.)
    markdown
        |> parse
    -- Now we have a value of this type:
    -- List (Result String Markdown.Block)
    -- And we need to transform this to:
    -- Result String (List Markdown.Block)
    -- We can use result-extra's `combine`!
        |> Result.Extra.combine
```

Great so this works. 


---

# Conclusion

By now you should understand that controlling the power of types is a trade-off. At first it might seem that empowering the user - so, providing the user with as much information as possible - is always better, but this may clash with other factors such as simplicity or performance.

My goal for this article is this: I want the consideration of the power of types in functional programming languages to be a concious choice of library authors. To make this possible it is necessary to make it an objective measure. I think that this framework provides one.

For this article I had an internal struggle with how much time I spend talking about what the functions would actually do when run.
* On the one hand, this article is meant to be read by someone who's not necessarily too familiar with reasoning using types alone. Therefore, it'd be necessary to provide something tangible to them to start with, e.g. example inputs and outputs (actual values, not their types!).
* On the other hand, if I did that, I'd basically get rid of one of the big benefits of types: Not having to think about concrete values and not having to be a human interpreter.

---

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