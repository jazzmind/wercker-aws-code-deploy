wercker-aws-code-deploy
=======================

This wercker step permits to deploy applications with [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html
) service.

Please read the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) documentation and [API](http://docs.aws.amazon.com/cli/latest/reference/deploy/index.html) before using this step.


## Versions

| Release date | Step version | 
| -------------| -------------| 
| 2014-12-04   | 0.0.2        | 
| 2014-12-03   | 0.0.1        | 


## Configuration

The following configuration is required to configure this step :

#### AWS Authentication

* `access-key-id` (required) AWS Access Key ID
* `secret-access-key` (required) AWS Secret Access Key
* `default-region` (optional) [Deployment config name](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html) By default : CodeDeployDefault.OneAtATime

#### AWS Code Deploy - Application 

* `application-name` (required) Name of the application to deploy
* `application-revision` (required) Revision of the application to deploy

#### AWS Code Deploy - Deployment Group

* `deployment-group-name` (required) Name of the deployment group
* `service-role-arn` (required) Service role arn giving permissions to use [Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/how-to-create-deployment-group.html)
* `ec2-tag-filters` (optional) A list of Amazon EC2 tags to filter on when [creating a deployment group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html)
* `auto-scaling-groups` (optional) A list of Auto Scaling groups when [creating a deployment group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html) 
* `deployment-config-name` (optional) [Deployment config name](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html) By default : CodeDeployDefault.OneAtATime

#### AWS Code Deploy - S3 Configuration

* `s3-bucket` (required) S3 Bucket where applications are pushed 
* `s3-region` (required) S3 Bucket region

## Example

The following example deploy an `hello` application on the deployment group `development` after pushed the application on the `apps.mycompany.com` S3 bucket :

```
deploy:
  steps:
  ...
  - nhuray/aws-code-deploy:
     access-key-id: AKRAIRVTDYKVCGUDJ3FJ3
     secret-access-key: 7ERFCYIVkZGPH9ujUJsmSsB9qxXWLYPmcsa4Os1Z5
     application-name: hello
     application-revision: 1.1.0
     deployment-group-name: development
     s3-bucket: apps.mycompany.com
     s3-region: us-east-1
     service-role-arn: arn:aws:iam::89862646$091:role/CodeDeploy
```
