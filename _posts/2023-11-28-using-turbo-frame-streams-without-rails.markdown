---
layout: post
title:  "Using Turbo Frames and Streams without Rails"
date:   2023-11-28
categories: experiments
tags: rails turbo hotwire how-stuff-works
---

Recently I've been using Turbo [frames](https://turbo.hotwired.dev/handbook/frames){:target="_blank"}
and [streams](https://turbo.hotwired.dev/handbook/streams){:target="_blank"} more and wanted to really
understand how they work. To do that I set out to rebuild a very simple To-Do application
(*peak* originality!), using Turbo but without Rails or
[turbo-rails](https://github.com/hotwired/turbo-rails){:target="_blank"} gem. I did that using Sinatra[^1].
As you'll see, it was really simple. So simple I wondered if it's worth a blog post.
But then I realised that is kind of interesting in itself.

This is not an intro-to-turbo post and I am assuming you already have some *basic* familiarity with **using** Turbo
in a Rails application and just want to know more about it. If you are just starting to use it I would recommend
[the official handbook](https://turbo.hotwired.dev/handbook/introduction){:target="_blank"} and this
[introductory blog post](https://medium.com/@alexischvez/hotwire-supercharged-rails-forms-with-turbo-6de79bb9e374){:target="_blank"}
(there are other excellent posts but I first read this one and found it easy to follow).

## The Sinatra application

The application will be a super simple task manager that supports:
- Presenting a list of tasks, each composed of just a text description.
- Creating new tasks.
- Editing existing tasks.
- Deleting tasks.

And it will all work without page reloads, like a real SPA[^2]. To simplify things the records will just be stored in memory, meaning they will go away once the app server stops running. But that's enough.

I'm speaking in future tense but you've probably guessed that I've already built it. It lives completely in a single file and it's just 151 lines of code, 98 if you ignore blank lines and comments, 38 if you also ignore inline HTML templates.

It lives in this github gist: [https://gist.github.com/radanskoric/9bdaa8f64289b00b3cfb1d35cd889196](https://gist.github.com/radanskoric/9bdaa8f64289b00b3cfb1d35cd889196){:target="_blank"}.

*If you are comfortable* reading the code, I would suggest you **browse it now and then come back** for the explanations that follow. *If you are not comfortable* reading the code I would suggest still read it and consider it as a practice ;) . I kept the code very straight forward and I've tried to explain it generously with comments. You don't need to read every line carefully, scanning it to get a sense of how it works will be enough.

## Using Turbo Frames

Rails usually does a lot of work behind the scenes to weave its magic in service of *complexity compression*, but in this case Rails actually needs to do very very little. So to use turbo without it you also need to do very little. What is needed is:
1. A scheme to generate consistent ids for turbo frames so Turbo correctly knows what content is meant to go where.
2. Wrap all relevant segments of HTML in `<turbo-frame id="my_consistent_id">` tags.
4. Render the response with `content-type: text/html`. Every framework, including Sinatra, will do that for you by default.

Consider the very first thing we needed for our application: an "Add task" link that loads displays a new task form inline.

For that, we have the html on the main page:
```html
<a data-turbo-frame="new_task_frame" href="/tasks/new">Add task</a>
<turbo-frame id="new_task_frame"></turbo-frame>
```
And the response rendered by the new task endpoint:
```html
<turbo-frame id="new_task_frame">
  <h2>New task</h2>
  <form action="/tasks" method="post">
    Task: <input type="text" name="description"/>
    <input type="submit" value="Create Task"/>
  </form>
</turbo-frame>
```

What makes it work is that ids match. When turbo follows a turbo frame link like above it will look for a matching turbo frame in the response HTML, take its content and replace the content of the frame in the page.

This is very simple but also a very powerful example of how rails mantra of ["convention over configuration"](https://rubyonrails.org/doctrine#convention-over-configuration){:target="_blank"} removes complexity. This is also why Rails providing a consistent system for those ids is so valuable. A lot of complexity goes away because the code is making this assumption on ids being consistently generated.

Consider how we are wrapping the rendered html of a specific task. We're using:
```ruby
<turbo-frame id="task_#{id}">...</turbo-frame>
```
And then the endpoint that returns the form for editing it, wraps the form in exactly the same tags. Our convention here is to use `"task_#{id}"` . Auto generating the ids is pretty much [the only logic that Turbo adds beyond directly generating the tag html](https://github.com/hotwired/turbo-rails/blob/4eb4e928e30be8cd537af8073f98b80ddea4a578/app/helpers/turbo/frames_helper.rb#L42){:target="_blank"}. It relies on [ActionView::RecordIdentifier#dom_id](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_id){:target="_blank"} to generate the ids in a consistent way.

## Using Turbo Streams

When simply replacing the content of a specific turbo frame is not enough we can turn to turbo streams.

To use them we need to change the response of our endpoint in two ways:
1. Change the `Content-Type` header to `text/vnd.turbo-stream.html`. Without this, Turbo will **not** attempt to execute any stream instructions. Sinatra will respond with the default content-type of `text/html` and Turbo will look for a turbo-frame tag and then fail when it doesn't find it.
2. Render the correct HTML for the turbo stream actions.

For the latter, consider the response from the task creation endpoint:
```html
<turbo-stream action="append" target="tasks">
  <template>
    Task rendering ommitted ...
  </template>
</turbo-stream>
<turbo-stream action="update" target="new_task_frame">
  <template></template>
</turbo-stream>
```

We are doing two things:
1. Appending the newly created task to the list of tasks on the main page.  For that we used the `append` action and for the target used the id `tasks` which happens to match a `turbo-frame` on main page that contains the list of all tasks.
2. Removing the form for the new task since we no longer need it. For that we are using `update` on the before mentioned `new_task_frame` and providing an *empty* template. This effectively clears it.

And that's pretty much it. Turbo will see the response content type, look for `turbo-stream` tags and run the action using the `target` and `template` data provided. There are a total of **7 actions** you can use, and you [can consult the official streams reference](https://turbo.hotwired.dev/reference/streams#the-seven-actions){:target="_blank"} for the full list.

If you like these kind of breakdowns, you might also enjoy [my breakdown od how rails async database queries work](/articles/understand-rails-async-db-queries) or [a deep dive into turbo morphing](/articles/turbo-morphing-deep-dive). If you subscribe I will also send you my [printable Turbo 8 cheat-sheet](/cheatsheet):
<script async data-uid="c481ada422" src="https://thoughtful-producer-2834.ck.page/c481ada422/index.js"></script>

## Conclusion

The backend story of Turbo Frames is very simple. I'm not sure what I was expecting but for such an important feature I was expecting a little bit more. The magic is mostly in the frontend.

And I think that is excellent! Every abstraction becomes riskier to use with every assumption it is making. Complex assumptions increase the risk more than simple ones. Turbo frames backend logic makes just a few very simple assumptions, with the biggest being a consistency and uniqueness of turbo frame ids. Even a large app, as long as it has clear internal conventions, will not have a problem fulfilling that assumption.

## Footnotes

[^1]: At first I wanted to go really bare bones and started writing a [pure rack application](https://github.com/rack/rack#usage){:target="_blank"} directly in `config.ru`  file but quickly realised I'm basically recreating a very bad alternative to [Sinatra](https://sinatrarb.com/){:target="_blank"} so I moved to it instead.

[^2]: Single Page Application. It's interesting that it has come to mean "a javascript heavy application" when in reality that's an implementation detail. The only meaning that the user cares about is "highly interactive and fast interface".
