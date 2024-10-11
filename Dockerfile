
FROM ruby:2.6

# Install dependencies required for Rails and MySQL
RUN apt-get update -qq && apt-get install -y nodejs default-mysql-client

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the working directory
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# Install the Bundler version specified in Gemfile.lock
RUN gem install bundler -v 2.4.7

# Install the gems specified in the Gemfile
RUN bundle install

# Copy the main application
COPY . /app


# Expose the port the app runs on
EXPOSE 3000

# Start the main process (Rails server)
CMD ["rails", "server", "-b", "0.0.0.0"]
