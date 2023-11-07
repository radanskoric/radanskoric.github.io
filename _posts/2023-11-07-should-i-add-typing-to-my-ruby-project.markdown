---
layout: post
title:  "Should I add typing to my Ruby project?"
date:   2023-11-06
categories: articles
tags: ruby types static-analysis sorbet rbs correctness
---

<style>
  /* Extra styling to make the question elements look interactive */
  li.task-list-item {
    cursor: pointer;
    padding-left: 1rem !important;
  }

  li.task-list-item:hover {
    background-color: var(--prompt-info-bg);
  }

  .content ul.task-list {
    padding-inline-start: 0.25rem;
  }
</style>

_I used statically typed languages and liked the extra safety but I also really like Ruby for how elegant it is and the freedom it gives me. Will I regret adopting types?_

_Will gradual typing be supported long term or is it a fad? Will this be an abandoned investment? If I decide to add it, which solution should I pick, battle tested Sorbet or core team endorsed RBS?_

## Introduction

> This article has an interactive component for evaluation. If you're here just for that and want to skip the intro, you can jump to [the evaluation section](#evaluation).
{: .prompt-info }


You've heard good things about Sorbet and RBS. Over in Javascript land, Typescript is all the rage. The long standing debate of static vs dynamic typing is alive in the software industry with a fresh energy and static typing seems to be currently winning. Ruby is _very_ dynamically typed but even it has had a lot of investment into typing tools backed by huge corporations (Sorbet) and endorsed by the Ruby Core team (RBS). On the other side, it seems that the community at large isn't jumping on it. People have various strong opinions going in different directions, including some [very](https://world.hey.com/dhh/programming-types-and-mindsets-5b8490bc){:target="_blank"} [prominent](https://zverok.space/blog/2023-05-05-ruby-types.html){:target="_blank"} members of the Ruby community.

I've also been wondering about the correct choice. I've been playing with Rust on the side and really enjoying it. On more than one occasion when debugging a Ruby issue I've thought "this would have been a compile time error in Rust". On the other hand I really enjoy beautifully written Ruby. IMO, elegance and readability of well crafted Ruby code is hard to match in almost any other language. On most real life projects, the speed of development is easily worth an occasional corner case bug with an unexpected `nil` value ... except when it isn't.

Beyond reading posts and comments on the topic I've also done the exercise of fully adding both Sorbet and RBS to a side project[^1].

### Anyway, why is static vs dynamic typing so controversial?

Quickly, of the top of your head, which approach is older, static or dynamic typing?

...

...

...

[FORTRAN](https://en.wikipedia.org/wiki/Fortran){:target="_blank"} is considered the worlds oldest widely adopted high level programming language and it first appeared in 1957. It is statically typed, so static typing is older. However, [Lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language)){:target="_blank"} first appeared in 1960 and it was the first dynamically typed programming language. Notice how close in time they are, just 3 years apart, over 6 decades ago.

Since then, a lot of digital ink has been spilled over which approach is better. If you google for "static vs dynamic typing" you will find a rabbit hole of articles arguing for one or the other with excellent points on both sides. Academic literature is no more conclusive [^3][^4][^5][^6]. The effects that do show up in studies are usually small and the authors notice that they are likely to be dominated by other factors, like how experienced the team is or what other software methodologies are used to prevent bugs.

There are many dimensions that make up a measure of quality software development and not all of them are along the same axis. As evidenced by many teams successfully using both static and dynamic languages to build high quality software, it's possible to thrive with both approaches.

And that is why it is safe to conclude that whether you would benefit from adopting gradual typing in your Ruby project is going to depend on a number of factors, i.e. you should do a **cost** vs **benefit** analysis for your particular project with considerations of **alternative solutions**.

I am preparing an overview of all of the libraries and tools available to Ruby projects that in some way work to prevent defects. Subscribe to not miss it:
<script async data-uid="e83d1aa837" src="https://thoughtful-producer-2834.ck.page/e83d1aa837/index.js"></script>

## Evaluation {#evaluation}

For Ruby projects in particular there are two main benefits: reduction of type related bugs and improved tooling. Static typing systems in other languages carry other benefits, like increased speed from ahead of time compiler optimisations. However we don't have that available in Ruby, at least not yet[^7].

I've identified 5 main factors which consistently appear in discussions and recommendations. This part of the article has some light interactivity. **Each factor has simple scoring and you can click on them to vote**. At the bottom of the post it will automatically tally up your result and provide some recommendations.

### Reduction of type related bugs

If you are considering adding types to an existing project, you already have some data you can examine to estimate what proportion of bugs it would have likely caught. In Ruby, a typo in the name of constant will result in a `NameError`. A valid, but incorrect type usually results in a `NoMethodError`. Most often it will be a `nil` where a non nil object is expected. Less likely, in the case where you have the correct type but are calling the method with a wrong number of arguments you will get an `ArgumentError`. With that you can:
- Search your bug tracker for occurrences of `NameError`, `NoMethodError` and `ArgumentError`.
- Search bug tickets in your project management software for the same snippets. Try similar phrases.
- Search your git commit messages for occurrences: `git log --grep="NameError"`. If your team has some git commit message convention you can use, that will help a lot.

If you are considering it for a new project then remember that often the best prediction of the future is assuming that the past will repeat. Do the same analysis on a previous project, preferably done by the same team.

How many errors that would be caught by type checking are you finding:

- [ ] 0 pt : No or almost no errors.
- [ ] 1 pt : Moderate amounts, regularly occurring but not among the most frequents errors.
- [ ] 2 pt : High amounts and among our most frequent errors.

### Improved tooling

How much benefit you gain from tooling that can take advantage of types is going to depend on what editors you and rest of your team prefer. Most of the community now [uses full featured editors](https://rails-hosting.com/2022/#what-is-your-preferred-editor){:target="_blank"} but Ruby is expressive enough that one can develop effectively in a more bare bones editor, and a lot of people still do that. Also, with the adoption of LSP (Language Server Protocol) it's very likely that almost all of the editors can take advantage of a language server, it's just that for some editors it will be easier to get it working:
- Visual Studio Code has an official extension for both [Sorbet](https://sorbet.org/docs/vscode){:target="_blank"} and [Steep+RBS](https://github.com/soutaro/steep-vscode){:target="_blank"}.
- RubyMine has [built in support for Sorbet](https://www.jetbrains.com/help/ruby/sorbet.html){:target="_blank"}.
- SublimeText has official docs on how to [use Sorbet LSP](https://lsp.sublimetext.io/language_servers/#sorbet){:target="_blank"}.

Survey your team for their setup and tally how many will be able to take advantage of improved LSP features with their current setup. It is unlikely that you will get people to change their setup and be happy with it.

How many people in your team will be able to take advantage of improved editor tools **with their current dev setup**?

- [ ] 0 pt : Almost none, less than 20% of the team.
- [ ] 1 pt : Some developers, 20-80% of the team.
- [ ] 2 pt : Almost everyone, 80%+ of the team.

### Usage of meta-programming

All type checkers still struggle a lot with meta-programming. Stripe, the creators of Sorbet have seen a decline in meta-programming [^8] with the adoption of Sorbet and the team is happy with that. The affinity to using meta-programming in Ruby is going to vary a lot between different development teams and it's a very important factor in deciding whether to adopt gradual typing as the two work against each other.

It's both important to estimate how much meta programming you are currently using and what is the team's preference. Here I am talking only about meta-programming in your own code. It's likely you are using Rails and it has a lot of meta-programming under the hood but that is hidden from you. There are repositories of RBI and RBS files for standard library and popular gems and the cost of maintaining them is amortised across the community, i.e. you don't have to bear that cost.

How much meta-programming are you using?
- [ ] 0 pt : We make extensive use of meta-programming and will continue doing so.
- [ ] 1 pt : Some meta-programming and we intend to continue using it.
- [ ] 2 pt : None at all and we intend to keep it that way, or we have some but want to eliminate it.

### How large is the codebase

When collecting comments from forum and blog posts I noticed that most of the excitement is coming from people working on very large codebases. All of the tooling and evangelism for Ruby gradual typing is coming from large companies with very large Ruby codebases. Even more importantly, almost all of the related development is due to investments by those companies. Matz has shown, at best, reluctant support for typed Ruby. It is reasonable to expect that most of the improvements will be geared towards making the tooling work better on large codebases worked on by a lot of developers. An often cited main benefit is the ability to accurately **jump to definition**. So instead of measuring the size of the codebase, because we have no data on this, let's frame it in the context of jumping to definition.

How much would you benefit from improved "Jump to definition" editor integration?
- [ ] 0 pt : Not at all, I mostly already know where something is defined or my existing setup works (e.g. [solargraph](https://solargraph.org/){:target="_blank"}).
- [ ] 1 pt : I would get some mild benefit. It happens regularly but not frequently that I have trouble finding the definition of a method or a constant.
- [ ] 2 pt : It would be a game changer, this is a frequent stumbling block for me when working.

### How do other developers in the team feel about this?

Last but not least, this is a change that will directly affect how people work and it's a topic on which developers often have strong opinions. Don't lie to yourself, even if you have great arguments for adopting it, forcing this on people who really dislike it will certainly have a negative effect on their performance. This is something that will be woven through their day to day work and impossible to ignore. We shouldn't lose sight of the fact that software is made by humans.

How many people in your team are excited to try adopting types in your project?
- [ ] 0 pt : Almost none, less than 20% of the team.
- [ ] 1 pt : Some developers, 20-80% of the team.
- [ ] 2 pt : Almost everyone, 80%+ of the team.

### Result

><span id="quizResult">You haven't answered any questions yet, you can answer by clicking on the answers above.</span>
{: .prompt-tip }

Here is the table for evaluating results which was created by a very scientific process of me thinking very hard about it! So, yes, if you disagree with the scale, I definitely invite you to think very hard about it and modify it. This is also part of the evaluation process. ;)

#### 0-3 points
You don't seem to be in a good position to benefit from gradual types. It's likely to be an uphill battle with little to show for it. I would suggest that instead you look into alternative approaches: increasing test coverage, adopting different kinds of linters, refactoring problematic parts of the codebase.

I plan to write in more detail about that in the next article. Subscribe to not miss it:
<script async data-uid="e83d1aa837" src="https://thoughtful-producer-2834.ck.page/e83d1aa837/index.js"></script>

#### 4-7 points
It's unclear if you'd benefit from adopting types. I would suggest doing an experiment by either adding it to part of your main project or to a smaller non-main project, a side project or an internal company facing project.

I've done that experiment and written about it[^1]. More interestingly, Shopify also did an evaluation on an internal project[^2].

#### 8-10 points
You seem to be in a great position to benefit from adopting types. See the next paragraph for advice on deciding between Sorbet and RBS.

## Sorbet or RBS?

If your evaluation resulted in you deciding to adopt gradual typing then one last question to answer is which tool to use?

One would expect that the decision can easily be postponed because it is theoretically possible to automatically translate one into the other. After all, they should ultimately both contain the same information. However, in practice, this work has not been high on anyone's list of priorities. Shopify worked internally on an [RBS to RBI automatic transpiler](https://github.com/Shopify/rbs_parser){:target="_blank"} but it was abandoned in January 2023. From what I've gathered it was because Shopify itself doesn't have any benefit from it. Also, the problem seems to be harder than one might expect and we are unlikely to get such a tool until some sufficiently large company decides to switch from RBS to RBI.

So, at the moment, you are better off picking one and sticking with it. If you have decided to adopt gradual typing and this is the last decision that you need to make, the most important difference is on how you as a team feel about **inline signatures**?

#### Subjective readability of inline method signatures

Some developers find Sorbet signatures to be a source of useful information due to them being very compact. They lack the semantic information that you usually find in, for example, YARD comments. However, if majority of the team has this stance, that is a big reason for choosing Sorbet with the default setup of inline signatures. This benefit is absent in the case of RBS or Sorbet in separate RBI files. This is going to be very subjective and you are unlikely to change someone's mind on it. Software is made by people and people's preferences are going to affect their productivity. So, it matters.

RBI files are just regular Ruby without method bodies and are therefore more verbose than RBS which is a separate syntax designed just for signatures. This all means that if you are going to exclusively write signatures in a separate file, you will be more efficient using RBS and you should choose RBS. If you like inline signatures then Sorbet seems like the better choice at the moment.

Try using both on a few key files in the project and make this decision based on what the majority of people on your team prefer.

## Conclusion

Whatever you pick in the end, please write about your experience so we can learn as a community!

Have you found this evaluation useful? Do you think there are criteria that I missed? Please let me know in the comments below.

## Footnotes

[^1]: I wrote about the details of my experiment and the results in [Experiment: Fully adding Sorbet and RBS to a small project](/experiments/experiment-gradual-typing)
[^2]: Shopify wrote about it in [Adopting Sorbet at Scale](https://shopify.engineering/adopting-sorbet){:target="_blank"}. Details of experiment results start under the subtitle "Benefits Realized, Even at typed: false". Their results are somewhat in line with what I found in [my experiment](/experiments/experiment-gradual-typing).
[^3]: The article ["An empirical comparison of C, C++, Java, Perl, Python, Rexx, and Tcl"](https://page.mi.fu-berlin.de/prechelt/Biblio/jccpprt_computer2000.pdf){:target="_blank"} is a bit older (from 2000) so it should be taken with a grain salt as we had a lot of development since then, especially in static language tooling. It examines 80 implementations of the same problem in different dynamic and static languages. It finds that the dynamic languages were more productive, however, even more importantly, it finds that the difference between languages was smaller than differences between programmers working in the same language. In other words, _who_ is programming mattered more than _with what_.
[^4]: The article ["An empirical study on the impact of static typing on software maintainability"](https://www.researchgate.net/publication/259634489_An_empirical_study_on_the_impact_of_static_typing_on_software_maintainability){:target="_blank"} compares speed of development and a few other factors between Java as static and Groovy as dynamic representative. The experiment has 33 participants solving 9 different tasks. The paper has a few interesting findings but the main ones are: Java being more effective for finding type errors and there being no sigificant difference in the tasks of findings semantic errors. A very interesting finding is that a likely reason for reduced time in fixing type errors is reduced time navigating the codebase.
[^5]: The article ["Static vs. Dynamic Type Systems: An Empirical Study About the Relationship between Type Casts and Development Time"](https://www.researchgate.net/publication/254007140_Static_vs_Dynamic_Type_Systems_An_Empirical_Study_About_the_Relationship_between_Type_Casts_and_Development_Time){:target="blank"} has 21 subjects solving programming tasks in Java and Groovy. To quote the paper: "The result of the study is, that the dynamically typed group solved the complete programming tasks significantly faster for most tasks - but that for larger tasks with a higher number of type casts no significant difference could be found."
[^6]: The article ["A Large Scale Study of Programming Languages and Code Quality in Github"](https://web.cs.ucdavis.edu/~filkov/papers/lang_github.pdf){:target="_blank"} examines 729 projects from Github and estimates code quality by examining commit history looking for commits that address defects. It finds that static typing is better than dynamic. However, the authors are quick to point out: "It is worth noting that these modest effects arising from language design are overwhelmingly dominated by the process factors such as project size, team size, and commit size."
[^7]: Stripe worked on an ahead of time compiler which would have taken advantage of types and you can even see an [unfinished version in the source code](https://github.com/sorbet/sorbet/tree/master/compiler/){:target="_blank"} but it was abandonded due to not being valuable enough internally. You can hear more about it [in this Changelog podcast episode, starting at 13:45](https://changelog.com/podcast/548#t=13:45){:target="_blank"}
[^8]: This [changelog episode has a very interesting discussion specifically about metraprogramming, starting at 19:57](https://changelog.com/podcast/548#t=19:57){:target="_blank"}. In short, heavy use of metaprogramming in Ruby goes against the effort of introducing a type checker like Sorbet.

<script>
  function checkAnswer(answerDom) {
    let classList = answerDom.querySelector("i").classList;
    classList.remove("far", "fa-circle");
    classList.add("fas", "fa-check-circle", "checked");
  }

  function clearAnswer(answerDom) {
    let classList = answerDom.querySelector("i").classList;
    classList.remove("fas", "fa-check-circle", "checked");
    classList.add("far", "fa-circle");
  }

  function refreshResult(answers) {
    let count = 0;
    let result = 0;
    answers.forEach((questionDom) => {
      if(questionDom.answer != undefined) {
        count += 1;
        result += questionDom.answer;
      }
    });

    let resultDom = document.getElementById("quizResult");
    if (count < answers.length) {
      resultDom.innerHTML = "You have answered <b>" + count + " / " + answers.length + " questions</b>. Please answer all of them for the results.";
    } else {
      resultDom.innerHTML = "<b> You scored " + result + " points!</b> See below for what that means.";
    }
  }

  let answers = [];

  document.querySelectorAll("ul.task-list").forEach((questionDom) => {
    answers.push(questionDom);
    let points = 0;
    questionDom.querySelectorAll("li.task-list-item").forEach((answerDom) => {
      let answerPoints = points;
      points += 1;
      answerDom.addEventListener(
        "click",
        (_event) => {
          questionDom.answer = answerPoints;
          questionDom.querySelectorAll("li.task-list-item").forEach(clearAnswer);
          checkAnswer(answerDom);
          refreshResult(answers);
        },
        {passive: true}
      );
    })
  })
</script>
