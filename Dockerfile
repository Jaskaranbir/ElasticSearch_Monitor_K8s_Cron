FROM ruby:2.5.0-alpine3.7

LABEL MAINTAINER Jaskaranbir Dhillon

WORKDIR /service

COPY ./Gemfile /service
COPY ./lib /service/lib
COPY init.rb /service

RUN bundle install
CMD ["/service/init.rb"]
