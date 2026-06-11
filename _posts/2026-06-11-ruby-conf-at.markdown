---
layout: post
title: "RubyConf Austria and the future of Ruby conferences"
date: 2026-06-11
categories: news
tags: ruby conference rubyconf-at
image: /assets/img/posts/rubyconfat/violins.jpg
---

To get from Zagreb, where I live, to Vienna, where RubyConf Austria was happening: drive 173km to Graz, take a right and go for another 198km. Sure, I've glossed over two country borders and some other details, but that's mostly it. It's pretty straightforward, unlike how the conference got me thinking about the future of Ruby conferences.

But I'll get to that.

## Day 1: The Vienna Ruby Meetup

The first day of the conference was actually the Vienna Ruby Meetup, held at Haus der Musik. Right off the bat, this hinted at the conference being a bit different. As part of our conference ticket, we also got tickets to the museum exhibition.

![Vienna used to have tiny violins](/assets/img/posts/rubyconfat/violins.jpg)

As people started gathering, I met some new people and was very happy to meet up with old Ruby friends, some of whom I hadn't seen for years.

The first presentation was an update by [Marco Roth](https://marcoroth.dev/){:target="_blank"} about the [Herb](https://herb-tools.dev/){:target="_blank"} and [ReActionView](https://reactionview.dev/){:target="_blank"} state. I told him this in person, but I'll also reiterate it here publicly: I'm really impressed by his work, as he alone is currently doing the bulk of pushing the Rails front-end story forward.

Next up, [Maedi Prichard](https://maedi.com/){:target="_blank"} introduced [Raindeer](https://github.com/raindeer-rb/raindeer){:target="_blank"}, a new heavily event-driven web framework he is working on.

The mixing of Ruby and music continued with a short but very uplifting piano concert by [Nadir Hošić](https://www.linkedin.com/in/nadir-hosic-a17980144/){:target="_blank"}.

Next up was the panel. The topic was AI and on the stage were: [Chad Fowler](https://chadfowler.com/){:target="_blank"}, [José Valim](https://github.com/josevalim){:target="_blank"}, [Obie Fernandez](https://obiefernandez.com/){:target="_blank"} and [Armin Ronacher](https://lucumr.pocoo.org/){:target="_blank"}. It started off with a question about AI and its effect on their work. The answers were unanimously very positive. And then, as the conversation started digging into specifics, I got the impression that it started leaning negative. There were still positive swings, but a lot of the negative stuff came out: The slop PRs, review burnout, unreliable performance...

Still, the prevalent opinion was that code is fading in importance and we'll all be talking to agents more and more. I walked away wondering if this might be the last year that we have Ruby conferences at all? **What's the point of a Ruby focused conference if programming languages are irrelevant?**

Later I realised that the first day ending on this unsettling but thought-provoking note had set the stage for the next day. At least for me personally. It got me into a very contemplative mood. Well, it and some discussions I had with the other attendees in the nearby brewery. Without it, I don't think I would have noticed the positive **clues**.

## Day 2: The actual conference

The next day, Saturday, was the actual conference day, taking place in [Das Muth theatre](https://muth.at/en/the-theatre/){:target="_blank"}.

Chad Fowler delivered the opening keynote. It followed the same line as his panel comments from the day before: languages and syntax no longer matter. However, mixed in with it were clues about which Ruby-adjacent parts still matter very much. *Because Ruby is so dynamic, its community has adopted practices that work well with ambiguity and uncertainty.* The prime example is the testing culture and, to a lesser extent, TDD. Even if you're not on the "tests first" bandwagon, I've never met a Ruby developer who doesn't intimately understand the importance and value of a high-quality, comprehensive test suite. It's impossible to work effectively with Ruby and deliver high-quality software without mastering automated testing. We developed sophisticated linters that analyse the code and apply a consistent style. We adopted structures that make it easier to navigate the codebase. We internalised best practices that keep the code easier to understand and reason about.

![We loved being trusted by Ruby](/assets/img/posts/rubyconfat/trusted-by-ruby.jpg)

> And here we have the **first clue**: Ruby was already far out on the programming language spectrum pushing towards natural language. You might argue that Ruby came the closest while still being a classical, fully deterministic programming language. Everything we as a community learnt and built to deal with it has become even more valuable in the era of "programming with English".
{: .prompt-tip }


Next up was another keynote, because you can never have enough keynotes. Obie Fernandez delivered a story about "two chefs". He has been working at [Zar app](https://www.zar.app/){:target="_blank"}, where he realised that his development style and the Zar founder, [Sebastian Scholl's](https://www.linkedin.com/in/sebscholl/){:target="_blank"} style are very different. They both use Ruby and they both use AI. They're both effective in their own way, but they also work in very different ways. Obie likes to work on many things in parallel, and to lean into letting agents lose and evaluating the work from outside. Sebastian focuses on one task at a time and holds tight control over the agent's output. For me the key insight was that they both pick tasks that are more suitable to each style.

Even though I read multiple books by Obie and loved them, Sebastian's style resonated much more with me. Afterwards, I found Sebastian and had a really insightful chat with him.

![Which kind of chef are you?](/assets/img/posts/rubyconfat/two-chefs.jpg)

> And here I got the **second clue**: Ruby and AI-assisted development support both ends of the modern development spectrum. One style moves super fast and loose, with many experiments and rapid correction if things break in production. The other moves with focus and precision, shipping higher quality than was possible before. Both styles have their place, and depending on the project, one or the other will be more suitable. Both styles work with Ruby and, even more importantly, the Ruby community and development culture are diverse enough to accept and support both styles.
{: .prompt-tip }

After lunch, we had talks about [Glimmer](https://github.com/AndyObtiva/glimmer){:target="_blank"}, The Event Bus and the future of [RuboCop](https://rubocop.org/){:target="_blank"}. [Bozhidar](https://batsov.com/){:target="_blank"} spent most of the presentation sharing anecdotes from his previous Vienna visits before delivering an overview of what's coming to RuboCop. Suffice it to say, version 2.0 will come with many strong improvements. Linters in general and RuboCop in particular have become even more useful as tools for constraining AI-generated code. RuboCop going strong is an important point for the Ruby community. This very much supported the first clue I got from Chad's keynote.

We were treated to another mini piano concert as a welcome intermezzo, this time by Iman Jahić Hošić.

![Piano concert](/assets/img/posts/rubyconfat/concert.jpg)

I lingered in the hallway track for a bit longer and skipped the next talk, but I made it back for [Carmine Paolino's](https://paolino.me/){:target="_blank"} talk about why "Ruby is the best language for building AI Web Apps". The talk was about his library: [RubyLLM](https://rubyllm.com/){:target="_blank"}. I'm already a fan of the library, but in my worried state about Ruby's future, the talk highlighted something important for me. Here is a library that, in true Ruby spirit, expresses AI integrations more succinctly than the English language.

![RubyLLM elegant DSL](/assets/img/posts/rubyconfat/rubyllm.jpg)

> There was my **third clue**: With enough insight and creativity, Ruby can be moulded into a DSL that makes you more expressive than natural language. Rails has many such examples (hard to be more expressive than `belongs_to :user`). RubyLLM provides many more. And there are countless others. Professional domains develop industry jargon, and Ruby is flexible enough to model it closely.
{: .prompt-tip }

Next up was a very fun talk titled "Why Go Surfing with Strangers: Creating Connection in the Ruby Community". The talk was more of a story about community building and the purpose of conferences, interspersed with music. The talk had very little technical content, and yet it felt very appropriate for a technical conference.

> Between the lines was the penultimate clue: the technical side is the conference trigger, but the conference point is not the technical content.
{: .prompt-tip }

[Dave Thomas](https://pragdave.me/){:target="_blank"} delivered the penultimate performance of the conference, on a better approach to writing classes in Ruby. I was so happy that, to round off the day, we got something purely about the craft of expressing ideas in Ruby. For a moment, we forgot the discussion about whether the topic is still professionally relevant or just a hobby craft, and we just enjoyed a wonderfully presented view on a better way to structure classes.

![Dave Thomas on classes](/assets/img/posts/rubyconfat/clean-classes.jpg)

> This gave me the final clue: It is ok to enjoy the craft, even if you're unsure about commercial value. This talk was an exercise in thinking and elegant expression through code. Its commercial merit in a post-AI world is debatable, but it was undoubtedly enjoyable and the auditorium was full.
{: .prompt-tip }

## The closing

The conference closed with something special ... actually, I won't write about that. Go read the post by [Muhamed](https://muhamed.at/){:target="_blank"}, the conference organiser: [I'm rich!](https://muhamed.at/im-rich/){:target="_blank"}.

And in the end, where does this leave us on the question of whether Ruby conferences still have a point? For me, the answer is a clear yes. What about you? Did the clues help you? If you have your own clues, positive or negative, please share them in the comments.

Finally, I'll leave you with the following thought, relevant to all good conferences and meetups: **When you go to meet your friends "for drinks", you're not really going because of the drinks.** The kind of people that Ruby tends to attract seem to get this.

P.S. Big thanks to Niklaas for going on the treasure hunt with me, even if we didn't manage to finish it. ;) Yes, there was a city wide treasure hunt as part of the conference.
