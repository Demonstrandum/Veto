require 'net/http'
require 'json'
require 'symbolized'

require 'sinatra'

set :run, true
set :server, %w{ thin }

set :port, 8080
enable :sessions

$INDIFFERENT = proc do |h, k|
  case k
    when String then sym = k.to_sym; h[sym] if h.key?(sym)
    when Symbol then str = k.to_s; h[str] if h.key?(str)
  end
end

$polls = {
  'this-is-a-poll-name' => {
    :name => 'This is a poll name',
    :votes => {},
    :alt => true,
    :voters => []
  }
}  # Example.

$JSON_ID = '1arifg'
$JSON_BASE = 'https://api.myjson.com'

String.class_eval { def to_uri; URI(self); end }
$polls.default_proc = $INDIFFERENT

def request_json
  puts "[!!] Requesting JSON, ID: #{$JSON_ID}"
  response = Net::HTTP.get "#{$JSON_BASE}/bins/#{$JSON_ID}".to_uri
  $polls = JSON.parse response, {:symbolize_names => true}
  $polls.default_proc = $INDIFFERENT
  pp $polls
end

def save_json
  puts "[!!] Saving JSON, ID: #{$JSON_ID}"
  uri = "#{$JSON_BASE}/bins/#{$JSON_ID}".to_uri
  puts "[!!]\tURI: #{uri}"
  req = Net::HTTP::Put.new uri
  req.set_content_type 'application/json'
  req.body = $polls.to_json
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request req }
  puts "[!!]\tResponse: #{res.inspect}"
end

request_json  # Initial JSON retrieval

def make_poll code, name, alt
  $polls[code] = {
    :name => name,
    :votes => {},
    :alt => alt,
    :voters => []
  }
  save_json
end

get '/' do
  erb :index
end

get '/poll' do
  redirect '/'
end

get '/share/:code' do
  erb :share
end

post '/new' do
  return nil if $polls.keys.include? params[:code]

  make_poll(
    params[:code],
    params[:name],
    params[:alt])

  params[:primary].each do |option|
    $polls[params[:code]][:votes][option] = {
      :number => 0,
      :primary => true
    }
  end
  save_json
end

get '/poll/:poll' do
  unless $polls.keys.map(&:to_s).include? params[:poll]
    return "This poll has not been created/does not exist!"
  end

  local = {:code => params[:poll]}
  local.merge! $polls[params[:poll]]
  erb :poll, :locals => local
end

post '/poll/:poll/cast' do
  return nil if $polls[params[:poll]][:voters].include? request.ip
  $polls[params[:poll]][:voters].push request.ip

  if $polls[params[:poll]][:votes].keys.include? params[:vote]
    $polls[params[:poll]][:votes][params[:vote]][:number] += 1
  else
    $polls[params[:poll]][:votes][params[:vote]] = {
      :number => 1,
      :primary => false
    }
  end
  save_json
end

get '/poll/:poll/votes.json' do
  $polls[params[:poll]][:votes].to_json
end

get '/exported.json' do
  $polls.to_json
end
