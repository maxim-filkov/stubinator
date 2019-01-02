# Use the barebones version of Ruby 2.2.3.
FROM ruby:2.5-slim

RUN apt-get update && \
    apt-get install -y net-tools && \
    apt-get install -y build-essential && \
    apt-get install -y curl

# install the app path
ENV APP_HOME /app
ENV HOME /root
RUN mkdir -p $APP_HOME

# set the context of where the server will be ran
WORKDIR $APP_HOME

# ensure gems are cached and only get updated when they change, this will
# drastically increase build times when your gems do not change
COPY Gemfile* $APP_HOME/
RUN bundle install

# copy in the application code
COPY . $APP_HOME

ENV PORT 3000
EXPOSE 3000

# The default command that gets ran will be to start the Unicorn server.
ENTRYPOINT ["bundle", "exec", "passenger", "start"]