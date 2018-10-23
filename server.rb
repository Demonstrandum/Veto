require 'net/http'
require 'json'
require 'symbolized'

require 'sinatra'

set :run, true
set :server, %w{ thin }

set :port, 8080
enable :sessions

$polls = {
  'this-is-a-poll-name' => {
    :name => 'This is a poll name',
    :votes => {},
    :alt => true,
    :voters => []
  }
}  # Example.

$JSON_ID = 's2abg'
$JSON_BASE = 'https://api.myjson.com'

String.class_eval { def to_uri; URI(self); end }
$polls.default_proc = proc do |h, k|
  case k
    when String then sym = k.to_sym; h[sym] if h.key?(sym)
    when Symbol then str = k.to_s; h[str] if h.key?(str)
  end
end

def request_json
  response = Net::HTTP.get "#{$JSON_BASE}/bins/#{$JSON_ID}".to_uri
  $polls = JSON.parse response, {:symbolize_names => true}
end

def save_json
  uri = "#{$JSON_BASE}/bins/#{$JSON_ID}".to_uri
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = $polls.to_json
  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request req }
end

def make_poll code, name, alt
  $polls[code] = {
    :name => name,
    :votes => {},
    :alt => alt,
    :voters => []
  }
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

  puts params[:primary]
  params[:primary].each do |option|
    $polls[params[:code]][:votes][option] = {
      :number => 0,
      :primary => true
    }
  end
end

get '/poll/:poll' do
  unless $polls.keys.include? params[:poll]
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
end

get '/poll/:poll/votes.json' do
  $polls[params[:poll]][:votes].to_json
end

get '/exported.json' do
  $polls.to_json
end
