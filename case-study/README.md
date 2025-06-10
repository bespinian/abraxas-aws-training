# 9. DevOps in and to AWS

>In this case-study you will do your first AWS architecture from planning to implementaion. Have fun!

## Task 1
- Draw an AWS Architecture on [draw.io](https://draw.io):
    - **Static** Front-End
    - **Eventbased** Backend
    - **Simple** RESTful API connecting both
    - Automated CICD Pipeline on AWS
- Avg 2 visitors / day
- Domain registration and DNS is **on AWS**
- No User-Accounts, no authenticated calls
- Admins have an admin app planned for later:
    - Plan **Admin IDP** and Authentication
    - An **Email identity** for my-fancy-app.ch needed
    - Login UI should be provisioned **by AWS**

## Task 2

- Validate your architecture
- Start developing the CICD pipeline:
    - The codebase is in this  [repository](./front-end/)
    - Find out how to build it on [SolidJS docs](https://www.solidjs.com/guides/getting-started)
- Create the CloudFormation / TF code:
    - Deploy all resources needed for the app
    - Don’t create the admin idp authentication 
    - Don’t create the dns topics or SSL certs
