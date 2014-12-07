Wercker step for AWS Code Deploy
=======================

This wercker step allows to deploy applications with [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) service.

Please read the [AWS Code Deploy](http://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html) documentation and [API](http://docs.aws.amazon.com/cli/latest/reference/deploy/index.html) before using this step.

This step use the [AWS Cli](http://docs.aws.amazon.com/cli/latest/reference/), so you have to use this step with a box where AWS Cli is already installed
or install AWS Cli with this Wercker step : [EdgecaseInc/wercker-step-install-aws-cli](https://github.com/EdgecaseInc/wercker-step-install-aws-cli).

## AWS Code Deploy workflow

To deploy an application with AWS Code Deploy, the Wercker step follow this steps : 

#### Step 1 : [Defining Application](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html) 

This first step consists on defining the application. If the application does not exists this step create the application in Code Deploy.
 
The following configuration allows to configure this step :

* `application-name` (required) Name of the application to deploy
* `application-version` (optional) Version of the application to deploy. By default: Short commit id _(eg. fec8f4a)_

#### Step 2 : [Defining Deployment Config](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html) (optional)

The second step consists on creating a deployment config. This step is totally *optional* because you can use the deployment strategy already defined in Code Deploy.

The following configuration allows to configure this step :

* `deployment-config-name` (optional) Deployment config name. By default : _CodeDeployDefault.OneAtATime_
* `minimum-healthy-hosts` (optional) The minimum number of healthy instances during deployment. By default : _type=FLEET_PERCENT,value=75_

#### Step 3 : [Defining Deployment Group](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-group.html)

The third step consists on defining a deployment group. If the deployment group provided does not exists this step create a deployment group in Code Deploy.

The following configuration allows to configure this step :

* `deployment-group-name` (required) Deployment group name
* `service-role-arn` (optional) Service role arn giving permissions to use Code Deploy when creating a deployment group
* `ec2-tag-filters` (optional) EC2 tags to filter on when creating a deployment group
* `auto-scaling-groups` (optional) Auto Scaling groups when creating a deployment group 

#### Step 4 : [Pushing to S3](http://docs.aws.amazon.com/cli/latest/reference/deploy/push.html)

This step consists to push the application to S3.

The following configuration allows to configure this step :

* `s3-bucket` (required) S3 Bucket
* `s3-source` (optional) S3 Source. By default : _._
* `s3-key` (optional) S3 Key. By default: _{application-name}_

#### Step 5 : [Registering Revision](http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html) 

This step consists to register the revision in Code Deploy.

The following configuration allows to configure this step :

* `revision` (optional) Revision of the application to deploy. By default: _{application-name}-{application-version}.zip_
* `revision-description` (optional) Description of the revision of the application to deploy

#### Step 6 : [Creating Deployment](http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html) 

This final step consists to create the deployment in Code Deploy.

The following configuration allows to configure this step :

* `deployment-description` (optional) Description of the deployment
* `deployment-overview` (optional) Visualize the deployment. By default : _true_

## Example

The following example deploy an `hello` application on the deployment group `development` after pushed the application on the `apps.mycompany.com` S3 bucket :

```
deploy:
  steps:
    - nhuray/aws-code-deploy:
       application-name: hello
       application-version: 1.1.0
       deployment-group-name: development
       s3-bucket: apps.mycompany.com
       service-role-arn: arn:aws:iam::89862646$091:role/CodeDeploy
       ec2-tag-filters: Key=app,Value=hello,Type=KEY_AND_VALUE Key=environment,Value=development,Type=KEY_AND_VALUE
```
