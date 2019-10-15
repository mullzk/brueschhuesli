# Brueschhuesli

Although publicly accessible, the Brueschhuesli-Project is taylored for a single use. It is the Reservation-System for our families weekend-cabin. It consists of: 

* A very rudimentary Authentification System (User-Controller), controlling who can make and see reservations. 
* The Model with Reservations for a certain timeslot
* A inifite scolling Calendar-View for those Reservations, a CRUD-Interface for them, and the year-over-year-statistic who had how many reservations (also as xls-Download)


## System dependencies & Configuration
To run this project, you need: 
- Ruby, at least version 2.5.1 (I use rvm for keeping track of ruby versions)
- Rails 5.2.1  (gem install rails)
- Bundler (gem install bundler)
- Postgres  
everything else should get installed when running "bundle install"

## Database 
Once Postgres is installed, you should create the databases according to config/database.yml.  
`createdb brueschhuesli_development`
`createdb brueschhuesli_test``

## Testing
Testing is rudimentary, but running  
`rails test` 
should produce no errors. 

## History
v1.0, 2010: Developed as one of my first Rails-Projects, in local git-repo only
v2.0, 2019 (this version). Newly initialized repo on github, complete new and responsive view-code


## Todo
No current todos. Possible next steps would be a "What should the next visitor bring"-List and a way to communicate when something broke


## Maintenance
`git pull`  
`git checkout dev-branch`  
`bundle update` 		# Updates *all* gems in Gemfile  
`rails test`			# runs test-suite  
`git add . && git commit -m "Updates" && git push` # pushs into dev-branch  
Make sure, that heroku dev-app automatically deploys dev-branch, wait until deployed  
Test dev-app  
`git checkout master`  
`git merge dev-branch`  
`rails test`  
`git add . && git commit -m "Updates" && git push`  # pushs into master  
Make sure, that heroku prod-app automatically deploys master, wait until deployed  
`git checkout dev-branch` # No working in master  

## Deployment
This of course is heavily dependent on the installation. My own way: I have two heroku-apps, prod and dev. Prod is linked to the master branch, dev is linked to whatever dev-branch I currently work in. With every push to the dev-branch, the Dev-App gets immediately updated. If everything works out as desired, I merge into master, deploy the master, on which herokus prod-app fetches its new code. 