# Plan for RytGuard Monetization & "WOW-Factor" Features

## 1. Introduction

This document outlines a strategic plan to evolve RytGuard from a financial wellness platform into a revenue-generating ecosystem for a partner bank. The core idea is to leverage the platform's deep understanding of a user's financial health to reward responsible behavior, creating a pipeline of low-risk, high-value customers for the bank.

## 2. Core Concept: The "RytGuard Score"

The central "WOW-factor" is the introduction of a dynamic **RytGuard Score** (e.g., from 300-850, similar to a credit score). This score will be a proprietary, real-time measure of a user's financial responsibility, calculated from the rich data already in the RytGuard ecosystem.

### Score Components:

-   **Debt Service Ratio (DSR):** Lower is better. (Weight: 30%)
-   **Savings Rate & Consistency:** Higher and more consistent is better. (Weight: 25%)
-   **Emergency Fund Status:** Measured in months of coverage. (Weight: 20%)
-   **Safe Balance Management:** How well the user stays within their "Safe Balance". (Weight: 15%)
-   **Bill Payment History:** On-time payment of recurring liabilities tracked in the app. (Weight: 10%)

This score will be prominently displayed on the user's dashboard, gamifying financial health and creating a clear incentive for improvement.

## 3. Monetization & Reward Features for "Good Payers"

Users with a high RytGuard Score will unlock exclusive financial products from a partner bank. This creates a powerful value proposition for both the user and the bank.

### Feature 1: Pre-Qualified Financial Products

-   **Concept:** Offer users with high RytGuard Scores access to pre-qualified, preferential-rate loans, credit cards, or lines of credit.
-   **User Benefit:** Access to cheaper credit without a cumbersome application process. The app tells them what they can afford.
-   **Bank's Benefit:**
    -   **Reduced Risk:** The RytGuard Score provides a more accurate risk profile than traditional credit scores, which are often based on lagging data.
    -   **Lower Customer Acquisition Cost (CAC):** The bank gains direct access to a pre-vetted pool of low-risk customers.
    -   **Increased Lending Volume:** Drive new loan and credit card applications from a desirable demographic.

### Feature 2: "RytGuard BNPL" - A Responsible Buy-Now-Pay-Later Service

-   **Concept:** Introduce a BNPL service that is integrated with the user's "Safe Balance". When a user considers a BNPL purchase, RytGuard will automatically simulate the impact of future payments on their cash flow.
-   **User Benefit:** Use BNPL without the risk of falling into a debt trap. The app provides a clear "go" or "no-go" based on true affordability.
-   **Bank's Benefit:**
    -   **Enter the BNPL Market Safely:** The bank can fund the BNPL facility, earning merchant fees or interest, while the risk is mitigated by RytGuard's affordability checks.
    -   **Positive Branding:** Be seen as a promoter of *responsible* credit, contrasting with predatory BNPL models.

### Feature 3: Dynamic Insurance Premiums

-   **Concept:** Partner with the bank's insurance arm to offer discounts on insurance products (life, health, auto) based on the RytGuard Score. A financially responsible person is often a lower risk in other areas of life.
-   **User Benefit:** Lower insurance costs as a reward for good financial management.
-   **Bank's/Insurer's Benefit:** Attract a low-risk customer base, leading to a more profitable insurance portfolio and reduced claim rates.

### Feature 4: Tiered & High-Yield Savings Products

-   **Concept:** Users who maintain a certain RytGuard Score for a specified period (e.g., 3-6 months) unlock access to exclusive high-yield savings accounts or fixed deposits.
-   **User Benefit:** Earn more on their savings.
-   **Bank's Benefit:** Attract and retain "sticky" deposits from financially stable customers, increasing the bank's capital base.

### Feature 5: AI-Driven Personalized Promotions

-   **Concept:** Use Claude AI to analyze user transaction history to identify spending patterns (e.g., frequent coffee shop visitor, specific grocery stores, fuel brands). Match these patterns against a list of promotions from the partner bank and its network of merchants.
-   **User Benefit:** Receive highly relevant, personalized vouchers and discounts that help them save money on their everyday spending.
-   **Bank's Benefit:**
    -   **Hyper-Targeted Marketing:** Drive spending to partner merchants, creating opportunities for B2B revenue.
    -   **Increased Engagement:** Transform the app into a daily source of value, increasing user loyalty and interaction.
    -   **Rich Customer Insights:** Gain a deeper understanding of consumer behavior to inform future product development.

## 4. The Role of AI and the Model Context Protocol (MCP)

The existing MCP server is the key to unifying these features into a seamless, conversational experience. Instead of just clicking through menus, the user can interact with the AI Financial Advisor to explore and utilize the new features.

The AI, powered by Claude via MCP, will use "tools" that correspond to our backend services.

**Example User Conversations:**

-   **Accessing the RytGuard Score:**
    -   *User:* "Why did my RytGuard score go down?"
    -   *AI (using the `get_score_details` tool):* "I see your score dropped by 15 points this month. This was mainly because your spending exceeded your 'Safe Balance' on three occasions. Would you like some tips on managing it better?"

-   **Exploring BNPL:**
    -   *User:* "I want to buy a new laptop for RM5,000. Can I afford to use BNPL?"
    -   *AI (using the `simulate_bnpl` tool):* "I've run a simulation. A BNPL for RM5,000 would make your 'Safe Balance' negative for the next two months, which is risky. However, you could comfortably afford a purchase up to RM3,200."

-   **Discovering Promotions:**
    -   *User:* "How can I save more money?"
    -   *AI (using the `get_personalized_promotions` tool):* "I noticed you frequently shop at Jaya Grocer. Our partner bank has a promotion for 10% cashback on all purchases there this month. I've added the voucher to your wallet."

## 5. High-Level Implementation Plan

### Phase 1: Develop the RytGuard Score & Promotions Engine

1.  **Backend (Node.js/TypeScript):**
    -   Create a `ScoreService` to calculate and track the RytGuard Score.
    -   Create a `PromotionsService` to manage bank promotions and use Claude for analyzing spending patterns.
    -   Add new tools to the MCP server:
        -   `get_score_details`
        -   `get_personalized_promotions`
    -   Create new API endpoints:
        -   `GET /api/v1/users/{userId}/score`
        -   `GET /api/v1/users/{userId}/promotions`
2.  **Database (TiDB):**
    -   Add `user_scores` and `promotions` tables.
3.  **Frontend (Flutter):**
    -   Implement the RytGuard Score widget on the dashboard.
    -   Create a new "Promotions & Vouchers" section.
    -   Enhance the chat UI to better display responses from the new AI tools.

### Phase 2: Implement BNPL & Pre-Qualified Products

1.  **Backend (Node.js/TypeScript):**
    -   Develop a `ProductEligibilityService`.
    -   Add new tools to the MCP server:
        -   `get_product_offers`
        -   `simulate_bnpl`
    -   Build new API endpoints and integrate with bank APIs.
2.  **Frontend (Flutter):**
    -   Create a "Marketplace" or "Rewards" section.
    -   Build UI flows for browsing and applying for financial products.
    -   Integrate the BNPL simulation into the AI chat and potentially on product pages of partner merchants.

## 6. Conclusion

By implementing the RytGuard Score and its associated reward features, RytGuard can transform from a utility into a powerful financial marketplace. This strategy creates a virtuous cycle: users are incentivized to become more financially healthy, and the partner bank gains a unique, low-risk channel to grow its most profitable business lines. This is a win-win that delivers significant value to all stakeholders.
