FROM golang:1.13-alpine

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

# Additional dependencies
RUN apk update && \
    apk add --no-cache ca-certificates libc6-compat libstdc++

# Add hugo v0.62
RUN git clone --branch v0.62.0 https://github.com/gohugoio/hugo.git /hugo
RUN cd /hugo; go install

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
