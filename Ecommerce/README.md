# E-Commerce Sales Analysis

Analysis of ~542,000 transaction lines from a UK online retailer
(Dec 2010 – Dec 2011). The dataset is real and messy — it includes
cancellations, returns, missing customer IDs and invalid prices — so
data cleaning is part of the analysis.

## Data cleaning
Raw data contained cancellations (invoice starting 'C'), negative-quantity
returns, ~25% of rows with no customer ID, and rows with non-positive
prices. A `clean_sales` view isolates valid completed sales for revenue
analysis, leaving ~530,000 clean rows.

## Questions answered
- Where does revenue come from geographically?
- Which products drive the most revenue and volume?
- How is customer value distributed?

## Key findings
- **The UK dominates revenue at [UK %]%** of the total.
- **Customer value is concentrated** — the top "[VIP]" segment is a small
  share of customers but drives [VIP revenue %]% of revenue (a Pareto pattern).
- [Add one product or trend finding from your results.]

## Techniques
Bulk loading with type conversion, character-encoding handling, views,
GROUP BY/HAVING, LAG, SUM OVER, CTEs, RFM-style customer analysis.

![Customer value segments](output.png)
