---
layout: post
title:  "How to locate the source of a Ruby method"
date:   2023-09-27
categories: articles
tags: ruby
---

_"Wait, where the hell is this method coming from??"_"

One of Ruby's strengths is how highly dynamic it is. This makes it very expressive but it also means that it can often be hard to figure out where a method that you see on an object has come from. Full featured Ruby editors like [RubyMine](https://www.jetbrains.com/ruby/){:target="_blank"} and various plugins for other editors based on gems like [Solargraph](https://solargraph.org/){:target="_blank"} have advanced in recent years and have excellent ability to find the definition of a method.

However, Ruby is so dynamic that there are cases where it is impossible to determine reliably without actually running the code. Static analysis having its limits is the cost of super high dynamism and you will eventually find yourself in a ruby REPL wondering: "Where is this method actually defined?"

There are multiple cases to consider, let's dig in.
## The easy case: Regular Ruby method

Assume you have a source file defined as follows:
```ruby
# file: foo.rb
class Foo
  def bar
    "BAR!"
  end
end
```
Ruby has the answer ready in the form of `source_location` which will very helpfully tell you that the method source is in *file "foo.rb" at line 3*:
```bash
3.2.2 :001 > require_relative "foo"
 => true
3.2.2 :002 > Foo.new.method(:bar).source_location
 => ["~/foo.rb", 3]
```

## Bonus: locating constants.

Since Ruby 2.7 we have another powerful method at our disposal: `const_source_location` which allows us to do the same for constants:
```
3.2.2 :002 > Object.const_source_location(:Foo)
 => ["~/foo.rb", 2]
```
#### Pry
If you are using [Pry](https://rubygems.org/gems/pry){:target="_blank"} as your REPL instead of the default IRB, it's even easier. Pry has the `show-source` (aliased as `$` ) command which is even more helpful and automatically works for both constants and methods:
```
[2] pry(main)> show-source Foo.new.bar

From: ~/foo.rb @ line 3:
Owner: Foo
Visibility: public
Number of lines: 3

def bar
  "BAR!"
end
```
Side note, there's also a companion `show-doc` (aliased as `?`) command that shows the YARD documentation for the method.
## The hard case: Dynamically defined Ruby method

Let's consider a case where we dynamically define some methods but still use regular Ruby code defined in a block:
```ruby
# file: dynamic.rb
class Dynamic
end

%i[foo bar].each do |name|
  Dynamic.define_method(name) do
    "#{name.upcase}!"
  end
end
```
Both `source_location` and Pry's `show-source` will point to the place where the method is defined, in this case the line number 6, the one calling `define_method`. Easy.

However, in a case where you're calling one of the `eval` methods with a string, all of the information gets destroyed while parsing the string:
```ruby
# in dynamic.rb
Dynamic.class_eval "def evald; 'EVALD!'; end"
# later
Dynamic.new.method(:evald).source_location # => returns [(eval), 1]
```
The reason is that `eval` requires you to explicitly pass what you consider the correct location of the source. I.e. if you do the following:
```ruby
Dynamic.class_eval "def evald_with_source; 'EVALD!'; end", __FILE__, __LINE__
```
Then `source_location` will return the location where this was called, just like in the `define_method` with block case above.

To help your future self, get into the habit of specifying the file and line number when doing meta-programming with `eval` and friends. :)

Meta-programming with eval is not uncommon in ruby gems so if you do find yourself in the very unfortunate case of having to find the source of an eval'd method your best bet might be disassembling the compiled method and looking for constants or simple operations for which you can guess the source code snippet and search for it:
```ruby
puts RubyVM::InstructionSequence.disasm(Dynamic.new.method(:evald))
```
## The "beyond Ruby" case: C code

Let's go meta, just a bit: What is the source location of the `source_location` method?
```ruby
3.2.2 :003 > Foo.new.method(:bar).method(:source_location).source_location
 => nil
```
What? `nil`? What's happening is that `source_location` is defined in the C source code of MRI. Anytime you see `source_location` return `nil` you know that the method was not defined in Ruby.

If you are using Pry you can install the [pry-doc](https://rubygems.org/gems/pry-doc){:target="_blank"} gem and it will allow you to reveal the source location of MRI internal methods:
```
[3] pry(main)> require "pry-doc"
=> true
[4] pry(main)> $ Foo.new.method(:bar).source_location

From: proc.c (C Method):
Owner: Method
Visibility: public
Signature: source_location()
Number of lines: 5

VALUE
rb_method_location(VALUE method)
{
    return method_def_location(rb_method_def(method));
}
```

But what if you can't use Pry, or, you need to find the source of a method in a gem's C-extension? `pry-doc` does a lot of work to locate the gems, actually using artifacts of parsing the C-code, but in most cases you can find it relatively quickly yourself in the C-extension source if you know what to look for.

First you need to know just a little bit about how C-extensions define the method. There's two parts: First, there is the C method defined in C-code. However that name gets lost in the compilation and actually exposing the method to the Ruby VM involves a call to one of several methods, with probably the most common being `rb_define_method` and that method needs to receive a string with the **ruby name of the method**. You can exploit that by searching the MRI or the relevant gem's source for the ruby name, surrounded by quotations (don't forget to escape them). Like this [search on ruby language github repo](https://github.com/search?q=repo%3Aruby%2Fruby%20%5C%22source_location%5C%22&type=code){:target="_blank"}. This search returns a few occurrences, but let's focus on these two:
```C
rb_define_method(rb_cProc, "source_location", rb_proc_location, 0);
//...
rb_define_method(rb_cMethod, "source_location", rb_method_location, 0);
```
Notice the parameter after the string: `rb_proc_location` and `rb_method_location`. Those are actual names of C methods. Using some clever deduction skills you can guess that first one is for the `source_location` method on a `Proc` object and second on the `Method` object. Searching for those will usually reveal just a few occurrences with one obviously being the definition of the method.

If you've never worked with C it might **feel intimidating to read C-code** but usually you don't actually have to fully understand it. You're probably looking for an answer to a specific question about what the method actually does. And for that you can often correctly guess what the C-code is doing and draw an informed guess as to how it maps back to Ruby code. In the end you'll verify the conclusion from Ruby land anyway.

Do it a few times and you'll notice you're getting better at it every time!

