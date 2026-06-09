# FinSight AI

> **Privacy-First Personal Finance Intelligence Powered by Local AI**
>
> Upload your bank statement, ask questions in plain English, and receive intelligent financial insights — all without sending your data to the cloud.

---

## Overview

FinSight AI is a full-stack, local-first personal finance platform that combines AI-powered transaction categorization, natural language querying, automated financial analysis, and interactive dashboards.

Built with **Flutter**, **FastAPI**, **PostgreSQL + pgvector**, and **Phi-4 Mini**, FinSight AI ensures your financial information remains entirely under your control.

### Core Principle

**Your financial data never leaves your machine.**

No cloud APIs. No third-party analytics. No external AI services.

---

## Key Features

### AI Transaction Categorization

Automatically classifies transactions into categories such as:

* Food & Groceries
* Transport
* Utilities
* Entertainment
* Shopping
* Healthcare
* Education
* Rent & Housing
* Income
* Other

Example:

| Transaction       | Category         |
| ----------------- | ---------------- |
| SHOPRITE LUSAKA   | Food & Groceries |
| ZESCO ELECTRICITY | Utilities        |
| SALARY CREDIT     | Income           |
| UBER TRIP         | Transport        |

---

### Natural Language Financial Assistant

Ask questions like:

* How much did I spend on groceries last month?
* What was my biggest expense this month?
* Compare transport and entertainment spending.
* What percentage of my income did I save?

FinSight converts questions into SQL automatically and explains results in plain language.

---

### AI-Powered Monthly Insights

Generate comprehensive monthly reports including:

* Income and expense summaries
* Spending trends
* Financial observations
* Savings analysis
* Personalized recommendations

Example sections:

* Monthly Overview
* Spending Breakdown
* Key Observations
* Action Plan

---

### Interactive Dashboard

Visualize:

* Income vs Expenses
* Savings Rate
* Spending by Category
* Largest Expenses
* Monthly Trends

---

### Semantic Transaction Search

Uses vector embeddings to enable intelligent transaction retrieval.

Examples:

* "Show all school-related payments"
* "Find supermarket purchases"
* "Search healthcare transactions"

---

## Architecture

```text
┌─────────────────────────────┐
│       Flutter Frontend      │
└─────────────┬───────────────┘
              │ HTTP/JSON
              ▼
┌─────────────────────────────┐
│      FastAPI Backend        │
├─────────────────────────────┤
│ Upload Statements           │
│ Transaction Management      │
│ Natural Language Chat       │
│ Financial Insights Engine   │
└─────────────┬───────────────┘
              │
      ┌───────┴─────────┐
      │                 │
      ▼                 ▼
┌───────────────┐ ┌───────────────┐
│  Phi-4 Mini   │ │ PostgreSQL    │
│ Local LLM     │ │ + pgvector    │
└───────────────┘ └───────────────┘
              │
              ▼
     all-MiniLM-L6-v2
      Embeddings Model
```

---

## Technology Stack

### Frontend

* Flutter 3
* Provider
* HTTP
* File Picker
* Flutter Markdown

### Backend

* FastAPI
* SQLAlchemy
* PostgreSQL 16
* pgvector
* Pandas
* NumPy

### AI Components

* Phi-4 Mini
* llama-cpp-python
* all-MiniLM-L6-v2
* Text-to-SQL Engine
* Embedding Search

---

## Project Structure

```text
finsight-ai/
│
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── ai_engine.py
│   ├── finance_processor.py
│   ├── schema.sql
│   ├── requirements.txt
│   └── .env
│
├── frontend/
│   ├── pubspec.yaml
│   └── lib/
│       ├── models/
│       ├── providers/
│       ├── services/
│       ├── screens/
│       └── widgets/
│
└── models/
    └── Phi-4-mini-instruct-Q4_K_M.gguf
```

---

## How It Works

### Step 1: Upload a Bank Statement

Upload a CSV file from your bank.

Supported formats include:

```csv
Date,Description,Amount,Balance
2025-01-02,SALARY CREDIT,25500.00,30500.00
2025-01-03,SHOPRITE LUSAKA,-450.00,29050.00
```

---

### Step 2: AI Categorization

FinSight:

1. Parses transactions
2. Categorizes spending using Phi-4 Mini
3. Generates vector embeddings
4. Stores everything in PostgreSQL

---

### Step 3: Ask Questions

Example:

```text
How much did I spend on groceries last month?
```

Generated workflow:

```text
Question
    ↓
Text-to-SQL
    ↓
Database Query
    ↓
AI Explanation
    ↓
User Response
```

---

### Step 4: Generate Insights

Receive a complete financial report generated from your actual spending patterns.

---

## Installation

### 1. Create Database

```bash
sudo -u postgres psql -c "CREATE USER phi4app WITH PASSWORD 'YOUR_PASSWORD';"

sudo -u postgres psql -c "CREATE DATABASE finsight_db OWNER YOUR_NAME;"

sudo -u postgres psql -d finsight_db -f backend/schema.sql
```

---

### 2. Install Backend

```bash
cd backend

python3 -m venv venv

source venv/bin/activate

pip install -r requirements.txt
```

---

### 3. Download Phi-4 Mini

```bash
python3 -c "
from huggingface_hub import hf_hub_download

hf_hub_download(
    repo_id='bartowski/Phi-4-mini-instruct-GGUF',
    filename='Phi-4-mini-instruct-Q4_K_M.gguf',
    local_dir='../models'
)
"
```

---

### 4. Configure Environment

```env
DATABASE_URL=postgresql://DB_USER:DB_PASSWORD@localhost:5432/finsight_db

MODEL_PATH=../models/Phi-4-mini-instruct-Q4_K_M.gguf

N_THREADS=4
N_CTX=4096
```

---

### 5. Start Backend

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

### 6. Start Flutter App

```bash
cd frontend

flutter pub get

flutter run -d linux
```

Android:

```bash
flutter run -d android \
--dart-define=API_URL=http://YOUR_IP_ADDRESS:8000
```

---

## API Endpoints

| Method | Endpoint              | Description                          |
| ------ | --------------------- | ------------------------------------ |
| GET    | /health               | Health check                         |
| POST   | /statements/upload    | Upload bank statement                |
| GET    | /transactions         | Retrieve transactions                |
| GET    | /transactions/summary | Spending summary                     |
| GET    | /transactions/months  | Available months                     |
| POST   | /chat                 | Natural language financial assistant |
| POST   | /insights/generate    | Generate AI insights report          |

---

## Performance Requirements

### Minimum

* 8 GB RAM
* 4 CPU cores
* 10 GB free disk space

### Recommended

* 16 GB RAM
* 8 CPU cores
* SSD storage

---

## Security & Privacy

### Local-First AI

* No cloud processing
* No external API calls
* No financial data transmission
* No vendor lock-in

### Database Protection

* PostgreSQL access control
* Read-only AI SQL execution
* SQL injection safeguards
* Conversation history storage

### AI Safety

* SELECT-only query execution
* SQL validation
* Controlled prompt templates
* Safe inference wrapper

---

## Future Roadmap

* Multi-account support
* Budget planning assistant
* Investment portfolio tracking
* Receipt OCR
* Financial forecasting
* Goal-based savings recommendations
* Mobile-first experience
* Offline desktop packaging

---

## Why FinSight AI?

Unlike traditional finance apps that upload your transactions to external servers, FinSight AI gives you the power of modern AI while keeping your financial data private.

✅ Local AI

✅ Natural Language Finance Queries

✅ Automatic Categorization

✅ AI Financial Reports

✅ Semantic Search

✅ Flutter Cross-Platform UI

✅ Fully Offline Operation

---

## Author

**Prince Mwaanga**

AI Developer • Entrepreneur • Founder

---

## License

MIT License

Copyright (c) 2026 Prince Mwaanga

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files to deal in the Software without restriction.
