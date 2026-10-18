# Library API

Ruby 3.2.2 / Rails 8.1 / PostgreSQL. 

Start with:
```sh
docker compose up --build
```

The API listens on `http://localhost:3000`. 
The API docs is accessible from [`/api-docs`](http://localhost:3000/api-docs).
PostgreSQL data persists in a named volume. No authentication is implemented.

## Design

### Database level constraints

A loan records every borrow/return. Reader email is unique case-insensitively; database constraints back up key validations. Deleting a returned book also deletes its history. Production
version might be archiving instead.

A partial unique index on `loans.book_id`, restricted to rows where `returned_at IS NULL`, ensures that each book has at most one active loan. The borrow and return services also lock the book row while updating its loan state, keeping the concurrency logic straightforward. Because simultaneous requests for the same book are expected to be rare, the simplicity of pessimistic locking outweighs the potential contention. If contention becomes significant, handling uniqueness conflicts with retries may be worth considering.

### Background jobs

`BorrowBook` schedules two Solid Queue jobs, 27 and 30 days after the loan began. Solid Queue uses the same database on the same PostgreSQL server and runs in the `worker` container. This way enqueueing can be done within a transaction that updates the state of the database.
A job skips a returned/deleted loan; otherwise it builds the mailer message and writes its payload to the worker log (no real email is sent). Already-scheduled jobs are intentionally not cancelled.

### MVC

The app follows pattern "thin-controller-thin-model". The businnes logic resides in a service class/module that is called from a controller.

If the service does not need a state then it is a module with module level methods.

## API documentation

Interactive API documentation is available at [`/api-docs`](http://localhost:3000/api-docs) when the app is running. The page uses [Scalar](https://scalar.com/) and loads the OpenAPI document from `/api-docs/v1/swagger.yaml`. Scalar's API Reference script is pinned to version 1.75.0 on jsDelivr; the page itself is in `public/scalar/`.

The request specs in `spec/requests/books_api_spec.rb` use the rswag DSL as both executable API examples and the source for the OpenAPI document. After updating those specs, regenerate the checked-in document with:

```sh
bundle exec rake rswag:specs:swaggerize
```

## Tests

With Docker running, execute:

```sh
docker compose run --rm --build -e RAILS_ENV=test -e DATABASE_NAME=momentum_library_spec web sh -c 'bin/rails db:test:prepare && bundle exec rspec'
```

To run RSpec on your host (with Ruby 3.2.2 and the bundle installed), start PostgreSQL and connect through its loopback-only port `5433`:

```sh
docker compose up -d db
RAILS_ENV=test DB_HOST=127.0.0.1 DB_PORT=5433 DB_USER=library DB_PASSWORD=library DATABASE_NAME=momentum_library_spec_local sh -c 'bin/rails db:test:prepare && bundle exec rspec'
```

Port `5433` avoids conflicts with a locally installed PostgreSQL on `5432`. Tests use the Active Job test adapter to inspect scheduled reminders without starting a worker.
