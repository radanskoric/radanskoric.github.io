---
layout: post
title: "Rails is better low code than low code"
date: 2024-11-26
categories: articles
tags: rails low-code opinion
---

"We need a very simple CRUD app for managing the reservations." **They**[^1] said. "Don't spend too much time on it." **They** added.

My thoughts are racing: "Hm, I am very good with Ruby on Rails, this seems like a good fit. But then I've also used these low code tools before, they are supposed to be the perfect solution for stuff like this. What should I use here ... ". In that very moment, *and only for the duration of this article*, I gain the ability to project my thoughts into the future down the timelines caused by both choices. Someone whispers "Lisan Al Gaib"[^2] but I ignore it.

Both arcs unfold before me in parallel ...

## Beginning: The prototype

I talk to **them** about the requirements. As they promised, the requirements really are simple. This really shouldn't take long.

### Timeline: Low code

I click around, this tool has everything I need, there's even a template that's almost exactly what I need. I start with the template, and click around to customise it further. In a few hours I have what they need. Another click and its live. Great, I'm done before lunch.

### Timeline: Ruby On Rails

I start by running the [scaffold generator](https://guides.rubyonrails.org/generators.html){:target="_blank"} a few times to get all the necessary models. Then I modify the code to make it use [Turbo](https://turbo.hotwired.dev/){:target="_blank"}.[^3] I combine the generated forms to get the basic functionality I need. I also update the generated tests and make sure they are green. I run the [authentication generator](https://rubyonrails.org/2024/9/27/rails-8-beta1-no-paas-required#generating-the-authentication-basics){:target="_blank"} and deploy to my server with [Kamal](https://kamal-deploy.org/){:target="_blank"} . The day is at an end but I have the site working and live.

## Rising action: The additional features

For the next few days, **they** ask for some additional features. As expected, when they started using my quick prototype, they realised that they initially forgot some additional features they need. Thankfully it's all predictable CRUD stuff.

### Timeline: Low code

The low-code platform creators anticipated these features, it's all there in the tool. Most of the features are either just a configuration change or a few simple clicks to add a few more built in components.

One features looks like it should be simple but I can't figure out how to get it working. I can get something similar but not quite what I need. Neither the docs, nor search, nor AI is giving a useful answer. Thankfully, an experienced user on the community forums tells me how I can get it working with a custom lambda function. Unfortunately I accidentally break another feature while trying to get that one working. I don't notice it until I put it live and a user complains. I don't have much in terms of automated tests. I start carefully manually testing the key parts after every change.

All in all the changes were pretty quick but I'm a bit nervous putting them live, unsure if I missed something.

### Timeline: Ruby On Rails

All of the features require some extra coding but Rails and Ruby are pretty good at compressing complexity and it's not a lot of code. I'm updating the tests as I go along which keeps me confident that everything is working as expected.

All of the changes require some custom code so it's taking a little bit longer than just turning on an option in settings but I'm never stuck. I have full control of the application. For some of the features I have a choice between custom code and pulling in a new gem dependency. I don't dwell too much on it, knowing that I can change my mind and refactor it down the line if I see I made a mistake. I'm also using version control so I can easily go back to a previous version of the application.

Along the way I also refactor and cleanup the existing code so every new change is actually turning out easier to add. I am able to make the application fit my problem domain.

## Climax: The unique feature

Oh no, **they** came up with a creative new feature that is unlike anything used in any other reservations app. It's very clever, nothing I've seen before.

### Timeline: Low code

Since it's a new idea, it's not anything that the creators of the platform have thought of so I'm struggling to get it working. It's requiring a lot of hacking around the assumptions of the platform.

Finally I do get something working with several custom lambda functions and using some of the platform features in a way that I doubt fit in the intended usage. I write up a document explaining in details how it all works as I'm afraid I'll forget it myself in a few weeks.

### Timeline: Ruby On Rails

I iterate on the solution until I'm happy. The Rails defaults get in the way a few times but I turn off the Rails defaults in the key places and replace with my custom code. I keep the code clean and well tested and in the end refactor it to keep it easy to understand and maintain.

Most of my application is still simple Rails code, but this one part is custom.

## Resolution: The SaaS pivot

*Unfortunately*, the new feature was so well received and is increasing engagement so much that **they've** decided to spin this off from an internal product into a public SaaS.

### Timeline: Low code

I start preparing the presentation on why we should rewrite the project from scratch using an open source web development framework.

### Timeline: Ruby On Rails

I sit down and start exploring which of the usual options for adding multi tenancy will work the best. The rest of the application doesn't need change, it's already production ready. This might turn out to be a fun project after all ...

## Narrator: But why is this the case?

It's easy to plan a project if we have certainty about the future. If you know all of the requirements in advance you can prepare for it. Unfortunately, it's very rare that you have this certainty. Next best after certainty, is having lots of future options.

And this is the crux of the problem. Low code system have low optionality because:
1. They are usually closed system.
2. They are made less general so that they can solve certain cases really well.

Rails is also less general, although not as much. But even so, because it's an open system, we can peel away the layers when the specialization doesn't fit our problem. And we can do that only in a part of our app.

Rails projects provide more future flexibility. This makes them more valuable under uncertainty.

You can say that this is true for any open source web framework. And you're right. But with 20 years of evolution driven largely by the aim for compression of complexity I believe that Rails is currently the best option for rapid development. This is why it can go head to head with low code for early development and leave all the options on the table.

If you're replacing an internal system that hasn't changed in years then yes, low code is probably a good idea. If there's any chance of innovation inside the application then not so much.

Also, if you're not a programmer, then absolutely, low code is great. But if you're reading this article, you're probably a programmer. So, why are you even thinking about it? Just `rails new`.

## Footnotes

[^1]: They are the stakeholders or the boss or maybe yourself. Whoever is asking for this application.
[^2]: [https://www.youtube.com/watch?v=JCAGE5OOz3A](https://www.youtube.com/watch?v=JCAGE5OOz3A){:target="_blank"}
[^3]: When I'm done I remember I could have just used [Hot Glue](https://github.com/hot-glue-for-rails/hot-glue){:target="_blank"}. I should keep that in mind for next time.
