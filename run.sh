#!/bin/bash
set +e

type_exists() {
  if [ $(type -P $1) ]; then
    return 0
  fi
  return 1
}

# Check AWS is installed
if ! type_exists 'aws'; then
  error 'AWS Cli is not installed on this box.'
  info 'Please install AWS Cli : https://github.com/EdgecaseInc/wercker-step-install-aws-cli'
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

if [ -z "$WERCKER_AWS_CODE_DEPLOY_S3_REGION" ]; then
  error "Please set the 's3-region' variable"
  exit 1
fi

if [ -z "$WERCKER_AWS_CODE_DEPLOY_S3_BUCKET" ]; then
  error "Please set the 's3-bucket' variable"
  exit 1
fi

if [ -z "$WERCKER_AWS_CODE_DEPLOY_SERVICE_ROLE_ARN" ]; then
  error "Please set the 'service-role-arn' variable"
  exit 1
fi

# ----- Application -----
# see documentation :
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/get-application.html
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html
# ----------------------
# Application variables
APPLICATION_NAME="$WERCKER_AWS_CODE_DEPLOY_APPLICATION_NAME"
# Check application exists
info "=== Checking application '$APPLICATION_NAME' exists ==="

APPLICATION_EXISTS="aws deploy get-application --application-name $APPLICATION_NAME"
info "$APPLICATION_EXISTS"
APPLICATION_EXISTS_OUTPUT=$($APPLICATION_EXISTS 2>&1)

if [[ $? -ne 0 ]];then
  warn "$APPLICATION_EXISTS_OUTPUT"
  info "=== Creating application '$APPLICATION_NAME' ==="

  # Create application
  APPLICATION_CREATE="aws deploy create-application --application-name $APPLICATION_NAME"
  info "$APPLICATION_CREATE"
  APPLICATION_CREATE_OUTPUT=$($APPLICATION_CREATE 2>&1)

  if [[ $? -ne 0 ]];then
    warn "$APPLICATION_CREATE_OUTPUT"
    error "Creating application '$APPLICATION_NAME' failed"
    exit 1
  fi
  success "Creating application '$APPLICATION_NAME' succeed"
else
  success "Application '$APPLICATION_NAME' already exists"
fi
# ----- Deployment group -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# ----------------------
# Deployment group variables
DEPLOYMENT_GROUP="$WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_GROUP_NAME"
DEPLOYMENT_CONFIG_NAME=${WERCKER_AWS_CODE_DEPLOY_DEPLOYMENT_CONFIG_NAME:-CodeDeployDefault.OneAtATime}
AUTO_SCALING_GROUPS="$WERCKER_AWS_CODE_DEPLOY_AUTO_SCALING_GROUPS"
EC2_TAGS_FILTERS="$WERCKER_AWS_CODE_DEPLOY_EC2_TAGS_FILTERS"
SERVICE_ROLE_ARN="$WERCKER_AWS_CODE_DEPLOY_SERVICE_ROLE_ARN"

# Ckeck deployment group exists
info "=== Checking deployment group '$DEPLOYMENT_GROUP' exists for application '$APPLICATION_NAME' ==="

DEPLOYMENT_GROUP_EXISTS="aws deploy get-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP"
info "$DEPLOYMENT_GROUP_EXISTS"
DEPLOYMENT_GROUP_EXISTS_OUTPUT=$($DEPLOYMENT_GROUP_EXISTS 2>&1)

if [[ $? -ne 0 ]];then
  warn "$DEPLOYMENT_GROUP_EXISTS_OUTPUT"
  info "=== Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME' ==="

  # Create deployment group
  DEPLOYMENT_GROUP_CREATE="aws deploy create-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP --deployment-config-name $DEPLOYMENT_CONFIG_NAME"

  if [ -n "$SERVICE_ROLE_ARN" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --service-role-arn $SERVICE_ROLE_ARN"
  fi
  if [ -n "$AUTO_SCALING_GROUPS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --auto-scaling-groups $AUTO_SCALING_GROUPS"
  fi
  if [ -n "$EC2_TAGS_FILTERS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --ec2-tag-filters $EC2_TAGS_FILTERS"
  fi
  info "$DEPLOYMENT_GROUP_CREATE"
  DEPLOYMENT_GROUP_CREATE_OUTPUT=$($DEPLOYMENT_GROUP_CREATE 2>&1)

  if [[ $? -ne 0 ]];then
    warn "$DEPLOYMENT_GROUP_CREATE_OUTPUT"
    error "Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME' failed"
    exit 1
  fi
  success "Creating deployment group '$DEPLOYMENT_GROUP' for application '$APPLICATION_NAME' succeed"
else
  success "Deployment group '$DEPLOYMENT_GROUP' already exists for application '$APPLICATION_NAME'"
fi

# ----- Deployment config (optional) -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# ----------------------

# ----- Push a revision to S3 -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html
# ----------------------
S3_REGION="$WERCKER_AWS_CODE_DEPLOY_S3_REGION"
S3_BUCKET="$WERCKER_AWS_CODE_DEPLOY_S3_BUCKET"
APPLICATION_REVISION="$WERCKER_AWS_CODE_DEPLOY_APPLICATION_REVISION"

info "=== Pushing revision '$APPLICATION_REVISION' to S3 ==="
PUSH_S3="aws deploy push --application-name $APPLICATION_NAME --region $S3_REGION --s3-location s3://$S3_BUCKET/$APPLICATION_NAME-$APPLICATION_REVISION.zip --source ."

info "$PUSH_S3"
PUSH_S3_OUTPUT=$($PUSH_S3 2>&1)

if [[ $? -ne 0 ]];then
  warn "$PUSH_S3_OUTPUT"
  error "Pushing revision '$APPLICATION_REVISION' to S3 failed"
  exit 1
fi
success "Pushing revision '$APPLICATION_REVISION' to S3 succeed"

# ----- Register revision -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html
# ----------------------
info "=== Registering revision '$APPLICATION_REVISION' ==="
S3_LOCATION="--s3-location bucket=$S3_BUCKET,key=$APPLICATION_NAME-$APPLICATION_REVISION.zip,bundleType=zip"
REGISTER_REVISION="aws deploy register-application-revision --application-name $APPLICATION_NAME $S3_LOCATION"

info "$REGISTER_REVISION"
REGISTER_REVISION_OUTPUT=$($REGISTER_REVISION 2>&1)

if [[ $? -ne 0 ]];then
  warn "$REGISTER_REVISION_OUTPUT"
  error "Registering revision '$APPLICATION_REVISION' failed"
  exit 1
fi
success "Registering revision '$APPLICATION_REVISION' succeed"

# ----- Deployment -----
# see documentation : http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html
# ----------------------
info  "=== Creating deployment for application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' ==="
DEPLOYMENT="aws deploy create-deployment --application-name $APPLICATION_NAME --deployment-config-name $DEPLOYMENT_CONFIG_NAME --deployment-group-name $DEPLOYMENT_GROUP $S3_LOCATION"

info "$DEPLOYMENT"
DEPLOYMENT_OUTPUT=$($DEPLOYMENT 2>&1)

if [[ $? -ne 0 ]];then
  warn "$DEPLOYMENT_OUTPUT"
  error "Deployment for application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' failed"
  exit 1
fi

DEPLOYMENT_ID=$(echo $DEPLOYMENT_OUTPUT | sed -n 's/.*"deploymentId": "\(.*\)".*/\1/p')
success "Deployment for application '$APPLICATION_NAME' on deployment group '$DEPLOYMENT_GROUP' succeed"
echo "You can see your deployment at : https://console.aws.amazon.com/codedeploy/home#/deployments/$DEPLOYMENT_ID"

set -e