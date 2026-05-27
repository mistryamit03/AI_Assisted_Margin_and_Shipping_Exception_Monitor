# Phase 2 Notes — Ollama Setup, Local AI Summary, Aggregate Node, LLM Chain, and Gmail Output

## Phase goal
Phase 2 introduced the AI summary layer.

The goal was not to build a full AI agent yet. The goal was to take the high-priority exception rows from Phase 1 and generate a short, plain-English business summary using a local LLM.

This phase turned the workflow from:
- rule-based automation

into:
- AI-assisted automation

## 1. Why Phase 2 was added
After Phase 1, the workflow could already:
- detect exceptions
- count them
- fetch detailed rows

But raw rows are not always enough for a stakeholder.

A summary layer was added so the workflow could explain:
- how many important rows were found
- what the main issue patterns looked like
- what should be reviewed first

## 2. Why Ollama was chosen
The local LLM was built using Ollama.

### Why this made sense
- it allowed local inference
- it avoided dependence on a paid cloud model for the MVP
- it fit the project goal of a self-hosted AI-assisted workflow

### Honest trade-off
Ollama was practical, but it also introduced hardware constraints:
- model size
- RAM requirements
- GPU memory issues
- CPU fallback decisions

## 3. Ollama setup and initial model issues
### First issue
A larger `llama3.2` model initially failed due to system memory limits.

The user saw an error showing that the model required more memory than the system had available.

### Meaning of that error
The model download succeeded, but the machine could not load it into memory to run inference.

### Fix
The model was removed and replaced with:
- `llama3.2:1b`

This smaller model was lightweight enough to run on the local machine.

### Practical lesson
For a project like this, smaller but stable is better than larger but unreliable.

## 4. Basic Ollama testing
Before reconnecting it to n8n, the model was tested in PowerShell using:
- `ollama run`
- plain prompt tests
- HTTP endpoint checks

### Why this mattered
It separated:
- model/runtime issues
- from workflow issues

This was important because several early failures were not n8n logic problems. They were environment or model-serving problems.

## 5. Connecting Ollama to n8n
An Ollama credential was created in n8n.

### Base URL used
- `http://host.docker.internal:11434`

### Why this mattered
n8n was running in Docker, while Ollama was running on the Windows host machine. That special hostname allowed Dockerized n8n to reach the host-served Ollama instance.

### Important setup detail
- no API key was needed for default local Ollama
- the selected model was `llama3.2:1b`

## 6. Early LLM testing and prompt problems
### First weak output
The first simple prompts produced poor results, for example:
- vague wording
- generic statements
- no grounding in the actual exception data
- incorrect counts
- unhelpful business phrasing

### Why
The model was being asked to summarize too little context or poorly structured context.

### Lesson
LLMs do not automatically produce good business summaries. They need:
- the right input format
- clear instructions
- scope constraints

## 7. Aggregate node — why it became critical
One of the most important fixes in Phase 2 was introducing the **Aggregate** node.

### Problem before Aggregate
Without aggregation, the LLM was effectively seeing exception rows one by one.

That caused:
- repeated executions
- inconsistent counts
- unstable summaries
- confusion around why outputs differed between runs

### What Aggregate did
It combined the 10 exception rows into **one item** with one array field:
- `exceptions`

### Why this solved the problem
Now the LLM got:
- one combined payload
- one prompt
- one summary
- one email output

### Core lesson
If the business goal is one summary for a set of rows, the LLM should receive one grouped item, not many separate items.

## 8. Basic LLM Chain
The **Basic LLM Chain** node was the main AI text-generation node.

### What it did
It took:
- the aggregated exceptions
- a human-written prompt

and used the Ollama model to generate:
- one plain-English business summary

### Early prompt design
The prompt instructed the model to:
- act as an operations analyst
- keep the summary short
- identify row count
- mention main issue patterns
- suggest what should be reviewed first

## 9. Prompt issues and fixes
### Problem: hallucination / over-interpretation
The model sometimes:
- invented explanations
- changed row counts
- produced overly generic business text
- returned weird formatting like `\n`, markdown symbols, or unstable wording

### Fixes applied
Prompt instructions were tightened to:
- keep the response short
- use plain English
- avoid markdown
- avoid inventing numbers or causes
- only summarize visible data

### Important learning
The prompt needed to constrain the model hard. Otherwise, even a small local model would drift.

## 10. Gmail summary output
After the LLM node worked, Gmail was connected so the output could be sent as proof.

### Why Gmail mattered
This was the first clear stakeholder-style deliverable:
- not just node output inside n8n
- but an actual delivered summary

### What the Gmail output contained at first
Initially, it was mostly:
- a short text summary

### Why that later changed
Plain text summary alone felt too weak as evidence. That later led to adding the exception table in the email.

## 11. Important Phase 2 fixes and lessons
### A. Subject/body interpolation issues
Some email fields initially printed expressions literally instead of evaluating them.

#### Fix
Those fields had to be switched to proper expression mode.

### B. Weird newline and markdown artifacts
The model sometimes returned outputs with:
- `\n`
- markdown-like formatting
- compressed text

#### Fix
Prompt instructions were tightened, and later the email HTML replaced newlines with `<br>` where needed.

### C. Multiple LLM executions confusion
The workflow logs showed several Ollama model entries, which was confusing at first.

#### Real meaning
This was a result of how items were passed through before aggregation and how logs were displayed. Once the Aggregate pattern was correct, the final summary path became much cleaner.

## 12. Honest Phase 2 positioning
At the end of Phase 2, the project became:

**an AI-assisted exception monitoring workflow**

Why this was honest:
- it had an LLM summary
- it used real tools
- it generated stakeholder-facing output

But it still did not have:
- real memory
- stateful comparison across runs
- action routing based on new vs known issues

So it was not yet a strong agent-like system.

## 13. Key findings from Phase 2
- local models are workable for MVPs if the model size is chosen realistically
- aggregation is essential if one summary should represent many rows
- prompt quality matters more than people think
- early LLM outputs often look “intelligent” but are not reliable enough without constraints
- sending output via Gmail makes the project much more tangible and portfolio-friendly

## 14. What Phase 2 enabled next
Phase 2 proved that the workflow could:
- detect exceptions
- summarize them
- notify a stakeholder

That raised the next question:
- can the system remember what it has seen before?

That became the core of Phase 3.
