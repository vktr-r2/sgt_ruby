FROM ruby:3.3.2-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfiles
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy app
COPY . .

# Set production environment
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=1
ENV RAILS_LOG_TO_STDOUT=1

# Start command - Rails will use PORT env var automatically
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]