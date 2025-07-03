FROM ruby:3.3
RUN bundle config --global frozen 1
WORKDIR /usr/src/bitcoin_wallet
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform x86_64-linux \
    && bundle install
COPY . .
ENTRYPOINT ["tail", "-f", "/dev/null"]
