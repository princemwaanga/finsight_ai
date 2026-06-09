FinSight AI Frontend

Beautiful, Privacy-First Personal Finance Management

A Flutter-powered cross-platform application that transforms bank statements into actionable financial insights using fully local AI.

Overview

FinSight AI Frontend is the user-facing application for the FinSight ecosystem. Built with Flutter, it provides an intuitive and modern interface for managing personal finances, visualizing spending habits, interacting with AI-powered financial analytics, and generating intelligent reports.

The application connects to a local FastAPI backend running Phi-4 Mini, ensuring that all financial data remains private and under the user's control.

Features
📊 Financial Dashboard

Get an instant overview of your financial health:

Total Income
Total Expenses
Net Savings
Savings Rate
Spending Categories
Largest Transactions
📁 Bank Statement Import

Upload CSV bank statements directly from your device.

Supported capabilities:

CSV File Picker
Multi-bank compatibility
Automatic processing
Real-time upload status tracking
🤖 AI Financial Assistant

Ask questions in plain English:

How much did I spend on groceries this month?
What are my largest expenses?
How much money did I save last month?
Compare transport spending to entertainment.

The assistant automatically communicates with the backend AI engine and displays natural-language responses.

📈 Spending Analysis

Visualize spending patterns through:

Category Breakdown
Spending Distribution
Monthly Trends
Top Expenses
📝 AI Financial Reports

Generate intelligent monthly reports including:

Income Analysis
Expense Analysis
Spending Patterns
Savings Performance
Personalized Recommendations
🔍 Smart Transaction Explorer

Browse and filter transactions by:

Category
Month
Account
Spending Type
Screens
Dashboard

Provides a high-level financial summary.

Features:

Income Card
Expense Card
Savings Card
Savings Rate Indicator
Spending Breakdown
Top Expenses
Transactions

Manage and explore imported bank transactions.

Features:

CSV Upload
Category Filters
Transaction List
Upload Status Monitoring
Account Naming
AI Chat

Interact with your finances using natural language.

Features:

Conversational Interface
Suggested Questions
SQL Transparency
Conversation History
Markdown Responses
Insights

Generate AI-powered financial reports.

Features:

Monthly Reports
Cached Insights
Financial Recommendations
Trend Analysis
Technology Stack
Framework
Flutter 3.x
Dart 3.x
State Management
Provider
Networking
HTTP Package
File Management
File Picker
Storage
Shared Preferences
Content Rendering
Flutter Markdown
Date Formatting
Intl
Project Structure
lib/
│
├── main.dart
│
├── models/
│   └── transaction.dart
│
├── services/
│   └── api_service.dart
│
├── providers/
│   ├── finance_provider.dart
│   └── chat_provider.dart
│
├── screens/
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── chat_screen.dart
│   └── insights_screen.dart
│
└── widgets/
    ├── category_bar.dart
    └── transaction_tile.dart
Architecture
┌───────────────────────────┐
│      Flutter Frontend     │
├───────────────────────────┤
│ Dashboard                 │
│ Transactions              │
│ AI Chat                   │
│ Insights                  │
└─────────────┬─────────────┘
              │
              │ HTTP / JSON
              ▼
┌───────────────────────────┐
│      FastAPI Backend      │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│       Phi-4 Mini AI       │
└───────────────────────────┘
Installation
Prerequisites
Flutter SDK 3.x
Dart SDK 3.x
Android Studio or VS Code
Running FinSight Backend

Verify Flutter installation:

flutter doctor
Setup
Clone Repository
git clone https://github.com/your-org/finsight-ai.git

cd finsight-ai/frontend
Install Dependencies
flutter pub get
Run Application

Linux:

flutter run -d linux

Android:

flutter run -d android

Windows:

flutter run -d windows

macOS:

flutter run -d macos
Backend Configuration

By default:

http://localhost:8000

For Android devices:

flutter run \
--dart-define=API_URL=http://YOUR_IP_ADDRESS:8000

Example:

flutter run \
--dart-define=API_URL=http:/YOUR_IP_ADDRESS:8000
Application Flow
1. Upload Statement
User Uploads CSV
        │
        ▼
Flutter File Picker
        │
        ▼
FastAPI Upload Endpoint
        │
        ▼
AI Categorization
        │
        ▼
Database Storage
2. View Dashboard
Dashboard Screen
        │
        ▼
Fetch Summary API
        │
        ▼
Display Charts & Statistics
3. Ask Questions
User Question
        │
        ▼
Chat Provider
        │
        ▼
Backend AI Engine
        │
        ▼
Text-to-SQL
        │
        ▼
Database Query
        │
        ▼
Natural Language Response
State Management

The application uses Provider for reactive state management.

FinanceProvider

Responsible for:

Loading transactions
Uploading statements
Loading summaries
Managing filters
Tracking upload progress
ChatProvider

Responsible for:

Managing conversations
Sending messages
Receiving AI responses
Maintaining chat history
UI Components
CategoryBar

Displays spending distribution by category.

TransactionTile

Displays transaction details including:

Description
Category
Date
Amount
Income/Expense Indicator
Dashboard Cards

Provides:

Income Summary
Expense Summary
Savings Summary
Privacy

FinSight Frontend never directly sends data to any external service.

All communication is restricted to:

Flutter App
     │
     ▼
Local FastAPI Server

No cloud APIs.

No third-party analytics.

No external AI providers.

No tracking.

Performance

Optimized for:

Fast startup
Responsive UI
Efficient state updates
Low memory usage
Large transaction datasets

Supports:

10,000+ transactions
Multi-month financial history
Long-running AI conversations
Future Enhancements
Dark Mode
Export Reports to PDF
Interactive Charts
Budget Planner
Goal Tracking
Multi-Account Support
Financial Forecasting
Desktop Packaging
Offline Notifications
Screenshots
Dashboard
├── Income Summary
├── Expense Summary
├── Savings Rate
└── Spending Categories

Transactions
├── CSV Upload
├── Filters
└── Transaction History

AI Chat
├── Suggested Questions
├── AI Responses
└── SQL Transparency

Insights
├── Monthly Reports
└── Financial Recommendations
Author

Prince Mwaanga

AI Developer | Entrepreneur | Founder

Building privacy-first AI solutions that empower individuals and businesses through local intelligence.

License

MIT License

Copyright © 2026 Prince Mwaanga. All rights reserved.
