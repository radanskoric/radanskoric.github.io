---
layout: post
title: "Migrating from Devise to Rails Auth before you can say \"Rails World keynote\""
date: 2024-09-30
categories: guest-articles
tags: rails authentication devise refactoring
author: miha
---

*Radan here: this is another guest post by Miha. He was so excited about it that he interrupted my weekend with a brand new post to review. I still found it interesting, so I hope you enjoy it as much as I did! Back to Miha now.*

Whether you caught wind of it through the [GitHub PR](https://github.com/rails/rails/pull/52328){:target="_blank"}, watched [David's Rails World 2024 opening keynote](https://www.youtube.com/watch?v=-cEn_83zRFw){:target="_blank"}, or read the announcement on the [Ruby on Rails blog for Beta 1](https://rubyonrails.org/2024/9/27/rails-8-beta1-no-paas-required){:target="_blank"}, the message is clear. If this is your first time hearing about it, prepare to be amazed: Rails now ships with **built-in, native authentication**.

Well, sort of. It ships with a basic generator that gets you started. In the words of DHH:

> This is not intended to be an all-singing, all-dancing answer to every possible authentication concern. It's merely intended to illuminate the basic path, and reveal that rolling your own authentication system is not some exotic adventure.

I see it as a stripped-down version of [authentication-zero](https://github.com/lazaronixon/authentication-zero){:target="_blank"}, which I used on [ECT Business](https://business.europeancoffeetrip.com/){:target="_blank"} and it's been flawless. [Visualizer](https://visualizer.coffee/){:target="_blank"}[^1], however, started a while ago, and there I used Devise, like many other (maybe even a majority?) of Rails apps do.

I've always had some problems with it when upgrading Rails versions. There were often GitHub issues and blog posts discussing workarounds or monkey patches to make it compatible, as Devise updates and releases tend to lag behind Rails releases. For example: support for Hotwire was added in February 2023 - **a full year and 3 months after** Rails 7.0 with Turbo Drive was released.

## Trouble in paradise

So, imagine my surprise, when after upgrading Visualizer to Rails 8.0 everything Devise-related was working fine. Well _everything_ was seemingly working fine - smoothest Rails upgrade ever.

But, wait…hmmm…Turbo Streams are broken in production?

Interesting, I see:
1. `connection.js:39 WebSocket connection to 'wss://visualizer.coffee/cable' failed` in the console.
2. `ActionController::RoutingError (No route matches [GET] "/cable")` in logs.

Huh, it works locally? Oh, wait a second: it doesn't work locally when I run it in `production` environment. Probably something is broken in Rails, it is **beta 1** after all. Let's make a `rails new` app, and confirm it's broken. *But it isn't!* Hmmmm…time for a deeper dive.

A couple of `bundle open`s later and pokings around I found [this block](https://github.com/rails/rails/blob/15ddce90583bdf169ae69449b42db10be9f714c9/actioncable/lib/action_cable/engine.rb#L66-L68){:target="_blank"} which prepends the mounting of `"/cable"` to routes. With some further [puts debugging](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer/){:target="_blank"} I found that in the brand-new app the block registers and executes while in Visualizer it registers but **never executes**.

I added some puts debugs inside [ActionDispatch#clear!](https://github.com/rails/rails/blob/15ddce90583bdf169ae69449b42db10be9f714c9/actionpack/lib/action_dispatch/routing/route_set.rb#L490-L497){:target="_blank"} and found that in the new app the ActionCable initializer is registered *before* first `clear` call, but in my app it happened `after`. So it has no chance to run the block. **Culprit found**.

Now I needed to know why this happens, and I put some `puts caller` in there. The only diff was that one included `devise-4.9.4/lib/devise/rails.rb:17`. Oh, god-damn, it's Devise again, isn't it? 😒

I looked at the code and [found this comment: _# Force routes to be loaded if we are doing any eager load_](https://github.com/heartcombo/devise/blob/72884642f5700439cc96ac560ee19a44af5a2d45/lib/devise/rails.rb#L15-L18){:target="_blank"} with very simple `app.reload_routes! if Devise.reload_routes`. And simply [disabling that in `config/initializers/devise.rb`](https://github.com/miharekar/visualizer/commit/ef83f0a9aa1658a123976e10e765d9f89460e563){:target="_blank"} fixed the issue.

I don't have time or Devise knowledge required to dive deeper, but I [opened a GitHub issue](https://github.com/heartcombo/devise/issues/5716){:target="_blank"}, so that anyone else with similar problems can find it, and that hopefully Devise fixes it in the next *year or two*.

Now that could have been it. But you saw the title of the blog post already, so you know there's more. Of course there's more, look at the scrollbar position. 😂

## Migrating away from Devise

Now, Visualizer is not a huge app, but it's not a simple/tiny one either. I'm in no way pushing Devise to its limits, but I do use quite a lot of it: sign up flow, sign in flow, password reset flow, _omniauthable_ to Airtable, `authenticate` route constraint, and I also provide Doorkeeper OAuth flow.

### Step one: setting it up

But, just for fun, how far can I push it with `rails generate authentication`? I [ran the generator](https://github.com/miharekar/visualizer/pull/112/commits/0b40abf3599e3a4b5c8a30655ca955e299bd582f){:target="_blank"} and found that it's pretty nice, yet some things are weirdly omitted: there's no _sign up flow_ and routes just use `resources` with no constraint which generates routes that controllers/views don't handle. Outside of that, it's pretty straight-forward: `Session` that belongs to `User`, with IP and User Agent persistence. It uses [`ActiveSupport::CurrentAttributes`](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html){:target="_blank"} which provides _thread-isolated per-request attributes_, which I was already familiar with, since _authentication-zero_ uses it as well.

So after that, it was time for some rapid fire changes, mostly find & replace (abbreviated to f&r so it looks cool):

1. f&r [`current_user` with `Current.user`](https://github.com/miharekar/visualizer/pull/112/commits/5ba5d5b35a96f8e3287a1423640173b6d1023672){:target="_blank"}
2. f&r `if current_user` with `if authenticated?`
3. f&r `authenticate_user!` with `require_authentication`
4. change to new sign in/up paths
5. rename `User`'s column from `encrypted_password` to `password_digest`

Yeah, _you're right_, the latter is not zero-downtime, but Postgres is pretty fast with these things, so it worked _just fine_ for my scale[^2]. Luckily both Devise and `has_secure_password` use `BCrypt::Password` under the hood, and since I haven't changed Devise's defaults, it _should just work_.

### Step two: migrating user sessions

And it did mostly work. So I was starting to wonder if there's a way to migrate users from Devise sessions/cookies **seamlessly**. After some googling I found that it stores `id` and first 30 characters of password salt in `session["warden.user.user.key"]` and `cookies.signed["remember_user_token"]`. The latter one also stores `Time.now.utc.to_f.to_s` for some reason, but it's irrelevant for our case. With that knowledge I was able to make this:

```ruby
def find_devise_session
  return unless devise_info

  clear_devise_info
  start_new_session_for(devise_user) if devise_user
end

def devise_info
  # try getting info from active session or from remembered cookie
  @devise_info ||= session["warden.user.user.key"].presence || cookies.signed["remember_user_token"].presence
end

def devise_user
  @devise_user ||= begin
	# the session looks like this: [[id], salt]
	# the cookie looks like this: [[id], salt, generated_at]
    user_id = devise_info.dig(0, 0)
    user_salt = devise_info.dig(1)
    return if user_id.blank? || user_salt.blank?

    user = User.find_by(id: user_id)
    # if we find user and its salt matches then we save it to @devise_user
    user if user&.password_digest[0, 29] == user_salt
  end
end

def clear_devise_info
  # we don't want to keep these around otherwise user won't be able to sign out
  session.delete("warden.user.user.key")
  cookies.delete("remember_user_token")
end
```
{: file="app/controllers/concerns/authentication.rb"}

And there was this simple change to the generated methods:

```diff
def resume_session
-  Current.session = find_session_by_cookie
+  find_session_by_cookie || find_devise_session
end

def find_session_by_cookie
-  Session.find_by(id: cookies.signed[:session_id])
+  Current.session = Session.find_by(id: cookies.signed[:session_id])
end
```
{: file="app/controllers/concerns/authentication.rb"}

I'll probably remove this after a couple of weeks, but it's really nice that I can migrate sessions over and not require users to sign in again.

### Step three: migrating views and adding user creation

Next, I copied all my customized Devise views and simply [updated the `form_with` call and field names](https://github.com/miharekar/visualizer/pull/112/commits/07602d9dd143b294610a5aefc87b6cfe9738bf03){:target="_blank"}. Then I discovered that the new Rails generator does not provide a way to create/sign up a user. Very weird choice, I believe. So I added a simple `RegistrationsController` with `new` and `create` actions, and reused the old views again.

The default generator creates a `User` with `email_address`, but I prefer just plain old `email` attribute. I also brought the [svg inline](https://github.com/jamesmartin/inline_svg){:target="_blank"} and migrated from `.slim` to `.erb` while at it[^3]. And then the same for [password reset flow](https://github.com/miharekar/visualizer/pull/112/commits/ba41136c30120560f58d19e856cff13e227a95c2){:target="_blank"}. And, of course, [emails](https://github.com/miharekar/visualizer/pull/112/commits/192d11bf2de9d5ba5b636dd8bc7376f16d216ea0){:target="_blank"}. With that, the main app was pretty much working, and the whole thing took me about 2 hours.

### Step four: Doorkeeper

Then I needed to focus on the API which uses basic auth and [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper){:target="_blank"}. Basic auth was very easy:

```diff
authenticate_with_http_basic do |email, password|
-  user = User.find_by(email:)
-  user if user&.valid_password?(password)
+  next unless user = User.authenticate_by(email:, password:)
+  start_new_session_for(user)
end
```
{: file="app/controllers/api/base_controller.rb"}

And Doorkeeper `resource_owner_authenticator` needed a bit more logic, but the code is very straight-forward:

```diff
- current_user || warden.authenticate!(scope: :user)
+ Current.session = Session.find_by(id: cookies.signed[:session_id])
+ next Current.user if Current.user # return if we have a signed user
+
+ # set the current path to return to after user signs in
+ session[:return_to_after_authenticating] = request.fullpath
+ redirect_to new_session_url
```
{: file="config/initializers/doorkeeper.rb"}

### Step five: route constraints

I use [PgHero](https://github.com/ankane/pghero){:target="_blank"} and [Mission Control — Jobs](https://github.com/rails/mission_control-jobs){:target="_blank"} and I don't want their engines to be exposed to non-admins. Devise makes this very simple with `authenticate` method, but without it, we can still make the same functionality very easily with [constraints](https://guides.rubyonrails.org/routing.html#advanced-constraints){:target="_blank"}:

```diff
- authenticate :user, ->(user) { user.admin? } do
+ constraints ->(request) { AuthConstraint.admin?(request) } do
```
{: file="config/routes.rb"}

What's this `AuthConstraint` you ask? Well, I'm glad you asked:

```ruby
class AuthConstraint
  def self.admin?(request)
    # we're not in ActionController context so we don't have access to cookies yet
    # luckily, it's very easy to get them
    cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)

    # we check if there is an admin that has a session with session_id
    User.joins(:sessions).where(sessions: {id: cookies.signed[:session_id]}, admin: true).exists?
  end
end
```
{: file="app/lib/auth_constraint.rb"}

### Step six: Omniauth

Lastly it was time for something I was putting off from the get-go: omniauth. Devise does seemingly a ton of magic there, so I was quite afraid to tackle it. Turns out, the fears were unfounded. I simply needed to write a new initializer for `OmniAuth`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :airtable,
    Rails.application.credentials.dig(:airtable, :client_id),
    Rails.application.credentials.dig(:airtable, :client_secret),
    scope: "data.records:read data.records:write schema.bases:read schema.bases:write webhook:manage"
  )
end
```
{: file="config/initializers/omniauth.rb"}

add some routes:

```ruby
get "auth/airtable/callback", to: "omniauth_callbacks#airtable"
get "auth/airtable", as: :connect_airtable
get "auth/failure", to: "sessions#omniauth_failure"
```
{: file="config/routes.rb"}

and change `user_airtable_omniauth_authorize_path` to `connect_airtable_path`. Wow. Really? That's it? I guess this is the benefit of me abstracting [`OmniauthCallbacksController`](https://github.com/miharekar/visualizer/blob/eb630907ef2e46d89430c825989ec40d22063f9d/app/controllers/omniauth_callbacks_controller.rb){:target="_blank"} and having a simple [OauthWrapper](https://github.com/miharekar/visualizer/blob/main/app/models/oauth_wrapper.rb){:target="_blank"} class:

```ruby
class OauthWrapper < SimpleDelegator
  def identifiers
    {provider:, uid:}
  end

  def identifiers_with_blob
    identifiers.merge(blob: self)
  end

  def identifiers_with_blob_and_token
    identifiers_with_blob.merge(
      token:,
      refresh_token:,
      expires_at: Time.zone.at(expires_at)
    )
  end

  %i[token refresh_token expires_at].each do |credential|
    define_method(credential) { dig(:credentials, credential) }
  end
end
```
{: file="app/models/oauth_wrapper.rb"}

This last one I've been carrying with me from project to project since 2013, and I hardly changed it since writing it over a decade ago. It really makes everything OAuth flow related so much easier. No _Hashie_, no _HashWithIndifferentAccess_, just Plain Old ~~Ruby Object~~ SimpleDelegator with a bit of metaprogramming sprinkles.

### Step seven: cleanup

Anyway, we're getting side-tracked. Back at `routes.rb` I noticed that the generated `session` and `passwords` use `resource` / `resources`, without any `only` or `except` options, yet the controller doesn't define all actions. So I added some:

```ruby
resource :session, only: %i[new create destroy]
resources :passwords, param: :token, only: %i[new create edit update]
```
{: file="config/routes.rb"}

### Step eight: …profit?

With that, the [migration PR](https://github.com/miharekar/visualizer/pull/112){:target="_blank"} looked complete. With testing, googling, LLMing, and what not, the whole thing took **about 6 hours**. And the line count is incredible `+737 −753`, given I changed many slim templates to erb which are much longer. But, the line count is deceiving because of this:

```diff
- gem "devise"
```
{: file="Gemfile"}

It only counts as one removed line, but in reality, a **massive** dependency with roughly 7,000 lines got removed. 🤯

But what makes me the happiest is that now the entire authentication system is vastly simplified and completely under my control. And that I'll never be afraid of Devise messing up my `bundle update rails`.

I'm incredibly grateful for Devise existing. I can say with certainty that without it, I wouldn't be where I am now. But I find myself now in a place where it no longer _sparks joy_. Thank you, and goodbye. 👋

## Footnotes

[^1]: Hi, yes, it's me, Miha, you might remember me from the [_getting rid of Pagy post_](/guest-articles/pagy-out-turbo-in). Yes, I like to remove gems from my projects.
[^2]: The entire migration took 0.0247s
[^3]: LLMs are incredible at this task
