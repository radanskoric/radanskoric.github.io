---
layout: post
title: "Hotwire and HTMX - Same Principles, Different Approaches"
date: 2024-10-29
categories: articles
tags: hotwire htmx turbo comparison
---

[Hotwire](https://hotwired.dev/){:target="_blank"} and [HTMX](https://htmx.org/){:target="_blank"} are two powerful libraries that both have the same goal: **simplify building modern web applications**.

Both embrace the HTML+CSS basis of the web and enhance it to enable slick UIs with little or no javascript needed.

While both projects share many fundamental values and even goals, they take different approaches to fulfilling them. By the end of this article you'll have a good high level understanding of their similarities and differences.

> My primary experience is with Hotwire. I have worked with it extensively. My interest in HTMX is mainly to expand my mental horizon: by learning other technologies I often find valuable new ideas.
>
> To ensure a balanced view **I bought and read the book [Hypermedia Systems](https://hypermedia.systems/){:target="_blank"}, written by the authors of HTMX**. They explain their ideas and walk through building a HTMX powered application.
>
> *If you notice I misunderstood something, please, write in the comments or to me directly and I'll improve the article.*
{: .prompt-info }

## Shared fundamental principle: Power of HTML

Both frameworks recognize the value of an HTML centred approach. This is in contrast to the numerous Single Page Application (SPA) javascript frameworks that implement the [thick client pattern](https://en.wikipedia.org/wiki/Rich_client){:target="_blank"} inside the browser. They treat HTML as not much more than a rendering medium.

On the other hand, frameworks like Hotwire and HTMX recognise that HTML is more powerful when treated as [the engine of application state](https://en.wikipedia.org/wiki/HATEOAS){:target="_blank"}. The principles behind the design of HTML as a [thin client](https://en.wikipedia.org/wiki/Thin_client){:target="_blank"} technology are old but still valid. HTML has seen a lot of advancement and HTML5 + CSS combo in modern browsers is very powerful. However, it's not enough to build rich modern interactive applications. **It is almost but not quite there.**

Frameworks like Hotwire and HTMX aim to close the gap and enable server side rendered HTML to deliver a modern user experience. They are implemented in javascript but they are designed to require as little custom application javascript as possible. As it turns out, this makes the majority of modern web applications much easier to build.
## Ridiculously short intros to the frameworks

This article isn't a tutorial for either framework. I will attempt to give you the shortest possible intro to both frameworks, just enough so rest of the article makes sense if you're unfamiliar with either or both of the frameworks.

### Hotwire
*If you have even just a basic familiarity with Hotwire, I suggest you skip to the next chapter.*

[Hotwire](https://hotwired.dev/){:target="_blank"} stands for **"HTML Over the Wire"**. It's an umbrella name for multiple libraries. The main one is **Turbo**.

Turbo enhances HTML by introducing a few key concepts:
- *Turbo Drive* intercepts regular browser navigation and instead performs an AJAX request and handles the response itself. It speeds up the navigation by avoiding a full page reload. It also adds missing HTML functionality, like an ability to make links perform a non-GET request.
- *Turbo Frames* decompose the page into independent contexts. They implement the mental model of a page within a page. This offers a natural way to build integrated UI that lives on the same page but is implemented as simply as if it was a separate set of pages. For example: inline editing can be treated as a multi page editing flow contained on a single page, in a frame.
- *Turbo Streams* allow the server to render small targeted instructions that modify a specific part of the page. They are delivered either as a response to a form submission or via websockets, to enable collaborative applications.

Underlying all of the Turbo features is the approach that developing should feel as much as possible like building a plain server side rendered HTML application, just one that works much better. All of the business logic is on the server and the interface is controlled by delivering HTML to the client.

Where that is not enough Hotwire's second library comes into play: *Stimulus*. You can think of Stimulus as a modern replacement for jQuery:
- Makes it easy to react to events and modify the DOM.
- Doesn't take over HTML but instead treats HTML as the source of application state.
- Best used to add specific functionality that HTML lacks out of the box.

It accomplishes this by attaching small *Stimulus controllers* that are attached to a specific DOM element and allow you to use javascript to enhance the element with some custom behaviour. For example, adding `data-action="mouseenter->popup#show"` on an element using the `popup` controller will cause the `show` javascript method on the controller to run when we hover the mouse over it.

### HTMX
*If you have even just a basic familiarity with HTMX, I suggest you skip to the next chapter.*

HTMX stands for **"HyperText Markup eXtensions"**. It is designed to enhance HTML by allowing:
- Any element to issue a HTTP request.
- Any event to trigger a HTTP request.
- Any HTTP verb to be used in the request.
- Any part of the page to be updated with the HTTP response.

It accomplishes this through a set of attributes that can be placed on any element and which enhance it with extra functionality, implemented by HTMX. There are many such attributes, here are just a few examples to give you a taste:
- `hx-post="url"` will turn the HTTP request from a regular GET to a POST. Equivalent attributes exist for all HTTP verbs.
- `hx-swap="outerHTML"` will make HTMX use the HTTP response to replace the whole target element, rather than just its content.
- `hx-trigger="mouseenter"` will trigger the HTTP request when we move the mouse over the element, rather than waiting for a click.
- `hx-target="#container"` will use the HTTP response to update the element with the id `container` instead of the element that we've clicked.

There are many other attributes. Some of them support mini DSLs for customizing the behaviour even further. All of the attributes are orthogonal and complementary. The general idea is that you combine these HTMX enabled attributes to build sophisticated interfaces.

For example here is a list element that, when clicked while holding a ctrl key will issue a post request to the `\generate` endpoint and add the response as the last item in the list:
```html
<ul hx-post="\generate" hx-trigger="click[ctrlKey]" hx-swap="beforeend">
  <li> Click while holding Ctrl to generate new items </li>
</ul>
```

## The similarities

Fundamentally, both start from the same premise:
1. HTML and CSS offer a rich interface for interactive experiences.
2. The Single Page Application approach of building a thick client that uses HTML just for rendering adds incidental complexity.
3. The additional complexity can be avoided by treating HTML as the source of application state and rendering it on the server.

Putting it all together, they conclude that there is great **opportunity to radically simplify web application development with a different approach**.

And both are taking the same high level approach:
1. Keep the business logic on the server.
2. Make HTML the store of application state.
3. Enhance HTML to enable modern user experiences.
4. Use Javascript for custom behaviour only when enhanced HTML is not enough.

Observed from a far both solutions look very similar, as if they are almost the same thing.

Looking closer, they adopt different principles with lead to significant differences in the way they feel. Spoiler alert: I think both are great, for different reasons.

## The differences

Their design choices differ in:
- Ratio of Implicit vs Explicit enhancements.
- How far to push the edge after which you are expected to write custom Javascript.
- How much it assumes from the backend to fully leverage its functionality.

### Implicit vs Explicit enhancements

A framework that enhances HTML needs to make a choice: When should the enhancement be explicitly activated by the application code and when it should activate implicitly based on context. In other words: **How "magical" do we want the framework to feel?**

Hotwire, and Turbo specifically, leans into "magical" quite a lot:
1. By default, as soon as you import Turbo on a page, it activates Turbo Drive and takes over the navigation. You can turn it off, but the default is for it to enable a set of enhancements without you needing to do anything.
2. Turbo Frames work hard to make the mental model of "page in a page" just work. For the most common cases, if you put the frames in the right places, all the common paths will just work. Frames enable many enhancements by default. You are expected to use custom attributes mainly to break out of the default behaviour.

This is intentional. If you're familiar with Ruby on Rails you'll notice that Hotwire inherits this approach from Rails.

HTMX takes a completely different approach. It makes an explicit choice to be a **low level enhancement** library that only does things explicitly. When HTMX is included on the page, by default it does: **nothing**. Every bit of functionality is enabled by explicitly adding one of the `hx-` attributes to an element. No attribute, no enhancement.

One lone exception to this is `hx-boost` which, when placed on an element will boost the links and forms contained in that element. Placing `hx-boost` on the BODY tag gets you some of the functionality that Turbo Drive gives out of the box. However, HTMX highlight this as a pragmatic exception to the philosophy of the library of having **only explicit enhancements**.

Both approaches have their pros and cons:
1. Turbo will require less work from you for the majority of features but will be more problematic when the "magic" stops working.
2. HTMX will require more work from but will leave you in control of exactly which parts of it are active on a particular element.

### How far can you get without javascript

If you are interested in doing as much as possible without writing custom javascript, HTMX will get you much further. Since it's designed as a low level toolkit, it has a large number of attributes that can be combined in many ways to get a lot of different behaviours. It might take you a while to learn all the attributes and all of their options but it will get you very far. Its DSL even enables things like animations via CSS transitions defined directly in `hx-` attributes.

Turbo on the other hand works very hard under the hood to give you a coherent mental model for its enhancements that will get you pretty far without you having to memorise too many options. Turbo enhancements are all focused on interactions with the server. As soon as you need some extra UI behaviour, it nudges you over to Stimulus, expecting you to write a small bit of custom javascript inside it.

Again, both approaches have their pros and cons:
- HTMX has a larger API surface that you have to memorise but it gives you more functionality by default.
- Turbo and Stimulus API make it easier to remember all the functionality they offer but you will be reaching for custom Javascript more often.

Neither is wrong, it's going to largely depend on what feels more natural to you and your team.

### How much it assumes from the backend

Hotwire came out of a largely backend framework: Ruby on Rails. HTMX didn't. This shows. Hotwire is still backend agnostic, *however*, if you are using Rails, it comes with an excellent integration with many things taken care off. And, it suggests other frameworks to use the Rails integration as the *reference backend integration*. HTMX pays much less attention to the backend.

This shows when a feature set really needs a specific backend part to make sense. For example, collaborative features of Hotwire, *just work* with Rails. Integration with the backend through websockets is a first class feature of Turbo. And Stimulus is fine tuned to work great with changes being streamed from the backend. Getting collaborative features working with Hotwire is very straightforward once you have the right backend integration. HTMX does have support for websockets integration but [it is an extension](https://v1.htmx.org/extensions/web-sockets/){:target="_blank"} that was not even mentioned in the book.

Both Hotwire and HTMX can be used with any backend stack, that's the whole point of the HTML-over-the-wire/Hypermedia approach. However, depending on your backend stack of choice, and the requirements of your application, you might find one or the other easier to integrate.

Unsurprisingly, for Ruby on Rails, [the turbo-rails gem](https://github.com/hotwired/turbo-rails){:target="_blank"} is much more developed than [the htmx-rails gem](https://github.com/rootstrap/htmx-rails){:target="_blank"}.

## Closing thoughts

It's very interesting how it's possible to start from the same set of fundamental values and arrive at two different high quality solutions that both honour the basic principles but still feel very different to use.

As a long time Rails developer, my library of choice is Hotwire. I love it when it works as expected but sometimes I wish it was more explicit when I need to do something different. And reading about the many options of `hx-` attributes got me thinking about how I could structure my stimulus controllers to ingest tiny DSLs to allow for more control directly from the HTML.

So which one is better overall? Like with many questions in programming the answer is frustratingly: it depends.

What about you, which approach do you prefer **for your current team and project**?

If you've enjoyed this comparison and are interested to learn more about Hotwire, consider subscribing below. I am working on a Hotwire e-book designed for *experienced Rails developers* to significantly speed up your journey to an *experienced Hotwire developer*. I'll announce the beta launch with a special discount only to my subscriber list.
