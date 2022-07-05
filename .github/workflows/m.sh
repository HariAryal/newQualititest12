#!/bin/bash

  set -ex

  API_KEY='1df2d88975bc9d4d'
  INTEGRATIONS_API_URL='https://3000-qualitiai-qualitiapi-51d2c33ux5c.ws-us51.gitpod.io'
  PROJECT_ID='3'
  CLIENT_ID='536b5c096d90ee084c3adaeab9f86cf6'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://api.qualiti-dev.com/public/api'
  INTEGRATION_JWT_TOKEN='afb94de1f425ec64539e51e5ba583808a041fd99166690699079a8adc929c0c4d4bd192869bbe2e29f7fbecd6375290a7522ad555b97281bc8e0a52ae85b6c9e9be733d0b14802fadb57dc42616a9cb2f16baa9287cd64ac029d87fc43e3ddd7609c92aece6756bd142241da0802b4b9fe743a9ba7a939e65a60639678646f32a11a42269a426e8fdc9e753a59113cf5c27f699b2d13ed2b1174f6f0a737b98cb677d744b3940ee5d4abb5f4e19052be4ef084925fa068074f89295c50906abd505ae39b44293edb3fb3d018141734d5ae398934934c98ec9cba591b34ddafe4449d45fa3ab3aec3f55eddd7b11795d556a52aac0ddfab8d297dd384f3772544c7b2eb7d8fd2e403e0ef1bbccd89b589|2ac582cda0fa3a4dbe5ebd7e347c878d|bacf0f85ca157ee19be0aaba8b0859d2'

  sudo apt-get update -y
  sudo apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
