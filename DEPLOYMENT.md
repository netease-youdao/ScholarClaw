# Deployment Guide

This guide explains how to deploy ScholarClaw and its backend services.

## Prerequisites

- Python 3.9+
- Node.js 16+ (optional, for TypeScript client)
- Docker (optional, for containerized deployment)
- Access to the following services:
  - ArXiv search server
  - PubMed search server
  - OpenAlex search server
  - QAnything service (for blog generation)

## Architecture

```
┌─────────────────┐
│   LobsterAI     │
│   Application   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ScholarClaw    │
│  Skill (this)   │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────────────────────────────────────┐
│         Unified Search Server (Port 8090)       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Search   │ │ Scholar  │ │ Citation │        │
│  │ Routes   │ │ Routes   │ │ Routes   │        │
│  └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│              Backend Services                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │  ArXiv   │ │  PubMed  │ │ OpenAlex │ ...    │
│  │ (8101)   │ │ (8103)   │ │ (8105)   │        │
│  └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────┘
```

## Local Development

### 1. Start Backend Services

First, ensure all backend services are running:

```bash
# Navigate to the project directory
cd /ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers

# Start individual services (or use a process manager)
python searchengines/arxiv_search_server.py &      # Port 8101
python searchengines/pubmed_search_server.py &     # Port 8103
python searchengines/openalex_search_server.py &   # Port 8105
```

### 2. Start Unified Search Server

```bash
python unified_search_server.py
```

The server will start on `http://localhost:8090`.

### 3. Verify Installation

```bash
# Health check
curl http://localhost:8090/health

# Test search
curl "http://localhost:8090/search?q=transformer&engine=arxiv&limit=5"
```

## Production Deployment

### Option 1: Systemd Service

Create a systemd service file:

```ini
# /etc/systemd/system/scholarclaw.service
[Unit]
Description=ScholarClaw Unified Server
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/ssd8/exec/mengfanchen01/projects/scholarclaw/code/search_servers
ExecStart=/usr/bin/python3 unified_search_server.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable scholarclaw
sudo systemctl start scholarclaw
```

### Option 2: Docker

Create a Dockerfile:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

EXPOSE 8090

CMD ["python", "unified_search_server.py"]
```

Build and run:

```bash
docker build -t scholarclaw .
docker run -d -p 8090:8090 --name scholarclaw scholarclaw
```

### Option 3: Kubernetes

Example deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scholarclaw
spec:
  replicas: 2
  selector:
    matchLabels:
      app: scholarclaw
  template:
    metadata:
      labels:
        app: scholarclaw
    spec:
      containers:
      - name: scholarclaw
        image: scholarclaw:latest
        ports:
        - containerPort: 8090
        livenessProbe:
          httpGet:
            path: /health
            port: 8090
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8090
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: scholarclaw
spec:
  selector:
    app: scholarclaw
  ports:
  - port: 8090
    targetPort: 8090
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SCHOLARCLAW_SERVER_URL` | Server URL for clients | `https://scholarclaw.youdao.com` |
| `SCHOLARCLAW_DEBUG` | Enable debug logging | `false` |

### Server Configuration

Edit `srcs/config.py` to configure backend services:

```python
SERVICES = {
    "arxiv": {"url": "http://localhost:8101"},
    "pubmed": {"url": "http://localhost:8103"},
    "openalex": {"url": "http://localhost:8105"},
    # ...
}
```

## Scaling

### Horizontal Scaling

1. Deploy multiple instances behind a load balancer
2. Use Redis for shared caching (if applicable)
3. Ensure sticky sessions for WebSocket connections (if using streaming)

### Vertical Scaling

1. Increase worker processes: `uvicorn app:app --workers 4`
2. Adjust timeout settings for long-running requests

## Monitoring

### Health Endpoints

- `GET /health` - Basic health check
- `GET /search/health` - Detailed backend service status

### Logging

Logs are written to stdout/stderr. Use a log aggregation service for production.

### Metrics

Consider adding Prometheus metrics:

```python
from prometheus_fastapi_instrumentator import Instrumentator

Instrumentator().instrument(app).expose(app)
```

## Troubleshooting

### Common Issues

1. **Connection refused**: Backend services not running
2. **Timeout errors**: Increase timeout in config or optimize queries
3. **Memory issues**: Reduce batch sizes or add pagination

### Debug Mode

Enable debug logging:

```bash
export SCHOLARCLAW_DEBUG=true
python unified_search_server.py
```
