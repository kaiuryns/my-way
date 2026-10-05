# MyWay

A small URL shortener built with Sinatra and SQLite.

- `POST /shorten` creates a short link (random 5-char code, or one you pick)
- `GET /:code` redirects to the original URL
- Shortening the same URL twice returns the same link
- HTML form by default, JSON when you ask for it

## Running it

```sh
bundle install
bundle exec rackup
```

`rackup` picks up `config.ru` by default and serves on Puma, <http://localhost:9292>.
The database is created and migrated on boot, so a bad setup fails immediately
instead of on the first request.

```sh
bundle exec rake test        # run the test suite
bundle exec rake run         # same as `rackup`
bundle exec rake db:import   # load the legacy links.json into SQLite
```

## HTTP API

`POST /shorten` takes `url` and an optional `code`.

| Case | Status | Body |
| --- | --- | --- |
| Link created | `201` | the short link |
| URL was already shortened | `200` | the same short link |
| `url` is not a valid http/https URL | `400` | `Invalid URL` |
| `code` does not match `[A-Za-z0-9_-]{3,30}` | `400` | `Invalid code` |
| `code` is already taken | `409` | `Code already in use` |
| `url` already has a different `code` | `409` | `URL already has code <code>` |
| No free code could be generated | `503` | `Cant generate a code, try a custom one` |
| `GET /:code` for an unknown code | `404` | `Link not found` |

### JSON

Send `Accept: application/json` (or `?format=json`) to get JSON instead of HTML.

```sh
$ curl -X POST -d 'url=https://ruby-lang.org&code=ruby' \
    -H 'Accept: application/json' http://localhost:9292/shorten
{"code":"ruby","url":"https://ruby-lang.org","short_url":"http://localhost:9292/ruby"}
```

Errors come back as `{"error": "..."}`.

## Layout

The app follows MVC. Dependencies point inwards: views know about controllers,
controllers know about services and models, and nothing below the service layer
knows that HTTP exists.

```
config.ru                     Rack entry point
app/
  my_way.rb                   namespace, requires, boot!/reset!
  controllers/
    application.rb            MyWay::Application - routes, thin by design
  services/
    shorten_link.rb           business rules, returns an Outcome value object
  models/
    link.rb                   Link value object + validation
    link_repository.rb        every SQL statement in the project
  db/
    connection.rb             SQLite handle: WAL, busy handler, migrations
    schema.rb                 CREATE TABLE + indexes
  helpers/
    app_helpers.rb            status mapping, HTML/JSON negotiation
  views/                      ERB templates
```

The service returns an `Outcome` (a `Data` object holding a `status`, an optional
`link` and an optional `message`) rather than calling `halt`. The controller is the
only layer that turns that into an HTTP status code, and `app/helpers/app_helpers.rb`
is the only place that knows what each status number is.

### Concurrency

The `UNIQUE` constraints on `links.code` and `links.url` are what enforce the
`409` conflicts, so two requests can never claim the same code even if they arrive
at the same instant. `SQLite3::Database` is safe to share across Puma's threads, so
the app keeps one connection open in WAL mode with a busy handler. `SQLite3::Statement`
objects are *not* thread safe, which is why `LinkRepository` prepares and closes a
statement inside each method call instead of caching one.

`test/concurrency_test.rb` covers both races.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `DATABASE_PATH` | `db/my_way.sqlite3` | SQLite file |
| `APP_ENV` | `development` | Sinatra environment |
| `LINKS_FILE` | `links.json` | Legacy file read by `rake db:import` |
| `PORT` | `9292` | `rackup -p $PORT` |