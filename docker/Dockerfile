FROM ruby:3.1.4

ENV APP_DIR /app

ARG USER $USER
ENV USER $USER

ARG UID $UID
ENV UID $UID

ARG GID $GID
ENV GID $GID

ENV PATH $APP_DIR/bin:$PATH
ENV DBUS_SESSION_BUS_ADDRESS $DBUS_SESSION_BUS_ADDRESS

COPY . $APP_DIR

WORKDIR $APP_DIR

# Install dependencies
RUN apt-get update -qq && \
    apt install -y dbus dbus-user-session && \
    groupadd -g $GID $USER && \
    useradd -m -u $UID -g $GID $USER && \
    chown -R $USER:$USER $APP_DIR

USER $USER

RUN bundle install

ENTRYPOINT ["bin/playon"]
