FROM node:8.11.3-slim

LABEL base.image="node:8-slim"
LABEL software="epiph"
LABEL software.description="A webapp to facilitate psychological trials based on questionnaires."
LABEL software.website="https://github.com/TeamEpiph/epiph"
LABEL software.license="SPDX:GPL-3.0"
LABEL maintainer="jaroslaw.surkont@unibas.ch"
LABEL maintainer.organisation="Biozentrum, University of Basel"
LABEL maintainer.location="Klingelbergstrasse 50/70, CH-4056 Basel, Switzerland"
LABEL maintainer.license="SPDX:GPL-3.0"

RUN apt-get update && \
  apt-get install --yes \
    git && \
  rm -rf /var/lib/apt/lists/*

RUN useradd meteor -G staff -m -s /bin/bash
USER meteor

COPY --chown=meteor:staff . /home/meteor/src

RUN cd /home/meteor/src && \
  curl https://install.meteor.com | sh && \
  /home/meteor/.meteor/meteor npm install --production && \
  mkdir -p /home/meteor && \
  /home/meteor/.meteor/meteor build --directory /home/meteor && \
  rm -rf /home/meteor/.meteor && \
  cd /home/meteor/bundle/programs/server && \
  npm install

WORKDIR /home/meteor/bundle

EXPOSE 3000
ENV PORT 3000
ENV ROOT_URL http://localhost

CMD ["node", "./main.js"]
