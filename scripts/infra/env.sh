#!/usr/bin/env bash
##############################################################################
# Usage: source env.sh
# Set all environment variables needed for the project.
##############################################################################
# Dependencies: Azure CLI
##############################################################################

echo "Exporting environment variables..." 

export PROJECT="java-runtimes-aca-jan-2026"
export RESOURCE_GROUP="rg-$PROJECT"
export LOCATION="eastus2"
export LOCATION_POSTGRE="westus3"
export TAG="$PROJECT"

export LOG_ANALYTICS_WORKSPACE="log-$PROJECT"
export CONTAINERAPPS_ENVIRONMENT="cae-$PROJECT"

#export UNIQUE_IDENTIFIER=${UNIQUE_IDENTIFIER:-${GITHUB_USER:-$(whoami)}}
export UNIQUE_IDENTIFIER="sharprav-java-aca"
export UNIQUE_IDENTIFIER_REGISTRY="sharpravjavaaca"
export UNIQUE_IDENTIFIER_DB="java-aca"

echo "Using unique identifier is: $UNIQUE_IDENTIFIER"
echo "  You can override it by setting it manually before running this script:"
echo "  export UNIQUE_IDENTIFIER=<your-unique-identifier>"

export REGISTRY="crjavaruntimes${UNIQUE_IDENTIFIER_REGISTRY}"
export IMAGES_TAG="1.0"

echo "Registry name is: $REGISTRY"

export POSTGRES_DB_ADMIN="javaruntimesadmin"
export POSTGRES_DB_PWD="java-runtimes-p#ssw0rd-12046"
export POSTGRES_DB_VERSION="14"
export POSTGRES_SKU="Standard_B1ms"
export POSTGRES_TIER="Burstable"
export POSTGRES_DB="psql-stats-$UNIQUE_IDENTIFIER_DB"
export POSTGRES_DB_SCHEMA="stats"
export POSTGRES_DB_CONNECT_STRING="jdbc:postgresql://${POSTGRES_DB}.postgres.database.azure.com:5432/${POSTGRES_DB_SCHEMA}?ssl=true&sslmode=require"

export QUARKUS_APP="quarkus-app"
export MICRONAUT_APP="micronaut-app"
export SPRING_APP="springboot-app"

echo "Account List:"
echo ""
az account show

echo
echo "SubScription and Resource Group: $RESOURCE_GROUP in $LOCATION"
echo ""
az account list --output table

az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags system="$TAG"
echo
echo
echo "Resource Group : $RESOURCE_GROUP"


echo "LOG_ANALYTICS_WORKSPACE:$LOG_ANALYTICS_WORKSPACE"
echo

az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags system="$TAG" \
  --workspace-name "$LOG_ANALYTICS_WORKSPACE"

export LOG_ANALYTICS_WORKSPACE_CLIENT_ID=$(az monitor log-analytics workspace show  \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_ANALYTICS_WORKSPACE" \
  --query customerId  \
  --output tsv \
  2>/dev/null | tr -d '[:space:]' \
)


echo "LOG_ANALYTICS_WORKSPACE_CLIENT_ID=$LOG_ANALYTICS_WORKSPACE_CLIENT_ID"

export LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_ANALYTICS_WORKSPACE" \
  --query primarySharedKey \
  --output tsv \
  2>/dev/null | tr -d '[:space:]' \
)

echo "LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=$LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET"
echo


az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags system="$TAG" \
  --name "$REGISTRY" \
  --workspace "$LOG_ANALYTICS_WORKSPACE" \
  --sku Standard \
  --admin-enabled true

  az acr update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REGISTRY" \
  --anonymous-pull-enabled true

export REGISTRY_URL=$(az acr show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$REGISTRY" \
  --query "loginServer" \
  --output tsv \
  2>/dev/null \
)

echo "Azure Container Registry:"
echo
echo "REGISTRY_URL=$REGISTRY_URL"




az containerapp env create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags system="$TAG" \
    --name "$CONTAINERAPPS_ENVIRONMENT" \
    --logs-workspace-id "$LOG_ANALYTICS_WORKSPACE_CLIENT_ID" \
    --logs-workspace-key "$LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET"

echo
echo "Container Apps Environment Created: $CONTAINERAPPS_ENVIRONMENT"
echo
az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$QUARKUS_APP" \
  --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --name "$QUARKUS_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 80 \
  --min-replicas 0 \
  --env-vars QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=validate \
             QUARKUS_HIBERNATE_ORM_SQL_LOAD_SCRIPT=no-file \
             QUARKUS_DATASOURCE_USERNAME="$POSTGRES_DB_ADMIN" \
             QUARKUS_DATASOURCE_PASSWORD="$POSTGRES_DB_PWD" \
             QUARKUS_DATASOURCE_JDBC_URL="$POSTGRES_DB_CONNECT_STRING"

az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$MICRONAUT_APP" \
  --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --name "$MICRONAUT_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 80 \
  --min-replicas 0 \
  --env-vars DATASOURCES_DEFAULT_USERNAME="$POSTGRES_DB_ADMIN" \
             DATASOURCES_DEFAULT_PASSWORD="$POSTGRES_DB_PWD" \
             DATASOURCES_DEFAULT_URL="$POSTGRES_DB_CONNECT_STRING"

az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$SPRING_APP" \
  --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --name "$SPRING_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 80 \
  --min-replicas 0 \
  --env-vars SPRING_DATASOURCE_USERNAME="$POSTGRES_DB_ADMIN" \
             SPRING_DATASOURCE_PASSWORD="$POSTGRES_DB_PWD" \
             SPRING_DATASOURCE_URL="$POSTGRES_DB_CONNECT_STRING"


echo
echo "Container Apps List"

export QUARKUS_HOST=$(
  az containerapp show \
    --name "$QUARKUS_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv \
    2>/dev/null \
)

echo "QUARKUS_HOST=$QUARKUS_HOST"
export MICRONAUT_HOST=$(
  az containerapp show \
    --name "$MICRONAUT_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv \
    2>/dev/null \
)

echo "MICRONAUT_HOST=$MICRONAUT_HOST"
export SPRING_HOST=$(
  az containerapp show \
    --name "$SPRING_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv \
    2>/dev/null \
)

echo "SPRING_HOST=$SPRING_HOST"
echo "Container Apps List Completed."



az postgres flexible-server create \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION_POSTGRE" \
  --tags system="$TAG" \
  --name "$POSTGRES_DB" \
  --database-name "$POSTGRES_DB_SCHEMA" \
  --admin-user "$POSTGRES_DB_ADMIN" \
  --admin-password "$POSTGRES_DB_PWD" \
  --public all \
  --cluster-option ElasticCluster \
  --version 17 \
  --tier "$POSTGRES_TIER" \
  --sku-name "$POSTGRES_SKU" \
  --storage-size 256 \
  --version "$POSTGRES_DB_VERSION"


  az postgres flexible-server execute \
  --name "$POSTGRES_DB" \
  --admin-user "$POSTGRES_DB_ADMIN" \
  --admin-password "$POSTGRES_DB_PWD" \
  --database-name "$POSTGRES_DB_SCHEMA" \
  --file-path "infrastructure/db-init/initialize-databases.sql"

echo "setup postgre Tables completed."
echo  
POSTGRES_CONNECTION_STRING=$(
  az postgres flexible-server show-connection-string \
    --server-name "$POSTGRES_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$POSTGRES_DB_SCHEMA" \
    --query "connectionStrings.jdbc" \
    --output tsv
)
echo "POSTGRES_CONNECTION_STRING=$POSTGRES_CONNECTION_STRING."
echo "Exported environment variables for project '${PROJECT}'."
