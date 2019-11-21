---
{
  "type": "blog",
  "author": "Philipp Krüger",
  "title": "The Motivation of Creating Human Computer Interfaces",
  "description": "A draft. (TODO CHANGE THIS)",
  "image": "/images/article-covers/fittslist.png",
  "draft": true,
  "published": "2019-11-21",
}
---

I believe user interfaces are one of the most important pieces of software. They're ubiquitous, and I even want there to be more. The only way to interface to a computer as a human is a human-computer-interface. There are a lot of them, differing in style and sophistication: Your web browser, a computer terminal, a text editor or your operating system's graphical interface.

Why do computers exist? What makes them so useful?
I have asked myself this question many times. Some answer this question in terms of the automation capabilities of computers, but I think that's it. I can imagine telling a person "I need a website, please build one for me. I have following goals and 10000$" and wait 4 months until that person comes back at me and says: "Hey, it's done. Do you like it?".

Sounds pretty automatic to me.

But I can't imagine a computer could do this yet, _at all_. That doesn't mean a computer is not useful, but it's not automatic either. Please don't get me wrong: I don't think trying to achieve this automation is desirable. To create a website with a computer today, you have to continually interact with it, until you're satisfied. And the interaction bit is the user interface stuff. This is the way I like working with the computer and I want it to become better at this and I want more human-computer interaction in the future.

I like to think of a computer more as an extension of your arm. Kind of like a tool, like a screwdriver or a hammer. Not literally, only metaphorically.

This way of working with a computer is here to stay for a long time. ff you're not convinced about that, let me show you this part of a paper:

![A scan of a paper that contains Paul M. Fitts' comparison of humans and machines](/images/content/FirstMABAMABA.png)

This is the researcher Paul M. Fitts analizing the tasks that machines are better than humans at and the other way around. This is known today as the "MABA-MABA-list" (Men are better at - Machines are better at) or the "Fitts list".

He analized this for choosing the best interaction interface border between human and an autopilot flight controller. It is crucial that the human will perform the tasks he can do better than the machine and the other way around. This paper was published in 1951.

I won't argue that everything on this list still applies today, but what I take away is that, in my subjective experience, computer programming is taught to be about what happened after pressing enter in a terminal way more than about what happens at the interaction boundary between us and this medium (the computer). Maybe technology would feel better, if this focus were different?

Even outside of autopilot design I think this careful consideration of which tasks humans and which tasks machines are better at and the careful design of the interface in between is important. It also applies to productivity tools, e-mail clients, operating systems, programming language compilers, theorem provers and probably everything else.

I want there to be more interfaces. I hope this means there are less black boxes:
More playing with your type error, more understanding why something didn't match up.
More inspecting and changing the automatic prover that got stuck.
So more flexibility, as it is possible to not only observe the programs behavior, but also change it.
More utilizing the 'Ability to improvise and use flexible procedures'.

But I hate writing interfaces. And I think many others do too. And I think that's why we don't have great interfaces for great programs.

In my experience most user interfaces are 90% boring, old, re-usable components: Buttons, images, text labels and input fields. The remaining 10% are the critical parts of most interfaces: They're the direct interface to the business logic that makes your program unique.

I used to work with JavaFX and it covers the 90% pretty well. But it's impossible to cover the 10% without being extensible. I remember using its table view and trying to put components into the table column headers, but it wouldn't quite support that. I remember using its editable-cells feature but couldn't change which cell was currently edited on enter or tab keypresses similar to excel's spreadsheets.
This table view would look very feature-rich when you took a look at its API, but many applications wouldn't need most of these features: What about a data table that couldn't be edited? It doesn't need these editable cell components constraining its performance or API flexibility.
The table view should be quite transparent, so I could reach through it to its underlying features: Aligning a bunch of cells across columns.
There is the JavaFX GridView, but it contains many other features that a table view doesn't need and TableView doesn't use GridView under the hood. Why don't they share this cell-aligning functionality?

Frustrated and impressed by the web's richness of different, complex user interfaces that didn't need to be installed and ran on most computers I left JavaFX and turned myself to the browser. And even though the space felt much better with functional and declarative APIs in React or Elm. No longer would I modify the component's text, but instead declaratively describe what my user interface would look like for a particular state of mine and could even combine my user interface building blocks - html elements / React components - compositionally.

However, even the web has its issues: There is the infamous problem of centering an html element vertically and horizontally at the same time in a container. Something you would expect every user interface library to support, didn't work easily before flexbox was introduced.
Compared to JavaFX, Qt, or Gtk, in Elm or React you suddenly lost the ability to easily handle the cursor position just like you handled the text of your input field.
And wheras you could write your own 'LayoutManagers' in JavaFX, you would have to wait until css subgrid support was widely available in all browsers, for example.

Again, I'm left frustrated with the current state of user interface libraries. Writing user interfaces in object-oriented programming languages is a mess of mutable state and side-effects in listeners that make it hard to reason about side-effect order and invariants. It is diffing before-and-after states (virtual-dom) hacks in functional programming that makes it hard to work with the hidden mutable state that so often contains crutial information: Positions, layout, cursors, etc. It is this cram-all-features-into-one hack of browser DOM that makes chrome, firefox and electron use immense amounts of power and cpu.

Maybe I can try improving the UI situation.

I want to write about my approach to improve this situation in the following blog posts. Now that I wrote this down for you to read, I'll have to finally share my humble results.
