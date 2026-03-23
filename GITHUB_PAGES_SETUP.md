# GitHub Pages Setup for octclaw.xyz

## Automatic Deployment

The website is now configured for automatic deployment via GitHub Pages. When you push to the `main` branch, GitHub Actions will automatically deploy the site.

## Manual Setup (if needed)

If automatic deployment doesn't work, follow these steps:

### 1. Enable GitHub Pages
1. Go to your repository on GitHub: https://github.com/2045max/octclaw
2. Click on **Settings**
3. Scroll down to **Pages** in the left sidebar
4. Under **Source**, select:
   - **Deploy from a branch**: `main`
   - **Branch**: `main` → `/ (root)`
5. Click **Save**

### 2. Wait for Deployment
GitHub Pages will build and deploy your site. This usually takes 1-2 minutes.

### 3. Access Your Site
Your site will be available at:
- **GitHub Pages URL**: https://2045max.github.io/octclaw/
- **Custom domain** (if configured): https://octclaw.xyz

## Website Structure

- `index.html` - Redirect page to main website
- `octclaw_website.html` - Main website (the actual content)
- `.github/workflows/deploy.yml` - GitHub Actions deployment workflow

## Custom Domain Setup

To use octclaw.xyz:

### 1. Configure DNS
Add these DNS records to your domain registrar:

```
Type    Name    Value
CNAME   @       2045max.github.io
CNAME   www     2045max.github.io
```

### 2. Configure in GitHub
1. Go to repository **Settings** → **Pages**
2. Under **Custom domain**, enter: `octclaw.xyz`
3. Check **Enforce HTTPS**
4. Click **Save**

### 3. Wait for SSL Certificate
GitHub will automatically provision an SSL certificate (may take up to 24 hours).

## Testing Locally

You can test the website locally by opening `octclaw_website.html` in your browser, or using a local server:

```bash
# Python 3
python3 -m http.server 8000

# Then open: http://localhost:8000/octclaw_website.html
```

## Website Features

The website includes:
- 🐙 OctClaw branding with orange color scheme
- Responsive design for mobile and desktop
- Interactive copy button for install command
- Platform compatibility grid
- Messaging integration showcase
- Skills system explanation
- GitHub Actions auto-deployment

## Troubleshooting

### GitHub Pages not updating
1. Check GitHub Actions workflow runs
2. Wait a few minutes for deployment
3. Clear browser cache

### Custom domain not working
1. Verify DNS records are correct (may take up to 48 hours to propagate)
2. Check GitHub Pages settings
3. Ensure domain is properly configured in repository settings

### SSL certificate issues
GitHub automatically provides SSL certificates. If you see certificate errors:
1. Wait 24 hours for certificate provisioning
2. Ensure "Enforce HTTPS" is checked in GitHub Pages settings