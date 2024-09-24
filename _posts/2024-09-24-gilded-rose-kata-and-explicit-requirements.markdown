---
layout: post
title: "Gilded Rose Kata and the value of explicit requirements in the code"
date: 2024-09-24
categories: articles
tags: ruby kata refactoring requirements maintenance
---

I came upon the [Gilded Rose coding kata](https://github.com/emilybache/GildedRose-Refactoring-Kata){:target="_blank"} by reading Victor Shepelev's (a.k.a. Zverok) [blog post about it](https://zverok.substack.com/p/gilded-rose-refactoring-kata-in-ruby){:target="_blank"}. I liked it, especially the part about not immediately reaching for the OOP solution. Ruby is an expressive multi-paradigm language that offers various tools beyond classic OOP.

However, looking at Victor's solution I felt like something is missing. After some head scratching I realised I'm **missing the original requirements expressed in the code**. They're definitely clearer than in the starting kata solution but they're still not explicit. This got me thinking if it could be refactored in a way that would make them explicit. The beauty of katas is that we can explore different approaches in a fraction of the time it would take on a real project.

Being [nerd sniped](https://xkcd.com/356/){:target="_blank"} I sat down to do the kata myself to see how much of the actual written requirements would Ruby *allow me to keep*.

> If you would like to try and solve the Kata yourself before continuing, you should now pause [and go do it](https://github.com/emilybache/GildedRose-Refactoring-Kata){:target="_blank"}. You can also reuse either [mine](https://github.com/radanskoric/GildedRose-Refactoring-Kata/blob/radan-kata-solution/ruby/gilded_rose_spec.rb){:target="_blank"} or [Victor's](https://github.com/zverok/gilded_rose_kata/blob/main/gilded_rose_spec.rb){:target="_blank"} spec, whichever ones you prefer.
{: .prompt-info}

## The requirements

I started by looking at the description of the Gilded Rose Kata thinking how each requirement, i.e. rule, could be expressed in code. I am taking the rules [from the original repo](https://github.com/emilybache/GildedRose-Refactoring-Kata/blob/main/GildedRoseRequirements.md){:target="_blank"}. What follows is those same requirements combined with me translating each one to simple Ruby.

> Hi and welcome to team Gilded Rose. As you know, we are a small inn with a prime location in a
prominent city ran by a friendly innkeeper named Allison. We also buy and sell only the finest goods.
Unfortunately, our goods are constantly degrading in `Quality` as they approach their sell by date.
>
We have a system in place that updates our inventory for us. It was developed by a no-nonsense type named
Leeroy, who has moved on to new adventures. Your task is to add the new feature to our system so that
we can begin selling a new category of items. First an introduction to our system:
>
>- All `items` have a `SellIn` value which denotes the number of days we have to sell the `items`
>- All `items` have a `Quality` value which denotes how valuable the item is

The provided code declares an Item class that allows its properties to be mutated:
```ruby
class Item
  attr_accessor :name, :sell_in, :quality

  def initialize(name, sell_in, quality)
    @name = name
    @sell_in = sell_in
    @quality = quality
  end
end
```

I'll express the rules as lambdas assigned to a variable with an expressive name because I've already finished this refactoring so I know where I'm going, bear with me.

> - At the end of each day our system lowers both values for every item

```ruby
can_expire = ->(item) { item.sell_in -= 1}
quality_degrades = ->(item) { item.quality -= 1 }
```

>Pretty simple, right? Well this is where it gets interesting:
>
>- Once the sell by date has passed, `Quality` degrades twice as fast

Looks like we need to amend the quality degradation rule:
```ruby
quality_degrades = ->(item) { item.quality -= item.sell_in.negative? ? 2 : 1 }
```

> - The `Quality` of an item is never negative
> - The `Quality` of an item is never more than `50`
```ruby
limit_quality = ->(item) { item.quality = item.quality.clamp(0, 50) }
```

> - __"Aged Brie"__ actually increases in `Quality` the older it gets

```ruby
better_with_age = ->(item) { item.quality += item.sell_in.negative? ? 2 : 1 }
```
> __"Sulfuras"__, being a legendary item, never has to be sold or decreases in `Quality`

```ruby
legendary: ->(item) { }
```
Some may question declaring a no-action rule. I think, if a requirement is that nothing changes, it's valuable to make it explicit in the code to keep symmetry with other rules. An alternative is to have a special case and **special cases are the bane of easy maintenance**.

>- __"Backstage passes"__, like aged brie, increases in `Quality` as its `SellIn` value approaches;
>	- `Quality` increases by `2` when there are `10` days or less and by `3` when there are `5` days or less

```ruby
demand_driven = ->(item) do
  item.quality += case item.sell_in
                  when 0..5 then 3
                  when 6..10 then 2
                  else 1
  end
end
```

> - `Quality` drops to `0` after the concert

```ruby
worthless_after_sell_date = ->(item) { item.quality = 0 if item.sell_in < 0 }
```

> Feel free to make any changes to the `UpdateQuality` method and add any new code as long as everything still works correctly. However, do not alter the `Item` class or `Items` property as those belong to the goblin in the corner who will insta-rage and one-shot you as he doesn't believe in shared codeownership.
>
  Just for clarification, an item can never have its `Quality` increase above `50`, however __"Sulfuras"__ is a legendary item and as such its `Quality` is `80` and it never alters.

I've skipped the part where a new requirement is introduced. We'll get to that.

## Defining which rules apply to which items

For the next step, I'll declare which rules apply to which items using a simple Ruby hash object:
```ruby
ITEM_TO_RULES = Hash
  .new(%i[can_expire quality_degrades limit_quality])
  .merge(
    "Aged Brie" => %i[can_expire better_with_age limit_quality],
    "Sulfuras, Hand of Ragnaros" => %i[legendary],
    "Backstage passes to a TAFKAL80ETC concert" => %i[demand_driven limit_quality can_expire worthless_after_sell_date],
    "Conjured Mana Cake" => %i[can_expire conjoured limit_quality]
  )
  .freeze
```
Here I'm declaring a hash object. I first define the default value, i.e. the set of rules that apply to items by default. Then I add custom rules that apply to items of a specific names.
Rules are defined by their names as arrays of symbols, using the `%i` shorthand for defining an array of symbols.

Using a hash avoids modifying the Item class to comply with the kata rules. In a real application I'd probably define the rules on the item objects directly.

> Every item except the legendary "Sulfuras" has `can_expire` and `limit_quality`. You might argue that we should DRY this. I disagree. The fact that we have a legendary item signals these are **not** universal rules and we might have other exceptions. At the moment repetition is the simpler solution. With more items a new pattern might emerge changing the balance. At that point we can refactor again, using the new information.
{: .prompt-tip}

> Notice that for backstage passes I had to move `can_expire` further down in the rules list.  That's because, for reasons I don't understand, the original kata code [modified the sell_in date half way through using it to modify quality](https://github.com/emilybache/GildedRose-Refactoring-Kata/blob/e63b7e7563f5e06a454d0d9ac0365cd2eee39aab/ruby/gilded_rose.rb#L33){:target="_blank"} so I have to match it in the refactoring. Thankfully, the new design made it trivial to match the old behaviour by just changing the order of rules.
{: .prompt-warning}

## Applying the rules to items

In order to be able to easily go from a rule name to the rule `Lambda` object we'll declared them a bit differently: as a hash.
```ruby
  RULES = {
    can_expire: ->(item) { item.sell_in -= 1},
    ...
    worthless_after_sell_date: ->(item) { item.quality = 0 if item.sell_in < 0 }
  }
```
It's exactly the same rules as we defined above, just stored in a `Hash`.

With that small change we're ready to apply the rules to each item when performing the update:
```ruby
def update_quality()
  @items.each do |item|
    ITEM_TO_RULES[item.name].map(&RULES).each { |property| property.(item) }
  end
end
```
That's it, the refactoring is finished. Unpacking what's going on here:
1. We find the list of rules by item name: an array of symbols. If it's not a special item we get the hash default value.
2. We covert the array of symbols to array of lambdas. We're using here the fact that `Hash` implements `to_proc` as: `->(key) { self[key] }`, i.e. it looks up the value in the hash. Since `(&RULES)` takes the `RULES` object and calls `to_proc` to get the block for the call this step converts rule names to rule lambdas.
3. Finally we take each lambda and apply it to the item in the order defined. `lambda.(item)` is just a shorthand for `lambda.call(item)`.

## Adding the new requirement

Finally, let's add the new requirement:
> We have recently signed a supplier of conjured items. This requires an update to our system:
>
> - **"Conjured"** items degrade in `Quality` twice as fast as normal items. *My note: In the integration tests we can see that the item is actually called: "Conjured Mana Cake".*

All we need to do is define the new rule and map the new item to the rule:
```diff
diff --git a/ruby/gilded_rose.rb b/ruby/gilded_rose.rb
index 74236b2..d076231 100644
--- a/ruby/gilded_rose.rb
+++ b/ruby/gilded_rose.rb
@@ -15,2 +15,3 @@ class GildedRose
     worthless_after_sell_date: ->(item) { item.quality = 0 if item.sell_in < 0 },
+    conjoured: ->(item) { item.quality -= item.sell_in.negative? ? 4 : 2 },
   }
@@ -23,2 +24,3 @@ class GildedRose
       "Backstage passes to a TAFKAL80ETC concert" => %i[demand_driven limit_quality can_expire worthless_after_sell_date],
+      "Conjured Mana Cake" => %i[can_expire conjoured limit_quality]
     )
```
What we accomplished is that:
- We added the new requirement with just 1 line for the rule and 1 line for the specific item.
- We didn't have to touch the `update_quality` method.
- We didn't have to understand any of the other rules, they are completely independent.
- The language used in the code is nearly identical to the wording of the new requirement.

## Closing thoughts

I found time and time again that refactoring the code to be extremely close to the actual wording of the business requirements is very beneficial. If you don't do that, every conversation with stakeholders involves you **translating in your head what they're saying to the concepts encoded in the code**. That is both tiring and a continuous source of bugs.

For example, even something as simple as renaming a class to have the same name that the stakeholders use can reduce mistakes. Making the actual business rules as clear as we did in this kata will have a significantly higher effect. It may be hard in a mature product but if the concepts are important enough it can be so worth it.
