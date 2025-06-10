# 9. DevOps in and to AWS

## Content

- Githooks and pipelines into AWS
- Localstack
- Quick Intro to Terraform
- The following services will be explained and focused on:
    - AppConfig
    - CDK & CloudFormation
    - CloudWatch
    - CodeArtifact
    - CodeBuild
    - CodeCommit
    - CodeDeploy
    - CodePipeline
    - FIS
    - Grafana
    - Prometheus
    - Secrets Manager
    - Service Catalog
    - Systems Manager
    - X-Ray

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## Amazon CloudWatch

**Amazon CloudWatch** is AWS’s observability service that provides **logging**, **metrics**, **dashboards**, and **alarms** for monitoring applications, infrastructure, and services.

It’s the default tool for tracking the health and performance of nearly everything in AWS.

### 📘 Terminology

| Term            | Meaning                                                                          |
|------------------|----------------------------------------------------------------------------------|
| **Log Group**     | Container for logs from one or more sources (e.g., Lambda, ECS)                 |
| **Log Stream**    | Time-ordered sequence of log events (typically 1 per instance/container)        |
| **Metric**        | A time-series value like CPU %, error count, or latency                        |
| **Dimension**     | Metadata that identifies a metric (e.g., `FunctionName`, `InstanceId`)          |
| **Alarm**         | A condition on a metric that triggers actions (e.g., email, autoscaling)        |
| **Dashboard**     | A custom panel to visualize logs/metrics/alarms                                 |
| **Insight**       | Log query language for aggregations and filtering                               |

### Key Features

- 📊 **Metrics monitoring** from all AWS services and custom apps
- 📝 **Centralized logging** from Lambda, ECS, EC2, API Gateway, etc.
- 🚨 **Alarms & notifications** via SNS, Slack, PagerDuty, etc.
- 📈 **Dashboards** to visualize logs, metrics, and alarms
- 🔍 **Log Insights** — query logs with a SQL-like syntax
- 💡 Native integration with X-Ray, Lambda, ECS, S3, and more

### 🔍 Logging vs Monitoring

| Logging                          | Monitoring                          |
|----------------------------------|--------------------------------------|
| Raw, unstructured or semi-structured data | Structured, numeric time-series data |
| Use case: debug & trace          | Use case: alert & visualize          |
| Examples: error logs, API input  | Examples: error rate, invocations/s  |

> ✅ Logs show **what happened**, metrics show **how often**.

### 🪵 Logs & Log Groups

- Logs are automatically sent from:
  - Lambda, ECS, EC2 (via agent), API Gateway, Load Balancer, etc.
- Log Group: `/aws/lambda/my-function-name`
- Log retention is **configurable** (default: never expires — be careful with costs!)
- Logs can be **searched, filtered, exported to S3**, or fed into Insights

### 🧠 Insights (Log Insights)

Use Log Insights for real-time investigation and log analytics:

Example query:
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```
Supports:
- Aggregation
- Time bucketing
- Field extraction (from JSON logs)

### 📏 Metrics & Dimensions
- Metrics are emitted **automatically** or via `PutMetricData` API
- Every metric has:
    - A **namespace** (e.g., `AWS/Lambda`)
    - One or more **dimensions** (e.g., `FunctionName`)
    - A **unit** (Count, Seconds, Bytes, etc.)

Examples:
- `Invocations`
- `Duration`
- `Errors`
- `Throttles`

> ✅ You can **publish your own metrics** from apps via the SDK

### 📊 Dashboard
Create custom dashboards to visualize:
- Metrics from Lambda, EC2, API Gateway
- Alarms and statuses
- Custom metrics and logs

Supports:
- Multiple widgets per dashboard
- Period auto-refresh
- Cross-service views

### 🧪 Filters
- Log filters let you define patterns to extract or match log lines
- Used in metric filters (to turn logs into metrics) and alarms
- Example pattern:
```text
?ERROR ?Exception
```
- Example filter in JSON:
```json
{ $.status = 500 }
```

### 🚨 Alarms
- Create alarms on:
    - Any CloudWatch metric (including custom)
    - Log-based metric filters
- Trigger:
    - SNS Topics
    - Auto Scaling
    - Lambda
    - EC2 actions
- You can set:
    - Static or anomaly-based thresholds
    - Evaluation periods
    - Notification targets

✅ Now when the Lambda is invoked and fails, the alarm will fire and send you an email

### Best Practices
✅ Set log **retention periods** — don’t leave them at “forever”   
✅ Use **structured JSON logs** for better Insights queries   
✅ Convert high-value logs into metrics using **metric filters**   
✅ Use **dashboards** for teams/ops visibility   
✅ Set up **alarms** for critical thresholds, not every fluctuation   
❌ Don’t log sensitive data (PII) — CloudWatch logs are not encrypted by default beyond KMS-at-rest   

## Grafana & Prometheus

**Grafana** and **Prometheus** are popular open-source tools for **metrics visualization** and **monitoring** — and they integrate deeply with AWS through **Amazon Managed Grafana** and **Amazon Managed Prometheus**.

They are especially powerful for teams that already use open-source observability stacks, run Kubernetes, or need **custom dashboards across multiple clouds or clusters**.

### Key Features

#### 📊 Amazon Managed Grafana

- Managed version of the **Grafana dashboard platform**
- Pre-integrated with:
  - CloudWatch
  - Prometheus (self-managed or Amazon Managed)
  - X-Ray, Redshift, IoT, Athena, and more
- Supports **advanced visualizations** and alerts
- Multi-source dashboards across AWS + third-party tools (e.g., Datadog, Elasticsearch, InfluxDB)

#### 📈 Amazon Managed Prometheus

- Fully managed **Prometheus-compatible metrics service**
- Scalable, high-availability backend for Prometheus metrics
- Pulls metrics from:
  - EKS (via Prometheus exporters)
  - EC2 instances
  - Custom applications
- Stores **time-series metrics** and exposes them for Grafana dashboards

> 🧠 Prometheus stores + queries the metrics; Grafana visualizes them.

### 🔄 Ecosystem: Grafana + Prometheus + CloudWatch

Together, they form a **flexible observability stack**:

| Component           | Role                                              |
|----------------------|---------------------------------------------------|
| **Prometheus**        | Collects + stores custom metrics (e.g., app latency, container stats) |
| **CloudWatch**        | AWS-native metrics + logs                        |
| **Grafana**           | Unified dashboards, alerting, and analysis       |

#### 🔌 Integration Flow Example

- Your app exposes metrics at `/metrics` (via a Prometheus exporter like `node_exporter`)
- Amazon Managed Prometheus scrapes this endpoint and stores the time-series
- Grafana connects to both:
  - **Prometheus** → app metrics
  - **CloudWatch** → AWS metrics
- You build dashboards that correlate EC2 CPU usage (from CloudWatch) with app latency (from Prometheus)

### Best Practices

✅ Use **CloudWatch** for AWS-native metrics (Lambda, EC2, ALB, etc.)  
✅ Use **Prometheus** when you:
  - Need fine-grained application or container metrics
  - Use Kubernetes/EKS  
✅ Use **Grafana** as a unified view across AWS and open-source data  
✅ Manage access via **IAM Identity Center (SSO)** or **SAML**  
✅ Set **retention periods and alerting rules** carefully — Prometheus scales fast  
❌ Don’t store logs in Prometheus — it’s for metrics only

## Infrastructure as Code (IaC)

IaC lets you manage your AWS resources using code — bringing version control, automation, repeatability, and reduced human error to your infrastructure setup.

AWS provides **CloudFormation** and **CDK** natively. Many teams also prefer **Terraform** for its flexibility, ecosystem, and multi-cloud capabilities.

### 🧱 CloudFormation & CDK

#### Key Features

**CloudFormation (CFN)**:
- Native IaC tool from AWS
- YAML or JSON-based
- Declarative (you describe *what* you want, not *how*)
- Handles ordering, dependencies, and rollback automatically
- Integrated with IAM, CloudWatch, and every AWS service
- Supports **Change Sets** and **StackSets**

**AWS CDK (Cloud Development Kit)**:
- Abstraction layer on top of CloudFormation
- Write IaC in Python, TypeScript, Java, C#, or Go
- Synthesizes to CloudFormation templates behind the scenes
- Reusable, testable, parameterized infrastructure "constructs"
- Allows for many functionalities that CFN misses (like the possiblity to loop resource creation instead of defining same resource over and over again -> Code Duplication)

> ✅ CDK = CloudFormation, but with code and logic  
> ❌ But you’re still bound to CloudFormation's limits (slow deploys, YAML output)

#### Hands-On: Deploying S3 with CloudFormation (Vanilla)

> Create a simple S3 bucket using raw YAML and deploy via the AWS Console or CLI

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Create a basic S3 bucket

Resources:
  MyS3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: my-training-bucket-demo
```
Deploy via AWS Console or with:
```bash
aws cloudformation deploy \ --template-file s3.yaml \ --stack-name simple-s3-demo
```
✅ Result: A working S3 bucket defined in code   

### 🌍 Terraform
**Key Features**
- Developed by HashiCorp (open-source + commercial)
- Declarative and **provider-based** (supports AWS, Azure, GCP, etc.)
- Written in **HCL** (HashiCorp Configuration Language)
- Large ecosystem of **modules, plugins, and community support**
- State file keeps track of real-world vs declared resources
- Flexible remote backends (e.g., S3 + DynamoDB for state locking)
- Supports **plan / apply** lifecycle

> ✅ Terraform works well in **multi-cloud, modular, DevOps-heavy environments**

### 🥊 Terraform vs AWS Native Stack (CFN/CDK)

| Feature / Concern        | CloudFormation          | CDK                      | Terraform                   |
| ------------------------ | ----------------------- | ------------------------ | --------------------------- |
| Language                 | YAML/JSON               | TypeScript, Python, etc. | HCL                         |
| Learning curve           | Medium                  | Easy (for devs)          | Easy (for DevOps)           |
| Ecosystem                | AWS-only                | AWS-only                 | Multi-cloud                 |
| Speed of feedback        | ❌ Slow deploys          | ❌ Slow (still CFN)       | ✅ Faster plan/apply         |
| Reusability / Modularity | ❌ Limited               | ✅ Constructs             | ✅ Modules + registry        |
| Tooling / Editor support | Limited                 | ✅ Strong (modern langs)  | ✅ Excellent                 |
| Community & Resources    | AWS docs                | Growing community        | ✅ Massive ecosystem         |
| Best for…                | Cloud-native-only infra | Dev teams close to AWS   | ✅ Multi-cloud, mature CI/CD |
| Lock-in                  | High                    | High                     | ✅ Lower                     |

### 💬 Honest Take
- **CloudFormation is stable**, predictable, but **painfully verbose** and slow. Best if you’re in full AWS-native environments and want 100% support with no third-party tools. But in general it's made for machine understanding and code generation, <ins>**not for humans to write it**!</ins>
- **CDK is great for developers** and made for humans, but harder for ops engineers and DevOps pipelines. You write code, but you still suffer from **slow CloudFormation updates** underneath. Also, its abstractions can **get in your way** as projects scale.
- Terraform is usually preferred by:
    - DevOps teams
    - CI/CD-heavy workflows
    - Teams using multiple clouds or external services

> 🔥 CDK is shiny, but Terraform is the <ins>**swiss standard**</ins>, **battle-tested** and **scales better** across teams, clouds, and environments.

### Best Practices
✅ Use **version control** for all infrastructure   
✅ Use **modules** (TF) or **constructs** (CDK) to reuse components   
✅ Enable **change reviews** using Terraform Plan or CloudFormation Change Sets   
✅ Store state securely (e.g., S3 + DynamoDB for TF)   
✅ Avoid “drift” — check actual state regularly   
✅ Terraform is the **swiss standard**, so use Terraform in most cases!

## CodeCommit

**AWS CodeCommit** is a fully managed **Git repository service** hosted in AWS. It provides private, secure source control that integrates tightly with other AWS services (IAM, CodeBuild, CodePipeline, etc.).

### Key Features

- ✅ Fully managed **Git-compatible** repositories
- 🔐 Integrated with **IAM for fine-grained access control**
- 💾 Stores any file type, supports large repositories
- 🔄 Supports **branching, merging, pull requests**
- 📡 Accessible via HTTPS or SSH
- 🔒 Encrypted at rest and in transit (KMS + TLS)
- 📈 Supports **triggers** (Lambda, SNS, SQS) on push/merge

### 🤔 CodeCommit vs GitHub / GitLab

| Feature                      | CodeCommit                    | GitHub / GitLab              |
|-----------------------------|-------------------------------|-------------------------------|
| Hosting                     | AWS-native                    | External (GitHub, SaaS/Self-hosted) |
| IAM integration             | ✅ Yes (native)               | ❌ No (requires PATs or SAML) |
| UI/UX & community           | ❌ Minimal                    | ✅ Excellent                  |
| Webhooks & CI/CD hooks      | SNS, Lambda, CodePipeline     | Webhooks, GitHub Actions, CI |
| Ideal for                   | Regulated, AWS-secure workloads | Open source, external collaboration |
| Multi-region replication    | ❌ Not built-in               | ❌ Not common either          |

> ✅ Use CodeCommit when:
> - You need **tight security with IAM**
> - You want everything in AWS (no third-party vendors)
> ❌ Avoid it for:
> - Public projects
> - Developer experience (GitHub UI is far superior)

### Hands-On: Repository Prep for Later Pipeline

> Goal: Create a CodeCommit repository with a sample app ready for CI/CD use in CodeBuild or CodePipeline.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Create the Repo
3. Clone and Initialize
```bash
git clone https://git-codecommit.<region>.amazonaws.com/v1/repos/my-training-repo
cd my-training-repo
```
4. Add Sample Files
```bash
echo "Hello from AWS CodeCommit!" > index.html
echo 'version: 0.2\nphases:\n  build:\n    commands:\n      - echo "Building..."' > buildspec.yml
```
5. Commit and push
```bash
git add .
git commit -m "Initial commit for training"
git push origin main
```
✅ Now your CodeCommit repo is ready for use with CodeBuild, CodePipeline, or manual deployments.

### Best Practices
✅ Use **branch protection** and **pull request workflows**
✅ Integrate with **CloudWatch Events** or **SNS** for repo triggers
✅ Use **encrypted connections (HTTPS/SSH)** with IAM auth
✅ Set **repository policies** to restrict push/merge actions
❌ Don’t use for public repos — there’s no public repo hosting

## AWS CodeBuild

**AWS CodeBuild** is a fully managed **build service** that compiles source code, runs tests, and produces deployable artifacts — without managing any build servers.

It works inside CodePipeline or standalone, and supports a wide range of languages and environments via prebuilt or custom Docker images.

### 🛡️ Key Features

- 🧪 **Fully serverless** — no need to provision CI runners or agents
- 📦 Supports builds for:
  - Java, Python, Node.js, Go, .NET, Ruby, Docker, and more
- 🧾 Uses a `buildspec.yml` to define steps (similar to GitHub Actions or GitLab CI)
- 🔁 Integrated with:
  - CodeCommit, GitHub, Bitbucket
  - S3 (for artifacts), ECR, CodePipeline
- 🔐 IAM-based permissions per project
- 🧱 Can run custom builds in your own **Docker containers**
- 🔄 Supports **parallel and batch builds**
- 📈 Emits logs and metrics to **CloudWatch**
- 💵 Pay per minute of actual build time

### 🧾 Example buildspec.yml

```yaml
version: 0.2

phases:
  install:
    commands:
      - echo Installing dependencies...
  build:
    commands:
      - echo Building the app...
      - npm run build
artifacts:
  files:
    - '**/*'
```
### 💡 Common Use Cases
| Use Case                      | Why Use CodeBuild?                    |
| ----------------------------- | ------------------------------------- |
| Compile and test code         | Fully managed CI, no Jenkins needed   |
| Build Docker images           | Push to ECR from CodeBuild            |
| Run linting, unit tests       | Simple to integrate with CodePipeline |
| Generate artifacts for deploy | Archive and pass to S3 or CodeDeploy  |

### Best Practices
✅ Use **small, fast containers** to save build time   
✅ Set **timeout limits** to avoid long-running builds   
✅ Store and version your **buildspec.yml** alongside code   
✅ Push **logs and metrics to CloudWatch** for diagnostics   
✅ Use **environment variables** (via SSM or Secrets Manager) for secrets   
❌ Don’t hardcode credentials or tokens — use IAM roles

## AWS CodeDeploy

**AWS CodeDeploy** is a fully managed **deployment automation service** that helps you deploy application changes to:

- EC2 instances
- On-premise servers
- Lambda functions
- ECS services (blue/green deployments)

It's designed to reduce downtime and make updates predictable, auditable, and automated — but it often comes with **extra setup complexity**.

### Key Features

- 🔁 **Supports in-place and blue/green deployments**
  - EC2 & on-prem: can stop/start services, replace files, run hooks
  - Lambda: traffic shifting between versions/aliases
- 🔄 Rollback on failure
- 📜 **AppSpec file** defines lifecycle hooks (BeforeInstall, AfterInstall, etc.)
- 🧩 Integrates with:
  - EC2 Auto Scaling
  - CodePipeline
  - S3 (for artifacts)
  - GitHub / CodeCommit (for triggers)
- 📊 Detailed deployment status via CloudWatch & Events
- 🔐 IAM-controlled deployments and instance roles

### 📜 Example appspec.yml (for EC2)

```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
hooks:
  AfterInstall:
    - location: scripts/configure.sh
      timeout: 180
      runas: ec2-user
```

### 💡 When to Use CodeDeploy
| Scenario                        | CodeDeploy Fit?    | Why                                       |
| ------------------------------- | ------------------ | ----------------------------------------- |
| Deploying to EC2 Auto Scaling   | ✅ Yes              | Hook into instance lifecycle              |
| Gradual rollout to Lambda       | ✅ Yes              | Built-in version traffic shifting         |
| On-prem deployments             | ✅ Yes              | Works with hybrid cloud or edge use cases |
| Deploying container apps on ECS | ✅ (for blue/green) | Only necessary for traffic shifting       |
| Simple S3 → Lambda deploys      | ❌ Overkill         | Use CodePipeline + Lambda                 |

### ⚠️ Things to Watch Out For
- AppSpec files must be accurate — small errors break deployments
- In-place deployments can cause **downtime if not coordinated**
- For containers, **ECS handles most of this natively now**
- Not needed if you're using **serverless-only pipelines** (e.g., Lambda + S3 + CloudFormation)

###  Best Practices
✅ Use **blue/green** for high-availability workloads   
✅ Monitor all deployments via **CloudWatch and Events**   
✅ Store `appspec.yml` with your app code for version control   
✅ Use **lifecycle hooks** to validate, backup, or preconfigure during deployment   
✅ Combine with **CodePipeline** for fully automated CI/CD   
❌ Don’t use in-place updates without validation or backups   

## AWS CodeArtifact

**AWS CodeArtifact** is a fully managed **artifact repository** for software packages. It lets you **store, share, and version** packages across teams — similar to npm, PyPI, Maven Central, or NuGet — but private and within your AWS account.

It's ideal for teams that want to host **internal libraries**, cache dependencies, or enforce vetted package usage.

### Key Features

- 📦 Supports multiple package formats:
  - npm (JavaScript/Node.js)
  - PyPI (Python)
  - Maven (Java)
  - NuGet (.NET)
- 🔁 Acts as a **proxy/cache** for public registries
- 🔐 Integrated with:
  - **IAM authentication**
  - **STS tokens**
  - **CodeBuild** and **CodePipeline**
- 📁 Scoped by **domain → repository → package**
- 🔄 Can automatically **fetch missing packages** from upstream (e.g., npmjs.org)
- 🧪 Versioning, dependency resolution, and retention policies supported

### 🧰 Example Use Cases

| Use Case                                  | Why CodeArtifact Helps                      |
|-------------------------------------------|----------------------------------------------|
| Internal shared libraries                 | Controlled versioning + security             |
| Cache public packages for CI/CD builds    | Faster and more reliable builds              |
| Control package versions                  | Prevent risky upgrades from upstream         |
| Use private packages with CodeBuild       | No need for secrets — IAM-based access       |

### 📥 How to Authenticate

1. Use AWS CLI to get a token:
```bash
aws codeartifact login \
  --tool npm \
  --repository my-repo \
  --domain my-domain
```
2. Then use `npm install`, `pip install`, etc. — CodeArtifact acts like a registry.
> ✅ Works with CodeBuild out of the box — no need for custom credential management.

###  Best Practices
✅ Use **IAM roles + STS tokens** for secure auth (no long-lived API keys)   
✅ Set up **upstream repositories** to cache public packages safely   
✅ Apply **package retention policies** to limit storage cost   
✅ Use **domains** to group by team or environment   
❌ Don’t hardcode repository URLs or tokens — use `codeartifact login` scripts

## AWS Systems Manager

**AWS Systems Manager (SSM)** is a suite of tools that helps you **manage, patch, automate, and operate** your AWS infrastructure — especially EC2 instances, hybrid environments, and configurations.

It acts as a **central control plane** for system operations across AWS, without needing direct SSH access.

### Key Features

#### 🖥️ Session Manager
- Secure shell access to EC2 **without SSH keys or open ports**
- Logs every session to **CloudTrail** or **S3**
- IAM-controlled access
- Supports **port forwarding** and tunneling

#### 🛠️ Run Command
- Remotely execute shell or PowerShell commands on instances
- No need to log in — just run commands via console or CLI

#### 🧩 State Manager
- Enforce **desired state** (e.g., install packages, manage users)
- Useful for compliance, baseline config, patching

#### 📦 Patch Manager
- Automates OS patching across fleets (Linux/Windows)
- Define patch baselines and maintenance windows

#### 🧰 Parameter Store
- Key-value config storage (secure + plaintext)
- Often used for app configs, feature flags, env vars
- Supports encryption with KMS

#### 📋 Inventory
- Tracks installed software, patch state, instance details
- Useful for CMDB-like reporting

#### 📁 Automation
- Create automation documents (SSM Documents) to run multi-step workflows:
  - Snapshot + patch + restart
  - Backup + deploy
  - Auto-remediation

### 🛠️ Example Use Cases

| Use Case                          | Tools Used                       |
|----------------------------------|-----------------------------------|
| Access EC2 without SSH            | Session Manager                   |
| Run update on 50 servers          | Run Command                       |
| Store app configs (e.g., `/env/`) | Parameter Store                   |
| Enforce antivirus installation    | State Manager                     |
| Auto-patch on Sundays             | Patch Manager + Maintenance Window|

### Best Practices

✅ Use **Session Manager** to eliminate SSH entirely  
✅ Use **Parameter Store** for app configs (or Secrets Manager for sensitive data)  
✅ Enforce config via **State Manager** for compliance  
✅ Schedule **Patch Manager** with **Maintenance Windows**  
✅ Tag resources to group and manage them logically  
❌ Don’t mix up Parameter Store and Secrets Manager — use each for what it’s best at

## AWS Secrets Manager

**AWS Secrets Manager** is a fully managed service that helps you **store, rotate, and retrieve secrets** like:

- Database credentials  
- API keys  
- OAuth tokens  
- Third-party service credentials

It allows secure, auditable access from apps and AWS services — without storing secrets in plain text in your code or config files.

### Key Features

- 🔐 **Secure, encrypted secret storage**
  - All secrets are encrypted with **KMS**
- 🔁 **Automatic rotation** of secrets (optional)
  - Supports built-in integrations for RDS, Aurora, Redshift
- 🔑 **Fine-grained IAM access control**
  - Control *who* can retrieve *which* secret
- 📦 **Versioning and staging labels**
  - Track current, previous, and pending versions
- 📈 **Audit logs** via CloudTrail
- 🧩 Integrates with:
  - Lambda, EC2, ECS, RDS, CodeBuild, Terraform, etc.
  - SDKs for all major languages

### 💬 Example Use Case: DB Credentials

1. Store credentials in Secrets Manager
2. Grant your Lambda/EC2/CodeBuild access to the secret via IAM
3. App retrieves credentials securely using AWS SDK

```python
import boto3

client = boto3.client('secretsmanager')
secret = client.get_secret_value(SecretId='prod/db-credentials')
```
> ✅ Secrets are **never hardcoded**, and can be **rotated without changing code**

### 🔄 Secret Rotation
- Supports automatic rotation using Lambda
- Works out-of-the-box with:
    - RDS (MySQL, PostgreSQL, MariaDB)
    - Redshift
- You can write a **custom rotation Lambda** for other systems
- Uses staging labels: `AWSCURRENT`, `AWSPENDING`, etc.

### 🔐 vs. Parameter Store

| Feature             | Secrets Manager          | SSM Parameter Store     |
| ------------------- | ------------------------ | ----------------------- |
| Secret rotation     | ✅ Yes                    | ❌ No                    |
| Audit logging       | ✅ Yes                    | ✅ Yes                   |
| Native secret types | ✅ Yes (JSON blobs)       | ✅ Yes                   |
| Cost                | 💰 Paid (\~\$0.40/month) | ✅ Free tier available   |
| Use case            | Secrets & credentials    | Config params, env vars |


### Best Practices
✅ Store secrets **outside of code**   
✅ Use **least-privilege IAM** for accessing secrets   
✅ Enable **automatic rotation** where supported   
✅ Use **KMS key policies** to restrict who can decrypt secrets   
✅ Set up **alerts via CloudTrail** or EventBridge for access anomalies   
❌ Don’t log secrets or pass them unencrypted between services   

## AWS CodePipeline

**AWS CodePipeline** is a fully managed **CI/CD orchestration service**. It automates build, test, and deployment steps whenever code changes, so you can release software faster and more reliably.

It connects various tools and services into a **visualized pipeline** of sequential or parallel stages.

### 🛡️ Key Features

- 🔁 Automates **source → build → deploy** flows
- 🔧 Native integrations with:
  - CodeCommit, GitHub, S3 (source)
  - CodeBuild (build)
  - CodeDeploy, Lambda, ECS, CloudFormation (deploy)
- 💥 Triggers on code push or webhook
- 🧩 Custom stages via Lambda or manual approval
- 🕓 Real-time pipeline execution + monitoring
- 🔐 IAM role per stage for least privilege

### 🧱 Pipeline Design in AWS

A real AWS pipeline uses a **combination of services**, depending on your architecture:

#### 🧬 Typical Flow

```text
[ Source (GitHub/CodeCommit) ]
        ↓
[ Build (CodeBuild) ]
        ↓
[ Deploy (Lambda, ECS, CF, CDK, Terraform) ]
        ↓
[ Post-deploy (Tests, Notifications, Dashboards) ]
```

#### 📦 Common Services in Pipeline
| Tool                     | Role in Pipeline                                | When to Use / Avoid                                      |
| ------------------------ | ----------------------------------------------- | -------------------------------------------------------- |
| **CodeBuild**            | Compile, test, bundle artifacts                 | ✅ Always needed if build or test is involved             |
| **CodeDeploy**           | EC2, Lambda, or ECS deployments (with rollback) | ✅ Use for EC2/ECS blue/green, ❌ Skip for basic S3/Lambda |
| **Secrets Manager**      | Securely inject secrets in CodeBuild or Lambda  | ✅ Needed if using tokens, passwords, keys                |
| **ECR**                  | Stores Docker images for ECS/Fargate            | ✅ For container-based apps                               |
| **CloudFormation / CDK** | Infrastructure deployment via IaC               | ✅ Use for IaC projects, but **slow** in pipeline         |
| **Terraform**            | IaC via CodeBuild custom stage                  | ✅ Great if you manage infra outside of CFN               |
> 💡 You can run Terraform inside a CodeBuild stage, as it’s not natively supported like CFN/CDK.

### Hands-On: My First Complete Pipeline & Monitoring
> Goal: Push Python Lambda with Powertools → Build & Deploy → Track “Star Wars” mentions → Visualize on a CloudWatch dashboard

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Create a repo with and push a function code to it that
    - Counts with powertools "Star Wars" in the event text
    - Publishes a custom metric
3. Create the buildspec that installs the python packages properly as lambda layer
4. Create the Pipeline with the CodeCommit as source, the buildstage on the buildspec and on the deploy stage a CloudFormation that creates the Lambda function
5. Push the lambda code into the repository and it should be deployed now
6. Now run the lambda multiple times
7.  Create a CloudWatch Dashboard:
    - Add a widget for `Custom/Lambda/StarWarsMentions` or however your metric was named
    - Set it to display latest invocation metric in real time

### ✅ Result
Now, every push to your repo:
- Builds the Lambda
- Deploys it automatically
- Runs and emits metrics
- Updates a CloudWatch dashboard

### Best Practices
✅ Separate **dev, test, prod** pipelines with environment variables   
✅ Use **IAM roles per stage** with scoped permissions   
✅ Store build artifacts in S3 or deploy to Lambda Layers   
✅ Integrate with **manual approval stages** for prod   
✅ Use **CloudWatch Logs + Events** for pipeline alerts   
❌ Don’t hardcode config — use Parameter Store or Secrets Manager   

## Git Hooks from Outside

Many teams already host their code on **GitHub** or **GitLab**, but still want to **trigger deployments or CI/CD pipelines inside AWS**. The most common way to do this is through **webhooks** — HTTP POST calls sent to AWS when something happens (e.g., code pushed, pull request merged).

### 🐙 GitHub Webhooks

GitHub supports **repository webhooks** to notify AWS services:

- Events supported:
  - `push`, `pull_request`, `release`, etc.
- Can send to:
  - API Gateway → Lambda
  - CodePipeline (via custom webhook URL)
  - EventBridge (via GitHub → API Gateway bridge)

#### Native Integration with CodePipeline

If you're using CodePipeline:
- ✅ GitHub (and GitHub Enterprise Cloud) is supported **natively**
- OAuth token required for connection
- Triggers on **commit to specific branch**

> Best for small, straightforward CI/CD pipelines hosted in GitHub

### 🦊 GitLab Webhooks

GitLab (SaaS or self-hosted) also supports outbound webhooks:

- Triggered on:
  - Pushes, tags, merges, pipeline events
- Can call:
  - Lambda (via API Gateway)
  - Step Functions
  - SQS for decoupling
- No native AWS integration — must set up manually via API Gateway or EventBridge proxy

> GitLab is powerful, but less natively integrated — expect more wiring.

### Hands-On: GitHub Push Triggers AWS Pipeline

> Goal: Push to a GitHub repo → trigger an AWS CodePipeline

1. Create a Pipeline (no source yet)
2. Use the AWS Console, Terraform or CLI to create a basic CodePipeline with:
    - Build + Deploy stages
    - **No source configured yet**
3. Create a Custom Webhook
```bash
aws codepipeline create-webhook \
  --name github-webhook \
  --target-pipeline my-training-pipeline \
  --target-action mySource \
  --filters '[{"jsonPath":"$.ref", "matchEquals":"refs/heads/main"}]' \
  --authentication GITHUB_HMAC \
  --authentication-configuration SecretToken=<your-token>
```
4. Save the returned webhook URL.
5. Add a Webhook to GitHub
Go to your GitHub repo:
- Settings → Webhooks → Add webhook
- Payload URL: `https://...` (from AWS CLI output)
- Content type: `application/json`
- Secret: same as `SecretToken`
- Events: select `push`
- Save

✅ Result: Every push to main triggers your AWS pipeline.   

### Best Practices
✅ Use **HMAC secrets** to verify webhook authenticity   
✅ Route webhooks through **API Gateway + Lambda** if validation/custom logic needed   
✅ Use **SQS or EventBridge** Pipes to decouple triggers from execution   
✅ For GitHub, prefer native integration unless you need full control   
❌ Don’t expose webhooks publicly without verification — they can be abused

## AWS AppConfig

**AWS AppConfig** is a managed service for **application configuration management** and **feature flag rollouts**. It’s part of AWS Systems Manager and helps you deploy configuration changes **safely and gradually**, without redeploying your code.

Think of it like a control plane for runtime application behavior.

### Key Features

- 🧩 Deploy **runtime configuration data** independently of code
- ⚙️ Designed for **feature flags**, tuning parameters, and dynamic settings
- 🔐 Validates config before rollout (JSON schema, Lambda validators)
- 🧪 Supports **canary deployments**, **linear rollouts**, or full rollout
- 📊 Built-in monitoring with CloudWatch alarms
- 🧵 Integrated with:
  - Lambda
  - ECS/Fargate
  - EC2
  - Mobile/web apps (via SDK or API)
- 💥 Abort and rollback if metrics indicate problems

### 🧰 Example Use Cases

- Toggle features on/off in production
- Gradually roll out a new UI layout
- Change application behavior (limits, thresholds) without redeploying
- Emergency disablement ("kill switches")

### 🗂️ How It Works

1. **Create an App** (logical grouping)
2. **Create an Environment** (dev, prod, etc.)
3. **Define a Configuration Profile**
   - Can source config from:
     - SSM Parameter Store
     - Secrets Manager
     - S3
     - Inline JSON
4. **Deploy the Configuration**
   - With validation (optional)
   - With controlled rollout strategy
   - With monitoring & rollback options

### Best Practices

✅ Use **schemas and validators** to avoid broken rollouts  
✅ Store **runtime configs**, not secrets (use Secrets Manager for credentials)  
✅ Monitor rollout health with **CloudWatch alarms**  
✅ Use **feature flags** to separate deployment from release  
❌ Don’t use AppConfig as a general-purpose config store — it’s for **controlled runtime flags**   

## AWS Fault Injection Simulator (FIS)

**AWS Fault Injection Simulator (FIS)** is a managed **chaos engineering service** that lets you safely test how your workloads respond to faults, like instance terminations, latency injection, API throttling, or network isolation.

It helps improve **resilience, fault tolerance, and observability** — especially in production-like environments.

### Key Features

- 💥 Simulates real-world failures:
  - Stop/terminate EC2 instances
  - Kill ECS tasks
  - Introduce CPU/network stress
  - Inject latency or packet loss in VPC
  - Throttle SSM, DynamoDB, or API Gateway
- ⚙️ Controlled **scoped experiments** with rollback support
- 🧪 Define actions + targets using:
  - Resource tags
  - Auto Scaling groups
  - SSM integrations
- 🧩 Integrates with:
  - CloudWatch (for alarms)
  - EventBridge (for alerts)
  - Systems Manager (to run commands pre/post fault)
- 🧠 Common use cases:
  - Test if auto-scaling kicks in
  - Validate retry logic
  - Observe monitoring system reactions

### 🧬 How FIS Integrates with CI/CD Pipelines

While FIS is often used in **pre-prod or staging**, you can integrate it into **post-deployment phases** of a CI/CD pipeline to test if resilience mechanisms are in place.

#### Example CI/CD Flow:

```text
[ Build & Deploy ] → [ Smoke Tests ] → [ Chaos Experiment (FIS) ] → [ Verify Observability ]
```
- ✅ After deploying an app via **CodePipeline**, run an **FIS experiment** to:
    - Kill one EC2 instance
    - Drop packets between two subnets
- ✅ Then validate that:
    - Auto Scaling replaced the instance
    - The service stayed available
    - Alarms fired and recovered

#### Integration Points:
- Trigger FIS experiment from a CodeBuild step using CLI:
```bash
aws fis start-experiment --experiment-template-id <template-id>
```
- Use **CloudWatch alarms** to auto-abort the experiment if impact exceeds tolerance
- Add a **manual approval** stage after the chaos test if needed

## AWS Service Catalog

**AWS Service Catalog** lets administrators create and manage **approved collections of resources** that teams can deploy in a self-service, controlled way.

It’s especially useful in **enterprise environments** where teams need to use vetted infrastructure (with security, cost, and compliance baked in) — but still want autonomy in launching services.

### Key Features

- 🧱 Define **products** (CloudFormation stacks) with optional parameters
- 🗂 Group products into **portfolios**
- 🔐 Use **IAM and SSO permissions** to control who can launch what
- 🧩 Launch templates include:
  - EC2 with hardening
  - Pre-approved S3/Lambda setups
  - Full VPCs, network layouts, databases
- 🔁 Version control of products (rollback possible)
- ✅ Users can deploy from console or CLI — no YAML editing needed

> 🧠 Think: “Internal AWS Marketplace” for infrastructure blueprints

### 🗂️ App Registry

The **AppRegistry** within Service Catalog helps **group and track resources** by application — useful for **inventory, compliance, and governance**.

- Link CloudFormation stacks to logical **applications**
- Assign **owners, environments, business metadata**
- Useful for:
  - Tag-based automation
  - App-level reporting
  - Cross-team transparency

> 🔍 AppRegistry = **meta-layer for governance and org-wide reporting**

### Example Use Cases

| Use Case                                      | Why Service Catalog Helps                  |
|-----------------------------------------------|---------------------------------------------|
| Developers need secure base templates         | Admins publish hardened EC2/S3 templates    |
| Maintain versioned VPC/Lambda blueprints      | Controlled stack updates                    |
| Allow self-service, but avoid free-for-all    | IAM limits + pre-configured options         |
| Central ops team wants app-level visibility   | Use App Registry to map stacks to owners    |

### Best Practices

✅ Use **tagging and AppRegistry** for lifecycle and audit clarity  
✅ Keep **products up to date** (especially for networking/security baselines)  
✅ Define **clear naming and parameter rules**  
✅ Grant **least privilege access** to portfolios via IAM  
❌ Don’t use Service Catalog if your teams are small, flexible, or constantly iterating — it slows down rapid prototyping

## AWS X-Ray

**AWS X-Ray** is a **distributed tracing service** that helps you understand how your application is behaving end-to-end — across microservices, Lambda, APIs, and databases.

It collects traces from your application, shows latency bottlenecks, and lets you **pinpoint where requests fail, slow down, or branch**.

### Key Features

- 📍 Trace **individual requests** across services and infrastructure
- 🧠 Understand:
  - Latency breakdown (e.g., 100ms in Lambda, 200ms in RDS)
  - Service dependencies
  - Outliers and anomalies
- 🔄 Works with:
  - Lambda
  - API Gateway
  - EC2, ECS, and Fargate (with agents)
  - SDK-integrated apps (e.g., Python, Node.js)
- 📈 Visual **service maps**, trace timelines, and error rate views
- 🔌 Integrated with CloudWatch and CloudTrail

### 🔧 How to Integrate X-Ray into CI/CD

While **X-Ray isn’t part of the pipeline execution itself**, you enable tracing **during or after deployment** — so you can observe the behavior of new releases in real time.

#### In a typical pipeline:

```text
[ CodeCommit ] → [ CodeBuild ] → [ CodeDeploy / Lambda ] → [ X-Ray enabled application ]
```

**How to enable:**
- ✅ For **Lambda:** just toggle `Active tracing` in deployment config or CLI:

```bash
aws lambda update-function-configuration \
  --function-name myLambda \
  --tracing-config Mode=Active
```

- ✅ For **ECS/EC2 apps:**
    - Install the **X-Ray daemon or sidecar**
    - Export trace headers in requests
    - Use SDK to instrument app code
- ✅ During deploy via CodePipeline/CDK:
    - Add X-Ray flags in **CloudFormation/CDK constructs**
    - Or use `aws xray` CLI in a post-deploy CodeBuild step

> 💡 Use this to **auto-enable tracing** as part of your delivery process, and alert on spikes or failures post-deploy.

### ⚠️ Considerations — When to Use and When It’s Overkill
| Scenario                               | X-Ray Fit? | Why                                          |
| -------------------------------------- | ---------- | -------------------------------------------- |
| Microservice debugging                 | ✅ Yes      | Traces request paths across services         |
| Lambda-based async workflows           | ✅ Yes      | Shows cold start latency and downstream deps |
| Small monolith or low-traffic app      | ❌ No       | Logs + metrics are sufficient                |
| Real-time debugging with low tolerance | ✅ Yes      | Combine with alarms to catch regression fast |
| Just need uptime/error checks          | ❌ No       | CloudWatch alone will do                     |

### Best Practices
✅ Enable **Active tracing** for key functions/services only (don’t overdo it)   
✅ Use **sampling** rules to limit trace volume and cost   
✅ Add **metadata and annotations** for custom filtering   
✅ Monitor trace anomalies post-deploy — great for **canary analysis**   
✅ Combine with **CloudWatch Logs Insights** for full observability   
❌ Don’t treat X-Ray as a logging tool — it’s for performance tracing   

## Bespinians most used Ranking

✅ **CloudWWatch** for logs and basic monitoring   
✅ Full **CodePipeline** based on customers DevOps strategy   
✅ Full **CodBuild** even outside of the basic Pipeliine to build dependencies like automated **Lambda Layer** creation  
✅ **Systems Manager** for multiple of its functionalities    
✅ **Secrets Manager** to store secrets for CICD Pipelines and automated workflows   
✅ **X-Ray** if we really need tracing (rarely but then effectively)