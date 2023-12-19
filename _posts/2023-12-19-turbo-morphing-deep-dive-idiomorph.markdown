---
layout: post
title:  "Turbo 8 morphing deep dive - how idiomorph works? (with an interactive playground)"
date: 2023-12-19
categories: articles
tags: rails turbo hotwire how-stuff-works morphing idiomorph
mermaid: true
---

_This is part 2 of the deep dive into how Turbo 8 morphing works. [Part 1](/articles/turbo-morphing-deep-dive) covered the backend code and Turbo's plumbing around idiomorph and this article focuses on the idiomorph's algorithm and how it works.
If you're only interested in better understanding exactly how idiomorph algorithm works then this article can be read on its own but if you want get a full mental picture of how Turbo morphing functionality works I would suggest you start by reading [part 1](/articles/turbo-morphing-deep-dive)._

> This article has a light idiomorph playground embedded at the end of the article that allows you to input before and after HTML and see what idiomorph will do with it. If you came here just for that you can [jump to it directly here](#playground).
{: .prompt-tip }

## High level

On the high level the algorithm proceeds in following steps:

1. The input is prepared for processing with the most significant preparation being building an id map for all old and new DOM elements.
2. If there is a head element, i.e. if we're doing a full page morph, the head tag is morphed in a special way. In the rest of the algorithm the head is ignored.
3. The new content is searched for the node that best matches the current dom's parent element. In the full page morphing case that will always be the top level `<html>` tag.
4. Recursively, starting from the best match, the old node and its children are morphed to match the new node.
5. If the best match had some content before or after it, that is now inserted around the morphed old content node.

I break down each step in its own separate section.

## Building the ID Map

The building of the *ID map* proceeds as follows, processing first the old and then the new content:
1. Find all children of the node that have `id` set. This is done efficiently by calling:
```js
node.querySelectorAll('[id]');
```
2. Prepare an empty `idMap` object that is an instance of [Map](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map){:target="_blank"} (which functions very similar to Ruby's Hash). Most importantly, like Ruby [Hash](https://docs.ruby-lang.org/en/master/Hash.html){:target="_blank"} anything can be a key and in this case the  DOM node instances are the keys. The values are an instance of [Set](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set){:target="_blank"} that contain a list of ids. JS Set works like Ruby [Set](https://docs.ruby-lang.org/en/master/Set.html){:target="_blank"}.
3. For each element with the `id` property it walks its parent chain until it reaches the top level node and along the way adds its id value to the Set of ids.

The end result is a mapping from the nodes to a list of all ids of its child elements. Here is an example to illustrate it:
```html
<div> <!-- ids=["left", "A", "B", "more", "right"] -->
  <div id="left"> <!-- ids=["left", "A", "B", "more"] -->
    <div> <!-- ids=["A", "B"] -->
      <p id="A"> <!-- ids=["A"] -->
        This is some A content
      </p>
      <p id="B"> <!-- ids=["B"] -->
        This is just B content.
      </p>
    </div>
    <div id="more"> <!-- ids=["more"] -->
      More content
    </div>
  </div>
  <div id="right"> <!-- ids=["right"] -->
    Right text
  </div>
</div>
```
This will be used extensively to check if two elements are a match. Whenever the algorithm looks for an id match between elements it will be looking if the two elements share an id in the *ID map*.

### Takeaways

- It's very important that ids really are unique. They should already be unique but HTML and CSS are reasonably forgiving of repeated ids. However, it could cause big issues with this algorithm.
- It's valuable to have ids on all the actual content. For example, if you have standard partials used in a lot of places, it would be beneficial to use a globally unique id on them, perhaps based on the id of the model being rendered (e.g. `id="project-123"`). The [dom_id Rails helper](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_id){:target="_blank"} is your friend here.

## Morphing the head element

The `head` element is handled differently from the `body` due to specific reasons. Here I am quoting them directly from the [official README](https://github.com/bigskysoftware/idiomorph/blob/main/README.md#the-head-tag){:target="_blank"}:
- It typically only has one level of children within it.
- Those children often to not have `id` attributes associated with them.
- It is important to remove as few elements as possible from the head, in order to minimize network requests for things like style sheets.
- The order of elements in the head tag is (usually) not meaningful.

Idiomorph supports multiple algorithms for merging `head` but Turbo is using the default **merge algorithm**. This means that:
- Elements that are both in new and old will be kept.
- Elements not in new will be removed.
- Elements that are just in new will be added.

The important remarks:
1. Order doesn't matter so in the end the content of head will match the new page but not necessarily in the same order.
2. The elements are compared by their entire `outerHTML`, i.e. the element has to fully match to be considered equal.
3. The algorithm is async because it will wait for the newly added elements to fire their `load` events. This is to ensure that new assets like javascript or stylesheets are loaded before we start morphing the body.

In a typical rails application where most pages share the same layout this should lead to minimal changes with usually only the `title` tag and CSRF protection token changing on navigation.

Once the head tag is resolved, the morphing restarts but in the second pass it will ignore the head element.

### Takeaways
- There is no cost for any head tags that stay the same between old and new content. This means there's going to be little benefit in ensuring that the page loads only the assets it needs. Front loading of all assets can be a reasonable strategy. As always test and profile.
- Beware of very large assets being added in the content we are morphing to. The page content will stay un-morphed until new assets are loaded

## Finding the best match for the old top level element

The first step in the morphing is to look for the best match for the old top level element. In the most common case of morphing the entire page this will be trivial: the `html` element will match. However, morphing can also be used on Turbo 8 remote frames and there it will be more relevant since the new content could be a list of elements.

The algorithm for finding the best match iterates through all of the top level elements of the new content and scores them by *adding 0.5 if they match in the type, plus 1 for each shared id from the ID map*. If they don't match in type the ids are ignored and the score is simply 0.  For example, take this old content
```html
<div><p id="A">aa</p><p id="B">bb</p><p id="C">cc</p></div>
```
and this new content (I put the actual scores in the comments):
```html
<p id="A">abcd</p> <!-- score: 0 (no node type match) -->
<div><p>aaa</p></div> <!-- score: 0.5 (just type match) -->
<div><p id="Z">zzz</p></div> <!-- score: 0.5 (just type match) -->
<div><p id="A">aaa</p></div> <!-- score: 1.5 (type match + 1 id) -->
<div><p id="B">bbb</p><p id="C">ccc</p></div> <!-- score: 2.5 (type match + 2 ids) -->
```
The element with the highest score is selected as best match. In this example that will be the last element. If that element was not there then the second to last element would be selected and if that one was missing then the first div would be selected. The first element will never be selected as it doesn't even match in node type.

If there is no match the algorithm gives up on morphing and simply removes entire old top level element and inserts the new one, replacing everything in one go. If there is a match it then proceeds to morphing.

### Takeaways

- The algorithm is simpler for full page morph.
- If updating a list in a remote Turbo frame is behaving strangely, try adding a few ids.

## Morph the parent into its best match

### Algorithm
The algorithm starts by looking at the old top element and it's best match from the new content:

#### 1. Sync attributes from best match

Add attributes that are missing and remove then ones not present. Then ones that are in both are updated if different. The end result is *the same as if we just overwrote the attributes* but any listener listening to changes on attributes will not be triggered if an attribute didn't actually change.

#### 2. Match new content child element
Take the first child of best match (i.e. new content) and look for **its own best match in the old content**:
1. First look for an an element that overlaps in at least one id from the ID map.
2. If that is not found, look for a child that is a *soft match* (i.e. same type of node). However, there's a little optimisation here. Along the way, it's checking if elements coming after it in the new content would have soft matched the old element it's currently scanning. Once it finds that 2 of its siblings would have matched but it didn't find a match for itself it gives up. This is because if we had proceeded, we would end up removing all of the elements in between. By bailing on this one we allow the 2 siblings to get morphed which is a better option (logic is as simple as 2 morphed is better than 1).
3. If no soft match is found it concludes this is a brand new element and moves on.

#### 3. Process the element

**If no match was found** (including if we gave up for the benefit of 2 siblings) the new node is simply inserted in the correct place.

**If a match was found** then:
1. **Everything we scanned in between is removed** because it's either in the wrong place or it's missing from new content. Notice that this means that in the case where content is the same just reordered, some elements will be morphed but others will be removed and re-added from the new content.
2. **The element is morphed to be equal to its matched element:** This is done by recursively calling the same method we are describing here, i.e. the algorithm is repeated on the child element and its own best match.

#### 4. Move to next element in new content

**Proceed from step 2 with the next element** from the new content until we reach the end of new content.

#### 5. Clean remaining old content

Once we've scanned all the children in the new content **any remaining children in the old content** are removed. At this point anything left over is simply not present at all in the new content.

#### Overview
Putting it all in a flow chart:
```mermaid
flowchart LR
  sync(Sync attributes) --> first(First child)
  first --> process(Process) --> last{Last\nchild?}
  last -->|Yes| cleanup(Clean remaining nodes)
  last -->|No| next(Next child)
  next --> process
```
And zooming into "process" node:
```mermaid
flowchart LR
  start((Start)) --> idmatch{Id match?}
  idmatch -->|No| softmatch{Soft match?}
  idmatch -->|Yes| removebetween(Remove old in between)
  softmatch -->|Yes| verifysoft{Optimal\nsoftmatch?}
  verifysoft -->|No| insert(Insert Node)
  verifysoft -->|Yes| removebetween
  removebetween --> morph(Morph)
  morph --> fin((End))
  insert --> fin
```

### Takeaways

- Do not ever rely on an element definitely being morphed in place in anything but trivial situations. The algorithm does its best to minimise removals and additions but one more child element could cause a different set of elements to be morphed.
- The worst case algorithm complexity is NxM (where N is number of DOM nodes in the old and M in the new content) but for typical Rails app it's likely to be [amortised linear](https://en.wikipedia.org/wiki/Amortized_analysis){:target="_blank"}.

## Insert the content surrounding the best match

Remember that at the top level, in the case where new content is a list of nodes, we found the best match and morphed the old content into its best match. Well, this also means that there is more content at the top level: _around the best match_. Now we insert that content around the old content we just morphed, completing the morphing. This will only be relevant when morphing remote turbo frames since the full page morph will always have just the one top level `html` element.

Before we get to the playground, if you're enjoying my content, it would mean a lot if you would consider subscribing:
<script async data-uid="a747d9cf0d" src="https://thoughtful-producer-2834.ck.page/a747d9cf0d/index.js"></script>

## Interactive playground {#playground}

Below is an interactive idimorph playground. There are two blocks of HTML code, old and new, and then rendered HTML with color coding depending on what idiomorph did with a block: **Orange are nodes that are being morphed, green are new nodes that were added and red are nodes that were removed**.
The actual final result will, of course, not have the red nodes. They are retained here for demonstration purposes. The HMTL blocks are fully editable, feel free to change them and rerun the algorithm with the button below them.

Here are also some premade examples for you to try:
<span id="examples-links">
  <a href="#" data-example="reorder">changing order of items</a>,
  <a href="#" data-example="append">adding an item to the end</a>,
  <a href="#" data-example="prepend">prepending an item to the start</a>,
  <a href="#" data-example="insert">insert between two items</a>,
  <a href="#" data-example="soft">softmatch on type</a>.
</span>


<script src="https://unpkg.com/idiomorph"></script>

<style type="text/css">
  .code-input {
    width: 100%;
    height: 10rem;
    background-color: inherit;
    color: inherit;
    border: none;
  }
</style>

<div class="language-html highlighter-rouge">
  <div class="code-header">
    <span data-label-text="Old HTML"><i class="fas fa-code fa-fw small"></i></span>
    <span></span>
  </div>
  <div class="highlight">
    <code>
      <textarea id="currentDOM" class="code-input">
        Please enable JavaScript to use the playground.
      </textarea>
    </code>
  </div>
</div>

<div class="language-html highlighter-rouge">
  <div class="code-header">
    <span data-label-text="New HTML"><i class="fas fa-code fa-fw small"></i></span>
    <span></span>
  </div>
  <div class="highlight">
    <code>
      <textarea id="newDOM" class="code-input">
        Please enable JavaScript to use the playground.
      </textarea>
    </code>
  </div>
</div>

<button onclick="runIdiomorph();" class="btn btn-outline-primary">Run idiomorph</button>

<div id="demoContainer">
</div>

<script>
  const examples = {
    "reorder" : [
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
      ,
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>\n'
    ],

    "append" : [
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
      ,
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p4">D</p>\n' +
      '</div>'
    ],

    "prepend" : [
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
      ,
      '<div>\n' +
      '    <p id="p0">0</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
    ],

    "insert" : [
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
      ,
      '<div>\n' +
      '    <p id="p1">A</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p2">B</p>\n' +
      '</div>\n' +
      '<div>\n' +
      '    <p id="p3">C</p>\n' +
      '</div>'
    ],

    "soft" : [
      '<div> I\'m original div. </div>\n' +
      '<p> I\'m p and I stay in place and just change text.</p>\n' +
      '<span> I\'m original span.</span>'
      ,
      '<span> I soft match last original element but 2 others softmatch so I\'ll be re-inserted.</span>\n' +
      '<p> I\'m p, only div is after me so I\'ll morph in place. </p>\n' +
      '<div> Old div was already removed when p was morphed so I\'m just inserted. </div>'
    ]
  }

  function loadExample(id) {
    let example = examples[id];
    document.getElementById("currentDOM").value = example[0];
    document.getElementById("newDOM").value = example[1];
    runIdiomorph();
  }

  function exampleLinkClick(event) {
    event.preventDefault();
    loadExample(event.target.dataset.example);
  }
  document.getElementById("examples-links").addEventListener("click", exampleLinkClick);

  function afterNodeAdded(node) {
    if (node.nodeType === 1) {
      node.style.border = "2px solid green";
      node.style.margin = "2px";
    }
  }
  function beforeNodeRemoved(node) {
    if (node.nodeType === 1) {
      node.style.border = "2px solid red";
      node.style.margin = "2px";
      return false;
    }
  }
  function afterNodeMorphed(oldNode, newNode) {
    if (oldNode.nodeType === 1) {
      oldNode.style.border = "2px solid orange";
      oldNode.style.margin = "2px";
    }
  }

  function prepareInputHTML(textareaId) {
    let html = document.getElementById(textareaId).value;
    return `<div>${html}</div>`;
  }

  function runIdiomorph() {
    let currentContent = prepareInputHTML("currentDOM");
    let newContent = prepareInputHTML("newDOM");

    let demoContainer = document.getElementById("demoContainer");
    demoContainer.innerHTML = currentContent;
    let currentDom = demoContainer.children[0];

    Idiomorph.morph(currentDom, newContent,
      {
        morphStyle: "outerHTML",
        callbacks: {
          afterNodeAdded,
          afterNodeMorphed,
          beforeNodeRemoved
        }
      }
    );
    currentDom.style.border = "2px dashed black";
  }

  loadExample("reorder");
</script>

