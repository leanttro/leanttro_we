#!/bin/sh
set -e

echo "Building and starting estoque-wpp..."
docker compose build
docker compose up -d

echo ""
echo "Status:"
docker compose ps
