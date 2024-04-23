---
layout: post
title: "Not understanding the motivation behind best practices dooms you to misuse them"
date: 2024-04-23
categories: articles
tags: software engineering meta thoughts
---

## The point

[Best practices](https://en.wikipedia.org/wiki/Best_practice){:target="_blank"} earn their name by being used with success by many people in many different situations. Over many attempts, on **average**, they worked better than other practices. Hence the name.

Someone tries something. It works great. They tell others. They try it and for most of them it again works great. Good, we have a new best practice, the industry moves forward.

Usually. Sometimes, the marketing, either intentional or accidental, overpowers the actual experience. Remember when brain teasers were considered the best way to interview programmers? It happens most often when expected benefit is hard or impossible to measure and we fall back to convincing each other it's good.

And sometimes, a practice that has genuinely earned its "best" adjective falls out of favour because it's misused. Again, difficulty of measurement plays a role in how long it continues to be misused. The longer it goes on being misused, the worse the disappointment.

And at the root of it, you'll often find well meaning people that understood **how** to apply the practice but failed to understand **why** it's considered "best". Each practice started as a specific solution to a specific problem. It got refined over many iterations of people applying it to their specific problems, usually similar to the original one. **The problem** being solved was the **motivation** behind the invention of the practice.

Failing to understand the motivation will doom you to misuse it in two ways:
1. You will apply it to the wrong problem. *Trying to screw in a nail will not get you far but the problem is not in the screwdriver.*
2. You will try to adapt it to your situation and you'll make it worse. *You flip the screwdriver over and start banging the nail with the handle. It kind of works, but it's hard work and the handle eventually breaks. The problem is still not in the screwdriver.*

  *And you have a perfectly good box of screws you could have used instead of the nails.*

At this point you might be thinking: "Radan, this is all extremely obvious, this is a useless article?" I'm not saying you're wrong, but *if this was so universally understood*, it wouldn't be so easy to find examples of this being violated across the software industry, across various levels of software development.

## Examples

### Not understanding small methods is about complexity compression leads to hard caps on method lengths

Shorter methods are easier to understand and lead to cleaner abstractions. So, a lot of linters have rules to limit the length of a method. Hitting this limit is usually a little bit annoying, especially if you think your method is of good length. Do you disable the rule or raise the limit?

Understanding that the value of the practice comes from compressing complexity makes it clear that:
1. Disabling it in cases where the complexity is not increased by longer source code is within the practice.
2. The linter rule is a reminder for the practice, not the actual practice.

And then it becomes clear that increasing the limit in the linter is the wrong adaptation. Instead, keep the limit but be quick to disable it when it makes sense.

### Not understanding DRY is about enabling changes leads to bad abstractions

[DRY (Don't repeat yourself)](https://wiki.c2.com/?DontRepeatYourself){:target="_blank"} tells us to extract away repeated code. The **motivation** is to lower the cost of future changes. It's not to save keystrokes.

The common failure of misunderstanding this is to DRY code that **looks the same** but **does not serve the same purpose**. So you end up with the same piece of code serving two purposes. And then any changes lead to more work down the line, not less. For example, this is very common with HTML view templates as we use the same UX patterns for different functionalities.

### Not understanding micro-services leads to using them everywhere

Most [micro-services](https://martinfowler.com/articles/microservices.html){:target="_blank"} success stories have a number of common traits: *a bounded context loosely coupled to the rest of the system owned by a team needing to iterate on it faster than the main project*. I'm simplifying *a bit* and glossing over infrastructure scaling aspects, but for every part of that sentence you can find microservice failure modes:
- ignore *"bounded context"* and get a microservice with a confusing, hard to use interface
- ignore *"loosely coupled"* and get a microservice that cannot be deployed on its own
- ignore *"owned by a team"* and get an unmaintained microservice that's a liability
- ignore *"needing to iterate faster"* and pay the maintenance overhead without the ability to reap the benefits

If you ignore the motivation that lead to the success stories, don't be surprised if you can't replicate the success.

### Not understanding the Agile manifesto leads to modern Agile

Failing to understand (or just wilfully forgetting) that the Agile manifesto was first and foremost about **delivering high quality software effectively**, organisations focus just on the mechanics of agile practices and then proceed to adapt them to their own situation. In the process we get ... well ... most of the modern Agile, all the stuff that gives it a bad reputation.

The failure is in trying to solve management problems with practices born out of development problems. No wonder the adaption of agile practices went wrong in so many cases.

## Why this is even more relevant in the age of AI

The Large Language Models are insanely amazing next token predictors. They don't seem to "understand" even the motivation behind that next token being the best choice, let alone the motivation behind the full answer. This matches my experience of using coding assistants, as useful as they are.

And this is why it is so important that you do understand it. It's a small but crucial piece of making you indispensable as a software engineer in the age of LLMs.

## Conclusion

Next time you are applying a practice, pause for a moment and ask yourself if you understand the motivation behind it and if it really fits your current problem. If you're not sure, discuss it with someone. Don't rush it, this is high leverage work.

