# Library API

Ruby 3.2.2 / Rails 8.1 / PostgreSQL. Start with `docker compose up --build` (or `docker compose up`); the API listens on `http://localhost:3000`. PostgreSQL data persists in a named volume. No authentication is implemented.

## Endpoints

All payloads are JSON; serial and card numbers are **strings of exactly six digits** (leading zeroes are preserved).

- `POST /books` — add a book: `{ "book": { "serial_number": "000001", "title": "A Book", "author": "An Author" } }`
- `GET /books` — list books with `available`/`borrowed` status.
- `GET /books/:id` — book details and chronological booking history, including reader, borrow/due/return dates.
- `POST /books/:id/borrow` — `{ "card_number": "000123" }`; returns booking and due date.
- `POST /books/:id/return` — return the current booking (no body required).
- `DELETE /books/:id` — remove a book and its history, only if not borrowed.

Invalid inputs return `422`, missing records `404`, and invalid status transitions `409`. Book IDs are database IDs; serial numbers and card numbers are unique business identifiers.

## Design

A booking records every borrow/return. A partial unique index on open bookings plus a row lock on the book prevent simultaneous borrowers. Reader email is unique case-insensitively; database constraints back up key validations. Deleting a returned book also deletes its history; a production system might archive instead.

`BorrowBook` schedules two Solid Queue jobs, 27 and 30 days after the loan began. Solid Queue uses a separate database on the same PostgreSQL server and runs in the `worker` container. A job skips a returned/deleted booking; otherwise it builds the mailer message and writes its payload to the worker log (no real email is sent). Already-scheduled jobs are intentionally not cancelled. If enqueueing fails after the loan commits, the loan remains recorded but an operator must retry the reminders; an outbox would make this atomic in a production system.

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
