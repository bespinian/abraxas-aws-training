# 4. Storage and Data

## Content

- The following services will be explained and focused on:
    - Aurora and RDS 
    - Backup
    - DataSync  
    - DMS 
    - DocumentDB 
    - DynamoDB 
    - ElastiCache 
    - Keyspaces 
    - MemoryDB 
    - Neptune 
    - OpenSearch 
    - QLDB 
    - S3 
    - Timestream 

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## Amazon S3 – Simple Storage Service

**Amazon S3** is AWS’s scalable, durable, and highly available object storage service. 
S3 Buckets are one of the few global services that even influence other accounts in a slight way - by allowing only a unique name, that AWS (not only your account) has **NEVER** seen.

S3 stores files (objects) in **buckets**, and is used for:
- Backups
- Static websites
- Media
- Data lakes
- Logs
- Machine learning inputs
- And more

### Terminology

| Term         | Description                                                       |
|--------------|-------------------------------------------------------------------|
| **Bucket**   | A container for storing objects (like a folder in a file system)  |
| **Object**   | A file + metadata stored in a bucket                              |
| **Key**      | The unique name of an object within a bucket. This is in traditional FS called a filename                      |
| **Prefix**   | A logical folder structure based on key naming (`logs/2024/`). On the UI it will look like a folder but in reality folders do not exist in S3 -> it is only a part of the full object name     |
| **Version**  | A specific revision of an object (if versioning is enabled)       |
| **Storage class** | Determines cost, durability, and retrieval latency for objects  |

### S3 Key Features

| Feature         | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| **Object storage** | Store any file (binary, text, etc.) up to 5 TB                          |
| **Versioning**  | Retain all versions of an object, including deletions                      |
| **High durability**     | 99.999999999% (11 9s) durability across multiple AZs: This means if you store 10,000 objects with Amazon S3, you can on average expect to incur a loss of a single object once every 10,000,000 years      |
| **Server-side encryption** | Encrypt objects at rest with KMS or S3-managed keys              |
| **Lifecycle rules** | Automate transitions between storage tiers or expiration               |
| **Access controls** | Use bucket policies, IAM, and ACLs to manage access                    |
| **Data consistency** | Strong read-after-write consistency (since Dec 2020)                  |
| **Events**      | Trigger notifications or Lambda functions on object operations             |
| **Replication** | Cross-region or same-region to duplicate objects for durability/compliance |

### S3 Storage Classes (Tiers)

S3 supports multiple **storage classes** with different durability, availability, and cost characteristics.

| Storage Class           | Use Case                                         | Key Traits                               |
|--------------------------|--------------------------------------------------|-------------------------------------------|
| **Standard**             | Frequently accessed data                         | High durability/availability, fast access |
| **Intelligent-Tiering**  | Unknown/variable access patterns                 | Auto-moves data between tiers             |
| **Standard-IA**          | Infrequently accessed (but still critical)       | Lower cost, higher retrieval fees         |
| **One Zone-IA**          | Infrequent, non-critical, single AZ              | Cheaper, less resilient                   |
| **Glacier**              | Archive (minutes to hours to access)             | Cheapest long-term, not real-time         |
| **Glacier Deep Archive** | Cold archive (12–48h access time)                | Extremely cheap, rarely used              |

### 🔄 S3 Lifecycle Management

You can define **lifecycle rules** to:
- Move objects between storage classes after a set time
- Expire/delete objects automatically
- Remove incomplete uploads or previous versions

These rules can be applied to multiple meta-data related factors and you can have multiple rules in one bucket. You could for example move items based on pre-fixes, file size or tags.

You can even expire versions instead of the full object and expire only a count of versions.
#### Hands-On – Create a Lifecycle Rule

> This lab will create a lifecycle rule to move files from S3 Standard → Glacier after 30 days, then delete them after 365 days.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to AWS Console → **S3**
3. Create a bucket named `s3-lifecycle-demo`
4. Upload any file (e.g., `test.txt`)
5. In the bucket settings → **Management** → **Lifecycle rules**

✅ Objects will automatically transition and delete based on your rules.

### 🔐 S3 ACLs, Policies and Object Ownership

#### What Are S3 ACLs?

**Access Control Lists (ACLs)** are a legacy method for granting permissions on S3 **buckets and objects**.

They allow you to:
- Grant read/write permissions to specific AWS accounts
- Mark buckets/objects as **public** or **private**

However:

> ⚠️ **ACLs are considered legacy and should be avoided** in favor of **bucket policies** and **IAM policies**.

#### ACL Use Cases (Still Valid Sometimes)

- Granting access to **specific AWS accounts** without using IAM
- Interoperability with **older tools or SDKs**
- Making **public-read** objects for unauthenticated access (e.g., image sharing)

#### What Is a Bucket Policy?

A **bucket policy** is a **resource-based JSON policy** attached directly to an S3 bucket.  
It defines who can access the bucket and what actions they can perform.

> ✅ Bucket policies are the **recommended way to manage cross-account and public access** to S3.

#### How Bucket Policies Work

- Similar to IAM policies, but **attached to the bucket**, not a user or role
- Grant or deny permissions to **principals** (users, roles, accounts)
- Can include **conditions** based on:
  - IP address
  - Encryption settings
  - Requesting account
  - VPC or referer header
  - MFA or time of day

#### S3 Object Ownership

When a user uploads an object to a bucket, **they are the owner** — unless ownership is overridden.  
This used to cause **permission conflicts** when cross-account users uploaded objects.

To solve this, AWS introduced the **Bucket Owner Enforcement** feature.

**🧩 Object Ownership Modes**

| Mode                     | Behavior                                                                 |
|--------------------------|--------------------------------------------------------------------------|
| **Bucket owner enforced** ✅ Recommended | All objects in the bucket are automatically owned by the bucket owner. ACLs are disabled. |
| **Object writer**         | The AWS account that uploads the object becomes its owner               |
| **Bucket owner preferred** | Tries to make bucket owner the owner, but allows exceptions             |

**Why "Bucket Owner Enforced" Is Best**

- ✅ Simplifies access control — no more ACL confusion  
- ✅ Prevents ownership conflicts in **cross-account uploads**  
- ✅ Enables IAM-only permissions (clean, modern)  
- ✅ Required for many org-wide policies to function correctly  

#### How to Enable It

1. Go to your bucket → **Permissions** tab  
2. Find **Object Ownership**  
3. Set to **Bucket owner enforced**  
4. Confirm that **ACLs are disabled**

### 🌐 S3 Static Website Hosting

S3 can host static websites — HTML, CSS, JS — directly from a bucket.

✅ Fast, simple, cost-effective  
❌ Not suitable for secure, scalable production sites

> ⚠️ Obsolete for production: Use **CloudFront + S3** instead. 

#### Hands-On – Host a Static Website with S3

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Create a new bucket: `s3-website-demo`
3. Upload the files pre-defined in this directory:
   - `index.html`
   - `error.html`
4. Go to bucket settings and enable static web hosting.
5. Grant **public read access** since otherwise nobody can access the website:
   - Permissions → Bucket policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::s3-website-demo/*"
    }
  ]
}
```
6. Visit the endpoint URL provided by S3

✅ Your static site is live! (but not secure or scalable — use CloudFront for that in production). Cloudfront will be covered in a later chapter!

### 📣 S3 Events
S3 can generate event notifications when objects are:
- Created
- Deleted
- Updated
- Or failed during upload

You can connect these events to:
- Amazon SNS (notify systems or people)
- Amazon SQS (queue for later processing)
- AWS Lambda (process image, trigger ETL, etc.)

### Best Practices
✅ Use Intelligent Tiering for unknown access patterns   
✅ Enable default encryption (SSE-KMS) on buckets   
✅ Use bucket policies + IAM — avoid ACLs   
✅ Enable versioning + MFA delete for critical data   
✅ Use lifecycle rules to reduce storage costs   
✅ Set up S3 events for workflow triggers   
❌ Don’t allow public access unless absolutely needed   
❌ Don’t use static site hosting for production, Go instead CloudFront (covered later)

## Amazon RDS & Aurora

**Amazon RDS** (Relational Database Service) is a managed service for deploying and running popular relational databases on AWS.  
**Amazon Aurora** is a MySQL- and PostgreSQL-compatible database engine built by AWS for **performance, scalability, and high availability**.

### Key Features

- 🗄️ **Fully managed relational databases**:
  - Supports MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, and Aurora

- 🔄 **Automated backups**:
  - Point-in-time restore
  - Backup retention up to 35 days

- 🧩 **Multi-AZ deployment**:
  - Automatic failover
  - High availability for production workloads

- 🚀 **Read replicas**:
  - Up to 5 (RDS)
  - Up to 15 (Aurora)
  - Useful for offloading read traffic and analytics

- 🔐 **Encryption at rest and in transit**:
  - Integrated with **AWS KMS**
  - SSL/TLS support for secure connections

- 📊 **Monitoring & metrics**:
  - Integrated with CloudWatch
  - Query performance insights (Aurora-specific)

- 🛠️ **Automatic minor version updates** and patching

- 📎 **IAM authentication support**
  - Avoids long-term user/password storage

### 🌊 Aurora vs. RDS

| Feature                   | RDS (MySQL/PostgreSQL)       | Aurora                              |
|---------------------------|------------------------------|-------------------------------------|
| Performance               | Standard                     | Up to 5x MySQL, 3x PostgreSQL       |
| Storage scaling           | Manual (except Aurora)       | Auto-scales up to 128TB             |
| High availability         | Multi-AZ with replicas       | Native, distributed architecture    |
| Read replicas             | Up to 5                      | Up to 15 with low-latency           |
| Pricing                   | Pay-per-instance             | Slightly higher, but more efficient |
| Failover time             | ~1–2 min                     | Typically <30s                      |
| Engine                    | External engines             | AWS-built, compatible with MySQL/PostgreSQL |

✅ Use **RDS** when you want managed versions of traditional databases.  
✅ Use **Aurora** when you need **performance**, **auto-scaling**, or **serverless mode**.

### 🕸️ Aurora Distributed Architecture

Amazon Aurora is built with a **distributed, fault-tolerant, and self-healing storage layer**, designed to separate **compute from storage** and maximize high availability.

There are two layers of distribution you should understand:

#### 🔁 1. Multi-AZ Storage and Compute (Same Region)

Aurora automatically stores your data across **three Availability Zones (AZs)** in a region, with **6 copies of data** (2 per AZ).  
This happens **even if you use only one database instance**.

- ✅ **Durability**: 6-way replication across 3 AZs
- ✅ **Fast failover**: If the instance dies, another in a different AZ takes over
- ✅ **No manual replication setup needed**
- ✅ **Storage layer auto-heals** bad blocks or disks

You can add **Aurora Replicas** in the same region, in different AZs:
- These replicas share the same distributed storage
- Used for **read scaling** and **high availability**

> When failover happens, the **writer role** is moved to a replica in another AZ within seconds (~30s)

#### 🌍 2. Global Databases (Multi-Region)

Aurora Global Database allows you to replicate your database across **multiple AWS regions** — with one **primary region** and one or more **read-only regions**.

| Feature               | Description                                        |
|------------------------|----------------------------------------------------|
| 🌐 **Primary region**    | Accepts reads/writes — source of truth            |
| 🌍 **Secondary regions** | Read-only copies — used for DR or geo-local reads |
| ⚡ **Replication speed**  | Typically <1s latency using dedicated Aurora link |
| 💥 **Disaster recovery** | You can **promote a secondary region** to primary |
| 🧩 **Use cases**         | Multi-region apps, DR, compliance, global scale   |

✅ Aurora replicates data asynchronously between regions, **without affecting performance in the primary region**.  
✅ Reads in other regions are **strongly consistent** after replication.

### Comparison: Multi-AZ vs Global Aurora

| Feature                     | Multi-AZ (within Region)      | Global Aurora (Multi-Region)           |
|-----------------------------|-------------------------------|----------------------------------------|
| Purpose                     | High availability, failover   | Disaster recovery, geo-local access    |
| Latency                     | Milliseconds                  | Typically <1 second                    |
| Writes                      | Single-AZ at a time           | Writes only in primary region          |
| Reads                       | Local & fast                  | Local in remote regions, async updated |
| Failover time               | ~30s                          | Minutes (promotion required)           |
| Use case                    | Prod workloads in one region  | Multi-region apps or regulatory need   |

### ⚡ Aurora Serverless

Aurora Serverless is an **on-demand, auto-scaling** version of Aurora.

- 📈 Scales up/down based on load (in seconds)
- 🧘 Pay only for usage (Aurora capacity units — ACUs)
- 💡 Ideal for:
  - Development and test environments
  - Infrequent, unpredictable workloads
  - Startups or variable-load apps

> ✅ Aurora Serverless v2 offers instant, fine-grained scaling.  
> ⚠️ Not supported for all Aurora features (e.g., global DBs in v1).

###  Hands-On – Launching an RDS Instance

> In this lab, you’ll deploy a basic RDS instance using the AWS Console.

#### Goal

- Launch a **MySQL RDS instance**
- Enable **Multi-AZ** and **encryption**
- Connect via **IAM-authenticated client**

#### Step-by-Step Instructions

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to AWS Console → Search for **RDS**
3. Instance type: `db.t3.medium` or smaller (we will cover instance types in the next chapter)
8. Storage:
   - Allocate 20–50 GB
   - Enable **storage autoscaling**
9. Network:
   - Select default VPC or a dedicated one
   - Make publicly accessible (optional, not best practice but ok for this test)

#### Post-Launch Tasks

- Connect with **MySQL Workbench** or `mysql` CLI
- Set up **IAM authentication** for secure, passwordless login
- Create a **read replica**
- Enable **Performance Insights**
- Turn-Off / delete DB, once finished (save  costs) !!

✅ You’ve now deployed a encrypted RDS instance!

### Best Practices

✅ Use **Aurora** for modern, high-performance workloads  
✅ Use **RDS** for traditional databases needing quick managed hosting or engines that you necessary need but **Aurora** misses    
✅ Always enable **encryption**, **Multi-AZ**, and **backups**  
✅ Rotate credentials via **Secrets Manager** (covered in a later chapter) or **IAM authentication**  
✅ Use **parameter groups** and **option groups** for advanced tuning  
✅ Monitor usage with **CloudWatch**, set up **alarms**  
❌ Don’t expose DBs to public internet unless absolutely required

## DynamoDB

**Amazon DynamoDB** is a fully managed, serverless NoSQL database service optimized for **speed, scale, and high availability**.

It’s used for:
- Key-value and document data
- Microservices
- Event-driven architectures
- Real-time dashboards
- Gaming, IoT, and serverless workloads
- Almost free for any low to medium traffic app

### 📘 Terminology

| Term               | Description |
|--------------------|-------------|
| **Table**          | A collection of items (like a relational table) |
| **Item**           | A row of data in the table (a JSON-like object) |
| **Attribute**      | A field in the item (similar to a column) |
| **Primary key**    | Unique identifier per item; can be simple or composite |
| **Partition key**  | Determines the partition (physical storage location) |
| **Sort key**       | Optional; used to sort/group items with same partition key and is the second part if you want a copmposite key |
| **Index**          | Alternative views of your data for querying (LSI, GSI) |
| **Throughput**     | Read/write capacity (RCU/WCU) or on-demand capacity |

### Key Features

- ⚡ **Single-digit millisecond latency at any scale**
  - Ideal for real-time applications

- 📈 **Scales automatically** with on-demand mode or provisioned capacity

- 🧪 **Built-in ACID transactions**
  - Enables multi-item/multi-table consistency

- 🔁 **Change streams** via DynamoDB Streams for event-driven processing (CDC mechanism)

- 🌍 **Global Tables**
  - Multi-region, active-active (each node can replicate data to other nodes in the cluster) replication

- 🔄 **Automatic backup and restore**
  - PITR (point-in-time recovery) available

- 📊 **Integrated with CloudWatch** for metrics and throttling insight

- 🚀 **DynamoDB Accelerator (DAX)** for microsecond in-memory caching

- 🔐 Integrated with **IAM**, **KMS encryption**, **VPC endpoints**, and **CloudTrail**

### 🔠 Data Format

- Each item is a **JSON-like structure**:
  - Types supported: String, Number, Boolean, Null, Binary, Map (nested), List
  - No strict schema, but all items must include the primary key

Example:
```json
{
  "UserId": "123",
  "Name": "Alice",
  "Score": 42,
  "IsActive": true
}
```

✅ Flexible format for diverse, nested, or sparse data structures

### ⚙️ Modes and Their Benefits

| Mode               | Description |
|--------------------|-------------|
| **Provisioned**          | **Generates constantly costs!** Manually allocate read/write capacity units (RCUs/WCUs). |
| **On-demand**           | **Pay per request. Generates only cost when traffic happens. If no traffic / only a little happens, it is free!** Automatically scales. Best for unpredictable workloads. Should be used as default if no regular / predictable traffic happens (which is more often the case)|
| **Auto scaling**      | **Generates constantly costs!** Automatically adjusts provisioned capacity based on usage. |


✅ Use on-demand for unknown or irregular traffic patterns   
✅ Use provisioned + autoscaling for cost control on known workloads

### Hands-On – My First DynamoDB Table
You'll create a DynamoDB table and insert some items via the console.

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to AWS Console → Search for DynamoDB
3. Create a usertable and we a non-composite primary key that represents an email. We want to use it as  on-demand for cost control.
4. Insert an Item either via cli or management workbench that has 
    - "John Doe" as name 
    - an Age of 30 
    - hobbies column that holds a list of strings. At least coding and party are two of the list values.

✅ You now have a functioning NoSQL table in seconds.

### 🔁 DynamoDB Transactions
DynamoDB supports ACID-compliant transactions:
- Up to 25 actions per transaction
- Can write to multiple items and tables
- Use TransactWriteItems or TransactGetItems

✅ Use transactions when atomic consistency is required   
⚠️ Higher latency and cost than single writes   
⚠️ Most cases are happy with eventually consistency, so no need for ACID

### 🌊 DynamoDB Streams
Streams capture item-level changes in your table:
 - Insert, modify, delete events
 - Available for 24 hours
 - Can be consumed by Lambda for serverless processing
 - Can be integrated in other event-based set-ups next to lambda 

✅ Use for:
- Event sourcing
- Real-time analytics
- Downstream syncs (e.g., Elasticsearch, Kinesis)

### 🔍 Indexes
| Index Type               | Description |
|--------------------|-------------|
| **LSI**          |  an index that has the **same** `hash key` as the table, but a **different** `range key`. A local secondary index is "local" in the sense that every partition of a local secondary index is scoped to a table partition that has the same hash key.|
| **GSI**           | An index with a `hash` and `range key` that can be **different** from those on the table. A `global secondary index` is considered "global" because queries on the index can span all of the data in a table, across all partitions.|

#### Additional differences:
- Local Secondary Indexes consume throughput from the table. When you query records via the local index, the operation consumes read capacity units from the table. When you perform a write operation (create, update, delete) in a table that has a local index, there will be two write operations, one for the table another for the index. Both operations will consume write capacity units from the table.
- Global Secondary Indexes have their own provisioned throughput, when you query the index the operation will consume read capacity from the index, when you perform a write operation (create, update, delete) in a table that has a global index, there will be two write operations, one for the table another for the index*.

⚠️ When defining the provisioned throughput for the Global Secondary Index, make sure you pay special attention to the following requirements:
> In order for a table write to succeed, the provisioned throughput settings for the table and all of its global secondary indexes must have enough write capacity to accommodate the write; otherwise, the write to the table will be throttled.

Management :
- Local Secondary Indexes can only be created when you are creating the table, there is no way to add Local Secondary Index to an existing table, also once you create the index you cannot delete it.
- Global Secondary Indexes can be created when you create the table and added to an existing table, deleting an existing Global Secondary Index is also allowed.

Read Consistency:
- Local Secondary Indexes support eventual or strong consistency 
- Global Secondary Index only supports eventual consistency.

Projection:
- Local Secondary Indexes allow retrieving attributes that are not projected to the index (although with additional cost: performance and consumed capacity units). 
- With Global Secondary Index you can only retrieve the attributes projected to the index.

#### These are the possible searches by index:
- By Hash
- By Hash + Range
- By Hash + Local Index
- By Global index
- By Global index + Range Index

✅ Use GSIs to query your data from different angles. LSI is only used rarely and is more complex to maintain.   

#### 💰 Cost Considerations Indexes
**📑 GSI – Global Secondary Index**   

✅ Great for flexible querying   
✅ You only pay for the indexes you define — no hidden charges   
❌ GSIs consume RCUs/WCUs separately   
❌ Each GSI doubles (or more) your write throughput and storage costs
  - Every write to the base table is replicated to the GSI (if indexed attribute is modified)   

>🧾 Only index what you actually need to query.
Don’t treat DynamoDB like a relational DB with indexes on everything.

**📑 LSI – Local Secondary Index** 

✅ No extra WCU/RCU costs (shares with base table)   
✅ No cost for writes unless you're storing extra projected attributes   
❌ Must be defined at table creation time — not modifiable later   
❌ Storage charges increase if LSIs include non-key projected attributes   

>🧾 LSIs are cheaper than GSIs, but inflexible. Use only when you're confident about your access pattern at design time.

#### Hands-On – My First Secondary Index
> You'll add a GSI to query users by their name

**Step-by-Step**
1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Either by CLI or Go to your Users table → Indexes → Add index
3. Configure a new GSI where the partition key is either the full name or last name (based on the structure you built earlier)
4. Include all attributes (for simplicity)
5. Once it is build, query it by name

✅ You’ve now built a queryable, efficient secondary index.


### 🌍 Global Tables
- Multi-region, active-active replication
- Writes/reads work from any region with eventual consistency
- Handles region failover, local read latency, and DR

> Great for global apps, compliance, and HA across continents

#### 💰 Cost Considerations Indexes

✅ Seamless cross-region availability and latency   
❌ ⚠️ Most expensive DynamoDB feature:
- You pay for writes replicated to every region
- Pay read/write capacity or on-demand costs in every region
- Data transfer between regions adds to cost
> 🧾 Use Global Tables only when multi-region active-active is a business requirement.
For most use cases, read replicas via Streams + Lambda are more cost-efficient.


### ⚡ DynamoDB DAX – Accelerator
- Fully managed, in-memory cache for DynamoDB
- Microsecond response times
- Drop-in SDK replacement (no app refactor)
- Best for:
    - High-read applications
    - Leaderboards, shopping carts, session state

⚠️ Not globally distributed — DAX clusters are region-specific

#### 💰 Cost Considerations DAX

✅ Reduces read costs by offloading requests from DynamoDB   
✅ Cost-effective only for high-throughput read-heavy workloads   
❌ You pay for DAX capacity separately — per node, per hour   
❌ Minimum 3 nodes for production-ready clusters   

> 🧾 Use DAX only when you're reading frequently and need microsecond latency.
For most moderate workloads, on-demand reads + caching layer (e.g., Lambda or ElastiCache) may be cheaper.

### 🔁 DynamoDB Backup & Restore
- Two modes:
  - On-demand backups
  - Point-in-time recovery (PITR) (last 35 days)
- Consistent, non-disruptive
- Stored encrypted in S3 (not visible to you directly)

✅ PITR is highly recommended for critical production data   
✅ Backups can be restored to a new table (not overwrite)

### Best Practices
✅ Use on-demand for new or spiky workloads   
✅ Design access patterns before designing schema   
✅ Use partition keys that evenly distribute load   
✅ Enable PITR and set up CloudWatch alarms for throttling on critical tables   
✅ Avoid large item sizes (>400KB)   
✅ Use DAX if your app is read-heavy and latency-sensitive   
❌ Don’t scan entire tables unless necessary (inefficient)   

## Managed NoSQL Databases (Overview)

This section introduces AWS-managed NoSQL databases **outside of DynamoDB**.  
You likely won't use all of them, but it's important to know **what exists**, **why they exist**, and **when they might come up** in a real-world architecture.

### 🧠 Amazon Neptune

**Amazon Neptune** is a fully managed **graph database** service.

- Supports **property graph (Gremlin)** and **RDF (SPARQL)** models
- Used for **knowledge graphs**, **fraud detection**, **recommendation engines**, and **social networks**

Example query (Gremlin):
```gremlin
g.V().has('person','name','Alice').out('knows')
```
Output: 
```json
{
  "id": "person:123",
  "label": "person",
  "name": "Alice",
  "age": 30
}
```
✅ Ideal for graph-based DB's and Knowledge Graphs
### 📜 Amazon QLDB
**QLDB** is a **ledger database** (the technology is more known as blockchain than ledger technology) — it records **immutable, cryptographically verifiable** history of all changes.
- Great for **audit logs, supply chain, finance**
- Immutable → no update/delete → everything is versioned
- Built-in cryptographic hash chain for tamper detection

Example document:
```json
{
  "VehicleId": "VIN12345",
  "Owner": "Alice",
  "Registered": true,
  "Timestamp": "2024-06-01T12:00:00Z"
}
```
✅ Use QLDB when you need trust and verifiability without building a blockchain.
### ⏱️ Amazon Timestream

**Amazon Timestream** is a purpose-built, fully managed **time series database**.

- Optimized for **timestamped data**: metrics, sensor readings, events
- Automatically moves data between **memory** and **magnetic tiers** for cost efficiency
- Scales to **billions of events per day**
- Fully serverless — no provisioning or scaling required

Example record:

```json
{
  "Time": "2024-06-01T12:00:00Z",
  "Dimensions": {
    "device": "sensor-123",
    "location": "warehouse-1"
  },
  "MeasureName": "temperature",
  "MeasureValue": "22.6",
  "MeasureValueType": "DOUBLE"
}
```
✅ Data is stored as measurements over time, not documents or rows

### 🧩 Amazon Keyspaces (for Apache Cassandra)
**Keyspaces** is a fully managed **Cassandra-compatible** NoSQL database.
- Scalable, distributed, highly available
- Used for **big data, sensor data, IoT, telecom**

CQL (Cassandra Query Language) example:

```sql
SELECT * FROM readings_by_device WHERE device_id = 'sensor-1';
```
Data model:
```json
{
  "device_id": "sensor-1",
  "timestamp": "2024-06-01T12:00:00Z",
  "temperature": 23.7
}
```
✅ Ideal for teams with existing Cassandra expertise moving to AWS.

### 📄 Amazon DocumentDB
**DocumentDB** is a managed **document database** compatible with **MongoDB** APIs.
- Stores data as JSON-like documents
- Scalable, with replica support and fast read performance
- Not actual MongoDB — it uses its own engine behind the scenes

Example document:

```json
{
  "_id": "user_123",
  "name": "Alice",
  "email": "alice@example.com",
  "roles": ["admin", "developer"]
}
```
✅ Use when migrating from or familiar with MongoDB workloads.

### 🔎 Amazon OpenSearch Service
**Amazon OpenSearch** is a managed version of the open-source **Elasticsearch** engine.
- Used for log analytics, full-text search, monitoring, security observability
- Ingest data from **CloudWatch Logs, S3, Lambda, Kinesis**
- Can serve different purposes like being a proper RAG solution for Gen-AI

Example document:
```json
{
  "timestamp": "2024-06-01T12:00:00Z",
  "log_level": "ERROR",
  "message": "Unauthorized access attempt",
  "user": "unknown"
}
```
✅ Use when building a Kibana-style dashboard, search interface, or real-time log monitoring platform.

### 🧠 MemoryDB & ElastiCache
Both are **in-memory databases**, but serve different needs:
#### 💾 Amazon ElastiCache
- Managed **Redis** or **Memcached**
- ⚡ Used for **caching, session state, leaderboards**
- Data is volatile (loss on reboot unless backups configured)
- Pay per node, extremely fast (<1 ms latency)
#### 🧠 Amazon MemoryDB for Redis
- Also Redis-compatible, but with:
  - **Multi-AZ** durability
  - Data persistence
  - Stronger consistency guarantees
- Used when you want **Redis-like** speed + **database reliability**
#### 🧮 MemoryDB vs ElastiCache
| Feature          | ElastiCache for Redis | MemoryDB         |
| ---------------- | --------------------- | ---------------- |
| Purpose          | Caching               | Durable Redis DB |
| HA / Multi-AZ    | Optional              | Built-in         |
| Data persistence | Optional backups      | Always-on        |
| Use case         | Speedy, temporary     | Durable + fast   |
| Cost             | 💰 Lower              | 💰💰 Higher      |

✅ Use ElastiCache when cache loss is acceptable   
✅ Use MemoryDB for stateful Redis-based applications   

## Data Migration

AWS offers multiple services for **migrating data** into or between environments.  
The most commonly used are:

- **DMS** – For databases (structure + data)
- **DataSync** – For files and object storage (e.g., S3, EFS, on-prem NAS)

### 🔄 AWS Database Migration Service (DMS)

#### 🛠 Key Features

- 🔁 Migrate **databases** between:
  - On-prem → AWS (lift-and-shift)
  - AWS → AWS (RDS ↔ Aurora, etc.)
  - Between engines (e.g., Oracle → PostgreSQL)
- 🔍 Supports **schema conversion** when paired with **AWS SCT** (Schema Conversion Tool)
- ⚡ Can perform **ongoing replication** for minimal downtime
- 🎯 Supports both **homogeneous** (same engine) and **heterogeneous** (different engines) migrations
- 🛡 Secure, fault-tolerant, and supports validation modes

#### 💰 Cost

- You pay **per hour** for the replication instance
- Additional charges for:
  - **Storage** used for staging
  - **Data transfer** (between regions or out of AWS)

✅ Relatively low-cost for one-time migrations  
❌ Not ideal for extremely large or continuous syncs of file data

#### ✅ Best Practices

- ✅ Use **Schema Conversion Tool (SCT)** before migrating to a new engine
- ✅ Enable **change data capture (CDC)** for near-zero downtime
- ✅ Run **validation checks** to confirm row counts and data types post-migration
- ❌ Don't use DMS for **large-scale file or object migration** — use DataSync instead

### 🚀 AWS DataSync

#### 🛠 Key Features

- 📂 Migrate **file-based data** at scale:
  - On-prem NAS → S3 or EFS
  - S3 ↔ S3 (cross-region or cross-account)
  - S3 ↔ EFS, FSx, or on-prem
- ⚡ 10× faster than `rsync` or custom tools
- 🔐 End-to-end encryption, data validation, and scheduling
- 🕓 Supports **one-time** or **continuous syncs**
- ✅ Integrates with Storage Gateway and on-prem NFS/SMB systems

#### 💰 Cost

- You pay **per GB transferred**
  - No charge for metadata-only syncs
  - No charge for staging (unlike DMS)
- ✅ Cost scales with usage — good for large file systems
- ❌ Not ideal for frequent small updates (e.g., app databases)

#### ✅ Best Practices

- ✅ Use **DataSync agent** for on-prem transfers (via VM or AWS Snowcone)
- ✅ Use **filters** to exclude unnecessary file types or temp files
- ✅ Use **scheduling** for regular sync jobs (e.g., nightly copy to S3)
- ❌ Don’t use for **structured database migrations** — use DMS instead

### 🆚 DMS vs. DataSync

| Feature                | DMS                              | DataSync                             |
|------------------------|----------------------------------|--------------------------------------|
| Primary Use Case       | Database migrations              | File, folder, object storage sync    |
| Supported Data Types   | Relational data, schemas         | Files, directories, object metadata  |
| Direction              | On-prem ↔ AWS, AWS ↔ AWS         | On-prem ↔ AWS, AWS ↔ AWS             |
| Real-time sync         | Yes (via change data capture)    | Yes (via scheduling or on-change)    |
| Latency-sensitive use  | ✅ (CDC/replication)             | ❌ Better for batch/file movement    |
| Cost model             | Hourly (replication instance)    | Per-GB transferred                   |
| Use for S3 migration   | ❌ Not applicable                | ✅ Primary tool                      |
| Use for RDS migration  | ✅ Primary tool                  | ❌ Not applicable                    |


✅ Use **DMS** for structured **database migrations**  
✅ Use **DataSync** for **file system and object storage** transfers  
❌ Avoid using the wrong tool — they’re not interchangeable!

## AWS Backup

**AWS Backup** is a fully managed, centralized backup service that lets you **define, automate, and monitor** backups across AWS services — and even on-premises.

It supports **scheduled backups**, **lifecycle rules**, **vault encryption**, and **compliance tracking** from a single pane of glass.

### Key Features

- 📅 **Automated backups** based on policies
  - Define frequency, retention, start window, etc.
- 🗃️ **Backup vaults** for secure, encrypted storage
- 🕓 **Lifecycle management**
  - Transition backups from warm to cold storage
- 🔐 **Vault access policies**
  - Control who can restore, delete, or access backups
- 📊 **Centralized dashboard**
  - Monitor backup jobs, failures, and policy compliance
- 🏢 **Organization-wide management**
  - Delegate backup admin to a central account
  - Apply policies across all AWS accounts

### 📦 Available Engines

AWS Backup supports a broad range of services:

- ✅ **DynamoDB**
- ✅ **RDS / Aurora**
- ✅ **EFS**
- ✅ **EC2 volumes (EBS)**
- ✅ **Storage Gateway volumes**
- ✅ **FSx**
- ✅ **S3** (limited preview as of 2024)
- ✅ **Virtual machines** (via AWS Backup Gateway)

❌ It does **not** back up:
- Lambda
- SQS, SNS, or most non-storage services

### 🏢 Org-Wide Usage

With **AWS Organizations**, you can:
- ✅ Set **backup policies** from a delegated admin account
- ✅ Centralize backups across all linked accounts
- ✅ Apply different backup strategies per OU or tag group
- ✅ Store backups in a centralized **Backup Vault**

✅ Combine with **IAM and SCPs** to restrict deletion or policy override

### Hands-On – Backup a DynamoDB Table

> In this lab, you'll create an AWS Backup vault, define a backup plan, and assign it to a DynamoDB table.

#### Step-by-Step

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Go to AWS Console → **AWS Backup**
3. Click **Backup vaults** → **Create backup vault**
4. Select the **KMS key** we created earlier
5. Go to **Backup plans** → Click **Create plan**
6. Rule settings:
   - Frequency: Daily
   - Retention: 7 days
   - Backup window: Default
7. Click **Create plan**
8. Open your **DynamoDB table** (or create one, e.g., `Users`)
9. In the backup plan, click **Assign resources**

✅ Backup will run automatically according to schedule  
✅ You can also run a manual backup from **Backup → Protected resources**

### Best Practices

✅ Centralize backup policies using **AWS Organizations**  
✅ Enable **vault lock** to prevent tampering  
✅ Use **tags** to group resources by workload (e.g., `env:prod`)  
✅ Set lifecycle rules to manage cost  
✅ Enable **notifications** via EventBridge for failed jobs  
❌ Don’t rely on app-layer backups alone for critical data (e.g., EC2 + EBS)

## Bespinians most used Ranking

✅ **S3** as goto file storage + **lifecycle management** for easy cost control   
✅ **DynamoDB** in "on-demand" almost on every case: Streams and advanced features on modern event-based solutions.   
✅ **RDS** for simple migrations of non-critical app or for testing / dev purposes   
✅ **Aurora** for productive relational SQL DB's   
✅ All the **managed DB's** for migrations, if really no re-architecting was allowed / made sense into **DynamoDB**   
✅ We haven't used **Neptune** but for knowledge graph-use cases we would go for it   
✅ **DMS** is a good solution for database migrations from on-prem lift&shift to the cloud, if you don't have other ways / capabilities to transfer. It is expensive though!   