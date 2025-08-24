# syntax = docker/dockerfile:1

# ========================================
# Stage 0: Base image
# ========================================
ARG RUBY_VERSION=3.2.6
FROM ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# ========================================
# Stage 1: Build stage
# ========================================
FROM base as build

# Install system dependencies for gems & node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      libvips \
      node-gyp \
      pkg-config \
      python-is-python3 \
      libpq-dev

# Install Node & Yarn
ARG NODE_VERSION=22.12.0
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Install Bundler
RUN gem install bundler -v 2.5.5

# Copy Gemfile & install gems
COPY Gemfile Gemfile.lock ./
RUN bundle _2.5.5_ install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy JS package files & install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Ensure docker-entrypoint has execution permission
RUN chmod +x bin/docker-entrypoint

# Precompile bootsnap & assets for production
ENV SECRET_KEY_BASE=dummy_secret_key_base
ENV RAILS_MASTER_KEY=dummy_master_key
RUN ruby ./bin/rails assets:precompile
RUN bundle exec bootsnap precompile app/ lib/

# ========================================
# Stage 2: Final image
# ========================================
FROM base

# Install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libsqlite3-0 \
      libvips \
      libpq5 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose default Rails port
EXPOSE 3000

# Default command
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
