---
layout: post
title: "\"Make the change easy, then make the easy change\" is a great way to code with AI"
date: 2026-10-27
categories: articles
tags: new-craft ai-coding refactoring
---

I firmly believe that we still need to read some of the code.[^1] It's suboptimal to read all of the code, but I consider it irresponsible to read none of it. I won't explain why now because that would fill several more articles. I just want to share this upfront because it clarifies where I'm coming from.

But I am trying to be smart about it[^2], and I've found the quote in the title very useful: *"Make the change easy, then make the easy change"*.

## Separate refactoring from new behaviour

This has been the best way to add a new feature since long before AI coding agents. It naturally leads to a more maintainable codebase in two very powerful ways:

1. Making the next change easy forces us to rethink current abstractions.
2. It then immediately tests the new abstraction with the next real change.

The purest way to do it when adding a feature is a clean two-step move:

1. A **pure refactoring**, i.e. a refactoring that makes absolutely no changes to the program's behaviour.
2. A **pure addition**, i.e. adding a new feature without changing any of the code powering old features.

That second step is an ideal, not a rule, especially if you're modifying an existing feature. The goal is to **make the behaviour change simple and as isolated as possible from the old code**.

[Kent Beck](https://kentbeck.com/){:target="_blank"} coined the phrase, and the full quote is slightly longer:

> Make the change easy (this might be hard), then make the easy change.

The part in brackets is why I used to hesitate to do it unless the change was important enough. I knew it was the right thing to do, but I had to be pragmatic with my time.

## Freeze behaviour before refactoring

However, one thing I genuinely enjoy about coding agents is just how good they are at refactoring. They'll tear through the code like a toddler through melting ice-cream. Give them a reliable oracle, and they will even do it cleanly. For a pure refactoring, the current codebase is that oracle: **we want to preserve its observable behaviour**.

I'm still figuring out how best to do this, but here's what's worked well for me. Temporary integration tests are *one way* to freeze that behaviour:

1. Ramp up integration tests on the part of the system you want to refactor. Ramp them up to a crazy amount. Way beyond what would be reasonable. Of course, use AI for it. This is a special case where test quality is less important since you'll remove them after the refactoring. They're not encoding the specification; they're **freezing behaviour**. Forbid the agent from changing a single line in the app code: the goal is to capture existing behaviour. Tests can't capture everything, so it's still up to you to judge if you need additional checks.
2. Freeze those tests and work with the agent on the refactoring. Pay less attention to the code, but keep judging the structure: *preserving behaviour is no excuse for making a mess*. But the **tests now check correctness**, so I can focus on whether the new structure is good.
3. Prompt the agent to make the easy change. This should now be a simple change, making it easy to **read the code**. If it isn't, discard it and go back to step 2 with what you've learned. Another thing I genuinely like about AI is that it's easy to create throwaway code just to learn.
4. Once done, delete the ridiculously detailed temporary tests that no longer earn their keep. They've served their purpose.

This is not the only way to check that we're preserving behaviour. For example, we could run the same inputs through the old and new versions and compare the outputs. The tools for doing this are the part I expect will evolve and change. Experiment with different techniques. *The overall approach is what matters.*

## Focus human review where it matters

That's how this helps me decide what code to read. During the refactoring, I judge the structure and use the **old behaviour** to check correctness. Then I closely read the **new behaviour**, now isolated in a much smaller change.

> For example, when [adding ERB support to the Archspec gem](https://github.com/crmne/archspec/pull/36/commits){:target="_blank"}, I first extracted Ruby source handling behind a common interface. Adding ERB then meant implementing another source reader and registering it. The existing analysis could stay mostly as it was. 
> 
> That gave me two clear places to focus my review: 
> 1. The refactored code's new shape and the source file analyser interface.
> 2. How the new reader turns ERB into analyser input.
{: .prompt-tip }

Freezing the system's behaviour and rearranging the code until I can easily slot in the change is an approach I've found useful for a long time. With agents, it lets me delegate most of the work while keeping the new behaviour simple enough to read carefully. That's where I want to spend my attention.

## Footnotes

[^1]: I still find it deeply ironic that this is a controversial statement in 2026.

[^2]: Using the word "trying" is intentional here: none of us can be sure about anything at this stage. Anyone claiming they have it fully figured out is full of it. I know this is a boringly "cold take" that would never please a social media algorithm, but this is just my blog, so I don't care. And there's no algorithm.
