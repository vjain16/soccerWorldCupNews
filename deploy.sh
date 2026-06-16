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
