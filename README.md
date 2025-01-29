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

* Import data
    - ScheduleImportJob.perform_now
