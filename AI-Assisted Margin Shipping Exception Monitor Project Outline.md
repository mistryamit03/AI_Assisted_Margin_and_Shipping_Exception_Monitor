# AI-Assisted Margin and Shipping Exception Monitor (Updated MVP Outline)

**Dashboard Preview (Screenshot):** [Looker Studio Dashboard](https://datastudio.google.com/u/0/reporting/e5c3c570-ec96-4b92-84d9-079da9944e3f/page/lZquF)  
**Workflow Export:** [phase3_memory_routing.json](https://github.com/mistryamit03/AI_Assisted_Margin_and_Shipping_Exception_Monitor/blob/main/workflows/phase3_memory_routing.json)  
**Workflow Diagram:** [AI_Assisted_Margin_and_Shipping_Exception_Monitor Workflow Diagram](https://github.com/mistryamit03/AI_Assisted_Margin_and_Shipping_Exception_Monitor/blob/main/Screenshots/n8n_workflow_full.png)

---

## 1) Project Summary

This project is an end-to-end analytics and workflow automation MVP that monitors **margin risk** and **shipping exceptions** from order and shipment data.

It combines:
- **BigQuery** for SQL-based exception detection and memory logic
- **Looker Studio** for dashboard visibility
- **n8n** for workflow orchestration and action routing
- **Ollama** with a local model (`llama3.2:1b`) for AI-generated business summaries
- **Gmail** for alert delivery and visual proof of workflow output

The project started as a lightweight exception-monitoring automation and evolved into an **AI-assisted exception workflow with memory and routing**.

### Honest positioning
- This is **more advanced than a simple dashboard or alert pipeline**
- It is **closer to agent-like behavior** because it compares current exceptions against memory and routes actions accordingly
- It is **not yet a full AI agent** because actions are still rule-based, memory behaves more like run history than full stateful memory, and dynamic planning/tool use is not implemented

---

## 2) Business Problem

In many businesses, operational order and shipment data are spread across CSV files, spreadsheets, and disconnected systems.

This creates three common problems:
1. **Low-margin or loss-making orders are detected too late**
2. **Shipping delays are reviewed manually and reactively**
3. **Stakeholders do not receive a fast, structured explanation of what matters most and what to do next**

This project solves that by using SQL logic to detect risky exceptions, surfacing them in a dashboard, summarising them with an LLM, and routing the result into different actions.

---

## 3) Updated MVP Goal

Build a practical end-to-end workflow that:
- uses structured order, cost, and shipment data already loaded into **BigQuery**
- calculates margin and delay metrics in SQL
- flags business-critical exceptions such as negative margin and late shipments
- displays exception KPIs in **Looker Studio**
- uses **n8n** to query and process the top high-priority exceptions
- uses a local **Ollama** model to generate a plain-English business summary
- sends an email with both the AI summary and the exception table
- stores exception history in a memory table to distinguish **new** vs **known** exceptions
- routes the workflow into **ALERT** vs **MONITOR** depending on the detected state

This is not a production deployment. It is a **portfolio-ready MVP** that proves analytics engineering, automation, and AI-assisted decision support.

---

## 4) What Was Actually Implemented

The initial outline described a broader concept. The executed MVP is more specific and more honest.

### Implemented
- mock order, cost, and shipment datasets loaded into **BigQuery**
- SQL joins, calculations, and flag logic
- exception views in BigQuery
- Looker Studio dashboard MVP
- manual-trigger **n8n** workflow
- local **Ollama** LLM summary step
- Gmail notification with summary + exception table
- memory table and comparison view for **new vs known** exception logic
- action routing in n8n

### Not implemented in this MVP
- automatic CSV ingestion from source systems via n8n
- scheduled production execution
- Slack / Teams / Notion output channels
- a full autonomous agent with dynamic planning and tool selection

---

## 5) Current Project Architecture

### Data layer: BigQuery
BigQuery is used for:
- raw and transformed order logic
- exception calculations
- history storage
- comparison logic between current vs past exceptions

### Dashboard layer: Looker Studio
Looker Studio is used for:
- KPI cards
- exception breakdowns
- exception review table
- dashboard screenshot proof for the portfolio

### Workflow layer: n8n
n8n is used for:
- triggering the workflow manually
- querying current exceptions from BigQuery
- aggregating rows into one AI input
- calculating exact counts for routing
- generating the AI summary
- sending email notifications
- writing current runs back into memory

### AI layer: Ollama
Ollama is used locally with:
- model: **`llama3.2:1b`**
- role: summarise exception patterns in plain English for stakeholder-friendly interpretation

---

## 6) BigQuery Data Model and SQL Logic

### Source tables
The MVP uses three BigQuery source tables:
- `Orders`
- `Costs`
- `Shipments`

### Core calculated fields
The project calculates:
- `margin_value = selling_price - total_cost`
- `margin_pct = SAFE_DIVIDE(margin_value, selling_price)`
- `delay_days = DATE_DIFF(actual_delivery_date, promised_delivery_date, DAY)`

### Exception flags
The monitor uses the following rules:
- **negative_margin_flag**: `margin_value < 0`
- **low_margin_flag**: `margin_value >= 0 AND margin_pct < 0.10`
- **late_shipment_flag**: `delay_days > 0`
- **critical_delay_flag**: `delay_days >= 3`

### Priority logic
High-priority rows are determined when the row is severe enough to require faster attention. In the current workflow, the selected review set focuses on rows where:
- `priority_level = 'High'`

### BigQuery views created

#### `vw_order_health`
This view represents the broader calculated order health output. It contains:
- joined order, cost, and shipment data
- margin and delay calculations
- exception flags

#### `vw_exceptions`
This view contains only the rows that match exception criteria. It is the base exception layer for the dashboard and workflow.

#### `vw_exception_agent_input`
This Phase 3 view compares current exceptions against memory. It adds:
- `exception_signature`
- `is_new_exception`
- `status` (`new` or `known`)

### Memory table created

#### `exception_memory`
This table stores exception records from each workflow run. It currently acts as a **run history / memory log**, not a deduplicated state table.

---

## 7) Dashboard MVP Implemented

The Looker Studio dashboard was built on top of the exception views.

### Implemented KPI cards
- Total Exception Orders
- High Priority Exceptions
- Negative Margin Orders
- Late Shipments
- Critical Delays

### Implemented charts
- Exceptions by Priority Level
- Exceptions by Country
- Exceptions by Product Type
- Exceptions over Time
- Detailed exception review table

### What the dashboard proves
- SQL logic is working
- exception counts are visible to stakeholders
- the workflow is not just an AI demo; it sits on top of a real analytics layer

---

## 8) n8n Workflow Design: Final Implemented Flow

### Trigger
- **Manual trigger** for demo and testing

### Phase 1: Automation workflow (without AI)
1. Count high-priority exceptions in BigQuery
2. Use an **IF** node to decide whether any serious exceptions exist
3. If yes, fetch the top high-priority exception rows
4. Add business fields such as `alert_type` and `run_mode`
5. If no, prepare a no-action output branch

### Phase 2: AI-assisted workflow
6. Aggregate the exception rows into one item called `exceptions`
7. Send the aggregated data to **Basic LLM Chain** using **Ollama**
8. Generate one plain-English business summary
9. Merge structured data and AI output
10. Send the result by email with an HTML table

### Phase 3: Memory and routing workflow
11. Use an **Agent Prep** step to compute:
   - `total_exception_count`
   - `new_exception_count`
   - `known_exception_count`
   - `agent_action`
12. Route the merged result into:
   - **Gmail Alert** if `agent_action = ALERT`
   - **Gmail Monitor** if `agent_action = MONITOR`
13. Write the current compared exception rows back into `exception_memory`

### Final true-branch workflow structure
`Manual Trigger -> BigQuery Count -> IF -> BigQuery Detail Query -> Edit Fields -> Aggregate -> Agent Prep -> Basic LLM Chain + Ollama -> Merge -> IF (ALERT/MONITOR) -> Gmail -> BigQuery Insert into Memory`

---

## 9) How AI Is Used in the Final MVP

The AI does **not** detect exceptions directly. Detection is still based on SQL because SQL is deterministic, explainable, and easier to validate.

### What the LLM does
The LLM receives:
- the top reviewed exception rows
- exact counts computed in n8n
- memory state (`new` vs `known`)
- a required action label

It then generates a short stakeholder summary that explains:
- how many rows were reviewed
- how many are new vs known
- what patterns are visible
- whether the workflow recommends **ALERT** or **MONITOR**

### Important learning from implementation
At first, the model was asked to infer too much directly from raw JSON, which caused inconsistent counts and unstable summaries.

This was improved by:
- computing exact counts in **Agent Prep**
- passing those counts into the prompt
- using the model mainly for explanation, not for counting

---

## 10) Phase-by-Phase Build Summary

### Phase 1: SQL and exception automation
Implemented:
- dataset joins
- margin calculations
- delay calculations
- flag logic
- exception output view
- workflow trigger and branch logic

### Phase 2: AI summary and proof output
Implemented:
- local Ollama setup with `llama3.2:1b`
- aggregate step for one combined AI input
- Basic LLM Chain summary generation
- Gmail email with summary + exception table

### Phase 3: Memory and action routing
Implemented MVP:
- `exception_memory` table
- `vw_exception_agent_input` comparison view
- `exception_signature` generation
- `new` vs `known` labelling
- `Agent Prep` count logic
- `ALERT` vs `MONITOR` routing
- writing the current run back into memory

### Honest Phase 3 status
Phase 3 is **implemented as an MVP**, but it is still rule-driven. It proves memory and routing, but it is not yet a fully autonomous agent.

---

## 11) Key Findings from the Build

### Finding 1: SQL should remain the source of truth
The LLM produced varying row counts and unstable summaries when asked to infer directly from raw JSON. The fix was to let SQL and n8n compute the exact counts and let the LLM only explain them.

### Finding 2: Aggregation is essential before the AI step
Before adding the **Aggregate** node, the LLM ran multiple times because it was receiving row-by-row items. After aggregation, the workflow generated one summary for the whole exception set.

### Finding 3: Summary-only alerts were too weak
A plain text blurb was not enough for trust. Adding the exception table to the Gmail body made the output much stronger and more credible.

### Finding 4: Memory works, but the current design behaves like history
The `exception_memory` table currently stores a run-by-run history. This is enough for MVP comparison, but repeated executions create duplicate rows with different `status` values. That is acceptable for the current prototype, but not ideal for a cleaner stateful memory design.

### Finding 5: Routing makes the workflow more agent-like
Adding:
- `new_exception_count`
- `known_exception_count`
- `agent_action`
- and **ALERT vs MONITOR** routing moved the project beyond a simple alert pipeline.

---

## 12) Recommendations for Improvement

### Recommendation 1: Improve summary quality further
The AI output is functional, but still somewhat raw and list-like. A stronger next step would be:
- tighter prompt wording
- more deterministic phrasing
- cleaner executive summaries

### Recommendation 2: Split memory into history vs state
Right now `exception_memory` behaves like a history log. A more mature design would separate:
- `exception_history`
- `exception_state`

so the workflow can reason more cleanly about recurring vs active exceptions.

### Recommendation 3: Add stronger state transitions
Instead of only `new` vs `known`, future versions could track:
- recurring
- resolved
- worsened
- improved

### Recommendation 4: Add scheduling
The current workflow uses a manual trigger for demo clarity. A next step would be a daily scheduled trigger.

### Recommendation 5: Add a second output channel
Email is enough for proof, but future versions could also send results to:
- Google Sheets
- Slack
- Teams
- Notion

---

## 13) Final One-Line Summary

A portfolio-ready AI-assisted exception monitoring workflow that detects margin and shipping risks in BigQuery, summarises them with a local LLM, routes alerts through n8n, and uses memory to distinguish new vs known exceptions for faster operational action.
