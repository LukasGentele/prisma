#!/bin/bash

set -e
export BUILDKITE_ARTIFACT_UPLOAD_DESTINATION="s3://$ARTIFACT_BUCKET/lambda/$BUILDKITE_JOB_ID"

# Use current dir as working dir base
cd "$(dirname "$0")"

SCRIPT_ROOT=$(dirname "$(pwd)")
BK_ROOT=$(dirname "$SCRIPT_ROOT")
SERVER_ROOT=$(dirname "$BK_ROOT")

echo "Current dir: $(pwd)"
echo "Script: $SCRIPT_ROOT"
echo "BK: $BK_ROOT"
echo "Server: $SERVER_ROOT"

docker run -e "BRANCH=$BUILDKITE_BRANCH" -e "COMMIT_SHA=$BUILDKITE_COMMIT" -e "CLUSTER_VERSION=$DOCKER_TAG" \
  -w /root/build \
  -v ${SERVER_ROOT}:/root/build \
  -v ~/.ivy2:/root/.ivy2 \
  -v ~/.coursier:/root/.coursier \
  -v /var/run/docker.sock:/var/run/docker.sock \
  prismagraphql/build-image:lambda sbt "project prisma-native" prisma-native-image:packageBin
#  -v /.cargo/:~/root/.cargo \

buildkite-agent artifact upload ${SERVER_ROOT}/images/prisma-native/target/prisma-native-image/prisma-native