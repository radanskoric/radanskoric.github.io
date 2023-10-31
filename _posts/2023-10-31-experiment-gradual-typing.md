---
layout: post
title:  "Experiment: Fully adding Sorbet and RBS to a small project"
date:   2023-10-31
categories: experiments
tags: ruby types static-analysis sorbet rbs correctness
---

_I used statically typed languages and liked the extra safety but I also really like Ruby for how elegant it is and the freedom it gives me. Will I regret adopting types?_

## TL:DR;

To get a better understanding of the value of gradual typing in Ruby projects I picked a small completely finished side project and did 3 experiments:
1. Adding Sorbet at strict level to all files without metaprogramming.
2. Adding RBS annotations to all files and Running Steep on strict setting.
3. Adding Simplecov and raising line and branch test coverage to maximum.

Here is what I learned:
- Both Sorbet and RBS found the same two bugs with RBS uncovering one extra small issue.
- Raising test coverage to maximum uncovered more bugs and more small issues than typing, including both bugs that gradual typing found.
- Sorbet feels like a more polished project, probably becasue some of the largest Ruby companies are using it. This is most noticeable in its excellent documentation.
- Both typing approaches were most painful around the (relatively light) meta-programming used in the project. Raising test coverage with Simplecov unsurprisingly had no issues there.

For this project I would conclude that **raising test coverage** is the most worthwhile investment followed by adopting Sorbet but only at the `typed: true` level. Read below for more details.

> I absolutely do not consider this a definite verdict on the typing question. It is **one data point** that I found very educational and useful but you should always take it for what it is: **one experiment, one data point**. It will give you most value if you use it as an inspiration for **running an experiment on your own project** and comparing with my findings.
{: .prompt-warning }

My next article will be digging deeper into how to decide if you should adopt gradual typing in your project. Subscribe to not miss it:
<script async data-uid="e83d1aa837" src="https://thoughtful-producer-2834.ck.page/e83d1aa837/index.js"></script>

## Background

It all started when I asked myself: _Should I adopt gradual typing in my Ruby projects?_

We are seeing an ongoing investment in gradual typing for Ruby by [Sorbet team](https://sorbet.org/){:target="_blank"} as well as [the core team adopting RBS](https://github.com/ruby/rbs){:target="_blank"}. Large companies that adopted one of these approaches claim great gains but the community at large isn't eagerly adopting it. _What is going on?_

To better understand Ruby gradual typing I decided to do an exercise. I took a small side-project (1.2k lines of Ruby) and **covered it completely** with both Sorbet and RBS annotations. The project is a vanilla (non-Rails) Ruby project: an implementation of the first part of the excellent [Crafting Intepreters](https://craftinginterpreters.com/a-tree-walk-interpreter.html){:target="_blank"} book. I recently finished it and [the repo with the code is here](https://github.com/radanskoric/ruby_lox){:target="_blank"}. I chose it because, as it's a full language interpreter, it has a lot of data being processed, transformed and flowing through the entire codebase. *Intuitively, I expect this kind of project to benefit from typing.* Also, as a side-project, I'm done with it, meaning there will be no changes on it between trying both options. Along the way I tracked what issues were uncovered by either approach.

## Experiments

### Sorbet
I am assuming you are already somewhat familiar with Sorbet and maybe even tried adding it to your codebase. If you aren't, [the official docs](https://sorbet.org/docs/overview){:target="_blank"} are a great place to get familiar with it.

The only thing you need to know to understand how I ran the experiment is that Sorbet supports multiple levels of strictness that can be set per file (via a special code comment) and in the experiment I am using:
- `typed: false` - Only syntax checks, const resolution and signature validations are performed.
- `typed: true` - This is the level that starts performing actual type checks, signatures are optional.
- `typed: strict` - All methods must have signatures.

#### Results
The full writeup of the bugs I found is [in the project, on the sorbet branch](https://github.com/radanskoric/ruby_lox/blob/sorbet/BUGS_FOUND.md){:target="_blank"}.

**In short:** running it at the lowest level, `false`, found one bug and raising it to the `true` level found another bug. Raising to the `strict` level didn't find any additional bugs.

Notes from the Sorbet experiment:
- The Sorbet documentation is excellent, comprehensive and easy to follow. I wouldn't be surprised if Stripe has a dedicated technical writer improving it to increase adoption in the community.
- Going from level `true` to level `strict` took a lot of effort. In contrast, it was quite easy to get to `true`.
- Sorbet had a lot of problems with relatively light meta-programming. For example, [I declare several classes](https://github.com/radanskoric/ruby_lox/blob/sorbet/lib/ruby_lox/expressions.rb){:target="_blank"} using `Struct` and define a few methods dynamically on all of them. Nothing exotic for Ruby. However, Sorbet can't make sense of it. The choices are to either rewrite using [Sorbet's typed struct](https://sorbet.org/docs/tstruct){:target="_blank"} or define all of the methods unrolled in an [RBI file](https://sorbet.org/docs/rbi){:target="_blank"}. From what I gathered this is expected. To make the most out of Sorbet, it's better to reduce the meta-programming.
- Signatures look like valid Ruby but they're not exactly Ruby. They're parsed and evaluated by Sorbet slightly differently and are actually a subset of full Ruby syntax. For example, [I wanted to define an alias for a collection of classes](https://github.com/radanskoric/ruby_lox/blob/sorbet/lib/ruby_lox/expressions.rb#L23-L28){:target="_blank"} and since I needed the list in two places I put it in an array and wanted to [splat](https://thoughtbot.com/blog/ruby-splat-operator){:target="_blank"} it into a Sorbet call. However, even though it looks like a regular Ruby method call, it doesn't support splatting arguments so I had to repeat the list in two places.
- It took me about 1.5 full work days to add Sorbet.

### RBS + Steep
Like with Sorbet, I am assuming you are already somewhat familiar with RBS. If you aren't, [the original blog post by RBS and Steep author](https://developer.squareup.com/blog/the-state-of-ruby-3-typing/){:target="_blank"} is a great place to get started.

The only thing you really need to be aware of to read my results is that RBS is the types annotations language and not a checker. [Steep](https://github.com/soutaro/steep){:target="_blank"} is the type checker developed by the same person working on RBS ([Soutaro Matsumoto](https://github.com/soutaro){:target="_blank"}). Steep can run the checker in a **lenient** or **strict** mode. The lenient mode will not perform all of the checks. The strict mode will find more errors but also demand more changes in the code.

#### Results
The full writeup of the bugs found can be found [in the project, on the rbs branch](https://github.com/radanskoric/ruby_lox/blob/rbs/BUGS_FOUND.md){:target="_blank"}.

**In short:** adding annotation signatures to all files and running the Steep checker in **lenient** mode found no bugs. Bumping it up to **strict** mode and fixing the issues it found the same two bugs found by Sorbet plus it warned me of another minor potential issue in the code.

Notes from the RBS experiment:
- I can't say that RBS documentation is great, at various points I struggled to find a clear explanation of the setup or answers to specific questions. Several times I ended up mentally parsing [the syntax grammar](https://github.com/ruby/rbs/blob/master/docs/syntax.md){:target="_blank"} to figure out the correct syntax.
- Like Sorbet, it also struggled with meta-programming and I was forced [to fully expand my dynamically defined classes](https://github.com/radanskoric/ruby_lox/blob/rbs/sig/ruby_lox/expressions.rbs){:target="_blank"} in the RBS annotations.
- It took me less time to add RBS than Sorbet. RBS took about 1 full work day compared to 1.5 for Sorbet at strict level. This might be just because I was adding all signatures after the code was finished and it was easier to edit RBS files in bulk than Sorbet inline annotations.

### Simplecov

With both of these experiments done, I thought: Hm, what if I just raised the test coverage to maximum? So I did just that. *And boy did that deliver on this project!*

Like with the other tools, I am assuming you are familiar with Simplecov and, if you are not, [the official README](https://github.com/simplecov-ruby/simplecov){:target="_blank"} is a great place to start.

The only thing you need to know to read my report is that it supports both **line** and **branch** coverage. If you turn on branch coverage it will report if all code paths on every branch are tested. For example, imagine that you have an `if` branch without an `else` branch. If you test the case when the condition is `true`, this will give you 100% line coverage because all the lines are executed. However, you could have a bug that manifest when the if block doesn't run and branching coverage will catch that because it will report that the condition being `false` is not tested.

#### Results
The full writeup of the bugs found can be found [in the project, on the main branch](https://github.com/radanskoric/ruby_lox/blob/main/BUGS_FOUND.md){:target="_blank"}.

**In short:** Getting the **line coverage to 100%** caught one minor issues and 3 bugs, including one of the two found by typing. Getting **the branch coverage to maximum** caught the other bug found by typing and one extra minor issue.

Notes from test coverage experiment:
- Raising test coverage found more bugs and more minor issues.
- As you would expect, there were no issues with meta-programming.
- Getting test coverage to maximum took the least time, about half a day. However, I already had a decent test suite in place.

## Conclusion
As I mentioned on the top, you should consider this as one datapoint and not a definitive research into effectiveness of gradual typing systems in Ruby.

The most important lesson is the value of doing a limited scale evaluation on your own project before deciding. And if you do that, you can use my findings here to compare them to yours.

For this particular project the finding is leaning heavily towards **raising test coverage as the main tool for preventing bugs**. I would also consider adding Sorbet at `typed: true` level since it had a good cost/benefit tradeoff.

_Have you run an experiment like this? What was your experience?_ I am most interested in whether the value starts to rapidly increase with very large codebases since I just added this to a small project.
