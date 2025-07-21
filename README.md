# PDF to Markdown Converter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue)](https://docker.com)

> 📖 **한국어**: [README-ko.md](./README-ko.md)

A powerful Next.js application that converts PDF files to Markdown using Mistral AI's OCR capabilities. This project supports both Vercel cloud deployment and self-hosted Docker deployment.

## 📖 About This Project

This is a modified version of [pdf2md](https://github.com/link2004/pdf2md) by riku ogawa, enhanced with:

- 🐳 **Docker deployment support** with nginx proxy
- 📁 **Local file storage** (alternative to Vercel Blob)
- 🔧 **Nginx Proxy Manager compatibility**
- 🛡️ **Production-ready security configurations**
- 📊 **Monitoring and backup capabilities**
- 🌏 **Korean server environment optimizations**

## ✨ Features

- 📄 **PDF Upload**: Support for PDF files up to 100MB
- 🤖 **AI-Powered OCR**: Uses Mistral AI for accurate text extraction
- 📝 **Markdown Conversion**: Converts extracted text to clean Markdown
- ✏️ **Live Editor**: Edit and preview Markdown in real-time
- 💾 **Multiple Export Formats**: Download as .md, .html, or .pdf
- 🔄 **Batch Processing**: Handle multiple files simultaneously
- 🐳 **Docker Ready**: Easy deployment with Docker Compose

## 🚀 Quick Start

### Cloud Deployment (Vercel)

1. **Get Mistral AI API Key**
   - Visit [Mistral AI](https://mistral.ai/) and create an account
   - Generate an API key from the dashboard

2. **Set up Vercel Blob Storage**
   - Create a new Vercel project
   - Add Blob storage in the Storage tab
   - Configure environment variables

3. **Deploy**
   ```bash
   git clone https://github.com/link2004/pdf2md.git
   cd pdf2md
   cp .env.example .env
   # Add your MISTRAL_API_KEY and BLOB_READ_WRITE_TOKEN
   vercel deploy
   ```

### 🐳 Docker Deployment (Self-Hosted)

Perfect for private servers with nginx proxy manager:

#### Prerequisites
- Docker & Docker Compose
- Nginx Proxy Manager (or similar reverse proxy)
- External network: `npm_default`

#### Quick Setup

1. **Copy configuration files**
   ```bash
   cp env.server.example .env
   cp docker-compose.server.yml docker-compose.yml
   ```

2. **Edit environment variables**
   ```bash
   nano .env
   # Set your MISTRAL_API_KEY and domain
   ```

3. **Update paths in docker-compose.yml**
   ```yaml
   volumes:
     - /path/to/your/data:/app/uploads        # Your data path
     - /path/to/your/data/logs:/app/logs      # Your logs path
   
   ports:
     - '127.0.0.1:YOUR_PORT:3000'             # Your port (e.g., 3002)
   ```

4. **Create data directories**
   ```bash
   sudo mkdir -p /path/to/your/data/{logs,backups}
   sudo chown -R $USER:$USER /path/to/your/data
   ```

5. **Deploy**
   ```bash
   # Basic service
   docker-compose up -d
   
   # With backup service
   docker-compose --profile backup up -d
   ```

6. **Configure Nginx Proxy Manager**
   - Target: `http://127.0.0.1:YOUR_PORT`
   - Domain: `your-domain.com`
   - SSL: Enable Let's Encrypt

For detailed deployment instructions, see [README-DOCKER.md](./README-DOCKER.md)

## 🔧 Development

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Testing

```bash
# Run tests
npm test

# Run tests in watch mode
npm test:watch

# Run integration tests
npm run test:integration
```

## 📋 Environment Variables

### Required
- `MISTRAL_API_KEY`: Your Mistral AI API key

### For Vercel Deployment
- `BLOB_READ_WRITE_TOKEN`: Vercel Blob storage token

### For Docker Deployment
- `NEXT_PUBLIC_APP_URL`: Your domain URL
- `UPLOAD_DIR`: Upload directory path (default: `/app/uploads`)

### Optional
- `NODE_ENV`: Environment (development/production)
- `NEXT_TELEMETRY_DISABLED`: Disable Next.js telemetry
- `BACKUP_RETENTION_DAYS`: Backup retention period (default: 30)

## 🏗️ Architecture

### Cloud Architecture (Vercel)
```
Internet → Vercel Edge → Next.js App → Mistral AI
                     ↓
                Vercel Blob Storage
```

### Self-Hosted Architecture (Docker)
```
Internet → Nginx Proxy → Next.js Container → Mistral AI
                      ↓
                Local File System
```

## 📊 Monitoring & Management

### Docker Deployment Features
- 🔍 **Health Checks**: Automatic container health monitoring
- 📊 **Prometheus Metrics**: Optional monitoring stack
- 📈 **Grafana Dashboards**: Visual monitoring interface
- 📝 **Log Aggregation**: Centralized logging with Loki
- 💾 **Automated Backups**: Daily backup with retention policy

### Management Commands
```bash
# View logs
docker logs pdf2md

# Check health
curl http://localhost:YOUR_PORT/api/health

# Manual backup
docker-compose --profile backup run --rm backup

# Update application
docker-compose up --build -d
```

## 🛡️ Security Features

- 🔐 **File Type Validation**: Only PDF files allowed
- 📏 **Size Limits**: 100MB maximum file size
- 🛡️ **Security Headers**: Comprehensive security headers
- 🚫 **Rate Limiting**: API and upload rate limiting
- 🔒 **SSL/TLS**: Automatic HTTPS with Let's Encrypt
- 👤 **Non-root Containers**: Secure container execution

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original project by [riku ogawa](https://github.com/link2004/pdf2md)
- [Mistral AI](https://mistral.ai/) for OCR capabilities
- [Next.js](https://nextjs.org/) framework
- [Vercel](https://vercel.com/) for cloud hosting platform

## 🆘 Support

- 📖 [Documentation](./README-DOCKER.md)
- 🐛 [Report Issues](https://github.com/your-username/pdf2md/issues)
- 💬 [Discussions](https://github.com/your-username/pdf2md/discussions)

## 🗃️ Version History

- **v1.1.0** - Added Docker support and local file storage
- **v1.0.0** - Original Vercel-based deployment (by riku ogawa)

---

**🌟 Star this repository if you find it helpful!**
