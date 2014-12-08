#!/bin/bash
set +e
set -o noglob


#
# Set Colors
#

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#
# Headers and Logging
#

underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
success() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}


type_exists() {
  if [ $(type -P $1) ]; then
    return 0
  fi
  return 1
}

jsonValue() {
  key=$1
  num=$2
  awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$key'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

# Check AWS is installed
if ! type_exists 'aws'; then
  error 'AWS Cli is not installed on this box.'
  note 'Please install AWS Cli : https://github.com/EdgecaseInc/wercker-step-install-aws-cli'
  exit 1
fi


# Check variables
if [ -z "$WERCKER_AWS_CODE_DEPLOY_APPLICATION_NAME" ]; then
  error "Please set the 'application-name' variable"
  exit 1
fi

if [ -z "$WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME" ]; then
  error "Please set the 'deployment-group' variable"
  exit 1
fi

if [ -z "$WERCKER_AWS_CODE_DEPLOY_S3_BUCKET" ]; then
  error "Please set the 's3-bucket' variable"
  exit 1
fi


# ----- Application -----
# see documentation :
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/get-application.html
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html
# ----------------------
# Application variables
APPLICATION_NAME="$WERCKER_AWS_CODE_DEPLOY_APPLICATION_NAME"
APPLICATION_VERSION=${WERCKER_AWS_CODE_DEPLOY_APPLICATION_VERSION:-${WERCKER_GIT_COMMIT:0:7}}

# Check application exists
h1 "Step 1: Defining application"
h2 "Checking application '$APPLICATION_NAME' exists"

APPLICATION_EXISTS="aws deploy get-application --application-name $APPLICATION_NAME"
info "$APPLICATION_EXISTS"
APPLICATION_EXISTS_OUTPUT=$($APPLICATION_EXISTS 2>&1)

if [[ $? -ne 0 ]];then
  warn "$APPLICATION_EXISTS_OUTPUT"
  h2 "Creating application '$APPLICATION_NAME' :"


  # Create application
  APPLICATION_CREATE="aws deploy create-application --application-name $APPLICATION_NAME"
  info "$APPLICATION_CREATE"
  APPLICATION_CREATE_OUTPUT=$($APPLICATION_CREATE 2>&1)

  if [[ $? -ne 0 ]];then
    warn "$APPLICATION_CREATE_OUTPUT"
    error "Creating application '$APPLICATION_NAME' failed"
    exit 1
  fi
  success "Creating application '$APPLICATION_NAME' succeeded"
else
  success "Application '$APPLICATION_NAME' already exists"
fi


# ----- Deployment config (optional) -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# ----------------------
DEPLOYMENT_CONFIG_NAME=${WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_CONFIG_NAME:-CodeDeployDefault.OneAtATime}
MINIMUM_HEALTHY_HOSTS=${WERCKER_AWS_CODE_DEPLOY_MINIMUM_HEALTHY_HOSTS:-type=FLEET_PERCENT,value=75}

# Ckeck deployment config exists
h1 "Step 2: Defining deployment config"
h2 "Checking deployment config '$DEPLOYMENT_CONFIG_NAME' exists"

DEPLOYMENT_CONFIG_EXISTS="aws deploy get-deployment-config --deployment-config-name $DEPLOYMENT_CONFIG_NAME"
info "$DEPLOYMENT_CONFIG_EXISTS"
DEPLOYMENT_CONFIG_EXISTS_OUTPUT=$($DEPLOYMENT_CONFIG_EXISTS 2>&1)

if [[ $? -ne 0 ]];then
  warn "$DEPLOYMENT_CONFIG_EXISTS_OUTPUT"
  h2 "Creating deployment config '$DEPLOYMENT_CONFIG_NAME'"

 # Create deployment config
  DEPLOYMENT_CONFIG_CREATE="aws deploy create-deployment-config --deployment-config-name $DEPLOYMENT_CONFIG_NAME --minimum-healthy-hosts $MINIMUM_HEALTHY_HOSTS"
  info "$DEPLOYMENT_CONFIG_CREATE"
  DEPLOYMENT_CONFIG_CREATE_OUTPUT=$($DEPLOYMENT_CONFIG_CREATE 2>&1)

  if [[ $? -ne 0 ]];then
    warn "$DEPLOYMENT_CONFIG_CREATE_OUTPUT"
    error "Creating deployment config '$DEPLOYMENT_CONFIG_NAME' failed"
    exit 1
  fi
  success "Creating deployment config '$DEPLOYMENT_CONFIG_NAME' succeeded"
else
  success "Deployment config '$DEPLOYMENT_CONFIG_NAME' already exists"
fi


# ----- Deployment group -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# ----------------------
# Deployment group variables
DEPLOYMENT_GROUP=${WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME:-$WERCKER_DEPLOYTARGET_NAME}
AUTO_SCALING_GROUPS="$WERCKER_AWS_CODE_DEPLOY_AUTO_SCALING_GROUPS"
EC2_TAG_FILTERS="$WERCKER_AWS_CODE_DEPLOY_EC2_TAG_FILTERS"
SERVICE_ROLE_ARN="$WERCKER_AWS_CODE_DEPLOY_SERVICE_ROLE_ARN"

# Ckeck deployment group exists
h1 "Step 3: Defining deployment group"
h2 "Checking deployment group '$DEPLOYMENT_GROUP' exists for application '$APPLICATION_NAME'"

DEPLOYMENT_GROUP_EXISTS="aws deploy get-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP"
info "$DEPLOYMENT_GROUP_EXISTS"
DEPLOYMENT_GROUP_EXISTS_OUTPUT=$($DEPLOYMENT_GROUP_EXISTS 2>&1)

if [[ $? -ne 0 ]];then
  warn "$DEPLOYMENT_GROUP_EXISTS_OUTPUT"
  h2 "Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME'"

  # Create deployment group
  DEPLOYMENT_GROUP_CREATE="aws deploy create-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP --deployment-config-name $DEPLOYMENT_CONFIG_NAME"

  if [ -n "$SERVICE_ROLE_ARN" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --service-role-arn $SERVICE_ROLE_ARN"
  fi
  if [ -n "$AUTO_SCALING_GROUPS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --auto-scaling-groups $AUTO_SCALING_GROUPS"
  fi
  if [ -n "$EC2_TAG_FILTERS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --ec2-tag-filters $EC2_TAG_FILTERS"
  fi
  info "$DEPLOYMENT_GROUP_CREATE"
  DEPLOYMENT_GROUP_CREATE_OUTPUT=$($DEPLOYMENT_GROUP_CREATE 2>&1)

  if [[ $? -ne 0 ]];then
    warn "$DEPLOYMENT_GROUP_CREATE_OUTPUT"
    error "Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME' failed"
    exit 1
  fi
  success "Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME' succeeded"
else
  success "Deployment group '$DEPLOYMENT_GROUP' already exists for application '$APPLICATION_NAME'"
fi


# ----- Push a revision to S3 -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html
# ----------------------
REVISION=${WERCKER_AWS_CODE_DEPLOY_REVISION:-$APPLICATION_NAME-$APPLICATION_VERSION.zip}
REVISION_DESCRIPTION="$WERCKER_AWS_CODE_DEPLOY_REVISION_DESCRIPTION"

S3_BUCKET="$WERCKER_AWS_CODE_DEPLOY_S3_BUCKET"
S3_SOURCE=${WERCKER_AWS_CODE_DEPLOY_S3_SOURCE:-.}
S3_KEY=${WERCKER_AWS_CODE_DEPLOY_S3_KEY:-$APPLICATION_NAME}

# Build S3 Location
S3_LOCATION="s3://$S3_BUCKET"
if [ -n "$S3_KEY" ]; then
  S3_LOCATION="$S3_LOCATION/$S3_KEY"
fi
S3_LOCATION="$S3_LOCATION/$REVISION"

h1 "Step 4: Pushing to S3"
PUSH_S3="aws deploy push --application-name $APPLICATION_NAME --s3-location $S3_LOCATION --source $S3_SOURCE"
if [ -n "$REVISION_DESCRIPTION" ]; then
  PUSH_S3="$PUSH_S3 --description '$REVISION_DESCRIPTION'"
fi

info "$PUSH_S3"
PUSH_S3_OUTPUT=$($PUSH_S3 2>&1)

if [[ $? -ne 0 ]];then
  warn "$PUSH_S3_OUTPUT"
  error "Pushing revision '$REVISION' to S3 failed"
  exit 1
fi
success "Pushing revision '$REVISION' to S3 succeeded"


# ----- Register revision -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html
# ----------------------
h1 "Step 5: Registering revision"

# Build S3 Location
BUNDLE_TYPE=${REVISION##*.}
S3_LOCATION="bucket=$S3_BUCKET,bundleType=$BUNDLE_TYPE"

if [ -n "$S3_KEY" ]; then
  S3_LOCATION="$S3_LOCATION,key=$S3_KEY/$REVISION"
else
  S3_LOCATION="$S3_LOCATION,key=$REVISION"
fi

# Define egister-application-revision command
REGISTER_REVISION="aws deploy register-application-revision --application-name $APPLICATION_NAME --s3-location $S3_LOCATION"
if [ -n "$REVISION_DESCRIPTION" ]; then
  REGISTER_REVISION="$REGISTER_REVISION --description '$REVISION_DESCRIPTION'"
fi

info "$REGISTER_REVISION"
REGISTER_REVISION_OUTPUT=$($REGISTER_REVISION 2>&1)

if [[ $? -ne 0 ]];then
  warn "$REGISTER_REVISION_OUTPUT"
  error "Registering revision '$REVISION' failed"
  exit 1
fi
success "Registering revision '$REVISION' succeeded"


# ----- Deployment -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html
# ----------------------
DEPLOYMENT_DESCRIPTION="$WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_DESCRIPTION"
DEPLOYMENT_OVERVIEW=${WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_OVERVIEW:-true}

h1 "Step 6: Creating deployment"
DEPLOYMENT="aws deploy create-deployment --application-name $APPLICATION_NAME --deployment-config-name $DEPLOYMENT_CONFIG_NAME --deployment-group-name $DEPLOYMENT_GROUP --s3-location $S3_LOCATION"

if [ -n "$DEPLOYMENT_DESCRIPTION" ]; then
  DEPLOYMENT="$DEPLOYMENT --description \"$DEPLOYMENT_DESCRIPTION\""
fi
info "$DEPLOYMENT"
DEPLOYMENT_OUTPUT=$($DEPLOYMENT 2>&1)

if [[ $? -ne 0 ]];then
  warn "$DEPLOYMENT_OUTPUT"
  error "Deployment of application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' failed"
  exit 1
fi

DEPLOYMENT_ID=$(echo $DEPLOYMENT_OUTPUT | jsonValue 'deploymentId' | tr -d ' ')
note "You can follow your deployment at : https://console.aws.amazon.com/codedeploy/home#/deployments/$DEPLOYMENT_ID"

if [ 'true' = "$DEPLOYMENT_OVERVIEW" ]; then
  h1  "Deploymnent Overview"
  DEPLOYMENT_GET="aws deploy get-deployment --deployment-id $DEPLOYMENT_ID"
  info "$DEPLOYMENT_GET"

  h2  "Deploying application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP'"

  while :
    do
      sleep 5
      DEPLOYMENT_GET_OUTPUT=$($DEPLOYMENT_GET 2>&1 > /tmp/$DEPLOYMENT_ID)
      if [[ $? -ne 0 ]];then
        warn "$DEPLOYMENT_OUTPUT"
        error "Deployment of application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' failed"
        exit 1
      fi

      # Deployment Status
      STATUS=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'status' | tr -d '\r\n' | tr -d ' ')
      ERROR_MESSAGE=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'message')

      # Deployment failed
      if [ "$STATUS" = 'Failed' ]; then
          error "Deployment of application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' failed: $ERROR_MESSAGE"
          exit 1
      fi

      # Deployment Overview
      IN_PROGRESS=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'InProgress' | tr -d '\r\n' | tr -d ' ')
      PENDING=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'Pending' | tr -d '\r\n' | tr -d ' ')
      SKIPPED=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'Skipped' | tr -d '\r\n' | tr -d ' ')
      SUCCEEDED=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'Succeeded' | tr -d '\r\n' | tr -d ' ')
      FAILED=$(cat /tmp/$DEPLOYMENT_ID | jsonValue 'Failed' | tr -d '\r\n' | tr -d ' ')
      echo  "| In Progress: $IN_PROGRESS | Pending : $PENDING | Skipped : $SKIPPED | Succeeded : $SUCCEEDED | Failed : $FAILED |"

      # Deployment succeeded
      if [ "$STATUS" = 'Succeeded' ]; then
         success "Deployment of application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' succeeded"
         break
      fi

    done
else
  info "Deployment of application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' in progress"
fi

set -e
