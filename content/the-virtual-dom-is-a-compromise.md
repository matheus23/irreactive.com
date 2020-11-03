---
{
  "type": "blog",
  "title": "The Virtual DOM is a Compromise",
  "description": "It is commonly believed that the virtual dom's purpose is performance for web apps. But it's an abstraction! Is it really a negative-cost abstraction? No. It's purpose is mainly something else: It's a pure abstraction over an stateful and impure API.",
  "image": "images/power-of-types/thumbnail.jpg",
  "draft": false,
  "published": "2020-11-02",
}
---

The virtual dom is what powers lots of frontend frameworks nowadays. It started with React, but now includes Elm, VueJs and more.

<in-margin>
<info title="DOM = Document Object Model.">
E.g. a 'div' element is a DOM object (very much in the object-oriented sense).
</info>
</in-margin>

The virtual dom, also VDOM, has two purposes, but I've mostly only heard about its first purpose. The VDOM is supposedly a performance optimization. But I can't believe that. If you didn't have a VDOM, you'd be doing DOM manipulation 'by hand' (like in the old days of jquery). And in the end, DOM manipulation is the only way to change what's on screen in a browser. How can letting an algorithm do this be faster?

What people mean by the virtual dom being a performance optimization is this: Instead of destroying the whole page's DOM and rebuilding it every frame, we only rebuild the DOM that actually changed, or apply changes to DOM objects compared to the last frame.

What everyone forgets, however, is that destroying the whole DOM and rebuilding it entirely every time we want our webpage to change is *absolutely impractical!* Consider all the state that gets lots:

* Input element text
* Focused elements
* Caret positions
* Hover states
* CSS Animation states

Preserving most of *that* state is the *actual purpose of VDOMs*.

One of the authors who talked about this in length is Raph Levien. He abstracts the virtual dom from its DOM origins, and describes it as a purity abstraction over a stateful tree-manipulation machine. In his view, an application might have multiple such trees with virtual DOMs in between. I recommend reading ['Towards a unified theory of reactive UI'](https://raphlinus.github.io/ui/druid/2019/11/22/reactive-ui.html).

Maybe the virtual DOM will turn out to be the right abstraction, I honestly don't know. But until I know, I propose something else.



# I propose, we ditch the VDOM


The VDOM leads to quite some frustration for functional programmers: In Elm, for example, it's impossible to specify the caret position of your input element the same way that you'd specify its input text.

That state was hidden from you, so you don't have to care about it. In most cases, this is great. The only state you now have to care about is just a `String`, not some more complicated `InputElementState`.

* You don't have to think about how to get from an `InputElementState` to a `String`
* No need to think about what happens to the caret when you change the `String` inside yur `InputElementState`.
* But also no way of changing or getting the caret position, when all you have is a `String`,  not an `InputElementState`.

After thinking about this for a long time and some experimentation, I strongly favor the more complicated, but honest `InputElementState` over the simpler, but leaky abstraction `String` in web apps.

One of the biggest reason for this is how you really need to think about what happens to the *actual* DOM objects when you render a different virtual dom.

Say you're rendering a list of shopping list items in your web app. The resulting virtual DOM looks like this:

```html
<ul>
<li><input type="text" value="Bread"></li>
<li><input type="text" value="Butter"></li>
<li><input type="text" value="Milk"></li>
</ul>
```

The user now focuses the `Bread` list item, because she wants to change it to 'Bread 500g'.

At the same time, her fiance is in the same web app on his own phone and adds 'Soy sauce' to the shopping list. Her shopping list is real-time connected and instantly shows the change:

```html
<ul>
<li><input type="text" value="Soy sauce"></li>
<li><input type="text" value="Bread"></li>
<li><input type="text" value="Butter"></li>
<li><input type="text" value="Milk"></li>
</ul>
```

But what happens to the actual DOM objects now? I can imagine at least two options:

1. Is the virtual dom smart enough to figure out that your intention was to add a new DOM object to the start of your `ul`, or
2. will it think that you've changed `Bread` to `Soy sauce`, `Butter` to `Bread`, `Milk` to `Butter` and added `Milk` at the end of the list?

You might think: But there's no difference. The end result is the same, no?

No, because we've hidden some state that's implicitly attached to the actual DOM objects, for example the focused element. If the virtual DOM ends up doing option 2, our user will now edit a shopping list item with the text `Soy sauce` instead of one with the text `Bread`!

You might think: The virtual DOM should just go with option 1!

But that's not that easy. Finding the minimal diff between two trees is an NP-Hard problem, which means in the worst case you've got to test every possible diff to find the smallest one, essentially guessing. Solving an NP-hard problem is the opposite of performant.

VDOM in such cases just push the burden of deciding which VDOM objects should map to which DOM objects to the user: For example, in React or Elm, you'll annotate each shopping list item with a `key`. This key will be used by the VDOM to figure out if it can smartly re-use an old DOM node, keeping all its implicit state.

```js
function ShoppingList() {
  // Of course, these shopping list items
  // would usually be created programatically
  return (
    <ul>
      <li key="bob-0"><input type="text" value="Soy sauce"></li>
      <li key="alice-0"><input type="text" value="Bread"></li>
      <li key="alice-1"><input type="text" value="Butter"></li>
      <li key="alice-2"><input type="text" value="Milk"></li>
    </ul>
  )
}
```

But the thing is: A beginner shouldn't have to understand what the virtual dom does to fix this peculiar bug. I think such cases show that the virtual dom is a very leaky abstraction, even in the simplest cases.



# What if we handled all state explicitly?


I wish we could get rid of the virtual DOM and paint our browsers' DOM like functional picture drawing APIs, including all the implicit state like scroll positions and input carets.

But as long as we want to interface with the browser's DOM and want to do so in a purely functional way, we *have* to build an abstraction over the impure DOM API. We simply don't have access to all of the implicit state.

The DOM is an abstraction over browsers by design. Each browser may choose itself how to handle scroll positions.

Nevertheless, I'm trying to figure the question "What if we handled all state explicitly" out, experimentally.
One of my intermediate goals is a framework with these properties:

1. All state is immutable. The framework is purely functional.
2. There is no virtual DOM and no implicit state. Scroll positions, carets and focused elements can be read from the application state.
3. Apps written in this framework should be cross-platform. Ideally, they're running in a browser.
4. The framework allows creating performant and energy-efficient apps.

I still have a lot to write about how I imagine solutions for these goals. For example,

* I have ideas about using applicative APIs to make handling state much easier for points 1 and 2,
* I'm thinking of building on top of webgl with skia's canvaskit for point 3,
* I've got ideas about using monoids as an ergonomic abstraction for incremental updates for tackling point 4.



# Benchmarks for a VDOM-less solution


I think from an outsider perspective, it's hard to understand what the problem with the current state of writing applications is. Let me show you some example widgets that are - hopefully surprisingly - hard to implement in today's solutions for GUIs. This list will also be valuable for discussing proposed solutions.

todo: insert pictures/videos

* A git-like side-by-side view of two text editors with synced-up scrollbars, *without duplicating the scrollbar state*. So there is *only one* scrollbar position in the app that determines the rendered scroll position for both containers and it is *impossible for the scrollbars to get out of sync*.
* A rich-text-editor that allows adding in media, which *works the same in every browser*.
* A pan- and zoomable canvas view of widgets like in figma *with acceptable performance*.
* A widget with its content's animation depending on the scroll position, *without the possibility of it going out of sync*.
* ...