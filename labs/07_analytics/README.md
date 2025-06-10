# 7. Dataengineering and analytics

## Content

- S3 as datalake
- How to build a lake house
- OpenTable Formats
- The following services will be explained and focused on:
    - AppFlow 
    - Athena 
    - EMR 
    - Glue 
    - Kinesis
    - Lake Formation 
    - MSK
    - RedShift
    - Quicksight

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## S3 as Data Lake

Amazon S3 is the core storage layer of modern data architectures in AWS. It's scalable, cost-effective, durable, and integrates with almost every AWS service — making it ideal for a **data lake**.

A **data lake** is a centralized repository that allows you to store **structured**, **semi-structured**, and **unstructured** data at any scale.

But S3 by itself is "just files." To make it powerful for analytics, you pair it with **OpenTable formats** like Parquet, Delta, or Iceberg that add schema and transactional behavior to your data.

### 🧬 OpenTable – What It Is

**OpenTable formats** are open-source file + metadata standards that:
- Bring **schema, partitioning, versioning, and transactions** to files in object storage
- Make S3 **queryable and manageable like a database**, without needing a data warehouse
- Enable multiple engines (Athena, EMR, Redshift Spectrum, etc.) to **query and share the same data** efficiently

#### 🧠 Key Terminology

| Term                    | Meaning                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| **Table Format**         | A metadata + layout standard (e.g., Iceberg, Delta, Hudi)              |
| **Manifest**             | A file that lists the actual data files for a given version or query   |
| **Schema Evolution**     | Ability to add/remove/rename columns over time                         |
| **Partitioning**         | Splitting data into logical folders (e.g., `year=2024/month=06`)       |
| **Snapshot / Versioning**| Point-in-time views of a table (used for rollback or audits)           |
| **Atomicity**            | Guarantees that data writes are "all or nothing"                       |

#### 📦 Common Formats

| Format     | Strengths                                               | Notes                                 |
|------------|----------------------------------------------------------|----------------------------------------|
| **Parquet** | Columnar, compressed, highly optimized for reads        | Used by Athena, Redshift, EMR, Glue    |
| **Delta**   | OpenTable format with ACID, time travel, schema tracking| Created by Databricks, open spec now   |
| **Iceberg** | Netflix-originated format focused on scale + multi-engine | Backed by AWS Athena, Glue, EMR        |
| **Avro**    | Row-based format with schema stored alongside data      | Common for Kafka, streaming pipelines  |

> ✅ **Parquet** is the most commonly used format for data lakes in AWS  
> 🧠 **Iceberg** is the most forward-looking for lakehouse architectures in AWS-native tools

#### 🔄 Backward and Forward Compatibility

| Concept                     | Why It Matters                             |
|-----------------------------|---------------------------------------------|
| **Backward compatibility**  | Can read older versions even after schema change |
| **Forward compatibility**   | Can read new data with added fields         |
| **Schema evolution**        | You don’t need to reprocess old files       |

✅ Good formats like **Iceberg and Delta** are designed to support safe, dynamic schema changes — crucial for long-term data platforms

#### 🪣 What It All Means for S3

Using these formats and patterns turns S3 from a "dump of files" into a **queryable, organized data lake**:

- 🔍 You can use Athena to run SQL directly on S3 files
- ⚙️ Glue can crawl and catalog Parquet or Iceberg tables
- 🏗️ Redshift Spectrum and EMR Spark can all query **the same S3 table**
- 🔁 Schema changes become manageable — not breaking events
- 📊 Storage becomes **analytically useful**, not just archival

> ✅ **Open formats + S3** = an open, scalable lakehouse  
> ❌ Just CSVs in S3 = unstructured chaos that’s hard to query or evolve

### 🧱 Lake Formation (Intro)

**Lake Formation** helps manage **security and governance** of your data lake.

| Feature                      | What It Does                                |
|-----------------------------|----------------------------------------------|
| 📜 Table/column permissions  | Fine-grained access control for S3 tables    |
| 🔐 Central access layer      | Replaces S3 bucket policies or IAM wildcards |
| 🧩 Integrates with           | Athena, Glue, Redshift Spectrum, EMR         |
| 🧠 Manages catalog metadata  | Syncs with Glue Data Catalog                 |

> Lake Formation is optional for small use cases but **essential for multi-user, multi-team lakes**

### 🏠 Lakehouse Pattern on S3

> The **Lakehouse** pattern combines the scalability of a data lake with the features of a data warehouse.

These services are essential (and you will learn just below about every service mentioned here) for a lakehouse architecture:

| Component        | AWS Service                            |
|------------------|-----------------------------------------|
| Data Storage     | S3 with Parquet + Iceberg               |
| Metadata Layer   | Glue Data Catalog / Iceberg             |
| Processing       | EMR, Athena, Redshift Spectrum, Glue    |
| Access Control   | Lake Formation                          |
| BI/Analytics     | Quicksight, Athena, Redshift            |

✅ On S3, this works with:
- Open file formats (Parquet, Iceberg)
- Schema-on-read engines (Athena)
- Structured access control (Lake Formation)

### Best Practices
✅ Use **Parquet + Iceberg** for all structured lakehouse workloads   
✅ Register tables in **Glue Catalog** to make them queryable from **Athena, EMR, Redshift Spectrum**   
✅ Use **Lake Formation** to restrict access by column or user   
✅ Store raw data in one prefix (`/raw/`), and curated data in another (`/iceberg/`)   
❌ Don’t manually manage file layout — let the table format handle it   

## AWS Glue

**AWS Glue** is a fully managed **data integration and ETL (Extract, Transform, Load)** service. It’s designed to prepare and move data for analytics, machine learning, and warehousing.

It plays a central role in **lakehouse architectures**, connecting raw S3 data with structured formats, catalogs, and query engines like Athena or Redshift Spectrum.

### Key Features

- 🔁 **Serverless ETL jobs** with Spark or Python (no infrastructure to manage)
- 📚 **Glue Data Catalog** — centralized schema registry across AWS analytics
- 🔍 **Data Crawlers** — automatically discover schema and partition structure
- 📦 Built-in support for **Parquet, Avro, CSV, JSON**, and **Iceberg tables**
- 👩‍🎨 **DataBrew** — no-code visual data transformation for analysts
- 📊 **Job bookmarks** — avoid reprocessing already-handled data
- 🔐 Integrates with **Lake Formation**, IAM, KMS for access control

### 🔄 Data Integration & ETL

Glue Jobs are used for:
- Ingesting files from S3 or JDBC sources
- Cleaning and transforming data (e.g., deduplication, column rename, type cast)
- Writing data back to S3, Redshift, or RDS
- Creating structured, analytics-ready datasets (e.g., Iceberg tables)

Glue supports two job types:
| Type         | Use Case                        |
|--------------|----------------------------------|
| **Spark (Python/Scala)** | Large-scale parallel ETL               |
| **Python Shell**         | Lightweight scripts or orchestrations |

### 🧪 Glue DataBrew

**DataBrew** is a visual interface to prepare data without writing code — for use cases like:
- Analysts needing to clean CSVs before reporting
- Business teams exploring raw datasets
- Low-code pre-ETL experimentation

| Feature                       | Description                            |
|-------------------------------|----------------------------------------|
| Drag-and-drop interface       | Over 250 built-in transforms           |
| Works with                    | S3, Redshift, RDS, JDBC                |
| Output                        | Cleaned Parquet or CSV files to S3     |
| Usage                         | Per session + job runtime              |

✅ Think of DataBrew as **Excel + [Python Pandas](https://www.w3schools.com/python/pandas/) + AWS-native UI**

### 📚 Glue Data Catalog & Data Crawlers

The **Glue Data Catalog** is a centralized **metadata store** for all your structured data in S3, RDS, Redshift, and other sources.

- Stores **table names, schema, partitions, formats**
- Used by **Athena, Redshift Spectrum, EMR**, and even Quicksight
- Acts as the foundation for **schema-on-read**

#### Crawlers

- Automatically **scan your S3 paths** or JDBC sources
- Detect formats (Parquet, CSV, JSON, etc.)
- Create or update **tables in Glue Catalog**
- Schedule crawlers to keep schemas up to date

> Example: A crawler on `s3://data/sales/` can detect partitioned folders and register them as a proper Athena table

### 🤝 Glue Catalog vs Lake Formation

| Feature                        | Glue Data Catalog                        | Lake Formation                              |
|-------------------------------|------------------------------------------|---------------------------------------------|
| Stores schema + metadata      | ✅ Yes                                   | ❌ Uses Glue underneath                     |
| Access control                | ❌ IAM-only                              | ✅ Fine-grained (table, column, row level)  |
| Integrated with               | Athena, EMR, Redshift, Quicksight        | Same — but with stronger control            |
| Data source awareness         | ❌ Glue doesn’t know about row-level usage | ✅ Tracks access policies + governance     |
| Can exist without             | ✅ Glue can run without Lake Formation    | ❌ Lake Formation requires Glue Catalog     |

✅ Think of:
- **Glue Catalog = Schema registry**
- **Lake Formation = Policy layer**

### Best Practice

✅ Use **Spark jobs** for heavy ETL logic, and **Python shell jobs** for orchestration or lightweight tasks  
✅ Organize S3 data in **partitioned folders** (`/year=2024/month=06/`) for efficient query and processing  
✅ Store data in **Parquet** or **ORC** to reduce scan costs and improve performance  
✅ Use **Job Bookmarks** to process only new data incrementally  
✅ **Tune DPU allocation** for large jobs — default may be too small  
✅ Keep **crawler paths specific** — don't scan full buckets unnecessarily  
✅ Monitor ETL job execution via **CloudWatch Logs** and set **retry policies**  
✅ Separate raw, staging, and curated zones using clear S3 prefixes  
✅ Use **Glue version 3.0+** for best performance and compatibility (including Iceberg)  
❌ Don’t run production ETL off of CSV — convert to columnar formats first  
❌ Don’t hard-code S3 paths or schema — keep dynamic and parameterized


## Amazon Athena

**Amazon Athena** is a **serverless SQL query engine** that allows you to run SQL queries directly on data stored in Amazon S3.

It’s a central part of the **lakehouse pattern**, because it enables fast exploration and analysis of structured or semi-structured data without requiring ETL into a warehouse.

### Key Features

- 🧠 **Serverless SQL** on S3 — no infrastructure to manage
- 📚 Uses **Glue Data Catalog** to reference table schemas
- 💾 Supports **Parquet, CSV, JSON, Avro, ORC, Iceberg** formats
- 🔄 Integrates with:
  - Glue (ETL jobs, crawlers)
  - Redshift (via federated queries)
  - Lake Formation (for permissions)
- 🧊 Full support for **Apache Iceberg** (v3 engine)
- 📊 Output query results to S3 for later use (e.g., Athena → S3 → Quicksight)
- 🔐 Enforce access via IAM + Lake Formation policies

### Common Use Cases

| Use Case                           | Why Use Athena?                          |
|------------------------------------|------------------------------------------|
| Query Iceberg or Parquet in S3     | Fast, cheap SQL access without ETL       |
| Ad-hoc analytics                   | Launch queries without infrastructure    |
| BI dashboards                      | Use Athena as backend for Quicksight     |
| Log & audit analysis               | Search CloudTrail, VPC Flow Logs, ELB logs|
| Explore raw CSVs                   | Quick exploration of raw data            |

### 💡 Notes

- Query cost is **based on the amount of data scanned**, so:
  - ✅ Use **Parquet** instead of CSV
  - ✅ Partition your data logically (e.g., by date, region)
  - ✅ Use **SELECT specific columns** instead of `SELECT *`

- Athena supports **CTAS** (Create Table As Select) and **UNLOAD** for exporting query results

###  Hands-On: Build Your First Iceberg Table in S3

> You’ll define an **Iceberg table on S3** using an existing **Parquet file**, and register it in the **Glue Data Catalog**.

**🗃️ Parquet File Structure**

This is the given parquet file structure of the parquet file attached in this labs directory

| Column Name     | Type       | Example                  |
|------------------|------------|---------------------------|
| `user_id`        | STRING     | `"a3f9-45d1"`             |
| `event_type`     | STRING     | `"login"` / `"purchase"` |
| `timestamp`      | TIMESTAMP  | `2024-06-01 14:23:11`     |
| `region`         | STRING     | `"eu-central-1"`          |
| `amount`         | FLOAT      | `19.99`                   |

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. Create a S3 Bucket as Data lake and upload the parquet file
3. Enable Iceberg Engine in Glue and create an Iceberg Table ontop of this S3 Bucket
4. Built the datalake ontop in a fashion like this with Athena (v3 engine):

```sql
CREATE DATABASE IF NOT EXISTS demo_lake;

CREATE TABLE demo_lake.user_events (
  user_id string,
  event_type string,
  timestamp timestamp,
  region string,
  amount float
)
PARTITIONED BY (region)
LOCATION 's3://<your-bucket>/data/iceberg-demo/'
TBLPROPERTIES (
  'table_type'='ICEBERG',
  'format'='parquet'
);
```
> This creates an Iceberg table layer on top of Parquet files in S3. No need to re-upload the data.

4. Query Table with Athena
```sql
SELECT event_type, COUNT(*) FROM demo_lake.user_events
GROUP BY event_type;
```
✅ You’ve now built a real Iceberg table on S3 — with schema, partitioning, and metadata tracking.
 
## Amazon EMR (Elastic MapReduce)

**Amazon EMR** is a managed big data platform that lets you run large-scale distributed data processing jobs using open-source frameworks like **Apache Spark**, **Hadoop**, **Hive**, **Presto**, and **HBase**.

It's designed for **custom analytics pipelines**, **data transformation**, **machine learning**, and **graph processing** at scale — but requires more operational involvement than newer serverless services.

### Key Features

- ⚙️ Deploys **custom clusters** of EC2 instances optimized for big data
- 🧠 Supports popular frameworks:
  - **Spark**, **Hive**, **Presto**, **Trino**, **HBase**, **Flink**, **Iceberg**
- 💾 Reads and writes directly from **S3**, **HDFS**, or **DynamoDB**
- 📦 Multiple deployment options:
  - **EMR on EC2** (classic, flexible)
  - **EMR on EKS** (container-native)
  - **EMR Serverless** (no infrastructure)
- 🔌 Integrates with:
  - Glue Catalog
  - Lake Formation
  - S3 Iceberg tables
- 📊 Deep control over:
  - Hardware, spot instances, scaling policies, networking
- 💰 Pay-as-you-go model (per node-hour or serverless job runtime)

### Is EMR Still Worth It?

**Yes — but only for specific use cases.**

| Scenario                                       | Use EMR?      | Why                                             |
|------------------------------------------------|---------------|--------------------------------------------------|
| Large-scale Spark/Presto/Hive pipelines        | ✅ Yes        | Full control over version, config, tuning       |
| Real-time stream processing (e.g., Flink)      | ✅ Yes        | Lower latency than Glue or Athena               |
| ML/graph data processing at scale              | ✅ Yes        | Libraries like MLLib, GraphX, SageMaker hooks   |
| You need hybrid deployment (EC2 + on-prem)     | ✅ Yes        | Flexible architecture                           |
| You want "set-and-forget" serverless pipelines | ❌ Use Glue   | Glue is easier, auto-scaling, less to manage    |
| You only run SQL analytics on S3               | ❌ Use Athena | Athena cheaper and simpler                      |
| You want zero-infra orchestration              | ❌ Use EMR Serverless or Glue | No EC2 needed                     |

### 💡 EMR Today

- **EMR on EC2**: Best for long-running, optimized clusters
- **EMR on EKS**: Best for teams already using Kubernetes
- **EMR Serverless**: Best for ad-hoc or event-driven jobs

If you're not managing complex Spark jobs or tuning performance, Glue or Athena likely does the job with less effort.

## Amazon MSK (Managed Streaming for Apache Kafka)

**Amazon MSK** is a fully managed, highly available **Apache Kafka service** on AWS. It eliminates the undifferentiated heavy lifting of deploying and operating Kafka clusters, so you can focus on streaming data and building real-time applications.

### Key Features

- 🧩 Fully managed **Apache Kafka clusters**
  - No need to manage brokers, Zookeeper, patching, or monitoring
- 🔄 Supports **Kafka Connect** and **Kafka Streams**
- 🔐 Integrated with IAM, KMS, and VPC networking
- 📊 Compatible with existing **Kafka producer/consumer clients**
- ⚙️ Automated scaling and replication
- 🧠 Integrates with:
  - Lambda, Firehose, Glue, Flink, Redshift, and more
- 💾 Supports **multi-AZ replication** and **automatic failover**

### ✅ When to Use MSK

| Scenario                                      | MSK Recommended? | Why                                        |
|-----------------------------------------------|-------------------|---------------------------------------------|
| You already use Apache Kafka on-prem           | ✅ Yes            | MSK provides drop-in migration path         |
| Need complex streaming topologies              | ✅ Yes            | Kafka Streams or Kafka Connect integration  |
| Require Kafka-specific features or guarantees  | ✅ Yes            | MSK maintains full Kafka compatibility      |
| Real-time ingestion from many sources          | ✅ Yes            | Low-latency, high-throughput ingestion      |


### ❌ When Not to Use MSK

| Scenario                                    | Better Alternative | Reason                                   |
|---------------------------------------------|---------------------|-------------------------------------------|
| Basic event-driven triggers (fan-out)       | SNS or EventBridge  | Simpler and cheaper                       |
| Stream analytics with low ops               | Kinesis Data Streams| Serverless, native AWS integration        |
| Batch workloads or scheduled ETL            | Glue or DataBrew    | MSK adds unnecessary complexity           |
| Lightweight event ingestion to S3           | Kinesis Firehose    | No infrastructure to manage               |


### 💡 MSK Tips

✅ Use **IAM authentication** with mTLS if security is critical  
✅ Monitor broker health and throughput via **CloudWatch**  
✅ Choose **MSK Serverless** for easier management (no provisioning)  
✅ Use **Kafka Connect** to move data in/out (e.g., to Redshift, S3)

❌ Avoid MSK for **short-lived, low-traffic apps** — startup and maintenance overhead is real, even if AWS manages it

### Best Practice

✅ Use **MSK Serverless** if you don’t need full cluster control — much simpler for most workloads  
✅ Choose the right **partition count** early — it can’t be easily changed later  
✅ Enable **encryption in transit (TLS)** and **at rest (KMS)** by default  
✅ Place MSK in **private subnets** and restrict public access  
✅ Use **IAM authentication with mTLS** or **SASL/SCRAM** for secure client access  
✅ Keep consumer groups healthy and balanced — monitor **lag metrics** via CloudWatch  
✅ Use **Kafka Connect** for moving data between systems (e.g., to S3 or Redshift)  
✅ Set **retention policies** to manage storage costs  
✅ Enable **multi-AZ** for fault tolerance  
❌ Don’t treat MSK like a simple message queue — it’s designed for **streaming and replay**, not just pub/sub

## Amazon Kinesis

**Amazon Kinesis** is a family of services designed for **real-time streaming data** — whether logs, metrics, clickstreams, video, or IoT.  
Unlike batch processing tools, Kinesis enables **low-latency ingestion, transformation, and delivery** of data as it arrives.

### 📘 Terminology

| Term               | Meaning                                                                      |
|--------------------|------------------------------------------------------------------------------|
| **Shard**          | Unit of capacity in a data stream — determines throughput                    |
| **Producer**       | A system or app sending data to Kinesis                                      |
| **Consumer**       | A system (e.g., Lambda, Firehose, KCL app) reading from Kinesis              |
| **Retention**      | Time data is stored in the stream (default 24h, up to 7 days or 365 days for extended) |
| **KCL / SDK**      | Libraries used to read and checkpoint stream data                            |
| **Delivery Stream**| A Firehose stream — abstracts producers and delivery destinations            |

### Key Features

- 🧠 Real-time, low-latency data ingestion
- 📈 High scalability (shard-based)
- 🔄 Supports replay, windowing, and parallel consumers
- 🔁 Serverless integrations with:
  - Lambda (trigger on new records)
  - Firehose (for delivery to S3, Redshift)
  - Glue streaming ETL
- 🔐 IAM + KMS secured
- 📊 Logging and metrics via CloudWatch

### 🔄 Kinesis Data Streams

Used for **custom stream processing** — e.g., real-time logs, app telemetry, fraud detection.

| Feature              | Notes                                |
|----------------------|---------------------------------------|
| Throughput           | Based on number of shards             |
| Retention            | 24h default, up to 365 days           |
| Replay               | ✅ Yes (reprocess past records)        |
| Consumers            | Lambda, EC2, Kinesis Data Analytics   |
| Use case             | Real-time pipelines, custom logic     |

### 📦 Kinesis Firehose

**Fully managed delivery pipeline** — no code, no infrastructure.

| Feature              | Notes                                    |
|----------------------|-------------------------------------------|
| Use case             | Buffer → transform → store (e.g. S3)     |
| Destinations         | S3, Redshift, OpenSearch, custom via Lambda |
| Transformations      | Inline Lambda transforms                 |
| Scaling              | ✅ Fully automatic                        |
| Replay               | ❌ No — data is streamed and dropped      |
| Use case             | Log ingestion, monitoring, ETL loading   |

### 🎥 Kinesis Video Streams

Purpose-built for **real-time video ingestion**.

- Sends raw or encoded video to AWS for:
  - Machine learning (Rekognition, custom models)
  - Storage (for playback or auditing)
- Integrates with:
  - WebRTC
  - GStreamer
  - IoT devices
- Use case: CCTV, drones, baby monitors, etc.

### ⚔️ Kafka vs. Kinesis — Brutally Honest Comparison

| Feature                         | Kafka (MSK)                        | Kinesis                            |
|----------------------------------|------------------------------------|-------------------------------------|
| Model                            | Clustered (MSK or DIY)             | Fully managed serverless            |
| Latency                          | Very low, sub-second               | Slightly higher (~100ms–1s)         |
| Ecosystem                        | Massive (Kafka Streams, Connect)   | Limited to AWS-native consumers     |
| Replay                           | ✅ Yes                             | ✅ Yes (Data Streams only)           |
| Fan-out                          | ✅ Yes                             | ✅ Yes (enhanced fan-out)            |
| Cost transparency                | Complex (per broker, EBS, traffic) | Simple (per shard, per GB)          |
| Start-up complexity              | High                               | Low                                 |
| Ideal for                        | Complex streaming systems          | AWS-native event pipelines          |
| Protocols                        | Kafka protocol                     | AWS SDKs                            |
| Ops overhead                     | Medium (even with MSK)             | Low to none                         |
| Cost for 1 MB/s stream, 24/7     | ~$100–150/month (MSK)              | ~$50–70/month (Kinesis)             |

### ✅ When to Use Kinesis

- You want **AWS-native**, fully managed streaming
- Your workloads are **event-driven or log-based**
- You want **zero maintenance** pipelines
- You stream into S3, Redshift, or OpenSearch
- You’re using **Lambda, Glue, Firehose** directly

### ❌ When to Use Kafka (MSK) Instead

- You need **Kafka Streams**, Connect, or protocol-level control
- You’re integrating with **non-AWS consumers**
- You need **guaranteed ordering + replay + complex topologies**
- You’re migrating an existing Kafka workload

> 🔥 Kinesis is great for 90% of real-time ingestion in AWS.  
> MSK is great for the 10% that needs **deep customization or Kafka-native power** — at the cost of more complexity and expense.

## AWS AppFlow

**AWS AppFlow** is a **fully managed data integration service** that lets you securely transfer data between **SaaS applications** (like Salesforce, Slack, ServiceNow) and AWS services (like S3, Redshift, or EventBridge) — all without writing code.

It’s ideal for organizations that want **low-code automation** for syncing external business data with their cloud systems.

### Key Features

- 🔄 **Bi-directional data flows** between SaaS apps and AWS
- ⚙️ Supports **on-demand, scheduled, or event-driven** flows
- 🧩 Built-in connectors for:
  - Salesforce, Slack, ServiceNow, Zendesk, Google Analytics, and more
- 📦 AWS integration with:
  - S3, Redshift, EventBridge, Honeycode, Lambda, Lookout for Metrics
- 🔐 Supports **field-level encryption**, **filtering**, and **data mapping**
- ✅ Automatically handles:
  - Pagination
  - Error retries
  - Rate limiting
- 🔍 Optionally validate, filter, or transform fields during flow setup

### Best Practices

✅ Use AppFlow when you need:
- Quick, **secure no-code data sync** between SaaS and AWS
- Business data ingestion (e.g., Salesforce → S3 → Athena)
- One-time or periodic reporting ETL flows

✅ Monitor flow health in **CloudWatch Logs**

❌ Avoid for:
- Real-time streaming — use **Kinesis, EventBridge, or custom polling**
- Heavy transformations — use **Glue, Lambda, or Step Functions**

> Think of AppFlow as a **low-friction alternative** to ETL pipelines for SaaS integrations, not a replacement for full-blown data engineering.

## Amazon Redshift

**Amazon Redshift** is AWS’s fully managed **cloud data warehouse (DWH)**. It’s built for **analytics at scale**, allowing you to run fast SQL queries over terabytes to petabytes of structured data.

It supports both **traditional data warehousing** (with internal storage) and **lakehouse-style queries** using S3 via **Redshift Spectrum**.

### Key Features

- 🧠 Columnar, MPP (Massively Parallel Processing) architecture
- 🪣 Supports querying S3 data directly with **Redshift Spectrum**
- 🧩 Integrates with:
  - Glue Data Catalog
  - Quicksight, Athena, SageMaker
  - Lake Formation (via Spectrum)
- 🔄 Supports:
  - Materialized views
  - Stored procedures
  - Semi-structured data (JSON, Avro)
- 🧪 Two deployment modes:
  - **Redshift Provisioned** (manual cluster setup)
  - **Redshift Serverless** (auto-scaling, on-demand)

### 🧊 Redshift Spectrum

**Redshift Spectrum** lets you run SQL queries from Redshift **directly on data stored in S3**, without loading it into Redshift.

| Feature                   | Notes                                           |
|---------------------------|--------------------------------------------------|
| Query engine              | Redshift compute nodes                          |
| Data format               | Parquet, ORC, CSV, JSON                         |
| Schema source             | Glue Data Catalog                               |
| Permissions               | Enforced via Lake Formation or IAM              |
| Cost                      | ✅ Charged per TB scanned (~$5/TB)              |
| Use case                  | Ad-hoc queries, large archive joins             |

> ⚠️ Be careful with **partitioning** and formats. Querying unoptimized S3 (e.g., CSV) with Spectrum gets **expensive very fast**.

#### 💰 Redshift Serverless & Spectrum Cost Warning

- Redshift Serverless is billed **per second based on Redshift Processing Units (RPUs)**
- If your query involves Spectrum, it **scans S3 + uses serverless compute**
- Even "simple queries" can trigger **high-cost minimums** if not tuned

✅ For cost-sensitive workloads:
- Use **Athena** for S3-only ad hoc queries
- Use **Redshift Spectrum** only when you need **joins with warehouse tables**

### 🔗 Role of Glue with Spectrum

- Spectrum uses **Glue Data Catalog** to discover and map S3 data
- You can:
  - Register S3 tables with a **Glue Crawler**
  - Use them directly in Redshift like:

```sql
SELECT * FROM glue_catalog.database.table LIMIT 10;
```
> Without the Glue Catalog, Redshift doesn't know your S3 schemas.

### 🆚 Aurora DWH vs. Redshift
Both Aurora and Redshift can be used for **analytical workloads**, but they serve very different purposes.
| Feature / Need   | Aurora                              | Redshift                          |
| ---------------- | ----------------------------------- | --------------------------------- |
| Purpose          | OLTP (transactions), light OLAP     | OLAP at scale                     |
| Architecture     | Row-based RDS                       | Columnar MPP engine               |
| Ideal for        | Operational dashboards, hybrid apps | Complex reporting, large datasets |
| Scale            | Up to TB range                      | Scales into PB range              |
| Query engine     | PostgreSQL/MySQL                    | Redshift SQL (similar to PG)      |
| Cost             | Lower for small, mixed workloads    | More efficient at high scale      |
| Lake integration | ❌ No                                | ✅ Yes (via Spectrum)              |

✅ Use Aurora if:
- You need OLTP + some analytics
- The OLAP is small or really purpose built + you don't want a lakehouse
- You already run your app on Aurora and want dashboards with no ETL

✅ Use Redshift if:
- You need high-speed queries over millions of rows
- You want to join S3 and warehouse data
- You’re building a dedicated BI or data warehouse layer

### Best Practices
✅ Use Redshift Spectrum for infrequently accessed S3 datasets   
✅ Store data in Parquet + partitioned format in S3   
✅ Register external tables in Glue Catalog   
✅ If using Serverless, monitor RPU usage to avoid surprise billing   
✅ Consider concurrency scaling or materialized views for dashboards   
❌ Don’t use Redshift as your app database — it’s for analytics, not transactions   

## QuickSight

**Amazon QuickSight** is AWS’s managed **business intelligence (BI)** and **data visualization** tool. It allows you to create dashboards, reports, and visual explorations on top of AWS-native data sources like S3, Athena, Redshift, and RDS.

It's serverless, scalable, and integrates with many AWS services — but it comes with trade-offs in both **cost** and **capability**.

### Key Features

- 📊 Build interactive dashboards and reports
- 🔄 Connects natively to:
  - Redshift
  - Athena
  - RDS (Aurora, PostgreSQL, MySQL)
  - S3 (via Athena or Spice)
- ⚙️ In-memory engine **SPICE** for caching high-performance data snapshots
- 📧 Scheduled and email-based reporting (PDF exports, alerts)
- 🧩 Embedding support for web apps and SaaS tools
- 🔐 Integrated with IAM and SSO

### 💰 Cost Considerations

| Mode                    | Cost Model                           | Notes                                  |
|-------------------------|---------------------------------------|----------------------------------------|
| **Author (Pro)**        | ~$24/month per user                   | Required for building dashboards       |
| **Reader (Standard)**   | ~$5/month per user **OR** per session | Additional cost for consumption        |
| **SPICE capacity**      | Charged per GB (up to TBs)            | Needed for performance                 |

> ⚠️ Costs add up **very quickly** in large teams or when dashboards scale — especially if you don’t use SPICE carefully.

### ✅ When to Use It

- You're doing a **small-to-medium AWS-native reporting use case**
- You want a **simple, embeddable dashboard**
- You have **no BI team** and need something fast + internal

### ❌ When to Avoid It

- You already have a **BI tool (Power BI, Tableau, Looker, Metabase)**
- Your reporting users expect polish and interactivity
- You need **cross-cloud or SaaS integration**
- You want cost-efficiency at scale

> 💡 This is actually a **great use case for multi-cloud architecture**.  
> There’s <ins>**no**</ins> reason to avoid connect **Power BI to Athena**, **Tableau to Redshift**, or **Looker to S3 via Presto** — and you’ll get a better UX, more features, and probably lower cost.

### 🧠 Honest Opinion

While QuickSight **“works well enough”** for basic dashboards, it is:

- ❌ Visually and functionally behind tools like **Power BI**, **Tableau**, or **Looker**
- ❌ Lacks many features: limited custom visuals, complex joins, slower UI
- ❌ Developer experience and documentation are weaker than competitors

### Best Practices

✅ Use **SPICE** wisely — cache only high-value datasets  
✅ Connect to **Athena or Redshift** for queryable lakehouse integration  
✅ Monitor reader usage to avoid unnecessary per-session costs  
✅ Use **row-level security** for sensitive dashboards  
❌ Don’t rely on it for advanced reporting pipelines — offload that to external BI systems

