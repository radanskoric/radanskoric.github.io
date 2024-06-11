---
layout: post
title: "How to refresh the full page when submitting a form inside a Turbo Frame?"
date: 2024-06-11
categories: articles
tags: rails hotwire turbo turbo-frames forms
---

Let's consider some UI examples and mentally check if we can get the Turbo magic by just slapping a Turbo Frame in the right place. By that I mean: can we make the implementation really **as simple as plain HTML** with *"the speed of a single-page web application"*:
- Navigating full pages of content. ✅
- Links that change a fixed different part of UI, like tabs. ✅
- Navigating a self contained small part of the UI like an image gallery. ✅
- Inline editing of elements in a list. ✅
- Submitting a form shows errors or modifies the full page, like adding an item to a list. ❌
- ...

Huh, that last one is relatively common, why is it not straightforward?

All we want there is to have a list and a form that can both show errors and add to the list when there are no errors. It's by no means **hard**, but it's not trivial and it sounds like it should be. The problematic part is that **the logic** for which of those two actions are needed is **dynamically** determined **on the server**.

The general problem description would be: **having a Turbo Frame that might update itself or might update the full page based on information only available after processing the request on the server**. Turbo has a number of mechanisms to **statically** define the target of a link click or form submission in the page itself, but it's not as easy when we need to control it from the server. It's confusing enough that there's [a long standing open issue on Turbo Github repo, with many comments]`(https://github.com/hotwired/turbo/issues/257){:target="_blank"}`.

I've faced this problem myself and used different solutions but I wanted to find the best one so I went through that whole thread. The answer: **it depends**. You don't have to go through the thread, here are all the techniques with their tradeoffs.

## Techniques

I am assuming you're using Rails but solutions should be easily transferable to a different backend framework.

### Just add target="_top"  to the Turbo Frame

It's as simple as creating the frame with "_top" as its target:
```ruby
turbo_frame_tag :target_top, target: "_top"
```
And voila, the form submission will navigate the full page rather than just the frame.

The problem with that is that it will **always** navigate the full page. Even if there are errors that you want to render inside the frame, Turbo will attempt to navigate the full page, breaking the process. So this is not viable if you need to also show errors. But, if you know every form submission is successful, this is by far the simplest approach.

**Use when** you know every submit will succeed.

### Emit a refresh action on a successful submit

The idea is that on a successful submit you emit a [refresh stream action]`(https://turbo.hotwired.dev/reference/streams#refresh){:target="_blank"}` instead of a redirect like you might for a plain HTML page. This action was added when [morphing](/articles/turbo-morphing-deep-dive) functionality was introduced and it causes Turbo to "refresh" the current page. Depending on your other configuration this will mean fetching the full page again and then either *replacing* the content of the `body` tag or *morphing* it. Either way, the result will be that the full page will be updated in an efficient manner by Turbo.

The neat part is that the error part doesn't need to change at all, it can stay identical to how it would be for the plain HTML approach. This is how it might look for an endpoint where we create a record that has validations:
```ruby
def create
  @record = Record.create(record_params)
  if @record.valid?
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
      format.html { redirect_to :index }
    end
  else
    render :new # Rely on the form rendering showing errors
  end
end
```
An important assumption of this approach is that you want to modify the current page. Next approach covers the case when that's not true.

**Use when** you need to show errors and the happy path leads back to the same page.

### Use custom full page redirect stream action

If instead of modifying the current page you want to either show errors or move to a different page, you'd normally use a redirect. But this will not work with Turbo because it would redirect only the Turbo Frame. If you want to redirect the full page you'll need to create a [custom stream action]`(https://turbo.hotwired.dev/handbook/streams#custom-actions){:target="_blank"}`. Custom stream actions allow us to expand the default list of stream actions that Turbo provides.

First define a new stream action for the full page redirect:
```javascript
Turbo.StreamActions.full_page_redirect = function() {
  document.location = this.getAttribute("target")
}
```
And then, similar to above example with the refresh action, respond with it when handling a turbo request:
```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: turbo_stream.action(:full_page_redirect, redirect_path)
  end
  format.html { redirect_to redirect_path }
end

```

**Use when** you need to show errors and the happy path leads to a different page.

### Rely on turbo-visit-control meta tag

A page can advertise to Turbo that it always needs to be loaded as a full page load. It does this with a special [turbo-visit-control]`(https://turbo.hotwired.dev/reference/attributes#meta-tags){:target="_blank"}` meta tag. It's as simple as calling a helper inside the view template:
```erb
<% turbo_page_requires_reload %>
```
When you respond with a redirect to a page with this meta tag, Turbo will:
1. Fetch the page.
2. Before attempting to update the Frame, check for this meta tag.
3. If it finds the meta tag it will abandon Frame update and instead issue a full page reload to the same url.

This is very simple if the destination page always requires to be a full page load. The downside is that it will cause the page to be loaded **twice**. However, this is a good tradeoff if the scenario happens rarely.

A common example is the login page. If you have authentication that might expire, it means that any visit might redirect to the login page. In that case it makes perfect sense to place this meta tag on the page.

**Use when** the target page must always be a full page load.

### Do not use a Turbo Frame

If you've been paying attention you'll notice that the above solutions all make the sad path, an error showing on the form, very simple, and the small added complexity is on the happy path. This often makes sense but if for you it's really important that the happy path is the simple one you have another option.

You can not use a Turbo Frame at all. The happy path is then literally identical to the plain HTML approach, since it really is a plain HTML form submission.

But you still want to show errors inline. The trick is to wrap the form in a plain element with an id and then use stream actions to replace it, effectively simulating a frame update in the case of an error.

First, in the view you use a plain `div` instead of a Turbo Frame:
```erb
<div id="<%= dom_id(record, "form") %>">
  <%= form_for record do |f| %>
    ...
  <% end %>
</div>
```
and then in the controller use a regular redirect for the happy path and a stream action to [replace]`(https://rubydoc.info/github/hotwired/turbo-rails/main/Turbo/Streams/TagBuilder#replace-instance_method){:target="_blank"}` the form content in case of an error:
```ruby
if @record.valid?
  redirect_to :index
else
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(@record, "form"),
        partial: "records/form",
        locals: {record: @record}
      )
    end
    format.html { render :new }
  end
end
```

As you can see, the reason that we opted before to keep the error path simple is that it *usually* results in overall simpler code. However, some cases might be different and then this can be a good choice.

**Use when** your happy path flow is unusually complex and this makes it much simpler.

## Why is it like this and when will it be improved?

It's fair to ask, why doesn't Turbo just work here? Is it really so hard? There are a number of heuristics we could use but they all have a problem of being correct in many cases but also being wrong in other, perfectly reasonable, cases.

We can't make this logic fuzzy, Turbo needs to be predictable. And since a reasonable logic has not been found yet, we have to be explicit about it. And this is the direction that most promising solutions suggested in that [Github Issue]`(https://github.com/hotwired/turbo/issues/257){:target="_blank"}` explore: how to allow the developer to be explicit in the simplest way possible. However, a satisfactory solution that actually works has not been found yet. Most promising ones are limited by what can be done in the browser. So we might have to wait for browser evolution until being able to get a truly satisfactory solution. At this point, I'm leaning towards this being something that will always require us to add a little extra complexity.

### Break out of the frame when missing matching frame?

However there is one area where Turbo might offer a bit more out of the box. What to do when the response (or the page to which we redirected) **doesn't** contain the target turbo frame? Currently it results in an error so it's not possible that anyone is relying on it as a feature. Turbo could instead treat it as a signal to update the full page. This could simplify some of the cases.

This might be a real future *partial solution*. It even has [DHH endorsing it]`(https://github.com/hotwired/turbo/issues/257#issuecomment-1188397132){:target="_blank"}`.

The good news is that, if you want to get this behaviour today, all you need to do is add this global listener to the [frame-missing event]`(https://turbo.hotwired.dev/reference/events#turbo%3Aframe-missing){:target="_blank"}`:

```javascript
document.addEventListener("turbo:frame-missing", function (event) {
    event.preventDefault()
    event.detail.visit(event.detail.response)
})
```

Do you have an alternative solution that I missed or a different take on it? Please share it in the comments below!
