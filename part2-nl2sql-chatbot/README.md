# Part 2 — NL2SQL Chatbot

A natural-language-to-SQL chatbot built on top of the Part 1 university database. Users
ask plain-English questions; the pipeline generates and runs the corresponding SQL query
and returns the result.

## Contents

```
part2-nl2sql-chatbot/
├── docs/
│   └── NL2SQL_Documentation.docx   # Technical report, capability & failure analysis
├── notebook/
│   └── nl2sql_chatbot.ipynb        # Full pipeline (Kaggle notebook)
└── data/
    └── uni_management.db           # SQLite export of the Part 1 database
```

## Pipeline Overview

- **Database:** SQLite export of the Part 1 MySQL schema, connected via LangChain's
  `SQLDatabase`, with a hand-written `CUSTOM_TABLE_INFO` schema description for every table.
- **Baseline model (required):** [`defog/sqlcoder-7b-2`](https://huggingface.co/defog/sqlcoder-7b-2)
  via Hugging Face Transformers, wrapped in a LangChain SQL chain.
- **Bonus — Ollama integration:** two additional models served locally via Ollama and
  wired into the same pipeline with `langchain-ollama`:
  - `duckdb-nsql`
  - `mistral`
- **Bonus — Prompt engineering fixes:** documented before/after comparisons for several
  failure cases (e.g. dialect mismatches, join-path hallucination), with the corrected
  prompt and resulting SQL.
- **Bonus — Interactive interface:** an `ipywidgets`-based chat widget for asking
  questions and viewing generated SQL/results inline in the notebook.

## Running the Notebook

1. Open [`notebook/nl2sql_chatbot.ipynb`](./notebook/nl2sql_chatbot.ipynb) in Kaggle
   (Settings → Accelerator → GPU T4 x2).
2. Upload `data/uni_management.db` as a Kaggle Dataset and update the `DB_PATH` variable
   to point to it.
3. Add a Hugging Face access token as a Kaggle Secret named `HF_TOKEN`.
4. Run all cells top-to-bottom. The Ollama sections install and start Ollama within the
   Kaggle session, so no separate setup is needed.

## Evaluation

The notebook demonstrates the chatbot across simple lookups, aggregation, sorting,
multi-table joins, AND/OR filtering, and a query matched against a manually-written
Part 1 query — plus a documented set of failure modes (schema hallucination, multi-hop
reasoning, SQL dialect mismatches, date/time reasoning) with root-cause analysis and, in
several cases, a working prompt-level fix.

Full write-up, model selection rationale and results summary are in
[`docs/NL2SQL_Documentation.docx`](./docs/NL2SQL_Documentation.docx).
