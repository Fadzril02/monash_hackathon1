# 🛡️ RytGuard - AI-Powered Financial Wellness Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![TiDB](https://img.shields.io/badge/Database-TiDB%2FMySQL-orange.svg)](https://tidbcloud.com/)

> **Your AI Financial Guardian** - Helping Malaysians avoid debt traps and make smarter money decisions.

---

## 🎯 Problem We Solve

Many Malaysians struggle with:
- 💸 **Overspending** without realizing they can't afford upcoming bills
- 📊 **High Debt-to-Income Ratios** leading to financial stress
- 🤔 **Poor financial visibility** - not knowing their "safe" spendable balance
- ⚠️ **Subscription fatigue** - losing track of recurring payments
- 📉 **No financial forecasting** - unable to predict future cash flow

**RytGuard** solves this by providing:
1. **Safe Balance Calculation** - Real-time spendable amount after accounting for upcoming bills
2. **AI Financial Advisor** - Claude AI analyzes spending patterns and provides personalized advice
3. **DSR Monitoring** - Track Debt Service Ratio to avoid over-leveraging
4. **12-Month Projections** - See your financial future with realistic income/expense variations
5. **Smart Withdrawal Protection** - Prevents spending that would compromise bill payments

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│  • Provider State Management                                 │
│  • Financial Dashboard with FL Charts                        │
│  • AI Chat Interface                                         │
│  • Subscription Management                                   │
└────────────────┬────────────────────────────────────────────┘
                 │ REST API + WebSocket
                 ↓
┌─────────────────────────────────────────────────────────────┐
│              Node.js/TypeScript Backend                      │
│  • Express.js REST API                                       │
│  • MCP (Model Context Protocol) Server                      │
│  • Claude AI Integration (Anthropic SDK)                    │
│  • Financial Analysis Engine                                 │
└────────────────┬────────────────────────────────────────────┘
                 │ mysql2
                 ↓
┌─────────────────────────────────────────────────────────────┐
│                   TiDB Cloud Database                        │
│  • MySQL-compatible distributed SQL                          │
│  • Stored Procedures for Safe Balance                       │
│  • 12-month transaction history                             │
│  • Real-time financial calculations                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### **Frontend (Mobile)**
- **Flutter 3.0+** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **FL Chart** - Interactive financial charts
- **HTTP** - API communication

### **Backend**
- **Node.js 18+** - JavaScript runtime
- **TypeScript 5+** - Type-safe development
- **Express.js 5** - Web framework
- **mysql2** - MySQL client with Promise support
- **Anthropic SDK** - Claude AI integration
- **MCP SDK** - Model Context Protocol
- **Zod** - Schema validation

### **Database**
- **TiDB Cloud** - MySQL-compatible distributed database
- **MySQL 8.0+ Compatible** - Stored procedures, triggers, views
- **SSL/TLS** - Secure connections

### **AI/ML**
- **Claude Sonnet 4.5** (Anthropic) - Natural language financial advisor
- **Tool Calling** - Structured function execution
- **Context-aware** - 200K token context window

---

## 📊 Key Features

### 1. **Safe Balance System**
```
Safe Balance = Current Balance - Upcoming Bills (30 days)
```
- Real-time calculation
- Prevents overspending
- Accounts for all subscriptions, loans, and utilities

### 2. **AI Financial Advisor**
- Natural language queries: *"Can I afford this purchase?"*
- Personalized recommendations
- Context-aware analysis of spending patterns
- DSR (Debt Service Ratio) monitoring

### 3. **Financial Health Dashboard**
- **DSR Calculator** - Track debt-to-income ratio
  - 🟢 <30%: Healthy
  - 🟡 30-40%: Warning
  - 🔴 ≥40%: Critical
- **Net Cash Flow** - Monthly income vs expenses
- **Savings Rate** - Percentage saved each month
- **Emergency Fund Coverage** - Months of expenses covered

### 4. **12-Month Financial Projections**
- Baseline scenario with realistic variations
- Income fluctuations (bonuses, freelance)
- Seasonal spending (CNY, holidays)
- Inflation modeling (0.3%/month)
- What-if scenario analysis

### 5. **Smart Recommendations**
- Prioritized action items
- Financial stress index (0-100)
- Custom savings goals
- Debt reduction strategies

---

## 🚀 Getting Started

### Prerequisites
```bash
# Backend
- Node.js 18+
- npm or yarn
- TiDB Cloud account (or MySQL 8+)

# Frontend
- Flutter 3.0+
- Dart SDK
- Android Studio / Xcode
```

### Backend Setup

1. **Install dependencies:**
```bash
cd mcp_backend
npm install
```

2. **Configure environment:**
```bash
# Create .env file
cp .env.example .env

# Add your credentials:
DATABASE_URL=mysql://user:pass@host:4000/ryt_guard
ANTHROPIC_API_KEY=
```

3. **Set up database:**
```bash
# Load schema
mysql -h <host> -u <user> -p < database_schema/MYSQL-rytguard_mvp_schema.sql

# Load mock data
mysql -h <host> -u <user> -p < database_schema/MYSQL-mock_data_john_doe.sql
```

4. **Run backend:**
```bash
npm run dev
```

Server runs on `http://localhost:3001`

### Frontend Setup

1. **Install dependencies:**
```bash
cd frontend
flutter pub get
```

2. **Configure API endpoint:**
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://localhost:3001';
```

3. **Run app:**
```bash
flutter run
```

---

## 📂 Project Structure

```
monash_hackathon1/
├── frontend/                    # Flutter mobile app
│   ├── lib/
│   │   ├── config/             # API configuration
│   │   ├── models/             # Data models
│   │   ├── providers/          # State management
│   │   ├── services/           # API & business logic
│   │   ├── widgets/            # UI components
│   │   └── main.dart
│   └── pubspec.yaml
│
├── mcp_backend/                # Node.js backend
│   ├── src/
│   │   ├── minimal/            # MCP minimal implementation
│   │   ├── tools/              # Banking tools
│   │   ├── mcp-server.ts       # MCP server setup
│   │   └── server.ts           # Main Express server
│   ├── .env                    # Environment config
│   └── package.json
│
├── database_schema/            # Database schemas
│   ├── MYSQL-rytguard_mvp_schema.sql
│   └── MYSQL-mock_data_john_doe.sql
│
└── README.md
```

---

## 🔒 Security Features

- ✅ **SSL/TLS Encryption** - All database connections encrypted
- ✅ **Safe Balance Protection** - Prevents unsafe withdrawals
- ✅ **API Key Security** - Environment variable management
- ✅ **Input Validation** - Zod schema validation
- ✅ **SQL Injection Prevention** - Parameterized queries

---

## 📈 Financial Calculations

### DSR (Debt Service Ratio)
```
DSR = (Total Monthly Debt Payments / Monthly Income) × 100
```

### Safe Balance
```
Safe Balance = Current Balance - Upcoming Liabilities (30 days)
```

### Financial Stress Index
```
Stress Index = weighted_sum([
  DSR Score (30%),
  Emergency Fund Score (25%),
  Savings Rate Score (20%),
  Cash Flow Score (15%),
  Runway Score (10%)
])
```

---

## 🌏 Malaysian Context

RytGuard is built specifically for Malaysians, with support for:
- **MYR (RM)** currency
- **Local services**: TNB, Air Selangor, Unifi, Maxis, etc.
- **PTPTN loans** - Education loan tracking
- **BNPL services** - SpayLater, Atome, GrabPayLater
- **Local spending patterns** - CNY, Raya, seasonal variations

---

## 🎓 Use Cases

### For Students
- Track PTPTN loan payments
- Manage part-time income
- Budget for semester expenses

### For Young Professionals
- Monitor car loan commitments
- Track subscription services
- Plan major purchases

### For Families
- Manage household expenses
- Track utility payments
- Emergency fund planning

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🏆 Hackathon Project

**Monash Hackathon 2025**
- **Team**: That one team
- **Category**: FinTech / Financial Wellness

---

## 🙏 Acknowledgments

- **Anthropic** - Claude AI API
- **TiDB Cloud** - Database infrastructure
- **Flutter Team** - Amazing cross-platform framework
- **Monash University** - Hackathon organizers



## 🎯 Future Roadmap

- [ ] Multi-currency support
- [ ] Bank API integrations (FPX, DuitNow)
- [ ] Investment tracking
- [ ] Family account sharing
- [ ] Gamification features
- [ ] Push notifications for bills
- [ ] Expense categorization with AI

---

**Built with ❤️ for financial wellness in Malaysia** 🇲🇾
