# 🛡️ RytGuard - AI-Powered Financial Wellness Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![TiDB](https://img.shields.io/badge/Database-TiDB%2FMySQL-orange.svg)](https://tidbcloud.com/)
[![Claude AI](https://img.shields.io/badge/AI-Claude%204.5-purple.svg)](https://www.anthropic.com/)

> **Your AI Financial Guardian** - Helping Malaysians avoid debt traps and make smarter money decisions with real-time AI insights.

---

## 🎯 Problem We Solve

Many Malaysians struggle with:
- 💸 **Overspending** without realizing they can't afford upcoming bills
- 📊 **High Debt-to-Income Ratios** leading to financial stress
- 🤔 **Poor financial visibility** - not knowing their "safe" spendable balance
- ⚠️ **Subscription fatigue** - losing track of recurring payments
- 📉 **No financial forecasting** - unable to predict future cash flow
- 💳 **Impulse withdrawals** - spending money needed for bills

**RytGuard** solves this with AI-powered features:
1. **Safe Balance Calculation** - Real-time spendable amount after accounting for upcoming bills
2. **AI Financial Advisor** - Claude AI analyzes spending patterns and provides personalized advice
3. **Smart Withdrawal Warnings** - Multi-stage warnings before risky withdrawals
4. **AI-Ranked Promotions** - Personalized offers based on financial health
5. **DSR Monitoring** - Track Debt Service Ratio to avoid over-leveraging
6. **12-Month Projections** - See your financial future with realistic income/expense variations
7. **What-If Scenarios** - Test financial decisions before making them

---

## ✨ New Features: RytGuard Monetization & AI Promotions

### 🎁 AI-Powered Personalized Promotions

**Smart Promotion Ranking:**
- 🤖 **Claude AI analyzes your finances** - Safe balance, DSR, spending patterns
- 🎯 **Context-aware recommendations** - Different offers for different financial situations
- 🔄 **Real-time adaptation** - Changes based on your current balance

**Status-Based Promotion Logic:**

| Safe Balance Status | Promotion Priority | Reasoning |
|---|---|---|
| 🔴 **CRITICAL** (Negative/Red) | **BNPL > Cashback** > Vouchers | You need payment flexibility and savings |
| 🟡 **WARNING** (Low balance) | **Cashback** > Mixed | Focus on saving money |
| 🟢 **HEALTHY** (High balance) | **Premium Perks** > Vouchers | Enjoy luxury rewards |

**Example:**
- Current Status: CRITICAL (-RM 983) → Shows "Pay Later with Atome" 
- After Reload: HEALTHY (+RM 1,017) → Shows "Plaza Premium Lounge"

### ⚠️ Smart Withdrawal Protection

**Two-Stage Warning System:**

1. **Pre-Withdrawal Warning** (if CRITICAL status):
   - Triggers when you click "Withdraw" with red safe balance
   - Shows full financial summary
   - User must confirm to proceed

2. **Amount-Specific Warning** (if exceeds safe balance):
   - After entering amount
   - Calculates exact impact
   - User can cancel or proceed

**Benefits:**
- ✅ Informed decisions, not blocked transactions
- ✅ Clear risk communication
- ✅ User maintains control

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Flutter Mobile App (Dart)                   │
│  • Provider State Management                                 │
│  • Financial Dashboard with FL Charts                        │
│  • AI Chat Interface                                         │
│  • Subscription Management                                   │
│  • AI-Ranked Promotions Display                             │
│  • Smart Withdrawal Warnings                                 │
└────────────────┬────────────────────────────────────────────┘
                 │ REST API (JSON)
                 ↓
┌─────────────────────────────────────────────────────────────┐
│         Node.js/TypeScript Backend (Express.js)              │
│  • REST API Endpoints                                        │
│  • MCP (Model Context Protocol) Server                      │
│  • Claude AI Integration (Anthropic SDK)                    │
│  • Financial Analysis Engine                                 │
│  • Promotion Ranking Service (AI-powered)                   │
│  • Safe Balance Protection Logic                            │
└────────────────┬────────────────────────────────────────────┘
                 │ mysql2 (SSL)
                 ↓
┌─────────────────────────────────────────────────────────────┐
│              TiDB Cloud Database (MySQL 8.0)                 │
│  • Distributed SQL with ACID guarantees                     │
│  • Views for Safe Balance calculation                       │
│  • Transaction history (12+ months)                         │
│  • Promotions table with AI-ranking metadata                │
│  • Real-time financial calculations                          │
└─────────────────────────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────────┐
│                   Claude AI (Anthropic)                      │
│  • Sonnet 4: Chat, financial advice, affordability          │
│  • Haiku 4.5: Fast promotion ranking                        │
│  • MCP Tool Calling for structured data access              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### **Frontend (Mobile)**
- **Flutter 3.9+** - Cross-platform mobile framework (iOS/Android/Web)
- **Dart 3.0+** - Type-safe programming language
- **Provider 6.1+** - Lightweight state management
- **FL Chart 0.69+** - Beautiful interactive financial charts
- **HTTP 1.2+** - REST API communication
- **Intl** - Date formatting and localization

### **Backend**
- **Node.js 24.x** - JavaScript runtime (Vercel requirement)
- **TypeScript 5+** - Type-safe development
- **Express.js 5** - Minimal web framework
- **mysql2** - MySQL client with Promise support
- **Anthropic SDK** - Claude AI integration
- **MCP SDK** - Model Context Protocol for AI tools
- **Zod** - Runtime schema validation
- **dotenv** - Environment configuration

### **Database**
- **TiDB Cloud** - MySQL-compatible distributed database
- **MySQL 8.0+ Compatible** - Full SQL support
- **Views** - Optimized safe balance calculations
- **SSL/TLS** - Secure connections
- **Connection Pooling** - High performance

### **AI/ML**
- **Claude Sonnet 4** (Anthropic) - Main financial advisor, chat, and affordability checks
- **Claude Haiku 4.5** (Anthropic) - Fast promotion ranking
- **Tool Calling** - Structured function execution via MCP
- **Context-aware** - 200K token context window
- **Streaming** - Real-time chat responses

### **Model Context Protocol (MCP)**
- **Custom Banking Tools** - Safe balance, affordability, projections
- **Promotion Ranking Tool** - AI-powered offer selection
- **System Prompts** - Financial advisor persona and promotion logic
- **Tool Registration** - Type-safe tool definitions

---

## 📊 Key Features

### 1. **Safe Balance System** 🛡️
```
Safe Balance = Current Balance - Upcoming Bills (30 days)
```
- Real-time calculation using TiDB views
- Prevents overspending
- Accounts for all subscriptions, loans, and utilities
- Visual status indicators (🟢 HEALTHY, 🟡 WARNING, 🔴 CRITICAL)

### 2. **AI Financial Advisor** 🤖
- Natural language queries: *"Can I afford this purchase?"*
- Personalized recommendations based on spending patterns
- Context-aware analysis with 200K token context
- DSR (Debt Service Ratio) monitoring
- MCP tool calling for structured data access

### 3. **Smart Withdrawal Protection** ⚠️
**Two-Stage Warning System:**
- **Stage 1**: Pre-withdrawal warning if safe balance is CRITICAL
  - Shows full financial snapshot
  - Clear risk explanation
  - User must explicitly continue
- **Stage 2**: Amount-specific warning if withdrawal exceeds safe balance
  - Real-time impact calculation
  - Option to cancel or proceed
- **Philosophy**: Inform, don't block. User maintains final control.

### 4. **AI-Powered Promotions** 🎁
**Intelligent Ranking Engine:**
- Claude AI (Haiku 4.5) analyzes 10+ promotions
- Ranks by relevance to your financial situation
- Updates after reload/withdraw transactions
- Persistent cache during navigation

**Smart Selection Logic:**
- **CRITICAL Status** → BNPL & Cashback (need flexibility)
- **WARNING Status** → Cashback & Savings (be cautious)
- **HEALTHY Status** → Premium Perks & Vouchers (enjoy rewards)

**Features:**
- Main page banner shows top-ranked promotion
- Full promotions page with all ranked offers
- Beautiful promotional images
- Tap banner to navigate to full promotions

### 5. **Financial Health Dashboard** 📈
- **DSR Calculator** - Track debt-to-income ratio
  - 🟢 <30%: Healthy
  - 🟡 30-40%: Warning
  - 🔴 ≥40%: Critical
- **Net Cash Flow** - Monthly income vs expenses
- **Savings Rate** - Percentage saved each month
- **Emergency Fund Coverage** - Months of expenses covered

### 6. **12-Month Financial Projections** 🔮
- Baseline scenario with realistic variations
- Income fluctuations (bonuses, freelance, seasonal)
- Expense variations (utilities, maintenance)
- Inflation modeling (0.3%/month)
- What-if scenario analysis:
  - Add new subscription
  - Emergency expense simulation
  - Income change scenarios
- Interactive charts with FL Chart

### 7. **Subscription Management** 📱
- Track all recurring payments
- Visual upcoming bills timeline
- Add/cancel subscriptions
- Auto-projected payment dates
- Impact analysis on safe balance

### 8. **Smart Recommendations** 💡
- Prioritized action items
- Financial stress index (0-100)
- Custom savings goals
- Debt reduction strategies
- AI-generated insights

---

## 🚀 Getting Started

### Prerequisites
```bash
# Backend
- Node.js 24.x (Vercel requirement)
- npm or yarn
- TiDB Cloud account (or MySQL 8+)
- Anthropic API key (Claude AI)

# Frontend
- Flutter 3.9+
- Dart SDK
- Chrome (for web testing) or Android Studio / Xcode
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
ANTHROPIC_API_KEY=sk-ant-...your-key...
```

3. **Set up database:**
```bash
# Load main schema
mysql -h <host> -u <user> -p < database_schema/MYSQL-rytguard_mvp_schema.sql

# Load mock user data
mysql -h <host> -u <user> -p < database_schema/MYSQL-mock_data_john_doe.sql

# Load promotions schema
mysql -h <host> -u <user> -p < database_schema/MYSQL-promotions_schema.sql

# Load mock promotions
mysql -h <host> -u <user> -p < database_schema/MYSQL-mock_data_promotions.sql
```

Or use the Node.js setup script:
```bash
npm run setup:promotions
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
// Update based on your platform:
static const String baseUrl = 'http://localhost:3001'; // Web
// or 'http://10.0.2.2:3001' for Android Emulator
```

3. **Verify assets:**
```bash
# Promotional images should be in:
frontend/assets/images/promotions/
  - promo_1.png through promo_8.png
```

4. **Run app:**
```bash
# For web (Chrome)
flutter run -d chrome

# For Android emulator
flutter run -d android

# For iOS simulator
flutter run -d ios
```

### MCP Server Setup (Optional - for Cursor AI integration)

1. **Install UV:**
```bash
pip install uv
```

2. **Configure Cursor:**
Create `.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "tidb-mcp-server": {
      "command": "python",
      "args": ["-m", "uvx", "tidb-mcp-server"],
      "env": {
        "TIDB_HOST": "your-host.aws.tidbcloud.com",
        "TIDB_PORT": "4000",
        "TIDB_USER": "your-user",
        "TIDB_PASSWORD": "your-password",
        "TIDB_DATABASE": "ryt_guard"
      }
    }
  }
}
```

---

## 📂 Project Structure

```
monash_hackathon1/
├── frontend/                    # Flutter mobile app
│   ├── lib/
│   │   ├── config/             # API configuration
│   │   │   └── api_config.dart
│   │   ├── models/             # Data models
│   │   │   ├── safe_balance.dart
│   │   │   ├── subscription.dart
│   │   │   ├── transaction.dart
│   │   │   ├── promotion.dart
│   │   │   └── financial_analysis.dart
│   │   ├── providers/          # State management
│   │   │   └── app_state.dart
│   │   ├── services/           # API & business logic
│   │   │   ├── api_service.dart
│   │   │   └── projection_service.dart
│   │   ├── widgets/            # UI components
│   │   │   ├── promotion_card.dart
│   │   │   ├── promotions_page.dart
│   │   │   └── prediction_dashboard.dart
│   │   └── main.dart           # App entry point
│   ├── assets/
│   │   └── images/
│   │       └── promotions/     # Promotional images
│   └── pubspec.yaml
│
├── mcp_backend/                # Node.js backend
│   ├── src/
│   │   ├── minimal/            # MCP minimal implementation
│   │   ├── tools/              # Banking tools
│   │   │   ├── banking-tools.ts
│   │   │   └── promotions-tools.ts
│   │   ├── prompts/            # AI system prompts
│   │   │   └── promotion-advisor-prompt.ts
│   │   ├── services/           # Business logic
│   │   │   └── promotion-service.ts
│   │   ├── models/             # TypeScript interfaces
│   │   │   └── promotion.ts
│   │   ├── mcp-server.ts       # MCP server setup
│   │   └── server.ts           # Main Express server
│   ├── .env                    # Environment config
│   ├── setup-promotions.js     # Database setup script
│   └── package.json
│
├── database_schema/            # Database schemas & data
│   ├── MYSQL-rytguard_mvp_schema.sql
│   ├── MYSQL-mock_data_john_doe.sql
│   ├── MYSQL-promotions_schema.sql
│   └── MYSQL-mock_data_promotions.sql
│
├── promotion_image/            # Source promotional images
│
├── plan.md                     # Feature planning document
└── README.md                   # This file
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
- Manage part-time income with irregular schedule
- Budget for semester expenses and textbooks
- Get alerts before bills due
- See promotions for student essentials

### For Young Professionals
- Monitor car loan commitments
- Track multiple subscription services (Netflix, Spotify, gym)
- Plan major purchases (laptop, phone)
- DSR monitoring for credit applications
- Receive relevant BNPL offers for necessary items

### For Families
- Manage household expenses
- Track utility payments (TNB, water, Unifi)
- Emergency fund planning
- What-if analysis for major life events
- Premium perks for family activities

---

## 🧪 Demo User

**Test Account:**
- External ID: `john_doe_001`
- Initial Balance: RM 1,814.69
- Upcoming Bills: RM 2,798.50
- Safe Balance: RM -983.81 (CRITICAL)
- DSR: 85% (Very High)

**Test Scenarios:**
1. Try withdrawing money → See CRITICAL warning
2. Reload RM 2,000 → Watch safe balance turn HEALTHY
3. Check promotions → See how AI ranks differently
4. Use What-If scenarios → Add emergency expense
5. Chat with AI → Ask "Can I afford a RM 1,000 laptop?"

---

## 🎯 AI Promotion Ranking Logic

### How It Works:

1. **Financial Data Collection**:
   - Safe balance, current balance, upcoming bills
   - DSR (Debt Service Ratio)
   - Average monthly income/expenses
   - Recent spending patterns

2. **AI Analysis** (Claude Haiku 4.5):
   - Evaluates user's financial health
   - Considers status (CRITICAL/WARNING/HEALTHY)
   - Analyzes spending categories

3. **Smart Ranking**:
   - **CRITICAL**: BNPL → Cashback → Others
   - **WARNING**: Cashback → Mixed → Premium
   - **HEALTHY**: Premium → Vouchers → Cashback

4. **Real-Time Updates**:
   - Cache cleared after reload/withdraw
   - Fresh ranking based on new balance
   - Persistent during navigation

### Example:
```
Before: Safe Balance -RM 983 (CRITICAL)
Ranking: [BNPL, BNPL, Cashback, ...]
Banner: "Pay Later with Atome" ← Top pick

After Reload RM 2000: Safe Balance +RM 1,017 (HEALTHY)
Ranking: [Premium Lounge, VIP Dining, ...]
Banner: "Plaza Premium Lounge" ← New top pick
```

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Guidelines
- Follow TypeScript/Dart best practices
- Add tests for new features
- Update documentation
- Keep commits atomic and descriptive

---

## 📱 API Endpoints

### Core Banking APIs
- `GET /health` - Backend health check
- `POST /api/reload` - Reload money to account
- `POST /api/withdraw` - Withdraw money with safe balance check
- `POST /api/check-withdrawal` - Pre-check withdrawal impact
- `GET /api/subscriptions` - Get active subscriptions
- `POST /api/add-subscription` - Add new recurring payment
- `POST /api/cancel-subscription` - Cancel subscription

### AI & Analysis APIs
- `POST /api/chat` - Chat with Claude AI financial advisor
- `GET /api/promotions` - Get AI-ranked promotions
- `POST /api/query` - Direct database query (internal use)

### MCP Tools (for Claude AI)
- `get-safe-balance` - Calculate safe spendable amount
- `check-affordability` - Check if user can afford a purchase
- `rank-promotions` - Rank promotions by financial relevance

---

## 🎨 UI/UX Features

### Main Dashboard
- **Header** - Branding and user profile
- **Promotion Banner** - Top AI-ranked promotion with image
- **Safe Balance Card** - Real-time balance with color-coded status
- **AI Chatbot** - Conversational financial advisor
- **Upcoming Bills** - Next 30 days of payments
- **Quick Actions** - Reload, Withdraw, Add/Cancel subscriptions

### Predictions Dashboard
- **Financial Health Metrics** - DSR, Savings Rate, Cash Flow
- **12-Month Projection Chart** - Interactive line chart
- **What-If Scenarios** - Add hypothetical scenarios
- **Recommendations** - AI-generated action items

### Promotions Page
- **Grid Layout** - 2-column responsive design
- **Promotion Cards** - Image, title, subtitle, description
- **AI Ranking** - Sorted by relevance to user
- **Visual Indicators** - Type badges, conditions

### Design System
- **Color Palette**: 
  - Primary: Blue (#0000E6)
  - Success: Green (#10B981)
  - Warning: Orange (#FF6B35)
  - Danger: Red (#EF4444)
- **Typography**: Arial with Roboto fallback
- **Shadows**: Subtle elevation for depth
- **Animations**: Smooth transitions (300ms)

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

### Phase 1: Core Enhancements
- [ ] Push notifications for upcoming bills
- [ ] Expense categorization with AI
- [ ] Transaction tagging and notes

### Phase 2: Banking Integration
- [ ] Bank API integrations (FPX, DuitNow)
- [ ] Real-time transaction sync
- [ ] Multiple account support
- [ ] Credit card integration

### Phase 3: Advanced Features
- [ ] Investment tracking (ASB, EPF, stocks)
- [ ] Multi-currency support
- [ ] Family account sharing
- [ ] Gamification features (achievements, streaks)
- [ ] Social features (anonymized spending comparisons)

### Phase 4: Monetization
- [ ] Premium subscription tier
- [ ] Affiliate partnerships with BNPL providers
- [ ] Commission on financial products
- [ ] White-label solution for banks

---

## 🏆 Hackathon Project

**Monash Hackathon 2025**
- **Team**: That One Team
- **Category**: FinTech / Financial Wellness
- **Technologies**: Flutter, Node.js, TiDB, Claude AI, MCP
- **Highlights**:
  - ✨ AI-powered promotion ranking
  - 🛡️ Smart withdrawal protection
  - 📊 12-month financial projections
  - 🤖 Conversational AI advisor with MCP tools

---

## 🙏 Acknowledgments

- **Anthropic** - Claude AI API and MCP SDK
- **TiDB Cloud** - Distributed database infrastructure
- **Flutter Team** - Amazing cross-platform framework
- **Monash University** - Hackathon organizers and platform

---

**Built with ❤️ for financial wellness in Malaysia** 🇲🇾

**Powered by:**
- 🤖 Anthropic Claude AI
- 🗄️ TiDB Cloud
- 📱 Flutter
- 🟢 Node.js
