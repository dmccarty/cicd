#!/usr/bin/env sh 

echo "DEBUG INFO: "
echo "GCP_PROJECT=${GCP_PROJECT}"
echo "API_SUBDOMAIN=${API_SUBDOMAIN}"
echo "DEFAULT_GCP_SERVICE_ACCOUNT=${DEFAULT_GCP_SERVICE_ACCOUNT}"
echo "OPENAPI_YAML=${OPENAPI_YAML}"


# TODO: Allow action user to pass additional options to this script (Needed?)
touch deployment_info.txt
gcloud endpoints services deploy ./"$OPENAPI_YAML" --project "$GCP_PROJECT" > deployment_info.txt 2>&1
CONFIG_ID=$(awk -F'[][]' '{print $2}' deployment_info.txt | tr -d '[:space:]')

echo "CONFIG_ID=$CONFIG_ID"

# TODO: Allow action user to pass additional options to this script (Needed?)
/tmp/gcp_build_image.sh -s "$API_SUBDOMAIN" -c "$CONFIG_ID" -p "$GCP_PROJECT"

# TODO: Allow action user to pass additional options to this script (Needed?)
gcloud beta run deploy discovery-endpoints-cloudrun-service \
  --image="gcr.io/$GCP_PROJECT/endpoints-runtime-serverless:$API_SUBDOMAIN-$CONFIG_ID" \
  --allow-unauthenticated \
  --platform managed \
  --project "$GCP_PROJECT" \
  --region us-central1 \
  --min-instances 2

gcloud run services add-iam-policy-binding discovery-api \
  --member "serviceAccount:$DEFAULT_GCP_SERVICE_ACCOUNT" \
  --role "roles/run.invoker" \
  --platform managed \
  --project "$GCP_PROJECT" \
  --region us-central1
