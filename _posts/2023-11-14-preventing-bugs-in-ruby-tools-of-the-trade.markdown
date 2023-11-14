---
layout: post
title:  "Preventing bugs in Ruby: tools of the trade"
date:   2023-11-14
categories: articles
tags: ruby preventing-bugs tools libraries correctness
---

## Intro

> Bugs are an inevitable part of complex software and aiming for complete bug-free perfection is not only unrealistic, but it hinders progress and product delivery. _David Heinemeier Hansson, creator of Ruby on Rails_

> Ruby is optimised for programmer happiness. _Yukihiro Matsumoto, creator of Ruby_

I completely agree with both of the above statements, but still my personal happiness takes a little hit when I realise I shipped a bug to production. When I was younger I would get personally upset. I would feel like _I personally messed up_. Now I'm much more experienced and wiser and I realise that yes, _I definitely messed up_. The key difference is in what I think I messed up. Experience has changed it from "I am stupid" to "I have a gap somewhere in the systems I am using to prevent bugs". The difference is significant. Former is an unchangeable personal trait while the latter is a process of continuous systemic improvement and a normal part of software development. I will definitely make mistakes but I can also help my future self make less mistakes.

When facing a new or an existing project and thinking about how to prevent defects, I find it useful to remind myself of all the things we have at our disposal to do so. This article is not intended as a comprehensive list of _all possible_ tools. An article would be a bad medium for that, and besides we have [the Ruby Toolbox](https://www.ruby-toolbox.com/){:target="_blank"}. This is an **opinionated** list of tools that I have found useful, placed here for easy reference and shared in the hope that others will find it useful.

## Automated tests

Number one on the list are all things related to automated tests. There used to be a time, long ago, when this would have been controversial. Today, the benefit of automated testing has been proven and is generally accepted. The Ruby community has embraced it especially strongly.

### Testing frameworks
- [Minitest](https://github.com/minitest/minitest){:target="_blank"}: The default testing framework that comes bundled with Ruby since version 1.9. Has two styles, one that resembles Test::Unit and one that resembles RSpec. It boasts very high speed of test execution.
- [RSpec](https://rspec.info/){:target="_blank"} - Framework of choice for many Ruby developers. It takes Ruby expressiveness to the maximum by employing a carefully designed DSL that aims to make tests easy to read.
- [Test::Unit](https://test-unit.github.io/){:target="_blank"} - Used to be the default testing framework in Ruby 1.8 and in Rails but it has since been replaced by Minitest. Ruby 1.9 made the change and added a bridging layer to keep backwards compatibility. A minimalist framework with a clean interface. It's development slowed since the switch to Minitest but it is still actively developed.
- [Capybara](https://github.com/teamcapybara/capybara){:target="_blank"}: Headless browser testing, supporting many different runners with many useful matchers.
- [Cucumber](https://cucumber.io/){:target="_blank"}: Highly expressive DSL that aims to read like regular english defining a feature specification.

These are the main testing frameworks. The full list is long, if you're interested, [Ruby Toolbox has the full list](https://www.ruby-toolbox.com/categories/testing_frameworks){:target="_blank"}.

### Supportive tooling
Testing frameworks mentioned above come with many extensions that are made for them in particular that extend its testing toolset. However, there are also tools which are orthogonal to the choice of a testing framework and contribute to ensuring they are used effectively, mainly around test coverage:

- [Simplecov](https://github.com/simplecov-ruby/simplecov){:target="_blank"}: the most popular code coverage tool. Use it to ensure your tests are exhaustive and are actually testing what you expect them to be testing. If you don't yet have code coverage setup, you will not go wrong with Simplecov. If you are looking for something different, [Ruby Toolbox again has you covered](https://www.ruby-toolbox.com/categories/code_coverage){:target="_blank"}.
- [Mutant](https://github.com/mbj/mutant){:target="_blank"}: Mutation testing. It mutates your code and runs the tests to see if it caught the mutation. If it didn't, the code is either not needed or the tests need improvement.

## Static analysis

Due to its highly dynamic nature Ruby doesn't lend itself as well to static analysis as some other languages but that hasn't stopped people from creating very useful static analysis tools.

### Linters
- [Rubocop](https://rubocop.org/){:target="_blank"}: Rubocop is mostly know as a style enforcing tool, but in its battery of checks also has [a number of linters](https://docs.rubocop.org/rubocop/1.57/cops.html#department-lint){:target="_blank"} which can catch certain kinds of bugs as well as [cops which will warn of potential security issues](https://docs.rubocop.org/rubocop/1.57/cops.html#department-security){:target="_blank"}.
- [Brakeman](https://brakemanscanner.org/){:target="_blank"}: This long standing project runs a number of static checks specifically designed to catch security errors in Rails projects.
- [Dawnscanner](https://github.com/thesp0nge/dawnscanner){:target="_blank"}: Another security focused scanner which will inspect the gems and the framework you are using and then run the appropriate subset of its many checks.

### Gradual typing systems
I wondered if these should be a separate section due to how much attention they received in recent years but semantically they do fall under Static Analysis tools. If you think they are more important, you'll be happy to hear that I wrote an [article dedicated to them](/articles/should-i-add-typing-to-my-ruby-project).

- [Sorbet](https://sorbet.org/){:target="_blank"}: Built at Stripe and adopted by others, most notably, Shopify, is a ruby type annotation system and checker. It has an [online playground](https://sorbet.run/){:target="_blank"} if you want to try it out.
- [RBS](https://github.com/ruby/rbs){:target="_blank"}: A type annotation standard endorsed by Ruby Core team, It's not a checker which is why I am also listing type checkers that work with it.
  - [Steep](https://github.com/soutaro/steep){:target="_blank"}: Developed by the Ruby Core team member that also designed RBS, it's the most mature type checker for RBS, as of the time of this writing.
  - [TypeProf](https://rubygems.org/gems/typeprof){:target="_blank"}: A new, still in development, type checker for RBS, developed by the core team. It has an [online playground](https://mame.github.io/typeprof-playground/){:target="_blank"} if you want to try it out.

## Live tools

Due to how dynamic Ruby is, sometimes the best way to ensure we don't ship any defects is to defend ourselves at runtime. Embrace that we will miss bugs in development and focus on the second line of defence: _preventing the user from noticing_.

- Bug tracker tools: A quick google will reveal many excellent tools and I won't attempt to compare them. The important thing is picking one and using it. The next best thing after preventing a bug is _fixing it quickly_.
- [Scientist](https://github.com/github/scientist){:target="_blank"}: A very useful gem from Github for larger refactoring. It makes it easy to deploy two codepaths side by side and effectively verify the correctness of the new codepath by comparing its results in production with the old codepath.
- [Mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler){:target="_blank"}: Bad performance can also looks just like a bug to the user. There are many tools for diagnosing and fixing such issues but, quite often, mini-profiler is the first one I reach for.

## Clean code
We're now getting into the part of the list where I'm not covering hard core tools. First is: _clean and well organised code_.

The power of Ruby is very much in how expressive and readable it can be. Matz and the core team have worked hard on ensuring that Ruby puts the programmer at the centre of its design. It would be foolish not to use that. Code that is clean and easy to understand is also code where it is easier to notice issues.

### Libraries
- [Rubocop](https://rubocop.org/){:target="_blank"}: The dominant style checker has a huge battery of checks you can configure. More important than the exact style you choose is to apply it consistently on the entire codebase. A consistent style means that you can spend your brain cycles understanding the logic of the code rather than its style. This leads to fewer defects. Perhaps even more importantly it has [a list of Metrics cops](https://docs.rubocop.org/rubocop/1.57/cops.html#department-metrics){:target="_blank"} that aim to reduce the complexity of the code. Lower complexity leads to less bugs.
- [Standard](https://github.com/standardrb/standard){:target="_blank"}: This gem is built on top of Rubocop but takes it further. It picks a single style that is not up for debate. The idea is that it removes all style conversations so you can focus on the functionality.

### Books and blogs

Number of books and blogs that offer great advice for writing clean Ruby code is too large to list and it wouldn't be fair to pick one as the top resource. Except, this is my post and I would like to share one author that I keep coming back to over and over: [Sandi Metz](https://sandimetz.com/){:target="_blank"} and specifically her books. So here, that is my reading recommendation if you haven't read her books before.

The list of good books and authors writting about good code is, of course, much larger. Almost all of it will be useful if you read it with a critical mind considering the _unspoken assumptions_ that the author is making.

### Development processes

How you develop code has as much effect as the technical setup. After all, software is made by humans (and despite the advances in AI, I fully expect it to stay that way for a long time, but that's a whole different topic).

Some things that I have found to consistently reduce defects:
- Code review: Whether code needs to be reviewed before it's deployed or you're practicing batched post-reviews, either way, it's pretty clear that having another developer think through your changes reduces defects.
- Pair programming: Long a [key practice of Extreme Programming](https://wiki.c2.com/?PairProgramming){:target="_blank"}, it reduces defects in the code by having two people actively collaborate on its creation.
- QA processes: Having a solid QA process that takes testing plans into account from the start of the development process can have a massive impact at both the overall quality of the product as well as its defect rate.

## Sleeping well

Maybe you think that I am joking now? :)

I am _100% serious_. The science is clear: sleep deprivation has a very negative effect on cognitive functions. A well rested developer that is getting enough sleep every night is a developer functioning at full capacity. This means fewer errors and higher ability to notice existing defects in the code.

I'm even wondering if this has a bigger effect than any of the other categories. Maybe it should be in the first spot in this list. I need to sleep on it, pun intended.

If you don't believe and want to read about the science proving it, instead of me quoting the science, I will recommend that you read a book that covers it extremely well: [Why We Sleep](https://www.goodreads.com/book/show/34466963-why-we-sleep){:target="_blank"} (this is not an affiliate link, I just think that developers should read this book).

## Conclusion
Yes, [software has bugs](https://37signals.com/podcast/software-has-bugs/){:target="_blank"} but we don't have to shrug and accept it. With the right setup and approach to work, we can keep iterating fast and shipping new features without having our users be frustrated by bugs that get in their way.
