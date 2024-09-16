---
layout: post
title: "EuRuKo 2024 conference reflection"
date: 2024-09-16
categories: news
tags: ruby conference euruko
---

I love Sarajevo. It's one of my favourite cities. A unique mix of cultures in this part of the world. I've visited it multiple times and have many fond memories. Unfortunately, it's been many years since the last time I visited. Because, well, life. Not a great excuse. Apologies to my Sarajevo friends. I'm sorry I needed the European Ruby Conference to be in Sarajevo to visit again. Some of you pointed it out. Ok, well, one of you pointed it. It was Mirza. You were right, Mirza.

Lucky me that this year's Euruko conference took place in Sarajevo.

As far as I'm aware, this was the largest Euruko ever in terms of content. Every previous Euruko I've been to, and I've counted 5, was a 2 day, single track event. This was a 3 day, 3 track event.

I couldn't possibly see everything. And I usually don't have the mental capacity to even completely follow a single track. So you'll get the conference from my eyes. Just keep in mind that I personally saw only **a small part of it**.

> When the talk videos come out I will update the article with links to all the videos.
{: .prompt-info}

## Day One

I love conference starts, it's buzzing with excitement and I'm looking forward to all of the conversations I'll have, old friends I'll see and new people I'll meet. I went for a run with friends in the morning and got in just in time for the first keynote.

### Keynote by Xavier Noria

![Main conference hall](/assets/img/posts/euruko2024/conference.jpeg)

It was an unusual choice for a Keynote, it was a very technical talk and keynotes are usually more philosophical, to get people excited. However, it was an excellent talk.

The talk is about [the Zeitwerk gem](https://github.com/fxn/zeitwerk){:target="_blank"} . It was also a disguised lesson about software design. It covered the history of Zeitwerk, what was the motivation for building it and how valuable it was that Shopify and Github were early adopters. But I found the software design lessons more interesting.

Not to spoil the talk, some of the lessons were:
- **The value of keeping the interface simple**: Zeitwerk does a lot of work behind the scenes to then be able to disappear from your code, doing its work silently in the background.
- **Making interfaces ergonomic**: strive to make the interface fool proof by designing an API that is hard or impossible to use incorrectly. Xavier makes a nice analogy with a bread cutter from his local supermarket. It has blades that could cut you but the buttons for starting it are disabled until you close the safety lid.
- **Good interfaces acknowledge asymmetries**: If some code is used more often it is good to acknowledge that and depart from the usual interface to provide it with a simpler and easier to use interface so this particular common use case would become very simple for the users.

The talk concludes with an interesting comment about the future. Xavier explains a gap, an edge case, in the current library design. As it turns out, Ruby 3.2. `Module#const_added` allows him to solve it. That will be the fix that triggers an upgrade of the mayor version to Zeitwerk 3. And with that he believes the library will be complete, all cases covered. Quite an accomplishment.

### A decade of Rails Bug Fixes by Jean Boussier

In the next talk I caught, Jean broke down the process of fixing 2 Rails bugs, his first one, over 10 years ago, and a very tricky one relatively recently. It was super technical but I enjoy these deep dives. The talks felt like watching over the shoulder of a very skilled colleague as they wrestle a hard issue.

The bugs were in Rails internals, in the areas I'm not familiar with, but the explanation was easy to follow. I won't recount the bugs themselves but I'll repeat the generally applicable lessons:
- **Reproduction is absolutely critical**: If you can't reproduce the bug it's nearly impossible to fix it. It's also why usually the best person to investigate a bug is the same one that experienced it. They have the reproduction in front of them. It's also why most unclosed old issues on github repositories are bugs without a clear reproduction.
- **Debugging is very much like applying the scientific method**: You observe an issue **->** form a question **->** form a hypothesis about the root cause **->** do an experiment to test it **->** analyse the results **->** reach a conclusion **->** use it to make a new, more useful observation. Rinse and repeat until the issue is solved.
- **Beware of assumptions you have about systems (you think) you know well**: The second bug he explained started as bug in Mastodon that turned out to be a bug in Rails that was triggered by a bug in Ruby. All the way down. Jean really emphasises the value of being comfortable digging into the lower layers. **We should treat all code as our code.**

These lessons ring very true. I've certainly traced issues down into gems on multiple occasions.

### Seven Things I know after 25 years of development by Victor Shepelev

![Victor presenting the talk remotely](/assets/img/posts/euruko2024/zverok.jpeg)

Since Victor is in the army of the war torn Ukraine, he delivered the presentation as a recording. Some years ago I had the privilege of working directly with Victor on the same project. He is an excellent developer and it was a pleasure seeing this talk.

I don't think it takes away from his talk if I list the the things he learned. The value is in the deeper explanations:
1. You outgrow every framework
2. Patterns and methodologies fail
3. Scale only grows with time
4. Pay attention to stories
5. The goals are truth and clarity
6. This might be a lonely experience
7. Never give up seeking truth

I'll unpack point 5 as it has a nice lesson that can stand on its own. Victor dug into the underlying truth is behind some common practices:
- OOP - try to model it as it is
- TDD/BDD - describe the expected behaviour
- DRY - single source of knowledge
- KISS - don't hide behind abstractions
- DDD - speak the same language as the domain

Whenever this gets forgotten, we're in danger of twisting the idea until it is no longer useful. It's something [I consider especially important](/articles/misunderstand-practice-misuse-it).

You should watch the full talk to understand the full meaning of other points.

### Networking

After lunch I took a break from the talks and went up to the Networking room with [Miha](https://mr.si/){:target="_blank"} which was completely empty. After making some corny sarcastic jokes about programmers being great at Networking, [Bartosz](https://github.com/bblimke){:target="_blank"}, the creator of [Webmock gem](https://github.com/bblimke/webmock){:target="_blank"} wandered in with the same idea. We ended up having a very interesting conversation about various topics, including sustainability of open source. This was also a topic of a later panel in which Bartosz participated. Bartosz was also kind enough to become the 200th subscriber to this blog. Thank you Bartosz, I'm humbled to have you as a subscriber.

### Lessons From Escaping  Dependency Upgrade Maze by Marko Ćilimković

I went to catch a talk of Marko who is also a member of the Zagreb Ruby community. He works for an agency that has many clients and many projects that they maintain for their clients. The problem he tackled was keeping the projects up to date. Number of outdated gems increase every month and bringing it down is a lot of work.

The talk was driven mainly by big agency problems, i.e. lots of clients in long maintenance mode. It will be less applicable if you're a team owning one product in continuous development.

It was interesting to see him tackle why we should care about state of dependencies if you have a project that is working. For those of us working on main company projects this answer is almost self evident. However for clients it's different and he found that emphasising benefits like new features they would get for free was a great selling point.

Most of the talk was about prerequisites to making the upgrade process smooth, some of which are:
- High code coverage
- Removing private API usages
- Reducing dependencies
- ...

To track the Project health in a score they implemented an internal solution. This is something that could be useful for teams focused on one project as well. For all of you interested, the automatic score calculation is open sourced as the [polariscope gem](https://github.com/infinum/polariscope){:target="_blank"}.

### Keynote: Evolution of real-time and AnyCable Pro by Irina Nazarova

![Anycable growth in 2024](/assets/img/posts/euruko2024/anycable.jpeg)

Irina is a CEO at Evil Martians and a cofounder at [AnyCable](https://anycable.io/){:target="_blank"}. Lots of interesting details were presented in the talk including the detailed breakdown of the business side of growing AnyCable as an open core product.

I've found it interesting enough that I forgot to take notes, sorry! One thing that surprised me is that the recurring revenue from AnyCable subscriptions is still dwarfed by their consulting revenue, sitting at just ~$30k ARR. Their consulting revenue is very healthy but I was expecting the division to be different. Big thanks to Irina for being so transparent! The talk is an invaluable resource to anyone considering a similar path.

### Fireside chat: A sustainable path in Open Source

![Anycable growth in 2024](/assets/img/posts/euruko2024/fireside.jpeg)

Irina's keynote served as a great intro to her fireside chat with Bartosz Blimke, Adrian Marin & José Valim about a sustainable path in Open Source. Bartosz is the maintainer of the popular [Webmock gem](https://github.com/bblimke/webmock){:target="_blank"}, Adrian is the creator of [the Avo gem](https://avohq.io/){:target="_blank"} and José is the creator of [the Elixir programming language](https://elixir-lang.org/){:target="_blank"}, among other things.

Various financial models were discussed:
- Donations
- Open-core
- Consulting
- Charging for support
- Sponsorship of large companies
- ...

There was no definite answer and more questions were opened then there were closed but a lot of good insights were shared. It's an important topic that our industry will need to address at some point to keep moving forward.

My main objection is that there was no actual fire on the stage, as you can see in the picture. That was quite a disappointment for me.

## Day Two

Let me take a break and share a snippet of amazing Bosnian nature. On the second day I went again for a run, joined by [Miha](https://mr.si/){:target="_blank"} and [Julian](https://juliancheal.co.uk/){:target="_blank"} . We went to the Spring of Bosnia and were rewarded:

![The spring of Bosnia](/assets/img/posts/euruko2024/vrelo_bosne.jpeg)

### Keynote: 20 years of YARV by Koichi

Koichi, the creator of YARV, the current reference Ruby implementation started by giving an overview of his history of working on YARV. It's very fortunate for the community that he was able to work for basically the whole time on YARV thanks to a series of employers that sponsored his work. They hired him to work on YARV, to continue contributing to open source. It's especially interesting in the light of day 1 discussion on sustainability of open source.

The talk then went into technical details of how YARV works. YARV is a stack based virtual machine and he explained how that works. The rest of this section went into specific optimisations that YARV takes when generating opcodes. Yes, the talk got increasingly more technical as it went.

It was interesting to see what he sees as good and bad points with YARV:
- Good point: Defining the Ruby VM instruction set. Before that people were even unsure if Ruby, with its heavy dynamic nature, can have a usable low level instruction set.
- Good point: Human readable instruction names.
- Bad point: There's no well defined instruction set. YARV does not have a published instruction set it sticks to. Tools rely on the current instruction set but it's not guaranteed to be stable. However, YJIT relies on the current specification and it's having an effect of stabilising the instruction set.
- Good point: Optimising method dispatch. It's an extremely hard problem in Ruby. The implementation was rewritten many times over the years.
- Good point: Optimising specialised instructions. This is mainly about specifically optimising dispatch of small frequently used standard library methods, e.g. `String#empty?`, `Integer#+` ...
- Good: Providing a way to handle instructions. This is about the methods for inspecting the compiles Ruby with `RubyVM::InstructionSequence`. Along the same lines is `prelude.rb`.

And interesting future improvement he talked about is the concept of lazy loading. Having compiled code stored as a binary and then load just the code that's needed. Potentially this could open a possibility of packing an application with all its gems into one binary that's then lazy loaded as needed.

A potential future project he might take on is implementing a Flexible JIT compiler as an alternative to YJIT. The idea is to have a JIT compiler that has JIT benefits but doesn't limit the flexibility of YARV. That project is still in an idea phase. He asked his employer to hire a few more people to form a research team to work on this project.

### Lightning talks

I really like Lightning talks, so much that I gave one at this years conference. Big thanks to Miha for helping me put it together.

As most lightning talks do, mine had just one point: to convince people on the fence about Hotwire to give it a try and to consider starting with Turbo Frames. It was fun to make and give, I titled it: **"The point is that it’s a gateway drug: Turbo Frames"** The other point was that people should subscribe to my blog. :D

My talk was second to last and I was so nervous about it that I didn't carefully follow any of the previous talks, sorry.

### Async Ruby by Bruno Sutic

[Bruno](https://brunosutic.com/){:target="_blank"} is one of the other two co-organiser of Ruby Zagreb meetup, along with myself. In this talk he dives into the not so often used concurrency solution: Async Ruby. He's an early adopter and the talk goes into fair amount of depth to explain the difference between the different primitives in Ruby:
- Processes
- Threads
- Ractors
- Fibers
He explains where async Ruby fits in that picture (spoiler alert: it's a higher layer relying on Fibers and a fiber scheduler). The gems ecosystem around Async is explained.

The talk then moves into a practical examples. The concept of async tasks and how they are used is explained. It's essentially a small crash course in writing async ruby.

The examples cover:
- Downloading multiple URLs
- Calling multiple endpoints at the same time and waiting just for the fastest one, cancelling and discarding the others.
- Calling a 3rd party API but limiting the callers to 2 at the same time. It can be useful to easily schedule a batch of work that's running against an API that has rate limits you need to honor. I.e. limiting the concurrency of a batch of tasks.
- Scaling IO operations. He demonstrates running a mix of 5000 different pure IO tasks with total running time of 7.8 seconds.

Finally, he contrasts Async Ruby, based on Fibers, with a more conventional approach involving Threads: The differences and limitations of either approach.

### Keynote: Livebook: where Web, AI, and Concurrency meet by José Valim

![Livebook in action](/assets/img/posts/euruko2024/livebook.jpeg)

José is a frequent guest on Euruko conferences, even if he mainly doesn't work with Ruby anymore. Elixir draws a lot of inspiration for language design from Ruby and José is a great speaker.

[Livebook](https://livebook.dev/){:target="_blank"} is an opensource project in the similar vein as Jupyter notebooks. The talk is very interactive with a lot of live coding. I will not try to replicate here but I will just say: **It got me thinking that it would be nice to have something like this in Ruby**.

### Evening

The evening had the usual Euruko party which this year featured Karaoke in one of the conference halls. Let's just say that it was super fun and by the end I was drenched in sweat.

![Karaoke with a very appropriate song](/assets/img/posts/euruko2024/karaoke.jpeg)

## Day Three

I'll be honest. by Day Three I was a bit fatigued from the talks so I relaxed on the notes taking. But, since this is a an article recounting my experience of the conference, the short talk descriptions are an accurate account of my real attention span on this day, even though the talks were good.

### Patterns of Application Development Using AI by Obie Fernandez

The talk is essentially a preview of Obie's book [of the same name as the talk](https://leanpub.com/patterns-of-application-development-using-ai){:target="_blank"}. I know because I bought his book and started reading it. I'm about a third in and I'm really enjoying it so far, looking forward to reading the rest.

Obie breaks down the experience building an AI based product, Olympia. He settled on a combination of regular AI patterns (like RAG -
Retrieval-augmented generation) and some I haven't seen mentioned anywhere else (like his Ventriloquist pattern).

### City Pitching

Just before lunch break was the city picthing section. This is the section where people present their city and themselves as candidate for the next year's Euruko organisation. I don't know why but this year there were very few candidates.

Barcelona team was the only one that came prepared with a presentation and very enthusiastic presenters. They were the only ones that applied in advance. When they finished their presentation they even asked: "Is this it, are we the only ones?"

Then there was a hand in the crowd and "Viana do Castelo" was presented by opening google image search results.

And that was it, no more candidates. As far as a I remember, every other Euruko I attended had at least 4-5 presentations.

In the end Viana do Castelo won by a relatively narrow margin. I'll be honest, it came as a surprise to me. That said, I wish the organiser all the best, I have utmost respect for everyone willing to take on the monumental work of putting together a conference like Euruko.

### Workshop: SQLite on Rails: From rails new to 50k concurrent users and everything in between by Stephen Margheim

I decided to skip talks in the afternoon and get some hands on practice. Stephen is maybe the foremost current expert on using SQLite with Rails and the workshop was very detailed and well put together. My only gripe is that it could have been better paced since we ran out of time a few sections before the end of the workshop.

If you want to go through the workshop on your own, it can be self paced by following the instructions in this repository: https://github.com/fractaledmind/euruko-2024

Also the first half of the talk has a lot of overlap with Stephen's blog post from earlier this year: [SQLite on Rails: The how and why of optimal performance](https://fractaledmind.github.io/2024/04/15/sqlite-on-rails-the-how-and-why-of-optimal-performance/){:target="_blank"}.

# Closing thoughts

Besides all the talks, for me personally, Euruko delivered on the most important aspect of conferences: I met some friends I haven't seen in a while and I met a lot of interesting new people. All in all, I was super happy that I went.

P.S. Big thanks to [Predrag](https://www.linkedin.com/in/predrag-radenkovic-07512116/){:target="_blank"} for driving to and from the conference and suffering, along with Miha, my company along the way.
