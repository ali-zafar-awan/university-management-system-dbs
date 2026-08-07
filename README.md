# University Management System — Database Project

A two-part database systems project: designing and building a relational database for a
university then layering an AI-powered natural language interface (NL2SQL chatbot) on top of it.

**Course:** CS254 - Database Systems
**Instructor:** Nauman Arshad
**Team:** Ali Zafar Awan, Hassan Malik, Khadija Mughees, Fizza Atif
**University:** Information Technology University of Punjab, Lahore.

---

## Repository Structure

```
university-management-system-dbs/
├── part1-database-design/     # DB design, MySQL implementation, RBAC, Flask web app
└── part2-nl2sql-chatbot/      # LangChain + LLM pipeline for natural language → SQL
```

Each part has its own README with setup instructions and details — start there:

- **[Part 1 — Database Design & Web App](./part1-database-design/README.md)**
- **[Part 2 — NL2SQL Chatbot](./part2-nl2sql-chatbot/README.md)**

## Project Overview

The project models a **University Management System** covering students, faculty,
departments, degrees, courses, sections, semesters, enrollment, attendance, address and fee
payments.

**Part 1** takes the system from requirements analysis through to a normalized (3NF)
relational schema, a populated MySQL database with role-based access control and
transaction handling, and a small Flask web app for browsing and updating records.

**Part 2** builds on the Part 1 database with a natural-language-to-SQL chatbot: a user
asks a plain-English question, the system generates and runs the corresponding SQL query
using an LLM via LangChain, and returns the result. It includes a baseline Hugging Face
model, bonus integrations with Ollama-served models (DuckDB-NSQL, Mistral), and an
interactive chat widget.

## Tech Stack

| Area | Tools |
|---|---|
| Database | MySQL, SQLite (for Part 2) |
| Diagramming | draw.io |
| Web App | Python, Flask, HTML/CSS |
| NL2SQL Pipeline | LangChain, Hugging Face Transformers, Ollama |
| Environment | MySQL Workbench, Kaggle Notebooks |

## License

This project was built for academic coursework. See individual folders for any
part-specific notes.
