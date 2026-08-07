USE dbs_project_prt1;

SET SQL_SELECT_LIMIT = DEFAULT;

#checking data inserts in the tables

SELECT *
FROM STUDENT;

SELECT * FROM ADDRESS;

SELECT * FROM DEPARTMENT;

SELECT * FROM DEGREE;

SELECT * FROM FACULTY;

SELECT * FROM COURSE;

SELECT * FROM SECTION;

SELECT * FROM SEMESTER;

SELECT * FROM ENROLLMENT;

SELECT * FROM ATTENDANCE;

SELECT * FROM FEES;

SELECT * FROM FEE_PAYMENT;

#QUERY 1: ranking departments by avg GPAs and stundet count

WITH Student_GPA AS (
    SELECT s.student_id, dg.dept_id,
        ROUND(AVG(
            CASE e.final_grade
                WHEN 'A+' THEN 4.0
                WHEN 'A'  THEN 4.0
                WHEN 'A-' THEN 3.7
                WHEN 'B+' THEN 3.3
                WHEN 'B'  THEN 3.0
                WHEN 'B-' THEN 2.7
                WHEN 'C+' THEN 2.3
                WHEN 'C'  THEN 2.0
                WHEN 'C-' THEN 1.7
                WHEN 'D'  THEN 1.0
                WHEN 'F'  THEN 0.0
                WHEN 'W'  THEN 0.0
                ELSE NULL
            END)
        , 2) AS student_GPA
    FROM STUDENT s
    JOIN DEGREE dg    ON s.degree_id = dg.degree_id
    JOIN ENROLLMENT e USING(student_id)
    WHERE e.final_grade IS NOT NULL
    GROUP BY s.student_id, dg.dept_id  
),

gpa_per_dept AS (
    SELECT dept_id, COUNT(student_id) AS Total_Students, ROUND(AVG(student_GPA), 2) AS department_avg
    FROM Student_GPA
    GROUP BY dept_id
)
SELECT d.dept_name, dg.Total_Students,dg.department_avg
FROM gpa_per_dept dg 
JOIN DEPARTMENT d USING(dept_id)
ORDER BY dg.department_avg ASC;

#QUERY 2: Faculty teaching load
SELECT f.faculty_id, f.first_name, f.last_name, d.dept_name, COUNT(DISTINCT se.section_id) AS Total_Sections, COUNT(e.enrollment_id) AS Total_Students
FROM FACULTY f 
JOIN DEPARTMENT d USING(dept_id)
JOIN SECTION se ON se.faculty_id = f.faculty_id
JOIN ENROLLMENT e USING(section_id)
WHERE f.dept_id = d.dept_id
GROUP BY f.faculty_id, f.first_name,f.last_name,d.dept_name
ORDER BY Total_Students ASC;

#QUERY 3: Absence rate per course with faculty member
WITH Attendance_Count AS (
    SELECT c.course_id, c.course_name, f.faculty_id, f.first_name, f.last_name, 
           COUNT(*) AS Total_Records, 
           COUNT(CASE WHEN a.status = 'A' THEN 1 END) AS absent_ct, 
           COUNT(DISTINCT e.student_id) AS Total_Students
    FROM ATTENDANCE a 
    JOIN ENROLLMENT e USING(enrollment_id)
    JOIN SECTION se USING(section_id)
    JOIN COURSE c USING(course_id)
    JOIN FACULTY f ON se.faculty_id = f.faculty_id
    GROUP BY c.course_id, c.course_name, f.faculty_id, f.first_name, f.last_name
)
SELECT course_name, first_name, last_name, Total_Students, absent_ct, Total_Records, 
       ROUND((absent_ct / Total_Records) * 100, 2) AS Absent_Rate
FROM Attendance_Count
ORDER BY Absent_Rate ASC;

#QUERY 4: Mark pending payments as overdue if the semester is over
SELECT COUNT(*) AS initial_pending
FROM FEE_PAYMENT
WHERE payment_status = 'Pending' AND sem_id IN(
    SELECT sem_id 
    FROM SEMESTER
    WHERE sem_status = 'Completed'
);

UPDATE FEE_PAYMENT
SET
    payment_status = 'Overdue'
WHERE
    payment_status = 'Pending'
    AND sem_id IN (
        SELECT sem_id
        FROM SEMESTER
        WHERE
            sem_status = 'Completed'
    );

SELECT COUNT(*) AS pending_after_update
FROM FEE_PAYMENT
WHERE
    payment_status = 'Pending'
    AND sem_id IN (
        SELECT sem_id
        FROM SEMESTER
        WHERE
            sem_status = 'Completed'
    );

#QUERY 5: Delete attendance records of withdrawn students
SELECT COUNT(*) AS to_delete
FROM ATTENDANCE
WHERE enrollment_id IN(
    SELECT enrollment_id 
    FROM ENROLLMENT
    WHERE final_grade = 'W'
);

DELETE FROM ATTENDANCE
WHERE
    enrollment_id IN (
        SELECT enrollment_id
        FROM ENROLLMENT
        WHERE
            final_grade = 'W'
    );

SELECT COUNT(*) AS after_delete
FROM ATTENDANCE
WHERE
    enrollment_id IN (
        SELECT enrollment_id
        FROM ENROLLMENT
        WHERE
            final_grade = 'W'
    );

#TRANSACTION 1: FEE PAYMENT PROCESS (COMMIT)
SELECT payment_id,student_id,total_amount_due,payment_date,payment_status
FROM FEE_PAYMENT 
WHERE student_id = 'STU000117' AND sem_id='7';

START TRANSACTION;

UPDATE FEE_PAYMENT
SET
    amount_paid = total_amount_due,
    payment_status = 'Paid',
    payment_method = 'Online'
WHERE
    student_id = 'STU000117'
    AND sem_id = '7';

INSERT INTO
    FEE_PAYMENT (
        total_amount_due,
        amount_paid,
        payment_date,
        payment_method,
        payment_status,
        student_id,
        sem_id
    )
VALUES (
        75000,
        0,
        NULL,
        NULL,
        'Pending',
        'STU000117',
        7
    );

COMMIT;

SELECT
    payment_id,
    student_id,
    total_amount_due,
    payment_date,
    payment_status
FROM FEE_PAYMENT
WHERE
    student_id = 'STU000117'
    AND sem_id = '7';

#TRANSACTION 2: Accidental grade update of the wrong student  (ROLLBACK)

SELECT e.enrollment_id,e.student_id,c.course_name,e.section_id,e.final_grade
FROM ENROLLMENT e 
JOIN SECTION se  USING(section_id)
JOIN COURSE c USING(course_id)
WHERE e.student_id = 'STU000005'AND e.section_id = 115;

START TRANSACTION;

UPDATE ENROLLMENT
SET
    final_grade = 'A+'
WHERE
    student_id = 'STU000005'
    AND section_id = 115;

SELECT e.enrollment_id, e.student_id, c.course_name, e.section_id, e.final_grade
FROM
    ENROLLMENT e
    JOIN SECTION se USING (section_id)
    JOIN COURSE c USING (course_id)
WHERE
    e.student_id = 'STU000005'
    AND e.section_id = 115;

ROLLBACK;

SELECT e.enrollment_id, e.student_id, c.course_name, e.section_id, e.final_grade
FROM
    ENROLLMENT e
    JOIN SECTION se USING (section_id)
    JOIN COURSE c USING (course_id)
WHERE
    e.student_id = 'STU000005'
    AND e.section_id = 115;

#ROLE BASED ACCESS CONTROL

CREATE USER IF NOT EXISTS 'student'@'localhost' IDENTIFIED BY 'Studentmeow';

CREATE USER IF NOT EXISTS 'faculty'@'localhost' IDENTIFIED BY 'Facultymeow';

CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'Adminmeow';

GRANT SELECT ON dbs_project_prt1.STUDENT TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.ADDRESS TO 'student'@'localhost';

GRANT
SELECT ON dbs_project_prt1.ENROLLMENT TO 'student'@'localhost';

GRANT
SELECT ON dbs_project_prt1.ATTENDANCE TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.COURSE TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.SECTION TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.SEMESTER TO 'student'@'localhost';

GRANT
SELECT ON dbs_project_prt1.FEE_PAYMENT TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.FEES TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.FACULTY TO 'student'@'localhost';

GRANT
SELECT ON dbs_project_prt1.DEPARTMENT TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.DEGREE TO 'student'@'localhost';

GRANT SELECT ON dbs_project_prt1.STUDENT TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.ADDRESS TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.COURSE TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.SECTION TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.SEMESTER TO 'faculty'@'localhost';

GRANT
SELECT ON dbs_project_prt1.DEPARTMENT TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.DEGREE TO 'faculty'@'localhost';

GRANT SELECT ON dbs_project_prt1.FACULTY TO 'faculty'@'localhost';

GRANT
SELECT,
UPDATE ON dbs_project_prt1.ENROLLMENT TO 'faculty'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE ON dbs_project_prt1.ATTENDANCE TO 'faculty'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.STUDENT TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.ADDRESS TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.FACULTY TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.DEPARTMENT TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.DEGREE TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.SEMESTER TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.COURSE TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.SECTION TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.ENROLLMENT TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.ATTENDANCE TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.FEES TO 'admin'@'localhost';

GRANT
SELECT,
INSERT
,
UPDATE,
DELETE ON dbs_project_prt1.FEE_PAYMENT TO 'admin'@'localhost';

REVOKE
UPDATE ON dbs_project_prt1.ENROLLMENT
FROM 'faculty'@'localhost';

REVOKE DELETE ON dbs_project_prt1.STUDENT FROM 'admin'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'student'@'localhost';

SHOW GRANTS FOR 'faculty'@'localhost';

SHOW GRANTS FOR 'admin'@'localhost';