#!/usr/bin/env bash
# Package the chart from exercise 04 and push it to the local MicroK8s registry.
# Fill in the TODOs, make it executable (chmod +x), and run it from this exercise's folder.
set -euo pipefail

CHART_DIR="../04-helm-create-chart/mychart"
REGISTRY="nuc.tail66abd2.ts.net:32000"
REPO_PATH="helm-charts"

helm package "$CHART_DIR" -d .
CHART_PACKAGE=$(ls ./*.tgz | sort -V | tail -n1)
echo "Packaged: $CHART_PACKAGE"

helm push "$CHART_PACKAGE" "oci://${REGISTRY}/${REPO_PATH}" --plain-http
