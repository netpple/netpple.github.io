---
title: Posts
permalink: /news/
---

# Posts
{% assign posts = site.posts | where_exp:'post', 'post.hidden != true'%}
{% for post in posts limit:10 %}
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
