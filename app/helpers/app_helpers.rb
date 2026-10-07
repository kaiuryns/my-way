# frozen_string_literal: true

require 'json'
require 'rack/utils'

module MyWay
  # Response helpers for the Sinatra application.
  #
  # Translates ShortenLink outcomes into HTTP statuses and renders them as
  # HTML or JSON, depending on what the client asked for.
  module AppHelpers
    OUTCOME_HTTP_STATUS = {
      created: 201,
      exists: 200,
      invalid_url: 400,
      invalid_code: 400,
      url_taken: 409,
      code_taken: 409,
      exhausted: 503
    }.freeze

    def json_requested?
      return true if params['format'] == 'json'

      request.accept?('application/json') && !request.accept?('text/html')
    end

    def short_url(code)
      "#{request.base_url}/#{code}"
    end

    def h(text)
      Rack::Utils.escape_html(text.to_s)
    end

    def render_outcome(outcome)
      http_status = OUTCOME_HTTP_STATUS.fetch(outcome.status)

      if json_requested?
        render_outcome_json(outcome, http_status)
      else
        render_outcome_html(outcome, http_status)
      end
    end

    def render_not_found
      return render_error_json('Link not found', 404) if json_requested?

      status(404)
      erb :not_found
    end

    private

    def render_outcome_html(outcome, http_status)
      locals = {
        message: outcome.message,
        link_url: outcome.link && short_url(outcome.link.code)
      }

      status(http_status)
      erb :index, locals: locals
    end

    def render_outcome_json(outcome, http_status)
      payload = if outcome.link
                  outcome.link.to_h.merge(short_url: short_url(outcome.link.code))
                else
                  { error: outcome.message }
                end

      status(http_status)
      content_type :json
      JSON.generate(payload)
    end

    def render_error_json(message, http_status)
      status(http_status)
      content_type :json
      JSON.generate(error: message)
    end
  end
end
