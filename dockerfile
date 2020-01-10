#
#
# Base alpine image with all the various dependencies
#
# Note that the node sass is broken with
# https://github.com/nodejs/docker-node/issues/1028
#
#
FROM node:10-alpine AS baseimage

# Install dependencies
RUN apk add --no-cache gettext

# Setup the /application/ directory
RUN mkdir -p /application/
# WORKDIR /application/

#
#
# Initial docker builder (resets node_modules)
#
#
FROM baseimage AS builder

# node-gyp installation 
RUN apk add --no-cache make gcc g++ python

# Copy over the requried files
COPY api /application/api/
COPY ui  /application/ui/
COPY docker-entrypoint.sh  /application/docker-entrypoint.sh

# Scrub out node_modules and built files
RUN rm -rf /application/api/node_modules
RUN rm -rf /application/ui/node_modules
RUN rm -rf /application/ui/dist

# Lets do the initial npm install
RUN cd /application/ui  && ls && npm install
RUN cd /application/api && ls && npm install

# Lets do the UI build
RUN cp /application/ui/config/apiconfig.sample.js /application/ui/config/apiconfig.js
RUN cd /application/ui && npm run build

#
#
# Docker application
#
#
FROM node:12-alpine as application

# Copy over the built files
COPY --from=builder /application/api     /application/
COPY --from=builder /application/ui/dist /application/ui-dist

# Debugging logging
RUN ls /application

# Expose the server port
EXPOSE 8000

#
# Configurable environment variable
#
ENV MAILGUN_EMAIL_DOMAIN=""
ENV MAILGUN_API_KEY=""
ENV WEBSITE_DOMAIN=""

# #
# # Preload the NPM installs
# #
# RUN cd /application/ui  && ls && npm install
# RUN cd /application/api && ls && npm install

# Setup the entrypoint
ENTRYPOINT [ "/application/docker-entrypoint.sh" ]
CMD []