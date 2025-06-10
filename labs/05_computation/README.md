# 5. Computation on AWS

## Content

- Instance Types and their use-cases
- Cold and Warm Start
- The following services will be explained and focused on:
    - Amplify 
    - App Runner 
    - Batch 
    - Beanstalk 
    - EBS 
    - EC2 
    - ECS 
    - ECR 
    - EFS 
    - EKS 
    - Fargate 
    - FSx 
    - Inspector 
    - Lambda 
    - Lightsail 
    - Step Function 
    - Storage Gateway 

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## Compute Instances

Before we dive into individual services like EC2 or Batch, it's important to understand **EC2 instance types**, how to **choose them**, and why **Auto Scaling** is often more efficient than just "going bigger."

### 🧬 Most Important Instance Families and Use-Cases

AWS offers dozens of instance types. You don’t need to memorize them, but you should know the **core families** and what they’re optimized for:

| Family | Purpose                           | Example Use Cases                       |
|--------|-----------------------------------|----------------------------------------|
| **t3/t4g** | General-purpose burstable       | Low-traffic web apps, dev/test         |
| **m5/m6g** | Balanced compute & memory       | Application servers, microservices     |
| **c5/c6g** | Compute-optimized               | CI/CD, data processing, game servers   |
| **r5/r6g** | Memory-optimized                | Databases, caching layers              |
| **g5/p4**  | GPU-accelerated                 | ML inference/training, video rendering |
| **i3/i4**  | Storage-optimized               | NoSQL DBs, data warehousing            |

✅ **Graviton (Arm-based)** variants (e.g., `t4g`, `m6g`, `c6g`) are cheaper and energy-efficient  
❌ Don’t overprovision — choose based on your **actual workload characteristics**

### 🎯 How to Choose the Right One

Ask these questions:

- **CPU-bound or memory-bound?**
  - Pick `c` for CPU-heavy, `r` for memory-heavy
- **Burst or constant usage?**
  - Pick `t` series for bursty traffic (cost-effective), or `m` for general workloads
- **Long-term vs short-term usage?**
  - Consider **spot instances** or **savings plans** (covered in just a moment)
- **Running containers or VMs?**
  - Match your ECS/EKS/Fargate design to instance types (if using EC2 launch type)

✅ Use **Cost Explorer** or **Compute Optimizer** to analyze and right-size instances  
✅ Start small, test under load, and adapt

### 🔁 Auto Scaling as a Concept

> “Don’t go big — go smart.”

Auto Scaling lets you adjust your infrastructure **dynamically** based on actual usage — up during spikes, down during idle times.

Instead of:
- ❌ Picking a giant `r5.8xlarge` instance to “handle all traffic just in case”

You can:
- ✅ Deploy 2–3 small `t3.medium` or `m5.large` instances
- ✅ Use **Auto Scaling groups** to add/remove capacity as needed
- ✅ Pay only for what you use

Benefits:
- 🧩 **Scalability** — app can handle unpredictable traffic
- 💸 **Cost-efficiency** — no idle overprovisioned resources
- 🛡️ **Redundancy** — traffic is spread across multiple AZs/instances

We'll explore how this works in detail with:
- EC2 (Auto Scaling Groups)
- ECS (Capacity Providers or Fargate)
- Lambda (autoscaling is built-in)

## ❄️ Cold Start vs Warm Start

When working with **serverless** or **on-demand containerized services**, you may experience **latency spikes** caused by how AWS spins up resources behind the scenes. This is known as a **cold start**.

### 🧊 What Is a Cold Start?

A **cold start** happens when AWS has to:
- **Launch a new execution environment** (e.g., Lambda container)
- **Pull the container image**
- **Initialize code/dependencies** before processing the request

This process adds **initial latency** — usually 100–1000ms, but it can be longer for:
- Large packages or dependencies
- VPC-attached functions
- Image-based Lambdas

### 🔥 What Is a Warm Start?

A **warm start** happens when AWS **reuses a previously initialized environment**, allowing your function or container to respond **much faster** — typically <50ms for Lambda.

### 📦 Services Affected by Cold Starts

| Service            | Cold Starts Possible? | Notes |
|--------------------|------------------------|-------|
| **AWS Lambda**      | ✅ Yes                 | Most commonly impacted, especially when idle |
| **App Runner**      | ✅ Yes                 | First request after idle triggers container boot |
| **Fargate**         | ✅ Yes (initial task startup) | No cold start on already-running tasks |
| **ECS/EKS**         | ❌ Only if scaling      | Once containers are running, no cold start |
| **EC2**             | ❌ No                  | Always "warm" after startup |
| **Beanstalk**       | ❌ Not typically       | Based on EC2, not serverless |
| **Lightsail**       | ❌ No                  | Long-lived instances |

### 🧩 How to Mitigate Cold Starts

| Technique                         | Applies To         | Benefit                             |
|----------------------------------|---------------------|-------------------------------------|
| **Provisioned Concurrency**       | Lambda              | Keeps environments warm at all times |
| **VPC-less functions**            | Lambda              | Reduces cold start delay            |
| **Keep-alive pings**             | App Runner, Lambda  | Keeps environments warm with traffic |
| **Small images + faster boot**   | App Runner, Fargate | Speeds up container init            |
| **Async invocation with retries** | Lambda              | Avoids cold start penalty on user path |

### 🔥 Rule of Thumb

- ✅ Cold starts **don’t matter** for background processing (e.g., nightly jobs, batch)
- ⚠️ Cold starts **can matter** for **user-facing APIs, chatbots, or real-time UIs**
- 🧪 Test latency for first request after 5–15 minutes of idle time

### 🤔 Architectural Considerations

| Scenario                            | Recommendation                                           |
|-------------------------------------|----------------------------------------------------------|
| **Interactive APIs** (chatbots, mobile apps) | Try out, often cold is enough but sometimes it needs **provisioned concurrency** or App Runner min instances |
| **Internal tools or admin APIs**    | Cold starts are acceptable                            |
| **Batch jobs or nightly processing**| Definitely Cold starts                             |
| **Synchronous event processing**    | Sometimes you want Pre-warm or queue events to handle latency spikes        |

#### 💰 Cost Considerations

| Technique                    | Cost Impact                                       |
|-----------------------------|---------------------------------------------------|
| **Cold start only (on-demand)** | 🟢 Cheapest (pay only when used)               |
| **Provisioned concurrency**  | 🔶 Higher cost — pay to keep instances warm     |
| **App Runner min instances** | 🟠 Fixed hourly cost — cheaper than provisioned Lambda |
| **Fargate / ECS**            | ⚖️ Pay per task or container uptime             |
| **EC2 / Beanstalk**          | 🔴 Always-on cost (charged 24/7 unless stopped) |

💡 Even **small amounts of warm capacity** (1–2 concurrent instances) can prevent 90%+ of cold starts while keeping cost predictable.   
✅ We still recommend true 0 scale serverless in most cases! Really just go with warming, if really needed!

### Best Practices

- 🔥 **Use provisioned concurrency** (Lambda) or **min instances** (App Runner) for **user-facing hihg-latency-sensitive apps**
- 💡 **Design stateless, fast-booting functions** (minimal init code, avoid heavy dependencies)
- 📦 **Keep container images small** (for Fargate/App Runner)
- 🧪 **Benchmark** cold vs warm latency under realistic conditions (5–15 min idle delays)
- 💬 Inform product teams about cold starts so they understand **what latency to expect**

## EC2 – Elastic Compute Cloud

Amazon EC2 gives you full control over virtual machines in AWS. It’s the most flexible compute option, but also requires the most configuration.

###  Key Features

- 🧱 Launch **virtual machines** with full OS-level access (Linux/Windows)
- 🔁 **Auto-Scaling** based on load or schedule
- 🧩 Integrates with:
  - EBS (block storage)
  - EFS (shared storage)
  - Load balancers (later topic)
- 🔐 Supports key pair authentication, IAM instance roles, and security groups
- 📈 Use **CloudWatch** to monitor CPU, disk, and memory usage

### ⚙️ Instance Types & Savings Plans

You can reduce EC2 cost dramatically by choosing the right **pricing model**:

#### 🧾 Instance Pricing Models

| Type         | Description                                         | When to Use                     |
|--------------|-----------------------------------------------------|----------------------------------|
| **On-Demand**| Pay by second; no commitment                        | Dev/test, variable workloads     |
| **Reserved** | 1 or 3-year term; cheaper if used constantly         | Always-on apps (e.g., self-hosted databases) |
| **Spot**     | Use unused AWS capacity; up to 90% off              | Batch jobs, fault-tolerant apps  |
| **Savings Plans** | Flexible commitments to reduce hourly rate     | Preferred over Reserved in most cases |

✅ **Graviton** instances (`t4g`, `m6g`, etc.) can reduce cost further (ARM-based CPUs)

### 💽 EBS – Elastic Block Store

- Provides **block storage** volumes for EC2
- Persistent even if instance stops
- Can be attached/detached
- Only one EC2 can **attach a volume at a time**
- Can be:
  - GP3 (general purpose)
  - IO2 (IOPS optimized)
  - ST1 (throughput)
  - SC1 (cold HDD)

✅ Ideal for operating systems, self-hosted databases, and logs

### 📍 Floating IPs and How to Connect via Bash

- EC2 uses **Elastic IPs** to simulate static public IPs
- This makes EC2 Instances reachable to the internet
- Can only be attached to **EC2 in public subnets**
- You can **associate/dissociate** at any time
- Great for failover or shared access
```bash
ssh -i my-key.pem ec2-user@<Elastic-IP>
```
###  Hands-On – My First EC2 Instance
> You'll launch an EC2 instance, attach an EBS volume.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to AWS Console → EC2
3. Click Launch Instance
4. Create an instance (use ideally a nano image or just something very light!)
5. Add an EBS Storage to it as well as an Elastic IP
6. Ping the Elastic IP to check if it worked
7. After that worked, terminate it (this deletes it)

### 📂 EFS – Elastic File System
- **Managed NFS** storage
- Mountable by **many EC2s** at once
- Scales automatically
- Pay only for storage used
- Use for **shared config, logs, or file sharing**

✅ Great for container clusters, shared data   
❌ Not suitable for high IOPS block-level workloads (use EBS instead)

### ⚖️ EBS vs EFS
| Feature     | EBS                     | EFS                            |
| ----------- | ----------------------- | ------------------------------ |
| Type        | Block storage           | Network file system (NFS)      |
| Attachment  | 1 instance at a time    | Multiple EC2s simultaneously   |
| Performance | High IOPS, low latency  | Good throughput, not for DBs   |
| Latency       | Lower (local SSD-like)      | Higher (network attached)            |
| Scaling       | Manual size config          | Automatic                           |
| Use Case    | Boot volumes, databases | Shared logs, config, user data |
| Mount location | `/dev/xvdf`, etc.      | Mounted via NFS path             |

### Amazon FSx

**Amazon FSx** provides **fully managed file systems** optimized for specific workloads.  
Unlike EFS (which is NFS-based and Linux-focused), FSx offers support for **Windows**, **Lustre**, **NetApp ONTAP**, and **OpenZFS**.

> Think of FSx as “choose your file system flavor, but fully managed.”

#### Key Features

- 📁 Managed **file storage** with POSIX or SMB/NFS access
- 🧠 Four file system options:
  - FSx for **Windows File Server**
  - FSx for **Lustre**
  - FSx for **NetApp ONTAP**
  - FSx for **OpenZFS**
- 🔒 Supports **encryption**, **backups**, **Active Directory integration**, and **multi-AZ**
- 🔄 Built-in **data deduplication**, **compression**, and **snapshots** (depending on type)

#### 📦 FSx Variants – Use Cases & Traits

**1. FSx for Windows File Server**

- 🖥 SMB protocol, native Windows file system (NTFS)
- Supports **Active Directory**, **DFS namespaces**, **Windows ACLs**
- ✅ Ideal for lift-and-shift of **on-prem Windows file shares**
- ❌ Linux clients cannot access

**2. FSx for Lustre**

- ⚡ High-performance, low-latency file system
- ✅ Used in **HPC**, **ML training**, **video rendering**
- Can **link to S3** for hot/cold storage tiering
- POSIX-compliant, Linux-only

**3. FSx for NetApp ONTAP**

- 🧩 Enterprise-grade features: **SnapMirror**, **FlexClone**, **multi-protocol (NFS/SMB)**
- ✅ Great for **hybrid enterprise storage**, **DR**, or **NetApp migration**
- Mountable from **Windows and Linux**

**4. FSx for OpenZFS**

- ⚙ ZFS-based file system, Linux focused
- ✅ Supports **snapshots**, **clones**, and **data integrity**
- Best for **Linux admin-heavy environments** that need advanced features

#### ⚖️ FSx vs EFS

| Feature                   | Amazon FSx                          | Amazon EFS                         |
|---------------------------|--------------------------------------|------------------------------------|
| Protocols                 | SMB, NFS, ZFS (depending on flavor) | NFS (Linux)                        |
| OS compatibility          | Linux & Windows                     | Linux only                         |
| Performance tuning        | More granular (e.g., Lustre, ONTAP) | Simpler scaling                    |
| Complexity                | Higher (variant-specific)           | Lower                              |
| Use case example          | Windows shares, ML training, NetApp | Shared config, Lambda/ECS storage  |

---

#### 💰 Cost Considerations

- You pay per:
  - **Provisioned storage**
  - **Throughput capacity** (in some cases)
  - **Backup storage**
- **Lustre and ONTAP** may be significantly more expensive due to performance features
- **Windows FSx** requires careful planning for **Active Directory** integration, which may also cost extra

✅ Backup and restore snapshots are incremental  
✅ Use lifecycle policies (if linked to S3 for FSx Lustre) to reduce storage costs

#### Best Practices

✅ Choose FSx **only when EFS isn’t sufficient** (e.g., you need SMB, AD, or performance)  
✅ Use **FSx for Windows** when lifting file servers  
✅ Use **FSx for Lustre** for ML, rendering, or HPC workloads  
✅ Use **dedicated VPC mount targets** for multi-AZ access  
❌ Don’t use FSx as a drop-in for object storage — it’s block/file-based only

### 📈 Auto Scaling (For EC2)
Auto Scaling ensures you have the **right number** of instances to handle load.
- You define:
    - **Desired** capacity (e.g., 2 instances always)
    - **Min/max** capacity
    - **Scaling policies** based on CPU, memory, time, etc.
- **Launch templates** define what instances to start
- Paired with **Elastic Load Balancer (covered later)** for traffic distribution

✅ Essential for fault tolerance and cost optimization   
✅ Can use On-Demand + Spot + Reserved mix

### Hands-On – Auto Scaling Group
> Create an Auto Scaling group with a desired count of 2 EC2 instances, min of 1 and max of 4.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to EC2 → Auto Scaling Groups → Create
3. Launch template:
4. Create new from EC2 config
5. Skip scaling policies for now (we're focusing on fixed size)


✅ Two EC2 instances will be now automatically provisioned   
✅ Try terminating one — Auto Scaling will replace it within minutes   
❌ Once you finished the lab, delete the auto scaling group and then terminate the EC2 instances

### Best Practices

✅ Use ***reserved or savings plan** pricing for steady workloads   
✅ Store state on **EBS or EFS**, not instance storage (instance storage is **ephermal**)  
✅ Enable **detailed monitoring and CloudWatch alarms**   
✅ Use **Auto Scaling** and **ELB** for HA and resilience   
✅ Rotate keys, patch instances, or use **SSM** to automate setup   
❌ Don't hardcode secrets — use **Secrets Manager** (covered later) or IAM roles 

## Amazon ECS & Fargate

**Amazon ECS** (Elastic Container Service) is a fully managed container orchestration service from AWS.  
You can run workloads using **EC2 instances** or **Fargate**, a serverless compute engine for containers.

### Key Features

- 📦 Run **Docker containers** at scale on AWS
- 🛠 **Two launch types**:
  - `EC2`: Run containers on self-managed EC2 instances
  - `Fargate`: AWS manages the compute for you
- 🔐 Integrates with:
  - IAM (role per task)
  - VPC networking
  - CloudWatch Logs & Metrics
- 🧩 Supports **load balancers**, **autoscaling**, and **task scheduling**
- ⚙️ Works with **ECR** (Elastic Container Registry) or any Docker-compatible registry
- 🌍 Can run across multiple AZs in a cluster
- 🧠 Supports **blue/green deployments** via CodeDeploy

### 📦 Amazon ECR – Elastic Container Registry

**ECR** is AWS’s Docker image repository service.

- 🔐 Integrated with IAM and KMS for access and encryption
- 🧽 Automatically scans images for vulnerabilities (optional)
- 🔄 Native integration with ECS, Fargate, EKS, and CodePipeline

✅ Use ECR to store container images you build, test, and deploy

Example image push:

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
```

### 🔁 Auto Scaling – ECS & Fargate

Both ECS and Fargate support **Auto Scaling**, but they scale **differently** depending on how you run your containers:

#### ECS on EC2

- 🔁 Auto Scaling happens at **two levels**:
  - **Service Auto Scaling** → Adjusts the number of container tasks
  - **EC2 Auto Scaling Group** → Adjusts the number of instances

- ✅ Useful when you want **deep control**, **custom AMIs**, or **per-container cost visibility**
- ❌ You manage the EC2 fleet yourself (patching, scaling, etc.)

#### Fargate

- 🧠 **No infrastructure management** — just define how many tasks you want
- 📈 Supports **Target Tracking Scaling** and **Scheduled Scaling**
- ✅ Ideal for:
  - Spiky workloads
  - CI/CD pipelines
  - Dev/test environments
- ❌ Slightly **higher cost per compute unit** vs EC2-based ECS
- ❌ **Cold start-like effect**: Task startup time is 15–60 seconds

#### ECS vs Fargate – Quick Comparison

| Feature                   | ECS (EC2)                      | Fargate                        |
|---------------------------|--------------------------------|--------------------------------|
| Control over infrastructure | ✅ Full (EC2-level access)     | ❌ None (serverless)           |
| Startup time              | Faster (container on live EC2) | Slower (spin up task infra)   |
| Cost                      | Cheaper for large, stable workloads | More cost for burst/flexibility |
| Auto Scaling complexity   | Two layers to manage           | One layer (task count only)   |
| Operational overhead      | You manage the cluster         | AWS manages everything        |

### 🧠 EKS as a Container Engine

**Amazon EKS** (Elastic Kubernetes Service) is AWS’s fully managed **Kubernetes** platform.

- Uses **Kubernetes** as the orchestration engine instead of ECS
- Best for:
  - Teams with existing Kubernetes skills or tooling
  - Multi-cloud workloads
  - More granular control over orchestration
- ⚠️ More complex than ECS:
  - You manage control plane objects (pods, services, deployments)
  - Higher learning curve

✅ You can run EKS with **EC2 or Fargate** as the compute layer  
❌ Not ideal for teams without K8s experience or where ECS already fits

> If you're new to containers: start with **ECS + Fargate**  
> If you're moving from Kubernetes: go with **EKS**

###  Best Practices

✅ Use **Fargate** for ease of use, elasticity, and low ops overhead  
✅ Use **ECS on EC2** when you need max control or cost optimization  
✅ Always push images to **ECR** and scan them regularly  
✅ Scale based on **request queue length**, **CPU/memory**, or **custom metrics**  
✅ Use **CloudWatch Logs** and **Container Insights** for monitoring  
❌ Don’t forget IAM roles — use **task-level roles**, not broad EC2 permissions

## AWS Storage Gateway

**AWS Storage Gateway** is a hybrid cloud storage service that connects **on-premises infrastructure** with AWS storage services.  
It allows you to **seamlessly back up, archive, or extend on-prem storage to the cloud**.

###  Key Features

- 🔁 Bridges **on-prem systems** with AWS S3, EBS, or Glacier
- 🧩 Comes as a **VM, physical appliance**, or runs on **AWS Snowcone**
- 📂 Supports caching and compression
- 📶 Local systems see **NFS, SMB, or iSCSI** — while AWS handles actual storage
- 🧠 Often used in **backup, migration, disaster recovery, and archiving**

### 📦 Gateway Types and Use Cases

| Type                    | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| **File Gateway**        | NFS/SMB file shares → Backed by S3. Used for backup, archive, or data lake ingest |
| **Volume Gateway**      | Block storage (iSCSI) backed by EBS or S3 snapshots. Used for on-prem backup & recovery |
| **Tape Gateway**        | Emulates physical tape libraries. Integrates with S3 + Glacier for cheap long-term backup |

#### ✅ Example Scenarios

- 🏢 **File Gateway**:
  - Department files stored locally but automatically backed to S3
  - Local access speeds + cloud durability
- 💽 **Volume Gateway**:
  - On-prem servers write to iSCSI disk
  - Snapshots stored in S3 (can restore in EC2)
- 📼 **Tape Gateway**:
  - Legacy backup tools write to virtual tapes
  - Data is stored in Glacier instead of physical tapes

### 💰 Cost Considerations

- Charged for:
  - **Provisioned storage**
  - **Data transfer** (if moving to AWS)
  - **Snapshots or virtual tapes** stored in S3/Glacier
- Local caching reduces repeated transfer cost
- ✅ Use lifecycle policies for **automatic archive to Glacier**

### Best Practices

✅ Use **File Gateway** for unstructured file backup and ingest  
✅ Use **Tape Gateway** to modernize backup workflows without rewriting apps  
✅ Monitor usage with **CloudWatch**, and protect access via IAM  
✅ Deploy Storage Gateway in **edge locations** using Snowcone where needed  
❌ Don’t use Storage Gateway for active app storage unless caching is properly configured

## Alternative PaaS Solutions

These services let you **deploy applications without managing infrastructure**. They're great for rapid prototyping, small teams, or specific use cases — but not always the best fit for large-scale or complex production workloads. It's important to know them but we don't recommend using them to often - hence only a quick introduction to each.

### 🌱 AWS Elastic Beanstalk

**Beanstalk** is a classic PaaS for deploying web apps using Docker, Python, Node.js, Java, etc.

- ✅ Handles provisioning, load balancing, scaling, and updates
- ✅ Great for small-to-mid web apps with standard architectures
- ❌ Limited transparency — hard to debug issues or customize infra
- ❌ Aging service with fewer updates than newer alternatives

### ⚡ AWS Amplify

**Amplify** is a frontend + backend platform focused on **mobile and web apps**.

- ✅ Connects React/Vue/Next.js apps with auth, APIs, storage
- ✅ Integrates well with Cognito, AppSync, S3, Lambda
- ❌ Not built for backend-heavy or enterprise apps
- ❌ Can be too "black box" — hard to debug or extend deeply

### 🧱 AWS Lightsail

**Lightsail** is a simplified hosting platform — like “EC2 for beginners.”

- ✅ One-click deploy for WordPress, LAMP stack, etc.
- ✅ Fixed-price, low-complexity VMs with optional databases
- ❌ Not designed for autoscaling or integration with advanced AWS services
- ❌ Limited networking/customization

### 🚀 AWS App Runner

**App Runner** is a modern PaaS for containerized web apps — think of it as a simplified Fargate + ALB + CI/CD bundled.

- ✅ Deploy from GitHub or ECR in minutes
- ✅ Handles HTTPS, scaling, load balancing automatically
- ✅ Great for microservices and internal tools
- ❌ Cold starts for idle apps unless you pay for min instances
- ❌ Less flexibility than ECS/EKS for fine-tuning performance

### 🧠 Honest Opinion: When to Use or Avoid

| Service      | Use When...                                 | Avoid When...                                 |
|--------------|---------------------------------------------|-----------------------------------------------|
| **Beanstalk**| You need a quick LAMP-style app with little AWS knowledge | You want infrastructure control or deep observability |
| **Amplify**  | You're building a full-stack JS app or prototype | You're building enterprise-grade backends or APIs |
| **Lightsail**| You just need a basic VPS/WordPress site    | You care about autoscaling or integrations     |
| **App Runner**| You want PaaS for containers with no ops   | You need custom networking, low latency, or high scale |

✅ Use these services to **ship fast and iterate**  
❌ Migrate away when you need **control, customization, or large-scale performance**

## AWS Batch

**AWS Batch** is a fully managed service for running **batch computing jobs** on AWS without manually managing servers or scheduling logic.

It’s ideal for **time-consuming, parallelizable workloads** like simulations, video processing, genomics, rendering, and large-scale data transformations.

### Key Features

- 🧠 **Job scheduler** and **queue management** built in
- 📦 Runs container-based jobs using **ECS or Fargate** under the hood
- ⚙️ Supports **array jobs**, **job dependencies**, and **prioritization**
- 🛠️ Automatically provisions and scales compute environments
- ✅ Integrated with:
  - IAM (per-job or per-environment roles)
  - ECR for container images
  - S3, CloudWatch, and VPC networking
- 🔁 Can run **GPU**, **memory-optimized**, and **spot** workloads

### Typical Use Cases

- 🔬 Scientific simulation and modeling
- 🖼️ Image/video rendering
- 🔄 ETL jobs or data preprocessing
- 🧬 Genomics/bioinformatics pipelines
- 📉 Large-scale data analytics

### How It Works

1. **Submit jobs** to a **job queue**
2. Batch matches them to a **compute environment**
3. Jobs are run in containers (via ECS or Fargate)
4. Results are stored in S3 or another output location

You define:
- ✅ **Job definitions** (image, vCPU/memory, command)
- ✅ **Queues** (can have priority tiers)
- ✅ **Compute environments** (EC2, Spot, or Fargate)

### 💰 Cost Considerations

- You pay for:
  - EC2 or Fargate resources used (based on instance pricing)
  - No additional charge for the Batch service itself
- ✅ Works very well with **EC2 Spot Instances** for massive cost savings
- ❌ Not ideal for latency-sensitive or interactive jobs

### Best Practices

✅ Use **Spot compute environments** for non-critical, cost-sensitive workloads  
✅ Pre-build and test **container images** locally before running in Batch  
✅ Use **array jobs** for parallel processing (e.g., one job per file or record)  
✅ Monitor with **CloudWatch Logs and Events**  
❌ Avoid Batch for real-time or low-latency use cases — it's optimized for queued, background jobs

## Lambda

**AWS Lambda** is a serverless compute service that lets you run code **without provisioning or managing servers**.

You write functions, define triggers, and AWS handles the execution, scaling, and billing — all the way down to the millisecond.

### Key Features

- ⚡ **Event-driven**: Runs in response to triggers like HTTP requests, S3 uploads, DynamoDB changes, etc.
- 🧠 **Auto-scaled**: No need to manage capacity
- 🧾 **Per-request billing**: Pay per ms of execution + resources used
- 📦 Native integration with:
  - API Gateway, DynamoDB Streams, S3, EventBridge, etc.
- 🔐 Secure by default: IAM-based permission control for what the function can access
- 📊 Full observability: CloudWatch Logs, metrics, and X-Ray tracing

### ⚙️ Runtimes

Lambda supports multiple runtimes:

- ✅ **Node.js**, **Python**, **Java**, **.NET**, **Go**, **Ruby**
- ✅ **Custom Runtime** support for any language (via Amazon Linux base)
- ✅ **Container Images** (up to 10 GB) for complex packaging needs

> ⚠️ Cold start time depends on the runtime — **Java and .NET** usually have longer cold starts.

### 📚 Lambda Layers

**Layers** let you share libraries, dependencies, or code across functions.

- 📦 Store common packages (e.g., NumPy, boto3, pandas) in a separate layer
- 🔁 Reuse them across multiple Lambda functions
- ✅ Speeds up deployment and standardizes environments

Example use case:
- One layer contains `requests`, `pandas`
- All data-processing functions can reference it

> ⚠️ Lambda limits you to **5 layers per function** and **50MB zipped per layer** (uncompressed: 250MB)

### 🔄 Triggers

Lambda can be triggered by:

| Trigger Source      | Example Use Case                       |
|---------------------|----------------------------------------|
| **DynamoDB Streams** | React to new records in a table        |
| **S3 Events**        | Process new uploads                    |
| **API Gateway**      | Build REST or HTTP APIs                |
| **EventBridge**      | Scheduled jobs, decoupled services     |
| **SNS/SQS**          | Notification or queuing pattern        |
| **Step Functions**   | As part of a larger workflow           |

###  Hands-On – React to DynamoDB Streams with Lambda

> You'll create a Lambda function that listens to changes in your previously created `Users` DynamoDB table and logs any new records to CloudWatch.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**  
2. Go to your **DynamoDB table** (e.g., `Users`)
3. Click **Enable stream**
   - Type: **New image**
   - Click Save
4. Go to **Lambda** → **Create function**
   - Permissions: Create a new role with **basic Lambda permissions**
5. Goal is that you can print out the event that is sent to the function.
6. Generate a proper event by adding a new record to DynamoDB

### 🤖 SDK Access to Other Services

Lambda functions can interact with other AWS services using **language-specific SDKs**.

- ✅ **Python** → `boto3`
- ✅ **Node.js** → `aws-sdk`
- ✅ **Java** → AWS Java SDK v2
- ✅ **Go** → AWS SDK for Go v2
- ✅ **Custom runtime** → Call AWS APIs directly (via HTTPS)

These SDKs are either:
- Pre-installed in the Lambda runtime (e.g., `boto3`, `aws-sdk`)
- Or you can include them via **Lambda Layers** or dependencies in the ZIP/container

#### 📦 Example: Python + Boto3

```python
import boto3

s3 = boto3.client('s3')
s3.put_object(
    Bucket='my-bucket',
    Key='example.txt',
    Body='Hello from Lambda'
)

```
✅ This will upload a file to s3://my-bucket/example.txt

> ⚠️ The Lambda execution role must have permission to perform these actions (e.g., s3:PutObject)

### Hands-On – Write DynamoDB Entry to S3 as CSV
> You’ll now enhance the previous Lambda function to write inserted DynamoDB items to an S3 bucket as CSV rows.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**  
2. Create an S3 Bucket for this task or use one of the existing
3. Update the lambda role to allow `s3:PutObject` to that S3 Bucket
4. Now in the lambda, instead of printing out the event, write code that prints the event into a csv inside your bucket.

### 🛠️ Lambda Powertools
**AWS Lambda Powertools** is a library that simplifies:
- Structured logging
- Metrics (CloudWatch)
- Tracing (X-Ray)
- Input validation
- Feature flags

```python
from aws_lambda_powertools import Logger

logger = Logger()

def lambda_handler(event, context):
    logger.info("Processing event", extra={"details": event})
```
✅ Available for **Python, Java, and TypeScript**   
✅ Great for production-grade serverless functions   

### ⛔ Lambda Limits and Quotas
| Resource                  | Limit                         |
| ------------------------- | ----------------------------- |
| **Max timeout**           | 15 minutes                    |
| **Memory**                | 128 MB – 10,240 MB            |
| **Package size (zip)**    | 50 MB (compressed)            |
| **Package size (unzip)**  | 250 MB                        |
| **Container image size**  | 10 GB                         |
| **Layers per function**   | 5                             |
| **Concurrent executions** | 1,000 (soft limit, raiseable) |
| **Environment vars size** | 4 KB total                    |

✅ You can request limit increases for concurrency and storage    

### Best Practices
✅ Keep functions short-lived (<15 min)   
✅ Use **provisioned concurrency** with Java and .Net if latency matters (or better just use **Typescript or Lambda**)   
✅ Offload shared code to layers   
✅ Add **timeouts, retries, and DLQs** for robustness   
✅ Use **structured logging** for downstream observability
❌ Don’t use plain Lambda for heavy, stateful, or persistent workloads — combine it with the next service shown **Step Function** or use **Fargate/ECS** if you can't make it eventbased

## AWS Step Functions

**AWS Step Functions** is a fully managed **workflow orchestration** service.  
It lets you **coordinate services and logic** into a visual, reliable flow — no glue code or queue plumbing required.

###  Key Features

- 🧩 Connects AWS services (Lambda, Batch, ECS, DynamoDB, SQS, etc.)
- 🔁 Supports **sequential**, **parallel**, **conditional**, and **retry** logic
- 📈 Visual workflow execution with history + error tracking
- 🧪 Ideal for:
  - Serverless apps
  - ETL pipelines
  - Approval workflows
  - Multi-step data processing

✅ Written using the **Amazon States Language (ASL)** — JSON-based declarative format  
✅ Optionally use **Workflow Studio** to design visually (no code)

### 🔄 Standard vs Express Workflows

| Feature                  | Standard Workflow                  | Express Workflow                   |
|--------------------------|------------------------------------|------------------------------------|
| Duration                 | Up to 1 year                       | Up to 5 minutes                    |
| Pricing model            | Per state transition               | Per duration + number of invocations |
| Use case                 | Long-running, auditable workflows  | High-volume, short-lived events    |
| Execution history        | Persisted + detailed               | Short-lived, logs only (CloudWatch) |
| Error handling           | Full ASL support                   | Limited retry/catch support        |

✅ Use **Express** for real-time event pipes  
✅ Use **Standard** for durable, auditable business logic

### 🔗 Integration with Other Services

Step Functions integrates natively with over **200 AWS services** via:

1. **Service Integrations** (no Lambda required):
   - e.g., `DynamoDB.PutItem`, `S3.CopyObject`, `Glue.StartJobRun`
2. **Lambda Functions** (traditional serverless workflows)
3. **API Gateway**, **SNS**, **SQS**, **EventBridge**, etc.

✅ **Direct service integration** = better performance, lower cost  
✅ Supports **IAM-per-state** granularity for fine-grained control

### 🧠 State Types

| State Type     | Description                             |
|----------------|-----------------------------------------|
| `Task`         | Call a Lambda, service, or external API |
| `Choice`       | If/Else branching logic                 |
| `Wait`         | Delay for fixed time or until timestamp |
| `Parallel`     | Run branches concurrently               |
| `Map`          | Run a loop over input array             |
| `Pass`         | Placeholder or fixed value injection    |
| `Succeed`/`Fail` | Ends the workflow with success/failure |

### Hands-On – My First Step Function

> Create a simple workflow:  
> **Wait 5 seconds → Call Lambda → Succeed**

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**  
2. Go to Step Functions → Create state machine
3. Two states should be added:
    - Wait state of 5 seconds
    - Task state integrating the lambda that is writing events into S3
4. Don't forget to append to proper IAM to the execution roles (tip: it needs to be able to call Lambda)
5. Start the workflow

### Best Practices
✅ Prefer dirct **service integrations** over task state that has a simnple boto3 Lambda when possible   
✅ Use **Catch/Retry** blocks for failure tolerance   
✅ Use **Map** state for processing arrays in parallel   
✅ Choose **Express** when you need real-time, high-volume execution   
❌ Don’t run tight loops or synchronous HTTP calls in Lambda inside Step Functions (lambda is billed by duration) - instead use Steps like "Wait" for polling logic and synchronous waits. This is waaaaay cheaper.

## Amazon Inspector

**Amazon Inspector** is a vulnerability management service that automatically scans your AWS workloads for security issues.

It’s used to identify:
- Software vulnerabilities (CVEs)
- Exposed secrets
- Misconfigurations
- Unpatched packages

###  Key Features

- ✅ **Automated scanning** of:
  - EC2 instances
  - Container images in ECR (Elastic Container Registry)
  - Lambda functions (runtime scanning)
- 🔍 Detects:
  - Outdated packages
  - OS-level CVEs (Common Vulnerabilities & Exposures)
  - Application vulnerabilities in container images
- ⚙️ Integrates with:
  - **AWS Systems Manager (SSM)** for agent-based scanning on EC2
  - **ECR** to scan images on push or periodically
  - **Security Hub** to consolidate findings
- 📊 Outputs detailed **findings**, sorted by severity and impacted resource
- Fully **agentless** for ECR/Lambda; **agent-based** for EC2

> Think of it as your internal vulnerability scanner — fully managed and cloud-native.

### Finding Example

| Finding                  | Severity | Description                              |
|--------------------------|----------|------------------------------------------|
| `CVE-2022-1234`          | High     | Outdated OpenSSL package in image layer  |
| `UnencryptedRootVolume` | Medium   | EC2 instance missing EBS encryption      |
| `OutdatedLambdaRuntime` | Low      | Node.js runtime version deprecated       |


### Best Practices

✅ Enable Inspector **org-wide** via AWS Organizations  
✅ Integrate with **Security Hub** for unified risk visibility  
✅ Set up **EventBridge** rules to notify devs when critical issues appear  
✅ Use Inspector as part of your **CI/CD pipeline** for container builds  
✅ **EFS** for VM migrations, where a shared filesystem is needed   
❌ Don’t rely on Inspector alone — complement with Config, GuardDuty, Macie, and IAM reviews   


## Bespinians most used Ranking

✅ **Lambda** + **Step Function** as event-based approach whenever we start a new app or allowed to rearchitect   
✅ **Inspector** is a nice to have in Landing Zones with centralized management   
✅ If we use IaaS like **EC2** (which we try to avoid), then we always auto-scale!   
✅ **FSx** can be very interessting with Machine Learning Container Workloads   
✅ **Batch** can be a godsent for quick one-time jobs or scheduled, reoccuring tasks   
✅ Sometimes **Amplify** can be a quick and good way to deploy your Front-End. We mostly avoid it but sometimes we seek it.   
✅ **Fargate** is a good possiblitiy for customers that don't want to / don't have the skills to manage their container environment but still want to forcefully use containers   
✅ **EKS** is the Backend we normally would for bigger Container Environments and systems
✅ We still would **always** prefer an eventbased approach with serverless FaaS (Lambda + Step-Functions) over IaaS and Container Topics on EKS/ECS
