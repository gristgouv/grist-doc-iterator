#!/usr/bin/env bash

if [ -z "$USER_API_KEY" ]; then
  echo -n "Api key: "
  read -r -s USER_API_KEY
  export USER_API_KEY
  echo ""
fi

if [ -z "$GRIST_DOMAIN" ]; then
  echo -n "Domain: "
  read -r GRIST_DOMAIN
  export GRIST_DOMAIN
  echo ""
fi

npm run test:api
npm run test:e2e
