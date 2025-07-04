FROM ruby:3.1.4

# Set the working directory
ENV APP_DIR /app
WORKDIR $APP_DIR

# Set up a non-root user
ARG USER
ARG UID
ARG GID
ENV USER=${USER:-user}
ENV UID=${UID:-1000}
ENV GID=${GID:-1000}

# Install dependencies and create the user
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends dbus dbus-user-session && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g $GID $USER && \
    useradd -m -u $UID -g $GID $USER

# Copy the Gemfile and Gemfile.lock and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application code
COPY . .

# Set the user
USER $USER

# Set the entrypoint
ENTRYPOINT ["bin/playon"]