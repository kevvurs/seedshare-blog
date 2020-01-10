+++
title = "Github Actions"
date = 2019-02-03T20:38:46-08:00
description = "GitHub Actions beta debrief"
tags = [ "", "" ]
categories = [ "workshop", "meta" ]

+++

**Update** - Since GH Actions entered general acceptance, the API has changed entirely without
any respect to the previous model. This article is effectively deprecated, but I
encourage readers to continue if you are interested in what Actions used to be.
A follow-up piece will be drafted soon with the new workflow API. _Spoiler, it
took a ridiculous effort to migrate and is tedious in general._

![jetpacktocat](/github-actions/jetpacktocat_wide.png)

Months ago, I signed up for the [GitHub Actions][gitact] beta, a feature that
allows you to hook CI actions directly into GitHub. Instead of using tools like
Drone, CircleCI, or Wercker, you can simply add a __.workflow__ file to your git
repo and reference a few container images to build and ship your product within
the git lifecycle. Recently GitHub approved my beta access, and I was eager to
take this feature for a test drive.

## first look
I went the GitHub [repository][repo] for this website and opened the new
"Actions" page. Inside, I found the workflow editor. The editor is a UI
experience for adding and connecting actions in a workflow. It has some good
features like discovering pre-made actions for platforms like AWS or Heroku.
Another useful feature is that when an workflow is triggered, you can watch its
status from the UI and review logs from each individual step as it completes.

![github workflow editor](/github-actions/github-actions-editor.png)

However, I did not find the editor was entirely easy to use. Making connections
seemed awkward at times, and if the actual workflow file was malformed, then
vague errors showed on the UI. I found editing the main.workflow file directly
was easier to do once I understood the syntax, but GitHub also offers a view for
you to edit the file directly from the Actions page.

## my workflow
I originally wanted to automate the process of publishing this blog with GitHub.
I am using [Hugo][hugo] which allows me to use templates for the view layer of
the app while I write most of the content is simple Markdown files. Hugo will
bind my content to the templates and generate a static site from it. My workflow
for publishing was fairly simple.

* Write site content in source files
* Generate static site with Hugo
* Deploy site to Firebase Hosting

To automate this, I needed to define a GitHub workflow that builds the website after
changes are pushed and deploys the generated site to the internet. I found one
step of the process was readily available; GitHub has an accepted
[action for Firebase][fireact] integration. I added this using the UI editor,
and linked it to my Firebase project.

![firebase plugin](/github-actions/workflow-firebase.png)

At this point, my main.workflow file was updated to a new state.
That is, the changes I made in the editor were manifested in the actual file.
I even made a new commit to the repository with this update.

```groovy
workflow "Publish SSG" {
  on = "push"
  resolves = ["GitHub Action for Firebase"]
}

action "GitHub Action for Firebase" {
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  secrets = ["FIREBASE_TOKEN"]
  env = {
    PROJECT_ID = "seedshare"
  }
  args = "deploy"
}
```

However, this only offers deploying my site automatically. I have yet to build
the static site from the Hugo project. I could just build locally with Hugo and
push my builds to the repository as well, but I prefer to automate it. I decided
to experiment with developing a custom action to build the site with Hugo.

## implementing an action
For building my static site automatically on `git push` I wrote my own custom
action for Hugo. This process was simple, and I found
[GitHub's documentation][devact] on custom actions to be extremely helpful. To
build my action, I created a docker image that could run the `hugo` command that
builds this site.

Since Hugo is a Go program, I used the Go Alpine Linux base image. Then, I
installed Git, the GCC compiler, and the __musl__ standard library. With this
toolkit, I can pull the [OSS Hugo codebase][devhugo] and build it inside the
container with a `go install` command. I added a litany of `LABEL` statements as
well, as recommended by GitHub for describing the component.

```Dockerfile
FROM golang:1.11.5-alpine3.8

# Github labels
LABEL "com.github.actions.name"="Hugo Action"
LABEL "com.github.actions.description"="Run Hugo build"
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/kevvurs/seedshare-blog"
LABEL "homepage"="https://www.seedshare.io"
LABEL "maintainer"="hello@seedshare.io"

# Install C and git
RUN apk add --no-cache gcc
RUN apk add --no-cache musl-dev
RUN apk add --no-cache git

# Add hugo v0.53
RUN git clone --branch v0.53 https://github.com/gohugoio/hugo.git /hugo
RUN cd /hugo; go install

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

Arguably, the "action" is really designed in the `entrypoint.sh` script, and
the Docker image is just the structure around it. In my script, I had a hugo
command to build the site from the codebase. GitHub will mount the repository to
the running container as the working directory, so assume your action will run
from the base of the project and don't set `WORKDIR` in the image. I added my
Hugo action to the workflow and did `git push` to test it.

```groovy
workflow "Publish SSG" {
  on = "push"
  resolves = ["GitHub Action for Firebase"]
}

action "GitHub Action for Firebase" {
  needs = "action hugo"
  uses = "w9jds/firebase-action@7d6b2b058813e1224cdd4db255b2f163ae4084d3"
  secrets = ["FIREBASE_TOKEN"]
  env = {
    PROJECT_ID = "seedshare"
  }
  args = "deploy"
}

action "action hugo" {
  uses = "./action-hugo"
}
```

## running and debugging
In the Actions UI, I could watch the execution, which may take a few minutes.
Also, the UI produced logs for the actions for debugging, which became useful
because I failed several times at first. In my workflow file, I added a "needs"
parameter to the Firebase action. Making it depend on my Hugo action causes my
action to run first. It's an awkward part of the API where you designate
terminal actions at the top-level of the workflow and stumble backwards through
the process, retrofitting antecedents. Others may defend this API, but I thought
it was a specially uninspired case for DX.

![GitHub Action running](/github-actions/github-actions-in-progess.png)
_UI view at runtime is pretty_

After pushing to the repo with my custom action in the pipeline, I had my first
error. I made a lot of mistakes in my action. One of the most frustrating parts
of this feature is pushing to the repo again and again to test the pipeline.

![action failed](/github-actions/hugo-action-failed.png)

Eventually, I discovered the critical bug. When GitHub runs the action, it
mounts my codebase to the container, but I have a git submodule in the themes
directory of my project. With Hugo, submodules are commonly used to link themes.
Cloning a repository does not automatically pull submodules though by default.
I fixed this by doing the pull in my entrypoint.sh script.

```shell
#!/bin/sh -l
sh -c "git submodule update --init --recursive"
sh -c "/go/bin/hugo $*"
```

After fixing this, and other bugs, I finally deployed my site through actions.
It actually felt great knowing that my blog will be deployed automatically. No
more will I need to manually publish my site. In fact, when I write this post,
I'll be publishing it through my new GitHub Actions CD pipeline. I recommend
Actions for developers looking to automate their workflow. Designing portable,
custom actions with docker, which can be shared with others, is the value-add.

### if you are reading this it worked

[gitact]: https://github.com/features/actions
[repo]: https://github.com/kevvurs/seedshare-blog
[hugo]: https://gohugo.io/
[fireact]: https://github.com/w9jds/firebase-action
[devact]: https://developer.github.com/actions/
[devhugo]: https://github.com/gohugoio/hugo
