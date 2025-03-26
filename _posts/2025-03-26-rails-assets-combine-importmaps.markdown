---
layout: post
title: "Rails 8 Assets: Combining importmaps"
date: 2025-03-26
categories: articles
tags: rails assets importmaps importmap-rails
mermaid: true
---

*This post is part of a mini series on Rails 8 asset pipeline. For the full picture, start with [breakdown of how propshaft and importmap-rails work together](/articles/rails-assets-propshaft-importmaps) and [Propshaft deep dive](/articles/rails-assets-deep-dive-propshaft).*

## Recap of importmap-rails gem

The [`import` statement in JavaScript modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import){:target="_blank"} allows you to import functionality from other module files. However, this typically requires providing URLs to the other JavaScript module sources. **Importmaps** simplify this process by letting you use shorter names instead of full URLs. This increases readability and makes it easier to relocate files, such as moving them to a CDN, without rewriting the `import` statements.

The `importmap-rails` gem supports defining an importmap using a neat DSL:
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
```
{: file="config/importmap.rb"}

This produces the following importmap in your HTML:
```html
<script type="importmap">{
  "imports": {
    "application": "/assets/application-f0907bdc.js",
    "@hotwired/turbo-rails": "/assets/turbo.min-fae85750.js"
  }
}</script>
```

## Why would you need to combine them?

Your rails application has its `importmap.rb` and if you're using Rails engines, each will get its own `importmap.rb` file with its own definitions.

I was setting up my [demo site](https://demo.radan.dev/){:target="_blank"} and I wanted to isolate each demo into a namespace so that I can have all its files conveniently separated. **I wanted to make the engine's importmap extend the main application's one.**  This the issue that [sent me down the path](/articles/rails-assets-propshaft-importmaps) of reading the source of Propshaft and importmap-rails.

## How to combine them

Key to doing that is understanding how the gem evaluates `importmap.rb`: it is loaded and `instance_eval`'d in the context of an `Importmap::Map` instance. It exposes a `draw` which does exactly that ([source code](https://github.com/rails/importmap-rails/blob/d91d5e134d3f27e2332a8cb2ac015ea03d130621/lib/importmap/map.rb#L13-L26)){:target="_blank"}. The DSL of `importmap.rb` is essentially calling methods on the instance of `Importmap::Map`. As you're calling the `pin` method it is building an internal `Hash` with all the entries it will later output into the HTML.

 All we need to do is to call `draw` twice, with the two importmap source files, but on the same importmap instance:
```ruby
myImportmap = Importmap::Map.new
myImportmap.draw("./importmap1.rb"))
myImportmap.draw("./importmap2.rb"))
```

The gem provides a `javascript_importmap_tags` helper function that renders all the necessary script tags.  It's not mentioned in the readme but it accepts an optional `importmap` parameter which allows you to override the default importmap map it uses:

```erb
<%= javascript_importmap_tags, importmap: myImportmap %>
```

## How to make Rails engine importmap extend the Applications's one

We need to:
1. Build a custom importmap.
2. Store it somewhere.
3. Use it in the layout.

There are multiple ways you can go about this but this is the simplest one I found. Inline comments explain the setup:
```ruby
module MyEngine
  class << self
    # Place it directly on the engine
    attr_accessor :importmap
  end

  class Engine < ::Rails::Engine
    # Set it up in a new initializer
    initializer "morphing.importmap", before: "importmap" do |app|
      Morphing.importmap = Importmap::Map.new
      # Evaluate the main application's importmap
      Morphing.importmap.draw(app.root.join("config/importmap.rb"))
      # Evaluate the engine's importmap
      Morphing.importmap.draw(root.join("config/importmap.rb"))
    end
  end
end
```
{: file="my_engine/lib/my_engine/engine.rb"}

Now use it in the engine's layout file:
```erb
<%=
  javascript_importmap_tags
    "my_engine/application",
    importmap: Engine.importmap
%>
```
{: file="my_engine/app/views/layouts/my_engine/application.html.erb"}

See a real-world implementation [in my demo application](https://github.com/radanskoric/demo/blob/ec47a45701bfea85ce9b94014d359987a7c421b0/demos/morphing/lib/morphing/engine.rb#L14-L16){:target="_blank"}.

> In the next article I'll explain how to combine bundled with importmap assets, i.e. how to keep using the default asset pipeline
> but still be able to use more complicated bundled packages from npm. Subscribe below to not miss it.
>
> <script async data-uid="c481ada422" src="https://thoughtful-producer-2834.kit.com/c481ada422/index.js"></script>
{: .prompt-info}


## Use cases for combined importmaps

This approach is also useful for:
* **Separate site sections**: Load specific JS files only when users visit admin or back office sections.
* **Complex UI components**: Preload heavy JS files only when specific components appear on screen. The `pin` method supports `preload: false`, which prevents preloading a source file until the `import` statement executes. That will avoid loading it on other pages but it will make the page with complex UI load slower. Instead, you could extend the main importmap to have it preload everything only on the page where the complex UI is present.

It's a flexible tool, go crazy, live a little.
