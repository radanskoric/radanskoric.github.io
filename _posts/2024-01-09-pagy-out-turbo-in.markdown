---
layout: post
title: "Pagy Out, Turbo In: Transforming Pagination with Infinite Scrolling and Turbo"
date: 2024-01-09
categories: guest-articles
tags: rails turbo hotwire pagy pagination infinite-scrolling cursor
author: miha
---

_Radan here. This is a guest post by [Miha](https://mr.si/){:target="\_blank"}. He's been using [Hotwire tools](https://hotwired.dev/){:target="\_blank"} for a while on his side projects [Visualizer](https://visualizer.coffee/){:target="\_blank"} and [ECT Business](https://business.europeancoffeetrip.com/){:target="\_blank"}. For a recent feature enhancement he did he made extenstive use of Turbo. The work fits the theme of my blog so I was very happy when he suggested to write a guest article on it. Handing it over to Miha now._

## The problem with pagination

I recently made [a substantial update](https://visualizer.coffee/updates/visualizer-v4){:target="\_blank"} to my SaaS side project for coffee nerds, [Visualizer](https://visualizer.coffee/){:target="\_blank"}. I've been using [Pagy](https://github.com/ddnexus/pagy){:target="\_blank"} for pagination since day 1, since it is the best[^1] tool for the job out there. There were a couple of things bothering me about it, though: first, OFFSET pagination is slow, and second, it is not very user friendly to have to click through pages and pages of results to find what you're looking for.

### Wait, what? OFFSET/LIMIT pagination is slow?

If you're as naïve as I was, you might be surprised to hear that OFFSET/LIMIT pagination is slow. If not, feel free to skip this section.

In small tables you might not notice it, but as the table grows, OFFSETs get larger, and consequently, query times get longer. The problem is quite clearly explained in [the official documentation](https://www.postgresql.org/docs/16/queries-limit.html){:target="\_blank"}. TL;DR; being:

> The rows skipped by an OFFSET clause still have to be computed inside the server; therefore a large OFFSET might be inefficient.

Having a database table with over 1.7M rows, my users were definitevely experiencing this problem more and more. I was already looking for a way to solve it with cursor pagination, so I could basically do `WHERE field > N` and trust Postgres to do its magic. There is a [pagy-cursor](https://github.com/Uysim/pagy-cursor){:target="\_blank"} gem, but it's not first party, and I'm the kind of developer who doesn't like to add more dependencies unless I really have to.

## Lazy Turbo to the rescue

I've been using Turbo on Visualizer from the moment I heard about it. Diving into git history, I can see I started with [beta 1 on Jan 4, 2021](https://github.com/miharekar/visualizer/commit/ea5e0830f7abc2e63b525d20d77fd551bad00265){:target="_blank"}. I wasn't a heavy user by any stretch of the imagination, but whenever I did, it was simple and straightforward, and \_it just worked_.

As far as I remember, in October of last year, was the first time I used the [Turbo Lazy-loaded Frames](https://turbo.hotwired.dev/reference/frames#lazy-loaded-frame){:target="\_blank"}. I [introduced a tab-based panel](https://visualizer.coffee/updates/recent-grinder-settings-and-enjoyments){:target="\_blank"}, and I wanted to load the content of the other tabs only when the user clicked on them. All I had to do was

```erb
<%= turbo_frame_tag :recents, src: recents_shots_path, loading: :lazy do %>
  Loading...
<% end %>
```

When the user clicked on the tab, they would see the "Loading..." text for a split second[^2], and then the content would appear. No extra JavaScript required. Not even any extra handling on controller side. Just an erb template with a `<%= turbo_frame_tag :recents do %>` that replaced the content of the frame.

## DIY Lazy Infinite Pagination

One day, I had a thought: what if I would use the same technique to implement infinite scrolling? When user scrolls to the bottom of the page, I could replace the content of the frame with the next page of results and a new lazy turbo frame for the next set of results. And I could do it with cursors, removing the need for Pagy in the process. How hard could that be? 🤔

Turns out, not that hard at all. I started in one controller, then implemented it in all the places where I had pagination. I refactored it several times along the way, and here I'll present the final/current iteration.

At the heart of it is a simple helper method that takes a relation[^3], and returns a tuple of paginated results and a cursor. Here it is in its entirety with added explanations in comments:

```ruby
module CursorPaginatable
  def paginate_with_cursor(relation, items: 20, before: nil, by: :id)

    # Filter by cursor start value, if one is provided. If missing, we know we're on the first page.
    relation = relation.where(by => ..before) if before.present?

    # Order the relation by the cursor field, and limit it to `items + 1` records.
    # This is because we want to know if there are more records to load,
    # and we need to know that before we actually load them.
    # `reorder` is used in case relation already has an order we need to override.
    relation = relation.reorder(by => :desc).limit(items + 1).to_a

    # If we don't have more records, we can just return the relation as is.
    # If we do, we remove the last record because we only need its cursor value
    # so we can use it to load the next page.
    cursor = relation.pop.public_send(by) if relation.size > items

    # Return the current results and the next cursor value.
    [relation, cursor]
  end
end
```

Now, we can use this helper in our controller to paginate by the `start_time` attribute:

```ruby
class ShotController < ApplicationController
  include CursorPaginatable

  def index
    # Business logic:
    @shots = Shot.visible_or_owned_by_id(current_user&.id).includes(:user)
    @shots = @shots.non_premium unless current_user&.premium?
    # Calling the helper method:
    @shots, @cursor = paginate_with_cursor(@shots, by: :start_time, before: params[:before])
  end
end
```

This is all, but it can be even simpler. In `UpdateController`, for example, I don't need to do any business logic, so I can just do:

```ruby
@updates, @cursor = paginate_with_cursor(Update, items: 3, by: :published_at, before: params[:before])
```

There was a bit more work required on the frontend. First, I created the following shared partial:

```erb
<% if cursor %>
  <%= turbo_frame_tag "cursor", src: path, loading: :lazy do %>
    <%= inline_svg_tag "logo-loading.svg" %>
  <% end %>
<% else %>
  <%= turbo_frame_tag "cursor" %>
<% end %>
```

And then I called it from the index.html.erb view like this:

```erb
<%= render partial: "shared/cursor_loader", locals: { cursor: @cursor, path: shots_path(before: @cursor, format: :turbo_stream) } %>
```

If we have a cursor, we render a lazy turbo frame with a `src` attribute and a loading svg animation. If we don't, we render an empty turbo frame. The `path` is the path to the current page, with the cursor as a `before` parameter, and the format set to `turbo_stream`. This is important, because we want to render a turbo stream response, not a full HTML page. This is accomplished with a new index.turbo_stream.erb view:

```erb
<%= turbo_stream.append "shots" do %>
  <%= render @shots %>
<% end %>
<%= turbo_stream.replace "cursor" do %>
  <%= render partial: "shared/cursor_loader", locals: { cursor: @cursor, path: shots_path(before: @cursor, format: :turbo_stream) } %>
<% end %>
```

[Radan explained Turbo Streams before](/experiments/using-turbo-frame-streams-without-rails#using-turbo-streams){:target="\_blank"}, but basically, we're appending the rendered shots to the `#shots` html element, and replacing the `#cursor` element with a new turbo frame with the next cursor. That's why we have that `else` clause in the partial - we need to replace the loader with an empty frame when we're at the end of the results.

That's it!

![Infinite loading](/assets/img/posts/visualizer-infinite-loading.gif)

There are many more changes in the [v4 pull request](https://github.com/miharekar/visualizer/pull/96){:target="\_blank"}, and you're more than welcome to check them out.

## Conclusion

With just a couple of lines of Ruby and a few lines of HTML/ERB, and **no JavaScript**, I was able to implement infinite loading with cursors on top of Turbo. It's faster, it's simpler, it gets rid of the Pagy gem dependency[^4], and it's a better user experience. What's not to like?

It truly is a great time to be a web developer.

## Footnotes

[^1]: In my opinion, and based on benchmarks
[^2]: Usually for ~30ms
[^3]: Or just a model class, if you want to paginate all records
[^4]: Not really, I still need it for API pagination 😒
