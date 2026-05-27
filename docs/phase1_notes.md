# Phase 1 Notes — BigQuery Foundation, Exception Logic, Dashboard MVP, and First n8n Automation

## Phase goal
Phase 1 was about turning raw order, cost, and shipment data into a usable business-monitoring layer. The objective was not just to join tables, but to build a reliable exception dataset that could later power a dashboard and workflow alerts.

## 1. Business problem being solved
The project started from a simple operations and finance question:
- Which orders are financially risky?
- Which orders are operationally risky?
- Which cases should be surfaced automatically instead of being checked manually row by row?

The MVP focused on detecting:
- loss-making orders
- weak-margin orders
- late shipments
- critically delayed shipments

This became the rule-based foundation for the rest of the project.

## 2. BigQuery setup and dataset structure
The project used Google BigQuery as the main data engine.

The working dataset combined three business sources:
- orders
- costs
- shipments

The initial requirement was to join these tables in a way that preserved the business grain correctly.

### Key design choice
A `LEFT JOIN` approach was used because orders were treated as the main business grain. That meant:
- all orders should stay in the output
- even if related cost or shipment data was missing

### What this helped with
This made it easier to:
- preserve coverage
- check missing related records
- avoid accidentally dropping important business rows too early

## 3. SQL step breakdown

### Step 1 — Join base tables
The first SQL step created one combined operational-financial table by joining:
- order information
- cost information
- shipment information

#### Why it mattered
A project like this is useless if the join is wrong.

#### What had to be checked
Before moving on, the joined dataset had to be validated for:
- row count
- duplicates
- null values
- expected business grain

#### Main lesson
A query that runs is not enough. The joined output must still be validated like a real analytics product.

### Step 2 — Add business calculations
After the base join, the next layer added the core business metrics:
- `margin_value`
- `margin_pct`
- `delay_days`

#### Business meaning
- `margin_value` = selling price minus total cost
- `margin_pct` = margin as a ratio of selling price
- `delay_days` = actual delivery date minus promised date

#### Why these calculations mattered
These three fields were the real bridge between raw data and business risk.

Without them:
- there is no financial risk signal
- there is no operational delay signal
- there is nothing meaningful to flag later

#### Main learning
The project started to become useful only when the data contained real business exceptions.

### Step 3 — Add exception flags
This was the first real business logic layer.

After building the calculations, rule-based exception fields were added:
- `negative_margin_flag`
- `low_margin_flag`
- `late_shipment_flag`
- `critical_delay_flag`

#### Business interpretation
- `negative_margin_flag` = loss-making order
- `low_margin_flag` = profitable but weak-margin order
- `late_shipment_flag` = delivered after promised date
- `critical_delay_flag` = delayed by 3 or more days

#### Priority logic
A `priority_level` field was created to classify rows into:
- `High`
- `Medium`
- `Low`

#### Rule logic
- `High` = negative margin or critical delay
- `Medium` = low margin or late shipment
- `Low` = no major exception

#### Technical lesson
In BigQuery, calculated aliases cannot always be safely reused later in the same `SELECT`. Using CTEs made the logic cleaner and easier to maintain.

#### Business lesson
This was the step where the dataset stopped being just analytical and became operationally useful.

### Step 4 — Create exceptions output
A separate output layer was created to focus only on flagged rows.

#### Why this mattered
It separated:
- the full order health picture
- from the actionable exception layer

That made downstream use easier for:
- dashboards
- alerts
- workflow automation
- later AI summaries

### Step 5 — Create reusable views
Two reusable BigQuery views were introduced:
- `vw_order_health`
- `vw_exceptions`

#### Purpose of each
**`vw_order_health`**  
The full business logic layer for all orders.

**`vw_exceptions`**  
The action layer containing only flagged rows.

#### Why reusable views mattered
This was the shift from ad hoc SQL toward a more professional analytics structure.

#### Main lesson
A working query is fine for testing. Reusable views are what make the project scalable and reusable.

### Step 6 — Fix `vw_exceptions` for reporting and sorting
While using `vw_exceptions` in Looker Studio, two problems appeared:
1. `priority_level` was sorting alphabetically, not in business order
2. the time chart based on raw `order_date` was not ideal for monthly reporting

#### Fixes added
The view was updated to include:
- `priority_sort_order`
- `priority_display`
- `order_month`

#### Why
- `priority_sort_order` allowed proper business sorting
- `priority_display` made dashboard labels clearer
- `order_month` made trend analysis cleaner

#### Main lessons
Sometimes a dashboard problem is really a data model problem. It is often better to fix logic in BigQuery than to fight dashboard settings.

## 4. Dashboard MVP
The first dashboard MVP was built after the view layer became stable.

### Dashboard purpose
The dashboard made the exception output visible to business users in a simple way.

### What it likely showed
- risky orders
- margin issues
- shipment delay issues
- priority distribution
- trends over time

### Why it mattered
The dashboard proved that:
- the SQL logic was not only technically correct
- it was also readable and useful in a business-facing reporting layer

## 5. First n8n automation logic
Phase 1 also introduced the first non-AI workflow structure in n8n.

### Basic workflow idea
1. Start with a manual trigger
2. Count high-priority exceptions
3. Use an IF node to check whether action is needed
4. If yes, fetch detailed high-priority rows
5. Format the result for output
6. If no, return a clean no-action message

### Key early nodes
- Manual Trigger
- BigQuery count query
- IF node
- detailed BigQuery query
- Edit Fields node

### Why this mattered
This was the move from passive reporting to active exception monitoring.

## 6. Questions and confusion that came up in Phase 1
During Phase 1, several good doubts came up that improved the project:

### “If no exceptions exist, what happens?”
That led to the false branch logic in the IF node and the `No High-Priority Exceptions` output.

### “Why count first?”
Because the workflow should not waste effort pulling detail rows and formatting outputs if there is nothing to act on.

### “Why are helper fields useful?”
Because business-facing layers often need fields that are not raw source fields:
- sort keys
- display labels
- grouped time fields

These small helper fields made reporting far cleaner.

## 7. Key findings from Phase 1
- Real projects become useful only when calculations are translated into business signals
- The join design matters as much as the calculations
- CTE-based SQL is cleaner than trying to force all logic into one SELECT
- Reusable views are a big step toward production-style thinking
- Dashboard issues often reveal modeling issues upstream
- Phase 1 was not just SQL work; it was business logic design

## 8. Honest Phase 1 positioning
Phase 1 delivered:
- a clean BigQuery data layer
- reusable exception views
- a dashboard MVP
- a first rule-based n8n monitoring workflow

This was the automation foundation, not yet AI.

## 9. What Phase 1 enabled next
Because Phase 1 built a reliable exception dataset, it made Phase 2 possible.

Without:
- clean exception rows
- a stable view layer
- clear high-priority logic

there would have been nothing meaningful for the LLM to summarize later.
