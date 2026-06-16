#!/bin/bash
# Deploy a site to vaibhav-jain.com/<site>/
# Usage:  ./deploy.sh <site-name>
# Example: ./deploy.sh fifa
#          ./deploy.sh bali
#
# Expected local structure:
#   <site>/
#     index.html
#     assets/   (optional - any JS/CSS libs)

set -e

SITE=${1:-fifa}
PROFILE="vaibAdmin"
BUCKET="vaibhav-jain.com"
CF_ID="E2PFKGONNP4B3M"
SRC_DIR="./$SITE"

if [ ! -f "$SRC_DIR/index.html" ]; then
  echo "Error: $SRC_DIR/index.html not found"
  exit 1
fi

echo "=== Deploying '$SITE' to https://vaibhav-jain.com/$SITE ==="

# Upload assets folder if it exists
if [ -d "$SRC_DIR/assets" ]; then
  echo "Uploading assets..."
  aws --profile $PROFILE s3 sync "$SRC_DIR/assets/" "s3://$BUCKET/$SITE/assets/" \
    --content-type "application/javascript" --delete
fi

# Upload icons if they exist
if [ -d "$SRC_DIR/icons" ]; then
  echo "Uploading icons..."
  aws --profile $PROFILE s3 sync "$SRC_DIR/icons/" "s3://$BUCKET/$SITE/icons/" \
    --content-type "image/png" --delete
fi

# Upload manifest.json if it exists
if [ -f "$SRC_DIR/manifest.json" ]; then
  echo "Uploading manifest.json..."
  aws --profile $PROFILE s3 cp "$SRC_DIR/manifest.json" \
    "s3://$BUCKET/$SITE/manifest.json" --content-type "application/manifest+json"
fi

# Upload service worker if it exists
if [ -f "$SRC_DIR/sw.js" ]; then
  echo "Uploading service worker..."
  aws --profile $PROFILE s3 cp "$SRC_DIR/sw.js" \
    "s3://$BUCKET/$SITE/sw.js" --content-type "application/javascript"
fi

# Upload index.html
echo "Uploading index.html..."
aws --profile $PROFILE s3 cp "$SRC_DIR/index.html" \
  "s3://$BUCKET/$SITE/index.html" --content-type "text/html"

# Invalidate CloudFront
echo "Invalidating CloudFront cache..."
aws --profile $PROFILE cloudfront create-invalidation \
  --distribution-id $CF_ID \
  --paths "/$SITE/*" \
  --query 'Invalidation.{Id:Id,Status:Status}' --output table

echo ""
echo "Done! Live at: https://vaibhav-jain.com/$SITE"
