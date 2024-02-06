---
layout: post
title: "Avoid most of the pain with test factories by adopting one fundamental principle"
date: 2024-02-06
categories: articles
tags: testing factories principles maintainability ruby
---

[Test factories](https://thoughtbot.com/blog/why-factories){:target="\_blank"} are a widely used tool for writing automated tests. The other main alternative are [test fixtures](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures){:target="\_blank"} but here I am assuming you are using factories. I have extensively used both over many years and projects and I found this lesson makes a big difference when using factories.

## The principle of minimal factory defaults

There is one fundamental principle that I have consistently found to be the most valuable in creating factories that stay maintainable and easy to use for years:

> **By default the factory should do just the bare minimum to create a valid object.**
>
> A corollary is that  everything else should go into [traits or nested factories](https://www.codewithjason.com/factory-bot-traits-vs-nested-factories/){:target="\_blank"}.
{: .prompt-tip }

I am not the first one to invent this principle (in fact it was explained to me many years ago by QA engineers I worked with) but I am not aware of a name for it. To make it easier to refer to it I will name it now as **the principle of minimal factory defaults**. Please tell me in the comments if this principle in fact has a specific existing name.

I am using the terminology from [FactoryBot](https://thoughtbot.github.io/factory_bot/){:target="\_blank"}, a widely used Ruby testing factory, and I'll give code examples with it, but the principles are universal and should apply to any test factory in any programming language.

### An example

Imagine you have a Post object in your application. It has: author, title, content and tags. You might be tempted to write a factory for it as:

```ruby
FactoryBot.define do
  factory :post do
    author { build(:user) }
    title { "Title" }
    content { "Lorem ipsum" }
    tags { ["blog", "article"] }
  end
end
```

However, tags are optional, the post doesn't need them to be valid. And let's also imagine that the post can be anonymous, without an author. So according to the principal of minimal factory defaults the factory should look something like this:

```ruby
FactoryBot.define do
  factory :post do
    title { "Title" }
    content { "Lorem ipsum" }

    trait :with_tags do
      tags { ["blog", "article"] }
    end

    trait :with_author do
      author { build(:user) }
    end
  end
end
```

## Common pains and how this fixes them

This is not the only principle you need for good factories but I consider it the most important one because of how many diverse benefits it has.
Let's examine some common pains and how this principle addresses them.

### Unclear test expectations

Assume we have the non minimal factory and consider a test that generates a post as part of its setup:
```ruby
new_post = create(:post)
```
Is it relevant for this test that the post has tags or that it has an author? There is no way for us to tell. There might be a comment explaining it but that's easy to forget. Using test factories with minimal defaults, we have no choice but to be explicit:
```ruby
new_post = create(:post, :with_tags, :with_author)
```
Now we know, here it's clearly relevant that the post has tags and an author.
### Changing the factory breaks unrelated tests

An existing factory doesn't quite work the way you need it for the next test you need to write. You make a small change, your new test works just great. You run all the tests to check for regressions ... 80 failures. You scroll through and a lot of tests are breaking in a similar way. You pick a random one and after 10 mins of understanding why the test broke you realize it's totally unrelated to what the test is actually testing. Which of the other 80 failures are unrelated and which are significant? There's no way for you to know without looking at each one. Time is wasted.

The worst part is that, once the application has grown large enough, **any change to the factory** is very likely to break lots of tests. So what often happens is that at some point no one touches the defaults. They become an unchangeable legacy that everyone works around.

If the factory was doing the minimum by default, that test would not have broken, it would be completely unaffected by your change. And any change to the defaults, by definition, is relevant for all tests.

### Changing the test breaks in a weird way

Related is a case where you modify an old test in a way that looks valid to you but then it breaks with a totally unexpected error. Once you dig in you notice that the test is relying on a specific setup in the factory that you were not aware of and definitely didn't realize is a significant part of the test setup.

Everything being explicit makes it very clear what the setup actually does.

### Factories that are hard to use

You are setting up a new test case. However, the factory makes many assumptions about what their consumers need and they don't match your current situation. *It just doesn't work for your test*. You either have to make heavy manual modifications *after* running the factory, or write a fresh *new* factory. It's hard to tell which is worse.

Minimal defaults and a rich set of traits make it easier to use exactly what you need and then add just the part unique to your test. Expanding the options in a factory is also straightforward, you just need to make an alternative version of an existing trait.

### Slow tests

One of the big arguments for using fixtures instead of factories is that factories can become very slow, especially using the default approach of having factories actually create the record in the database. For most test suites, the slowest part is interaction with the database.

Non minimal factories do more than the minimum needed for the test setup. Less setup means less database interaction which in turns makes the test suite faster.

This is not the full solution to the speed problem but it is a significant part of it.

> If this is useful, consider subscribing to receive more focused, advanced content:
> <script async data-uid="eee193b17b" src="https://thoughtful-producer-2834.ck.page/eee193b17b/index.js"></script>
{: .prompt-info}

## How to implement the principle

There's no easy way to automate enforcing this rule. There's no linter for this that I am aware of.

To make things worse, when you're just creating the factory, not following this principle is actually easier. After all, you have just one test using it and *you know exactly what you need*. Once there's enough factories like that the inertia is taking you further in that direction. It takes a *real effort* to turn it around.

**This has to be part of the team culture.** The team needs to be on board with the value of the principle.

The good news, in my experience, is that once most of your factories are built like this, the inertia starts working in your favour. Anyone expanding the factory will see there are lots of specific traits and is very likely to stick to the pattern. When adding a new factory they will probably have a look at an existing factory.

And just like that, the flywheel is spinning in your favour.
