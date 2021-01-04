FROM node:8.11.3-slim

LABEL base.image="node:8-slim"
LABEL software="epiph"
LABEL software.description="A webapp to facilitate psychological trials based on questionnaires."
LABEL software.website="https://github.com/TeamEpiph/epiph"
LABEL software.license="SPDX:GPL-3.0"
LABEL maintainer="jaroslaw.surkont@unibas.ch"
LABEL maintainer.organisation="sciCORE, University of Basel"
LABEL maintainer.location="Klingelbergstrasse 50/70, CH-4056 Basel, Switzerland"
LABEL maintainer.license="SPDX:GPL-3.0"

RUN apt-get update && \
  apt-get install --yes \
    git && \
  rm -rf /var/lib/apt/lists/*

RUN useradd meteor -G staff -m -s /bin/bash
USER meteor

COPY --chown=meteor:staff . /home/meteor/src

# install meteor
RUN curl https://install.meteor.com | sh

# build the app
RUN cd /home/meteor/src && \
  npm install --production && \
  mkdir -p /home/meteor/build && \
  /home/meteor/.meteor/meteor build --directory /home/meteor/build && \
  cd /home/meteor/build/bundle/programs/server && \
  npm install --production

# cleanup
RUN rm -rf /home/meteor/.meteor

WORKDIR /home/meteor/build/bundle

EXPOSE 3000
ENV PORT 3000
ENV ROOT_URL http://localhost

CMD ["node", "./main.js"]
