# Purchase order analysis using R

## 📖 About This Repository
This repository contains an R-based analysis of purchase orders and inventory data, based on 2 mock datasets. The project answers the following key questions:

1️⃣ Outstanding Quantity per Article per Month
2️⃣ Number of Deleted Purchase Orders
3️⃣ Number of Purchase Orders for e-Commerce
4️⃣ Total e-Commerce Order Value
5️⃣ Expected vs. Actual Date of Receipt


## 📂 Repository Contents
-order_analysis.R |	R script containing the full analysis
-order_analysis.Rmd	| Notebook for RStudio
-anonymized_masterdata.csv | Dataset used for calculations
-anonymized_orders.csv
-README.md	This file.

🛠️ How to Run the Code
1️⃣ Download the Repository

2️⃣ Open the R Script
Open purchase_order_analysis.R in RStudio or any R environment.

3️⃣ Install Required Libraries

## 📊 Key Insights from the Analysis

🔹 How much outstanding quantity exists per article per month?
Used group_by() and summarize() to calculate quantities.

🔹 How many purchase orders were deleted?
Filtered rows where status = "deleted".

🔹 How many purchase orders are for e-Commerce?
Identified e-Com orders using filter(channel == "e-Com").

🔹 Summarized total e-Com order value
Aggregated order values per category.

🔹 Expected vs. Actual Date of Receipt
Compared expected_date and actual_date using mutate() and case_when().

📩 Contact
For questions, feel free to reach out via LinkedIn.

