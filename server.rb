require 'sinatra'


set :run, true
set :server, %w{ thin }

set :port, 8080
enable :sessions

$polls = {
  'this-is-a-poll-name' => {
    :name => 'This is a poll name',
    :votes => {},
    :alternatives => true
  }
}

def make_poll code, name, alt
  $polls[code] = {
    :name => name,
    :votes => {},
    :alt => alt
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

  session.merge! $polls[params[:poll]]
  erb :poll
end

post '/poll/:poll/cast' do
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
