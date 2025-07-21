# PDF2MD Docker Deployment Guide

Docker production deployment guide for the Next.js application that converts PDF files to Markdown.

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Create environment variables file
cp env.prod.example .env

# Edit environment variables
nano .env
```

**Required Settings:**
- `MISTRAL_API_KEY`: Mistral AI API key
- `DOMAIN`: Domain name (e.g., your-domain.com)
- `SSL_EMAIL`: Email address for SSL certificates

### 2. Run Deployment

```bash
# Execute deployment script
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 📋 System Requirements

- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **Memory**: Minimum 2GB (Recommended 4GB+)
- **Disk**: Minimum 10GB (for uploaded file storage)
- **Ports**: 80, 443 (HTTP/HTTPS)

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Internet  │───▶│    Nginx    │───▶│  Next.js    │
│             │    │ (SSL/Proxy) │    │    App      │
└─────────────┘    └─────────────┘    └─────────────┘
                           │
                   ┌───────▼───────┐
                   │  Let's Encrypt │
                   │   (Certbot)    │
                   └───────────────┘
```

## 🔧 Key Components

### Services

- **pdf2md**: Next.js application
- **nginx**: Reverse proxy + SSL termination
- **certbot**: Let's Encrypt SSL certificate auto-renewal
- **prometheus**: Monitoring (optional)
- **grafana**: Dashboard (optional)
- **backup**: Automatic backup

### Volumes

- `uploads`: Uploaded file storage
- `ssl`: SSL certificate storage
- `logs`: Application logs
- `backups`: Backup files

## 📂 Directory Structure

```
pdf2md/
├── docker-compose.yml          # Basic configuration
├── docker-compose.prod.yml     # Production configuration
├── Dockerfile                  # Application image
├── env.prod.example           # Environment variables example
├── nginx/
│   ├── nginx.conf             # Nginx main configuration
│   └── conf.d/
│       └── pdf2md.conf        # Virtual host configuration
├── scripts/
│   ├── deploy.sh              # Deployment script
│   └── backup.sh              # Backup script
└── monitoring/
    └── prometheus.yml         # Monitoring configuration
```

## 🚀 Deployment Commands

### Basic Deployment
```bash
# Start production services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### SSL Certificate Setup
```bash
# Obtain Let's Encrypt certificate
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl run --rm certbot

# Start SSL renewal service
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl up -d
```

### Enable Monitoring
```bash
# Start Prometheus + Grafana
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile monitoring up -d
```

### Run Backup
```bash
# Manual backup
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile backup run --rm backup
```

## 🔍 Monitoring & Management

### View Logs
```bash
# All logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

# Specific service logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f pdf2md
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f nginx
```

### Check Service Status
```bash
# Container status
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps

# Health check
curl -f http://localhost:3000/api/health
```

### Access URLs
- **Main Site**: https://YOUR_DOMAIN.com
- **Grafana**: http://YOUR_DOMAIN.com:3001
- **Prometheus**: http://YOUR_DOMAIN.com:9090

## 🔐 Security Settings

### SSL/TLS
- **Protocols**: TLS 1.2, 1.3
- **Certificates**: Let's Encrypt (auto-renewal)
- **HSTS**: Enabled
- **OCSP Stapling**: Enabled

### Security Headers
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Content-Security-Policy
- Strict-Transport-Security

### Rate Limiting
- API: 10 req/sec
- Upload: 2 req/sec
- Connection: 20/IP

## 🛠️ Maintenance

### Updates
```bash
# Application update
git pull
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Backup Restoration
```bash
# List backup files
ls -la backups/

# Restore backup (example)
tar -xzf backups/pdf2md_backup_20241220_120000.tar.gz -C /tmp
cp -r /tmp/pdf2md_backup_20241220_120000/uploads/* uploads/
```

### Manual SSL Certificate Renewal
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl exec certbot-renew certbot renew
docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx
```

## 🐛 Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check port usage
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   ```

2. **SSL Certificate Errors**
   ```bash
   # Check certificate status
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml --profile ssl logs certbot
   ```

3. **Memory Issues**
   ```bash
   # Check memory usage
   docker stats
   ```

### Log Locations
- **Nginx**: `nginx-logs` volume
- **Application**: `logs` volume
- **SSL**: `certbot-logs` volume

## 📞 Support

If you encounter issues, please check:

1. Environment variable configuration (`.env` file)
2. Domain DNS settings
3. Firewall settings (ports 80, 443)
4. Docker service status

---

**Domain**: YOUR_DOMAIN.com  
**Server IP**: YOUR.SERVER.IP  
**DDNS**: your-ddns-host.com 