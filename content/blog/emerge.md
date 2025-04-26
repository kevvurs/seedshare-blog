+++
title = "Reemergence"
date = 2025-04-24T23:00:00-06:00
description = "I return from my hiatus"
images = [ "/emerge/welcome-back.jpg" ]
tags = [ "development", "blog", "austin", "amazon" ]
categories = [ "life", "meta" ]
+++

![hi](/emerge/kauai.jpg)
_Kauai_

## how ya been?

I haven't posted to this blog since mid-2020. So, what happened? Well, there
was a global pandemic that went on and on. In the midst of all the change,
around the time I stopped posting here, I had a thought.

> I don't want this pandemic to end and still be doing the same things at the end as I was at the start.

Motivated to change in some meaningful way, I dusted off my old resume,
refreshed LinkedIn and began hitting apply buttons worldwide. One day, a
recruiter at Amazon DM'd me. I crammed [leetcode][tech] and studied
[Cracking the Coding Interview][book] before the dreaded "loop" interview.
Long story short, I got the job and went to my favorite doughnut shop to
celebrate (s/o [Top Pot][donut]).

Since then, I've been super busy at work, letting my blog rust. I got to do
some pretty neat things at Amazon. In my first team, we owned multifactor
authentication for employees. Our primary app was the all-in-one intranet
for employee services at Amazon. We supported +30 single-sign-on integrations
to allow low-friction egress from intranet to first-party and third-party
applications for payroll, benefits, and more. At the time, COVID-19 was
creating immense pressure on global supply chains while also driving up
demand for e-commerce. The number of employees at Amazon reached new heights,
particularly at fulfillment centers, where most Amazonians work.

![A to Z Login](/emerge/atoz-login.jpg)

In an effort to social distance, these FC employees began to use our
workforce app to clock-in on-site. It became vital to improve MFA to prevent
it from becoming a bottleneck. Over time my incredible team shipped
improvement after improvement to the login experience.

Eventually, a new requirement came up to expand some employee resources to
former workers, such as continuing benefits and tax documents. The critical
challenge to this was that all of our internal systems were designed to block
access to external parties. I needed to integrate our apps with a new auth
provider and then carve a secure lane of limited access for former employees
to use in our app. This was a fun and challenging project that pushed me to
grow. Today, many people use this feature to get self-service post-employment
support.​​​​​​​​​​​​​​​​

![Amazon Alumni](/emerge/alumni.jpg)

After all that, it was time for another change. I branched out to a young,
new team, Amazon Privacy. At the end of COVID-19 I moved to Austin, TX,
(more on that later). Privacy was an Austin-based team with a relatable
mission. First, I helped ship the Digital Markets Act (DMA) privacy
experience for Amazon Shopping. It was an exciting and rigorous task for our
brand new team that brought us closer together. I also accomplished an
ambition of mine: to take part in customer journey on the world's biggest
e-commerce website.

| | |
|--|-|
| ![web cookie banner](/emerge/banner-web.jpg) | ![mobile DMA banner](/emerge/banner-mobile.jpg) | 

The next project I launched was collecting Cookie Consent in Quebec. I
learned so much by extending and eventually rearchitecting consent collection
for Amazon Stores. A fundamental shift I made to the process was to move
consent collection from a centralized backend service, where it frequently
impacted sitewide latency, to a frontend request that runs in parallel with
the page-load. This new dynamic is helping to decouple the workflow from
latency of rendering the core CX.

## on a personal note

I have been doing new things outside of work too. Having enough rain to last
a lifetime, I packed up and moved to Austin, TX. I bought my first house,
I started playing pickleball and working out [Nike Studios][nike], a new HIIT
venture. I love Austin for its quaintness, a city that has not fully grown
out of its small town vibe. At the same time, it's constantly growing. Since
moving here, at least six new boba tea spots have opened up with more on the
way. I'm bullish on Austin, and it has treated me well.

![austin](/emerge/austin-sketch.jpg)

## what's next?

I have a lot of plans for [seedshare][share]. I started a backlog of things
to write about and example projects to play with. Here are a few:
* WebAssembly
* crypto webapp
* GenAI and [GenUI][v0]
* WebGL
* leetcode examples
* non-technical words of advice

Additionally, I want to develop a feature on this site to offer consultations
and mock interviews. My original passion for this site was a place and
platform to inspire other developers. With that in mind, I hope to see you
here again soon!

### a postscript

I want to spend less time on screens. Programming all day at work and
blogging by night challenges that. So I am trying something new. I wrote
this entire post by hand! Then, I uploaded photos of my terrible penmanship
to [Claude][ai], and asked it to transcribe it in markdown. This is the result.
Not bad! More to come...

![my handwriting](/emerge/notes.jpg)

p.p.s.: getting this blog up and running again was a piece of work! But it is a
[labor of love ♥](https://github.com/kevvurs/seedshare-blog/compare/kevvurs:26a2b6f...kevvurs:f51af7d).

[tech]: https://leetcode.com/problemset/
[book]: https://www.amazon.com/Cracking-Coding-Interview-Programming-Questions/dp/0984782850
[donut]: https://maps.app.goo.gl/iZnYep1bD9rFus3N6
[nike]: https://nikestudios.com/
[share]: https://seedshare.io/
[v0]: https://v0.dev/
[ai]: https://claude.ai/
