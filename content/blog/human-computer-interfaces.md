---
{
  "type": "blog",
  "author": "Philipp Krüger",
  "title": "Why you should care about User Interface Development",
  "description": "Or: My Motivation for Creating Human Computer Interfaces",
  "image": "/images/article-covers/fittslist.png",
  "draft": false,
  "published": "2019-11-21",
}
---

Why do computers exist? What makes them so useful?
I have asked myself this question many times. Some answer this question in terms of the automation capabilities of computers, but I don't think that's it. I can imagine telling a person "I need a website, please build one for me. I have following goals and $10000." and wait 2 months until that person comes back at me and says: "Hey, it's done. Do you like it?".

Sounds pretty automatic to me.

But I'm quite sure computers are *very* far from doing something like that, as of yet. That doesn't mean a computer is not useful, but it's not automatic either. Please don't get me wrong: I don't think trying to achieve this automation is desirable, because that is just not something computers are good at. To create a website with a computer today, you have to continually interact with it, until you're satisfied. And the interaction bit is the user interface stuff. This is the way I like working with the computer and I want it to become better at this and I want more human-computer interaction in the future.

I like to think of a computer more *like an extension of your arm*. Kind of *like a tool*, *like a screwdriver* or *a hammer*.

# The Human Computer Interaction Boundary

This way of working with a computer is here to stay for a long time. If you're not convinced about that, take a look at this:

<Carusel id="maba-maba-carusel">
<ImgCaptioned id="maba-maba-image" src="/images/content/FirstMABAMABA.png" alt="A scan of a paper that contains Paul M. Fitts' comparison of humans and machines">
A scan of a paper that contains Paul M. Fitts' comparison of humans and machines.

Swipe this view to read a transscript.
</ImgCaptioned>
<Markdown id="maba-maba-text">
*Men versus Machines.* In this section we have considered the roles men and machines should have in the future air navigation and traffic control system. We have surveyed the kinds of things men can do better than present-day machines, and vice versa.
Humans appear to surpass present-day machines in the following:

1. Ability to detect small amount of visual or acoustic energy.
2. Ability to percieve patterns of light or sound.
3. Ability to improvise and use flexible procedures.
4. Ability to store very large amounts of information for long periods and to recall relevant facts at the appropriate time.
5. Ability to reason inductively.
6. Ability to exercise judgment.

Present-day machines appear to surpass humans in respect to the following:

1. Ability to respond quickly to control signals, and to apply great force smoothly and precisely.
2. Ability to perform repetitive, routine tasks.
3. Ability to store information briefly and then to erase it completely.
4. Ability to reason deductively, including computational ability.
5. Ability to handle highly complex operations, i.e. to do many things at once.
</Markdown>
</Carusel>

This is was written by the researcher Paul M. Fitts, who identified tasks that machines are better at than humans and the other way around and is known today as the 'MABA-MABA-list' (Men are better at - Machines are better at) or the 'Fitts list'.

He analized this to determine the best interaction interface border between a human and an autopilot flight controller. It is crucial that the human will perform the tasks he can do better than the machine and the other way around. **This paper was published in 1951**.

I won't argue that everything on this list still applies today, but what I take away is that, in my subjective experience, computer programming is taught to be about what happened after pressing enter in a terminal way more than about what happens at the interaction boundary between us and this medium (the computer). 

Would technology have evolved for the better if this focus were different?

Even outside of autopilot design I think this careful consideration of which tasks humans and which tasks machines are better at and the careful design of the interface in between is important. It also applies to productivity tools, e-mail clients, operating systems, programming language compilers, theorem provers and probably everything else.

I want there to be more interfaces. I hope this means there are less black boxes:
More playing with your type error, more understanding why something didn't match up.
More inspecting and changing the automatic prover that got stuck.
So more flexibility, as it is possible to not only observe the programs behavior, but also change it.
More utilizing the *"Ability to improvise and use flexible procedures"*.
And I think the best way to enable such rich interfaces are graphical user interfaces (GUIs).

Anyone who has tried to implement an application with a rich user interface has felt how **today's technology is failing us**. I think the lack of tooling prevents many from realizing their vision. When we notice that our ideas for the user interface don't seem to work, we adapt them to what is possible - which may result in a worse interface - or don't implement them at all.

In my experience most GUIs are 90% re-usable components: buttons, images, text labels and input fields, but the remaining 10% are the critical parts: the direct interface to the business logic that makes your program unique.

<Carusel id="ui-examples">
<ImgCaptioned id="sibelius-image" src="/images/content/sibelius.jpg" alt="The sheet music editing program 'Sibelius'.">
The sheet music editing program 'Sibelius'.
</ImgCaptioned>
<VideoCaptioned id="oeffi-screen-record" src="/images/content/oeffi-screen-record.mp4" alt="A screen recording of an open-source train connection searcher 'Öffi'">
A screen recording of an open-source train connection searcher 'Öffi'
</VideoCaptioned>
<VideoCaptioned id="calendar-recording" src="/images/content/calendar-recording.mp4" alt="A screen recording of the google calendar android app">
A screen recording of the google calendar android app
</VideoCaptioned>
<ImgCaptioned id="vscode-code-lens" src="/images/content/vscode-code-lens.png" alt="Visual Studio Code's 'Code Lens' feature">
Visual Studio Code's 'Code Lens' feature (light blue section). Notice, that the code lens is *not* a popup, but instead splits the code view in half, there are no hidden lines of code.
</ImgCaptioned>
</Carusel>

## The Search for the UI Answer

Motivated to find the right tool for building UIs today, I was quickly looking around for any UI related work I could get my hands on.

The first two bigger UIs projects I worked on were written with JavaFX and it covers the 90% pretty well. But it's impossible to cover the 10% without being extensible. I remember using its table view and trying to put components into the table column headers, but it wouldn't quite support that. I remember using its editable-cells feature but couldn't change which cell was currently edited on enter or tab keypresses similar to excel's spreadsheets.
This table view would look very feature-rich when you took a look at its API, but many applications wouldn't need most of these features: What about a data table that couldn't be edited? It doesn't need these editable cell components constraining its performance or API flexibility.
The table view should be quite transparent, so I could reach through it to its underlying features: Aligning a bunch of cells across columns.
There is the JavaFX GridView, but it contains many other features that a table view doesn't need and TableView doesn't use GridView under the hood. Why don't they share this cell-aligning functionality?

Frustrated with JavaFX and impressed by the web's richness of diverse, complex user interfaces that didn't need to be installed and ran on most computers I turned myself to the browser. And even though the space felt much better with functional and declarative APIs in React or Elm. No longer would I modify the component's text, but instead declaratively describe what my user interface would look like for a particular state of mine and could even combine my user interface building blocks - html elements / React components - compositionally.

However, even the web has its issues: There is the infamous problem of centering an html element vertically and horizontally at the same time in a container. Something you would expect every user interface library to support didn't work easily before flexbox was introduced.
Compared to JavaFX, Qt, or Gtk, in Elm or React you suddenly lost the ability to easily handle the cursor position just like you handled the text of your input field.
And wheras you could write your own 'LayoutManagers' in JavaFX, you would have to wait until css subgrid support was widely available in all browsers, for example.

Again, I'm left frustrated with the current state of user interface libraries. Writing user interfaces in object-oriented programming languages is a mess of mutable state and side-effects in listeners that make it hard to reason about side-effect order and invariants. It is diffing before-and-after states (virtual-dom) hacks in functional programming that makes it hard to work with the hidden mutable state that so often contains crutial information: Positions, layout, cursors, etc. It is this cram-all-features-into-one hack of browser DOM that makes chrome, firefox and electron use immense amounts of power and cpu.

JavaFX, Elm and React (and by extension, the DOM) are not the only UI libraries I have been working with, but they're the ones I've had most experience with. I have also been looking at younger frameworks like Flutter or SwiftUI, both big leaps forward and very interesting, but still not quite ticking all boxes I'm looking for.

# All Icing, no Cake

I have only been talking shallowly about user interfaces and my experiences and not been providing any solutions. Over the last couple of years I've been trying to re-think many GUI abstractions from a purely-functional perspective and have come up with some solutions. By no means have I come far yet, but it is a start worth sharing I believe.

Originally I planned to begin by writing about concrete ideas, but I quickly found out that I would always de-rail the topic of the blog post to what I have written here. The goal of this blog post is to hopefully free up my mind and provide the basis for future posts.

Even though I couldn't get into any details today, I still hope that you can relate to what I'm writing and as you might have had headaches about trying to fit your design ideas to the constraints of your graphical user interface libraries.
