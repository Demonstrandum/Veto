require 'mongo'
require 'json'

require 'sinatra'

set :run, true
set :server, %w{ thin }

set :port, 8088
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
    :code    =>  code,
    :name    =>  name,
    :votes   =>  {},
    :alt     =>  alt,
    :voters  =>  [],
    :created =>  Time.now
  }
  POLLS.insert_one poll
end

class String
  def pseudo_dot
    self.gsub '.', "\u2024"  # Full-stop look-alike, since MongoDB uses dot notation.
  end

  def pseudo_dot!
    replace pseudo_dot
  end
end

DESC = "Create real time straw polls. " +
       "Easy to use, Free and Open Source Software."
HEAD_TAGS = <<-HTML
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <!-- Global site tag (gtag.js) - Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=UA-129403871-1"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', 'UA-129403871-1');
  </script>

  <!-- Search Engine -->
  <meta name="description" content="#{DESC}">
  <meta name="image" content="https://veto.vote/square.png">
  <!-- Schema.org for Google -->
  <meta itemprop="name" content="Veto Vote — Straw Polls">
  <meta itemprop="description" content="#{DESC}">
  <meta itemprop="image" content="https://veto.vote/square.png">
  <!-- Twitter -->
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="Veto Vote — Straw Polls">
  <meta name="twitter:description" content="#{DESC}">
  <meta name="twitter:image:src" content="https://veto.vote/square.png">
  <!-- Open Graph general (Facebook, Pinterest & Google+) -->
  <meta name="og:title" content="Veto Vote — Straw Polls">
  <meta name="og:description" content="#{DESC}">
  <meta name="og:image" content="https://veto.vote/card.png">
  <meta name="og:url" content="https://veto.vote/">
  <meta name="og:site_name" content="Veto Vote — Straw Polls">
  <meta name="og:type" content="website">

  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
  <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
  <link rel="manifest" href="/site.webmanifest" />
  <link rel="mask-icon" href="/safari-pinned-tab.svg" color="#303030" />
  <meta name="msapplication-TileColor" content="#ffffff" />
  <meta name="theme-color" content="#ffffff" />

  <link rel="stylesheet" type="text/css" href="https://use.fontawesome.com/releases/v5.5.0/css/all.css" integrity="sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU" crossorigin="anonymous">
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
  erb :index, :locals => {:head_tags => HEAD_TAGS}
end

get '/poll' do
  redirect '/'
end

get '/share/:code' do
  erb :share, :locals => {:head_tags => HEAD_TAGS}
end

post '/new' do
  params[:code] = URI.decode_www_form_component params[:code]
  return nil if poll_exist? params[:code]

  make_poll(
    params[:code],
    params[:name],
    params[:alt])

  params[:primary].each do |option|
    POLLS.update_one({:code => params[:code]}, {
      :"$set" => {
        :"votes.#{option.pseudo_dot}" => {
          :number => 0,
          :primary => true,
          :date => Time.now
        }
      }
    })
  end
end

get '/poll/:poll' do
  unless poll_exist? params[:poll]
    status 404
    return erb :oops, :locals => {:head_tags => HEAD_TAGS}
  end

  local = {:code => params[:poll], :head_tags => HEAD_TAGS}
  local.merge! Hash.from_bson POLLS.find({:code => params[:poll]}).first.to_bson
  erb :poll, :locals => local
end

post '/poll/:poll/cast' do
  params[:vote].pseudo_dot!
  if params[:vote].strip.empty?
    status 406
    return "Cannot cast empty vote."
  end

  return nil if request.ip != '::1' && POLLS.find(:"$and" => [{:code => params[:poll]}, {:voters => request.ip}]).to_a.size > 0
  POLLS.update_one({:code => params[:poll]}, {:"$push" => {:voters => request.ip}}) unless request.ip == '::1'

  if POLLS.find({ :"$and" => [{:code => params[:poll]}, { :"votes.#{params[:vote]}" => {"$exists": true}}] }).to_a.size > 0
    POLLS.update_one({:code => params[:poll]}, { :"$inc" => { :"votes.#{params[:vote]}.number" => 1 } })
  elsif POLLS.find({:code => params[:poll]}).first[:alt]
    POLLS.update_one({:code => params[:poll]}, { :"$set" => { :"votes.#{params[:vote]}" => {
      :number => 1,
      :primary => false,
      :date => Time.now
    }}})
  end
end

get '/poll/:poll/votes.json' do
  (Hash.from_bson POLLS.find({:code => params[:poll]}).to_a.first.to_bson)[:votes].to_json
end

get '/polls.json' do
  POLLS.find.to_a.map { |doc| doc[:code] }.to_json
end

get '/poll/:poll/has-voted' do
  (POLLS.find(:"$and" => [
    {:code   => params[:poll]},
    {:voters => request.ip   }
  ]).to_a.size > 0).to_s
end

not_found do
  status 404
  erb :oops, :locals => {:head_tags => HEAD_TAGS}
end
