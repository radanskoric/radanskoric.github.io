---
layout: page
title: Explore
icon: fas fa-compass
order: 0
---

<nav aria-label="Explore sections" class="d-flex flex-wrap gap-3 mb-4">
  <a href="#topics">Topics</a>
  <a href="#categories">Categories</a>
  <a href="#tags">Tags</a>
</nav>

## Topics

I primarily write about three topics:

<div class="topics">
  <section class="topic" aria-labelledby="topic-ruby">
      <div class="topic-logo">
      <a href="{{ '/tags/ruby/' | relative_url }}" aria-label="Browse Ruby articles"><img src="{{ '/assets/img/topics/ruby.svg' | relative_url }}" alt="Official Ruby logo" width="80" height="80"></a>
      </div>
      <div>
      <h3 id="topic-ruby">Ruby</h3>
      <p><em>The language that optimises for developer happiness</em></p>
      <p>
          Ruby is more than a programming language. It's a medium for expressing solutions clearly and concisely. It has the precision of code and as much of the elegance of English as a programming language can bear. I share in-depth explanations and advanced advice on using Ruby in your work.
      </p>
      </div>
  </section>

  <section class="topic" aria-labelledby="topic-hotwire">
    <div class="topic-logo">
      <a href="{{ '/tags/hotwire/' | relative_url }}" aria-label="Browse Hotwire articles"><img src="{{ '/assets/img/topics/hotwire.svg' | relative_url }}" alt="Official Hotwire lightning bolt" width="80" height="80"></a>
    </div>
    <div>
      <h3 id="topic-hotwire">Hotwire</h3>
      <p><em>Building modern web apps with Rails simplicity</em></p>
      <p>
          Hotwire lets us build modern apps with plain HTML and a little help from Rails. I write about making that work in practice, understanding the magic and fixing it when it gets in the way. I wrote <a href="https://masterhotwire.com" target="_blank">Master Hotwire</a>.
      </p>
    </div>
  </section>

  <section class="topic" aria-labelledby="topic-new-craft">
    <div class="topic-logo">
      <a href="{{ '/tags/new-craft/' | relative_url }}" aria-label="Browse New Craft articles"><img src="{{ '/assets/img/topics/new-craft.svg' | relative_url }}" alt="New Craft logo: curly braces and an amber spark above a charcoal anvil" width="96" height="96"></a>
    </div>
    <div>
      <h3 id="topic-new-craft">New Craft</h3>
      <p><em>Exploring how we build and trust software in the age of LLMs</em></p>
      <p>LLMs are changing how we build software, and I'm figuring out what that means for my own work. What can we hand over? What should we verify? How do we understand the systems we build with AI? Which of our old practices are in the way and which have become even more useful? There are plenty of open questions because it's a <strong>new</strong> craft, and we're figuring it out together.
      </p>
    </div>
  </section>

</div>

<p class="topic-credits"><small>Logos: <a href="https://hotwired.dev/">Hotwire</a>; <a href="https://www.ruby-lang.org/en/about/logo/">Ruby</a>, © 2006 Yukihiro Matsumoto, licensed under <a href="https://creativecommons.org/licenses/by-sa/2.5/">CC BY-SA 2.5</a>. New Craft is an original mark for this blog.</small></p>

## Categories

{% assign sorted_categories = site.categories | sort %}
{% for category in sorted_categories %}
{% assign category_name = category | first %}
{% assign category_posts = category | last %}
<div class="card categories">
  <div class="card-header">
    <i class="far fa-folder fa-fw" aria-hidden="true"></i>
    <a class="mx-2" href="{{ category_name | slugify | url_encode | prepend: '/categories/' | append: '/' | relative_url }}">{{ category_name }}</a>
    <span class="text-muted small">{{ category_posts.size }} {% if category_posts.size == 1 %}post{% else %}posts{% endif %}</span>
  </div>
</div>
{% endfor %}

## Tags

<div id="explore-tags" class="d-flex flex-wrap mx-xl-2">
  {% assign tag_names = '' | split: '' %}
  {% for tag in site.tags %}
    {% assign tag_names = tag_names | push: tag[0] %}
  {% endfor %}
  {% assign sorted_tags = tag_names | sort_natural %}
  {% for tag in sorted_tags %}
    <div>
      <a class="tag" href="{{ tag | slugify | url_encode | prepend: '/tags/' | append: '/' | relative_url }}">
        {{ tag }}<span class="text-muted">{{ site.tags[tag].size }}</span>
      </a>
    </div>
  {% endfor %}
</div>
