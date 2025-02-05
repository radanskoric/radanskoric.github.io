---
layout: post
title: "How to avoid problems with Turbo morphing"
date: 2025-02-05
categories: articles
tags: rails turbo hotwire morphing tips
---

> A beautiful UI \
> Morphed into existence \
> Suddenly broken

*A Haiku about Turbo Morphing, by me (just me, no AI)*

## The problem with morphing

Turbo 8 [debuted](https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/){:target="_blank"} a new page refresh approach: [morphing](https://turbo.hotwired.dev/handbook/page_refreshes){:target="_blank"}. For the rest of the article I'm going to assume you are familiar with it.

Like other Rails "magic", morphing delights when it works and frustrates when it interferes. And its interference can be extremely annoying.

Common problems include:
- Non-Turbo-aware JavaScript libraries lose their initialized DOM elements during morphing.
- User-modified UI states (opened sidebars, accordion elements) reset to defaults.
- Server-loaded forms disappear after morphing.

These issues share one root cause: **Part of the new state is in the browser and morphing causes problems by forcing it to match server state.**

## Solutions

The solutions fall into 3 categories:
1. Telling Turbo to leave it alone.
2. Limiting the update scope.
3. Getting the server state to match the browser state.

Each strategy is best for different scenarios.

>Find the accompanying demo at [https://demo.radanskoric.com/morphing](https://demo.radanskoric.com/morphing){:target="_blank"}. Browse its source code here: [https://github.com/radanskoric/demo/tree/main/demos/morphing](https://github.com/radanskoric/demo/tree/main/demos/morphing){:target="_blank"}. If you want to look at concrete examples I will mention them throughout the article..
{: .prompt-info }

### Telling Turbo to leave it alone

When we're using a sophisticated 3rd party JavaScript UI library that is not Turbo aware it's likely that it will modify the DOM and keep state in JavaScript objects.

The easiest thing is to tell Turbo to leave it alone. There are 2 ways to do that.

#### data-turbo-permanent

Attaching `data-turbo-permanent` attribute to an element will cause Turbo to preserve the element and its children.

To use it effectively, it's important to understand how this works under the hood. When Turbo is doing a refresh of the page it:
1. Saves all elements marked with data-turbo-permanent from the current page. It stores them by id to be able to reference them later. This is why all **permanent elements must have a unique id**.
2. Finds existing permanent elements in the new content to be inserted and replaces them with placeholders, keeping the id.
3. Performs the page refresh.
4. Finds all placeholders by id and inserts the matching saved nodes from the previous page. This means that the nodes remain as exactly the same JavaScript objects. This is how the permanent elements keep all of the attached JavaScript objects or listeners intact across an update.

Notice that this technique doesn't mention morphing. It will also work if you're not using morphing and instead using the default strategy of *replacing* the full content of the body element.

Note: by marking an element as permanent you might have the opposite problem: the element staying completely unaffected even if it should change a bit. Usually it will be enough to listen to the appropriate event and modify the state.

In the [demo](https://demo.radanskoric.com/morphing){:target="_blank"}, the rich text editor is marked as permanent. This causes the typed in text to remain even after submitting the form. To solve that, the form listens to the form submit event and resets itself.

#### Before morphing callbacks

Turbo provides two morphing-specific callbacks:
1. `turbo:before-morph-element` fires before element morphing
2. `turbo:before-morph-attribute` fires before attribute morphing

You can call `event.preventDefault()` in these listeners to stop specific morphing actions. See the [official documentation](https://turbo.hotwired.dev/reference/events#page-refreshes){:target="_blank"} for details.

In the [demo](https://demo.radanskoric.com/morphing){:target="_blank"}, the counter element at the bottom uses that approach.

### Limiting the update scope

Turbo gives us two tools to update specific page sections:
1. Turbo stream actions - particularly **replace** and **update**
2. Turbo frames

#### Turbo stream actions

[Replace](https://turbo.hotwired.dev/reference/streams#replace){:target="_blank"} and [update](https://turbo.hotwired.dev/reference/streams#update){:target="_blank"} stream actions modify elements completely or update their content. Both support updating with morphing through the `method="morph"` attribute.

These actions apply the same morphing logic as full-page updates but scoped to the target element. All the other  mentioned techniques also work within this scope.

Full page updates are simpler to maintain, if they work. Sometimes scoping the update to a part of the page can be the simplest solution.

This approach particularly helps when adding morphing to **legacy applications**. Start with smaller page sections and expand the morphing scope as the codebase adapts.

#### Turbo frames

Turbo frames scope the updates to a part of the page. However, there is a bit of a problem if we're talking about morphing: it doesn't support it.

You may now be thinking: "Wait a minute! there's a `refresh="morph"` attribute!" And you're right, it's right there in the [official documentation](https://turbo.hotwired.dev/reference/frames#frame-that-will-get-reloaded-with-morphing-during-page-refreshes){:target="_blank"}. But notice the wording: "Frame that will get reloaded with morphing **during page refreshes**" (emphasis mine). The morphing algorithm runs **only** when the frame is refreshed as part of a *full page refresh*, not if just the frame itself is being refreshed.

Still, frames might provide smooth enough updates without morphing. Focus on the user experience rather than specific technical approaches.

> This is not entirely true, a frame with `refresh="morph"` will also update using morphing if it is explicitly reloaded from javascript using `.reload()`. There is an [unmerged documentation PR that clarifies this](https://github.com/hotwired/turbo-site/pull/170){:target="_blank"}.
{: .prompt-info }

### Getting the server state to match the browser state

And, for the final trick, I will not use any specific functionality of Turbo. Instead, notice that we wouldn't have the problem in the first place if server fully contained the new state. We would then be morphing towards the actual desired state, completely sidestepping the problem.

This is best applicable to simpler UI updates:
1. We opened a sidebar and don't want it closed.
2. We toggled a HMTL widget and don't want it reset to the default state.
3. We opened a non default tab and want to stay on it.

And so on ...

In all those cases, we could render the correct state on the server, if we had the information.

#### Preserving the state on the server

If we store the state of the UI on the server we can re-render it correctly. There is no special technique here, it's all regular UI development.

If we have some HTML widgets that you can toggle we could also have a *user preferences* object to save the state of widgets. When a widget is toggled, a stimulus controller attached to it submits the new state which gets saved in the preferences object. We can then use that when rendering the page on the server. Morphing will no longer reset it and, as a bonus, it persists across user sessions.

This best usage of this approach is when it also has a UX benefit beyond fixing morphing.

If database is not the appropriate place to store it, consider whether it makes sense to store it in the session object.

In the [demo](https://demo.radanskoric.com/morphing){:target="_blank"}, this is exactly where the open/closed state of the info box at the top is stored, using a custom Stimulus controller.

#### Preserving the state in the URL

Server side is not the only place where we can store the state. We can also modify the address bar.

For example: when a user opens the sidebar, we could modify the URL to include a `sidebar=1` parameter. Later we trigger morphing by submitting a form which does some work and redirects back. However, the back url has `sidebar=1` and on the server we can render the sidebar as already open, matching the state on the frontend.

This approach also enables URL sharing with preserved UI states. Many highly interactive web apps use URL parameters for this purpose.

In the [demo](https://demo.radanskoric.com/morphing){:target="_blank"}, the details sections on the saved notes store their open/closed state in the URL, using a custom Stimulus controller.

## What if none of this works for your case?

If you're still unsure how to fix your particular morphing issue and none of the specific techniques above are working, it might mean you have a really special case.

In that case, the best next steps is to get familiar with how exactly morphing works under the hood. My articles on [how morphing works from Rails perspective](/articles/turbo-morphing-deep-dive) and [how the underlying idiomorph algorithm works](/articles/turbo-morphing-deep-dive-idiomorph) give a thorough overview.

And finally, did I miss some useful techniques you would like to share? Please share them in the comments and I might include it in the article.

Morphing is still a relatively young technique and it would benefit greatly from everyone sharing their experience.
