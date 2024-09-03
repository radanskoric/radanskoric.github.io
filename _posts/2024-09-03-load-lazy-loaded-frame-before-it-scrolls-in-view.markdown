---
layout: post
title: "How to load a lazy loaded turbo frame a bit before it scrolls into view"
date: 2024-09-02
categories: articles
tags: rails hotwire turbo turbo-frames lazy-loading
---

Turbo supports [lazy loaded frames](https://turbo.hotwired.dev/reference/frames#lazy-loaded-frame){:target="_blank"} that start loading only when they enter into the view. It's a wonderful feature that can save server resources for rarely seen content, only loading when the user is actually able to see it.

However, since it only starts loading after it is visible, there's always a small delay from it scrolling into view to it being loaded. It would be nice to start loading heavy content that's in the centre of user attention sooner. By the time it's in the view, it would be already loaded.

Turbo doesn't support this out of the box but we can implement it with a small custom Stimulus controller. First, I'll explain how Turbo implements it so the solution is clearer. This way **you'll know exactly how you can adapt it** further to your needs.

If you just want the copy-paste solution, jump directly to it [here](#solution).

## Detecting that a frame will soon scroll into view

Under the hood Turbo encapsulates the frame lifecycle logic in a [FrameController](https://github.com/hotwired/turbo/blob/main/src/core/frames/frame_controller.js){:target="_blank"} class which uses a helper class called [AppearanceObserver](https://github.com/hotwired/turbo/blob/main/src/observers/appearance_observer.js){:target="_blank"} . It is responsible for detecting that the frame has entered the browser viewport.

Inside AppearanceObserver the crucial line is:
```javascript
this.intersectionObserver = new IntersectionObserver(this.intersect)
```

[IntersectionObserver](https://developer.mozilla.org/en-US/docs/Web/API/IntersectionObserver){:target="_blank"} is a native browser object available in all modern browsers that offers robust functionality for detecting when a target element intersects the viewport. It's more versatile than that but for our purposes this is enough. If you're interested, the MDN docs I linked are a good read.

The first parameter, the one Turbo passes, defines a callback function which the observer calls whenever there's a change in the intersection.

However, there is also an optional second parameter that allows you to pass additional options. One of the options is the `rootMargin` property. This is how the docs explain it:

> A string which specifies a set of offsets to add to the root's bounding_box when calculating intersections, effectively shrinking or growing the root for calculation purposes. The syntax is approximately the same as that for the CSS margin property;

Hm, "shrinking or growing" sounds like exactly what we need! The default value is `0px 0px 0px 0px` which is why Turbo has it firing only when the frame is already within the viewport. The order of the values is like for the margin property: *top, right, bottom, left*.

Quiz time! Imagine the frame is on the bottom of the page and the user is scrolling down. You want to trigger intersection observer 1000px before it enters the viewport. What should you set the `rootMargin` to?

...

If you answered: `1000px 0px 0px 0px` then you were confused by the wording in the same way I was! That's the wrong answer. It's "shrinking or growing" the **root**, not the **target**. In our case the root is **the viewport**. So we need to pretend that the viewport is extending extra 1000px below its actual bottom. The **correct answer** is: `0px 0px 1000px 0px`.

So, if we could just change the Turbo source to declare the observer as:
```javascript
new IntersectionObserver(this.intersect, {rootMargin: "0px 0px 1000px 0px"})
```
we would have our functionality. But we can't do that.

But we can put it in a Stimulus controller. We'll attach the controller to the frame element and in the connect method set up the observer if the frame is lazy loaded:
```javascript
if (this.element.getAttribute("loading") == "lazy") {
  this.observer = new IntersectionObserver(this.intersect, {rootMargin: "0px 0px 1000px 0px"})
  this.observer.observe(this.element)
}
```

The intersect method we will take directly from Turbo source and just change the action that it takes:
```javascript
intersect = (entries) => {
  const lastEntry = entries.slice(-1)[0]
  if (lastEntry?.isIntersecting) {
    // do something to make it load now
  }
}
```
This check of `isIntersecting` is because the intersection observer will fire when elements *enter* **and** *leave* the viewport, including when it's added to the DOM. It's pretty standard to have this extra check to ensure that we're running the logic only when the element has actually entered.

Now we just need to make it load.

## Making the frame load

Thankfully, In the before mentioned [FrameController](https://github.com/hotwired/turbo/blob/main/src/core/frames/frame_controller.js){:target="_blank"} class Turbo is doing extra work to react to changes in the HTML. In particular, there's a `loadingStyleChanged` function that Turbo runs whenever the loading attribute changes and it adjusts the frame logic.

So, to cause a lazy loaded frame to load right now all we need to do is change its `loading` attribute directly on the HTML element:
```javascript
this.element.setAttribute("loading", "eager")
```

I really like this as an example of how useful Hotwire's philosophy of treating HTML as the **state of the UI** and not just as *the rendering of the state*. We don't have to wade through some arcane Turbo calls but instead we can just modify the HTML and Turbo will adapt. Turbo does the hard work to allow us to have *a simpler mental model*.

## Putting it all together {#solution}

This is the full Stimulus controller, assuming standard Rails setup with auto-loaded Stimulus controllers:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.getAttribute("loading") == "lazy") {
      this.observer = new IntersectionObserver(this.intersect, {rootMargin: "0px 0px 1000px 0px"})
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    // We want to be good citizens and clean up after ourselves.
    this.observer?.disconnect()
  }

  intersect = (entries) => {
    const lastEntry = entries.slice(-1)[0]
    if (lastEntry?.isIntersecting) {
      this.observer.unobserve(this.element) // We only need to do this once
      this.element.setAttribute("loading", "eager")
    }
  }
}
```
{: file="app/javascript/controllers/prefetch-lazy_controller.js"}

Note the file name. I named it `prefetch-lazy`. It's a nod to [Turbo link prefetching functionality](https://turbo.hotwired.dev/handbook/drive#prefetching-links-on-hover){:target="_blank"} which I view as serving a similar purpose: *making the user wait less*.

Attach it directly to a lazy-loaded turbo frame to use it:
```ruby
turbo_frame_tag :awesome, src: url, loading: :lazy, data: {controller: "prefetch-lazy"}
```

And that's it. On a page that is being vertically scrolled down this frame will be lazy loaded 1000 pixels before it enters the browser screen.

As a bonus, you could make it configurable using [Stimulus values with defaults](https://stimulus.hotwired.dev/reference/values#default-values){:target="_blank"}. That is left as an exercise to the reader.

This recipe goes really well with Turbo infinite scrolling as it's explained in [this guest article](/guest-articles/pagy-out-turbo-in).

## Why not extend Turbo with this functionality?

I had this idea at first, it would be a small change to Turbo. But then I started thinking what the interface would look like and if you tried to make it generic it would become fairly complex.

The simplest would be to extend Turbo Frame interface with something like `lazy-loading-root-margin` attribute to allow directly setting a custom `rootMargin`. However, I don't know how to explain this in Turbo docs without writing everything I wrote in this blog post. And at this point you might as well take this solution and **keep full control over it**.

Plus, it's like 20 lines in total. Just copy paste it in your project. It's going to be easier to maintain in the long run.

