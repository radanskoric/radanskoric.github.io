---
layout: post
title: "Hidden feature of Turbo: stream actions inside regular HTML"
date: 2024-05-14
categories: articles
tags: rails hotwire turbo stream-actions
---

## The feature

[Turbo stream actions](https://turbo.hotwired.dev/handbook/streams){:target="_blank"} are a central feature of Turbo, allowing for control of the webpage from server side. In essence, turbo stream actions are a piece of custom HTML markup that Turbo has a special way of interpreting as an action to execute rather than as content to be rendered.

Here's what [the official documentation](https://turbo.hotwired.dev/handbook/streams){:target="_blank"} has to say about when they can be used:

> You can render any number of stream elements in a single stream message from a WebSocket, SSE or in response to a form submission.

>Turbo knows to automatically attach `<turbo-stream>` elements when they arrive in response to `<form>` submissions that declare a [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types){:target="_blank"} of `text/vnd.turbo-stream.html`.

Quickly, without checking, answer this: will a stream action work if it is just inserted inside a plain HTML response? In other words, if I render a page and simply include a turbo stream tag somewhere in the middle of it, will the associated action be executed?

...

The answer is **yes**. The article title probably gives it away anyway.

But, for me it came as a surprise. It's because the documentation doesn't mention this explicitly. And since the list of places where you can use stream actions is so specific, I expected it to also be exhaustive.

The feature is actually very simple. Here is a minimal example showing it in action, just a small piece of static HTML. Turbo can easily be [used without Rails](/experiments/using-turbo-frame-streams-without-rails):
```html
<html>
  <head>
    <script src="https://unpkg.com/@hotwired/turbo"></script>
  </head>
  <body>
    <turbo-stream action="append" target="list">
      <template>
        <li>list element</li>
      </template>
    </turbo-stream>

    This list has an element added via the stream action:
    <ul id="list">
    </ul>
  </body>
</html>
```
If you render this in the browser, the list will have the element in it. You can see it in action in this [JSFiddle](https://jsfiddle.net/radanskoric/okx07ute/){:target="_blank"}.

## When exactly will this work?

The only thing needed for this to work is for the stream tag element to be rendered into the HTML DOM:
- Anywhere inside the initial page HTML.
- As part of the turbo frame response **as long as it is rendered inside the frame tag**. Since content from outside the frame is not rendered into the actual document, the tag needs to be *inside the frame* for this to work.
- If any javascript at any point rendered a turbo stream element anywhere inside the document DOM.
- If a stream action renders HTML content (like it does in the example above) **and that content in turn also has a stream action tag inside it**, the second action tag will also work. *Note: Unless you're doing something very strange, you probably don't want to do this.*

The only thing needed is that the tag ends up as part of the rendered HTML. It will work anywhere, regardless of how the tag is added to the HTML. It will even work if Turbo Drive is disabled.

## What is this useful for?

If you're building a Turbo powered application from the ground up you can probably use more direct Turbo mechanisms instead. However, if you're retrofitting Turbo onto an existing application or making a minor addition to an existing Turbo feature it can be very useful. Think of it as *a backup tool* to reach for when more direct Turbo approaches don't work or become convoluted for your particular situation.

Some examples where I've found this useful:

### Example: Executing side-effects with a Turbo frame response

You might have implemented a very elegant flow using pure Turbo Frames but there is just some small extra thing that needs to happen when the Turbo Frame loads. For example: update a counter or modify a small related piece that's outside the frame.

Depending on the details of your case you could [use full page Turbo Morphing](/articles/turbo-morphing-deep-dive). If that won't work, you could refactor everything to just return a turbo streams response. The turbo frame response could become a turbo stream `replace` action and then you could add more actions.

But sometimes you want to make the minimal change needed to make it work. For that you could render the stream action for the side-effects *inside the frame* and rely on the feature we are discussing here. You achieve the side-effect with minimal changes and keep the main logic simple.

### Example: Updating multiple parts of the page after following a GET link

For GET requests Turbo will **not** expect a Turbo streams response and if you do return a Turbo stream response (i.e. Content-type of `text/vnd.turbo-stream.html` instead of `text/html`), it will not attempt to process it as such. It will simply not work. The assumption is that you're either updating a full page or one frame.

This means that you can't use Turbo streams on get requests to update multiple parts of the page. However, you can insert streams into the primary HTML response to achieve the same.

Be very careful with this and think twice before using it. In most cases you probably don't need it but Ruby and Rails are all about sharp tools given to you to use wisely. This is another one.

### Example: Executing JS on Page, Frame or plain AJAX load

In a lot of legacy applications you'll find inline `<script>` tags with the HTML code to be executed when HTML is loaded.

Stream actions inside HTML can eliminate any need for inline javascript. Anything you would want to do with a custom piece of javascript can be done more elegantly and cleanly with a Turbo Stream Action rendered inside the HTML.

For example, triggering frontend analytics tracking from server side or opening a UI widget (like a modal) on page load. This is not uncommon in legacy applications as sometimes the easiest way to get it working is to just use inline javascript. Instead, you could create a custom Stream Action, implement the logic on it, and then render just the stream action tag. The code will be cleaner and more maintainable.

This will also allow you to easily get to the point where you can configure the [script-src Content-Security-Policy rule to disallow inline scripts](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src#unsafe_inline_script){:target="_blank"}, which is one of the biggest security wins CSP provides.

#### A note on using this with custom stream actions

If you'll be using this with [custom stream actions](https://turbo.hotwired.dev/handbook/streams#custom-actions){:target="_blank"} invoked from initial page load, make sure to use the approach where the custom action is defined directly on the stream actions object, i.e.:
```javascript
import { StreamActions } from "@hotwired/turbo"

// <turbo-stream action="log" message="Hello, world"></turbo-stream>
//
StreamActions.log = function () {
  console.log(this.getAttribute("message"))
}
```
The other approach outlined in [the documentation](https://turbo.hotwired.dev/handbook/streams#custom-actions){:target="_blank"}, using `turbo:before-stream-render` won't work because the tag can be rendered before the listener is attached. To find out why, read on.

## Is this documented?

It has been working like this from the very first version of turbo, `7.0.0-beta.1` (Turbo inherited versioning from [Turbolinks](https://github.com/turbolinks/turbolinks){:target="_blank"}, which is why it started counting versions at 7).

I couldn't find anything mentioned about this in [the official documentation](https://turbo.hotwired.dev/handbook/streams){:target="_blank"}. There's nothing in the [7.0.0-beta.1 release notes](https://github.com/hotwired/turbo/releases/tag/v7.0.0-beta.1){:target="_blank"} nor in the [Turbo 7 official release announcement](https://world.hey.com/hotwired/turbo-7-0dd7a27f){:target="_blank"}.

That said, there is a passing reference in the documentation that hints at this feature but I only caught it after going in with the debugger and figuring out how it works.
The docs say: "Turbo knows to automatically **attach** `<turbo-stream>` elements". The attach word is significant. To understand why, read on to find out how it works.

> Consider subscribing to get more articles like this one and to get my [printable Turbo 8 cheat-sheet](/cheatsheet):
> <script async data-uid="c481ada422" src="https://thoughtful-producer-2834.ck.page/c481ada422/index.js"></script>
{: .prompt-info}

## How does this feature work?

Turbolinks didn't have any concept like Turbo Streams. They were introduced with Turbo. And from the very first implementation of turbo streams (in [this commit](https://github.com/hotwired/turbo/commit/bf1f555a9a64b02fe29f23bd2c892f4ae9473373){:target="_blank"}) embedding them in HTML worked.

It's because Turbo streams are implemented as [a custom HTML element](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements){:target="_blank"}. If you're not familiar with them, they are a way to add application specific html elements (e.g. `<my-widget>Lore ipsum</my-widget>`). For now, this is all you need to know about how custom HTML elements work:
1. They are implemented with a JS class that subclasses one of the existing HTML element classes built in by the browser. Often it just extends the base `HTMLElement` class.
2. The class can override a number of functions to modify how the element is rendered and one of those is the `connectedCallback` function which is called by the browser when the element is parsed and *connected* to the DOM tree.
3. You link your class with the HTML tag name by defining it on the [customElements property of the window object](https://developer.mozilla.org/en-US/docs/Web/API/Window/customElements){:target="_blank"}, implemented by the browser.

Turbo, when it is loaded defines the custom `StreamElement` ([source](https://github.com/hotwired/turbo/blob/main/src/elements/stream_element.js){:target="_blank"}) class which inherits from `HTMLElement` and then adds it to customElements:
```javascript
customElements.define("turbo-stream", StreamElement)
```

`StreamElement` implements the `connectedCallback` method so that, instead of rendering, it interprets and executes the stream action. After it's done it completely removes the tag from the DOM. The implementation changed a bit over time but the gist of it stayed the same.

When the documentation says that "Turbo knows to automatically **attach** `<turbo-stream>` elements" it means that Turbo is inserting the stream elements into the DOM and then letting the browser parse it and in turn invoke the `StreamElement` code. This has the nice benefit of the browser doing the heavy lifting of processing the source of the stream action.

And if anything else were to **attach** a `<turbo-stream>` element it would also work because the browser will always invoke `connectedCallback` on `StreamElement`. And this is how this feature works.

## Conclusion

Considering how the feature was implemented and how it's not mentioned anywhere and Turbo doesn't do anything specifically to make it work, it seems almost accidental that we got this feature. However, the mechanism behind it working is so fundamental and so simple that I don't expect this feature to go anywhere and I'm very comfortable using it.

I've [opened an issue on Turbo](https://github.com/hotwired/turbo/issues/1258){:target="_blank"} to clarify the situation and initial feedback is positive. I will update here as it develops.
