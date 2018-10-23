FROM ruby:2.5.2-alpine

RUN apk update && apk --update --no-cache add libstdc++
RUN apk --update --no-cache add --virtual .build_deps git g++ musl-dev make
RUN apk upgrade

COPY Gemfile /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock
WORKDIR /usr/src/app

RUN bundle config --global silence_root_warning 1
RUN bundle install

RUN gem cleanup
RUN apk del .build_deps

COPY . /usr/src/app

ENV PORT 8080
EXPOSE 8080

CMD ["bundle", "exec", "ruby", "/usr/src/app/server.rb", "-o", "0.0.0.0"]
