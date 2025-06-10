# 8. Quick Intro to A.I. on AWS

## Content

- The following services will be explained and focused on:
    - Augmented AI
    - Bedrock
    - Comprehend
    - Fraud Detector
    - Forecast
    - Lex
    - Monitron
    - Personalize
    - Polly
    - Rekognition
    - SageMaker
    - Textract
    - Transcribe
    - Translate

## Workload Account

To already gather some real world experience in how to use your own landing zone, we will treat the following hands-on as if they would be in a live productive LZ. For all the following tasks (if not specified different) work in the **sandbox/test** account.

## SageMaker

**Amazon SageMaker** is AWS’s fully managed **machine learning platform**, designed to cover the entire ML lifecycle: from data labeling and preprocessing to training, evaluation, deployment, and monitoring.

It allows data scientists and ML engineers to build, train, and deploy models at scale — either from scratch or using built-in algorithms and pre-trained models.

### Key Features

- 🏗️ **Integrated IDE** (SageMaker Studio) for Jupyter-style notebooks
- 🔁 **End-to-end ML lifecycle support**:
  - Data prep → Training → Evaluation → Deployment → Monitoring
- 🧪 **Built-in algorithms** and marketplace model access
- 🧠 Bring-your-own-model with Docker support
- ☁️ **Serverless inference** and **multi-model endpoints** (for cost efficiency)
- 🔍 **Model monitoring** for data drift and accuracy
- 🧩 Integrates with:
  - Glue, Redshift, S3, Lambda, CloudWatch, and more

> SageMaker is a power tool — best used when you’re managing custom ML workflows or deploying models at scale.

### Ground Truth

**Ground Truth** is SageMaker’s managed **data labeling service**, used to generate training datasets.

- 🔍 Supports human-in-the-loop (Amazon + custom workforces)
- 🖼️ Use cases:
  - Image classification, object detection
  - Text classification, sentiment
  - Custom workflows (bounding boxes, text spans, etc.)
- 🔄 Automatically creates training datasets in formats ready for SageMaker training
- 💰 Cost-efficient via **active learning** — only label what the model is uncertain about

✅ Ground Truth is ideal for teams that need **high-quality labeled datasets** but lack internal labeling resources.

### 🧰 Data Wrangler

**SageMaker Data Wrangler** helps you **explore, transform, and prepare** data for ML training — all in a low-code visual interface.

| Feature                    | Description                                       |
|----------------------------|---------------------------------------------------|
| GUI-based workflows        | Clean, filter, join, and transform datasets       |
| Built-in transforms        | One-hot encoding, imputation, normalization, etc. |
| Data sources               | S3, Athena, Redshift, Snowflake, SageMaker Feature Store |
| Export to SageMaker        | One click to training job or feature store        |

✅ Think of Data Wrangler as the **Pandas + SQL + Glue** of the SageMaker world, built for ML prep.

### 🪲 Machine Learning Debugging

SageMaker includes tools to **debug training jobs** and **monitor models post-deployment**:

- 🛠️ **Debugger**:
  - Automatically captures model metrics, weights, gradients
  - Detects training anomalies (e.g., vanishing gradients, overfitting)
  - Hooks into TensorFlow, PyTorch, XGBoost

- 📈 **Model Monitor**:
  - Tracks data drift, prediction quality, schema mismatches
  - Works on live endpoints
  - Sends alerts to CloudWatch

✅ These tools are helpful for **production ML** and **model governance** — particularly where explainability and auditability are required.

### Best Practices

✅ Start with **built-in algorithms or AutoML** before building custom models  
✅ Use **Ground Truth** for labeling pipelines, but validate labels for quality  
✅ Profile your training jobs with **Debugger** — especially on large datasets  
✅ For data prep, use **Data Wrangler or Glue** — not hand-coded scripts  
✅ Consider **SageMaker Serverless Inference** for occasional predictions  
❌ Don’t use SageMaker for small models that run well in Lambda or on-device — it's overkill
❌ Don't try to re-invent the wheel - Only do Machine Learning and use Sagemaker therefore, when none of the managed SaaS-Tools below fit the shoe   

## Amazon Bedrock

**Amazon Bedrock** is AWS’s fully managed **Generative AI platform**, letting you build and deploy GenAI apps using **foundation models (FMs)** from multiple providers — **without managing infrastructure or tuning models** yourself.

Unlike SageMaker, where you bring and train your own models, Bedrock provides **ready-to-use models** for tasks like summarization, code generation, Q&A, image generation, and more.

### 🧠 Providers Available in Bedrock

Bedrock supports models from leading foundation model providers:

| Provider       | Models Available                        | Specialties                              |
|----------------|-----------------------------------------|-------------------------------------------|
| **Anthropic**  | Claude 2, Claude 3                      | General-purpose, reasoning, chat          |
| **Meta**       | Llama 2 (opt-in)                        | Open-source foundation models             |
| **Amazon**     | Titan (text, embeddings)                | AWS-native, optimized for AWS infra       |
| **AI21 Labs**  | Jurassic-2                              | Text generation, multilingual             |
| **Cohere**     | Command R+, Embed                       | RAG-friendly, lightweight models          |
| **Stability AI** | Stable Diffusion                     | Text-to-image generation                  |
| **Mistral (preview)** | Mistral 7B, Mixtral              | Fast open models for code + reasoning     |

✅ Bedrock is multi-model by design — you can **swap providers** without rewriting your app.

### 🧬 Types of Models in Bedrock

| Task Type          | Examples                        |
|---------------------|---------------------------------|
| **Text Generation** | Claude, Titan Text, Jurassic    |
| **Chatbots**        | Claude, Mistral, Command R+     |
| **Embeddings**      | Titan Embeddings, Cohere Embed  |
| **Text-to-Image**   | Stability AI (Stable Diffusion) |
| **Text Summarization/Q&A** | All major text models   |

All models are accessible via **a consistent API**, with options for:
- 🔄 Synchronous or streaming responses
- 🔍 System prompts + user instructions (prompt engineering)
- 🧠 Embeddings + retrieval-based workflows (RAG)

### 📚 Knowledge Bases in Bedrock

The **Knowledge Base** feature lets you combine **Bedrock FMs with your own data**, enabling **RAG (Retrieval-Augmented Generation)** in just a few steps:

1. 🗃️ Connect a data source (e.g., S3 with PDFs or docs)
2. 🔍 Index it using an embedding model (e.g., Titan or Cohere)
3. 💬 Ask questions — Bedrock retrieves relevant context and feeds it to the model

> Great for: chatbots over documentation, internal knowledge Q&A, support assistants

✅ Powered by **Amazon OpenSearch Serverless, Postgres, Neptune or RedShift** under the hood  
✅ Supports **Cognito + IAM** for access control

### Hands-On: Try Out Bedrock in Console

> 📝 This quick lab shows how to test a foundation model in the Bedrock console — no coding required.

1. Open Bedrock Console  
2. Choose "Playground"  
- Click “Model Access” and ensure at least **one provider is enabled** (e.g., Anthropic Claude)
- Go to **"Playground" → "Text playground"**
3. Select a Model  
- Choose **Claude 3**, **Jurassic-2**, or **Titan Text**  
- Set system prompt:  
```text
  "You are a helpful assistant summarizing customer feedback."
```
4. Try a Prompt  
```text
Summarize the following:
"The interface is clunky, but the response time is excellent. I'd use it again if the UX improved."
```

✅ This shows how you can evaluate model performance without any infrastructure or code.

### Best Practices
✅ Use **Titan** or **Claude** for most enterprise-safe GenAI work   
✅ Use **Managed Knowledge Base** for grounded answers over your content (RAG)   
✅ Use **streaming inference** for long-form output (e.g., transcripts, code)   
✅ Monitor **token usage and costs** closely — they scale fast   
✅ Keep prompts simple and clean — start with structure, then iterate   
❌ Don’t fine-tune just to "fix" a prompt — fine tuning doesn't enhance the information quality, only the way the A.I. uses to talk. Instead do a RAG!      

## PaaS A.I.

These are **trainable machine learning services** on AWS — not raw models, but fully managed platforms that let you feed in your own data and get tailored predictions or outcomes without having to build ML from scratch.

### 🎯 Amazon Personalize

- 📦 Build real-time recommendation engines (like "customers also bought")
- 🧠 Based on the same tech as Amazon.com
- 🗃️ Input: user-item interaction history, item metadata, optional user metadata
- ⚙️ Output: ranked recommendations, similar items, user affinities
- 🔌 Integrates with websites, mobile apps, or marketing tools

> ✅ Good for product, content, or job recommendations — with relatively small datasets  
> ❌ Not useful for general ML — strictly for recommendations

### 🏭 Amazon Monitron

- 🛠️ End-to-end predictive maintenance platform for industrial equipment
- 📡 Includes **physical sensors** (vibration + temperature) and an AWS gateway
- 🧠 Uses ML to detect early signs of failure
- 🗃️ No model training required — just install sensors and stream data
- 📱 Mobile app for maintenance teams to receive alerts

> ✅ Great for factories, HVAC systems, rotating machinery  
> ❌ Doesn’t apply to software or cloud-based failure detection

### 💬 Amazon Lex

- 🗣️ Service for building **voice and text chatbots**
- 🧠 Powers Alexa — supports intent recognition, slots, multi-turn dialogs
- 🔌 Integrates with:
  - Lambda (to run backend logic)
  - Connect (call center platform)
  - Slack, Facebook Messenger, etc.
- 🗃️ No training data needed to get started — rule-based with ML intent matching

> ✅ Great for chatbots, call center automation, basic voice assistants  
> ❌ Not as flexible or open-ended as Claude, GPT, or other LLMs

### 📈 Amazon Forecast

- 📊 Time-series forecasting (e.g., inventory, sales, demand)
- 🧠 Trains custom models from your historical data (CSV or S3 input)
- 📅 Supports related time series (e.g., holidays, marketing campaigns)
- 🔮 Outputs predictions with confidence intervals
- ⚙️ Uses algorithms from Amazon.com retail demand planning

> ✅ Very strong if you already have structured time-series data  
> ❌ Not helpful for NLP or image-based forecasting

### 🔐 Amazon Fraud Detector

- 🚫 Detects potentially fraudulent activity (login fraud, payment abuse, fake signups)
- 🧠 You train it on historical fraud/non-fraud events
- 🛠️ Offers rule-based AND ML scoring
- 💡 Use case examples:
  - Account takeovers
  - Transaction risk scoring
  - Fake account detection

> ✅ Great if you have labeled fraud history  
> ❌ Not a general-purpose anomaly detector

## SaaS A.I.

These services are **fully managed, pre-trained AI APIs** that require **no machine learning experience or data preparation**. You just call the service with your input — and get structured output in return.

### 📄 Amazon Textract

- 🧠 OCR service for **structured document extraction**
- Parses:
  - Printed and handwritten text
  - Forms (key-value pairs)
  - Tables
- Input: image or PDF → Output: JSON with text, structure, confidence
- Use cases: invoices, passports, contracts, identity documents

> ✅ Stronger than traditional OCR — understands layout  
> ❌ Expensive for large-scale or real-time streaming OCR

### 🌍 Amazon Translate

- 🌐 Neural machine translation across **75+ languages**
- Fast, scalable, and domain-adaptive
- Use cases:
  - Translating user content (reviews, chats)
  - Multilingual websites or apps
  - Translating documents from S3

> ✅ Very easy to use and low-latency  
> ❌ Doesn’t offer formatting preservation like some PDF tools

### 🗣️ Amazon Polly

- 🎤 Text-to-Speech engine
- Converts plain text to lifelike speech in many languages
- Offers:
  - Neural voices (NTTS)
  - MP3 output for apps, devices, IVRs

> ✅ Great for accessibility, voice response systems, audiobooks  
> ❌ Not a voice assistant — just generates audio files

### 👁️ Amazon Rekognition

- 🧠 Computer vision API for analyzing images and video
- Can detect:
  - Labels (objects, scenes)
  - Faces and emotions
  - Unsafe content
  - Text in images
  - Celebrity or face match
- Integrates with EventBridge, Lambda, and S3

> ✅ Good for image moderation, content tagging, ID checks  
> ❌ Not ideal for pixel-level segmentation or complex CV models

### 📝 Amazon Transcribe

- 🧠 Speech-to-text service
- Supports:
  - Real-time and batch transcription
  - Multi-language support
  - Speaker identification and timestamps
- Input: audio/video → Output: text (JSON or plain)

> ✅ Perfect for meeting notes, call transcripts, subtitles  
> ❌ Not ideal for noisy audio or overlapping speakers

### 🧠 Amazon Comprehend

- NLP API for:
  - Sentiment analysis
  - Entity recognition (names, locations, brands)
  - Key phrase extraction
  - Language detection
  - Topic modeling
- Input: plain text → Output: structured JSON

> ✅ Great for social media monitoring, surveys, chat logs  
> ❌ Not suited for very domain-specific NLP without training

### Hands-On: Lambda Goes A.I.

> 🧠 Use case: Upload a **scanned German document** to S3 →  
> Lambda triggers → runs **Textract**, **Translate**, and **Comprehend**

#### Prerequisites

- S3 bucket with prefix `input/documents/`
- Lambda function with access to:
  - Textract
  - Translate
  - Comprehend
  - S3 read/write

1. **If you know Terraform, then do the following tasks with the proper Terraform resources instead of the management console!** 
2. 📥 Upload a **German PDF or image** to ad dedicated bucket
3. Lambda is triggered on S3 `ObjectCreated` event
4. Create the lambda code with boto3 that first calls `textract`, then translates the extracted data with `translate` and to finish it off detects the sentiment with `comprehend` 
5. Output each result from the A.I. in the console via a print statement

### Best Practices
✅ Use pre-trained SaaS A.I. whenever possible to keepl costs low   
✅ Combine services in Lambda for powerful lightweight and ideally eventbased pipelines   
❌ Don’t run them inside synchronous API paths without timeout handling   

## Amazon Augmented AI (A2I)

**Amazon Augmented AI (A2I)** lets you insert **human review steps** into ML workflows — for when you don’t fully trust model output, or need human oversight for accuracy, compliance, or training purposes.

Rather than replace your ML predictions, A2I adds a **“human in the loop” (HITL)** checkpoint where selected outputs are routed to manual reviewers.

### Key Features

- 👨‍⚖️ **Human review workflows** for ML predictions
- ⚙️ Works with AWS AI services like:
  - **Textract** (form extraction)
  - **Comprehend** (entity classification)
  - **Rekognition** (content moderation)
- 🛠️ Supports **custom ML models** via Lambda
- 🧰 Built-in templates for common review types:
  - Bounding boxes (images)
  - Text classification or correction
  - Form/key-value validation
- 🧑‍💻 You can assign reviewers via:
  - Internal teams (private workforce)
  - Amazon Mechanical Turk
  - Vendor workforces (third-party)
- 🔁 Human feedback can be:
  - Auditing only
  - Used to retrain models

### ✅ When to Use A2I

- When you need **human validation** for high-risk decisions (e.g., OCR of legal docs)
- When model confidence is low and you need a fallback
- When you’re building datasets from partial automation + human review
- When compliance requires **explainability + traceability**

### ❌ When Not to Use It

- For low-risk, high-volume predictions where cost and speed matter more than perfection
- In real-time systems where latency matters — A2I introduces human delay
- In all processes where the damage done by a error is lower than the human labor you constantly create with it   

### Best Practices

✅ Use **confidence thresholds** to decide when to route to A2I  
✅ Store A2I output and feedback to **improve future ML models**  
✅ Use **private workforces** for sensitive data  
✅ Combine A2I with **Textract + Comprehend** for document validation  
❌ Don’t build your entire process around A2I — it's designed as a fallback, not a primary path
