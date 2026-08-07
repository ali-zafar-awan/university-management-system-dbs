# Part 1 — Database Design: University Management System

Design, implementation, and front-end for a relational database supporting the daily
operations of a university — student records, course management, attendance, grading,
and fee tracking.

## Contents

```
part1-database-design/
├── docs/
│   └── UNI_DBS_Report.docx     # Full written report: analysis, ERD, normalisation,
│                                # data dictionary, RBAC & transaction write-ups
├── erd/
│   └── uni_management_erd.drawio   # Entity Relationship Diagram (draw.io source)
├── sql/
│   ├── schema.sql               # CREATE TABLE statements (MySQL, 3NF)
│   ├── data.sql                 # Sample data inserts (1000+ rows total)
│   └── queries.sql              # Demonstration queries, incl. CTEs & aggregation
└── webapp/
    ├── app.py                   # Flask application
    ├── static/style.css
    └── templates/                # home, students, faculty, departments, fee_payments, form
```

## Database Design

The schema models 8+ core entities, normalized from UNF through to 3NF:

`DEPARTMENT`, `FACULTY`, `DEGREE`, `SEMESTER`, `COURSE`, `SECTION`, `STUDENT`,
`ENROLLMENT`, `ATTENDANCE`, `FEES`, `FEE_PAYMENT`, `ADDRESS`

Full analysis, the ERD, normalisation stages, and the data dictionary are documented in
[`docs/UNI_DBS_Report.docx`](./docs/UNI_DBS_Report.docx). The ERD source file can be opened
and edited at [draw.io](https://draw.io).

## Setup

### 1. Database (MySQL)

Requires MySQL 8.x and MySQL Workbench (or the `mysql` CLI).

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p < sql/data.sql
```

This creates the `dbs_project_prt1` database and populates it with sample data.
Demonstration queries (including a CTE and aggregation examples) are in `sql/queries.sql`.

### 2. Role-Based Access Control

Three roles are implemented with `CREATE USER` / `GRANT` / `REVOKE` — see
`docs/UNI_DBS_Report.docx` for the full role definitions, privilege tables, and business
justification for each role.

### 3. Web App (Flask)

```bash
cd webapp
pip install flask mysql-connector-python
python app.py
```

The app connects to the MySQL database and serves:

- `/` — dashboard with summary stats (students, faculty, courses, enrollments, fees)
- `/students` — searchable/filterable student list
- `/faculty` — faculty listing
- `/departments` — department listing
- `/fee-payments` — fee payment records
- `/add-student` — form to add a new student record

> **Before running:** `app.py` currently has database credentials (host, user, password)
> hardcoded at the top of the file. Update these to match your local MySQL setup, and if
> this repo is public, move them into environment variables (e.g. via `python-dotenv`)
> rather than committing real credentials.

## Report

The full written report — introduction, entity/transaction analysis, ERD walkthrough,
normalisation (UNF → 3NF), data dictionary, transactions, and RBAC — is in
[`docs/UNI_DBS_Report.docx`](./docs/UNI_DBS_Report.docx).
