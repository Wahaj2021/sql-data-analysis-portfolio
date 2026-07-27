# Retail Sales Analysis

Analysis of 1,000 retail transactions to understand what drives revenue
across gender, age, product category and time.

## Questions answered
- How does revenue split by gender and age?
- Which product categories perform best?
- How does spend vary across age groups?

## Key findings
- **Revenue is evenly spread across categories** — Electronics (34.4%),
  Clothing (34.1%), Beauty (31.5%). No single-category dependence.
- **The gender revenue gap is volume-driven, not value-driven.** Women and
  men spend almost identically per transaction (~£456 vs ~£455); women
  simply make slightly more transactions.
- **Per-transaction spend is highest among younger customers** (18–25 average
  ~£500) and declines with age, while the 46–60 group drives the most total
  revenue through sheer volume.

## Techniques
GROUP BY, CASE bucketing, DATE_FORMAT, RANK, LAG, ROW_NUMBER, PARTITION BY, CTEs.

![Category revenue by rank and share](output.png)
