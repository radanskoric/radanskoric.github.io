---
layout: post
title: "How to customize Rails console setup without modifying the project"
date: 2024-03-12
categories: articles
tags: rails console setup
---

When working on projects with other developers you might (like me) find yourself wanting to customize the project console in a way that's not useful as a default but it is useful for you. And ideally, I don't want to modify the project, these are just my configurations. I deserve some privacy.

My friend [Nikola Topalović](https://github.com/topalovic){:target="\_blank"} shared with me a setup that makes this possible in an elegant way.

## Set it all up in an initializer

It starts with a custom initializer where you make the changes you want, for example, it might look like this:

```ruby
Rails.application.console do
  puts "Loading custom initializer #{__FILE__}"

  Rails.logger.level = 0
  puts 'Enabled SQL logs'

  ApplicationController.allow_forgery_protection = false
  puts "Disable CSRF to enable app.post calls"

  puts "DJOTD: #{DAD_JOKES.sample}"
end
```
{: file='config/initializers/me.rb'}


The message printing the location of the initializer file is there for that inevitable moment you will forget that you set this up and will be wondering why your console is different.

## Make git ignore the initializer

The least disruptive way is to navigate to `.git/info/exclude`
 and add a line excluding your custom initializer:
```
config/initializers/me.rb
```
{: file='.git/info/exclude'}

And that's it, git will ignore it, you have your own console modifications and you didn't have to modify anything in the project.
