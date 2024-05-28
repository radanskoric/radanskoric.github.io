---
layout: post
title: "How to reuse the same page in different Turbo Frame flows"
date: 2024-05-24
categories: articles
tags: rails hotwire turbo turbo-frames
---

## The problem

Consider the following examples on a Rails application that is using [Turbo Frames](https://turbo.hotwired.dev/handbook/frames){:target="_blank"}.

**Example 1**: Clicking the login link brings up a login form in a popup modal. You can also navigate to registration or forgot my password pages within the same modal. *Imagine you have a new requirement:* also support the login/registration pages as standalone pages that can be linked to directly.

**Example 2**: You're listing products as card UI elements and within each card you can navigate to different product details. *Imagine you have a new requirement:* add a comparison screen where on the left you can show one product and on the right another, still being able to navigate their details in the same way.

What both examples have in common is:
- There's an existing feature that has the user moving through multiple pages inside the same Turbo Frame.
- You need to use the same pages in a frame that's in a different place in the UI.

The initial setup is a textbook example of using Turbo Frames. You render a turbo frame on the main page and the pages you are loading render the same turbo frame. However, the additional requirement means you now have to load the same page in two different Turbo Frames.
The content is the same, but it could be placed in two different places in the UI.

If you hard code the id of the frame you can't have both pieces of the UI on the same page, since the frame id has to be unique on the page. But you need this in both examples. And, when Turbo fetches the content for a frame, it expects the response to contain a frame with the matching `id` or it will complain with **Content missing**.

You need to somehow dynamically determine the frame id.

## The solution

### Not great: pass a query parameter

You could pass a query parameter in the url.

In example 1 it might be `?popup=true` when the form is being loaded in the popup modal. And then in the view template:
```ruby
turbo_frame_tag (params[:popup] ? :popup_modal : :full_page)
```

 In example 2 it might be `?side=left` to indicate which side of the comparison screen is being loaded and then use that in the template:
```ruby
turbo_frame_tag (params[:side] || @product)
```
But you need to keep track of it through the code and need to make sure to always match the passed parameter to the frame it's in. It's not that complex but it's extra plumbing that would be best avoided.

### Great: use the Turbo-Frame request header

Fortunately, Turbo has your back. Every request where Turbo is expecting a response for a specific frame will have the id of that frame in the `Turbo-Frame` header on the HTTP request. Turbo-rails gem exposes it with the `turbo_frame_request_id` helper but if you're [using Turbo without Rails](/experiments/using-turbo-frame-streams-without-rails) you can also read the header directly.

With that, we can solve it in a similar way to passing a parameter but without all the extra plumbing.

For example 1:
```ruby
turbo_frame_tag (turbo_frame_request_id || :full_page)
```

And for example 2:
```ruby
turbo_frame_tag (turbo_frame_request_id || @product)
```

Note that for both of them we're echoing the frame id if it is specified. In both of these cases it works out as expected because even if we start with a different usage, it will be carried forward correctly. Turbo requests a specific frame id back and if you're rendering only one frame in your response, you can always echo it when it's provided.

But you can't do that if you're simplifying your logic by rendering multiple frames within the same response and relying on Turbo to pick the one it needs. You would end up with multiple frames with the same id in your response. In that case, make the code more intentional by checking the value before echoing it, for example:
```ruby
turbo_frame_tag (turbo_frame_request_id.in?(%w[left right]) ? turbo_frame_request_id : @product)
```
Notice that `turbo_frame_request_id` is a String, not a Symbol.

At this point it's better to move that logic into a helper, but that is left as an exercise for the reader.
