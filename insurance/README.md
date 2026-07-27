# Insurance Charges Analysis

Analysis of 1,338 medical insurance policyholders to identify what drives
insurance charges.

## Questions answered
- Which factors most affect medical insurance charges?
- Do factors interact, or act independently?

## Key findings
- **Smoking is by far the biggest single driver** — smokers average ~$32,050
  versus ~$8,434 for non-smokers, nearly 4×.
- **The real story is the interaction between smoking and obesity.** Obesity
  alone barely moves charges for non-smokers (~$8,843 vs ~$7,977). But obese
  smokers average ~$41,558 — far more than either factor alone would predict.
- Age has a steady upward effect; sex and region have only minor influence.

## Note
This is observational data, so these are associations, not proven causes.

## Techniques
Aggregation, CASE bucketing (age bands, WHO BMI categories), two-factor
interaction analysis, RANK window function.

![Smoking and BMI interaction](output.png)
