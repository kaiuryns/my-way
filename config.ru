# frozen_string_literal: true

# Rack entry point. `rackup` picks this file up by default:
#
#   bundle exec rackup
#   bundle exec rackup -p 3000 -o 0.0.0.0
#
# MyWay.boot! runs from the app's `configure` block, so the database is opened
# and migrated here: a broken setup fails at boot instead of on the first hit.

require_relative "app/controllers/application"

run MyWay::Application