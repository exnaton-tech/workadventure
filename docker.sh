#!/bin/sh

if [ -z $1 ]; then 
  echo "Operation is unset. Please use script like this:";
  echo "./docker.sh build or ./docker.sh push\n"
  exit 1;
fi

if [ -z $2 ]; then 
  echo "Module is unset. Please use script like this:";
  echo "./docker.sh build front or ./docker.sh push front\n"
  exit 1;
fi

CPU_ARCH=$(uname -m)
MODULE_NAME=$2
USERNAME=exnaton
REPO_NAME=workadventure
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
IMAGE_NAME=$USERNAME/$REPO_NAME:$MODULE_NAME
#-${BRANCH_NAME}

if [ "$1" = "build" ]; then 
  echo Building image $IMAGE_NAME on $CPU_ARCH
  if [ $CPU_ARCH = x86_64 ]; then
    docker build --no-cache \
      -t $IMAGE_NAME \
      -f $MODULE_NAME/Dockerfile .
  else
    echo "Building for x86_64"
    docker buildx build --no-cache --platform linux/amd64 \
      -t $IMAGE_NAME \
      -f $MODULE_NAME/Dockerfile .

  fi
else
  if [ "$1" = "push" ]; then 
    echo Pushing image $IMAGE_NAME
    docker push $IMAGE_NAME
  else
    echo "$1 is not a valid option. Please use script like this:";
    echo "./docker.sh build or ./docker.sh push\n"
    exit 1;
  fi
fi




