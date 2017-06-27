Wercker step for AWS Code Deploy
=======================

[![wercker status](https://app.wercker.com/status/3810984a0833d6af679f0609bd3e18be/m "wercker status")](https://app.wercker.com/project/bykey/3810984a0833d6af679f0609bd3e18be)

This wercker step allows to deploy applications with [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) service.

Please read the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) documentation and [API](http://docs.aws.amazon.com/cli/latest/reference/deploy/index.html) before using this step.


The step install the [AWS Cli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) through pip, if the CLI is not already installed.


## AWS Code Deploy workflow

To deploy an application with AWS Code Deploy, the Wercker step follow this steps :

#### Step 1 : [Configuring AWS](http://docs.aws.amazon.com/cli/latest/reference/configure/index.html)

This initial step consists on configuring AWS.

The following configuration allows to setup this step :

* `key` (required): AWS Access Key ID
* `secret` (required): AWS Secret Access Key
* `region` (optional): Default region name
* `skip` (optional, default `false`): Skip deployment on a flag value

#### Step 2 : [Defining Application](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html)

This second step consists on defining the application. If the application does not exists this step create the application in Code Deploy.

The following configuration allows to setup this step :

* `application-name` (required): Name of the application to deploy
* `application-version` (optional): Version of the application to deploy. By default: Short commit id _(eg. fec8f4a)_

#### Step 3 : [Defining Deployment Config](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html) (optional)

This step consists on creating a deployment config. This step is totally *optional* because you can use the deployment strategy already defined in Code Deploy.

The following configuration allows to setup this step :

* `deployment-config-name` (optional): Deployment config name. By default : _CodeDeployDefault.OneAtATime_
* `minimum-healthy-hosts` (optional): The minimum number of healthy instances during deployment. By default : _type=FLEET_PERCENT,value=75_

#### Step 4 : [Defining Deployment Group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html)

This step consists on defining a deployment group. If the deployment group provided does not exists this step create a deployment group in Code Deploy.

The following configuration allows to setup this step :

* `deployment-group-name` (required): Deployment group name
* `service-role-arn` (optional): Service role arn giving permissions to use Code Deploy when creating a deployment group
* `ec2-tag-filters` (optional): EC2 tags to filter on when creating a deployment group
* `auto-scaling-groups` (optional): Auto Scaling groups when creating a deployment group

#### Step 5 : [Pushing to S3](http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html)

This step consists to push the application to S3.

The following configuration allows to setup this step :

* `s3-bucket` (required): S3 Bucket
* `s3-source` (optional): S3 Source. By default : _._
* `s3-key` (optional): S3 Key. By default: _{application-name}_

#### Step 6 : [Registering Revision](http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html)

This step consists to register the revision in Code Deploy.

The following configuration allows to setup this step :

* `revision` (optional): Revision of the application to deploy. By default: _{application-name}-{application-version}.zip_
* `revision-description` (optional): Description of the revision of the application to deploy

#### Step 7 : [Creating Deployment](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html)

This final step consists to create the deployment in Code Deploy.

The following configuration allows to setup this step :

* `deployment-description` (optional): Description of the deployment
* `deployment-overview` (optional): Visualize the deployment. By default : _true_

## Example

The following example deploy an `hello` application on the deployment group `development` after pushed the application on the `apps.mycompany.com` S3 bucket :

```
deploy:
  steps:
    - nhuray/aws-code-deploy:
       key: aws_access_key_id
       secret: aws_access_secret_id
       application-name: hello
       application-version: 1.1.0
       deployment-group-name: development
       service-role-arn: arn:aws:iam::89862646$091:role/CodeDeploy
       ec2-tag-filters: Key=app,Value=hello,Type=KEY_AND_VALUE Key=environment,Value=development,Type=KEY_AND_VALUE
       s3-bucket: apps.mycompany.com
       skip: false
```
