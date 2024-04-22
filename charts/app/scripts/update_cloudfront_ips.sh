set -eux -o pipefail

CLOUDFRONT_IPS=$(curl -s https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips | jq  'map(.[]) | sort' | yq .)

yq e -i ".global.ingress.allowFromCloudFrontCIDRs = $CLOUDFRONT_IPS" values.yaml