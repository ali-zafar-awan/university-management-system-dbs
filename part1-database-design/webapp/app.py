from flask import Flask, render_template, request
import mysql.connector
import os
import sqlite3

app = Flask(__name__)

# Path to local SQLite database fallback from Part 2
SQLITE_DB_PATH = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "part2-nl2sql-chatbot", "data", "uni_management.db"
))

class SQLiteWrapper:
    """Wrapper around sqlite3 connection to emulate mysql.connector cursor behavior with %s placeholders."""
    def __init__(self, conn):
        self.conn = conn
    
    def cursor(self):
        return SQLiteCursorWrapper(self.conn.cursor())
    
    def commit(self):
        self.conn.commit()
        
    def close(self):
        self.conn.close()

class SQLiteCursorWrapper:
    def __init__(self, cursor):
        self.cursor = cursor
        
    def execute(self, query, params=None):
        query_converted = query.replace("%s", "?")
        if params:
            return self.cursor.execute(query_converted, params)
        return self.cursor.execute(query_converted)
        
    def fetchone(self):
        return self.cursor.fetchone()
        
    def fetchall(self):
        return self.cursor.fetchall()
        
    @property
    def lastrowid(self):
        return self.cursor.lastrowid
        
    def close(self):
        self.cursor.close()

def get_db():
    host = os.environ.get("DB_HOST", "localhost")
    user = os.environ.get("DB_USER", "root")
    password = os.environ.get("DB_PASSWORD", "101201")
    port = int(os.environ.get("DB_PORT", 3306))
    database = os.environ.get("DB_NAME", "dbs_project_prt1")
    
    try:
        return mysql.connector.connect(
            host=host,
            user=user,
            port=port,
            password=password,
            database=database
        )
    except Exception as mysql_err:
        if os.path.exists(SQLITE_DB_PATH):
            conn = sqlite3.connect(SQLITE_DB_PATH)
            return SQLiteWrapper(conn)
        raise mysql_err

@app.route("/")
def home():
    try:
        db = get_db()
        cursor = db.cursor()

        cursor.execute("SELECT COUNT(*) FROM STUDENT")
        total_students = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM FACULTY")
        total_faculty = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM COURSE")
        total_courses = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM ENROLLMENT")
        total_enrollments = cursor.fetchone()[0]

        cursor.execute("SELECT sem_session FROM SEMESTER WHERE sem_status = 'Active' LIMIT 1")
        active_sem = cursor.fetchone()
        active_semester = active_sem[0] if active_sem else "None"

        cursor.execute("SELECT COUNT(*) FROM FEE_PAYMENT WHERE payment_status = 'Overdue'")
        overdue_fees = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM FEE_PAYMENT WHERE payment_status = 'Paid'")
        paid_fees = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM DEPARTMENT")
        total_departments = cursor.fetchone()[0]

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    return render_template("home.html",
        total_students=total_students,
        total_faculty=total_faculty,
        total_courses=total_courses,
        total_enrollments=total_enrollments,
        active_semester=active_semester,
        overdue_fees=overdue_fees,
        paid_fees=paid_fees,
        total_departments=total_departments
    )

@app.route("/students")
def students():
    try:
        db = get_db()
        cursor = db.cursor()

        search = request.args.get("search", "")
        dept   = request.args.get("dept", "")
        batch  = request.args.get("batch", "")

        query = """
            SELECT s.student_id, s.first_name, s.last_name, s.batch,
                   s.gender, s.email, s.phone, d.dept_name, dg.degree_title
            FROM STUDENT s
            JOIN DEGREE dg     ON s.degree_id = dg.degree_id
            JOIN DEPARTMENT d  ON dg.dept_id  = d.dept_id
            WHERE 1=1
        """
        params = []

        if search:
            query += " AND (s.first_name LIKE %s OR s.last_name LIKE %s OR s.student_id LIKE %s)"
            params += [f"%{search}%", f"%{search}%", f"%{search}%"]

        if dept:
            query += " AND d.dept_name = %s"
            params.append(dept)

        if batch:
            query += " AND s.batch = %s"
            params.append(batch)

        query += " ORDER BY s.student_id ASC"

        cursor.execute(query, params)
        student_list = cursor.fetchall()

        cursor.execute("SELECT dept_name FROM DEPARTMENT ORDER BY dept_name")
        departments = [row[0] for row in cursor.fetchall()]

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    return render_template("students.html",
        students=student_list,
        departments=departments,
        search=search,
        selected_dept=dept,
        selected_batch=batch
    )

@app.route("/add-student", methods=["GET", "POST"])
def add_student():
    message = ""
    try:
        db = get_db()
        cursor = db.cursor()

        cursor.execute("SELECT degree_id, degree_title FROM DEGREE ORDER BY degree_title")
        degrees = cursor.fetchall()

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    if request.method == "POST":
        try:
            db = get_db()
            cursor = db.cursor()

            student_id  = request.form["student_id"]
            first_name  = request.form["first_name"]
            last_name   = request.form["last_name"]
            batch       = request.form["batch"]
            dob         = request.form["dob"]
            gender      = request.form["gender"]
            house_no    = request.form.get("house_no")
            street      = request.form.get("street_lane")
            sector      = request.form.get("sector_block_phase")
            town        = request.form["town"]
            city        = request.form["city"]
            province    = request.form["province"]
            country     = request.form["country"]
            postal_code = request.form["postal_code"]
            phone       = request.form["phone"]
            email       = request.form["email"]
            degree_id   = request.form["degree_id"]

            cursor.execute("""
                INSERT INTO ADDRESS (house_no, street_lane, sector_block_phase, area_town_mohalla, city, province, country, postal_code)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (house_no, street, sector, town, city, province, country, postal_code))

            address_id = cursor.lastrowid

            cursor.execute("""
                INSERT INTO STUDENT (student_id, first_name, last_name, batch, dob, gender,
                    address_id, phone, email, degree_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (student_id, first_name, last_name, batch, dob, gender,
                  address_id, phone, email, degree_id))

            db.commit()
            message = "Student added successfully!"
            cursor.close()
            db.close()

        except Exception as e:
            message = f"Error: {str(e)}"

    return render_template("form.html",
        degrees=degrees,
        message=message
    )

@app.route("/faculty")
def faculty():
    try:
        db = get_db()
        cursor = db.cursor()

        search = request.args.get("search", "")
        dept   = request.args.get("dept", "")

        query = """
            SELECT f.faculty_id, f.first_name, f.last_name, f.job_title,
                   f.email, f.phone, d.dept_name
            FROM FACULTY f
            JOIN DEPARTMENT d ON f.dept_id = d.dept_id
            WHERE 1=1
        """
        params = []

        if search:
            query += " AND (f.first_name LIKE %s OR f.last_name LIKE %s)"
            params += [f"%{search}%", f"%{search}%"]

        if dept:
            query += " AND d.dept_name = %s"
            params.append(dept)

        query += " ORDER BY f.faculty_id ASC"

        cursor.execute(query, params)
        faculty_list = cursor.fetchall()

        cursor.execute("SELECT dept_name FROM DEPARTMENT ORDER BY dept_name")
        departments = [row[0] for row in cursor.fetchall()]

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    return render_template("faculty.html",
        faculty=faculty_list,
        departments=departments,
        search=search,
        selected_dept=dept
    )

@app.route("/departments")
def departments():
    try:
        db = get_db()
        cursor = db.cursor()

        cursor.execute("""
            SELECT d.dept_id, d.dept_name,
                   f.first_name, f.last_name,
                   COUNT(DISTINCT fa.faculty_id) AS faculty_count,
                   COUNT(DISTINCT s.student_id)  AS student_count
            FROM DEPARTMENT d
            LEFT JOIN FACULTY f   ON d.hod_id     = f.faculty_id
            LEFT JOIN FACULTY fa  ON fa.dept_id    = d.dept_id
            LEFT JOIN DEGREE  dg  ON dg.dept_id    = d.dept_id
            LEFT JOIN STUDENT s   ON s.degree_id   = dg.degree_id
            GROUP BY d.dept_id, d.dept_name, f.first_name, f.last_name
            ORDER BY d.dept_id ASC
        """)
        dept_list = cursor.fetchall()

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    return render_template("departments.html", departments=dept_list)

@app.route("/fee-payments")
def fee_payments():
    try:
        db = get_db()
        cursor = db.cursor()

        status = request.args.get("status", "")

        query = """
            SELECT fp.payment_id, s.student_id, s.first_name, s.last_name,
                   fp.total_amount_due, fp.amount_paid, fp.payment_date,
                   fp.payment_method, fp.payment_status, se.sem_session
            FROM FEE_PAYMENT fp
            JOIN STUDENT s  ON fp.student_id = s.student_id
            JOIN SEMESTER se ON fp.sem_id    = se.sem_id
            WHERE 1=1
        """
        params = []

        if status:
            query += " AND fp.payment_status = %s"
            params.append(status)

        query += " ORDER BY fp.payment_id ASC"

        cursor.execute(query, params)
        payments = cursor.fetchall()

        cursor.close()
        db.close()

    except Exception as e:
        return f"Database error: {str(e)}"

    return render_template("fee_payments.html",
        payments=payments,
        selected_status=status
    )

if __name__ == "__main__":
    app.run(debug=True)