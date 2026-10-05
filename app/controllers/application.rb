# frozen_string_literal: true

require "sinatra/base"

require_relative "../my_way"
require_relative "../helpers/app_helpers"

module MyWay
  class Application < Sinatra::Base
    set :root, MyWay::APP_ROOT
    set :views, File.join(MyWay::APP_ROOT, "app", "views")
    set :container, MyWay

    helpers AppHelpers

    configure do
      MyWay.boot!
    end

    get "/" do
      erb :index, locals: { message: nil, link_url: nil }
    end

    get "/:code" do
      link = settings.container.repository.find_by_code(params[:code])
      halt render_not_found unless link

      redirect link.url, 302
    end

    post "/shorten" do
      outcome = settings.container.shorten_link.call(url: params[:url], code: params[:code])
      render_outcome(outcome)
    end

    not_found do
      render_not_found
    end
  end
end