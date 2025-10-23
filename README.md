# nginx-gomplate

A Docker image combining nginx with [gomplate](https://github.com/hairyhenderson/gomplate) for dynamic nginx configuration templating.

## Overview

This image extends the official nginx image with gomplate templating
capabilities, allowing you to generate nginx configuration files dynamically
from environment variables, data sources, and templates at container startup.

## Quick Start

### Basic Usage

1. Create a gomplate template file (e.g., `default.conf.gotmpl`):

```nginx
server {
    listen 80;
    server_name {{ getenv "SERVER_NAME" "localhost" }};

    location / {
        proxy_pass {{ getenv "BACKEND_URL" "http://backend:8080" }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

2. Run the container:

```bash
docker run -d \
  -p 80:80 \
  -e SERVER_NAME=example.com \
  -e BACKEND_URL=http://api:3000 \
  -v $(pwd)/default.conf.gotmpl:/etc/nginx/conf.d/default.conf.gotmpl:ro \
  ghcr.io/fergusfinn/nginx-gomplate
```

The container will:

- Process all `.gotmpl` files, replacing environment variables
- Generate `default.conf` from `default.conf.gotmpl`
- Validate the nginx configuration
- Start nginx

### Docker Compose Example

```yaml
version: '3.8'

services:
  nginx:
    image: your-image-name
    ports:
      - "80:80"
      - "443:443"
    environment:
      - SERVER_NAME=example.com
      - BACKEND_URL=http://backend:8080
      - MAX_BODY_SIZE=10m
    volumes:
      - ./nginx-templates:/etc/nginx/conf.d:ro
      - ./ssl:/etc/nginx/ssl:ro
```

## Gomplate Template Examples

### Environment Variables with Defaults

```nginx
client_max_body_size {{ getenv "MAX_BODY_SIZE" "1m" }};
```

Note: you can do this in envsubst using the base nginx image.

### Conditional Configuration

```nginx
{{ if getenv "ENABLE_SSL" }}
server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    # ...
}
{{ end }}
```

### Multiple Backends from JSON

Given environment variable `BACKENDS='[{"name":"api","port":3000},{"name":"web","port":8080}]'`:

```nginx
{{ range (getenv "BACKENDS" | jsonArray) -}}
upstream {{ .name }} {
    server backend:{{ .port }};
}
{{ end }}
```

### Using Data Sources

You can also use external data sources like files, HTTP endpoints, or vault:

```nginx
{{ $config := datasource "config" -}}
server_name {{ $config.domain }};
```

## Template File Naming

All files ending in `.gotmpl` in `/etc/nginx` will be processed. The output file will have the `.gotmpl` extension removed:

- `default.conf.gotmpl` → `default.conf`
- `nginx.conf.gotmpl` → `nginx.conf`
- `upstreams.conf.gotmpl` → `upstreams.conf`

## Debugging

To see the templating output, check container logs:

```bash
docker logs your-container-name
```

You'll see:

```
Processing gomplate templates...
Templating: /etc/nginx/conf.d/default.conf.gotmpl -> /etc/nginx/conf.d/default.conf
Successfully templated 1 file(s)
Validating nginx configuration...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Starting nginx...
```

## Gomplate Documentation

For more gomplate functions and features, see:

- [Gomplate Documentation](https://docs.gomplate.ca/)
- [Function Reference](https://docs.gomplate.ca/functions/)
- [Data Sources](https://docs.gomplate.ca/datasources/)

## License

This image combines:

- nginx - [2-clause BSD license](http://nginx.org/LICENSE)
- gomplate - [MIT license](https://github.com/hairyhenderson/gomplate/blob/main/LICENSE)
