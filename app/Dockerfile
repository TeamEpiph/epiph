FROM node:8-slim

RUN apt-get update && \
  apt-get install --yes \
    git && \
  rm -rf /var/lib/apt/lists/*

RUN useradd meteor -G staff -m -s /bin/bash
USER meteor

COPY --chown=meteor:staff . /home/meteor/src

RUN cd /home/meteor/src && \
  curl https://install.meteor.com?release=$(cat .meteor/release | cut -f2 -d'@') | sh && \
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
