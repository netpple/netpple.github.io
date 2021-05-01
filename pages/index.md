---
layout: page
title: Welcome to Netpple
permalink: /
---
## 새로운 글 

<div class="section-index">
    <hr class="panel-line">
    {% for post in site.posts  %}        
    <div class="entry">
    <p><a href="{{ post.oriurl | prepend: site.baseurl }}"><img src="{{ post.image }}" width="100%"/></a></p>
    <h5><a href="{{ post.oriurl | prepend: site.baseurl }}">{{ post.title }}</a> <span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span></h5>
    <p>{{ post.description }}</p>
    </div>{% endfor %}
</div>