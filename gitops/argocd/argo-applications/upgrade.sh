#!/bin/bash

# exit when any command fails
set -e

NEW_VERSION=$1
echo "new version: ${NEW_VERSION}"

docker tag nginx:1.23.3 "marcellmartini/nginx:${NEW_VERSION}"

docker push "marcellmartini/nginx:${NEW_VERSION}"

TMP_DIR="$(mktemp -d)"
echo "${TMP_DIR}"

git clone -b add-gitops git@github.com:marcellmartini/devops-tools.git "${TMP_DIR}"

sed -i "s#marcellmartini/nginx:.*#marcellmartini/nginx:${NEW_VERSION}#g" "${TMP_DIR}/gitops/argocd/apps/my-app/1-deployment.yaml"

cd "${TMP_DIR}"
git add .
git commit -m "Update image to ${NEW_VERSION}"
git push

rm -fr "${TMP_DIR}"
