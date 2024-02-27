---
layout: post
title:  "Turbo 8 morphing deep dive - how does it work?"
date: 2023-12-12
categories: articles
tags: rails turbo hotwire how-stuff-works morphing
mermaid: true
---

_This is part 1 of a 2 part series on how Turbo 8 works. [Part 2](/articles/turbo-morphing-deep-dive-idiomorph) covers the idiomorph algorithm[^3] and this article covers the rest._

Turbo 8 and the morphing functionality that was [presented at the first Rails World](https://www.youtube.com/watch?v=m97UsXa6HFg){:target="_blank"} is looking like a strong contender for the most magical Rails feature yet! And as with every *Rails magic* feature I'm part excited for all of the development time savings I'm about to reap and anxious for all of the time I will waste figuring out why it stopped working. In my 15+ year long professional career dominated by Rails projects I've experienced both. Thankfully it was mostly the former but the latter was quite painful and I would really like to eliminate it. My favourite way to battle it is to pull the curtain on the magic. I'm not scared once I've seen the wizard behind the curtain pulling the ropes.

This is not an introduction on how to use Turbo Morph in your app, but a teardown of how it works under the hood. For the introduction to how to use it I would recommend [Turbo 8 in 8 minutes](https://fly.io/ruby-dispatch/turbo-8-in-8-minutes/){:target="_blank"}.

## Magia ex machina

A picture is worth a thousand words so a diagram must be worth at least five hundred! Let's imagine two users, good old Alice and Bob, looking at a list of tasks in a todo application (same setup as in my article on [using turbo frames and streams without rails](/experiments/using-turbo-frame-streams-without-rails)).

This sequence diagram covers the scenario of Bob creating a new task while Alice also has the list open and by the end of the diagram sees it update live in front of her:
```mermaid
sequenceDiagram
  participant A as Alice's browser
  participant B as Bob's browser
  participant W as Web server
  participant J as Background Worker
  participant T as Turbo::StreamsChannel
  B->>W: Submit form
  activate W
  W->>J: Create<br/>broadcast job
  W->>B: Return HTML
  deactivate W
  B->>B: Morph page
  J->>T: Broadcast: refresh<br/>stream action
  T->>B: Refresh<br/> (ignored)
  T->>A: Refresh
  A->>W: Fetch page
  A->>A: Morph page
```
Did you get how it all works? You did? Really? I mean ... I did prepare a more in depth explanation but if you don't need it, <small>*not like I worked on it for a few hours*</small> ... No, no, it's fine ... You'd like to read it anyway? You sure? Ok then!

### Bob's browser -> Web server

Bob submits the form which is handled by the Rails controller in a regular way saved to the database. The magic starts to happen when the model callbacks trigger the codepath to broadcast a refresh ...

### Web server -> Background worker

If you're using morphing the model will use [broadcasts_refreshes](https://github.com/hotwired/turbo-rails/blob/4eb4e928e30be8cd537af8073f98b80ddea4a578/app/models/concerns/turbo/broadcastable.rb#L146-L150){:target="_blank"} which unrolls into:
```ruby
stream = model_name.plural
after_create_commit  -> { broadcast_refresh_later_to(stream) }
after_update_commit  -> { broadcast_refresh_later }
after_destroy_commit -> { broadcast_refresh }
```

These calls ultimately schedule a background job[^1], specifically [Turbo::Streams::BroadcastStreamJob](https://github.com/hotwired/turbo-rails/blob/main/app/jobs/turbo/streams/broadcast_job.rb){:target="_blank"}. The only thing that the job does is perform the broadcast using [ActionCable broadcast method](https://api.rubyonrails.org/v7.1.2/classes/ActionCable/Server/Broadcasting.html#method-i-broadcast){:target="_blank"}.

#### What is being broadcast

To broadcast a message you need a stream name and content to be broadcast.

The stream name is constructed from objects which are triggering the update. For a single record the logic reduces to calling `record.to_gid_param` which is [a method from the globalid gem](https://www.rubydoc.info/gems/globalid/GlobalID/Identification#to_gid_param-instance_method){:target="_blank"} and for multiple records [the gid params are concatenated](https://github.com/hotwired/turbo-rails/blob/4eb4e928e30be8cd537af8073f98b80ddea4a578/app/channels/turbo/streams/stream_name.rb#L26){:target="_blank"}.

> In absence of `to_gid_param` the actual logic [falls back to using](https://github.com/hotwired/turbo-rails/blob/main/app/channels/turbo/streams/stream_name.rb#L28) `to_param`  which is implemented by `String`. This mean that you don't really need an AR record to broadcast. You can manually construct the callbacks using any string:
``` ruby
# In the model
after_update_commit -> { broadcast_refresh_later_to("Beeblebrox") }
# In the view
turbo_stream_from "Beeblebrox"
```
{: .prompt-tip }

The stream name is then signed using `Turbo.signed_stream_verifier#generate`to produce a signed name. The verifier is an instance of [ActiveSupport::MessageVerifier](https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifier.html){:target="_blank"}, i.e. a standard Rails mechanism for preventing man in the middle attacks.

Since all we're broadcasting is a message that the page needs to be refreshed, the content is very simple, it's just a turbo stream refresh tag rendered using [turbo_stream_refresh_tag helper](https://github.com/hotwired/turbo-rails/blob/4eb4e928e30be8cd537af8073f98b80ddea4a578/app/helpers/turbo/streams/action_helper.rb#L38){:target="_blank"} and looks like this:
```html
<turbo-stream
  request-id=\"ca519ab9-1138-4625-abc2-6049317321a9\"
  action=\"refresh\">
</turbo-stream>
```
The request id is a new mechanism added specifically for refresh actions. It is a unique id [generated on the frontend](https://github.com/hotwired/turbo/blob/ac0035982e2f8a6a72055acc954d813330afa771/src/http/fetch.js#L12){:target="_blank"}, and passed to the server via `X-Turbo-Request-Id` header. The backend simply passes it on to the refresh tag. The frontend stores it in an array and if a refresh action comes with an already stored request id it is ignored. As far as I could make it, the purpose is to **avoid a refresh being caused by your own action** since you should get the content with the regular HTTP response.

#### Debouncing the brodcasts

Before the broadcasting job is actually scheduled, there's a little optimisation happening which is important to understand: **The creation of the background job goes through a debouncer object to avoid brodcasting multiple unnecessary refresh actions when we execute multiple updates during the same HTTP request.**

The debouncer is an instance of [Turbo::Debouncer](https://github.com/hotwired/turbo-rails/blob/main/app/models/turbo/debouncer.rb){:target="_blank"} scoped to the thread . Under the hood it relies on [Concurrent::ScheduledTask](https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/ScheduledTask.html){:target="_blank"} from concurrent-ruby gem. In short, it's an object that *ensures that an action will run only once in a given period of time*. Debouncer works by cancelling the current broadcast and scheduling a new one with a delay. The default delay is 0.5 seconds. Unlike with throttling which runs immediately and then rejects subsequent requests for a certain period, debouncer runs once at the end of the delay. This means that usually[^2] the actual broadcast will happen half a second after the last database update you make.

### Turbo::StreamChannel -> Browsers

The HTML will contain a tag to specify the stream on which they will listen for stream actions:
```html
<turbo-cable-stream-source
  channel=\"Turbo::StreamsChannel\"
  signed-stream-name=\"SIGNED_NAME">
</turbo-cable-stream-source>
```
In reality, in place of `SIGNED_NAME` there will be a name generated and signed in the same way as described above, when sending the refresh action.

Turbo will find that tag and connect via websockets to the channel and listen for messages on the stream. When the refresh message arrives, it triggers a new [refresh action](https://github.com/hotwired/turbo/blob/ac0035982e2f8a6a72055acc954d813330afa771/src/core/streams/stream_actions.js#L37-L39){:target="_blank"} code path.  This in turn will  resolve to calling idiomorph[^3] to perform the [actual morphing from the current page into a new page](https://github.com/hotwired/turbo/blob/ac0035982e2f8a6a72055acc954d813330afa771/src/core/drive/morph_renderer.js#L28C1-L39){:target="_blank"}. Turbo is here delegating all the heavy lifting to idiomorph with a few important modifications using standard idiomorph options:
- It will not add an element that has an `id`, a `data-turbo-permanent` attribute and is already present on the page. This prevents idiomorph from modifying elements we tagged as permanent.
- It will not morph or remove an element if any of the following is true:
    - The element is marked with `data-turbo-permanent` attribute
    - The frame we are currently updating is not a morphing remote turbo frame. Morphing remote turbo frame is a turbo frame with remote source that has refresh attribute set to `morph`. This is for the case where we're updating a frame, not the whole page.
    - The node we are about to replace is a morphing remote turbo frame. These are reloaded separately after the morphing has finished.
At this point the flow is done and the update has finished.

This is a 2 part article. The 2nd part, which covers how idiomorph works can be found [here](/articles/turbo-morphing-deep-dive-idiomorph).

## Conclusions

For me the main takeaways are:
- I don't need to worry about spawning too many broadcast messages on the same stream, the framework handles that. However, I should think for a moment if a specific model really needs to broadcast at all as refreshes from different models are not aggregated.
- The user initiating an action will not do a refresh but will instead morph with what I send it back and I just need to make sure that is the same as what the other users will fetch when refreshing.
- I can broadcast to a collection without a parent by picking a string name and constructing the refresh callbacks myself.
- I can exclude sections of the page from morphing by using `data-turbo-permanent` attribute.
- The approach clearly has nuance to it and more corner cases that need to be handled will arise but it has a solid and straight forward logic so I'm optimistic about its future.

The real meat of the feature is the idiomorph[^3] library and you can find its deep dive [here](/articles/turbo-morphing-deep-dive-idiomorph).
If you are struggling to debug an issue you have with the morphing feature, I also wrote an article with tips on [debugging Turbo Morphing issues](/articles/how-to-debug-issues-with-turbo-morphing).

## Footnotes

[^1]:  The only action which doesn't schedule a job is deletion which has to broadcast immediately since there will be no record to use for the broadcast later.

[^2]: I say usually because in case of very slow requests that last more than half a second and you are updating on different models outside a single transcation, you could end up broadcasting multiple times before the request has finished.

[^3]: [Idiomorph](https://github.com/bigskysoftware/idiomorph){:target="_blank"} is a javascript library that implements morphing one DOM tree to another. It essentially figures out the minimal set of changes to the DOM needed to get it into the new state.
