---
layout: post
title: "Rails World 2025 from a first time speaker perspective"
date: 2025-09-10
categories: news
tags: ruby conference rails-world
---

Last time I was in Amsterdam I was 17 and it was a different kind of trip.

This time I was speaking at RailsWorld 2025. My first time giving a talk at an event of this magnitude. I've given many meetup talks but this is different. Also, the last time I talked in front of a few hundred people was before Covid, and that was in my home town. This is a long way of saying that this was a very, very big deal for me.

## Day 0 - arrival

I arrived at the speaker hotel on Wednesday midday. The room was not ready so I visited the viewing platform at the top of the hotel. I worked a bit with a wonderful view of the Amsterdam canal and grabbed lunch with several attendees I hadn't met before. I was pleasantly surprised that some people recognised my name from reading my blog. I put a lot of work into my blog and hearing in person that I actually helped someone is a huge motivator. What a great start.

![Working from Sir Adam tower hotel sky bar](/assets/img/posts/railsworld2025/tower-laptop.jpeg)

After settling in my room I headed for the pre-registration. It was at the historical Beurs van Berlage venue which was a short ferry ride and walk away. I ran into [Joe Masilotti](https://masilotti.com/){:target="_blank"} on the ferry and we had a really interesting chat about Hotwire and the curious lack of an official core team.

The venue was gorgeous and the hallway track was already in full swing when we arrived. Even before getting to the main hall I ran into people I hadn't seen in a while and met some people I'd only interacted with online. **This** is why we go to these things; the talks are almost an excuse.

[Adrian](https://adrianthedev.com/){:target="_blank"} just arrived and he showed me the new Ruby passport project. I'll explain more about that later, but for now I'll just mention that each passport was the size and form of a real passport and he had over 800 of them in his bags. And I'm not sure that he had anything else. I think we can all be grateful for the Schengen Area[^1] as I'm not sure how he would have explained 800 fake passports if he had to cross a border.

## Day 1

The day started with a nice 6km morning run along the canals, in good company of Ruby developers. The speaker hotel is on the north side of the main channel, opposite the old city centre. This meant that in the short 3km to the turning point, we were treated to a transition from an urban area by the large channel to an almost countryside view of family houses with their yards leading to quaint canals.

![Post run group photo](/assets/img/posts/railsworld2025/run.jpeg)

Then shower, quick breakfast, and a boat ride organised by Baltic Ruby. It turned out that the ride was giving a completely new meaning to the concept of guerrilla marketing. As they said themselves, now that we couldn't leave the boat, they told us all about Baltic Ruby. The presenter was funny and the ride was enjoyable so I concluded I'm OK with that kind of marketing.

### Intro

At the venue, we all filed into the main hall for the official start of the conference. The production was of a high standard. Large historical hall with a huge arched ceiling above, a large curved presentation screen. Then lights out, upbeat music starts, [Amanda Perino](https://x.com/AmandaBPerino){:target="_blank"} walks on, music fades out, and the conference officially started.

She introduced herself, the team, volunteers and sponsors, and gave an overview of Rails Foundations work over the last year. There were a lot of details that I forgot but the underlying theme was that they were busy. And successful, doubling the number of sponsors.

#### Organisation

I want to make special mention of the organisation of the event. It was superb all the way. From the big things all the way to the small details. The information was presented clearly, in detail and on time. I got a schedule emailed with all the correct times for all the speaker-related happenings and information. I basically had no unanswered questions.

When I checked into the hotel, my speaker badge and welcome package were already waiting for me in the room. Here I was trying to figure out where I needed to go to get it and it was all taken care of! It was smooth sailing throughout the whole event.

Well done Amanda Perino and the rest of the organisation team!

### Keynote

Now, the keynote by DHH. Here is the [link to the video recording](https://www.youtube.com/watch?v=gcwzWzC7gUA){:target="_blank"}.

The theme of the keynote was stepping back and looking at the whole problem. He talked about how we've forgotten the idea of what the problem was, that we've gone backwards and he wanted to think about the whole problem, all of web development. In the keynote he teased that he'd talk later about the problem beyond web development, but I'll give you a spoiler. That part of the presentation was about [Omarchy](https://omarchy.org/){:target="_blank"}.

In real life the keynote continued with the now familiar theme of compressing complexity and simplifying work. He drew a lot of comparisons between the experience of developing web pages in the 90s vs today. The Roman empire makes an appearance but I won't spoil that, watch the video.

![DHH presenting the keynote](/assets/img/posts/railsworld2025/dhh-keynote.jpg)

One thing that doesn't come off through the video is just how much energy David projects from the stage. Metaphorically in the style of the presentation but also quite literally with how loud he gets.

The talk featured a recap of all the major additions to Rails that will be released with 8.1 and the next version of Turbo. I'll give you a quick rundown as I was taking notes during the talk:
- Markdown becoming a first-class citizen with `format.md` being added to Rails controllers. Part of the motivation is that Markdown has become the lingua franca of AI.
- LEXY, based on [Meta's lexical](https://lexical.dev/){:target="_blank"}, becomes the new rich text editor for Rails. Side note, the Lexy screenshot had "Basecamp Five" written on the top, probably an accidental early announcement. 😏
- ActiveJob continuations. The approach relies on giving more structure to the jobs, by breaking their work into blocks that are labelled as steps. The library will take care of tracking the current step and continuing a job from the last completed step in case of a restart.
- The "frontier" of native mobile apps has some heavy lifting features coming:
    - Turbo Offline - More on that later when I'll talk about Rosa's talk where she talked just about that.
    - Native push notifications got an out-of-the-box solution: ActionPush which is Action Push Native and Action Push Web for PWAs. This also included an unexpected bit of news: [Campfire is now free and MIT licensed](https://github.com/basecamp/once-campfire/){:target="_blank"}. The stated reason is that DHH wants someone to extract the Action Push Web out of its code and upstream it to ActionPush. My RubyZG co-organiser [Stanko](https://stanko.io/){:target="_blank"} who recently started working at 37signals got the honour of managing the influx of PRs that followed shortly afterwards.
- Rails will make better use of Docker even if you're not developing with devcontainers by making it easy to put just the databases into Docker.
- They're dropping system tests: they removed 180 system tests from Hey, and reduced it to just 10 smoke tests. Since then they have not seen a single bug get to production that would have been caught by the removed tests. So, going forward, Rails will not suggest system tests by default in its generators. The framework is still there, and you can use it just as before, but it's no longer suggested. This one is likely to be a controversial decision.
- Support for local CI running. Due to much better hardware in local machines it's very feasible to just run CI tests locally. The only thing you need to make sure is that tests were actually run. So Rails is getting a DSL for configuring local CI runs with signoff supported using [GitHub signoff](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/managing-the-commit-signoff-policy-for-your-repository#about-commit-signoffs){:target="_blank"}.

What followed felt a bit like a side presentation: installing Omarchy on a brand new Framework desktop. David started installation with a stopwatch and talked about his experience of leaving Mac, going to Ubuntu, finding Typecraft videos on Hyprland and tumbling down that rabbit hole. He was interrupted by the installation finishing in 4:45 and moved on to giving a tour of Omarchy.

The rest of the talk was mostly about 37signals taking a stab at the problem of edge computing for their new product Fizzy. He gave a taste of what they're doing but I'll say a bit more about that in my comments on the next two talks I went to.

Overall, the talk was about adding more stuff but having it all aimed at needing less: more local development, more out-of-the-box setup, fewer moving parts with more functionality. I personally like this direction a lot.

### Multi-Tenant Rails: Everybody Gets a Database!

[Mike Dalessio](https://mike.daless.io/){:target="_blank"} talked about multi-tenancy. First, multi-tenancy can mean: comingled data (same database but separated by a key) or separate databases.

For reasons that will become clear when I cover the after-lunch talk, 37signals wants separate databases, with the focus on SQLite. They decided to build it on top of Rails 6.1 work for horizontal sharding and other multi-db improvements. The goal was to have it deeply integrated with every part of Rails so it mostly works out of the box.

What followed was a detailed ride through the implementation. The feeling I got was that this kind of work is very whack-a-mole because after he did the hard work of figuring out how it would be implemented, he had to track down many, many places in the framework where the pattern needs to be applied.

And I think doing this in the framework is the perfect place for this. This way we'll all experience some of the bugs while testing, instead of one company experiencing all of the bugs. And we'll get a robust solution built into the framework.

### SQLite Replication with Beamer

After lunch [Kevin McConnell](https://x.com/kevinmcconnell){:target="_blank"} essentially gave Part II of the multi-tenancy talk, the other side of the coin: Once you have one database per tenant, you can move it closer to the tenant and then add replication for low-latency reads from anywhere.

The talk started with an overview of what replication is and why it is useful. I'll bottom-line it: it's to avoid points of failure and allow scaling horizontally. This was followed by a speed-run overview of how Beamer works, and how SQLite works.

The motivation for this whole work is their new product: Fizzy, a ticket tracking system. They want it to be fast and the approach they're taking is edge computing, which is a fancy way of saying: *we'll put a server near every customer*. Fizzy is behind most of the big contributions 37signals has added to the framework recently. For example, Kamal Proxy, which was introduced at last RailsWorld, is a critical piece of that puzzle.

Many companies tried to solve edge computing and we'll see if 37signals can crack it in a way that will keep it easy to work with and accessible to small teams. It's worth watching this space in the year to come.

### Ruby Embassy

![The entrance to the Ruby Embassy](/assets/img/posts/railsworld2025/embassy.jpeg)

In the intro I mentioned that Adrian brought a bag full of Ruby Passports. Turns out that there was a Ruby Embassy on the first floor of the building. It was a super fun experience. Some volunteers (including Amanda Perino's parents) were enacting an embassy.

I arrived, got security checked. I was carrying a glass of water. When asked what it was I said "Let's say water" and the security guard answered in character with: "Let's say water is acceptable". Then I filled in a questionnaire, got my photo taken and was interrogated intensely by Amanda's mother. I nearly got rejected on account of killing a house plant but I blamed it on the plant's drinking problem which satisfied her. Finally, I got my passport stamped and my picture glued in.

Like many others have said, super fun experience and I hope to see more embassies at other Ruby conferences!

### Structured logging and events

After the break I made my way to [Adrianna Chang's](https://x.com/adriannakchang){:target="_blank"} talk about structured logging and events. Shopify needed a significantly more sophisticated solution than current Rails logging. They spent the last year developing it and then upstreamed it back to Rails. It will come out in Rails 8.1.

They were solving a problem of tracking business events in a structured manner. Current log lines are unstructured, essentially free-form text. This is great for reading but it's not great for processing and analysing by upstream systems.

In the new logging system, it all starts with an event: something interesting that happened in an application. The new system gives it structure, some standard properties that it expects, almost all optional, and the ability to add extensions. For example, shopper ID is a standard extension inside Shopify as it's used in almost every system.

The events are collected and emitted as structured JSON for consumption by upstream systems but it can also be formatted into a single line of text for human consumption.

Their motivation was a unified API for all event data in Rails. The goal is improved quality of event data that allows developers to find what they need faster. And to make it work with any observability stack. This is mainly done through support for OpenTelemetry.

### Closing Keynote: Hotwire Native - A Rails Developer’s Secret Tool for Building Mobile Apps

Joe Masilotti closed the day with a thorough overview of Hotwire Native in general, how it makes development of mobile apps easier and what's new in Hotwire 1.3. If you're at all interested in adding a native app to your Rails application, definitely watch his keynote; he answers all of the questions.

![Joe Masilotti presenting](/assets/img/posts/railsworld2025/joe.jpg)

I can also personally recommend [his book](https://pragprog.com/titles/jmnative/hotwire-native-for-rails-developers/){:target="_blank"}. He shared a coupon for 50% off: **RAILSWORLDJOE**. I don't get a cut or anything like that; I just think Joe really knows his stuff and it's a good book.

### Speaker dinner

The evening was reserved for the speaker dinner. For me, this was the most interesting perk of being a speaker. It gave me the chance to meet some very interesting people.

There was an organised boat from the speaker hotel to the restaurant. It's quite interesting boarding a boat and seeing Typecraft and DHH discussing something intensely.

Wednesday weather was moody but for the speaker dinner we were blessed with almost perfect weather. It really was a great opportunity to talk to many great people. It shouldn't come as a surprise but it's interesting just how down-to-earth and normal people in our community are when you meet them in a relaxed setting, even the very well-known ones.

I had the opportunity to tell Amanda directly just how impressed I am about the organisation. She said "go on, flattery works on me". It definitely wasn't flattery, but now you know, if you see her at a conference and you're impressed by the organisation, go ahead and tell her.

Everyone was very relaxed and conversations featured the usual mix of serious tech talk and silly jokes that you could hear in any other corner of the conference. Speaking of jokes, I reminded Aaron of an obscure event from 11 years earlier where I met him while we, believe it or not, shared a stage on a roundtable discussion[^3]. He was on stage because he's Tenderlove and I was there because I worked for a company that was sponsoring the event, but still. It gave me the chance to enjoy another joke-filled conversation with him.

On the boat ride back I chatted with [Jean Boussier](https://bsky.app/profile/byroot.bsky.social){:target="_blank"} about life. Really nice guy, the boat ride back went by very quickly.

## Day 2

Now, unfortunately I have much, much less to write about Day 2 talks. The reason is that my talk was at 15:45 and I spent a large part of the day calming myself down and going over the talk. This was a big thing for me. The last time I spoke in front of a large crowd was before Covid and it was also in my home town, which made it a bit easier.

I still went for a morning run but I skipped the organised boat and headed to the conference later. I figured I'd better get more sleep on the day of the talk. There was a fireside discussion in the morning but when I arrived it was already underway and the hall was full. I stayed at the back long enough to hear a few puns from Tenderlove and then I went to the speaker section to go over the talk.

### Lightning talks

Lightning talks were during breaks and they were in a separate room on the second floor. [Miha](https://mr.si/){:target="_blank"} was giving a presentation about his profitable side project [visualizer.coffee](https://visualizer.coffee/){:target="_blank"}. I went to watch his presentation and it was great. Maybe I'm biased since we helped each other with our talks (thanks again Miha for the help!) but he gave a nice overview of his journey from solving his own problem to having a growing community of users.

![The final slide from Miha's talk](/assets/img/posts/railsworld2025/miha.jpeg)

### Bringing Offline Mode to Hotwire with Service Workers

[Rosa](https://rosa.codes/){:target="_blank"} tackled one of the most requested features of Turbo: offline mode support. This is especially important for native apps. And the motivation behind her work is offline support for Hey email clients.

The basic idea behind the approach is to use JavaScript service workers to download the relevant pages ahead of time for serving them to the main app when the user is offline. And only for GET requests. The pages to be downloaded will be declared with a custom element that will serve as a manifest of offline pages that the current page expects to need to load for offline functionality.

![Rosa presenting](/assets/img/posts/railsworld2025/rosa.jpeg)

The [PR is still in progress](https://github.com/hotwired/turbo/pull/1427/){:target="_blank"} but it's looking very promising. If you're interested in contributing or understanding the approach better, watch Rosa's talk when it comes out. It's both entertaining and it gives an excellent technical explanations of the approach and technologies used.

### My talk: Lessons from Migrating a Legacy Frontend to Hotwire

My talk wasn't quite yet on the agenda, but I couldn't watch any other talks; the nervousness was getting to me.

I retreated to the speaker's section. It was a room just off the main hall that was reserved for speakers to have a quiet space to prepare for the talk. Besides some comfortable chairs there was nothing special back there: a coffee machine and a fridge with refreshments. But most importantly it was calm.

I took out my laptop and went through the presentation once again in my head. All good, I'd prepared it enough in advance that I'd already had several practice runs. Then I went out a bit into the hall to chat with people, and came back. I did that a few times.

When it was time to go and get ready for the talk, I took out my headphones. Music can do wonders for managing emotional states. I put on [Papilon by Editors](https://www.youtube.com/watch?v=Wq4tyDRhU_4){:target="_blank"} which I know helps me calm down and focus when I'm nervous. I don't know why, it just does. I walked through the crowd in the hall outside for some air and then slowly back in and into the presentation hall. With the level of excitement I had at that moment and with Papilon playing in my ear, I felt a bit like I was in a personal music video. I know it's completely ridiculous and childish but it was a big thing for me and I allowed my inner child[^2] to enjoy the moment.

The technicians hooked me up to the microphone and I had about 10 minutes to kill. I played the song again and walked slowly by the stage. That calmed me down. The minute just before going on is the most intense but it goes away once I start.

![The view when I was waiting for people to come in and the talk to start](/assets/img/posts/railsworld2025/behindthestage.jpg)

Typecraft came, greeted me, went out, announced me and I went on. The rest went very fast for me, almost in a blur. I'd rehearsed it enough that I was doing it almost on autopilot. The time went by so fast that at one point when I had about a third of the presentation left, I looked at the clock and saw it showing 11:30. My slot was 30 minutes so I freaked out for a moment because I thought I was going way too fast and would finish too soon. And then I calmed down because the clock changed to 11:29 and I realised it was counting down not up. The fact that this whole thought process took literally a second tells you how fast my mind was racing under the adrenaline.

![My presentation under way](/assets/img/posts/railsworld2025/intro-slide.jpg)

And then it was over. I went off, various friends came to tell me it went great and I could now fully relax and enjoy the closing keynote.

During the talk I also shared a [30% discount code for my book](https://masterhotwire.com/?discount=RAILSWORLD){:target="_blank"}. The code never expires so whenever you're reading this, it'll be good.

> The talk was all about my work at [Halalbooking.com](https://halalbooking.com/){:target="_blank"} and we're currently hiring. It's a small team with an extremely low number of meetings and copious focus time. I have time to interact with everyone on the team. You can [find the open positions here](https://github.com/halalbooking/hiring){:target="_blank"}.
{: .prompt-info }

### Closing Keynote

Aaron gave a great closing keynote in his usual style of some rapid puns with a switch to a super-deep technical dive. In classic Aaron style, it was both an amusing and engaging presentation. Maybe someday I can be like Aaron.

However, being a speaker gave me a bit of a background glimpse. Since I had a slot just before the closing keynote, I spent a lot of time in the speaker area and he was also there, going over his talk. And he looked visibly nervous. I asked him how it was going and we chatted very briefly with Mike Dalessio and in the middle of the conversation he snapped and went "I need to go learn, learn, learn" and went back to his presentation. I know this is often mentioned but I keep forgetting that even the best go through a similar mental journey as the rest of us; the stakes are just a bit higher.

### The closing party

I went back to the hotel before the closing party and lay down on the bed to just relax a bit. I almost fell asleep but then decided I wasn't missing the party and took a quick shower before grabbing a taxi.

The party venue, [the STRAAT Museum of street art](https://straatmuseum.com/){:target="_blank"}, was amazing. A giant hall filled with huge pieces of artwork that were amazing. I walked around, honestly enjoyed the art and concluded that the party had reached hipster levels previously thought unattainable.

![The view of the part of the museum where the party was](/assets/img/posts/railsworld2025/party.jpeg)

One small thing to complain about was that the DJ was instructed to keep the level moderate. I mentioned this to Amanda and made a small remark that at Euruko closing parties, DJs have free rein. She said she knows because she's seen videos and that's why this DJ has different instructions. Considering we were literally inside a museum, I have to begrudgingly agree that was a wise call.

A few of us later found some remedy in a karaoke bar in central Amsterdam. We did our duty and one of the songs we picked was ["Ruby" by Kaiser Chiefs](https://www.youtube.com/watch?v=qObzgUfCl28){:target="_blank"}. 🫡

## Closing thoughts

And that was a wrap, I'm writing these words on a plane heading back to Zagreb, somewhere above Germany. The impressions are still sinking in. I'm extremely grateful to everyone that made this possible, and that made this journey more enjoyable. Everyone I met and talked to. By and large, the people were normal, nice and down to earth.

It's a good community to be a part of.

## Footnotes

[^1]: Schengen Area is a system of open borders that encompass 29 European countries that have officially abolished border controls at their common borders.

[^2]: To be fair, it's not like my inner child is buried very deeply, the smallest things bring him right out.

[^3]: There actually is a recording of this on Youtube. I went looking for it to check the exact year. But you shouldn't look for it. I gave a short intro presentation that, with 11 more years of experience, makes me cringe.
