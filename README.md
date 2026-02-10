# SGT (Spreadsheet Golf Tour)

A Rails API backend for a fantasy golf competition where friends compete by drafting PGA Tour golfers each week.

![Ruby](https://img.shields.io/badge/Ruby-3.3.2-CC342D?logo=ruby)
![Rails](https://img.shields.io/badge/Rails-8.0-D30001?logo=rubyonrails)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12+-4169E1?logo=postgresql)
![Redis](https://img.shields.io/badge/Redis-5.4+-DC382D?logo=redis)
![Sidekiq](https://img.shields.io/badge/Sidekiq-7.3-B1003E)

---

## Prerequisites

- Ruby 3.3.2
- PostgreSQL 12+
- Redis 5.4+
- Bundler

---

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `REDIS_URL` | Redis connection string (e.g., `redis://localhost:6379`) |
| `RAPIDAPI_KEY` | Live Golf Data API key from RapidAPI |
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Rails encryption key |
| `RAILS_MASTER_KEY` | Credentials decryption key |

### Email (Production)

| Variable | Description |
|----------|-------------|
| `SMTP_ADDRESS` | SMTP server (e.g., `smtp.sendgrid.net`) |
| `SMTP_PORT` | SMTP port (e.g., `587`) |
| `SMTP_DOMAIN` | SMTP domain |
| `SMTP_USERNAME` | SMTP username (e.g., `apikey` for SendGrid) |
| `SMTP_PASSWORD` | SMTP password or API key |
| `MAILER_FROM_ADDRESS` | From email address |
| `APP_HOST` | Backend host URL |
| `FRONTEND_URL` | Frontend app URL (for password reset links) |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `RAILS_ENV` | `development` | Environment mode |
| `RAILS_LOG_LEVEL` | `info` | Logging verbosity |
| `PORT` | `3000` | Server port |
| `RAILS_SERVE_STATIC_FILES` | - | Enable for production |
| `RAILS_LOG_TO_STDOUT` | - | Enable for production logging |
| `WEB_CONCURRENCY` | `2` | Puma worker count |
| `RAILS_MAX_THREADS` | `5` | Threads per worker |

---

## Local Development Setup

```bash
# Install dependencies
bundle install

# Start PostgreSQL (macOS)
brew services start postgresql

# Start Redis
redis-server

# Setup database
rails db:create db:migrate db:seed

# Start Rails server
rails server

# Start Sidekiq (separate terminal)
bundle exec sidekiq
```

---

## Database Commands

```bash
rails db:create              # Create database
rails db:migrate             # Run migrations
rails db:seed                # Seed initial data
rails db:reset               # Drop, create, migrate, seed
rails db:drop db:create db:migrate db:seed  # Full reset
```

---

## Running Tests

```bash
rspec                        # Full test suite (~400+ tests)
rspec spec/requests/         # API tests only
rspec spec/services/         # Service tests only
rspec --format documentation # Verbose output

rubocop                      # Linting
rubocop -A                   # Auto-fix offenses
```

---

## Cron Job Schedule

All times are in EST.

| Job | Schedule | Purpose |
|-----|----------|---------|
| `ScheduleImportJob` | Jan 26, 10:00 PM | Annual PGA Tour schedule import |
| `TournamentImportJob` | Tuesday 12:00 AM | Weekly tournament and golfer data |
| `ValidatePicksJob` | Wednesday 11:59 PM | Randomize missing draft picks |
| `SnakeDraftJob` | Thursday 12:00 AM | Assign golfers via snake draft |
| `LeaderboardImportJob` | Daily 9AM, 12PM, 3PM, 6PM, 9PM, 12AM | Score updates during tournaments |
| `MatchResultsJob` | Monday 12:00 AM | Calculate weekly match results |

---

## Manual Job Execution

```ruby
# In Rails console
rails console

# Import annual schedule
ScheduleImportJob.perform_now

# Import current week's tournament and golfers
TournamentImportJob.perform_now

# Update leaderboard scores
LeaderboardImportJob.perform_now

# Calculate match results
MatchResultsJob.perform_now

# IMPORTANT: After modifying Ruby files, reload!
reload!
```

---

## Production Deployment (Railway)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and initialize
railway login
railway init

# Add PostgreSQL and Redis services in Railway dashboard
# Set environment variables in Railway dashboard

# Deploy
railway up

# First deploy only - run migrations
railway run rails db:migrate
```

---

## API Endpoints

### Tournament Data

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tournaments/current/scores` | Live tournament leaderboard (drafted golfers) |
| GET | `/api/tournaments/current/full_leaderboard` | All 150+ tournament players |
| GET | `/api/tournaments/history` | Paginated past tournaments |
| GET | `/api/tournaments/:id/results` | Specific tournament results |

### Standings

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/standings/season?year=YYYY` | Cumulative season standings |
| GET | `/api/standings/seasons` | List all historical seasons |
| GET | `/api/standings/season/:year` | Detailed season with tournaments |

### App Info

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/app_info` | Draft window status (`before_window`, `open`, `after_window`) |

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/users/sign_in` | User login |
| DELETE | `/users/sign_out` | User logout |
| POST | `/users/password` | Request password reset |
| PUT | `/users/password` | Reset password with token |

### Admin

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/admin/users/:id/generate_reset_link` | Generate password reset link |

---

## Useful Console Commands

```ruby
# Get current tournament
tournament = BusinessLogic::TournamentService.new.current_tournament

# View drafted picks for current tournament
MatchPick.where(tournament: tournament, drafted: true).includes(:golfer)

# Check scores for a tournament
Score.joins(:match_pick).where(match_picks: { tournament: tournament })

# View API data for debugging
client = RapidApi::LeaderboardClient.new
data = client.fetch_leaderboard(tournament.unique_id)

# After modifying Ruby files in console
reload!
```

---

## API Rate Limits

- **RapidAPI**: 250 calls/month (Live Golf Data API)
- **Per Tournament Week**: ~15 calls (1 import + 14 leaderboard updates)
- **Monthly Capacity**: ~16 tournaments

---

## Security Features

- Account lockout after 5 failed login attempts (15 minute cooldown)
- Rate limiting: 5 login attempts per 15 minutes, 100 API calls per minute
- Security headers: X-Frame-Options, X-XSS-Protection, X-Content-Type-Options
- Bearer token authentication via Devise

---

## License

Private project - All rights reserved.
