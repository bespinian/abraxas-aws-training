# 6. Networking & Interfaces

## Content

- The following services will be explained and focused on:
    - ACM 
    - API Gateway 
    - AppSync 
    - CloudFront
    - Direct Connect 
    - ELB 
    - EventBridge 
    - Lambda URL 
    - Resource Access Manager 
    - Route 53 
    - SES 
    - SNS 
    - SQS
    - VPC 
    - WAF & Shield 

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## Amazon CloudFront

**Amazon CloudFront** is a **Content Delivery Network (CDN)** that caches and delivers content (static or dynamic) through a global network of edge locations.

It helps speed up websites, APIs, video streams, and even full web applications by serving responses closer to the user — while reducing load on origin servers.

### 🌍 CDN – What It Is and Why It Matters

A **CDN (Content Delivery Network)** is a distributed system of edge servers around the world that:
- 🌐 Caches your content close to your users
- 🚀 Reduces latency by avoiding round-trips to the origin (e.g., S3, ALB, API)
- 📦 Helps absorb bursts of traffic
- 🛡️ Adds security via HTTPS, geo-blocking, and WAF

✅ Unlike traditional Cloud services (doesn't matter of which cloud), **CDNs aren't bound to specific AWS Regions**  
As example: CloudFront uses **over 400+ edge locations** across continents for global reach.

### 🧠 CloudFront Terminology

Understanding these key terms will help you configure and troubleshoot CloudFront distributions effectively:

| Term                        | Description                                                                 |
|-----------------------------|-----------------------------------------------------------------------------|
| **Origin**                  | The source of the content — typically an S3 bucket, ALB, EC2, or API Gateway |
| **Distribution**            | The CloudFront configuration that connects origins to edge locations        |
| **Edge Location**           | A global data center where CloudFront caches and serves content             |
| **Cache Behavior**          | Rules that define how CloudFront handles different request paths or methods |
| **TTL (Time to Live)**      | How long content is cached at the edge before it's refreshed from origin    |
| **Origin Access Control (OAC)** | Mechanism that allows CloudFront to securely access private S3 content      |
| **Signed URL / Cookie**     | Tokens used to control access to restricted CloudFront content              |
| **Invalidation**            | A request to remove (or refresh) cached objects from CloudFront edge nodes  |
| **Viewer Protocol Policy**  | Whether CloudFront allows HTTP, HTTPS, or redirects from HTTP to HTTPS      |
| **Lambda@Edge / CF Functions** | Code that runs at edge locations to transform requests/responses           |

✅ Knowing these terms helps with:
- Understanding **error messages** and logs
- Writing **fine-tuned configurations**
- Integrating **secure and optimized** CloudFront setups

### Key Features

- 🌐 Global edge delivery for **websites, APIs, apps**:
  - Acts as a public access to files and apps, that behind CloudFront are treated as private.
- 🧊 Caches:
  - S3 objects (HTML, CSS, JS, images)
  - ALB or custom HTTP origin responses
  - API Gateway, AppSync, Lambda URLs
- 🔐 HTTPS with **ACM or default cert**
- 🪪 Supports **Origin Access Control (OAC)** or legacy **OAI**
- 🔄 TTL control (cache for seconds → days)
- 🧩 Native integration with:
  - **WAF**
  - **Lambda@Edge** or **CloudFront Functions**
  - **Signed URLs / Cookies** for access control
- 📊 Logs to S3 or CloudWatch

### ✅ When to Use

| Use Case                         | CloudFront Recommended? |
|----------------------------------|--------------------------|
| Public static website            | ✅ Yes                   |
| Global video or image hosting    | ✅ Yes                   |
| API fronting with caching        | ✅ Yes                   |
| Secure content behind signed URLs| ✅ Yes                   |
| Private internal content         | ❌ No (VPC-only solutions better) |

### Hands-On – Distribute Your S3 Website via CloudFront (with OAC)

We’ll convert your earlier **S3 static website** to a **secure CloudFront-powered delivery** using **Origin Access Control (OAC)**.

#### Prerequisites

- You already have a public S3 bucket with static site content (e.g., index.html)
- Previously used **S3 Static Website Hosting** (we’ll now turn that option **off**. CloudFront takes now this task on.)

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**
2. Go to **S3 → Your bucket**
3. Under **Properties → Static website hosting**
4. Choose **Disable**

✅ We're switching to private access via CloudFront + OAC

5. Go to **CloudFront → Distributions → Create distribution**
6. Origin domain:
   - Select your **S3 bucket** (from dropdown)
7. Origin access:
   - Click **"Create origin access control (recommended)"**
   - Signing behavior: `Always`
8. S3 bucket access:
   - Choose: **"Yes, update the bucket policy"**
   - ✅ This lets CloudFront access S3 **privately**
9. Default behavior:
   - Viewer protocol policy: `Redirect HTTP to HTTPS`
   - Allowed methods: `GET, HEAD`
   - Cache policy: `CachingOptimized`
10. Wait for status = `Deployed` (~5–10 mins) (continue with the rest and come back later)
11. Copy the CloudFront **Domain name** (e.g., `d123abc.cloudfront.net`)
12. Open in browser — you should see your S3 site load over HTTPS

✅ You’ve now migrated to a secure, global CDN-based hosting setup

### Best Practices

✅ Use **CloudFront over S3 website hosting** for production workloads  
✅ Always use **OAC**, not public access (legacy OAI is deprecated)  
✅ Add **WAF** for DDoS and OWASP protection  
✅ Cache carefully — short TTLs for APIs, long for static files  
✅ Use **signed URLs or signed cookies** for private content  
❌ Don’t rely on CloudFront for authentication — use Cognito, signed URLs, or auth upstream

## Amazon VPC – Virtual Private Cloud

**Amazon VPC** lets you create an isolated, logically-separated network within AWS where you launch and manage resources like EC2, RDS, or Lambda.  
You control **IP ranges, routing, subnets, firewalls**, and **internet access**.

### Key Features

- 🏠 Define custom **CIDR blocks** (e.g., `10.0.0.0/16`)
- 🌍 Create **public and private subnets**
- 🔁 Use **Internet Gateways**, **NAT**, and **VPC Endpoints**
- 🔐 Control access with **Security Groups** and **Network ACLs**
- 🔗 Peer VPCs across accounts/regions (VPC peering, Transit Gateway)
- 💡 Foundation for all EC2, RDS, Lambda (in VPC), etc.

✅ Think of it as your **network “data center” in the cloud**

### 🌐 Subnets (Public vs Private)

| Subnet Type   | Has Route to Internet Gateway? | Can EC2 get public IP? | Use Case                      |
|---------------|-------------------------------|------------------------|-------------------------------|
| **Public**    | ✅ Yes                        | ✅ Yes (if assigned)    | Web servers, bastion hosts    |
| **Private**   | ❌ No                         | ❌ No                   | DBs, internal services, batch jobs |

> ✅ A **subnet is public only if it has a route to an Internet Gateway**

### 🏠 The Default VPC – What It Is and Why You Probably Shouldn’t Use It

When you create a new AWS account, AWS automatically creates a **default VPC** in each region.

This default VPC includes:
- A `/16` CIDR block (e.g., `172.31.0.0/16`)
- One **public subnet per AZ** in that region
- An **Internet Gateway**
- A **main route table** and default **Security Group**
- Automatically assigns **public IPs** to EC2 instances

#### ✅ Why It Exists

- Makes it easy to **launch EC2 or Lambda** with internet access immediately
- Ideal for:
  - **Quick experiments**
  - **Temporary proof-of-concept work**
  - Individual developer sandboxes

#### ❌ Why You Should Avoid It in Real Environments

| Reason                      | Why It Matters                                                             |
|-----------------------------|-----------------------------------------------------------------------------|
| **Hard to control**         | Default setup mixes public & private unintentionally                       |
| **No naming consistency**   | Everything is auto-named (e.g., `subnet-1234abcd`)                          |
| **Doesn’t match infra-as-code** | Not reproducible — IaC tools usually assume clean-slate custom VPC     |
| **Lack of segmentation**    | All subnets route directly to the Internet Gateway                         |
| **Shared across workloads** | If you’re not careful, multiple teams/devs may pollute the same environment |
| **Org-wide deployments**    | Centralized security, auditing, and policies work better with consistent custom VPCs |

#### ✅ Best Practice Default VPC: Delete or Disable Use of Default VPCs

- In most **enterprise accounts or AWS Organizations**:
  - 🔒 Create custom VPCs per workload/unit/environment
  - 🛡️ Use Control Tower or Org-wide templates to enforce this
  - ❌ Don’t let devs build into `172.31.0.0/16` out of habit

> ✅ You can delete the default VPC in all regions (via console or script), or restrict access via SCPs and automation.

#### How to Clean Up a Default VPC

1. Identify the default VPC in each region:
   - Console: Look for VPC with name “default”
   - CLI: `aws ec2 describe-vpcs --filters Name=isDefault,Values=true`

2. Delete the components in this order:
   - Subnets → IGW → Route Tables → SGs → VPC

3. Replace it with:
   - Your **own custom VPC**
   - Proper **CIDR**, **naming**, **public/private subnet split**
   - Provisioned via **Terraform, CloudFormation, or Control Tower**

#### TL;DR

✅ Use the default VPC only for temporary testing  
🟡 Never use it for production or organizational workloads  
❌ Delete it or block it entirely when enforcing IaC and security standards

### 🛰️ Route Tables & Gateways

- 🔀 **Route Table** = set of rules for how traffic leaves the subnet
- 🌐 **Internet Gateway (IGW)** = outbound access to the internet
- 🔁 **NAT Gateway** = outbound internet for **private subnets only**
- 🚫 **No inbound traffic is allowed** by default — must be explicitly opened via Security Groups


### Hands-On – Create a Subnet for EC2 (no EC2 yet)

> In this lab, you will create a **shared VPC** in the `management/network` account. Later, other accounts can deploy workloads into it. This will be provisioned to other accounts in a later lab but let's prepare it now!

Recap of the org sturcture:
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
Use AWS SSO or Identity Center to switch to your `network` account.
2. Create a VPC without Subnets and make it big like `10.100.0.0/16` because normally this network will be shared across multiple Accounts
3. Add two subnets and ensure they are in **different AZs** for HA.:
   - `public-subnet-1` → `10.100.1.0/24`
   - `private-subnet-1` → `10.100.2.0/24`
4. Create an `Internet Gateway` and add it to the **public subnet's** `route table`

✅ You've now created a VPC with **public subnet** and a **private subnet** to share to other accounts.

### 🔐 Security Groups vs Network ACLs

| Feature            | Security Group (SG)         | Network ACL (NACL)             |
|--------------------|-----------------------------|--------------------------------|
| Applies to         | ENIs (EC2, Lambda, etc.)    | Subnets                        |
| Stateful?          | ✅ Yes                      | ❌ No (explicit return rules)  |
| Default rule       | Deny all inbound            | Allow all (until modified)     |
| Typical usage      | Per resource, app-focused   | Subnet-level, coarse filtering |
| Rules are...       | ALLOW only                  | ALLOW or DENY                  |


#### 🧭 When to Use Which

✅ **Security Groups** — 95% of the time  
✅ Use NACLs only when:
- You need **broad IP-based access blocks** (e.g., blacklist IP ranges)
- Compliance requires **explicit subnet-level deny rules**

❌ Don’t overuse NACLs — they add complexity and are hard to audit  
❌ Don’t try to use NACLs for app-level logic — use SGs


### Hands-On – Security Group for SSH Only

> Create a security group that only allows port 22 (SSH) from your own IP.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to **VPC → Security Groups → Create security group**
3. Open SSH port 22 to your own IP (if you don't know it, google `What is my IP`)
4. Outbound: Leave default (allow all)
5. Create an EC2 instance, hook it up to that Secrutiy Group and test SSH connect
6. Once it worked, terminate the EC2 instance again to save cost

### 🔌 PrivateLink & VPC Endpoints

**VPC Endpoints** let you privately connect to AWS services without using public IPs or internet gateways.

| Type                | Description                                           |
|---------------------|-------------------------------------------------------|
| **Interface Endpoint** | Creates a private ENI in your subnet to access AWS services like S3, DynamoDB, Secrets Manager, etc. |
| **Gateway Endpoint**   | Used specifically for S3 and DynamoDB (route table-based) |
| **PrivateLink**        | Lets you access services across accounts/VPCs privately over AWS backbone |


#### ✅ When to Use VPC Endpoints / PrivateLink

- You want **private connectivity** to S3, DynamoDB, or internal APIs
- You have strict **security/compliance** (no internet access allowed)
- You're building **SaaS or service mesh** across accounts

❌ Avoid if your architecture doesn’t require strict network isolation — endpoints can add cost and complexity.

### 🏢 Centralized Network Management in an Organization

In multi-account environments, especially with AWS Organizations, it's a best practice to **centralize VPC creation and control** in one account — usually a dedicated **network account**.

#### 🧠 Why Centralize Networking?

| Reason                             | Benefit                                           |
|------------------------------------|--------------------------------------------------|
| 🔐 Security                        | Central control of routing, egress, peering      |
| 🛠 Simplicity                      | One place to manage IGWs, NATs, VPNs, TGWs       |
| 🧩 Service connectivity            | Share VPCs with other accounts via **RAM**       |
| 💸 Cost efficiency                 | Share expensive resources like NAT Gateways      |
| 🧪 Better observability            | Flow logs, inspection, firewall in one place     |

### 📌 What Belongs in the Network Account?

| ✅ Centralized Things             | ❌ Should Stay Account-Local              |
|----------------------------------|-------------------------------------------|
| VPCs and Subnets                | Lambda network configs                    |
| Transit Gateways, NAT Gateways | ECS/EKS task-specific VPCs                |
| Route 53 private hosted zones   | App-specific internal DNS                 |
| VPC Peering/Sharing             | Temporary dev VPCs                        |

> ✅ **Share**, not duplicate — use **AWS Resource Access Manager (RAM)** to share subnets/VPCs with sandbox/dev/test accounts.

### Best Practices for Org-Wide Network Management

✅ Designate one **network account per org**   
✅ Remove the default VPC (ideally on a centralized mechanism) on each account   
✅ Share subnets using **AWS RAM**, not manual peering where possible  
✅ Apply **centralized firewall, flow logs, and NAT billing** in the network account  
✅ Use **SCPs** to prevent rogue VPC creations in non-network accounts   
❌ Avoid NACL if possible, only use Secruity Groups   
❌ Don’t manage networking piecemeal per account — you’ll lose visibility and security

## AWS Resource Access Manager (RAM)

**AWS RAM** allows you to **securely share AWS resources** between AWS accounts within your Organization — without needing to copy or duplicate infrastructure.

### Key Features

- 🔗 Share VPCs, subnets, Route 53 zones, Transit Gateways, and more
- 🧑‍🤝‍🧑 Works with **AWS Organizations** for easy multi-account setup
- 🔐 You control which accounts/OUs get access to what
- 🔄 Recipients can **use** the resource, but **not manage** it (unless explicitly allowed)
- 💡 Crucial for **centralized network, security, and DNS patterns**

### 🔄 Typical Use Cases

| Use Case                               | Resource Shared                       |
|----------------------------------------|----------------------------------------|
| Central network account                | VPCs and subnets                       |
| Shared DNS across accounts             | Route 53 private hosted zones          |
| Shared NAT or Transit Gateway infra    | TGWs, VPNs, etc.                       |
| Shared license/configs (Windows, etc.) | License Manager, Directory Service     |

### Hands-On – Central VPC Setup in `network` Account

> In this lab, you will provision the earlier created **shared VPC** in the `management/network`.

We won't deploy into it just yet, but here's how you’d share it via **AWS Resource Access Manager (RAM)**

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to **RAM → Create Resource Share**
3. Resources: Choose the VPC we created earlier and add the `sandbox` as principal

Now other accounts (e.g., `sandbox/test`) can deploy EC2, Lambda, ECS tasks into your centralized VPC **without owning it**.

### Best Practices

✅ Use RAM to **centralize infra**, not duplicate it  
✅ Only share **readily consumable** resources (e.g., subnets, zones — not IAM roles)  
✅ Use **OU-based sharing** for long-term manageability  
✅ Combine with **SCPs** to limit subnet/VPC creation outside network accounts  
❌ Don’t share resources across accounts unless absolutely needed — prefer **API-based access** where possible

## Elastic Load Balancers (ELB)

**Elastic Load Balancing** automatically distributes incoming traffic across multiple targets (e.g., EC2, containers, Lambda) in one or more AZs.  
It ensures **high availability**, **fault tolerance**, and enables **auto scaling**.

### Key Features

- 🔁 Distributes traffic across **multiple instances or services**
- 📡 Supports **health checks** for intelligent routing
- ⚙️ Integrates with:
  - EC2 Auto Scaling Groups
  - ECS, EKS, and Lambda
  - WAF, CloudFront, and Global Accelerator
- 🔐 Supports **HTTPS termination** (via ACM), **sticky sessions**, and **cross-zone balancing**
- 📊 Fully monitored via CloudWatch and ELB access logs

### 🧩 Types of Load Balancers

| Type                     | Use Case                                      |
|--------------------------|-----------------------------------------------|
| **Application (ALB)**    | HTTP(S) traffic, routing by path, host, header |
| **Network (NLB)**        | TCP/UDP traffic, ultra-low latency, static IP |
| **Gateway Load Balancer**| Appliance-style traffic forwarding (e.g. firewalls) |

✅ All support **Auto Scaling**, **multi-AZ**, **integration with VPCs**

### ❓ When to Use Which

| Scenario                                  | Recommended LB Type   |
|-------------------------------------------|------------------------|
| Web apps, REST APIs                       | ALB (ISO/OSI L7)       |
| Gaming, real-time streaming, low latency  | NLB (ISO/OSI L4)       |
| Transparent security appliances           | GWLB                   |
| Lambda-based backend                      | ALB                    |
| Static IP requirement                     | NLB                    |

> ✅ For 90% of typical web use cases, **ALB** is the right choice    
> ❌ Don’t use NLB unless you **need raw TCP** or **static IPs** on the Load Balancer   

### Hands-On – Auto Scaling + Load Balancer 

> In this lab, you’ll add an **ALB** to the **Auto Scaling group** in `sandbox/test`.

#### Prerequisites / Labs done earlier

- Auto Scaling group with EC2 (created earlier in `sandbox/test`)
- A **Security Group** that allows **HTTP (port 80)**

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. In `sandbox/test` account: Create Target Group to `HTTP Port 80` and use the default VPC's **subnets**
3. Health check path: `/`
4. Go to **EC2 → Auto Scaling Groups**
5. Select your existing group and add **Target Group**
6. Update launch template to include a **user-data startup script** with a basic web server (e.g., `yum install -y httpd`)
7. In the **Security Group** done earlier to allow SSH, also allow now Port 80 and append it to the auto-scaling group
8. Create an **Application Load Balancer** that is `Internet-facing` and put it into the public subnet
9. Listener: HTTP:80 → Forward to your target group
10. Get the **DNS name** of the Load Balancer (e.g., `sandbox-alb-123456.elb.amazonaws.com`)
11. Open in browser — it should reach your EC2 instances
12. If that worked, destroy / terminate the load balancer as well as the auto-scaling group

✅ You now have true **auto-scaled, load-balanced EC2 infrastructure**  

### Best Practices

✅ Use **ALB** for most app and API workloads  
✅ Always attach **health checks** to target groups  
✅ Use **HTTPS with ACM** for production (via HTTPS listener)  
✅ Place LBs in **at least 2 AZs** for HA  
✅ Monitor with **CloudWatch, ALB logs, and AWS X-Ray**  
❌ Don’t mix private and public subnets in the same LB unless intentional

## AWS Direct Connect

**AWS Direct Connect (DX)** provides a **dedicated network connection** between your on-premises data center or office and AWS.

It’s designed for **low-latency, high-throughput**, and **secure hybrid architectures**, bypassing the public internet entirely.

### Key Features

- 🔌 Establishes **private, dedicated fiber connection** to AWS
- 🚀 Provides **more consistent performance** than VPN over internet
- 🔐 Traffic stays off the public internet (more secure, lower jitter)
- 🌐 Can connect to **one or multiple AWS VPCs/regions**
- 💰 Reduces **data transfer costs** compared to internet traffic
- 📡 Available in **Direct Connect locations** worldwide
- 🧩 Integrates with:
  - **Virtual Interfaces (VIFs)**
  - **Transit Gateways**
  - **VPCs** via virtual private gateway or TGW attachments

### 🧭 When to Use Direct Connect

✅ Ideal for:
- Enterprises with **hybrid cloud or data center** connectivity needs
- Low-latency apps (e.g., financial trading, medical imaging)
- **Massive data transfers** (e.g., backups, video rendering)
- Compliance or contracts that forbid public internet routing

### 🧱 Direct Connect Setup Concepts

| Term               | Description                                           |
|--------------------|-------------------------------------------------------|
| **LOA-CFA**        | "Letter of Authorization / Connecting Facility Assignment" – document for colocation provider |
| **Virtual Interface (VIF)** | Logical network overlay (private or public)        |
| **Public VIF**     | Access to AWS public services like S3, DynamoDB       |
| **Private VIF**    | Access to VPC via private IP                          |
| **Transit VIF**    | Connect to Transit Gateway to reach multiple VPCs     |

> Most orgs use **Private VIF** or **Transit VIF** for routing into VPCs securely.

### ❌ When Not to Use

- ❌ You just need secure access — use **Site-to-Site VPN** instead
- ❌ You’re dealing with light or inconsistent workloads
- ❌ You’re not near a DX location (colocation cost adds up)

### Best Practices

✅ Use **DX + VPN** together for high availability  
✅ Monitor with **CloudWatch + VPC Flow Logs**  
✅ Use **Transit Gateway + DX** to scale across multiple VPCs  
✅ Get help from an AWS Partner if colocation or BGP is new to your team  
❌ Don’t over-engineer with DX if your latency + throughput needs are modest

## Route 53

**Amazon Route 53** is a **highly available and scalable DNS service** that lets you route traffic to AWS and external resources using domain names instead of IPs. You can also register domain names directly in Route 53.

It also supports **health checks**, **routing policies**, and **domain registration**.

### Key Features

- 🌐 **DNS service** for public and private zones
- 🧭 Built-in support for:
  - A, AAAA, CNAME, MX, TXT, NS, SRV, PTR records
- 🧠 **Smart routing policies**:
  - Simple, Weighted, Geolocation, Failover, Multi-value
- 🔒 Can create **private hosted zones** for internal VPCs
- 🔗 Deep integration with:
  - ELB, CloudFront, API Gateway, S3 static websites, etc.
- ⚙️ Optional **health checks** to redirect traffic automatically if targets fail

### 🤔 Difference Compared to External DNS

Most external DNS providers (e.g., GoDaddy, Cloudflare, Namecheap) can only route to **IP addresses** or **CNAMEs** — they are unaware of AWS internals.

Route 53 is different:

| Feature                        | External DNS             | Route 53                           |
|-------------------------------|--------------------------|-------------------------------------|
| Alias records to AWS services without a static IP | ❌ No                     | ✅ Yes (auto-managed internally)     |
| Understands CloudFront/S3     | ❌ No                     | ✅ Yes (name-based integration)      |
| Supports AWS region-aware DNS | ❌ No                     | ✅ Yes (latency & geo routing)       |
| Direct API for infra-as-code  | ⚠️ Varies                | ✅ Fully supported via CloudFormation/Terraform |
| Private DNS zones | ❌ No (or paid add-on)  | ✅ Yes |
| Native health check failover  | ❌ Usually external-only  | ✅ Integrated into routing policies |

### 💡 Example: A Record to CloudFront?

Normally, an **A record (alias)** must point to a static IP. But:
- **CloudFront**, **ALBs**, and **S3 static websites** don’t have static IPs
- Instead, AWS gives them a **DNS name** (e.g., `d123.cloudfront.net`)

Route 53 allows **alias A-records** that point directly to these resources:
```text
www.example.com → A (alias) → CloudFront distribution
```
✅ You don’t need to track DNS names or IPs manually   
✅ If the target service changes its IP behind the scenes → DNS still resolves correctly   
✅ No TTL or caching issues   

### Best Practices

✅ Use alias records for AWS resources instead of CNAMEs   
✅ Prefer latency-based or weighted routing for global apps   
✅ Create private hosted zones for VPC-internal services   
✅ Use health checks for automatic failover scenarios   
❌ Don’t try to manually map dynamic AWS endpoints via external DNS — it’s brittle and error-prone   

## AWS Certificate Manager (ACM)

**AWS Certificate Manager** helps you provision, manage, and deploy **SSL/TLS certificates** for use with AWS services — all without manual CSR generation, renewal, or uploading.

### Key Features

- 🔐 Free **public SSL certificates** for use with:
  - **CloudFront**
  - **ALB / NLB**
  - **API Gateway / App Runner**
- 🔄 **Automatic renewal** of public certs issued by Amazon
- ✅ Supports **private certificates** with ACM Private CA (paid)
- 📦 Easy integration with:
  - Route 53 (auto-validation)
  - ELB, CloudFront, API Gateway, etc.
- 🛂 Supports **domain validation (DNS or Email)**

> Note: ACM certificates **must be in us-east-1** for use with **CloudFront**. Other SSL can be in the region where the services are.

### 🌐 Using ACM with Route 53 vs External DNS

| Step                          | Route 53                           | External DNS                     |
|-------------------------------|-------------------------------------|-----------------------------------|
| DNS validation setup          | ✅ Automatic                       | ❌ Manual                         |
| TXT record creation           | Auto-created by ACM                | You must copy/paste to external  |
| Cert issuance speed           | Fast (minutes)                     | Slower (depends on DNS TTL)      |
| Auto-renewal + re-validation  | ✅ Fully automatic                  | ⚠️ Manual validation every 13 months |
| Best for                      | Full AWS-managed domains           | Legacy or externally-hosted DNS  |

---

#### ✅ Route 53 Advantage

If your domain is in Route 53, ACM can:
- Auto-generate the DNS validation record
- Auto-validate it behind the scenes
- Auto-renew the cert with **no action required**

> This makes it ideal for workloads in CloudFront, ALB, API Gateway — especially for production HTTPS setups.

#### ❌ External DNS Trade-offs

If your domain is managed outside AWS:
- You’ll need to manually create **TXT validation records**
- These must be correct and **propagate DNS** properly
- Every **renewal cycle (approx. annually)** will require re-validation unless your DNS supports **API automation**

> It's not a blocker, but it **adds friction and risk of expiry** if you miss a renewal.

### Best Practices

✅ Use **Route 53 + ACM** together for zero-touch SSL  
✅ Always use **DNS validation** (not email — email is fragile)  
✅ For CloudFront: request certificates in `us-east-1`  
✅ Enable **CloudWatch alarms** for expiring certs  
✅ Rotate **private certs** (ACM Private CA) on tighter schedules if used internally  
❌ Don’t try to upload Let's Encrypt certs to ACM — it's possible, but manual and misses out on automation

## Amazon API Gateway

**Amazon API Gateway** is a fully managed service to build, publish, secure, and monitor APIs.  
It acts as the **front door** for applications to access Lambda, EC2, or any HTTP backend.

### Key Features

- 🌐 Create **REST**, **HTTP**, and **WebSocket** APIs
- 🔐 Native auth integrations: **Cognito**, **IAM**, **API keys**
- 📊 Built-in **throttling**, **rate limiting**, and **metrics**
- 🔄 Caching, request/response transformation, and validation
- ⚙️ Integrated with Lambda, VPC Link, Step Functions, and more
- 💰 Pay per call — no idle costs

### 🔁 REST vs HTTP vs WebSocket APIs

| Feature                     | REST API                        | HTTP API                         | WebSocket API                    |
|-----------------------------|----------------------------------|-----------------------------------|----------------------------------|
| Launch year                 | ~2015                           | ~2020                            | ~2019                            |
| Designed for                | Full control, legacy apps       | Lightweight, modern apps         | Real-time, bidirectional comms   |
| Cost                        | 💸 Higher                       | 🟢 70–80% cheaper                 | Varies (per connection + msg)    |
| Features                    | ✅ Caching, transforms, stages   | ✅ Simpler, faster, fewer features | 🔄 Persistent WebSocket channels |
| Auth support                | ✅ IAM, Cognito, Custom, API Key | ✅ IAM, Cognito                   | ✅ IAM, Custom                    |
| Route matching              | Method + path                   | Path-based only                  | Message-based via routeKey       |
| Use Case Example            | Enterprises, legacy REST APIs   | Serverless apps, microservices   | Chat apps, gaming, notifications |

### 🤔 When to Use Which

| Use Case                              | Choose                  |
|---------------------------------------|--------------------------|
| Modern microservice, Lambda backend   | ✅ HTTP API              |
| Public-facing legacy REST API         | ✅ REST API              |
| You need request mapping, caching     | ✅ REST API              |
| Budget-sensitive, simple APIs         | ✅ HTTP API              |
| WebSocket chat, game, IoT updates     | ✅ WebSocket API         |
| You just need a URL for Lambda        | ⚠️ Consider Lambda URL   |

### 🔐 Integrating with Cognito

API Gateway supports Cognito for:
- 🧑‍💻 User authentication (via user pools)
- 🎟️ OAuth2 access control
- 🔐 Custom authorizers

✅ Great for:
- Adding login/registration to frontends
- Protecting APIs with bearer tokens
- Federated access with Google/Microsoft/SSO

> You define an **authorizer** in API Gateway and connect it to a **Cognito User Pool**

### 🧠 API Gateway Concepts Explained

API Gateway may look simple from the outside, but under the hood it has **multiple configuration layers** — understanding them helps you avoid "why is this not working?" moments.

#### 📦 Deployment & Stages

- **Deployment**: A snapshot of your current API config (routes, integrations, etc.)
- **Stage**: A named version of your deployed API (like `dev`, `test`, `prod`)
- You can:
  - Deploy the same API to multiple stages (e.g., dev vs prod)
  - Configure logging, throttling, variables *per stage*

> 🔁 Every time you change a method or integration, you need to **redeploy** to apply it.

#### 🧩 Request Handling Flow (REST APIs)

```text
Client → Method Request → Integration Request → Lambda or HTTP backend
                          ↑                  ↓
                 Method Response ← Integration Response
```
🔹 **Method Request**
- Define:
    - Required query strings
    - HTTP headers
    - Request validators
    - Optional API keys or Cognito authorizers

🔹 **Integration Request**
- Set up how API Gateway forwards the request to:
    - Lambda
    - HTTP backend
    - AWS service (e.g., SQS, DynamoDB)
- Can include:
    - Request mapping templates (convert query/body into a JSON payload)
    - Path variables, headers, and more

🔹 **Integration Response**
- Handles the raw response from the backend
- You can:
    - Extract values (e.g., HTTP status, JSON fields)
    - Map them to friendly responses

🔹 **Method Response**
- The final format your user sees
- Set:
    - Status codes (e.g., 200, 400, 500)
    - Response headers
    - Response models

### 🔑 Parameter Types

| Type                 | Where It Appears           | Example                            |
| -------------------- | -------------------------- | ---------------------------------- |
| **Path parameter**   | Inside URL path            | `/user/{id}` → `/user/123`         |
| **Query parameter**  | After `?` in URL           | `/user?id=123`                     |
| **Header parameter** | Inside request headers     | `Authorization: Bearer <token>`    |
| **Request body**     | For POST/PUT payloads      | `{"name": "Alice"}`                |
| **Stage variable**   | Set per stage              | `env = dev`, used in mappings      |
| **Model schema**     | Optional validation schema | Define expected structure for body |

### ✅ Tip for Debugging
If something fails:
- Check logs in CloudWatch
- Look at the integration request mapping
- Validate you're calling the correct stage URL
- Check if you re-deployed after changes

### Hands-On – My First REST API (w/ Required Query Params)

> We’ll create a **REST API** with a GET endpoint `/log`, that accepts required query parameters and passes them to your existing Lambda function (`log-step-input` from earlier labs).

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**
2. Open API Gateway and create a REST-API
3. Create Resource and Method
4. Go to the lambda from earlier and add it as integration. 
5. Back on the API-GW select GET method → Click **Method Request**
6. Under **Request Validator** → Choose `Validate query string parameters`
7. Under **URL Query String Parameters**:
   - Add `user` → Required ✅
   - Add `msg` → Required ✅
8. Click `Actions → Deploy API`
9. Stage: `dev`
10. Copy the **Invoke URL** and test it

Example full URL:
```bash
curl "https://abc123.execute-api.region.amazonaws.com/dev/log?user=alice&msg=hello"
```
✅ Check CloudWatch Logs for the Lambda → It should print the event with query strings.   

### Best Practices

✅ Use HTTP API by default — it's faster, simpler, and cheaper   
✅ Only use REST API when you need:   
- Request mapping templates
- Response transformation
- Advanced stages and caching:
    - ✅ Protect APIs with Cognito, IAM, or Custom authorizers
    - ✅ Set rate limits and quotas
    - ❌ Don’t expose Lambda APIs without auth for sensitive use cases

## Lambda URL

**Lambda Function URLs** provide a **built-in HTTPS endpoint** for your Lambda function — no API Gateway required.
> They’re great for simple use cases or internal tools, but limited in control and security compared to API Gateway.


### 🧠 What It Is

- An **auto-generated HTTPS endpoint** (e.g., `https://abc123.lambda-url.eu-central-1.on.aws/`)
- Bound directly to **one Lambda function**
- Can be publicly accessible or restricted to **IAM-authenticated callers**
- Supports **CORS** and **query/body parameters**

### ✅ Use Cases

| Scenario                          | Notes                                       |
|-----------------------------------|---------------------------------------------|
| Quick internal scripts or webhooks| Easy to call from internal systems          |
| CI/CD triggers or Slack bots      | Good for event-based utilities              |
| Private backend services          | When secured with IAM or VPC access         |
| MVPs, demos, prototypes           | Skip full API Gateway setup                 |


### ❌ Limitations / When to Avoid

| Limitation                         | Why It Matters                              |
|------------------------------------|----------------------------------------------|
| ❌ No **rate limiting**, caching, or stages | No throttling or API versioning             |
| ❌ No **custom domain** support    | You're stuck with the AWS-generated URL     |
| ❌ No fine-grained **authz** options | Only supports IAM auth or no auth           |
| ❌ Limited logging/debugging       | No built-in logging like API Gateway stages |
| ❌ No WAF/WAFv2 or Shield support  | Can't front with extra edge security         |

### 🤔 Summary

✅ Use **Lambda URL** for:
- Fast, direct access to a Lambda
- Lightweight internal APIs or one-off tools

❌ Avoid for:
- Public-facing production APIs
- Anything that requires auth, caching, throttling, or observability

> Use **API Gateway** instead when you need real control over traffic, security, and scaling.

## AWS AppSync

**AWS AppSync** is a managed **GraphQL API service** that lets you request exactly the data you need — no more, no less.  
It simplifies backend data access by combining **multiple sources into a single API endpoint**.

### Key Features

- 📦 Fully managed **GraphQL endpoint** with built-in scalability
- 🧩 Integrates with:
  - DynamoDB (ideal for serverless)
  - Lambda
  - RDS (via Data Source Mapping)
  - Elasticsearch/OpenSearch
  - HTTP APIs
- 🔄 Real-time updates via **GraphQL subscriptions** (WebSocket-based)
- 🔐 Built-in auth options:
  - API key
  - IAM
  - Cognito
  - Lambda authorizers
- 📝 Auto-generates schema from DynamoDB tables
- ⚙️ Request/response **mapping templates** for full control
- 📊 Built-in caching, batching, and observability

### 🔄 AppSync vs. API Gateway

| Feature                            | AppSync (GraphQL)                      | API Gateway (REST/HTTP)              |
|------------------------------------|----------------------------------------|--------------------------------------|
| API Style                          | GraphQL (one endpoint)                 | REST, HTTP, WebSocket (multi-path)   |
| Frontend flexibility               | ✅ Yes (query only what you need)      | ❌ Fixed endpoints and payloads       |
| Real-time subscriptions            | ✅ Built-in                            | ⚠️ Requires WebSocket setup manually |
| Multiple backend sources per query | ✅ Built-in resolvers                  | ❌ Manual orchestration (or StepFn)  |
| Ideal for                          | Mobile/web apps with data flexibility | Backend systems, APIs, microservices |
| Cost                               | Per query + real-time connection time  | Per request (and payload size)       |
| Auth methods                       | IAM, Cognito, API Key, Lambda Auth     | IAM, Cognito, Custom, API Key        |

### ✅ When to Use AppSync

- You’re building a **frontend-heavy app** (web/mobile) that needs:
  - Multiple resources in one request
  - Partial/flexible data selection
  - Real-time updates
- Your data lives in **DynamoDB**, **Lambda**, or **OpenSearch**
- You want to simplify client-side data logic and reduce overfetching

### ❌ When Not to Use AppSync

- You’re exposing **simple, CRUD-style REST APIs**
- You want **fine-grained control** over routing, throttling, or integrations
- You need **binary payloads** or large file uploads
- You already have a robust REST backend — no need to add GraphQL

### TL;DR

| Use AppSync for:         | Use API Gateway for:               |
|--------------------------|------------------------------------|
| Frontend-focused apps    | Service-focused backends           |
| Real-time, multi-source  | Simple HTTP/REST integrations      |
| Flexible data queries    | Predictable, versioned REST routes |

> AppSync is a **powerful abstraction layer**, but don't add GraphQL just because it’s new.  
> If REST is working well — stick with it.

### Best Practices for Using AppSync

✅ GraphQL encourages flexibility, but you still need a solid API schema. Avoid exposing too much control to the client too early.   
✅ Mapping templates (VTL) can be powerful for DynamoDB, but also verbose. If logic is complex, consider offloading to Lambda.   
✅ AppSync supports built-in **per-field** caching with TTL — this can reduce load dramatically on backend sources like Lambda or DynamoDB.   
✅ Use **Cognito**, **IAM**, or **Lambda Authorizers** — avoid long-term usage of unauthenticated API keys in production.   
✅ Use GraphQL's built-in ability to fetch **related data in one call**, reducing client-side round-trips.   
✅ Prevent abuse by setting **max depth, complexity, and timeout quotas** to avoid runaway queries.   
✅ WebSockets can be expensive if overused. Enable subscriptions selectively and **close idle clients**.   
✅ Track **latency, errors, cache hit rates**, and field-level execution metrics for tuning performance.   
❌ It’s great for *frontend APIs* — not ideal for file transfer, streaming data, or deeply stateful workflows.   
❌ If your logic becomes hard to trace, consider composing services behind a unified Lambda instead.   

## Amazon EventBridge

**Amazon EventBridge** is a fully managed **event bus** service that connects AWS services, custom apps, and SaaS platforms using an event-driven architecture.

It's ideal for building **loose-coupled**, **scalable**, and **reactive** systems — without writing polling logic or cron jobs.

### Key Features

- 🔁 **Event-driven** messaging with filtering, routing, and fan-out
- 🔌 Native integration with **100+ AWS services**
- 🌍 Supports external SaaS events (e.g., Zendesk, Datadog, Auth0)
- 🔍 Built-in **schema discovery** and registry
- 🕰 Built-in **scheduler** (cron, rate) — replaces EventBridge + Lambda combos for simple tasks
- 🧪 Replay past events for diagnostics or testing
- ✅ Delivers to:
  - Lambda
  - Step Functions
  - SQS/SNS
  - EC2, ECS, Kinesis, etc.

### 🔗 Integration Examples

| Source (Event Producer) | Target (Event Consumer)     |
|--------------------------|-----------------------------|
| GuardDuty                | Lambda (quarantine instance)|
| CodePipeline             | SNS (notify team)           |
| EC2 state change         | Step Function (approval)    |
| SaaS app (Auth0)         | SQS (track login activity)  |
| Security Hub             | EventBridge → Action Flow   |

✅ No polling needed — AWS services emit events automatically

### 🔄 Event Buses vs EventBridge Pipes

| Feature           | EventBridge Bus                      | EventBridge Pipe                          |
|-------------------|---------------------------------------|--------------------------------------------|
| 🧠 Use Case        | General-purpose event routing         | Point-to-point event ingestion pipelines   |
| 🧩 Destinations    | Multiple (fan-out supported)          | One target per pipe                        |
| ⚙️ Processing      | Custom logic in consumer (e.g. Lambda)| Built-in filtering, transformation, enrichment |
| 🪵 Logging         | CloudWatch Events                    | CloudWatch Logs per pipe                   |
| 💰 Cost            | Per event                            | Slightly more for added transformation     |

✅ Use **Buses** for **many-to-many** routing  
✅ Use **Pipes** when you're bridging systems (e.g., DynamoDB → Lambda → SQS) with transformations inline

### 📦 Schema Registry

- 🧬 EventBridge can **automatically detect and register schemas** from incoming events
- You can:
  - Generate strongly typed SDKs from schemas
  - Store schemas in a centralized registry
  - Validate or route based on schema versions

### ⏰ Scheduler

- ✅ Native cron or rate-based scheduling
- ✅ Can invoke:
  - Lambda
  - Step Functions
  - SQS
  - API Gateway
- 💡 Use instead of CloudWatch Events or writing your own cron logic

### 🏢 EventBridge Across the Organization

By default, **EventBridge only routes events within the same AWS account**.  
To send events across accounts (e.g., from `security` to `sandbox/test`), you need to:

1. Use **EventBridge's organization-wide event bus delivery** (if using AWS Organizations)
2. Allow the sender account to **publish** to the receiver’s event bus
3. Deploy the actual **rule** and **consumer logic** in the destination account

#### Use Case

| Account          | Role                                      |
|------------------|-------------------------------------------|
| `security`       | Runs **Security Hub** + GuardDuty         |
| `sandbox/test`   | Runs **Lambda** that reacts to findings   |


### Best Practices for Cross-Account Events

✅ Use organization-scoped delivery over hardcoded account IDs   
✅ Use event filtering at rule level, not in your Lambda   
✅ Keep sensitive actions (e.g., key disabling) isolated in secure accounts   
✅ Log and alert on failed events in both source and destination   
✅ Use custom event buses for app-specific events   
✅ Use EventBridge Scheduler for cron-style workflows   
✅ Secure events using resource-based policies   
✅ Avoid creating “mega Lambda handlers” — route to multiple small functions instead   
❌ Don’t hard-code source/target logic — use events as clean interfaces between components   

## Simple Email Service (SES) & Simple Notification Service (SNS)

AWS provides two core messaging services:

- **SES** = Full email sending service  
- **SNS** = Fan-out publish/subscribe service (supports email, SMS, HTTP, Lambda, SQS, etc.)

While they overlap slightly (SNS can send email) and people often don't know which to use, they’re built for **different communication models**.

### Key Features

#### Amazon SES

- ✉️ Send **transactional or marketing emails**
- 📥 Receive and process inbound emails
- 🧩 Integrates with:
  - Lambda (email processor)
  - S3 (store emails)
  - EventBridge (delivery feedback)
- 💡 Supports **HTML**, attachments, templating, DKIM/DMARC
- 🧪 Use cases:
  - Contact forms
  - App-generated emails (reset links, alerts)
  - Inbound mail parsing

#### Amazon SNS

- 🔔 **Pub/sub messaging system**
- 📣 Fan-out messages to:
  - Email
  - SMS
  - HTTP endpoints
  - SQS
  - Lambda
- 🧩 Supports **filtering by attribute**
- 🧪 Use cases:
  - System alerts (e.g., root usage, failed pipeline)
  - Notifying multiple systems of the same event
  - Firing off actions (e.g., restart Lambda, tag EC2)

---

### ✉️ Similarities (for Email Use)

| Feature                      | SES                    | SNS                         |
|------------------------------|------------------------|-----------------------------|
| Can send email               | ✅ Yes                | ✅ Yes                      |
| Requires verified email      | ✅ Yes                | ✅ Yes                      |
| Sends to multiple recipients | ⚠️ Requires custom code | ✅ via subscriptions       |
| Email reliability            | ✅ High deliverability | ❌ Not built for formatting |
| Bounce/feedback tracking     | ✅ Yes                | ❌ No                       |

---

### 🔄 Differences (Beyond Email)

| Feature                       | SES                           | SNS                          |
|-------------------------------|--------------------------------|------------------------------|
| HTML formatting               | ✅ Yes                         | ❌ No                        |
| Attachments                   | ✅ Yes                         | ❌ No                        |
| SMS / HTTP / SQS support      | ❌ No                          | ✅ Yes                       |
| Inbound email                 | ✅ Yes (SMTP or MX)            | ❌ No                        |
| Message templating            | ✅ SES templates or API        | ❌ No                        |
| Event destinations            | ✅ (for delivery status)       | ✅ (for messages)            |
| Use case                      | Email system                   | Event distribution system    |

✅ TL;DR: Use **SES for real emails**, use **SNS for alerts and automation**

### Hands-On – SNS Alert on Root User Usage

> This lab uses **centralized CloudTrail** to detect and alert on **root user activity** via **SNS email**.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!**
2. Log into the account that has the centralized CloudTrail
3. Create a SNS Topic
4. Subscribe Your Email
5. Open your inbox and confirm the subscription link.
6. Create CloudWatch Log Metric Filter
7. Go to **CloudWatch → Logs → Log groups** and find the log group where **CloudTrail logs are centralized** (e.g., `/aws/cloudtrail/...`)
```json
{ $.userIdentity.type = "Root" }
```
8. Go to **CloudWatch → Alarms → Create alarm**
9. Select the metric you just created and giv it a threshold of `>= 1` within 5 minutes
10.  **Send to SNS topic → `root-alerts`**
11. Simulate Root User Action (Optional/Dangerous)

✅ Your email should receive an alert when any action is performed using the root user.

### Best Practices

✅ Use **SNS for lightweight fan-out alerts**  
✅ Use **SES for email you want humans to read**  
✅ Centralize CloudTrail to detect cross-account behavior  
✅ Always alert on **root user usage** — it should be rare  
❌ Don’t expose SES or SNS without access controls — both can be abused

## Amazon SQS (Simple Queue Service)

**Amazon SQS** is a fully managed **message queueing service** that decouples producers and consumers. It helps build **asynchronous, reliable, and scalable** systems where services don’t need to respond immediately.

It acts like a **buffer** between microservices, serverless functions, or components that operate at different speeds.

### Key Features

- 📦 **Message queueing** — decouple systems without losing messages
- ⏳ **Short** and **Long polling** for efficient consumption
- 🔁 **Dead-letter queues (DLQ)** for handling failed messages
- 🧩 Triggers:
  - Lambda
  - EC2, ECS
  - EventBridge (via rules)
- 🔐 Supports encryption (KMS), IAM policies, VPC endpoints
- 🧪 Two queue types:
  - **Standard queue**: high throughput, at-least-once delivery, unordered
  - **FIFO queue**: exactly-once processing, preserved order

### 🔄 SQS vs SNS – When to Use Which

| Feature                      | SQS (Queue)                            | SNS (Topic)                         |
|------------------------------|----------------------------------------|-------------------------------------|
| Model                        | Pull (consumers poll messages)         | Push (messages pushed to subscribers) |
| Message fan-out              | ❌ Single consumer per message         | ✅ One message → multiple subscribers |
| Use case                     | Decoupling, buffering                  | Notifications, broadcast messaging  |
| Retry / backoff              | ✅ Built-in DLQ & retries              | ✅ Retry for some protocols          |
| Order guarantees             | ✅ FIFO queue support                  | ❌ No order guarantees               |
| Integration with Lambda      | ✅ Via trigger                         | ✅ Via direct subscription           |
| Scalability                  | Very high                              | Very high                           |
| Latency                      | Slightly higher (polling)              | Lower (push)                        |
| Message filtering            | ❌ Only basic filtering (via attributes)| ✅ Advanced attribute filtering      |

### ✅ When to Use SQS

- You want **one message → one processor**
- You need to **buffer** or **throttle** load between systems
- Your consumer might go down or scale slowly
- You want **exactly-once delivery** (FIFO) or delayed processing
- Use cases: job queues, payment processing, background tasks

### ✅ When to Use SNS

- You want **one message → multiple consumers** (fan-out)
- You need **email, SMS, or HTTP** notifications
- You’re building a **pub-sub** or **event-driven** architecture
- Use cases: alerts, broadcast messaging, decoupled APIs

### Best Practices

✅ Use **DLQs** to isolate and debug failed messages  
✅ Use **FIFO queues** only when ordering truly matters (they scale less)  
✅ Add **message deduplication ID** to avoid duplicates  
✅ Encrypt sensitive messages with **KMS**  
✅ Use **visibility timeout** wisely — don’t reprocess too early  
❌ Don’t let queues pile up indefinitely — monitor queue length & age

## AWS WAF & Shield

**AWS WAF (Web Application Firewall)** and **AWS Shield** are security services that protect applications from common web-based attacks and DDoS threats.

They’re designed to work with:
- **CloudFront**
- **ALB / API Gateway**
- **App Runner / Lambda URLs**

### Key Features

#### AWS WAF

- 🔐 Protects against common HTTP exploits:
  - SQL injection, XSS, bad bots, IP blacklists, etc.
- 📦 Built-in managed rule groups for OWASP Top 10
- ✏️ Create custom rules using:
  - IP sets, header match, rate limiting, geoblocking, regex
- ✅ Real-time metrics + logging via CloudWatch
- ⚙️ Integrated with **CloudFront, ALB, API Gateway**, AppSync, and App Runner

#### AWS Shield

- 🛡️ **Shield Standard**: Always-on DDoS protection for free
- 🧠 **Shield Advanced**: Paid service for:
  - Enhanced detection & response
  - 24/7 DDoS incident support from AWS
  - Cost protection from large-scale attacks

### ✅ When to Use WAF & Shield

| Use Case                                  | Notes                                         |
|-------------------------------------------|-----------------------------------------------|
| Public-facing web app or API              | Especially if using ALB, API Gateway, CloudFront |
| Handling sensitive data (auth, billing)   | Extra filtering and visibility is valuable    |
| Must meet compliance (PCI, ISO, etc.)     | Helps tick off security & audit boxes         |
| Already experiencing targeted abuse       | Can react fast with rate-based rules          |
| Multi-region/public high-scale architecture | Especially with CloudFront + Shield Advanced  |

### ❌ When WAF & Shield Are Overkill

| Scenario                               | Notes                                                   |
|----------------------------------------|-----------------------------------------------------------|
| Internal-only apps (no public access)  | ❌ Skip — not exposed to internet-level threats           |
| MVPs or dev/test with no real users    | ❌ Save the cost and complexity                           |
| Behind other trusted security layers   | ⚠️ Consider case-by-case — may be redundant               |
| Your API is already fully private/VPC-only | ❌ WAF can’t even apply unless exposed via Gateway/ALB   |

### 💡 Honest Take

✅ **WAF is powerful**, but it’s not a silver bullet — it filters bad requests, not deeply malicious logic  
✅ **Shield Standard** is *on by default* and good enough for most apps  
🔒 **Shield Advanced** is worth it only for:
- Large companies
- Highly targeted services
- Or apps where **downtime or ransom-level attack cost is high**

❌ Don’t use WAF just to check a box — poorly configured rules can cause **false positives** and break real traffic

### Best Practices

✅ Use **rate limiting rules** early on — they stop basic abuse fast  
✅ Layer **AWS Managed Rules** + **your own rules**  
✅ Log to CloudWatch Logs or S3 for audit trails  
✅ Protect APIs and user input endpoints — don’t bother filtering GET `/favicon.ico`  
❌ Don’t enable every rule group “just in case” — it adds latency and cost

## Bespinians most used Ranking

✅ You cannot operate EC2 in big scale without **VPC**   
✅ **ELB** for any IaaS Services like EC2 and ECS as well as multi-engine Load's (like mixing EC2 with Lambda request handling)     
✅ **EventBrdige** when events are used in multiple workflows at once (especially for different business teams and uses)     
✅ **ACM** for SSL Certificates for public facing URL's   
✅ **Lambda URL** is enough for small integrations or testing purposes but lacks a lot of features that **API Gateway** has   
✅ **SES** for automatic Emails like **registration confirmations** or to process incomming email in an eventbased way   
✅ **SNS** for event-distribution from alarms or when Eventbridge would be overkill, as well for Subscriber Notification patterns  
✅ **CloudFront + S3** for any non-SSR, cloud managed Front-End we develop   
✅ **RAM** to distribute VPC netwworks in a from us managed landing zone environment   
✅ **Route 53** if we are allowed to point the name server from external DNS (or when the domain was registered on AWS)   