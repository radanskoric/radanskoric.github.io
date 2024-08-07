---
layout: post
title: "An interactive intro to ruby debugger, in the debugger"
date: 2024-03-26
last_modified_at: 2024-04-09
categories: articles
tags: ruby debugging tutorial
---

**Update 2024-04-09**: Added a second tutorial on using breakpoints.

This is an introduction tutorial to Ruby debugging, inside the ruby debugger itself.
The instructions are woven through the code so you're learning to use the debugger as
you're using the debugger. It's all very meta.

All you need is a working installation of [Ruby 3.3+](https://www.ruby-lang.org/){:target="\_blank"}.

To start the tutorial, first clone my [ruby debug tutorial repo](https://github.com/radanskoric/ruby_debug_tutorial){:target="\_blank"}:
```bash
git clone https://github.com/radanskoric/ruby_debug_tutorial.git
```

And then run the following command in your terminal:
```bash
ruby start.rb
```
Don't read the source code because it will spoil the fun. :)

Did I just ask you to run a piece of code without inspecting it??
I guess I did. Yes, I know, it's a lot to ask.

If you don't trust me (I don't mind, it's a wise choice) or just don't have Ruby 3.3+ installed,
you can also use Docker. To do that, instead of running `rdbg` directly, run:
```
./run_with_docker.sh
```
That script will download a ruby 3.3 official image and run the code inside it.
Reading the source of `run_with_docker.sh` and Dockerfile will not spoil the fun, so please go ahead. :)
