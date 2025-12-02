# Deployment Guide for Emergency Alert System

This guide covers deploying your Flask application to various platforms.

## Prerequisites

1. **Environment Variables** - You'll need these set on your deployment platform:
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_KEY` - Your Supabase service role key (NOT the anon key)
   - `SECRET_KEY` - A secret key for Flask sessions (generate with: `python -c "import secrets; print(secrets.token_hex(32))"`)
   - `PORT` - Usually set automatically by the platform
   - `FLASK_DEBUG` - Set to `false` for production

2. **Git Repository** - Your code should be in a Git repository (GitHub, GitLab, etc.)

## Quick Deployment Options

### 🚂 Railway (Recommended - Easiest)

1. Go to [railway.app](https://railway.app) and sign up
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repository
4. Railway will auto-detect Python and install dependencies
5. Go to "Variables" tab and add:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `SECRET_KEY`
6. Your app will deploy automatically!

**Cost**: Free tier available, then ~$5/month

---

### 🎨 Render

1. Go to [render.com](https://render.com) and sign up
2. Click "New" → "Web Service"
3. Connect your GitHub repository
4. Configure:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app`
   - **Environment**: Python 3
5. Add environment variables in the dashboard
6. Click "Create Web Service"

**Cost**: Free tier (spins down after inactivity), then $7/month

---

### 🟣 Heroku

1. Install Heroku CLI: [devcenter.heroku.com/articles/heroku-cli](https://devcenter.heroku.com/articles/heroku-cli)
2. Login: `heroku login`
3. Create app: `heroku create your-app-name`
4. Set environment variables:
   ```bash
   heroku config:set SUPABASE_URL=your_url
   heroku config:set SUPABASE_KEY=your_key
   heroku config:set SECRET_KEY=your_secret_key
   ```
5. Deploy: `git push heroku main`

**Cost**: No free tier, starts at $5/month

---

### 🪰 Fly.io

1. Install flyctl: [fly.io/docs/getting-started/installing-flyctl](https://fly.io/docs/getting-started/installing-flyctl)
2. Login: `fly auth login`
3. Launch: `fly launch` (follow prompts)
4. Set secrets:
   ```bash
   fly secrets set SUPABASE_URL=your_url
   fly secrets set SUPABASE_KEY=your_key
   fly secrets set SECRET_KEY=your_secret_key
   ```
5. Deploy: `fly deploy`

**Cost**: Free tier available

---

### 🐍 PythonAnywhere

1. Sign up at [pythonanywhere.com](https://www.pythonanywhere.com)
2. Go to "Files" tab and upload your files (or use Git)
3. Go to "Web" tab → "Add a new web app"
4. Choose Flask and Python 3.10+
5. Edit the WSGI file to point to your app
6. Set environment variables in "Web" → "Static files" section
7. Reload the web app

**Cost**: Free tier (limited), then $5/month

---

## Environment Variables Setup

For all platforms, make sure to set:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_service_role_key_here
SECRET_KEY=generate_a_random_secret_key_here
FLASK_DEBUG=false
```

**Important**: Use the **service_role** key from Supabase, NOT the anon key. This bypasses RLS policies for backend operations.

## Post-Deployment Checklist

- [ ] Verify environment variables are set correctly
- [ ] Test the `/health` endpoint
- [ ] Test login functionality
- [ ] Verify Supabase connection is working
- [ ] Check application logs for errors
- [ ] Test file uploads (if applicable)
- [ ] Verify static files are being served

## Troubleshooting

### App won't start
- Check logs for errors
- Verify all environment variables are set
- Ensure `gunicorn` is in requirements.txt
- Check that PORT environment variable is being used

### Database connection errors
- Verify SUPABASE_URL and SUPABASE_KEY are correct
- Make sure you're using the service_role key, not anon key
- Check Supabase project is active

### Static files not loading
- Verify static files are in the `static/` directory
- Check Flask static file configuration
- Some platforms may need additional configuration

## Need Help?

- Check platform-specific documentation
- Review application logs
- Verify environment variables are set correctly
- Test locally first with the same environment variables


