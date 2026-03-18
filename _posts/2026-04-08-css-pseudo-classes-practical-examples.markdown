---
layout: post
title: "Practical CSS: Combining :has, :not, :only-child and :placeholder-shown pseudo-classes"
date: 2026-04-08
categories: articles
tags: css pseudo-classes frontend
---

{% include_relative _includes/pseudo_classes/_visual_widget_style.html %}

> **pseudo**, *adjective: being apparently rather than actually as stated*

CSS pseudo-classes are like regular classes in that they can be used to select DOM elements. They're unlike regular classes in that you can't see them in the HTML. They select elements dynamically, based on their own rules. This is what makes them powerful.

And I really like them because they allow me to remove some of the dynamic presentation logic from JavaScript and keep it in CSS. This in turn leaves JavaScript more straight forward, easier to understand, easier to maintain.

## Setup

Best to learn this on a concrete example. The example is made up to strike a balance between being realistic and simple.

We'll look at a form for creating tags. Here's the key behaviour:
1. Typing a string into the input field and pressing enter creates a new tag.
2. When you start typing an "x" button appears inside the input field and allows clearing the field.
3. When there's no tags, a message is shown saying "You have no tags".
4. When there's just one tag it's rendered more prominently.
5. Tags can be removed.

Here's an implementation that leverages JS for all of the requirements (this is an interactive widget, you can try it out):

<style>
  {% include_relative _includes/pseudo_classes/_js_tag_editor.css %}
</style>

<script type="module">
  {% include_relative _includes/pseudo_classes/_js_tag_editor.js %}
</script>

{% include_relative _includes/pseudo_classes/_js_tag_editor.html %}

I'll skip the styling CSS since it's irrelevant for the article. It's here just so you have a nicer example widget to look at. But I will show you the full Stimulus controller attached to it.

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

I'm assuming you are familiar with regular CSS selectors and their combinations. The most basic examples are CSS selectors to select an `#element-by-its-id` or `.by-its-class` or by `.a-combination.of.classes`.

Modern CSS also supports a range of **pseudo-classes** that let you select elements based on the full context of an element: it's state and surrounding elements.

You're likely already familiar with some pseudo classes, for example `:hover` which allows you to apply styling to an element when it is hovered over. Another commonly used one is `:disabled` for input elements or buttons that are disabled.

The list of all supported pseudo classes [is rather long](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/Pseudo-classes) but there are just a handful that are especially handy. Used well they can cut significantly reduce presentation logic in your JS, leaving it to cater just to functionality.

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

Now, we'll build it back up with pseudo classes! Look at me trying to get you excited about CSS with exclamation marks!

## Building it back up with pseudo-classes

### :only-child

We'll start easy and take care of the unique styling of a single tag.

`:only-child` will match if the element is an only child of its parent which is exactly what we need. We'll style the tag differently if it is an only child:

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

The `:has` pseudo selector is a heavy hitter. It's my favourite CSS selector by a wide margin because it often allows me to simplify my JavaScript. Is it weird that I have a favourite CSS selector? I don't care.

The `:has` pseudo selector will match an element based on **the elements that are rendered inside it.** For example: `div:has(.my-class)` will match any div that contains an element with `my-class` as its class. To clarify: it's not the div itself that has `my-class` but an element inside it. It's an extremely powerful difference. It is [widely supported in all modern browsers](https://caniuse.com/css-has).

`:not` is much simpler: it will match an element that does not match the selector inside the parentheses. For example: `div:not(.my-class)` will match any div that does not have `my-class` as its class.

We can use the two in combination alternatively show and hide the list of tags and the "You have no tags" message:

```css
.tag-editor:has(.tag-list li) .empty-message {
  display: none;
}
.tag-editor:not(:has(.tag-list li)) .tag-list {
  display: none;
}
```

#### Another example of :has usage

I have a modal dialog that has its content loaded with a Turbo Frame that's inside the dialog. Sometimes the modal should be wide and sometimes narrow. Most content requires padding but sometimes the content should be edge to edge and there should be no padding around the frame.

You could solve this with a bit of javascript that monitors content and toggles classes on the modal element ... or, you could just use `:has` pseudo selector!

```css
.modal:has(.modal-content-wide) {
    width: 80%;
}

.modal:has(.modal-content-edge-to-edge) {
    padding: 0;
}
```

### :placholder-shown

`:placeholder-shown` matches any  `<input>`  or `textarea>` element that is currently displaying [placeholder text](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input#placeholder).

In out input field we have an "x" button that can be used to clear the input field. There's no point in showing it where there's nothing to clear. There's no selector to select empty inputs. But, empty inputs also show their placeholder!

So, if the placeholder is shown, the input is empty and we should hide the clear button:

```css
.tag-editor .input-area input:placeholder-shown ~ .clear-btn {
  display: none;
}
```

### Final result

Putting it all together we have completely restored the original widget:

<style>
{% include_relative _includes/pseudo_classes/_tag_editor_pseudo.css %}
</style>

{% include_relative _includes/pseudo_classes/_tag_editor_html.html %}

And we didn't touch JavaScript. The final controller has remain clean and simple with just pure functional logic: *add or remove tags* and *clear input field*.

> Notice that CSS ended up being declarative. It's not describing how to change the style but how it should look depending on the state of the page. Since the browser handles the state changes, the presentation ends up being almost Reactive: when the state changes, the presentation changes automatically. Except, we don't need any reactive JS framework to make it happen.
{: .prompt-tip }

> One small word of warning. I have seen mobile browsers struggle with very complex CSS selectors that contain pseudo classes. It would occasionally fail to re-calculate the layout. As the mobile browsers improve, this will go away. Just be careful if you're using pseudo-classes inside very complex selectors (with 4 or more nested selectors).
{: .prompt-warning }
