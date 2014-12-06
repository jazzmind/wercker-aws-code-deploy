wercker-aws-code-deploy
=======================

This wercker step permits to deploy applications with [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html
) service.

Please read the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) documentation and [API](http://docs.aws.amazon.com/cli/latest/reference/deploy/index.html) before using this step.

Note: Before using this step you have to install [AWS Cli](https://github.com/EdgecaseInc/wercker-step-install-aws-cli).

## Versions

| Release date | Step version | 
| -------------| -------------| 
| 2014-12-04   | 0.0.8        | 


## Configuration

The following configuration is required to configure this step :

#### AWS Code Deploy - [Application](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html) 

* `application-name` (required) Name of the application to deploy
* `application-version` (required) Version of the application to deploy

#### AWS Code Deploy - [Deployment Config](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html)

* `deployment-config-name` (optional) Deployment config name. By default : _CodeDeployDefault.OneAtATime_
* `minimum-healthy-hosts` (optional) The minimum number of healthy instances during deployment. By default : _type=FLEET_PERCENT,value=75_

#### AWS Code Deploy - [Deployment Group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html)

* `deployment-group-name` (required) Deployment group name
* `service-role-arn` (optional) Service role arn giving permissions to use Code Deploy when creating a deployment group
* `ec2-tag-filters` (optional) EC2 tags to filter on when creating a deployment group
* `auto-scaling-groups` (optional) Auto Scaling groups when creating a deployment group 

#### AWS Code Deploy - [S3 Push](http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html)

* `s3-bucket` (required) S3 Bucket
* `s3-region` (required) S3 Bucket region
* `s3-source` (optional) S3 Source. By default : _._
* `s3-key` (optional) S3 Key

#### AWS Code Deploy - [Revision](http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html) 

* `revision` (optional) Revision of the application to deploy. By default: _{application-name}-{application-version}.zip_
* `revision-description` (optional) Description of the revision of the application to deploy. By default: _{application-name}-{application-version}.zip_

## Example

The following example deploy an `hello` application on the deployment group `development` after pushed the application on the `apps.mycompany.com` S3 bucket :

```
deploy:
  steps:
  # Install aws cli
  - edgecaseadmin/install-aws-cli:
     key: AKRAIRVTDYKVCGUDJ3FJ3
     secret: 7ERFCYIVkZGPH9ujUJsmSsB9qxXWLYPmcsa4Os1Z5
     region: us-east-1 
  # AWS Code Deploy
  - nhuray/aws-code-deploy:
     application-name: hello
     application-version: 1.1.0
     deployment-group-name: development
     s3-bucket: apps.mycompany.com
     s3-region: us-east-1
     service-role-arn: arn:aws:iam::89862646$091:role/CodeDeploy
     ec2-tag-filters: Key=app,Value=hello,Type=KEY_AND_VALUE Key=environment,Value=development,Type=KEY_AND_VALUE
```
