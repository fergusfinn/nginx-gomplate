#!/bin/bash
set -e

echo "Processing gomplate templates..."

# Debug logging controlled by DEBUG env var
if [ "${DEBUG:-false}" = "true" ]; then
  echo "DEBUG: Environment variables:"
  printenv | sort
  echo "DEBUG: Files in /etc/nginx:"
  ls -la /etc/nginx/
fi

# Track if we found any templates
template_count=0

# Find all .gotmpl files in /etc/nginx and template them
# Use process substitution instead of pipe to avoid subshell issues
while IFS= read -r template; do
  output="${template%.gotmpl}"
  echo "Templating: $template -> $output"

  if ! gomplate -f "$template" -o "$output"; then
    echo "ERROR: Failed to template $template"
    exit 1
  fi

  if [ "${DEBUG:-false}" = "true" ]; then
    echo "DEBUG: Generated $output:"
    cat "$output"
    echo "DEBUG: End of $output"
  fi

  template_count=$((template_count + 1))
done < <(find /etc/nginx -type f -name "*.gotmpl")

if [ $template_count -eq 0 ]; then
  echo "No .gotmpl files found in /etc/nginx - skipping templating"
else
  echo "Successfully templated $template_count file(s)"
fi

echo "Validating nginx configuration..."
if ! nginx -t; then
  echo "ERROR: nginx configuration validation failed"
  exit 1
fi

echo "Starting nginx..."
exec nginx -g 'daemon off;'
