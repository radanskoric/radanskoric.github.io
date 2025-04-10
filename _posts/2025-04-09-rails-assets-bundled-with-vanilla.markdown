---
layout: post
title: "Rails 8 Assets: Adding a bundled package alongside vanilla setup"
date: 2025-04-10
categories: articles
tags: rails assets propshaft importmap-rails bundling jsbundling-rails cssbundling-rails
---

{% include_relative _includes/asset_pipeline_links.markdown %}

Propshaft + importmap-rails works great but can't cover all possible cases. When you start reaching for more complex npm packages, you might encounter packages that require some form of bundling.

For example, let's consider a relatively popular select UI package: [Tom Select](https://tom-select.js.org/){:target="_blank"}.

Try pinning it: `bin/importmap pin tom-select`. It will appear to work, but using it will reveal it's broken. The default build pulled from JSPM or JSDelivr isn't completely bundled. It contains inline `import` calls that reference other files by relative path. These imports can't be resolved because they reside in your application's `node_modules` subfolder and aren't exposed to the asset pipeline or included in your importmap.

Does this mean switching our entire asset approach just to adopt this one package? Absolutely not, we can actually have our cake and eat it too. **We can bundle just this one package and keep everything else unchanged.**

## Bundling just one npm package

First, add the `jsbundling-rails` gem by following the [installation instructions from its README](https://github.com/rails/jsbundling-rails?tab=readme-ov-file#installation){:target="_blank"}. The principle explained here works with any runtime supported by the gem, but I'll use [Bun](https://bun.sh/){:target="_blank"}.

The following steps will be for Tom Select but they should work for any package.
You can see a live demo of the setup we'll create [at my demo site](https://demo.radan.dev/bundling){:target="_blank"}.

First, add it to your package.json:
```shell
npm i tom-select --save
```

Now for the crucial step: create a simple file that imports the full TomSelect object and exports it as the default. This file will serve as the entrypoint for bun to bundle. **It's important that this file is ignored by propshaft.** Create an `app/assets/bundled` directory for bundled entrypoint files. Add this directory to the excluded paths so Propshaft ignores it by adding the following line to `config/application.rb`:

```ruby
config.assets.excluded_paths << Rails.root.join("app/assets/bundled")
```
{: file="config/application.rb"}

Inside the new folder, create `tom_select.js` with the following content:

```javascript
// This file is used to bundle tom-select into a single module
import TomSelect from 'tom-select';

// Export tom-select again, as a module
export default TomSelect;
```
{: file="app/assets/bundled/tom_select.js"}

Next, modify the generated `bun.config.js` to process this file, bundle it into a single JavaScript module, and output it to `app/assets/builds`. With Bun you just need to modify the config object:

```javascript
const config = {
  sourcemap: "external",
  entrypoints: ["app/assets/bundled/tom_select.js"],
  outdir: path.join(process.cwd(), "app/assets/builds"),
  format: "esm",
};
```

The `assets/builds` directory serves as the standard location for built files in Rails applications. By default, it's git ignored and Rails includes it in asset paths. It's exactly what we need.

## Using the bundled package from unbundled JavaScript

With this setup, Bun will bundle the file. Currently, it doesn't perform minification or digesting, though it could easily do so. Propshaft picks up the file from the builds directory, adds a digest, moves it to the public folder, and adds it to the manifest. Now add it to the importmap:

```ruby
pin "tom-select"
```
{: file="config/importmap.rb"}

Finally, call it from your JS code. Use it from a Stimulus controller delivered through the regular Rails assets pipeline:
```javascript
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom_select"

export default class extends Controller {
  connect() {
    this.tom = new TomSelect(this.element, {})
  }

  disconnect() {
    this.tom.destroy()
  }
}
```
{: file="app/javascript/controllers/tom_select_controller.js"}

Attaching this controller to a select element transforms it into a fancy tom select!

## Adding the CSS

We're not done yet. Our fancy select needs the custom CSS that ships with Tom Select.

So, what about npm packages that contain custom CSS? If bundling is required, you can use [cssbundling-rails](https://github.com/rails/cssbundling-rails){:target="_blank"}, similar to how we used jsbundling-rails.

However, a simpler solution often exists. Npm packages usually include precompiled CSS. For example, Tom-select provides compiled CSS inside the `dist/css` folder within the node module.

We could add that folder to the load paths so Propshaft would process it. However, I think a cleaner solution is to add a symbolic link from a folder that's already in the load path. And `app/assets/stylesheets` is just the right folder:
```shell
cd app/assets/stylesheets
ln -s ../../../node_modules/tom-select/dist/css/tom-select.css
```

Once linked, Propshaft handles the rest. Add it to your layout:
```erb
<%= stylesheet_link_tag "tom-select.css" %>
```
{: file="app/views/layouts/application.html.erb"}

Now you have a fully working, styled tom select.

> You can see it in action at my demo site, at [https://demo.radan.dev/bundling](https://demo.radan.dev/bundling){:target="_blank"}.
{: .prompt-tip}

## Conclusion

The default Rails asset pipeline composed of Propshaft+importmap-rails provides simplicity and easy maintenance but has limitations.

Encountering these limitations doesn't require abandoning the system! Keep the simple pipeline for most code and implement a more advanced setup only for components that require it.

This is enabled by the simplicity of Propshaft and importmap-rails. By being **simple** and having **few assumptions** about your application, they are very flexible and easy to adapt.
