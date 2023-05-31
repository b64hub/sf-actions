FROM --platform=linux/amd64 node:20.2-bullseye-slim as fetch

ARG DOWNLOAD_URL=https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/nightly/sfdx-linux-x64.tar.xz
ENV DEBIAN_FRONTEND=noninteractive 
ENV SHELL /bin/bash

RUN apt-get update && apt-get install -y -q \
  curl \
  xz-utils

RUN curl -s $DOWNLOAD_URL --output sfdx-linux-x64.tar.xz \
  && mkdir -p /usr/local/sfdx \
  && tar xJf sfdx-linux-x64.tar.xz -C /usr/local/sfdx --strip-components 1 \ 
  && rm sfdx-linux-x64.tar.xz \
  && rm /usr/local/sfdx/bin/node \
  && ln -sf /usr/local/bin/node /usr/local/sfdx/bin/node


# FROM --platform=linux/arm64 node:20.2-bullseye-slim as fetch-arm

# ARG DOWNLOAD_URL=https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/nightly/sfdx-linux-x64.tar.xz
# ENV DEBIAN_FRONTEND=noninteractive 
# ENV SHELL /bin/bash

# RUN apt-get update && apt-get install -y -q \
#   curl \
#   xz-utils \
#   && apt-get autoremove --assume-yes \ 
#   && apt-get clean --assume-yes  \   
#   && rm -rf /var/lib/apt/lists/*

# RUN curl -s $DOWNLOAD_URL --output sfdx-linux-x64.tar.xz \
#   && mkdir -p /usr/local/sfdx \
#   && tar xJf sfdx-linux-x64.tar.xz -C /usr/local/sfdx --strip-components 1 \ 
#   && rm sfdx-linux-x64.tar.xz



FROM --platform=linux/amd64 node:20.2-bullseye-slim

RUN apt-get update && apt-get install -y -q --no-install-recommends \
  openjdk-11-jdk-headless \
  jq \
  && apt-get autoremove --assume-yes \ 
  && apt-get clean --assume-yes  \   
  && rm -rf /var/lib/apt/lists/*

COPY --from=fetch /usr/local/sfdx /usr/local/sfdx

ENV PATH="/usr/local/sfdx/bin:$PATH"
ENV XDG_DATA_HOME=/sfdx_plugins/.local/share \
    XDG_CONFIG_HOME=/sfdx_plugins/.config  \
    XDG_CACHE_HOME=/sfdx_plugins/.cache \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

#
# Create isolated plugins directory with rwx permission for all users
# Azure pipelines switches to a container-user which does not have access
# to the root directory where plugins are normally installed
RUN mkdir -p $XDG_DATA_HOME $XDG_CONFIG_HOME $XDG_CACHE_HOME \
    && chmod -R 777 sfdx_plugins

# Install sfpowerscripts package dependecies and plugins
RUN npm install -g vlocity@1.16.1 \
  && echo 'y' | sfdx plugins install sfdx-browserforce-plugin@2.9.1 \
  && echo 'y' | sfdx plugins install sfdmu@4.18.2 \
  && echo 'y' | sfdx plugins install @dxatscale/sfpowerscripts@$SFPOWERSCRIPTS_VERSION \
  && npm cache clean --force
  # && rm -r $XDG_CACHE_HOME

LABEL org.opencontainers.image.description "Lightweight docker image with sfdx and sfpowercripts to reduce container startup times"
LABEL org.opencontainers.image.licenses "MIT"
LABEL org.opencontainers.image.url "https://github.com/b64hub/dx-actions"
LABEL org.opencontainers.image.documentation ""
LABEL org.opencontainers.image.revision $GIT_COMMIT
LABEL org.opencontainers.image.vendor "b64"
LABEL org.opencontainers.image.source "https://github.com/b64hub/dx-actions"
LABEL org.opencontainers.image.title "SFDX slim docker image"

