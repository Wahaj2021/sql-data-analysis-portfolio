# Customer Churn Analysis (Banking)

Analysis of 10,000 bank customers to identify who is churning, which
segments are highest-risk, and where retention effort should focus.

## Questions answered
- What is the overall churn rate, and how does it vary by geography?
- Which customer segments are most likely to leave?
- Which current customers should the retention team prioritise?

## Key findings
- **Overall churn is 20.4%.**
- **Churn is heavily concentrated in Germany at 32.4%** — roughly double
  France (16.2%) and Spain (16.7%). Despite having half France's customer
  base, Germany produces more churned customers in absolute terms.
- **The risk-scoring model produces a prioritised retention list.** The
  highest-risk current customers are overwhelmingly German, inactive, and
  single-product holders, several with balances over £100k.

## Recommendation
Prioritise retention effort in Germany, focus on re-engaging inactive
customers, and investigate the underlying cause of the German churn gap
(pricing, product fit, or local competition).

## Techniques
Churn rate via AVG of a 0/1 flag, CASE segmentation, RANK, ROW_NUMBER,
AVG OVER (PARTITION BY), multi-condition risk scoring, CTEs.

![Retention target list](output.png)
