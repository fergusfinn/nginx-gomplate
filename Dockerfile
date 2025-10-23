FROM nginx:1.29.1-bookworm

# Update packages to fix security vulnerabilities
# Note: CVE-2023-45853 in zlib1g is a false positive - see https://github.com/madler/zlib/issues/868
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Install gomplate
COPY --from=hairyhenderson/gomplate:stable /gomplate /bin/gomplate

# Prepare directories for non-root nginx user (using existing nginx user from base image)
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run \
  && chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run /etc/nginx

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

# Switch to non-root user
USER nginx

ENTRYPOINT ["/entrypoint.sh"]
