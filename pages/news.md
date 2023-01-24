---
title: Posts
permalink: /news/
---

# Posts
{% for post in site.posts limit:10 %}
   <div class="post-preview">
   <a class="post-title" href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a> <span class="post-date">{{ post.date | date: "%y.%m.%d" }}</span>
   {{ post.content | split:'<!--more-->' | first }}
   {% if post.content contains '<!--more-->' %}
    <a href="{{ post.url | prepend: site.baseurl }}">read more</a>
   {% endif %}
   </div>
   <hr>
{% endfor %}

Want to see more? See the <a href="{{ site.baseurl }}/archive/">News Archive</a>.
