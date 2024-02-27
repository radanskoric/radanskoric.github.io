---
layout: post
title: "How to debug issues with Turbo Morphing"
date: 2024-02-26
categories: articles
tags: debugging rails turbo hotwire morphing
---

[Turbo's morphing feature](https://turbo.hotwired.dev/handbook/page_refreshes){:target="\_blank"} can look magical. There's a lot of pieces
moving behind the scenes to make it come alive. That's great when it works but when it doesn't you might be left staring
at the screen unsure where to start to debugging it. *Maybe* you made a mistake in your code. *Maybe* it's all working as
expected but it caught you by surprise. *Maybe* you ran into a bug in Turbo itself. Yes, that's also possible.

Recently, I decided to debug an issue reported to Turbo, thinking it's someone misunderstanding expected behaviour.
However, I instead found a [corner case bug](https://github.com/hotwired/turbo/issues/1158#issuecomment-1938477505){:target="\_blank"}.
It's a complex bug but I was happy that it took just about an hour from starting debugging it to finishing the write up.
I used a few techniques that helped me a lot and here I share them in short, in case you also need to do the same.

## Get accurate mental models

Because there's a fair amount of moving pieces, it's extremely useful if you have an accurate mental model of how it
all works together. I did two deep dive articles on how Turbo morphing works: one on
[the turbo plumbing around the actual morphing algorithm](/articles/turbo-morphing-deep-dive) and
[one on how the algorithm, idiomorph, works](/articles/turbo-morphing-deep-dive-idiomorph). My advice would be to read
them both (20min total read time). If you are in a rush and don't have the time and need to debug **right now**,
read on, I'll mention the key points again here.

## Make it reproducible

This is true for absolutely any debugging effort but it's worth repeating. Make sure that you can reproduce the issue
repeatedly and consistently as you'll likely need to do it a few times.

Usually, you would also put a lot of effort into making a *minimal reproducible example*. Here it's less important.
If you can easily turn off chunks of the page not affected to make it easier to focus, do it. But don't spend a lot of
effort getting to absolute minimal example. You'll be able to debug effectively even if there's some extra HTML action
going on. Also, if it'll turn out to be a Turbo bug that you want to report, you'll find it easier to create a good
minimal example once you find the root cause.

## Change Rails to use a non minified version of Turbo

By default, a minified version of Turbo will be used. In a fresh Rails app using importmaps (the default) it will look like this:
```ruby
pin "@hotwired/turbo-rails", to: "turbo.min.js"
```
Change it to:
```ruby
pin "@hotwired/turbo-rails", to: "turbo.js"
```
This will make it easier to follow what's going on in the library itself when debugging and set breakpoints inside turbo code.

## Break on DOM change

*I am assuming you have at least a basic familiarity with developer tools javascript debugger. If you don't, one place
where you could start getting familiar is [this MDN article](https://developer.mozilla.org/en-US/docs/Learn/Common_questions/Tools_and_setup/What_are_browser_developer_tools#the_javascript_debugger){:target="\_blank"}.*

For debugging Turbo it is very useful that there is no intermediate state stored in Javascript between two morphing updates.
It means that morphing is fully defined by the new HTML that arrived over the wire and the current state of the DOM.
It also makes debugging easier.

Morphing modifies the current DOM nodes by either removing them or updating its attributes and children. All of these can
be caught by setting a breakpoint on the DOM note. Turn on the web inspector by right clicking the element on the page
and selecting "Inspect". Then, in the inspector view showing html, right click the relevant dom element. In the context
menu find a submenu like this one:

![[Screenshot 2024-02-19 at 14.49.27.png]](/assets/img/posts/browser-break-on-element.png)
*This is a screenshot from Brave which is based on Chromium, but other main stream browsers (e.g. Chrome, Firefox, Safari) all have almost identical menus.*

All of the 3 options are useful in some scenarios:
- **subtree modifications**: Idiomorph algorithm recursively descends the DOM tree, morphing each node with its children before proceeding to siblings. This is convenient for debugging, as breaking on subtree modification will allow you to easily step through the changes to that node.
- **attribute modifications:** this one is especially useful for debugging issues with turbo frames inside morphed content. Remote turbo frames inside morphed content can be especially tricky because they have a more complex lifecycle than regular nodes or even regular turbo frames. If you find yourself running into strange issues related to Turbo Frames try putting some breakpoints inside [FrameController](https://github.com/hotwired/turbo/blob/main/src/core/frames/frame_controller.js){:target="\_blank"} in Turbo source. More on breakpoints in Turbo source in next section.
- **node removal:** This is probably the least useful option because if a node is being completely removed when you expect it in the final output, the most likely cause is that it's missing in the new HTML response. Anything other than that is a bug in the morphing library.

## Setting breakpoints inside Turbo source

At this point, if you just set breakpoints on the relevant elements and go through the recreation steps you'll probably find them firing before you got to the relevant reproduction step. You can keep pressing "Resume" to let it continue running until you get to the reproduction point but that is tedious. It will be easier if you stop execution just before the morphing starts and then set the breakpoints on elements while paused.

You don't need to know the entire turbo source, there are just a few key points to be aware of. As of the time of this writing turbo version is **v8.0.3**. I will give you snippets to search for instead of source links since those are more likely to remain true in future versions.

In the developer tools, navigate to Elements tab and in the `<head>` find the `script` tag for turbo, right click and select "Reveal in Sources tab". There you can:
1. Search for `async #morphBody` and place a breakpoint inside it. If morphing is triggering as expected, this is where the actual morphing will start.
2. Search for `shouldMorphPage =`. This will land you inside the `PageView#renderPage` method which handles the actual rendering of the response received from the server. If you're not hitting the morph body breakpoint, try here as this should fire every time.
3. Finally, if you have issues getting it to even call through to the server, search for `linkClicked=` this is a callback that attaches to links and lets Turbo takeover from default browser behaviour.

Go through your reproduction steps and wait until you hit the breakpoint. Only then use one of "Break on" options
with the problematic elements and then resume script execution. Note that in the debugger sidebar you can turn on and
off individual breakpoints for quicker set up in subsequent runs.

And good luck!

# A request for your feedback

Finally, a small request from me. Explaining effective debugging is quite hard, especially for such a visual and distributed flow as Turbo. If you came so far and are still struggling to figure out how to debug your issue, please either write about it below in the comments or e-mail me (e-mail can be find at the bottom of the menu sidebar). I will read every e-mail and I will do my best to help you as time allows me. I am playing with ideas on how to explain effective debugging and a concrete example of where someone got stuck would help me produce better content.
