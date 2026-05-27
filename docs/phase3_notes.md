# Phase 3 Notes — Memory Table, Comparison View, Agent Prep, Routing, Writeback, and Demo Reset Logic

## Phase goal
Phase 3 was the step that made the project feel more agent-like.

The goal was to move from:
- “summarize the current exception rows”

to:
- “compare current exceptions against past runs”
- “identify what is new versus already known”
- “route different actions”
- “store the latest run back into memory”

This was the first phase where the workflow stopped being purely linear and started behaving like a simple state-aware monitoring system.

## 1. Why Phase 3 was needed
Phase 2 could summarize current exceptions, but it still had a major limitation: it treated every run as if the workflow had no history.

That meant:
- repeated exceptions looked new every time
- there was no memory of prior runs
- the AI had no state context
- the workflow could not distinguish between:
  - something newly broken
  - something already known

Phase 3 solved that.

## 2. `exception_memory` table
A BigQuery table called:
- `exception_memory`

was created to store exception history across runs.

### Table purpose
It stores the key details of each run’s high-priority exceptions, including:
- run timestamp
- order information
- business metrics
- signature
- new/known flag at that moment
- status
- workflow metadata such as alert type and run mode

### Why this mattered
This became the workflow’s memory layer.

### Important note
The current design is append-only. That means every successful run writes another batch of rows into memory.

So this table behaves more like:
- a run history log

than:
- a perfectly deduplicated state table

### Honest limitation
This is fine for an MVP, but it is not yet a perfect long-term agent memory design.

## 3. `exception_signature`
To compare current exceptions against past exceptions, each exception row needed a consistent identifier.

That became:
- `exception_signature`

### How it works
The signature is created by hashing together key rule-based fields, such as:
- order_id
- negative_margin_flag
- low_margin_flag
- late_shipment_flag
- critical_delay_flag

### Why this mattered
If the same business condition appears again, it should generate the same signature.

That made it possible to ask:
- “Have I seen this exception pattern before?”

### Conceptual meaning
The signature is like a fingerprint for the exception state of that order.

## 4. `vw_exception_agent_input`
A new BigQuery comparison view was created:
- `vw_exception_agent_input`

### What it does
This view:
1. reads the current exception rows from `vw_exceptions`
2. creates their `exception_signature`
3. compares those signatures against the distinct signatures already stored in `exception_memory`
4. labels each current row as:
   - `is_new_exception = TRUE/FALSE`
   - `status = 'new'/'known'`

### Why this mattered
This was the key transition from static monitoring to memory-aware monitoring.

### Core business question it answered
For today’s high-priority exceptions:
- which ones are new?
- which ones are already known?

## 5. New Phase 3 BigQuery retrieval logic
The detailed exception query in n8n changed.

### Before
The workflow fetched from:
- `vw_exceptions`

### After
The workflow fetched from:
- `vw_exception_agent_input`

### Why that change mattered
Before, the workflow only knew:
- current high-priority rows

After, it also knew:
- `exception_signature`
- `is_new_exception`
- `status`

That extra context powered the rest of Phase 3.

## 6. Agent Prep node
One of the most important new nodes in Phase 3 was:
- `Agent Prep`

### Why it was added
The AI should not be trusted to calculate basic counts by itself.

Instead, n8n computed the facts directly.

### Fields added
The Agent Prep node computed:
- `total_exception_count`
- `new_exception_count`
- `known_exception_count`
- `agent_action`

### Action logic
The action logic was intentionally simple:
- if any exception is new → `ALERT`
- otherwise → `MONITOR`

### Why this mattered
This made the workflow:
- more deterministic
- easier to debug
- less dependent on LLM counting

### Main lesson
Let the workflow compute facts. Let the LLM explain those facts.

## 7. Updated Basic LLM Chain prompt
The Phase 3 prompt was updated so the model used:
- the exact counts from Agent Prep
- the structured exception array
- tighter instructions about what it could and could not say

### Prompt goals
The LLM was asked to:
- explain what is new versus known
- mention patterns directly visible in the data
- avoid inventing causes
- avoid markdown
- keep the answer short

### Why this mattered
The LLM now reasoned over a memory-aware input, not just raw rows.

### Honest limitation
The text quality still remained weaker than the workflow logic. The workflow structure became strong; the model summary stayed simple.

## 8. Merge node in Phase 3
The **Merge** node combined:
- structured Agent Prep output
- AI summary text

### Input 1
Agent Prep:
- exceptions
- counts
- action label

### Input 2
Basic LLM Chain:
- text summary

### Output
One combined item containing both:
- machine-structured fields
- human-readable AI text

### Why this mattered
This made the next nodes much simpler because they only had to read one final combined payload.

## 9. ALERT vs MONITOR routing
A second IF node was introduced to route the workflow by action.

### Logic
- if `agent_action = ALERT` → Gmail Alert path
- else → Gmail Monitor path

### Why this mattered
This was the first real action-routing layer in the workflow.

### Business meaning
- `ALERT` = something new needs immediate attention
- `MONITOR` = only known issues are present, so the tone can be softer

### Important note
In most of the testing shown in the project, the workflow went down the ALERT path because the selected set still contained new signatures.

## 10. Gmail Alert and Gmail Monitor
Two Gmail nodes were introduced:
- `Gmail Alert`
- `Gmail Monitor`

### What they sent
Both emails contained:
- title
- counts
- recommended action
- AI summary text
- exception details table

### Why this mattered
This made the project much stronger for demos and portfolio use.

The output was no longer just:
- raw n8n logs
- or raw BigQuery results

It became a proper stakeholder-facing notification.

### Important fix
The subject line initially printed the expression literally. This was fixed by switching the subject field to proper expression mode.

## 11. HTML email structure
The email body used HTML expressions inside the Gmail node.

### What the HTML did
It rendered:
- the heading
- summary count lines
- AI summary section
- table of exception rows

### Why HTML mattered
Without HTML, the email was too plain and weak. With HTML, it became visually readable and evidence-rich.

### Important expression pattern
A loop like this was used conceptually:
- map over `$json.exceptions`
- create one HTML `<tr>` per row
- join them into one table body

That was how the exception detail table was built dynamically.

## 12. Memory writeback
At the end of the workflow, another BigQuery node inserted the current compared exceptions back into:
- `exception_memory`

### Why this mattered
Without writeback, the system would never remember anything new.

### What this achieved
After a run:
- current exceptions are logged into memory
- future runs can classify repeated signatures as `known`

### Important limitation
Because the table is append-only:
- rerunning the workflow creates more history rows
- it does not deduplicate automatically

This is acceptable for the MVP, but worth acknowledging honestly.

## 13. Reset logic with `TRUNCATE TABLE`
Because the memory table accumulates rows across runs, a clean demo reset query became necessary.

### Reset query
```sql
TRUNCATE TABLE `ferrous-biplane-450410-i2.AI_Mockproject.exception_memory`;
```

### Why this mattered
It allowed:
- clean interview demos
- fresh memory state
- predictable proof runs

### Recommended demo flow
1. truncate memory table
2. confirm count is 0
3. run workflow
4. confirm 10 rows were inserted
5. explain that the next run would classify repeats as known

This became the safest interview-ready demonstration pattern.

## 14. Questions and confusion that came up in Phase 3
This phase created the most confusion, which is normal.

### Main confusion
Why does the memory table keep growing?

### Real answer
Because the design stores every run as appended history.

### Why that is okay for now
The system only needs to know whether a signature exists in history. So duplicates do not break the new/known logic.

### Main lesson
Phase 3 is the point where the project starts behaving like a stateful system, and that is why it feels more complex than earlier phases.

## 15. Final honest positioning
Even after Phase 3, the honest label is still:

**AI-assisted exception monitoring workflow with memory and routing**

### Why it is not yet a full AI agent
- actions are still hardcoded
- the model does not dynamically choose tools
- the memory table is more history than clean state memory
- there is no multi-step autonomous planning

### Why it is still strong
It now has:
- rule-based detection
- memory comparison
- new vs known classification
- AI explanation
- action routing
- stakeholder notification
- memory writeback

That is strong enough to be interview-worthy and to show agent-like thinking, even if it is not a full autonomous agent.

## 16. Key findings from Phase 3
- memory changes the project completely
- comparison across runs adds real business meaning
- deterministic prep logic is better than asking the model to count things
- routing makes the workflow feel much more operational
- reset queries are important for clean demos
- append-only history is acceptable for the MVP, but should be called out honestly

## 17. What Phase 3 delivered
Phase 3 delivered the final MVP behavior:
1. detect current high-priority exceptions
2. compare them against memory
3. classify them as new or known
4. calculate exact counts and action
5. generate an AI summary
6. route to ALERT or MONITOR
7. send a stakeholder-facing email
8. write the run back into memory

That is the final executed project state.
