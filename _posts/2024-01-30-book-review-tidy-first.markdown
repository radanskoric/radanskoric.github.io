---
layout: post
title: "Book review: \"Tidy first?\" by Kent Beck"
date: 2024-01-30
categories: articles
tags: book review refactoring agile
---

![The best coworker in the world helping me write the review](/assets/img/posts/reading-tidy-first.jpg){: width="503" height="579" .right.floating-image}

I read the book ["Tidy First?"](https://www.oreilly.com/library/view/tidy-first/9781098151232/){:target="\_blank"} by Kent Beck and it got me thinking in ways both enjoyable and productive. I'm approaching it from the position of an experienced Ruby developer, because that is my primary professional background. Spoiler alert: the review is positive with just one real criticism.

*This is not an affiliate link and I receive nothing if you buy the book other than personal satisfaction for helping spread the word about a book that deserves it.*

## Book overview

> "I have to change this code, but it's messy. What should I do first?" _Kent Beck_

This is the full question from the book title and what the book unpacks in great detail.

The book is divided into 3 parts: **Tidyings**, **Managing** and **Theory**. Each chapter is very short and the whole book can easily be read in an afternoon. This I consider its great strength. It takes a lot of work and knowledge to convey ideas in fewer words.

### Part I: Tidyings

The first part is very specific, it covers ways in which a piece of code can be made clearer and more maintainable, or as Kent puts it: **"tidier"**. If you are already an experienced programmer you might be taken back by how simple each **"tidying"** is. It's very likely you're already practicing most of it. Some of the advice is even just a rule in a linter like Rubocop. The others describe a simple refactoring, the kind that might take a few minutes on its own or as part of a larger refactoring.

Personally, I've been aware and have used all of the advice already in one way or the other, yet I still gathered significant value in 3 ways:
1. I re-evaluated the usefulness of these techniques: e.g., I do order things for easier reading but not always. It made me appreciate its value more so I've started doing it more often.
2. I better understand how to get the most out of techniques: e.g. I've unrolled functions when trying to understand how a library works but I've not used the unrolling as an intermediate step in refactoring my own code. There's a one page chapter that explains the benefit vividly.
3. Last but not least, Kent did a better job explaining their value than I could. I can reuse his words when explaining the value to someone else.

If even *just one* of these little tidyings wasn't familiar to you before, that alone will make the book worth reading.

### Part II: Managing

This part tackles the question of when and how to do the tidyings.

At your workplace you might see this problem manifest by someone saying some variation of: *"Yes, we should definitely do that but not now."* If you were the one wanting to do the technical cleanup, you were probably frustrated by that answer not actually specifying *when* you will do it.

Kent unpacks that question beautifully and gives you tactics for doing it in a way that works with and not against the rest of your development process.

### Part III: Theory

This part builds a theory and a mental framework for thinking of the tradeoffs inherent in software design and around software quality.

This part had me frequently stopping to think about what I just read and how I would apply it. The way in which he builds a bridge between software development and financial theory is especially illuminating. It would be foolish to attempt to summarise it here as it's already very concise in the book but I'll just tell you that it gave me a whole new way of deciding how flexible should my software design be in any given case. For me that insight was the biggest value I got from the book. I expect it to pay off massively on the next inflection point of any project I work on.

This is also the part to which I expect to return most often. In fact, for example, while writing this I paused to re-read chapter 30.
## Who is it for?

The explanations are high level but rooted in real life experience. Without the relevant experience it's much harder to understand the explanation. That is why I believe that a junior developer would not get much value from the book.

That's mainly because it is light on concrete examples. Some of the tidyings, but not all, have short code examples. However, concrete examples are almost completely lacking in later parts. It is understandable as those chapters are talking more about the development process and tradeoffs you are making than the code itself. It is very hard to create examples for that. If you have personal experience of problems Kent talks about, you will have no problem pulling them from memory, the abstract descriptions are clear and well written. That was the case for me. In later chapters I found myself often putting the book down and recalling an experience from my professional development career.

If you lack those experiences the value of the book would be greatly increased by an addition of case studies illustrating real world applications of the advice. This is perhaps the only real criticism of an otherwise excellent book.

However this brings me to a setting where this short coming disappears and where I think the book delivers maximal value:
### Book clubs

If your company has an internal book club I think "Tidy First?" would be a great fit. The shortcoming I mentioned above is likely to disappear with other readers sharing their experiences as comments on the book.

If I was using it on a book club I’d have everyone read the first section, discuss it whole at one session. It’s pretty straightforward, and it's unlikely to be controversial. Some people can share examples if they've used one of the tidyings recently.

Now, later chapters can each spawn a very productive discussion and they’re short enough to even just read at the beginning of the book club session. Make sure to use it for reflection on the problems your are facing on your own projects and this way I am confident you will get very high value out of the exercise.

Happy reading! :)
