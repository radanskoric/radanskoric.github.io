---
layout: post
title: "Rails 8 Assets: Deep dive into Propshaft"
date: 2025-03-18
categories: articles
tags: rails assets propshaft
mermaid: true
---

{% include_relative _includes/asset_pipeline_links.markdown %}

## TL:DR;

Here's the gold fish attention span version, minus some details:
- Propshaft processes every file in its list of load paths and moves it into the public folder.
- Processing involves adding the digest to the filename and then running a set of "compilers" that process the file's content.
- Use jsbundling-rails and cssbundling-rails gems to add more advanced asset processing. These gems work by dropping already processed files into one of the load paths so Propshaft will pick them up.

## The Propshaft processing pipeline

Propshaft has a simple processing pipeline. It scans all load paths defined by `config.assets.paths` and processes each file it finds. This approach simplifies the process and eliminates the need for other tools to explicitly mark assets for processing. They just need to place them in the right folder.

Let's focus on the processing of a single file, depicted by this diagram:
```mermaid
flowchart LR
    A[Asset] --> B{Already<br/>digested?}
    B -->|No| C(Add digest<br/>to filename)
    B -->|Yes| D(Use existing<br/>filename)
    C --> E[Digested<br/>asset]
    D --> E
    E --> H(Add to manifest)
    E -->|Process| F[Processed<br/>asset]
    F -->|Copy to<br/>public| G[Final<br/>asset]
```

Breaking down that diagram:
1. Check if the asset is already digested: if the filename, excluding the last file extension, ends in `-[digest].digested`, it is considered already digested. For example, `bundle-abc123.digested.js` is considered already digested.
2. Leave already digested filenames unmodified. Modify all others by appending a digest of their content, using the SHA1 hashing algorithm. *This is crucial for efficient asset caching in production.*
3. Add the asset to the manifest. The manifest is a json file that contains a map from the original name to its final public path, including the digested filename.
4. Process the asset. By default, this process involves light modifications: resolving asset references found inside the assets. This takes care of things like image references in CSS. You can add your own processing logic.
5. Copy the processed file to the public folder. The final location is the one included in the manifest.

> All of the assets are first processed up to the "Digested asset added to manifest" stage. This is needed in order to have a complete manifest file before processing starts, so that all asset references can be resolved.
{: .prompt-warning }

Notice that the digest is always based on the initial, unprocessed, asset content.

## How to modify the processing pipeline

Processing happens through **Propshaft compilers**.

A compiler is simply a class with a `compile` instance method that accepts an asset and an input string, the content of the asset file. The method returns a modified input string. The list of compilers is defined by the `assets.compilers` configuration setting. It's just an array of `[mime_type, compiler_class]` pairs.

To add a custom compiler to Propshaft, append it to the list of asset compilers with the appropriate mime type.

For demonstration purposes let's define a simple "compiler" which removes consecutive blank lines and register it to run when processing javascript files:

```ruby
require "propshaft/compiler"

class TestCompiler < Propshaft::Compiler
  def compile(asset, input)
    input.gsub(/\n[\s*\n]+/, "\n")
  end
end

Rails.configuration.assets.compilers << ["text/javascript", TestCompiler]
```

Yup, that's all that's needed.

The `asset` parameter is an instance of [Propshaft::Asset](https://github.com/rails/propshaft/blob/main/lib/propshaft/asset.rb){:target="_blank"} and `input` is just a `String`. The method is expected to return a `String`.

If you want to introduce a custom compiler, it's useful to look at how the built-in compilers are implemented. You can find them in the gem source under [lib/propshaft/compilers](https://github.com/rails/propshaft/tree/main/lib/propshaft/compiler){:target="_blank"}.

> The order of compilers matters. When processing an asset, Propshaft takes the list of all compilers matching the file's mimetype and runs them in turn, feeding the output of the previous one to the next in line. Depending on what the compilers do, the order becomes relevant. Since `assets.compilers` is just an array, you can insert your compiler in the right place. Best place to do it is in a Rails initializer. This will ensure it's inserted early enough for all uses.
{: .prompt-danger }

## How js/css bundling gems work with Propshaft?

Propshaft does not perform advanced processing like minification of js and css files out of the box. Instead, you can use the recommended [`jsbundling-rails`](https://github.com/rails/jsbundling-rails){:target="_blank"} and [`cssbundling-rails`](https://github.com/rails/cssbundling-rails){:target="_blank"} gems to add advanced processing.

Theoretically, you can create a custom compiler to minify an asset. However, these gems do not use that approach. Instead, they run **before Propshaft** and output files with the `.digested` suffix so that Propshaft will not add its own digest.

This design stems from two main reasons:
1. These gems process files using command line invocations of JavaScript-based tools (e.g., Bun, ESBuild, PostCSS...). Since compilers operate on in-memory strings, this would require juggling temporary files, which would likely get messy.
2. As the names suggest, they also bundle multiple assets into one, and **Propshaft** compilers operate on a single asset file.

The flow is then pretty simple:
1. The bundling gems attach to the rake assets:precompile task and run their logic before Propshaft. They process and bundle the input files into one or more output files that they drop into one of the folders in the load paths (i.e. `config.assets.paths`).
2. Since Propshaft processes all the files it finds, it picks them up and runs them through its own pipeline. It skips digesting but still processes any remaining cross-file asset references.

## Conclusion

Propshaft does much less than other asset processing tools. I'd argue that is its strength, making it simple to understand and easy to extend.

The next article [explores how to combine multiple importmaps](/articles/rails-assets-combine-importmaps).
