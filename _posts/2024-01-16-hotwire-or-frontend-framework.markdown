---
layout: post
title: "Should you use Hotwire or a Frontend framework on your next Rails project?"
date: 2024-01-16
categories: articles
tags: rails turbo hotwire frontend
excerpt_separator: <!--more-->
---

*I am writing this for the senior engineer or tech lead that is deciding whether to use [Hotwire](https://hotwired.dev/){:target="\_blank"} or a Frontend framework (e.g. [React](https://react.dev/){:target="\_blank"}, [Vue](https://vuejs.org/){:target="\_blank"}, [Svelte](https://svelte.dev/){:target="\_blank"} ...) for the frontend portion of the next Rails project. If this is you, read on.*

## The key factor

You have already gone over the usual list of factors that you consider for *every new project no matter what tech stack it is on*: **the expertise of your team members**, **technologies used on existing projects at your company**, **available libraries or ready solutions**. These are table stakes, you've considered them like you always do and for this project, they're not pointing either way. I will make a case that, once those fundamental questions are cleared, there is one that is specific to this decision and stands above all others:

**How is the complexity of the project distributed between shared state management and visual interactions?**

Most of the cost of software is in maintenance and most of the cost of maintenance comes from the complexity of our solution. Picking a tech stack that is well suited for managing the kind of complexity you are facing will make it easier to keep the complexity under control.

The point will become clearer once we consider the two extremes.

<!--more-->

## Case 1: Most of the complexity of your application is in managing shared state.

The shared state is stored in the database. The DB is the literal source of truth and getting just the pure state is **simplest when talking directly to the DB**. The backend layer is the one closest to the DB so it is not surprising that complexity reduces when you put most of the logic there.

Common arguments for Hotwire are mostly about state management. The most repeated reason I've seen is: "With FE frameworks you are managing 2 applications." This is mostly in reference to the codebase but with SPAs you're also managing two running applications. Which means distributed state. Which is never easy but becomes worse if most of your complexity is in managing shared state.

## Case 2: Most of the complexity of your applications is in visual interactions.

Here the complexity will be all about interacting with the browser, the user interface and efficient rendering. FE frameworks are right there, metaphorically in the bed with the browser. So it's not surprising that they will shine in that scenario.

Again, common examples of why one should use FE frameworks are complex interactions, usually very visual. Another often mentioned argument are excellent ready made components. This is most useful when you are designing complex user interactions. If you are building an immersive visual experience or very innovative UI, then you will heavily reduce complexity with a strong FE framework.

## What about something in between those two cases?

There are many dimensions of complexity in each project and they influence many technical decisions but the state vs interactions complexity is one I have found most important for making a good decision on the frontend tech stack.

Most of the apps will have a mix of the two cases:
- *Mostly straightforward with one very rich interaction component.* Example: A pretty straight forward business app with a calendar screen with lots of custom functionality.
- *App built around one very interactive screen where users spend most of the time and auxiliary screens.* Example: An interactive whiteboard app.
- *Nothing standing out but most UI being a bit more interactive than "lightly styled HTML".* Example: quite a few consumer apps will want to make the interaction itself more fun to keep the user engaged. There's a whole spectrum here.

It's going to be your call which way it leans but once you look at it through the complexity taming lens the answer is likely to stare back at you.

Don't forget that the hybrid approach is also viable: **A mostly Hotwire app with small self contained single page applications embeded in the pages.** If in the end there are still too many unknowns to make an informed call, this might be the safest way forward since it's closer to the default Rails approach.

If you're enjoying my writing, please consider subscribing:
<script async data-uid="a747d9cf0d" src="https://thoughtful-producer-2834.ck.page/a747d9cf0d/index.js"></script>

## Conclusion

Answering a technical choice by first looking at the tools themselves is usually a bad way to find the answer. It's always a tradeoff and your specific tradeoff comes from the project, not the tools. Understand where is the complexity and **only then find the best tool for the job.** 

For me personally, based on my experience and the kind of work I do, the complexity of most apps is in the shared state which is why I'm [very](/articles/turbo-morphing-deep-dive) [excited](/articles/turbo-morphing-deep-dive-idiomorph) about the Hotwire approach. For you, and your work, you know best, make your choice confidently.
