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

- Add password reset capabilities
- Add reminder email services
- Add the scottie scheffler rule 
- Dynamic draft:
    - Make draft window start two days before tournament is set to start, not just Tues + Wed
    - Make draft window only open when the tournament type is 'stroke'
    - Check live API response for season schedule to ensure it only brings in tournaments from Jan - TOUR Championship in Aug/Sept