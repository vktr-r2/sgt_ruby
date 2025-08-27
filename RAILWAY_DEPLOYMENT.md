# Railway Deployment Guide

## Required Environment Variables

Set these environment variables in your Railway project:

### Rails Configuration
```
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=1
RAILS_SERVE_STATIC_FILES=1
RAILS_MASTER_KEY=<your_master_key_from_config/master.key>
```

### Database Configuration
Railway will automatically provide `DATABASE_URL` when you add a PostgreSQL service.
Alternatively, you can set individual variables:
```
DATABASE_URL=<railway_provided_postgres_url>
POSTGRES_DATABASE=<database_name>
POSTGRES_USER=<username>
POSTGRES_PASSWORD=<password>
DATABASE_HOST=<host>
DB_PORT=5432
```

### Additional Configuration (Optional)
```
SECRET_KEY_BASE=<generate_with_rails_secret>
DEVISE_SECRET_KEY=<generate_with_rails_secret>
PORT=3000
```

## Deployment Steps

1. **Create Railway Project:**
   ```bash
   npm install -g @railway/cli
   railway login
   railway init
   ```

2. **Add PostgreSQL Service:**
   - In Railway dashboard, click "New Service"
   - Select "PostgreSQL"
   - Railway will provide `DATABASE_URL` automatically

3. **Configure Environment Variables:**
   - Go to your service settings in Railway dashboard
   - Add the environment variables listed above
   - Get your `RAILS_MASTER_KEY` from `config/master.key`

4. **Deploy:**
   ```bash
   railway up
   ```

5. **Run Database Setup (First Deploy Only):**
   ```bash
   railway run rails db:migrate
   railway run rails db:seed
   ```

## Port Configuration

Railway expects your app to listen on the port specified by the `PORT` environment variable (default 3000). The Dockerfile is configured to expose port 80, but Puma will bind to the PORT env var.

## Health Check

Railway will use the `/` endpoint for health checks as configured in `railway.toml`.

## File Structure
- `railway.toml` - Railway configuration
- `Dockerfile` - Container configuration (PostgreSQL ready)
- `.railwayignore` - Files to exclude from deployment
- `RAILWAY_DEPLOYMENT.md` - This deployment guide