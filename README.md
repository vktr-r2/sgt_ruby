# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration
    - config/credentials/development.yml.enc
    - config/credentials/production.yml.enc
    - config/credentials.yml.enc (database setup)

* Database creation
    - 

* Database initialization
    - rails db:drop db:create db:migrate db:seed

* How to run the test suite
    - rspec -rf

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions
    - bin/rails server (start server)
    - redis-server (start redis)
    - bundle exec sidekiq (start sidekiq)

* Import data

    - ScheduleImportJob.perform_now
    - TournamentImportJob.perform_now

    OR 

    - bundle exec sidekiq-scheduler run schedule_import_job
    - bundle exec sidekiq-scheduler run tournament_import_job



IMPROVE ADMIN FUNCTIONALITY 
- Adding a Golfer should ask you which tournament they should be linked to (DONE)
    - Should give me a drop down menu with available tournaments that already exist in the database ()
- Adding a User should ask me to only input a name, email, and an unencrypted password. On submit, we should encrypt the password
- Basically make all manual DB processes more user friendly

MISC UPDATES
- Add password reset capabilities
- Add draft reminder email services
- Update favicon
- Make logo
- Work on styling (mobile friendly)

MATCH FEATURES
- Pull in tourn score data
    - API call needs to be built
    - Data mapper needs to be built
    - Cron job twice daily IF tournament is active that day
    - Save player scores
    - Publish on match page
- Build match page
    - Assign the drafted golfers to each user accordingly
    - Show the priorities picked by each user for transparency
- Scoring
    - Determine a winner based on strokes
    - Add logic to break a tie
    - Add handling for a cut player

DRAFT FEATURES
- Set the draft order based on the results of the last tournament
- Add to draft page a reminder of the order of priority for that weeks draft

SEASON FEATURES
- Tally weekly results
    - Scoring for tourn results + picking a winner + winning a major
- Build season page
- Import previous season data?

DASHBOARD
- Msgs/memes board

DATA BACKUP SERVICE
- TBD

FINAL CLEANUP
- Stop prod deployments from reseting the DB each time!
- Security vulnerabilities to be addresseds