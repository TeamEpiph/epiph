epiph 
======

Epiph is a webapp to facilitate psychological trials based on questionnaires.

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
Code and documentation copyright 2016 Patrick Recher and University of Basel. Code license is to be determined.
