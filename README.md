# Ecommerce_Data_Analyzing_using_SQL

A professional, portfolio-ready SQL analytics project based on the *Maven Fuzzy Factory* e-commerce case study.
This repository bundles the exact SQL files you uploaded (kept exactly as-is) and a career-friendly project writeup you can show to hiring managers.

---

## Project summary

**What this project is:** a complete set of real-world SQL queries and analyses for traffic & channel analysis, landing-page A/B tests, conversion funnels, cross-sell and product performance, and executive-ready monthly/quarterly reporting. The SQL files are included exactly as you provided.

**Business context:** work simulates an analyst at an e-commerce startup answering requests from CEO, Marketing Director, and Website Manager (examples: Which channels drive the most valuable traffic? Does the new landing page lift CVR? Are repeat visitors more valuable?).

**Why this is portfolio-ready:** it demonstrates domain knowledge (marketing analytics, funnels, A/B testing), advanced SQL use (session/pageview joins, temp tables, aggregation patterns), and business storytelling.

---

## Repo structure

```
Ecommerce_Data_Analyzing_using_SQL
│── README.md
│── summary_and_all_queries.md
│
├── 01_traffic_and_channel_analysis
│     ├── Traffic Source Analysis.sql
│     ├── Channel Portfolio Management.sql
│     ├── Landing Page performace and testing.sql
│     └── Cross Sell Product.sql
│
├── 02_user_and_conversion_behavior
│     ├── Analyzing Customer Behaviour.sql
│     └── Cross Sell Product.sql  (reference)
│
├── 03_projects
│     ├── Mid Course Project.sql
│     └── Final Project.sql
│
└── 04_product_performance
      └── Cross Sell Product.sql
```

> Note: `Cross Sell Product.sql` is shown in multiple logical places; the canonical copy is in `01_traffic_and_channel_analysis/Cross Sell Product.sql`.

---

## How to run these queries (recommended)

1. Download this repository (zip) and extract locally.
2. Install MySQL and MySQL Workbench (or use any SQL client).
3. Create the database (if not already):
   ```sql
   CREATE DATABASE mavenfuzzyfactory;
   USE mavenfuzzyfactory;
   ```
   then load your dataset or the course-provided DDL/data.
4. Open the `.sql` file you want to run in Workbench; run queries in logical order (some files create temporary tables that later queries expect).
5. When re-running any file: drop temporary tables if needed or run in a fresh session.

---

## Files included (short descriptions)

### 01_traffic_and_channel_analysis
- `Traffic Source Analysis.sql` — UTM breakdowns, gsearch analysis, conversion rates, weekly trends.
- `Channel Portfolio Management.sql` — compare gsearch vs bsearch, device splits, channel share & trends.
- `Landing Page performace and testing.sql` — landing page entry analysis, bounce rate, `/home` vs `/lander-1` A/B test, weekly trends and funnel.
- `Cross Sell Product.sql` — cart CTR, average products per order, AOV, revenue per cart session, and refund checks.

### 02_user_and_conversion_behavior
- `Analyzing Customer Behaviour.sql` — repeat sessions, time-to-return, repeat vs new conversions, channels used by returning users.

### 03_projects
- `Mid Course Project.sql` — mid-course deliverable: curated queries for leadership-level slides (trends, CVR lift calculations).
- `Final Project.sql` — final deliverable: quarterly trends, channel breakdowns, product margin & revenue series.

---

If you want, I can:
- create a GitHub-ready ZIP for you to upload (**already creating now**),
- generate a single-click upload guide,
- or prepare a README variant optimized for recruiters.

