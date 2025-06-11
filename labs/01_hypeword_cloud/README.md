# 2. Hypeword Cloud

## Content

- Getting the AWS CLI to work
- Logging into the management console

## Installing the CLI

To install the AWS CLI, follow these steps:
1. Download the AWS CLI installer from the official AWS page.
2. Run the installer and follow the on-screen instructions.
3. Verify the installation by running:
```bash
aws --version
```
## Getting root Keys
1. Navigate to the [AWS Management Console](https://aws.amazon.com/console/).
2. Enter your credentials to log in.
3. Switch the region to eu-central-1
4. To access root keys:
    - Go to My Security Credentials.
    - Select Access keys.
    - Create new access keys if you don’t have any.
5. Export them
```bash
export AWS_ACCESS_KEY=<key>
```
```bash
export AWS_SECRET_ACCESS_KEY=<key>
```
## SSO Configure for Profiles
This will be used LATER (after chapter 3). Don't do it before.   
To configure SSO profiles for AWS CLI:
1. Run the following command:
```bash
aws configure sso
```
2. Follow the prompts to:
    - Enter your SSO start URL.
    - Specify the AWS Region.
    - Choose the account and role.
3. After configuration, export profiles with:
```bash
export AWS_PROFILE=<profile_name>
```