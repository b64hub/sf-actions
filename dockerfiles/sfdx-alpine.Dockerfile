FROM --platform=linux/amd64 node:20.2-alpine3.17 as build

ARG DOWNLOAD_URL=https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/nightly/sfdx-linux-x64.tar.xz
ARG SFPOWERSCRIPTS_VERSION=alpha

RUN apk update && apk add --no-cache curl bash flatpak gcompat
ENV SHELL /bin/bash

RUN curl -s $DOWNLOAD_URL --output sfdx-linux-x64.tar.xz \
  && mkdir -p /usr/local/sfdx \
  && tar xJf sfdx-linux-x64.tar.xz -C /usr/local/sfdx --strip-components 1 \ 
  && rm sfdx-linux-x64.tar.xz \
  && rm /usr/local/sfdx/bin/node \
  && ln -sf /usr/local/bin/node /usr/local/sfdx/bin/node

ENV PATH="/usr/local/sfdx/bin:$PATH"
ENV XDG_DATA_HOME=/sfdx_plugins/.local/share \
    XDG_CONFIG_HOME=/sfdx_plugins/.config  \
    XDG_CACHE_HOME=/sfdx_plugins/.cache

#
# Create isolated plugins directory with rwx permission for all users
# Azure pipelines switches to a container-user which does not have access
# to the root directory where plugins are normally installed
RUN mkdir -p \ 
  $XDG_DATA_HOME \
  $XDG_CONFIG_HOME \
  $XDG_CACHE_HOME \
  && chmod -R 777 sfdx_plugins

# Install sfpowerscripts package dependecies and plugins
RUN npm install -g vlocity@1.16.1
RUN echo 'y' | sfdx plugins install sfdx-browserforce-plugin@2.9.1 \
  && echo 'y' | sfdx plugins install sfdmu@4.18.2 \
  && echo 'y' | sfdx plugins install @dxatscale/sfpowerscripts@$SFPOWERSCRIPTS_VERSION


FROM --platform=linux/amd64 node:20.2-alpine3.17

RUN apk update && apk add --no-cache bash flatpak gcompat openjdk11
ENV SHELL /bin/bash
ENV SFDX_CONTAINER_MODE=true

COPY --from=build /usr/local/sfdx /usr/local/sfdx
ENV PATH="/usr/local/sfdx/bin:$PATH"
ENV XDG_DATA_HOME=/sfdx_plugins/.local/share \
    XDG_CONFIG_HOME=/sfdx_plugins/.config  \
    XDG_CACHE_HOME=/sfdx_plugins/.cache \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk

COPY --from=build /sfdx_plugins/.config $XDG_CONFIG_HOME
COPY --from=build /sfdx_plugins/.local/share $XDG_DATA_HOME
COPY --from=build /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN chmod -R 777 sfdx_plugins \
  && ln -sf /usr/local/lib/node_modules/vlocity/lib/vlocitybuild.js /usr/local/bin/vlocity

