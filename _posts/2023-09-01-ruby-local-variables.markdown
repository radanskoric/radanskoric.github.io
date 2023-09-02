---
layout: post
title:  "Is it possible to conditionally define a local variable in Ruby?"
date:   2023-09-01
categories: ruby
---

Let's say you wish to conditionally define a local variable in Ruby. Why would you need that? That's beside the point, it's mostly a thought excercise that's an excuse to learn about a specific corner of Ruby. But, if you still want a real use case, you're being a bit difficult, but let's say that you've got some metaprogramming code that at some points uses `defined?(x)` calls to do something based on whether a local variable is defined or not. Yes, it's very contrived.

So let's try and define a variable based on whether a condition is `true` or `false`.

## Try 1: just use if

Ruby being so incredibly dynamic, my first thought was that I could just define it behind an `if`. The `true` case is trivial:
```ruby
if true
  x = 42
end
puts x.inspect # => 42
```

And the only thing we need now is for the `false` case to raise a `NameError: undefined local variable or method 'x'` and this article is done:
```ruby
if false
  x = 42
end
puts x.inspect # => nil
```
That didn't work, it's defined and has a `nil` value, although the code defining it clearly didn't run.

As it does, the [official documentation has the explanation](https://ruby-doc.org/3.2.2/syntax/assignment_rdoc.html#label-Local+Variables+and+Methods){:target="_blank"}:

> The local variable is created when the parser encounters the assignment, not when the assignment occurs

Ruby is dynamic, but all that dynamism starts only after the parser is done! Can we cheat the parser?

## Try 2: Cheat the parser with eval

Code we `eval` is only parsed at runtime, maybe that will work?
```ruby
if false
  eval("x = 42")
end
puts x.inspect # => raises NameError
```

We fooled it! Now just to check the true case:
```ruby
if true
  eval("x = 42")
end
puts x.inspect # => raises NameError
```

No luck. It turns out that **`eval` introduces a new scope around the code being eval'd**, so the new variable is only local to it.

## Try 2: Cheat the parser with binding methods.

[Binding has a `local_variable_set` method](https://ruby-doc.org/3.2.2/Binding.html#method-i-local_variable_set){:target="_blank"}. Let's try that:
```ruby
if false
  binding.local_variable_set(:x, 42)
end
puts x.inspect # => raises NameError
```

Good so far. And the `true` case:
```ruby
if true
  binding.local_variable_set(:x, 42)
end
puts x.inspect # => raises NameError
```

No luck. Second look at the documentation explains it:
```ruby
bind.local_variable_set(:b, 3) # create new local variable `b'
                               # `b' exists only in binding
```

## Conclusion

We're out of options, so the answer is that **it can't be done**. Most likely, any code relying on `defined?` to run conditional logic should probably think if there is a cleaner way that is less likely to hit against the limits of Ruby dynamism.

## Bonus: unpredictable behaviour of defined?

Remember the contrived case from the beginning of the post? It might look something like this:
```ruby
# Only set the value of x if it was previously defined.
if defined?(x)
  x = true
end
puts x.inspect # => nil
```

So far so good. And you would of course rewrite this into a one liner:
```ruby
x = true if defined?(x)
puts x.inspect # => true
```

Wait, it gives a different result? Those two expressions should be always identical. What's going on? The answer lies in the generated RubyVM instructions:

```ruby
puts RubyVM::InstructionSequence.compile("if defined?(x); x = true; end").disasm
```
Gives:
```
== disasm: #<ISeq:<compiled>@<compiled>:1 (1,0)-(1,29)> (catch: false)
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] x@0
0000 putself                                                          (   1)[Li]
0001 defined                                func, :x, true
0005 branchunless                           13
0007 putobject                              true
0009 dup
0010 setlocal_WC_0                          x@0
0012 leave
0013 putnil
0014 leave
```

While:
```ruby
puts RubyVM::InstructionSequence.compile("x = true if defined?(x)").disasm
```
Gives:
```
== disasm: #<ISeq:<compiled>@<compiled>:1 (1,0)-(1,23)> (catch: false)
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] x@0
0000 putobject                              true                      (   1)[Li]
0002 branchunless                           10
0004 putobject                              true
0006 dup
0007 setlocal_WC_0                          x@0
0009 leave
0010 putnil
0011 leave
```

Notice that in the first case, the `defined?` function is called. In the second case, because parser just parses top to bottom, left to right, it has already parsed the variable declaration and entered it into the local variables table by the time it gets to the if keyword. It then optimises the `defined?` call by resolving it to `true` at compile time. The rule is that parser defines the variable and it does it in the parsing order, regardless of the execution order. So, the optimisation means that actual implementation of `defined?` never runs.

And that's another way in which being clever with `defined?` can turn against you.

