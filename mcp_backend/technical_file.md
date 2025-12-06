# RytGuard Backend Technical Documentation

**Version:** 1.0.0
**Last Updated:** December 2025
**Base URL:** `http://localhost:3001`

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Authentication](#authentication)
4. [REST API Endpoints](#rest-api-endpoints)
5. [MCP (Model Context Protocol) Tools](#mcp-tools)
6. [Database Schema](#database-schema)
7. [Error Handling](#error-handling)
8. [Flutter Integration Guide](#flutter-integration-guide)

---

## Overview

RytGuard backend is a Node.js/Express server with PostgreSQL database that provides:
- REST API for financial transactions and subscription management
- MCP (Model Context Protocol) integration for AI-powered banking tools
- Real-time safe balance calculation
- Recurring liability tracking

**Tech Stack:**
- **Runtime:** Node.js
- **Framework:** Express.js
- **Language:** TypeScript
- **Database:** PostgreSQL
- **AI Integration:** Anthropic Claude via MCP

---

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│   (Frontend)    │
└────────┬────────┘
         │ HTTP/REST
         ▼
┌─────────────────┐
│  Express Server │◄─────┐
│   (Port 3001)   │      │ MCP Protocol
└────────┬────────┘      │
         │              ┌─┴──────────────┐
         ▼              │  Claude AI     │
┌─────────────────┐    │  (via MCP)     │
│   PostgreSQL    │    └────────────────┘
│   (Port 5433)   │
└─────────────────┘
```

---

## Authentication

**Current Status:** No authentication required (MVP/Demo mode)

**Default Test User:**
- External User ID: `john_doe_001`
- Name: John Doe
- Email: john.doe@example.com

**Future:** Implement JWT-based authentication for production.

---

## REST API Endpoints

### 1. Health Check

**Endpoint:** `GET /health`

**Description:** Check if server is running

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-06T10:30:00.000Z",
  "database": "connected"
}
```

---

### 2. Direct Database Query (Development Only)

**Endpoint:** `POST /api/query`

**Description:** Execute raw SQL queries (for development/testing)

**Request:**
```json
{
  "query": "SELECT * FROM users WHERE external_user_id = $1",
  "params": ["john_doe_001"],
  "limit": 100
}
```

**Response:**
```json
{
  "rows": [...],
  "rowCount": 1,
  "executionTime": "15ms"
}
```

**⚠️ Warning:** This endpoint should be disabled in production for security.

---

### 3. Chat with AI Assistant

**Endpoint:** `POST /api/chat`

**Description:** Send message to Claude AI assistant with banking context

**Request:**
```json
{
  "userExternalId": "john_doe_001",
  "message": "Can I afford to buy a RM 800 phone?",
  "conversationHistory": [
    {
      "role": "user",
      "content": "What's my safe balance?"
    },
    {
      "role": "assistant",
      "content": "Your safe balance is RM 1,200."
    }
  ]
}
```

**Response:**
```json
{
  "response": "Let me check your finances...",
  "toolsUsed": ["get-safe-balance", "check-affordability"],
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

---

### 4. Reload Money (Deposit)

**Endpoint:** `POST /api/reload`

**Description:** Add money to user's account

**Request:**
```json
{
  "userExternalId": "john_doe_001",
  "amount": 1000.00,
  "description": "Bank transfer deposit"
}
```

**Validation:**
- `amount` must be > 0
- `amount` must be ≤ 10,000 (max deposit limit)
- `userExternalId` is required

**Success Response (200):**
```json
{
  "success": true,
  "transaction": {
    "id": "reload_1733485200_abc123",
    "amount": 1000.00,
    "type": "CREDIT",
    "description": "Bank transfer deposit",
    "date": "2025-12-06T10:30:00.000Z",
    "previousBalance": 2500.00,
    "newBalance": 3500.00
  }
}
```

**Error Response (400/404/500):**
```json
{
  "error": "Maximum deposit amount is RM 10,000",
  "success": false
}
```

---

### 5. Withdraw Money

**Endpoint:** `POST /api/withdraw`

**Description:** Withdraw money from account (validated against safe balance)

**Request:**
```json
{
  "userExternalId": "john_doe_001",
  "amount": 500.00,
  "recipientName": "Ali Ahmad",
  "description": "Payment for services"
}
```

**Validation:**
- `amount` must be > 0
- `amount` must not exceed safe balance (prevents overspending)
- `recipientName` is required
- `userExternalId` is required

**Success Response (200):**
```json
{
  "success": true,
  "transaction": {
    "id": "withdraw_1733485200_xyz789",
    "amount": 500.00,
    "type": "DEBIT",
    "recipientName": "Ali Ahmad",
    "description": "Payment for services",
    "date": "2025-12-06T10:30:00.000Z",
    "previousBalance": 3500.00,
    "newBalance": 3000.00
  }
}
```

**Safe Balance Exceeded Error (400):**
```json
{
  "error": "Insufficient safe balance. Your safe balance is RM 1,200.50. This withdrawal would leave you unable to pay your upcoming bills.",
  "success": false,
  "safeBalance": 1200.50,
  "requestedAmount": 1500.00
}
```

---

### 6. Get Active Subscriptions

**Endpoint:** `GET /api/subscriptions`

**Description:** Fetch all active subscriptions/recurring liabilities for a user

**Query Parameters:**
- `userExternalId` (required): User's external ID

**Example Request:**
```
GET /api/subscriptions?userExternalId=john_doe_001
```

**Success Response (200):**
```json
{
  "success": true,
  "subscriptions": [
    {
      "liability_id": 1,
      "liability_type": "SUBSCRIPTION",
      "liability_name": "Netflix Premium",
      "amount": "55.00",
      "recurrence_pattern": "MONTHLY",
      "next_due_date": "2025-12-15",
      "last_paid_date": "2025-11-15",
      "is_verified": true,
      "created_at": "2025-01-01T00:00:00.000Z"
    },
    {
      "liability_id": 2,
      "liability_type": "UTILITY",
      "liability_name": "TNB Electricity",
      "amount": "180.00",
      "recurrence_pattern": "MONTHLY",
      "next_due_date": "2025-12-20",
      "last_paid_date": null,
      "is_verified": true,
      "created_at": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

**Subscription Types:**
- `SUBSCRIPTION` - Digital subscriptions (Netflix, Spotify, etc.)
- `UTILITY` - Utilities (TNB, Air Selangor, Unifi)
- `LOAN` - Loans (car loan, personal loan)
- `BNPL` - Buy Now Pay Later (SpayLater, Atome, etc.)
- `INSURANCE` - Insurance premiums

---

### 7. Add New Subscription

**Endpoint:** `POST /api/add-subscription`

**Description:** Create a new recurring liability/subscription

**Request:**
```json
{
  "userExternalId": "john_doe_001",
  "subscriptionName": "Spotify Premium",
  "amount": 19.90,
  "type": "SUBSCRIPTION",
  "nextDueDate": "2025-12-25"
}
```

**Validation:**
- `subscriptionName` is required and non-empty
- `amount` must be > 0
- `type` must be one of: SUBSCRIPTION, UTILITY, LOAN, BNPL, INSURANCE
- `nextDueDate` is required (format: YYYY-MM-DD)
- `userExternalId` is required

**Success Response (200):**
```json
{
  "success": true,
  "subscription": {
    "id": 15,
    "name": "Spotify Premium",
    "amount": 19.90,
    "type": "SUBSCRIPTION",
    "nextDueDate": "2025-12-25",
    "message": "Spotify Premium subscription added successfully!"
  }
}
```

**Notes:**
- Automatically creates a projected payment record for the first due date
- Default recurrence pattern is `MONTHLY`
- Subscription is automatically marked as verified and active

---

### 8. Cancel Subscription

**Endpoint:** `POST /api/cancel-subscription`

**Description:** Cancel (soft delete) a subscription

**Request:**
```json
{
  "userExternalId": "john_doe_001",
  "liabilityId": 15
}
```

**Validation:**
- `userExternalId` is required
- `liabilityId` is required
- Subscription must be active

**Success Response (200):**
```json
{
  "success": true,
  "subscription": {
    "id": 15,
    "name": "Spotify Premium",
    "amount": 19.90,
    "type": "SUBSCRIPTION",
    "message": "Spotify Premium subscription cancelled successfully!"
  }
}
```

**Soft Delete Behavior:**
- Sets `is_active = false` (does NOT delete from database)
- Marks all future projected payments as `SKIPPED`
- Preserves historical data for analytics

---

## MCP Tools

The backend provides 5 MCP banking tools that Claude AI can use to answer user questions.

### Tool 1: get-safe-balance

**Description:** Calculate user's safe balance (current balance - upcoming bills)

**Input Schema:**
```typescript
{
  user_external_id: string,      // Required: User's external ID
  lookahead_days?: number         // Optional: Days to look ahead (default: 30)
}
```

**Example Call:**
```json
{
  "user_external_id": "john_doe_001",
  "lookahead_days": 30
}
```

**Output:**
```json
{
  "user_external_id": "john_doe_001",
  "current_balance": 2500.00,
  "upcoming_liabilities": 1299.40,
  "safe_balance": 1200.60,
  "status": "WARNING",
  "upcoming_count": 7,
  "next_payment_date": "2025-12-15",
  "next_payment_amount": 55.00,
  "lookahead_days": 30,
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

**Status Values:**
- `HEALTHY` - Safe balance > 30% of current balance
- `WARNING` - Safe balance 10-30% of current balance
- `CRITICAL` - Safe balance < 10% of current balance

---

### Tool 2: get-upcoming-bills

**Description:** List all upcoming bills for next N days

**Input Schema:**
```typescript
{
  user_external_id: string,      // Required: User's external ID
  lookahead_days?: number         // Optional: Days to look ahead (default: 30)
}
```

**Example Call:**
```json
{
  "user_external_id": "john_doe_001",
  "lookahead_days": 30
}
```

**Output:**
```json
{
  "user_external_id": "john_doe_001",
  "lookahead_days": 30,
  "bills_count": 7,
  "total_amount": 1299.40,
  "bills": [
    {
      "liability_name": "Netflix Premium",
      "liability_type": "SUBSCRIPTION",
      "amount": 55.00,
      "payment_date": "2025-12-15",
      "payment_status": "UNPAID"
    },
    {
      "liability_name": "TNB Electricity",
      "liability_type": "UTILITY",
      "amount": 180.00,
      "payment_date": "2025-12-20",
      "payment_status": "UNPAID"
    }
  ],
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

---

### Tool 3: check-affordability

**Description:** Check if user can afford a purchase based on safe balance

**Input Schema:**
```typescript
{
  user_external_id: string,           // Required: User's external ID
  purchase_amount: number,            // Required: Purchase amount in RM
  purchase_description?: string       // Optional: What user wants to buy
}
```

**Example Call:**
```json
{
  "user_external_id": "john_doe_001",
  "purchase_amount": 800.00,
  "purchase_description": "iPhone 15"
}
```

**Output:**
```json
{
  "user_external_id": "john_doe_001",
  "purchase_description": "iPhone 15",
  "purchase_amount": 800.00,
  "financial_overview": {
    "current_balance": 2500.00,
    "upcoming_liabilities": 1299.40,
    "safe_balance": 1200.60,
    "status": "WARNING"
  },
  "affordability_check": {
    "can_afford": true,
    "remaining_after_purchase": 400.60,
    "percentage_of_safe_balance": "66.6%"
  },
  "recommendation": "You can afford this, but it will significantly reduce your safe balance. Consider if it's essential.",
  "upcoming_bills_preview": [
    {
      "name": "Netflix Premium",
      "amount": 55.00,
      "date": "2025-12-15"
    }
  ],
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

**Recommendation Logic:**
- `can_afford = true` AND `remaining > 30% of safe balance` → "Go ahead!"
- `can_afford = true` AND `remaining > 0` → "Proceed with caution"
- `can_afford = false` → "Wait until bills are paid"

---

### Tool 4: get-spending-summary

**Description:** Analyze user's spending patterns by category

**Input Schema:**
```typescript
{
  user_external_id: string,      // Required: User's external ID
  days_back?: number              // Optional: Days to analyze (default: 30)
}
```

**Example Call:**
```json
{
  "user_external_id": "john_doe_001",
  "days_back": 30
}
```

**Output:**
```json
{
  "user_external_id": "john_doe_001",
  "period_days": 30,
  "summary": {
    "total_spent": 1850.50,
    "total_transactions": 25,
    "categories_count": 5
  },
  "categories": [
    {
      "category": "Food & Dining",
      "transaction_count": 12,
      "total_spent": 680.00,
      "average_transaction": 56.67
    },
    {
      "category": "Transportation",
      "transaction_count": 8,
      "total_spent": 450.00,
      "average_transaction": 56.25
    }
  ],
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

---

### Tool 5: save-conversation

**Description:** Store conversation history in database for context

**Input Schema:**
```typescript
{
  user_external_id: string,      // Required: User's external ID
  role: "user" | "assistant" | "system",  // Required: Message sender
  message: string,                // Required: Message content
  metadata?: Record<string, any>  // Optional: Additional metadata
}
```

**Example Call:**
```json
{
  "user_external_id": "john_doe_001",
  "role": "user",
  "message": "Can I afford a new phone?",
  "metadata": {
    "platform": "flutter",
    "device": "android"
  }
}
```

**Output:**
```json
{
  "saved": true,
  "message_id": 152,
  "user_external_id": "john_doe_001",
  "role": "user",
  "safe_balance_at_time": 1200.60,
  "created_at": "2025-12-06T10:30:00.000Z",
  "timestamp": "2025-12-06T10:30:00.000Z"
}
```

---

## Database Schema

### Key Tables

#### users
```sql
user_id                SERIAL PRIMARY KEY
external_user_id       VARCHAR(255) UNIQUE NOT NULL
name                   VARCHAR(255)
email                  VARCHAR(255)
current_balance        DECIMAL(15,2) DEFAULT 0.00
created_at             TIMESTAMP DEFAULT NOW()
updated_at             TIMESTAMP DEFAULT NOW()
```

#### recurring_liabilities
```sql
liability_id           SERIAL PRIMARY KEY
user_id                INTEGER REFERENCES users(user_id)
liability_type         VARCHAR(50)  -- SUBSCRIPTION, UTILITY, LOAN, BNPL, INSURANCE
liability_name         VARCHAR(255)
amount                 DECIMAL(10,2)
recurrence_pattern     VARCHAR(20)  -- MONTHLY, WEEKLY, etc.
next_due_date          DATE
last_paid_date         DATE
is_verified            BOOLEAN DEFAULT false
is_active              BOOLEAN DEFAULT true
created_at             TIMESTAMP DEFAULT NOW()
updated_at             TIMESTAMP DEFAULT NOW()
```

#### projected_payments
```sql
payment_id             SERIAL PRIMARY KEY
user_id                INTEGER REFERENCES users(user_id)
liability_id           INTEGER REFERENCES recurring_liabilities(liability_id)
payment_date           DATE
amount                 DECIMAL(10,2)
payment_status         VARCHAR(20)  -- UNPAID, PAID, SKIPPED
created_at             TIMESTAMP DEFAULT NOW()
UNIQUE(liability_id, payment_date)
```

#### transactions
```sql
transaction_id         SERIAL PRIMARY KEY
user_id                INTEGER REFERENCES users(user_id)
external_transaction_id VARCHAR(255)
amount                 DECIMAL(10,2)
transaction_type       VARCHAR(20)  -- CREDIT, DEBIT
description            TEXT
merchant_name          VARCHAR(255)
category               VARCHAR(100)
balance_after          DECIMAL(15,2)
transaction_date       TIMESTAMP DEFAULT NOW()
status                 VARCHAR(20)
```

### Database Views

#### v_user_safe_balance
Pre-calculated safe balance for each user:
```sql
SELECT
  user_id,
  external_user_id,
  current_balance,
  upcoming_liabilities (30-day),
  safe_balance,
  upcoming_count,
  next_payment_date,
  next_payment_amount
FROM v_user_safe_balance;
```

#### v_upcoming_payments_30days
Upcoming bills for next 30 days:
```sql
SELECT
  external_user_id,
  liability_name,
  liability_type,
  amount,
  payment_date,
  payment_status
FROM v_upcoming_payments_30days
WHERE external_user_id = 'john_doe_001';
```

---

## Error Handling

### Standard Error Response Format

```json
{
  "error": "Error message describing what went wrong",
  "success": false,
  "code": "ERROR_CODE"  // Optional
}
```

### Common HTTP Status Codes

| Status | Meaning | Example |
|--------|---------|---------|
| 200 | Success | Transaction completed |
| 400 | Bad Request | Missing required field, invalid input |
| 404 | Not Found | User not found, subscription not found |
| 500 | Server Error | Database connection failed |

### Common Error Messages

**User Not Found:**
```json
{
  "error": "User not found",
  "success": false
}
```

**Validation Error:**
```json
{
  "error": "Amount must be greater than 0",
  "success": false
}
```

**Safe Balance Exceeded:**
```json
{
  "error": "Insufficient safe balance. Your safe balance is RM 1,200.50.",
  "success": false,
  "safeBalance": 1200.50,
  "requestedAmount": 1500.00
}
```

---

## Flutter Integration Guide

### 1. Setup HTTP Client

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RytGuardApi {
  static const String baseUrl = 'http://localhost:3001';

  // For Android emulator connecting to localhost:
  // static const String baseUrl = 'http://10.0.2.2:3001';

  // For physical device:
  // static const String baseUrl = 'http://YOUR_COMPUTER_IP:3001';
}
```

### 2. Example: Reload Money

```dart
Future<Map<String, dynamic>> reloadMoney({
  required String userExternalId,
  required double amount,
  String? description,
}) async {
  final response = await http.post(
    Uri.parse('${RytGuardApi.baseUrl}/api/reload'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userExternalId': userExternalId,
      'amount': amount,
      'description': description ?? 'Reload',
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Failed to reload money');
  }
}
```

### 3. Example: Get Subscriptions

```dart
Future<List<Subscription>> getSubscriptions(String userExternalId) async {
  final response = await http.get(
    Uri.parse('${RytGuardApi.baseUrl}/api/subscriptions?userExternalId=$userExternalId'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
      return (data['subscriptions'] as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    }
  }
  throw Exception('Failed to load subscriptions');
}
```

### 4. Example: Withdraw with Validation

```dart
Future<Map<String, dynamic>> withdrawMoney({
  required String userExternalId,
  required double amount,
  required String recipientName,
  String? description,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${RytGuardApi.baseUrl}/api/withdraw'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userExternalId': userExternalId,
        'amount': amount,
        'recipientName': recipientName,
        'description': description,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return data;
    } else if (response.statusCode == 400) {
      // Handle safe balance error
      throw SafeBalanceException(
        message: data['error'],
        safeBalance: data['safeBalance'],
        requestedAmount: data['requestedAmount'],
      );
    } else {
      throw Exception(data['error'] ?? 'Withdrawal failed');
    }
  } catch (e) {
    rethrow;
  }
}
```

### 5. Model Classes

```dart
class Subscription {
  final int liabilityId;
  final String liabilityType;
  final String liabilityName;
  final double amount;
  final String recurrencePattern;
  final DateTime nextDueDate;
  final DateTime? lastPaidDate;
  final bool isVerified;

  Subscription({
    required this.liabilityId,
    required this.liabilityType,
    required this.liabilityName,
    required this.amount,
    required this.recurrencePattern,
    required this.nextDueDate,
    this.lastPaidDate,
    required this.isVerified,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      liabilityId: json['liability_id'],
      liabilityType: json['liability_type'],
      liabilityName: json['liability_name'],
      amount: double.parse(json['amount'].toString()),
      recurrencePattern: json['recurrence_pattern'],
      nextDueDate: DateTime.parse(json['next_due_date']),
      lastPaidDate: json['last_paid_date'] != null
          ? DateTime.parse(json['last_paid_date'])
          : null,
      isVerified: json['is_verified'],
    );
  }
}
```

### 6. Error Handling

```dart
class SafeBalanceException implements Exception {
  final String message;
  final double? safeBalance;
  final double? requestedAmount;

  SafeBalanceException({
    required this.message,
    this.safeBalance,
    this.requestedAmount,
  });

  @override
  String toString() => message;
}

// Usage in UI:
try {
  await withdrawMoney(...);
} on SafeBalanceException catch (e) {
  // Show specific UI for safe balance error
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Insufficient Safe Balance'),
      content: Text('Your safe balance is RM ${e.safeBalance?.toStringAsFixed(2)}. '
          'This withdrawal would leave you unable to pay upcoming bills.'),
    ),
  );
} catch (e) {
  // Handle other errors
  showSnackBar(e.toString());
}
```

### 7. Testing Locally

**For Android Emulator:**
- Use `http://10.0.2.2:3001` instead of `localhost:3001`

**For Physical Device:**
1. Find your computer's IP address (e.g., `192.168.1.100`)
2. Ensure phone and computer are on same Wi-Fi
3. Use `http://192.168.1.100:3001`

**For iOS Simulator:**
- `localhost:3001` or `127.0.0.1:3001` should work

---

## Environment Variables

The backend uses these environment variables (defined in `.env`):

```env
# Database Configuration
DB_HOST=127.0.0.1
DB_PORT=5433
DB_NAME=ryt_guard
DB_USER=postgres
DB_PASSWORD=420690

# Alternative: Full connection string
# DATABASE_URL=postgresql://user:password@host:port/database

# Anthropic API (for AI chatbot)
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# Server Port
PORT=3001
```

---

## Rate Limiting & Performance

**Current Status:** No rate limiting implemented (MVP)

**Future Considerations:**
- Implement rate limiting for production (e.g., 100 requests/minute per user)
- Add caching for frequently accessed data (safe balance, subscriptions)
- Use connection pooling for database (already implemented)

---

## Support & Documentation

**Backend Repository:** https://github.com/yourusername/RytGuard
**Issues:** Report bugs via GitHub Issues
**Contact:** [Your Email]

**Additional Resources:**
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Guide](https://expressjs.com/)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)

---

**Last Updated:** December 2025
**API Version:** 1.0.0
