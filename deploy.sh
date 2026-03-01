#!/usr/bin/env bash
set -euo pipefail

PROJECT="zestliving-cfd1d"
SERVICE="tarksh-com"
REGION="us-central1"

echo "Deploying $SERVICE to Cloud Run ($REGION)..."

gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --memory 128Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 3 \
  --project "$PROJECT"

echo ""
echo "Deployed. URL:"
gcloud run services describe "$SERVICE" \
  --region "$REGION" \
  --project "$PROJECT" \
  --format "value(status.url)"

# Map custom domain (skips if already mapped)
DOMAIN="tarksh.com"
EXISTING=$(gcloud beta run domain-mappings list \
  --region "$REGION" \
  --project "$PROJECT" \
  --filter="metadata.name=$DOMAIN" \
  --format="value(metadata.name)" 2>/dev/null || true)

if [ -z "$EXISTING" ]; then
  echo ""
  echo "Mapping $DOMAIN to $SERVICE..."
  gcloud beta run domain-mappings create \
    --service "$SERVICE" \
    --domain "$DOMAIN" \
    --region "$REGION" \
    --project "$PROJECT"
  echo "Domain mapped. SSL certificate will provision once DNS propagates."
else
  echo ""
  echo "Domain $DOMAIN is already mapped."
fi
