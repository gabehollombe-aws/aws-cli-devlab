#!/bin/bash

# If you're running this Dev lab on a shared machine (say, at an AWS Summit), 
# this script will clean up some of the resources that may be lurking around if 
# the previous user didn't finish the lab.

roles=$(aws iam list-roles --query 'Roles[?starts_with(RoleName, `Cloud9-devlab`)].RoleName' --output text)

for role in $roles; do
  policies=$(aws iam list-attached-role-policies --role-name=$role --query AttachedPolicies[*][PolicyArn] --output text)
  for policy in $policies; do
    aws iam detach-role-policy --policy-arn $policy --role-name $role
  done
  aws iam delete-role --role-name $role
done
