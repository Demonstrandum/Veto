require 'mongo'
require 'json'

require 'sinatra'

set :run, true
set :server, %w{ thin }

set :port, 8080
enable :sessions

before { request.path_info.sub! %r{/$}, "" }

# ENV['MONGO_DB'] variable with Now secrets, or just in your shell if local.
CLIENT = Mongo::Client.new "#{ENV['MONGO_DB']}/Veto"
POLLS = CLIENT[:polls]

def poll_exist? code
  POLLS.find({:code => code}).to_a.size > 0
end

def make_poll code, name, alt
  alt = alt.to_s == 'true'
  poll = {
    :code => code,
    :name => name,
    :votes => {},
    :alt => alt,
    :voters => []
  }
  POLLS.insert_one poll
end

$HEAD_TAGS = <<-HTML
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.0/normalize.min.css" />
  <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/skeleton/2.0.4/skeleton.min.css" />
  <link rel="stylesheet" type="text/css" href="/styles.css" />

  <script
    src="https://code.jquery.com/jquery-3.3.1.min.js"
    integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
    crossorigin="anonymous">
  </script>
  <script
    src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"
    integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU="
    crossorigin="anonymous">
  </script>
HTML

get '/' do
  erb :index, :locals => {:head_tags => $HEAD_TAGS}
end

get '/poll' do
  redirect '/'
end

get '/share/:code' do
  erb :share, :locals => {:head_tags => $HEAD_TAGS}
end

post '/new' do
  return nil if poll_exist? params[:code]

  make_poll(
    params[:code],
    params[:name],
    params[:alt])

  params[:primary].each do |option|
    POLLS.update_one({:code => params[:code]}, {
      :"$set" => {
        :"votes.#{option}" => {
          :number => 0,
          :primary => true
        }
      }
    })
  end
end

get '/poll/:poll' do
  unless poll_exist? params[:poll]
    return "This poll has not been created/does not exist!"
  end

  local = {:code => params[:poll], :head_tags => $HEAD_TAGS}
  local.merge! Hash.from_bson POLLS.find({:code => params[:poll]}).first.to_bson
  erb :poll, :locals => local
end

post '/poll/:poll/cast' do
  return nil if POLLS.find(:"$and" => [{:code => params[:poll]}, {:voters => request.ip}]).to_a.size > 0
  POLLS.update_one({:code => params[:poll]}, {:"$push" => {:voters => request.ip}})

  if POLLS.find({ :"votes.#{params[:vote]}" => {"$exists": true} })
    POLLS.update_one({:code => params[:poll]}, { :"$inc" => { :"votes.#{params[:vote]}.number" => 1 } })
  else
    POLLS.update_one({:code => params[:poll]}, {:"$set" => {:"vote.#{params[:vote]}" => {
      :number => 1,
      :primary => false
    }}})
  end
end

get '/poll/:poll/votes.json' do
  (Hash.from_bson POLLS.find({:code => params[:poll]}).to_a.first.to_bson)[:votes].to_json
end

get '/polls.json' do
  POLLS.find.to_a.map { |doc| doc[:code] }.to_json
end
