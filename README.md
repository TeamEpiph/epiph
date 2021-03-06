epiph
======

epiph is a webapp to facilitate psychological trials based on questionnaires.
You can enter your own questionnaires with multiple question/answer types
(multiple-choice (single/multi selection), text, date, etc.).
Design your study and schedule visits by defining which questionnaires
have to be filled out in which visit. After creating patients,
you are ready to fill out questionnaires. Epiph supports exporting the
gathered answers as a csv or save it to a (MongoDB) collection for direct
access from multiple statistic tools (ex. R).

## Usage

### Development / run locally

This webapp is based on [Meteor](http://meteor.com).
If you haven't installed it already, this is how you get it.

```
curl https://install.meteor.com/ | sh
```

Once meteor is installed, this command checks out the repo and starts the app.

```
git clone https://github.com/TeamEpiph/epiph.git
cd epiph/app
meteor
```

The app now runs with an empty database on http://localhost:3000

### Deployment

This app can be easily deployed using docker-compose.
If you haven't installed Docker and Docker Compose already, check the official
documentation for the installation details:
[Docker](https://docs.docker.com/install/) and
[Docker Compose](https://docs.docker.com/compose/install/).

```
git clone https://github.com/TeamEpiph/epiph.git
cd epiph/app
docker-compose up
```

### Default User for login to epiph

* email: admin@admin.com
* username: admin
* password: password

## Copyright and license
Code and documentation copyright 2016 Patrick Recher, Ronan Zimmermann and
University of Basel. Code is licensed under GPLv3.
