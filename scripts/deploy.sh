#!/usr/bin/env bash
# Deploys one image to one server through SSM Run Command.
# Inputs: AWS_REGION, REGISTRY, IMAGE_REF, VERSION, INSTANCE_ID
set -euo pipefail

cat > params.json <<EOF
{
  "commands": [
    "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}",
    "docker pull ${IMAGE_REF}",
    "docker rm -f app || true",
    "docker run -d --name app --restart unless-stopped -p 80:8080 -e APP_VERSION=${VERSION} ${IMAGE_REF}",
    "sleep 5",
    "curl --fail --silent http://localhost/health"
  ]
}
EOF

CMD_ID=$(aws ssm send-command \
  --document-name AWS-RunShellScript \
  --instance-ids "$INSTANCE_ID" \
  --comment "deploy ${VERSION}" \
  --parameters file://params.json \
  --query Command.CommandId --output text)
echo "SSM command id: $CMD_ID"

sleep 3
aws ssm wait command-executed --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" || true

aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --query '{Status:Status,Output:StandardOutputContent,Errors:StandardErrorContent}'

STATUS=$(aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --query Status --output text)
echo "Deploy status: $STATUS"
[ "$STATUS" = "Success" ]