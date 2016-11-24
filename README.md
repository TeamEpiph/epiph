epiph 
======

epiph is a webapp to facilitate psychological trials based on questionnaires.
You can enter your own questionnaires with multiple question/answer types (multiple-choice (single/multi selection), text, date, etc.). Design your study and schedule visits by defining which questionnaires have to be filled out in which visit. After creating patients, you are ready to fill out questionnaires. Epiph supports exporting the gathered answers as a csv or save it to a (MongoDB) collection for direct access from multiple statistic tools (ex. R).

## Usage

### Development / run locally
This webapp is based on [Meteor](http://meteor.com). If you haven't installed it already, this is how you get it.
```
curl https://install.meteor.com/ | sh
```

Once meteor is installed, this command checks out the repo and starts the app.
```
git clone https://git.scicore.unibas.ch/schmeck/epiph-meteor.git
cd epiph-meteor/app
meteor
```
The app now runs with an empty database on http://localhost:3000

### Deployment
For deployment to production environments this app comes with a Dockerfile (app/Dockerfile\_stage\_kjpk).
To build a docker image you normally do something along the following lines.
```
cd epiph-meteor/app
sudo docker build -t epiph-meteor -f Dockerfile_stage_kjpk .
sudo docker tag epiph-meteor registry.d.patpat.org/epiph-meteor:0.0.11
sudo docker push registry.d.patpat.org/epiph-meteor:0.0.11
```
Docker compose and further maintenance files are held in another repo: https://git.scicore.unibas.ch/schmeck/epiph-misc.git


## TODOs
Project planning is done via trello: https://trello.com/epiph


Copyright and license
-------
Code and documentation copyright 2016 Patrick Recher and University of Basel. Code is licensed under GPLv3.
