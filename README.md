# Dev Lab - Working effectively with the AWS Command Line Interface (CLI)

The AWS Command Line Interface (AWS CLI) is an open source tool that enables you to interact with AWS services using commands in your command-line shell. With minimal configuration, you can start using functionality equivalent to that provided by the browser-based AWS Management Console from the command prompt in your favorite terminal program. And, in some cases, there are even some things you can do with the CLI that you can't do with the browser-based AWS console (see below for one such example)!

All IaaS (infrastructure as a service) AWS administration, management, and access functions in the AWS Management Console are available in the AWS API and CLI. New AWS IaaS features and services provide full AWS Management Console functionality through the API and CLI at launch or within 180 days of launch. 

The AWS CLI provides direct access to the public APIs of AWS services. You can explore and interact with a service's capabilities with the AWS CLI, or develop shell scripts to manage your resources. 

In addition to the low-level, API-equivalent commands, several AWS services provide customizations for the AWS CLI. Customizations can include higher-level commands that simplify using a service with a complex API. For example, the `aws s3` set of commands provide a familiar syntax for managing files in Amazon Simple Storage Service (Amazon S3). We'll cover more on these Amazon S3 commands below.

## Setting Up The Environment

### Open a terminal window in an AWS Cloud 9 instance

For this lab, we'll use the AWS Cloud 9 web-based IDE to provide us with a terminal program running on a virtual machine that comes with the AWS CLI pre-installed and configured.

1. Navigate to the [AWS Cloud 9 web console](https://console.aws.amazon.com/cloud9/home?region=us-east-1)
2. On the left-hand sidebar, click 'Shared with you'
3. Find the 'AWS CLI DevLab Cloud9 Env' entry and click the 'Open IDE' button
4. After the interface loads, find the tab with the Terminal and click to maximize it

![Cloud 9 Maximize Terminal](https://raw.githubusercontent.com/gabehollombe-aws/aws-cli-devlab/master/Cloud9MaximizeTerminal.png)


## AWS CLI Basics

### Getting Help

To start with, let's explore how you can 'teach yourself to fish' by viewing the built-in help that comes with the AWS CLI. You can get help with any command when using the AWS CLI. To do so, simply type `help` at the end of a command name. 

For example, the following command displays help for the general AWS CLI options and the available top-level commands. 

```
aws help
```

Press `q` to exit the paginated help text when you're finished reading.

### The AWS CLI Command Structure

The AWS Command Line Interface (AWS CLI) uses a multipart structure on the command line that must be specified in this order: 

1. The base call to the `aws` program. 
2. The top-level *command*, which typically corresponds to an AWS service supported by the AWS CLI. 
3. The *subcommand* that specifies which operation to perform. 
4. General CLI options or parameters required by the operation. You can specify these in any order as long as they follow the first three parts. If an exclusive parameter is specified multiple times, only the *last value* applies. 

```
aws <command> <subcommand> [options and parameters]
```

Parameters can take various types of input values, such as numbers, strings, lists, maps, and JSON structures. What is supported is dependent upon the command and subcommand you specify. 

## Working With Amazon S3 Buckets and Files

Let's dive in with some commands that are really helpful for managing files on Amazon S3.

Amazon Simple Storage Service (Amazon S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance. Customers of all sizes and industries use it to store and protect any amount of data for a range of use cases, including websites and data backup/restore/archival scenarios. 

S3 is so useful for storing and retrieving files that developers will often interact with it from the command line. In this section, you'll create a new bucket, put some files in it by syncing a folder from the local filesystem, and list the files from the remote bucket. There's a lot more you can do with S3 from the CLI, but this is a great start.


### Create a new S3 Bucket

Whenever you store data on S3, you put it in a construct called a bucket. A bucket is just a namespace that groups data objects together at the root level, similar to how the files on your computer reside on your hard drive. 

S3 Buckets must have globally unique names. Let's make a unique bucket name and store it in a shell variable so we don't have to re-type it all the time.

```
export BUCKET_NAME="devlab-cli-bucket-$(uuidgen)"
echo $BUCKET_NAME
```

Now let's use that unique name to make a bucket

```
aws s3 mb s3://$BUCKET_NAME
```

As mentioned above, the command structure for working with the AWS CLI follows this pattern: aws <command> <sub-command> <arguments>. In the line above, we're using the `s3` command and the `mb` (for 'make bucket') sub-command, passing in our bucket name as the argument for the command. 


### Sync a local folder with the bucket

That `sync` sub-command you might have seen inside `aws s3 help` is a really great one to know about. Heres what it says inside `aws s3 sync help`: 


> Syncs directories and S3 prefixes. Recursively copies new and updated files from the source directory to the destination. Only creates folders in the destination if they contain one or more files.


Let's try it out by taking a directory with a lot of files in it and synchronizing it to our S3 bucket. Our Cloud 9 virtual machine has some basic website structure in `/var/www` so let's just use that. Run

```
aws s3 sync /var/www s3://$BUCKET_NAME
```

to sync the local directory with the S3 bucket. 

When the sync finishes, you can list the contents of the S3 bucket to see what's there, if you like, with 

```
aws s3 ls s3://$BUCKET_NAME
```

A popular use for the `aw s3 sync` command is for publishing a website built with a static site generator. Since [S3 is capable of hosting static websites](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html) from a publicly accessible bucket, if you configure a bucket for website hosting, deploying new builds is as easy as running your build command on your local development workstation or CI build server and then running `aws s3 sync path/to/built/site s3://your-webite-s3-bucket`. 

Finally, let's clean up by deleting the S3 bucket and all of the content inside of it

```
aws s3 rb s3://$BUCKET_NAME --force
```



## Filtering and Querying

When working with the AWS CLI, you'll often want to limit the amount of information retrieved. For this purpose, you can use the `--filter` and `--query` flags.

### Filter the data server-side

Some (not all) AWS CLI commands support the `--filter` flag to limit the items returned from the server. For example,  `aws ec2 describe-images` allows you to list all of the images available for you to base your EC2 virtual machines off of. It accepts a `--filter` argument, allowing you to narrow down the list of results before the server sends the data back to your terminal.

Here's an example of this in action, taken from `aws ec2 describe-images help`

> This  example describes Windows AMIs provided by Amazon that are backed by Amazon EBS.

Try running this command to see the `--filters` argument in action

```
aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs"
```

After a moment, you'll see a LOT of text begin to scroll by in the response. Press `Control-c` to interrupt the output and return to a command prompt. 

We saw so much output from the command above because there are many images that match these filter parameters, and because the JSON output format defaults to including many fields for each item in the result set. Keep reading to see what we can do about it.


### Query The Data Client-side

Often, we're not interested in all of the data returned by the API endpoints and so, the AWS CLI provides the `--query` argument to allow us to provide a specially formatted string called a JMES Path Expression to limit and optionally transform the output before the CLI writes the output.

Using the same example from the filtering section above, let's use the `--query` argument to narrow down what information we see:

```
aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" --query "Images[0:10].{name: Name, id: ImageId}" 
```

You can think of this query as saying “Show me all of the values in the array returned by the 'Images' key at the top level. Take a slice of only the first ten items. Then, for each image item, take the Name field and return it under the 'name' key, and take the ImageId field and return it under the 'id' key.

The query example shown above is pretty simple, but you can do very powerful queries and transforms using JMES Path expressions. Take a look at http://jmespath.org/examples.html for more inspiration on what you can achieve here. Also, you may find the open source tool `jq` helpful for working with JSON results on the command line. See https://stedolan.github.io/jq/ to learn more.

The output from our command above that uses the additional query argument is easier on the eyes than a wall of JSON containing fields we don't care about, but we can still do better.


### Use different Output Styles

Sometimes it can be a lot easier to read the output from AWS CLI commands if we change the output format. In addition to the default JSON output, the AWS CLI can also output results in an ASCII tabular format or as tab-seperated lines of text.

Take the same command we used directly above, but change the output format to a table with `--output=table`

```
aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" --query "Images[0:10].{name: Name, id: ImageId}" --output=table
```

Doesn't that look prettier?

The text output style from `--output-text` is helpful for passing the results on to other UNIX commands like this

```
aws ec2 describe-images --owners amazon --filters "Name=platform,Values=windows" "Name=root-device-type,Values=ebs" --query "Images[0:10].{name: Name, id: ImageId}" --output=text | cut -f 2 | sort
```



## Putting it All Together

Let's take everything we've learned above and put it together into one comprehensive example.

First, we'll create an IAM role suitable for attaching to an EC2 instance. This is a common practice that lets you grant EC2 instances permissions for various API calls on AWS without having to manage credentials yourself on the instance.

Copy and paste the following AWS CLI commands into the Cloud9 terminal.

```
aws iam create-role \
--role-name "Cloud9-devlab-ec2-role" \
--description "Allows EC2 instances to call AWS services with given permissions." \
--assume-role-policy-document \
'{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["sts:AssumeRole"],"Principal":{"Service":["ec2.amazonaws.com"]}}]}'

aws iam attach-role-policy \
--role-name "`Cloud9-`devlab-ec2-role" \
--policy-arn "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
```

*Note: Normally, you would also create an instance profile for this role to attach it to an EC2 instance, but we'll skip that step for brevity's sake here. [More info on instance roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html).*

Now, we'll try to delete the role, which won't work because you can't delete a role that has policies attached to it.

```
aws iam delete-role —role-name Cloud9-devlab-ec2-role
```

Notice the error message:


> An error occurred (DeleteConflict) when calling the DeleteRole operation: Cannot delete entity, must detach all policies first.


So in order to delete a role, we must first detach all of the policies from it. Of course, we can do this one at a time by hand, but let's use the power of the CLI with a little shell scripting to automate this process.

Let's use a shell script to find all roles that begin with `Cloud9-dev`, detach all the policies from them, then delete the roles. 

1. First we'll fetch the roles with `aws iam list-roles` and use a `--query` parameter to only find roles with names starting with `Cloud9-dev`. 
2. Then, for each role we'll fetch its attached policies with `aws iam list-attached-role-policies` taking care to only select back the policy ARN for each attachment. 
3. We'll then call `aws iam detach-role-policy` to detach the policy from the role.
4. Finally, we'll use `aws iam delete-role` to delete the role.

Copy and paste the following shell script into the Cloud9 terminal:

```
roles=$(aws iam list-roles --query 'Roles[?starts_with(RoleName, `Cloud9-devlab`)].RoleName' --output text)

for role in $roles; do
  policies=$(aws iam list-attached-role-policies --role-name=$role --query AttachedPolicies[*][PolicyArn] --output text)
  for policy in $policies; do
    aws iam detach-role-policy --policy-arn $policy --role-name $role
  done
  aws iam delete-role --role-name $role
done
```

And this time, our attempt succeeds, because we removed all of the attached policies first! 

## Further Reading

Congratulations! You've taken your first steps towards becoming more familiar with the powerful AWS Command Line Interface. To continue your learning journey, you might enjoy the following resources:

[The AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
[The JMES Path Site](http://jmespath.org/) (for querying JSON results with the AWS CLI)

