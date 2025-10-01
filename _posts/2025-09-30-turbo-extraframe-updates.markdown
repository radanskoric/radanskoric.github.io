---
layout: post
title: "How to elegantly update other UI when a Turbo Frame is updated"
date: 2025-09-29
categories: articles
tags: rails hotwire turbo turbo-frames
image: /assets/img/posts/extraframe-improved.gif
---

Turbo Frames are great for carving out a part of the UI and having it update via normal server interaction. If all that needs to be updated is this specific part of the UI and nothing else then standard Turbo Frames usage is all you need. It's great for localised changes.

However, sometimes you also need to update some other part of UI: for example a menu, a counter, a title or some other piece of UI that is **physically outside the Turbo Frame** but **logically belongs to the frame content**. Since this content belongs to the frame but sits outside it, I will call it **extraframe content**[^1].

Certainly some cases will require a frontend solution. But before you reach for JavaScript, let me show you a **simple technique** that covers many cases and is implemented completely in the backend, using Rails.

## The problem

I recently used this technique when working on the web version of my book ["Master Hotwire"](https://masterhotwire.com/){:target="_blank"} and I'll use it as an example to explain it.

When browsing chapters, there's a sidebar with the chapter list. A `chapter_content` Turbo Frame takes up most of the screen and renders the current chapter content. The sidebar chapter links target that `chapter_content` turbo frame.

When you click the link, the frame updates. All good. Except, I want to change the currently highlighted sidebar chapter, the extraframe content. This is the effect I want to implement:

![Extraframe content being updated with the frame](/assets/img/posts/extraframe.gif)

Notice that title highlight updates when I click. That doesn't happen by default since only the frame content gets updated. All that is really needed is to remove the highlight CSS classes from the current chapter and add them to the just clicked chapter. A simple Stimulus controller could do this. However, for reasons that will become apparent if you read the article until the end, I don't want to do it like this. I want to keep the logic fully on the backend.

## The solution

> The code snippets demonstrating the solution are extracted from the actual code, the book's web version which is a custom Rails app. But, I've simplified them to make the point clearer. I'm using Tailwind so the biggest change is omitting all the tailwind classes.
{: .prompt-info }

First of all, the view layout contains a rendering slot for the sidebar content:
```erb
<body>
  <aside>
    <%= yield :sidebar %>
  </aside>
  <main>
    <%= yield %>
  </main>
</body>
```
{: file="app/views/layouts/application.html.erb"}

The idea is to render into the `sidebar` slot for the full page load. However, for the turbo frame request we'll emit a turbo stream that will update the sidebar in place. The key implementation part is a small view helper implementing the key logic. Before I get to the helper I'll show you the other views. This will make the helper easier to understand.

In the view for the chapter page I render the turbo frame with the sidebar content and the chapter content:
```erb
<%= turbo_frame_tag :chapter_content do %>
  <%= render 'sidebar', chapters: @chapters, chapter: @chapter %>

  <article>
    <h1><%= @chapter.full_title %></h1>
    <%= render_chapter(@chapter.content) %>
  </article>
<% end %>
```
{: file="app/views/chapters/show.html.erb"}

The `_sidebar` partial renders so that the current chapter is highlighted. This is where I use the new helper (that I'm calling  `turbo_aware_content_for`):
```erb
<%= turbo_aware_content_for :sidebar do %>
  <nav id="sidebar">
    <ul>
      <% chapters.each do |chap| %>
        <li>
          <%= link_to chap.full_title,
                      chapter_path(chap),
                      class: "link #{'highlight' if chap == chapter}",
                      data_turbo_frame: :chapter_content
                      %>
        </li>
      <% end %>
    </ul>
  </nav>
<% end %>
```
{: file="app/views/chapters/_sidebar.html.erb"}

Finally, this is the new helper:
```ruby
  def turbo_aware_content_for(name, &block)
    if turbo_frame_request?
      turbo_stream.replace(name, method: :morph, &block)
    else
      content_for(name, &block)
    end
  end
```
{: file="app/helpers/application_helper.rb"}

Here's how it works:
- If it's a turbo frame request it emits a turbo stream that replaces the current sidebar HTML with the new one. It uses morphing to make the update smoother. Both [replace](https://turbo.hotwired.dev/reference/streams#replace){:target="_blank"} and [update](https://turbo.hotwired.dev/reference/streams#update){:target="_blank"} turbo stream methods support using the morphing algorithm for the update. This is crucial in keeping the sidebar scroll position unchanged while we're clicking.
- If it's a regular request, it uses `content_for` to insert it in the usual place in the `sidebar` view slot.

> Two technical details are very important:
> 1. It's critical that the sidebar renders **inside the turbo frame**. It makes no difference for the full page request but for the turbo frame request it's using [the fact that streams will work if rendered into the HTML](/articles/stream-actions-inside-regular-html).
> 2. The helper assumes that there's an element rendering with the matching `id` (in this case the `nav` element with id `sidebar`). Create the top-level element inside the helper to avoid this implicit requirement. In this case I opted not to do that but if it makes sense for your case go ahead and expand the helper to also generate the wrapper element. By having the helper generate the wrapper, it's impossible to use it incorrectly.
{: .prompt-warning }

## The power of this approach

After I finished and deployed this, I made a UI improvement that nicely demonstrates the benefits of this approach. I wanted to also render the subtitle list when the chapter opens to allow readers to jump directly to a subtitle.

This is how the UI looked after the change:

![Sidebar showing more complex update](/assets/img/posts/extraframe-improved.gif)

If we used the pure frontend solution, we'd now face some *not so trivial* changes to make it work.

With the "turbo aware content for" approach, the first step is to update the sidebar partial to render the subtitle list for the current chapter:
```diff
      <% chapters.each do |chap| %>
        <li>
          <%= link_to chap.full_title,
                      chapter_path(chap),
                      class: "link #{'highlight' if chap == chapter}",
                      data_turbo_frame: :chapter_content
                      %>
+         <% if chap == chapter %>
+           <ul class="subheadings">
+             <% chapter.subheadings.each do |subheading| %>
+               <li>
+                 <%= link_to subheading[:text],
+                             "##{subheading[:id]}",
+                             %>
+               </li>
+             <% end %>
+           </ul>
+         <% end %>
        </li>
      <% end %>
```

And the second step ... well actually, there's no second step. *We're done!* Because of everything else that is set up, after this change it all works as expected. When the chapter link is clicked, frame is loaded, the turbo stream renders the new sidebar content which is smoothly updated using morphing. The full page load also just works.

To make it nicer I added some CSS transitions to have the subheadings expand out when the element is created and that's it.

With this technique any change in the extraframe content only requires changing how that content is rendered on the server. The setup takes care of everything else.

[^1]: "extra" as a prefix literally means "outside"
