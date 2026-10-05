# frozen_string_literal: true

LINKS_FILE = ENV.fetch('LINKS_FILE', 'links.json')

require_relative '../shortener'
require 'sinatra'
require 'json'

links = File.read(LINKS_FILE)
urls = JSON.parse(links)
codes = urls.invert

helpers do
  def show(status_code, message)
    halt status_code, erb(:index, locals: { message: message })
  end

  def short_link(code)
    "#{request.base_url}/#{code}"
  end
end

get '/' do
  erb :index, locals: { message: nil }
end

get '/:code' do
  code = codes[params[:code]]
  halt 404 unless code
  redirect code
end

post '/shorten' do
  url = params[:url]
  custom = params[:code].to_s
  show 400, 'Invalid URL' unless valid_url?(url)

  if urls.key?(url)
    show 200, short_link(urls[url]) if custom.empty? || custom == urls[url]
    show 409, "URL already has code #{urls[url]}"
  end

  if custom.empty?
    begin
      code = generate_code(codes)
    rescue RuntimeError => e
      show 503, e.message
    end
  else
    show 400, 'Invalid code' unless valid_code?(custom)
    show 409, 'Code already in use' if code?(custom, codes)
    code = custom
  end

  urls[url] = code
  codes[code] = url
  File.write(LINKS_FILE, JSON.pretty_generate(urls))
  show 201, short_link(code)
end
