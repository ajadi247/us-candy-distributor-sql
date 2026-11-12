# U.S. Candy Distributor — Sales Performance & Profitability Analysis

SQLite portfolio project using Maven Analytics’ U.S. Candy Distributor data. The analysis covers sales to U.S. customer destinations from January 2021 through December 2024.

**[Dashboard and executive report (HTML source)](report.html)** · **[SQL queries](sql/analysis.sql)** · **[Data-quality results](results/quality.csv)**

## Executive summary

| U.S. metric | 2021–2024 |
|---|---:|
| Revenue | $138,830.34 |
| Gross profit | $91,508.23 |
| Gross margin | 65.91% |
| Distinct source order IDs | 8,389 |
| Sales lines | 9,994 |
| Distinct customers | 5,009 |

- **Growth.** Revenue reached $45,959.35 in 2024, up 26.86% year over year. Gross margin moved from 66.02% in 2023 to 65.91% in 2024, a decline of 0.11 percentage points. November 2024 was the highest-revenue month at $6,741.14.
- **Division concentration.** Chocolate generated $129,019.61 in revenue (92.93% of U.S. sales) and $87,030.05 in gross profit (95.11% of U.S. gross profit). Sugar had the highest division margin at 68.10%, on $348.73 in revenue.
- **Product performance.** Wonka Bar – Triple Dazzle Caramel led revenue at $28,087.50. Wonka Bar – Scrumdiddlyumptious led gross profit at $18,907.50 with a 69.44% margin.
- **Geographic concentration.** California led the 49 reported state or district categories with $27,917.40 in revenue (20.11% of U.S. sales) and $18,479.42 in gross profit.

## Business questions

1. How much U.S. revenue and gross profit did the distributor generate, and at what margin?
2. How did monthly and annual performance change?
3. Which divisions and products drove revenue and gross profit?
4. Which customer destination states contributed the most revenue?

## Data model

| Table | Grain and key | Main fields or relationships |
|---|---|---|
| `candy_sales` | One source sales line per `row_id` (PK) | Order and customer IDs, order/ship dates, destination, units, sales/cost/profit in cents. `product_id` references `candy_products`. |
| `candy_products` | One SKU per `product_id` (PK) | Product name, catalog division, unit price and cost in cents. `factory` references `candy_factories`. |
| `candy_factories` | One factory per `factory` (PK) | Latitude and longitude. |
| `candy_targets` | One published target per `division` (PK) | Target in cents. Retained for reference. |
| `us_sales` | One U.S. sales line | Joins the sales and product tables by product ID and filters customer country to `United States`. |

Dates use validated ISO text, monetary inputs use integer cents, coordinates use real numbers, and postal codes use text to preserve formatting. The database contains all source sales rows for audit. The performance queries read the U.S. view.

## Methodology and limitations

- **Scope and timing.** U.S. customer destinations only. All trends use order date. The 200 Canadian sales lines are excluded from performance metrics. The source ship dates range from June 2026 to June 2030, so the analysis uses no shipping or fulfillment measures.
- **Financial metrics.** Revenue sums source `Sales`. Gross profit sums source `Gross Profit`, reconciled to sales less manufacturing cost on every line. Gross margin divides total gross profit by total revenue. Net profit and shipping expenses are outside the available measures.
- **Order count.** The KPI counts distinct values of the supplied `Order ID`. All 9,994 U.S. lines have an ID ending in their product ID. The source therefore supports an exact count of 8,389 source IDs, while the number of checkout transactions is unverified. Distinct counts can overlap across reporting groups.
- **Division attribution.** The product catalog supplies division and product labels. Six U.S. Fizzy Lifting Drinks lines are labeled Sugar in sales and Other in the catalog. They are reported under Other. Source labels are preserved in the sales table.
- **Targets.** The data dictionary identifies the target as a 2024 sales target, with one row per division. The provided fields and dictionary give no geography. The U.S. dashboard omits attainment because a U.S.-only target could not be confirmed.
- **Validation.** Across both countries there are 10,194 sales lines, 8,549 distinct source order IDs, 5,044 customers, 15 products, five factories, and three product divisions. SQLite integrity, foreign-key and sales-row uniqueness checks report zero errors. Gross profit reconciles on all rows.

## Source and provenance

Downloaded the official [Maven Analytics U.S. Candy Distributor dataset](https://mavenanalytics.io/data-playground/us-candy-distributor) on November 12, 2026 using the [ZIP linked from the dataset page](https://maven-datasets.s3.amazonaws.com/US+Candy+Distributor/US+Candy+Distributor.zip). Maven lists the dataset as Public Domain. The archive SHA-256 is `ea088fc31cbbd628cda03432c30bd35c48f4bf6d09b4276fd7a312b65aa5a7d4`.

The four original Candy CSVs and Maven’s data dictionary are included in `data/`. The optional ZIP lookup was inspected for structure and omitted because sales already identifies customer destination states. This database was independently built from the public dataset.

