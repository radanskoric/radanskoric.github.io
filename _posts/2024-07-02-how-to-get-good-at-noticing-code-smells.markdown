---
layout: post
title: How to get good at noticing code smells
date: 2024-07-01
categories: articles
tags: software engineering meta thoughts becoming-senior
---

[A code smell](https://martinfowler.com/bliki/CodeSmell.html){:target="_blank"}, put loosely, is **code that looks like it's going to be trouble**.

When it's **correctly** _identified_ you usually discover that:
- it's hiding a much bigger problem
- it's tightly coupled to another component causing maintenance headaches
- it's hard to understand for new developers slowing done the development
- it's brittle and will easily break with future changes
- put simply, it's going to cause problems ...

Removing the smell is a win. Maybe it's a small or maybe it's a big win but if you do it consistently you're going to do wonders for the codebase. You'll earn a reputation of a person that truly leaves the codebase better than you found it[^1]. But you if you misdiagnose the smell, you'll _waste effort and time_.

That is why getting better at detecting code smells is crucial for becoming a better senior developer.

## The taxonomies

If you start searching the web for code smells you'll find a long list of articles, wiki pages and even books, tackling code smell directly or indirectly, with many examples. There are even taxonomies of code smells, some of really good quality.

The problem with all of these is that they are good for reminding but not great for learning. By and large, when reading these, people either nod along because they've already seen it or don't grasp the key point.

## The hard way is the best way

The bad news is that there aren't any shortcuts here. It's a pattern recognition skill that takes practice. The good news is that with the right attitude and habits you can pick up the skill faster.

The one thing that has helped me a lot, more than reading books on the topic, is best summed up in a quote by Kent Beck[^2] (which I traced down to [a 2012 tweet of his](https://twitter.com/KentBeck/status/250733358307500032?lang=hr)){:target="_blank"}: "*for each desired change, make the change easy (warning: this may be hard), then make the easy change*"

You know how when you're in a hurry you're tempted to just hack something quick to get it working even though you know it's not good?

Instead, start by refactoring to make the change easy. This will help you identify what made the previous version of the code less maintainable. Keep doing that and you'll start to notice **patterns**, things you've seen before. Intuition is just distilled experience and I have found the deliberate nature of this approach to be great at speeding up the distillation for the intuition of recognizing code smells.

Refactoring guides you to uncover tradeoffs, making it more effective for learning than simply asking yourself why this code is hard to work with. Every time you refactor and then implement a feature you get a definite answer if your *smell detection* was correct. Finding out when your intuition was off is key.

And then you keep doing that year after year...

## Footnotes

[^1]: Also known as the [boy scout rule](https://wiki.c2.com/?BoyScoutRule){:target="_blank"}.
[^2]: In general I like Kent's work, as evidenced by my [review of "Tidy first"](/articles/book-review-tidy-first).
