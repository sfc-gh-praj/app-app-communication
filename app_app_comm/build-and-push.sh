#!/bin/bash
DB_NAME="app_app_comm_db"
SCHEMA_NAME="public"
IMAGE_REPO_NAME="docker_images"

# To push source_app image IMAGE_NAME should be fastapi-app and DIR_NAME="./source_app"
# To push destination_app image IMAGE_NAME should be ui and DIR_NAME="./destination_app"
IMAGE_NAME="fastapi-app"   
DIR_NAME="./source_app"

# make sure the target repository exists
echo "Creating DB and objects..."
snow sql -q "create database if not exists $DB_NAME"
snow sql -q "create schema if not exists $DB_NAME.$SCHEMA_NAME"
snow sql -q "create image repository if not exists $DB_NAME.$SCHEMA_NAME.$IMAGE_REPO_NAME"

IMAGE_REPO_URL=$(snow spcs image-repository url $IMAGE_REPO_NAME --database $DB_NAME --schema $SCHEMA_NAME)
IMAGE_FQN="$IMAGE_REPO_URL/$IMAGE_NAME"

# build and push the image (uses :latest implicitly)
echo "Building Docker image..."
docker buildx build --platform=linux/amd64 -t $IMAGE_FQN $DIR_NAME

echo "Logging into Snowflake registry..."
snow spcs image-registry login

echo "Pushing image to Snowflake registry..."
docker image push $IMAGE_FQN
echo "Build and push completed successfully!"
