FROM buildpack-deps:stretch-curl

# Ruby installations

# Dependencies for various ruby and rubygem installations
RUN apt-get update \
  && apt-get install -y libreadline-dev bzip2 build-essential libssl1.0-dev zlib1g-dev libpq-dev libsqlite3-dev \
  curl patch gawk g++ gcc git make libc6-dev patch libreadline6-dev libyaml-dev sqlite3 autoconf \
  libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev bison libxslt-dev \
  libxml2-dev default-libmysqlclient-dev wget unixodbc-dev freetds-dev freetds-bin --no-install-recommends

# rbenv
RUN git clone https://github.com/rbenv/rbenv.git /usr/local/.rbenv
RUN chmod -R 777 /usr/local/.rbenv

ENV RBENV_ROOT="/usr/local/.rbenv"

ENV PATH="$RBENV_ROOT/bin:/usr/local:$PATH"

RUN git clone https://github.com/rbenv/ruby-build.git /usr/local/.rbenv/plugins/ruby-build
RUN chmod -R 777 /usr/local/.rbenv/plugins/ruby-build

RUN /usr/local/.rbenv/plugins/ruby-build/install.sh

# Install ruby 2.3.3 (default), 2.3.8, 2.4.5
ENV RUBY_CONFIGURE_OPTS=--disable-install-doc

ENV RUBY_CFLAGS=-O3

RUN eval "$(rbenv init -)" \
  && export WEBSITES_DEFAULT_RUBY_VERSION="2.3.3" \
  && rbenv install $WEBSITES_DEFAULT_RUBY_VERSION \
  && rbenv install "2.3.8" \
  && rbenv install "2.4.5" \
  && rbenv install "2.5.5" \
  && rbenv install "2.6.2" \
  && rbenv rehash \
  && rbenv global $WEBSITES_DEFAULT_RUBY_VERSION \
  && ls /usr/local -a \
  && rbenv local $WEBSITES_DEFAULT_RUBY_VERSION \
  && gem install bundler --version "=1.13.6" \
  && rbenv local 2.3.8 \
  && gem install bundler --version "=1.13.6" \
  && rbenv local 2.4.5 \
  && gem install bundler --version "=1.13.6" \
  && rbenv local 2.5.5 \
  && gem install bundler --version "=1.13.6" \
  && rbenv local 2.6.2 \
  && gem install bundler --version "=1.13.6" \
  && rbenv local $WEBSITES_DEFAULT_RUBY_VERSION \
  && chmod -R 777 /usr/local/.rbenv/versions \
  && chmod -R 777 /usr/local/.rbenv/version

RUN eval "$(rbenv init -)" \
  && rbenv global $WEBSITES_DEFAULT_RUBY_VERSION \
  && bundle config --global build.nokogiri -- --use-system-libraries

# Because Nokogiri tries to build libraries on its own otherwise
ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=true
