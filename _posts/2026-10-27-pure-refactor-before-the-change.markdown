---
layout: post
title: "\"Make the change easy, then make the easy change\" is a great way to code with AI"
date: 2026-10-23
categories: articles
tags: new-craft ai-coding
---

I am firmly of the opinion that we still need to read some of the code. [^1] It's suboptimal to read all of the code but I consider it irresponsible to read none of it. I won't now explain why because that would fill another several articles. I just want to share this upfront as a filter for readers.

And I am trying to be smart about it. [^2]

And I've found the quote from the title very useful: *"Make the change easy, then make the easy change"* 

For a long time, long before AI coding agents I've found it to be the best way to add a new feature. It naturally leads to a more maintainable codebase in 2 very powerful ways:
1. Making the next change easy forces us to rethink current abstractions.
2. It then immediately tests the new abstraction with the next real change.

The purest way to do it is a clean 2 step move:
1. A **pure refactoring**, i.e. a refactoring that makes absolutely no changes to the behaviour of the program.
2. A **pure addition**, i.e. a new feature is added without changing any of the code powering old features.

The phrase, one my favourite, was coined by Kent Beck and the full quote is slightly longer:

> Make the change easy (this might be hard), then make the easy change.

This part in the brackets is the reason why in the past I would hesitate to do it unless the change is important enough. I knew it was the right thing to do but I had to be pragmatic with my time.

However, one of the few aspects of coding agents that I genuinely enjoy is just how good they are at refactoring. They will rewrite arbitrary amounts of code and if you can provide a reliable oracle, they will even do it reliably. Thankfully, every pure refactoring has a perfect oracle: the current codebase. 

I'm still figuring out how to best leverage it but here's what's worked well for me:
1. Ramp up integrations tests on the part of the system I want to refactor. Like ramp it up to a crazy amount. Way beyond what would be reasonable. The point is to freeze observable outside behaviour. This would be a waste of time before but with agents its fine. Forbid them from changing a single line in the app code, the goal is to capture existing behaviour.
2. Now freeze the integration tests and work on the refactoring to make the change easy. You drive the changes together with the agent, in the usual way you work with agents. However, you can move a lot of faster because you have the oracle of the old code frozen in the tests. For the same reason you can get away with not reading the code carefully. Glancing the structure is usually enough.
3. Now prompt the agent to make the easy change, i.e. add the new feature. Because of all the work you did in the refactoring, this should be a simple change that's easy to review. If that's not true, discard it and go back to step 2 with the new learnings. 
4. Repeat steps 2 and 3 until you get to a point where 2 is a **pure refactoring** and 3 is a simple change for which it's easy to **read the code**. Doing so many repetitions would be infeasible before, but another thing I genuinely like about AI is that it's easy to create throwaway code just to learn.
5. Delete those ridiculously over detailed integration test you added in step 1. They've done their purpose.

The main idea is simple:
1. The bulk of the code is the refactoring and the source of truth for its correctness is the **old code** as oracle.
2. And then this makes the new change simpler, making it easier for **you** to review.

## Footnotes

[^1]: I still find it deeply ironic that this is a controversial statement in 2026.

[^2]: Using the word "trying" is intentional here: none of us can be sure about anything at this stage. Anyone claiming they have it fully figured out is full of it. I know this is a boringly "cold take" that would never please a social media algorithm, but this is just my blog so there's no algorithm.
