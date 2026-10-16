# Project instructions

## Running tests

Use Ruby 3.2.2 (see `.ruby-version`). Use chruby (if available). Prepare the test database and run the full RSpec suite with the local PostgreSQL instance:

```sh
RAILS_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 DB_USER=library DB_PASSWORD=library DATABASE_NAME=momentum_library_spec_local sh -c 'bin/rails db:test:prepare && bundle exec rspec'
```

When running tests concurrently, choose a unique `DATABASE_NAME` for each run to avoid database conflicts.
