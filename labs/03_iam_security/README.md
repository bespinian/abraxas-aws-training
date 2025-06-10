# 3. Identity, Access and Security

Security is a shared responsibility in the cloud — AWS secures the infrastructure, while you secure everything you build on top of it. In this chapter, we’ll focus on **identity, access control, encryption, and threat detection** services.

## Content

- Least Privilege principle
- Best practise security patterns
- The following services will be explained and focued on:
    - Artifact
    - Audit Manager
    - Cloud Trail
    - Cognito
    - Detective
    - Guard Duty
    - IAM
    - Identity Center
    - KMS
    - Macie
    - Organization SCP's
    - Security Hub

## Least Privilege Principle

The **Principle of Least Privilege (PoLP)** means **giving users, applications, and systems the minimum access** they need to perform their task — no more, no less.

### Why it matters:

- Reduces the blast radius in case of compromise
- Limits accidental misconfigurations
- Helps meet compliance standards (e.g., ISO, SOC2)

### Examples:

- A developer needs read-only access to S3 buckets — not full admin permissions
- A Lambda function only needs permission to write to a specific DynamoDB table
- An EC2 instance should not be able to delete IAM roles

## Best Practice Security Patterns

To begin with, these service names an principle might sound gibberish to you. We wanted them to be on top so that whenever you revisit this chapter, you'll find them imediately on top. After you finished the lab, come back up here and re-read them again.

✅ **Use IAM Roles, not long-term IAM Users**
- Prefer temporary credentials via **STS** or **IAM Identity Center**

✅ **Segment access by environment**
- Use separate accounts or roles for dev, staging, and prod
- Apply **SCPs** to restrict capabilities

✅ **Centralize logging**
- Enable **CloudTrail**, **Config**, and **Security Hub** in every account
- Aggregate logs to a central logging account (via Control Tower or manually)

✅ **Encrypt everything**
- Use **KMS** to encrypt EBS, S3, RDS, and Lambda environment variables
- Use **customer-managed keys (CMKs)** when auditing key usage is critical

✅ **Continuously monitor and audit**
- Use **GuardDuty**, **Inspector**, and **Security Hub**
- Set up alerts on suspicious behavior or permission changes

✅ **Start with deny**
- When unsure, start by denying access and grant incrementally
- Use **IAM Access Analyzer** and **last accessed** data to review unused permissions

You’ll now dive into individual services that implement these principles in the following sub-chapters:

## IAM, Identity Center and Organization SCP's

### IAM
AWS IAM (Identity and Access Management) is the foundation of access control in AWS. It defines **who** can do **what** on **which resources**, and under **what conditions**.

Understanding the following core components of IAM is essential to implementing secure and manageable access controls.

#### 🔐 IAM Users
- Represent individual people or applications
- Have **long-term credentials** (password + access keys)
- Should be avoided when possible in favor of **roles**

#### 👥 IAM Groups
- Collections of users
- Used to manage permissions **at scale**
- Cannot be nested (no group-in-group)

#### 🎭 IAM Roles
- Intended for **temporary access**
- Assumed by:
  - AWS services (e.g., Lambda assuming a role)
  - Other IAM users or roles (cross-account access)
  - External identities (SAML, Identity Center)
- Preferred over users for service and cross-account access

#### 📄 IAM Policies
- JSON documents that define permissions
- Attached to users, groups, or roles
- Consist of one or more **statements**

**IAM Policy Statement Structure**

It is broken down to:
- Effect: Allow or Deny
- Action: One or more AWS service actions (e.g., ec2:StartInstances)
- Resource: One or more ARNs (Amazon Resource Names)
- Condition: (optional) Restrict based on time, IP, tag, MFA, etc.

Example:
```json
{
  "Effect": "Allow",
  "Action": "s3:ListBucket",
  "Resource": "arn:aws:s3:::my-bucket"
}
```

#### Access Strategies
IAM supports fine-grained permission models. Here are common strategies:
- Least privilege: Start with no permissions and add only what is required
- Scoped roles: Use narrowly defined roles for each task or persona
- Federation: Use temporary roles instead of long-term credentials
- Tag-based access control (ABAC): Grant access based on tags like project or environment
- Cross-account roles: Use trust policies for delegation between accounts

#### Best practise
✅ Use roles instead of users  
✅ Avoid root — lock it down, use only for break-glass  
✅ Assign permissions to groups or roles, not individuals  
✅ Use managed policies for standard access, inline for exceptions  
✅ Use conditions (e.g., IP range, MFA) for added security  
✅ Monitor with IAM Access Analyzer and “last accessed” data  
❌ Don’t give AdministratorAccess by default  
❌ Don’t embed secrets in policies or environment variables  

#### Hands-On: Writing your first role and policy 
> In this exercise, you’ll create a scoped IAM policy that allows the user to access **AWS Cost Explorer** and an IAM user to test the permissions, but the scope is set to only let you access Cost explorer from within the region `eu-central-1`.

**Goal:**
- Create a **custom policy** that grants access to **Cost Explorer**
- Add a **condition** that restricts usage to **eu-central-1**
- Create a new user and attach the policy to him

**Task**
1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Open the AWS Console → Navigate to **IAM**
3. In the left sidebar, click **Policies** → **Create policy**
4. Now write the policy according to the specs (Tip 1, go check out the api from [cost explorer](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_Operations_AWS_Cost_Explorer_Service.html) and tip 2 you can use wildcards for statements like `Get*` or `List*`)
5. Now create a user, attach the policy to him. Log into that user and check if he can access the cost controler. 

### IAM Identity Center (formerly AWS SSO)

**AWS IAM Identity Center** is the recommended way to manage **workforce access** to AWS accounts, roles, and applications.

Instead of creating IAM users in each account, Identity Center lets you:

- Connect a **central directory** (native or external like Okta, Azure AD)
- Create and manage **user groups and permissions** centrally
- Assign **roles to users across multiple AWS accounts**
- Use **short-lived, secure credentials** (no permanent access keys)

#### Identity Center Concepts

| Term                  | Meaning                                                                 |
|-----------------------|-------------------------------------------------------------------------|
| **User**              | A person or service identity (either manually created or from IdP)      |
| **Group**             | Logical grouping of users (e.g., Admins, Developers)                    |
| **Permission Set**    | A reusable set of IAM permissions (like a policy template)              |
| **Account Assignment**| A mapping of user/group → account → permission set                      |
| **Identity Source**   | Where users come from: AWS native, or external IdP (e.g., Azure AD)     |

You can assign **different permissions to different groups in different accounts** — without logging into each account separately.

#### Best Practices

✅ Use **Groups** to assign permissions (never assign per-user unless exceptional)  
✅ Use **Permission Sets** to reflect job functions (Admin, Developer, Auditor, etc.)  
✅ Grant **least privilege** (e.g., PowerUser instead of Admin where possible)  
✅ Name permission sets clearly: `Admin-All`, `Dev-Sandbox`, `CCC-Management`  
✅ Use **OU-based account assignments** for scalability  
✅ Regularly review group membership and access reports  
❌ Avoid assigning Admin access everywhere “just in case”

#### Hands-On Lab – Creating Identity Center Access Across Accounts

> In this lab, you’ll define three user roles in Identity Center, and assign them to the appropriate accounts and OUs in your AWS Organization.

**Goal:**  
Create three **permission sets**:
- `AdminRole` – full admin access
- `CloudCompetenceCenterRole` – power user access
- `DeveloperRole` – scoped access to compute, storage, analytics, and AI  

Assign them to:   
- Admin → All accounts
- CCC → All accounts in `management` and `sandbox`
- Dev → Only accounts in `sandbox`


**Recap of Your Organization Structure**
```
/ (root)
├── management
│ ├── security
│ ├── configuration
│ └── network
└── sandbox
  └── test
```
1. **Watch out if you use Terraform for this task**: Resources aren't called "Identity Center" but have still the formerly legacy name of `SSO Admin` and `SSO Identity Store`
2. If you don't use Terraform, then **Go to** → AWS Console → **IAM Identity Center**
3. Go to **Permission sets** → Click **Create permission set**
4. Create different roles. Wherever possible use AWS-managed policies or role templates (tip: The fulladmin requires a AWS managed `policy` while the CCC will be able to use a power user template `role`). 
5. The dev role is the hardest to define. To ensure proper `least privilege` principle, we will append the permissions whenever we go into a new lab. Just note that whenever you have a permission issue, go back to this role and append additional permissions (or add them in Terraform).
6. Create the user groups Admin, CCC and Dev and add the defined permission sets to each role
7. Create a user for yourself and add him to all three groups (then you should be able to decide on each login, which role you are going to use)
8. Go to the accounts section and add the user groups according to the plan above
9. On the Identity Center Dashboard, you will find your `AWS access portal URL`. Log in with the newly created user.
10. If everything worked properly you should see the respective roles on each account:
```
/ (root) -> admin
├── management
│ ├── security -> admin, ccc
│ ├── configuration -> admin, ccc
│ └── network -> admin, ccc
└── sandbox
  └── test -> admin, ccc, dev
```

#### What happened?
✅ Users will now log in via the AWS access portal, see the accounts and roles assigned to them, and switch seamlessly   
✅ All access is temporary — no permanent credentials   
✅ Assignments are centrally managed in one place   
✅ You’ve avoided IAM users entirely
✅ Access is role-based, account-scoped, and centralized
✅ You can scale this model for large teams or entire organizations

### When to Use IAM Users, Groups, Roles, and Identity Center

Not all IAM tools are created equal — and not all of them should still be used today.

If you’re building in 2025 and beyond, this is the honest breakdown:

#### 👤 IAM Users

> ❌ **Deprecated pattern for human access. Use Identity Center instead.**

✅ Use IAM users **only if you absolutely must**:
- Your organization **does not use Identity Center or an external IdP**
- You’re building a **quick prototype in a sandbox**
- You need **long-term credentials** for automation (and even then, prefer IAM roles with automation tools)

❌ Don’t use IAM users for:
- Developers
- Admins
- Auditors
- Human login

They are harder to manage, harder to audit, and easier to compromise.

#### 👥 IAM Groups

> ✅ Still useful **only** if you are using IAM users.

- IAM Groups are a way to **attach policies to multiple IAM users**
- Useful for **sandbox environments** or **legacy systems** still using IAM users

⚠️ If you’ve adopted **Identity Center**, you can safely ignore IAM groups.

#### 🎭 IAM Roles

> ✅ The **foundation of access** in AWS — keep using them.

Use roles for:
- **Temporary human access** (via Identity Center or STS)
- **Machine-to-AWS access** (e.g., EC2 → S3)
- **Service-to-service access**
- **Cross-account access**

✅ Roles are the **right way** to implement access logic across services and accounts.

#### 🔐 IAM Identity Center (formerly AWS SSO)

> ✅ The **modern, preferred solution** for human access across AWS.

- Centralized access management
- Easily integrates with external IdPs (Okta, Azure AD, etc.)
- Assign users and groups **across multiple AWS accounts and roles**
- Uses **IAM Roles + Permission Sets** under the hood
- Eliminates long-term credentials

Identity Center is the **standard** for workforce access in multi-account AWS environments.

#### 🧭 Summary Table – What to Use in 2025

| Scenario                            | IAM User | IAM Group | IAM Role | Identity Center |
|-------------------------------------|----------|-----------|----------|------------------|
| Human login across accounts         | ❌       | ❌        | ✅       | ✅           |
| Machine-to-service (e.g. EC2 → S3)       | ❌       | ❌        | ✅       | ❌               |
| Federated access (e.g., Azure AD)   | ❌       | ❌        | ✅       | ✅               |
| Long-term API access (non-human)    | ⚠️ *     | ⚠️ *     | ✅       | ❌               |
| Sandbox dev work (quick and dirty)  | ✅       | ✅        | ✅       | ❌ or ✅         |
| Multi-account access control        | ❌       | ❌        | ✅       | ✅               |

⚠️ *Long-term credentials (via IAM user access keys) should be rotated frequently and avoided when possible. Prefer temporary credentials via STS or tools like IAM Roles Anywhere.*

#### Best Practice in 2025

✅ **Use Identity Center** for all human access  
✅ **Use IAM Roles** for service-to-service, automation, and federated access  
✅ Avoid IAM users unless you're in a rare edge case  
❌ Don't build new orgs with IAM users and groups unless you're intentionally choosing legacy for some reason

### Best Practice Security for the Root User Account

The **root user** is the original identity that creates an AWS account. It has **full access** to every resource and every setting in AWS — no matter what policies are in place.

🔒 That’s why it must be **locked down** and **rarely used**.

#### Why the Root User Is Dangerous

- It **cannot be restricted** by IAM policies
- It **bypasses SCPs** (Service Control Policies can limit its use, but not fully in all cases)
- It is the **single point of ultimate control**
- If compromised, your **entire AWS environment is at risk**

#### 🔐 Root Account Best Practices

✅ **Enable MFA** (Multi-Factor Authentication)  
   - Use a **hardware MFA device** or a **secure authenticator app**
   - Never rely solely on email + password

✅ **Create a named IAM admin user/role in Identity Center** for daily use  
   - Don’t use the root user for management tasks
   - Assign permissions through IAM Identity Center instead

✅ **Forget your password**  
   - Forget it forever. 
   - Use MFA + Password recovery to create a new temporary password whenever you want to access root
   - After using it, don't write it down. We will never use it again!

✅ **Use as many characters and symbols as possible**  
   - After all, wwe want the most secure password, since we will not remember it but instead recover a new one next time
   - The more complex, the smaller the chance of brute force entry

✅ **Remove access keys from the root user**  
   - You should **never generate or use** access keys for root

✅ **Create CloudTrail + Config logs early**  
   - This ensures root activity is auditable and detectable
   - Later you will learn how to monitor and alter via CloudWatch -> Use this to alert whenever someone logs in as root to be informed about breaches!

✅ **Use AWS Organizations to isolate accounts**  
   - Restrict what root access can actually impact across environments

✅ **Test recovery procedures** annually  
   - Make sure you know how to recover access, for the lost root credentials

#### ✅ Use Root Only For:

Most of the time you will not use the root account. There are only these few tasks that only the root user can actually perform:
| Action                                          | Alternatives? |
|-------------------------------------------------|---------------|
| Setting up the first IAM admin or Identity Center | ❌ Required    |
| Changing the AWS support plan                    | ❌ Required    |
| Modifying billing info or tax settings           | ❌ Required    |
| Closing the AWS account                          | ❌ Required    |
| Rotating account-level keys (e.g., KMS, S3)       | ✅ Sometimes   |

#### ❌ Never Use Root For:

- Creating EC2 instances, S3 buckets, IAM users, or Lambda functions  
- Daily administrative tasks  
- Any long-term scripts or automation  
- Logging into the AWS Console regularly
- Any task generally, that another user could do

#### Hands-On Lab – Securing Your Root User

> In this exercise, you’ll verify and secure the root user account of your AWS Organization’s management account.

**Step-by-Step Instructions**

1. Log into your **management account** as the root user (final time).
2. Navigate to → **IAM** → **Security credentials** tab
3. Perform these actions:
   - ✅ Enable **MFA** if not already done  
   - ✅ Delete any **active access keys**  
   - ✅ Check **last activity time** of the root user  
   - ✅ Set up an **email alias** for root (e.g., aws-root@yourcompany.com)
4. Log out, and **never use this account again** unless in emergency situations.

✅ From this point forward, use **IAM Identity Center roles** for all administrative tasks.

> You only get one root user per account. Treat it like a master key to your entire cloud kingdom. Hide it. Lock it. Forget about it.

### Organization SCP – Service Control Policies

**Service Control Policies (SCPs)** are guardrails for your AWS Organization. They define the **maximum set of permissions** available to accounts in your org — no matter what IAM policies say.

> If IAM says “allow” but the SCP says “deny” (or omits the action), the action is blocked.

The organization root account, each OU, and any account in the org has at least one SCP attached to it. When an org is first deployed, a SCP called FullAWSAccess is applied to every entity to ensure that originally every service is accessible to begin with. 
There are two strategies you can use - **whitelisting** and **blacklisting** services. Then SCP's work either implicitely through **whitelisting** (a service is inaccessible by not being included in an Allow statement) or through **blacklisting** explicitly (a service being included in a Deny statement)

#### How SCPs Work

- SCPs are attached to:
  - **Root** of the organization
  - **Organizational Units (OUs)**
  - **Individual member accounts**

- Permissions are **evaluated in aggregate**:  
  The **final permission = intersection** of:
  - SCPs (what’s allowed at org level)
  - IAM policies (what’s granted to the identity)
  - Any session policies (if using STS) for example via Identity Center

#### Key Rule

> SCPs apply to **everyone** in an account — even users with `AdministratorAccess`, or the **root user**.

#### Where SCPs Live

SCPs are **external** to the accounts they apply to.

- IAM admins **inside** an account (except the **management account**) **cannot see or modify** SCPs that apply to their own account
- You manage SCPs from the **management account** via **AWS Organizations**

#### Conditions in SCPs

SCPs support **conditions**, just like IAM policies.

✅ You can limit actions based on:
- **Region** (e.g., only allow use in `eu-central-1`)
- **Tags** (e.g., only allow access to tagged resources)
- **Service-specific conditions** (e.g., require encryption)

Example condition to enforce encryption for S3 uploads (or disallow to upload files that will not be encrypted):

```json
{
  "Sid": "DenyUnEncryptedObjectUploads",
  "Effect": "Deny",
  "Action": "s3:PutObject",
  "Resource": "*",
  "Condition": {
    "Bool": {
      "s3:x-amz-server-side-encryption": false
    }
  }
}
```
This SCP would then be attached to a OU or Account to enforce this rule from withing the root (**management account**) account.

#### Range of Effect – What SCPs Can and Cannot Control
✅ What SCPs can control:
- Which services are allowed or blocked (e.g., block EC2, allow only S3)
- Which regions are usable
- Which actions can be performed (e.g., s3:DeleteObject, kms:Encrypt)
- What conditions apply (e.g., encryption enforced, tag presence)

❌ What SCPs cannot control:
- Access inside the account (you can’t specify “Bob can do this” — IAM does that)
- External principals (e.g., users from other AWS accounts outside your organisation)
- Finer resource-level controls (IAM handles this)
- What permissions identities see — SCPs silently block


#### Common SCP Strategy

There are two structure ways people use SCP's (and a ton of unstructured wild ways, that have no clear pattern). We recommend to go for one strategy we present, stay consistent with it and don't mix different approaches.

**Deny List Pattern** / **blacklisting**
1. Attach FullAWSAccess to allow everything by default to every SCP
2. Add a custom SCP that blocks specific risky behaviors and unwanted services / regions

> This is your goto strategy for letting your organization use full cloud capabilities and the one we most often recommend. This makes only sense, if you have some few services you don't want people to use in your organization (e.g. no EC2 is a classic deny we see often). If you want to block more than 50% of all services, we recommend the secnond approach!

**Allow List Pattern** / **whitelisting**
1. Remove FullAWSAccess from all SCP's. This way by default no service is allowed to use
2. Add a custom SCP that allows specific services and regions to be used

> This is your goto strategy for conservative behaviour and the one we most often try to avoid. This makes sense, if you only have some few edgecases you want to use or just some few services in generall. If you want to allow more than 50% of all services, we recommend the first approach!

#### SCP vs IAM vs Identity Center 

| Feature / Scope | SCP | IAM | Identity Center |
|-------------------------------------|----------|-----------|----------|
| Controls max permissions?         | ✅       | ❌       | ❌       |
|Applied outside the account?       | ✅       | ❌       | ✅       |
| Affects root user?                | ✅       | ❌        |❌        |
| Per-identity access control?      | ❌       | ✅        | ✅       |
| Good for org-wide policy?         | ✅       | ❌        | ✅       |
| Time-based or temporary?          | ❌       | ✅ (with STS)| ✅ (uses STS behind)  | 

#### SCP Best Practices
✅ Use SCPs to define guardrails, not fine-grained policies   
✅ Start with FullAWSAccess + explicit deny policies in most cases   
✅ Use OU targeting to control whole environments (e.g., block EC2 instances on sandboxes)   
✅ Combine with IAM policies and Identity Center roles   
✅ Monitor SCP effectiveness with Access Analyzer   

❌ Don’t rely on SCPs to enforce cross-account restrictions   
❌ Don’t use SCPs instead of tagging, logging, or proper IAM

#### Hands-On Lab – Deny All Regions Except eu-central-1 and eu-central-2
> In this lab, you’ll write and apply an SCP that blocks access to **any AWS region** except **Frankfurt (eu-central-1)** and **Zurich (eu-central-2)**.

This will be applied to the **`management` OU** from your earlier org structure:
```
/ (root)
├── management
│ ├── security
│ ├── configuration
│ └── network
└── sandbox
└── test
```
1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Log into the **management account**
3. Go to **AWS Organizations**
4. In the left menu, select **Policies** and create the scp with a deny policy
5. We have a blacklisting stratgey, so attach FullAWSAccess + your self written new policy it to the management OU
6. Now log into that account and test it

## Cognito

Amazon Cognito is AWS's **user identity and authentication service** for web and mobile apps.

It helps you:
- Add **sign-up**, **sign-in**, and **user management** to your applications
- Handle **federated login** (e.g., Google, Facebook, SAML)
- Issue **secure tokens** for authenticated sessions

### Key Features

| Feature                    | Description                                                             |
|----------------------------|-------------------------------------------------------------------------|
| **User Pools**             | Managed user directory with built-in signup, login, MFA, etc.           |
| **Identity Pools**         | Enable federated access to AWS resources using temporary credentials     |
| **Federation**             | Support for social (Google, Facebook), enterprise (SAML), and OpenID     |
| **Hosted UI**              | Ready-to-use auth screens without coding login UIs                      |
| **Multi-Factor Auth (MFA)**| Support for TOTP, SMS, email-based second factors                       |
| **Triggers**               | Lambda hooks on user events (pre/post signup, auth, confirm, etc.)      |

🧠 **User Pool** = Who they are  
🔐 **Identity Pool** = What they can access in AWS

### Cognito User Pool Feature Plans

Amazon Cognito offers three **feature plans** for user pools: **Lite**, **Essentials**, and **Plus**. Each plan provides a different level of functionality, customization, and security — and you can choose the one that best fits your application's needs.

#### 🔹 Lite Plan

> 🧪 Best for: Testing, simple internal tools, MVPs

- **Low-cost**, ideal for small-scale or low-risk applications
- Includes:
  - Basic sign-up and sign-in
  - Classic **Hosted UI** (limited customization)
- **Limitations**:
  - No access token customization
  - No passkey support
  - No advanced security or sign-in analytics

✅ Use if you're building a simple login portal without complex security requirements  
❌ Don’t use for public-facing or regulated apps

#### 🔸 Essentials Plan

> ⚙️ Best for: Production workloads with modern login experiences

- Includes everything in Lite, plus:
  - Support for **Managed Login** UI (modern, flexible)
  - **Choice-based sign-in** (e.g., username *or* email)
  - **Email-based MFA**
  - Passkey authentication support
  - Better user attribute management

✅ Recommended for most customer-facing apps  
✅ Provides a solid, secure auth experience  
❌ No advanced risk detection or activity logging

#### 🔶 Plus Plan

> 🔐 Best for: High-security environments, regulated apps, or anything customer-critical

- Includes everything in Essentials, plus:
  - **Security analytics** for sign-in, sign-up, and password changes
  - **Anomalous behavior detection**
    - Sign-in from unusual locations
    - Use of breached passwords
  - **Exportable activity logs** for external analysis
    - Integrate with SIEMs or security dashboards

✅ Use for compliance-heavy, enterprise-grade apps  
✅ Helps detect account takeover attempts and credential leaks  
✅ Recommended when security visibility and anomaly detection matter

#### Comparison Table

| Feature                          | Lite | Essentials | Plus |
|----------------------------------|------|------------|------|
| Basic sign-up/sign-in            | ✅   | ✅         | ✅   |
| Classic Hosted UI                | ✅   | ✅         | ✅   |
| Managed Login UI                 | ❌   | ✅         | ✅   |
| Email MFA                        | ❌   | ✅         | ✅   |
| Passkey authentication           | ❌   | ✅         | ✅   |
| Token customization              | ❌   | ✅         | ✅   |
| Risk-based sign-in analytics     | ❌   | ❌         | ✅   |
| Breached password detection      | ❌   | ❌         | ✅   |
| Exportable user activity logs    | ❌   | ❌         | ✅   |

✅ Start with **Essentials** for new production apps  
✅ Upgrade to **Plus** if you're handling sensitive or regulated user data  
✅ Avoid Lite unless you're prototyping or building low-impact internal tools  
❌ Don’t rely on Lite for anything public-facing with real users or data

### Cognito Use Cases

- Add authentication to apps without building your own auth system
- Federate users from multiple sources (e.g., Google + Azure AD + custom)
- Issue **AWS credentials** (via Identity Pools) for mobile/web apps to securely call AWS services

### Hands-On Lab – Create a Cognito User Pool

> In this lab, you’ll create a **User Pool**, enable self-registration, and test the hosted UI login screen.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Open AWS Console → Search for **Cognito**
3. Choose **Manage User Pools** → Click **Create user pool**
4. Create a userpool that at least takes in your name, email and enable MFA via SMS
5. Then create an app integration with the name `web-client`. Let it generate a `client secret` for later use (this will help authenticating you rest-api calls later).
6. Add a **Domain name** with a unique prefix to, which is needed to enable the hosted UI
7. Go to **App client settings**
   - Enable `Cognito User Pool` as provider
   - Callback URL: `https://example.com/callback` (placeholder)
   - Sign-out URL: `https://example.com/signout` (placeholder)
   - Enable `Authorization code grant`
   - Save changes
8. Now open the **Hosted UI URL** (link provided after saving)
   - You should see a login page
   - Try creating a user via **Sign Up**

#### What You Just Built

- A secure, managed **user directory**
- An app-ready **authentication interface**
- A foundation for issuing **JWTs** to authenticated users

### Best Practices

✅ Use Cognito for **user identity**, not direct AWS permissions  
✅ Combine with **Identity Pools** if you need AWS resource access  
✅ Use **triggers** for workflows like approvals, audits, notifications  
✅ Enforce password policies, MFA, and email verification in production   
❌ Don’t roll your own login system unless you have strong auth expertise - Rather choose Cognito whenever possible!  

## AWS CloudTrail

**AWS CloudTrail** is your primary service for logging **who did what, when, and from where** in your AWS environment.

> It records every API call and management console action made within your account(s).

### Key Features

- **Records AWS API calls and events** from:
  - Console
  - SDKs/CLI
  - AWS services (e.g., Lambda invoking S3)
- Captures:
  - **Identity**
  - **Time**
  - **Source IP**
  - **Region**
  - **Event type**
  - **Parameters passed**
- Stores logs in **S3**
- Integrates with **CloudWatch Logs** - Monitoring Service, **SNS** - Notification Service, and **EventBridge** - Eventbus service
- Can be **aggregated across accounts** via AWS Organizations

✅ Use CloudTrail to:
- Audit root account usage
- Track changes to multiple workload and management services
- Investigate incidents
- Detect unusual activity (e.g., login from unfamiliar IP)

### 🏛️ Strategy with AWS Organizations

In a multi-account environment, best practice is to configure a **centralized organization trail**:

1. **One trail at the org level** (created in the management account)
2. **Logs events from all accounts**
3. Delivered to a **central S3 bucket** (e.g., in `log-archive` account)
4. Enables consistent auditing and compliance enforcement
5. Avoids the need to configure CloudTrail separately in each account

✅ Combine CloudTrail with:
- **AWS Config** for configuration history
- **Security Hub** for alerting - will be covered just in a moment
- **GuardDuty** for threat detection - will be covered just in a moment

### 🔎 CloudTrail Insights

**CloudTrail Insights** helps detect **unusual or anomalous API activity** in your AWS accounts — like a sudden spike in IAM changes or EC2 launches.

Instead of just recording what happened, Insights tries to answer:
> "Is this behavior normal, or does it look suspicious?"

#### What It Detects

CloudTrail Insights watches for changes in:
- **API call volume** (e.g., sudden increase in `RunInstances`)
- **Rate of errors** (e.g., lots of failed logins)
- **Unusual behavior** patterns from users or services

It identifies **spikes and outliers**, not specific malicious actions.

#### Example Scenarios

| Scenario                                       | What You Might See                       |
|------------------------------------------------|-------------------------------------------|
| A script goes rogue and launches 100 EC2s      | Spike in `RunInstances` API calls         |
| An attacker brute-forces credentials           | Spike in `ConsoleLogin` errors            |
| Mass deletion of S3 objects                    | Surge in `DeleteObject` API calls         |

#### How to Enable It

1. Go to the **CloudTrail** console  
2. Select your **Organization Trail** or individual trail  
3. Click **Edit**  
4. Under **Insights events**, check:  
   ✅ **Enable Insights events**

You can choose to monitor:
- **Management events** (recommended)
- Read-only or write-only activity

#### Where the Data Goes

- Logged into the same **S3 bucket** as your trail
- Shows up in the **CloudTrail console under "Insights"**
- Can trigger **EventBridge rules** or **CloudWatch alarms** for response automation


#### Best Practices with CloudTrail Insights

✅ Enable **CloudTrail Insights** on all org-wide trails  
✅ Use it alongside **GuardDuty** for layered threat detection  
✅ Create alerts or dashboards in **CloudWatch** for anomaly tracking  
✅ Periodically review Insights events for baselining behavior  
❌ Don’t rely on Insights alone — it won’t catch every malicious act, just statistical outliers

### Hands-On Lab – Create an Organization Trail

> In this lab, you’ll create a centralized CloudTrail that records events from **all accounts in your organization** and delivers logs to a centralized S3 bucket.

#### Prerequisites

- You must be logged in as an admin in the **management account**
- Quickly log into `log-archive` and go to `S3` service. Just create a bucket called **YOUR_NAME**`-org-cloudtrail-logs` without any special configuration - Don't worry, we'll cover S3 in a later chapter in length

#### Step-by-Step Instructions

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
1. Go to **CloudTrail** in the AWS Console (management account)
2. Click **Create trail**
3. Apply the trail to all accounts in your organization
5. **Management events**:
   - Read/write events: ✅ (select both)
   - API activity: ✅ (full coverage)
6. **Storage location**:
   - Choose your central S3 bucket (e.g., `org-cloudtrail-logs`)
   - Enable log file validation ✅

#### What to Observe

- Go to your **S3 bucket** → Verify log files start appearing
- Use the **Event history** tab in CloudTrail to search for actions
- Try filtering:
  - `Event source: iam.amazonaws.com`
  - `Event name: CreateUser`
  - `Username: YOUR USERNAME.admin`

### Best Practices

✅ Always enable CloudTrail — it's your audit baseline  
✅ Use an **organization trail** for multi-account visibility  
✅ Send logs to **log-archive account** (not where the trail is created)  
✅ Enable **log file integrity validation**  
✅ Enable **data events** for critical buckets and functions  
✅ Combine with **CloudWatch Alarms**, **EventBridge**, or a **SIEM** of your choice  
❌ Don’t store logs in the same account that generates them (risk of tampering)

## Audit Manager

**AWS Audit Manager** helps you **automate evidence collection** for audits and compliance assessments. Instead of manually collecting logs, screenshots, or reports, it continuously maps AWS resource configurations and activity to specific **control frameworks** like ISO 27001, GDPR, or SOC 2.

### Key Features

- Automates **evidence collection** from AWS services (like CloudTrail, Config, IAM)
- Maps AWS activity to **compliance frameworks** like:
  - ISO 27001
  - GDPR
  - SOC 2
  - NIST 800-53
  - Custom frameworks
- Continuously collects evidence from:
  - **Resource configurations**
  - **API activity (via CloudTrail)**
  - **IAM policies and usage**
- Supports **multi-account** data aggregation via AWS Organizations
- Outputs **audit-ready reports** with attachments

> 🧠 Think of it as your auditor’s assistant: it pulls together the boring (but critical) evidence you’d otherwise gather manually.

### 📊 Audit Manager vs. CloudTrail

| Feature                        | **CloudTrail**                                     | **Audit Manager**                                |
|-------------------------------|----------------------------------------------------|--------------------------------------------------|
| Purpose                        | Logs all API calls                                 | Collects evidence for compliance frameworks      |
| Scope                          | Account or org-wide                                | Assessment-scoped across AWS services            |
| Format                         | Raw logs (JSON events)                             | Structured documents, mapped to controls         |
| Used for                       | Forensics, investigation, API auditing             | Internal/external audits, reports, certifications|
| Human-readable reporting       | ❌ No – log-based                                   | ✅ Yes – generates PDF/HTML reports              |
| Compliance framework support   | ❌ Not directly                                     | ✅ Prebuilt (CIS, ISO, NIST, etc.)               |
| Automation                     | ❌ None (implicitly)                         | ✅ Continuous evidence gathering                 |
| Who uses it                    | Engineers, security teams                          | Auditors, compliance teams                       |

### Best Practices

✅ Choose **Foundational Security Best Practices** as your baseline for all new workloads   
✅ Use **prebuilt frameworks** (e.g., CIS) for quick adoption  
✅ Delegate evidence reviews to **auditor IAM roles or Identity Center users**  
✅ Export reports before audits, not during them  
✅ Regularly export and review reports — don’t just “set and forget”  
✅ Combine with **CloudTrail** and **Config** for deep visibility  
❌ Don’t use Audit Manager as a substitute for actual security controls — it **verifies**, it doesn't **enforce**   
❌ Don’t rely on Audit Manager alone — it shows you *what’s collected*, not *what’s missing*   

## AWS Artifact

**AWS Artifact** is your central portal for accessing AWS **compliance reports**, **security attestations**, and **agreements** — directly from Amazon.

> If an auditor or legal team ever asks for AWS's SOC 2 report, ISO certifications, GDPR info, or HIPAA compliance — Artifact is where you go.

### Key Features

- 📄 **Download AWS compliance documents** (e.g., SOC 1, SOC 2, ISO 27001, PCI DSS)
- 📝 **Accept legal agreements** for services like:
  - HIPAA Business Associate Addendum (BAA)
  - GDPR Data Processing Addendum (DPA)
- 🕵️‍♂️ Access **third-party audit reports** to assess AWS’s internal security practices
- Supports **region-specific** and **service-specific** documentation

### Hands-On – Explore Artifact

> This is a quick, read-only lab to get familiar with AWS Artifact’s interface and purpose.

1. Log in to the AWS Console → Search for **Artifact**
2. Under **AWS Artifact**, explore two main sections:

   #### 1. **Reports**
   - Browse documents like:
     - SOC 1 Type II
     - SOC 2 Type II
     - ISO 27001/27017/27018
     - PCI DSS
   - Click a document → Accept the agreement → Download PDF

   #### 2. **Agreements**
   - Review and accept:
     - HIPAA BAA
     - GDPR DPA
   - Use the “View agreement status” to see if your org has accepted them

## Amazon Macie

**Amazon Macie** is a fully managed data security service that uses machine learning to automatically discover, classify, and protect **sensitive data** in Amazon S3 (File-Object Storage that will be covered in the next chapter).

> Think of it as a data privacy and compliance assistant — it helps you identify exposed PII, credentials, and other sensitive content in your storage buckets.

### 🔐 Key Features

- 📦 **Scans S3 buckets** for sensitive data like:
  - Names, addresses, phone numbers
  - Credit card numbers
  - AWS secret keys
  - National ID numbers (e.g., EU, US, UK formats)

- 🧠 Uses **Machine Learning and pattern matching** to detect data types

- 📊 Provides a **dashboard of findings**, including:
  - Severity level (Low, Medium, High)
  - Type of data detected
  - Object location (S3 bucket/key)

- 🏢 Supports **organization-wide scanning**
  - Enable Macie centrally from the **security account**
  - Automatically enrolls **member accounts**
  - All findings can be sent to the security account for central review

- 🗺️ Can scan **specific buckets** or your **entire environment**
- 🕵️‍♂️ Helps with compliance: GDPR, HIPAA, PCI DSS, etc.
- 🔄 Integrates with:
  - **Security Hub**
  - **EventBridge**
  - **SNS** for alerting
  - **S3 Object Lambda** for on-the-fly data inspection

### Best Practices

✅ Run Macie in all critical regions and accounts in AWS Organizations   
✅ Enable automated discovery jobs for regular scanning   
✅ Set up event-driven alerts for High severity findings directly **ONLY** if you don't use security hub   
✅ Integrate with Security Hub for centralized risk visibility   
✅ Avoid uploading unencrypted sensitive data into S3 at all   
❌ Don’t scan with Macie “once and forget” — make it part of ongoing compliance if you decide to use it!   
❌ Don’t rely on object metadata alone — Macie scans object content   

## GuardDuty

**Amazon GuardDuty** is a threat detection service that continuously monitors your AWS accounts, workloads, and data for **malicious activity** and **unauthorized behavior**.

> It’s your cloud-native security analyst — always on, always watching.

### Key Features

- ✅ **Agentless** threat detection — no need to install anything
- 🔍 Analyzes:
  - AWS CloudTrail logs (incl. S3, DNS, and IAM activity)
  - VPC (Networking Service in AWS) Flow Logs
  - DNS query logs
  - EKS (Kubernetes Service in AWS) audit logs (optional)
- 🧠 Uses machine learning + threat intelligence feeds (AWS, 3rd-party)
- 🚨 Detects:
  - Compromised IAM credentials
  - Crypto-mining behavior
  - Unusual API activity
  - Reconnaissance (e.g., port scanning)
  - Unauthorized data access (e.g., exfiltration from S3)
- 🛠 Integrates with:
  - **Security Hub**
  - **EventBridge** and **SNS** for real-time alerting
  - **Organizations** for central threat management

### 🏢 Organization-Wide Deployment

✅ GuardDuty supports centralized, org-wide activation:

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Enable from the **security account**
3. Automatically enroll **all member accounts**
4. Centralize findings in the **security account**
5. Apply consistent threat detection across your AWS environment

> Ideal for security teams that need to monitor all accounts from one place.

### Best Practices

✅ Enable GuardDuty across all accounts and regions   
✅ Set up automated response via EventBridge **ONLY** if you don't use security hub  
✅ Forward findings to Security Hub for centralized visibility   
✅ Regularly review severity levels and act on high risks   
✅ Tag and monitor critical resources (e.g., buckets, instances)   
❌ Don’t treat it as “set and forget” — integrate into response workflows if you decide to use it

## Amazon Detective

**Amazon Detective** helps security teams **investigate, visualize, and understand** the root cause of potential security issues in AWS.

> It works hand-in-hand with GuardDuty and CloudTrail to turn logs into visual, linked graphs of what happened and when.

### 🕵️‍♂️ Key Features

- 🔍 Automatically **analyzes and links data** from:
  - GuardDuty findings
  - CloudTrail logs
  - VPC Flow Logs
  - IAM actions and network traffic
- 🧠 Builds a **graph-based investigation model**
  - Resources (IAM users, EC2, IPs, etc.) are nodes
  - Events (API calls, alerts) are edges
- 🧭 Helps you understand:
  - What happened before and after a finding
  - Who made the call
  - What resources were involved
- 💡 Shows time-based views of:
  - Login behavior
  - API activity
  - Role assumption and session usage

> In short: GuardDuty says **"a thing happened"**, and Detective shows you **"the full story around it."**

### 🏢 Org-Wide Support

- Detective supports **organization-wide deployment**
- Enable from the **security account**
- Automatically ingests findings from **linked accounts**
- View **cross-account context** in one place (e.g., shared roles, IPs, compromised keys)

### Best Practices
✅ Use Detective in tandem with GuardDuty, CloudTrail, and Security Hub   
✅ Make it part of your incident response runbook if you decide to use it   
✅ Grant access only to incident responders / security analysts   
✅ Use event correlation to reduce false positives   
✅ Review entity profiles regularly for unusual patterns   
❌ Don’t rely on Detective for alerting — it’s an investigation tool, not a SIEM   

## AWS Security Hub

**AWS Security Hub** provides a **centralized view** of your security posture across AWS accounts and regions.

> It aggregates, normalizes, and prioritizes findings from AWS services and third-party tools — making it your single pane of glass for security.

### Key Features

- 📊 **Aggregates findings** from:
  - GuardDuty
  - Inspector
  - Macie
  - Firewall Manager
  - IAM Access Analyzer
  - Many third-party security tools (e.g., Palo Alto, Splunk, Trend Micro)

- ✅ Supports **AWS Foundational Security Best Practices (FSBP)**:
  - Predefined security controls across IAM, EC2, S3, etc.
  - Automatically checks for misconfigurations
  - Assigns severity and remediation steps

- 🔄 Consolidates findings across:
  - **Regions**
  - **Accounts** (via AWS Organizations)

- 🧩 Integrates with:
  - **EventBridge** (automate alerts or remediation)
  - **SNS / Lambda** for notification & response
  - **Detective** for deep investigation

- 📝 Findings are:
  - Normalized to AWS Security Finding Format (ASFF)
  - Deduplicated and timestamped
  - Assigned severity (Low, Medium, High, Critical)

### 🏢 Organization-Wide Strategy

- ✅ Enable Security Hub in the **security account**
- ✅ Auto-enable for all member accounts in AWS Organizations
- Centralizes all security findings in one console
- Can be integrated with **SIEMs**, ticketing tools, or Slack for alerts

> Ideal for cloud security teams monitoring multiple AWS accounts.

### Best Practices

✅ Enable Security Hub across all regions and accounts  
✅ Turn on **Foundational Best Practices** for automatic checks  
✅ Use **EventBridge** to notify teams or trigger automation (will be done in a lab in a later chapter)  
✅ If you use **EventBridge** on security hub, other services that are centralized into securit hub should **NOT** trigger eventbridge separately due to duplicate events being generated otherwise  
✅ Review findings regularly, not just before audits  
✅ Integrate with **third-party tools** for full visibility  
❌ Don’t ignore “Low” findings — many small issues become big ones

## AWS KMS – Key Management Service

**AWS Key Management Service (KMS)** is the backbone of encryption in AWS. It allows you to **create, manage, and audit encryption keys** used to protect your data at rest and in transit.

> If you’re encrypting anything in AWS — S3, RDS, EBS, Lambda, Secrets Manager — you’re using KMS, whether you realize it or not.


### Key Features

- 🔑 Create and manage **Customer Managed Keys (CMKs)**
- 🔒 **Integrated with over 100 AWS services**! AWS services integrate with KMS to **encrypt data at rest**
- 📊 Full **audit trail** via CloudTrail (every use of a key is logged)
- ⏱️ Optional **automatic key rotation** (every 1 year)
- 🏢 Supports **multi-account access** (you can share keys across accounts)
- ✅ FIPS-compliant and supports **Bring Your Own Key (BYOK)** scenarios
- 📏 Fine-grained IAM + KMS **key policies** for secure delegation

### 🧠 KMS Key Types

| Key Type          | Description                                                            |
|-------------------|------------------------------------------------------------------------|
| **AWS Managed Key**   | Automatically created by AWS for a service (e.g., `aws/s3`, `aws/rds`) |
| **Customer Managed Key (CMK)** | You create and control it, including access policies, rotation, deletion |
| **Imported Key Material** | Bring your own key (e.g., from HSM) for compliance-sensitive workloads |

### 🔐 Encryption Modes

- **Envelope encryption**: AWS services use data keys (DEKs) to encrypt, and KMS encrypts the DEK
- **Symmetric keys**: Default, used for most workloads
- **Asymmetric keys**: Use for digital signatures and public-key encryption (less common)

### 💡 Why Use Customer-Managed Keys (CMKs)?

✅ Fine-grained access control  
✅ Enable/disable keys programmatically  
✅ Audit exact usage (who/what/when)  
✅ Rotate keys automatically or manually  
✅ Set usage policies per role, service, or time

> ⚠️ You are billed per CMK, so only create them when needed.

### Hands-On – Create and Use a KMS Key

> In this lab, you’ll create a **customer-managed KMS key**, then use it to encrypt/decrypt a simple value via the AWS CLI.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to the AWS Console → Search for **KMS**
3. Click **Create key**
4. Create a symmetric key for en- and decryption and enable automatic key rotation
5. Now add a key either via console or via terminal aws cli

✅ KMS returns the original secret in plaintext.

### Best Practices
✅ Use customer-managed keys (CMKs) for sensitive workloads   
✅ Enable automatic rotation for CMKs   
✅ Audit key usage via CloudTrail   
✅ Apply least privilege using key policies and IAM   
✅ Use envelope encryption for large-scale data encryption   
✅ Encrypt everything by default (EBS, RDS, S3, Lambda, etc.)   
❌ Don’t embed raw KMS keys in apps or scripts — use SDKs or integrated services

## Bespinians most used Ranking

✅ **IAM** for service to service access control (roles + policies)  
✅ **Identity Center** for user access control   
✅ **KMS** for data encryption   
✅ **Cognito** on custom apps as IDP    
✅ **WAF** + **Shield** for public facing apps to defend against web-exploits and attacks   
✅ **SCP's** with AWS **Organization** for complex Landing Zone service and region Access controls   
✅ **Security Hub** for cross Account security management in a landing zone   
✅ **Cloud Trail** for Audit on Cloud Logins & Actions (single account + cross account on landing zone)

**Now go back up to the start of lab <ins>03. Identity, Access and Security</ins> and read the security best practises again**