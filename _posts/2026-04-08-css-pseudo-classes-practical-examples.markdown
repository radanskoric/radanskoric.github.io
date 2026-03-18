---
layout: post
title: "Practical CSS: Combining :has, :not, :only-child and :placeholder-shown pseudo-classes"
date: 2026-04-08
categories: articles
tags: css pseudo-classes frontend
image: /assets/img/posts/covers/css-pseudo-classes.png
---

{% include_relative _includes/pseudo_classes/_visual_widget_style.html %}

> **pseudo**, *adjective: being apparently rather than actually as stated*

CSS pseudo-classes are like regular classes in that they can be used to select DOM elements. They're unlike regular classes in that you can't see them in the HTML. They select elements dynamically, based on their own rules. This is what makes them powerful.

I really like them because they let me remove dynamic presentation logic from JavaScript and keep it in CSS. That leaves JavaScript more straightforward, easier to understand, and easier to maintain.

## Setup

This is best learnt through a concrete example. I aimed to strike a balance between realism and simplicity.

We'll look at a form for creating tags. Here's the key behaviour:
1. Typing a string into the input field and pressing enter creates a new tag.
2. When you start typing, an "x" button appears inside the input field and lets you clear the field.
3. When there are no tags, a message appears saying "You have no tags".
4. When there's just one tag, it is rendered more prominently.
5. Tags can be removed.

Here's an implementation that uses JS for all of those requirements. This is an interactive widget, so try it out:

<style>
  {% include_relative _includes/pseudo_classes/_js_tag_editor.css %}
</style>

<script type="module">
  {% include_relative _includes/pseudo_classes/_js_tag_editor.js %}
</script>

{% include_relative _includes/pseudo_classes/_js_tag_editor.html %}

I'll skip the styling CSS since it is irrelevant to this article. It's here only to give you a nicer widget to look at. But I will show you the full Stimulus controller attached to it.

Open the details block and just scan it. It's not important to carefully read the code, **just get a sense of how it looks**:

<details markdown="1">
  <summary>JS Driven Tag Editor Stimulus Controller</summary>

  ```javascript
{% include_relative _includes/pseudo_classes/_js_tag_editor.js %}
  ```
</details>

It uses the following classes to work:
<details markdown="1">
  <summary>Classes used by the JS Driven Tag Editor</summary>

  ```css
{% include_relative _includes/pseudo_classes/_js_tag_editor.css %}
  ```
</details>

All of these are presentation classes and they're explicitly manipulated by JS.

We'll now use pseudo-classes to clean it up.

## Striping away the presentation logic

I'm assuming you're familiar with regular CSS selectors and how to combine them. The most basic examples select `#element-by-its-id`, `.by-its-class`, or `.a-combination.of.classes`.

Modern CSS also supports a range of **pseudo-classes** that let you select elements based on an element's full context: its state and surrounding elements.

You're likely already familiar with some pseudo-classes. For example, `:hover` lets you style an element when someone hovers over it. Another common one is `:disabled` for input elements or buttons that are disabled.

The full list of supported pseudo-classes [is rather long](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/Pseudo-classes), but a few are more useful than the others. Used well, they can significantly cut presentation logic in your JS and leave it to handle functionality.

First, let's remove all of the presentation logic from the controller and see what's left:

<script type="module">
{% include_relative _includes/pseudo_classes/_tag_editor.js %}
</script>

{% include_relative _includes/pseudo_classes/_tag_editor_bare.html %}

Everything still works, it's just that it doesn't look quite right.

But the JS controller is now much simpler:

<details markdown="1">
  <summary>Stimulus Controller free of presentation logic</summary>

  ```javascript
{% include_relative _includes/pseudo_classes/_tag_editor.js %}
  ```
</details>

Now we'll build it back up with pseudo-classes! Look at me trying to get you excited about CSS with exclamation marks!

## Building it back up with pseudo-classes

### :only-child

We'll start easy and take care of the unique styling of a single tag.

`:only-child` matches an element when it is its parent's only child, which is exactly what we need. We'll style the tag differently when that happens:

```css
.tag-editor .tag-list li:only-child {
    padding: 0.5rem 1rem;
    font-size: 1rem;
    background: #3a9e75;
    color: white;
}
.tag-editor .tag-list li:only-child .remove-btn {
    color: white;
}
```

#### Another example of :only-child usage

If you have a list where the last element should not be removed, you want to hide the remove button when there's just one element in the list. That can be done purely with CSS:
```css
li:only-child btn.remove { display: none }
```

### :has and :not

The `:has` pseudo-selector is a heavy hitter. It's my favourite CSS selector by a wide margin because it often lets me simplify my JavaScript. Is it weird that I have a favourite CSS selector? I don't care.

The `:has` pseudo-selector matches an element based on **the elements rendered inside it.** For example, `div:has(.my-class)` matches any `div` that contains an element with `my-class`. To clarify, the `div` itself does not have `my-class`; an element inside it does. That difference is extremely powerful. *It allows reversing the normal direction of influence: a child element can influence a parent.* And it's [widely supported in all modern browsers](https://caniuse.com/css-has).

`:not` is much simpler: it matches an element that does not match the selector inside the parentheses. For example, `div:not(.my-class)` matches any `div` that does not have `my-class`.

We can use the two in combination to show and hide the tag list and the "You have no tags" message:

```css
.tag-editor:has(.tag-list li) .empty-message {
  display: none;
}
.tag-editor:not(:has(.tag-list li)) .tag-list {
  display: none;
}
```

#### Another example of :has usage

Imagine you have a modal dialog that loads its content through a Turbo Frame inside the dialog. Sometimes the modal should be wide and sometimes narrow. Most content needs padding, but sometimes the content should go edge to edge and the frame should have no padding around it.

You could solve this with a bit of JavaScript that monitors the content and toggles classes on the modal element. Or you could just use the `:has` pseudo-selector!

```css
.modal:has(.modal-content-wide) {
    width: 80%;
}

.modal:has(.modal-content-edge-to-edge) {
    padding: 0;
}
```

### :placeholder-shown

`:placeholder-shown` matches any `<input>` or `<textarea>` element that is currently displaying [placeholder text](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input#placeholder).

In our input field, we have an "x" button that clears the field. There is no point in showing it when there is nothing to clear. There is no selector for empty inputs. But empty inputs also show their placeholder.

So if the placeholder is shown, we can conclude the input is empty, and we should hide the clear button:

```css
.tag-editor .input-area input:placeholder-shown ~ .clear-btn {
  display: none;
}
```

### Final result

Putting it all together, we have completely restored the original widget:

<style>
{% include_relative _includes/pseudo_classes/_tag_editor_pseudo.css %}
</style>

{% include_relative _includes/pseudo_classes/_tag_editor_html.html %}

And we didn't touch JavaScript. The final controller has remained clean and simple, with only pure functional logic: *add or remove tags* and *clear input field*.

> Notice that CSS ended up being declarative. It does not describe how to change the style. It describes how the page should look in each state. Since the browser handles state changes, the presentation becomes almost reactive: when the state changes, the presentation changes automatically. We don't need a reactive JS framework to make that happen. The pure CSS approach is: easier to understand, easier to maintain, and more performant.
{: .prompt-tip }

> One small word of warning: I have seen some mobile browsers struggle with very complex CSS selectors that contain pseudo-classes. They would occasionally fail to recalculate the layout. As mobile browsers improve, this will go away. For now be careful when using pseudo-classes inside very complex selectors with four or more nested selectors.
{: .prompt-warning }
