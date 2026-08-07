DROP DATABASE IF EXISTS dbs_project_prt1;

CREATE DATABASE dbs_project_prt1;

USE dbs_project_prt1;

CREATE TABLE ADDRESS (
    address_id INT NOT NULL AUTO_INCREMENT,
    house_no VARCHAR(10),
    street_lane VARCHAR(50),
    sector_block_phase VARCHAR(50),
    area_town_mohalla VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    province VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL DEFAULT 'Pakistan',
    postal_code VARCHAR(12) NOT NULL,
    PRIMARY KEY (address_id)
);

CREATE TABLE DEPARTMENT (
    dept_id INT NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (dept_id),
    UNIQUE (dept_name)
);

CREATE TABLE FACULTY (
    faculty_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender ENUM('M', 'F', 'O') NOT NULL,
    address_id INT NOT NULL,
    phone CHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL CHECK (email LIKE '%@%.%'),
    dept_id INT NOT NULL,
    PRIMARY KEY (faculty_id),
    UNIQUE (phone),
    UNIQUE (email),
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT (dept_id),
    FOREIGN KEY (address_id) REFERENCES ADDRESS (address_id)
);

ALTER TABLE DEPARTMENT
ADD hod_id INT,
ADD CONSTRAINT fk FOREIGN KEY (hod_id) REFERENCES FACULTY (faculty_id) ON DELETE SET NULL;

CREATE TABLE DEGREE (
    degree_id INT NOT NULL AUTO_INCREMENT,
    degree_title VARCHAR(100) NOT NULL,
    duration TINYINT NOT NULL CHECK (duration BETWEEN 1 AND 6),
    dept_id INT NOT NULL,
    PRIMARY KEY (degree_id),
    UNIQUE (degree_title),
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT (dept_id)
);

CREATE TABLE SEMESTER (
    sem_id INT NOT NULL AUTO_INCREMENT,
    sem_session VARCHAR(15) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    sem_status ENUM('Active', 'Completed', 'Upcoming') NOT NULL DEFAULT 'Upcoming',
    PRIMARY KEY (sem_id),
    UNIQUE (sem_session)
);

CREATE TABLE COURSE (
    course_id INT NOT NULL AUTO_INCREMENT,
    course_name VARCHAR(100) NOT NULL,
    credit_hours TINYINT NOT NULL CHECK (credit_hours BETWEEN 1 AND 5),
    dept_id INT NOT NULL,
    PRIMARY KEY (course_id),
    FOREIGN KEY (dept_id) REFERENCES DEPARTMENT (dept_id),
    UNIQUE (course_name)
);

CREATE TABLE SECTION (
    section_id INT NOT NULL AUTO_INCREMENT,
    section_name CHAR(1) NOT NULL,
    capacity INT NOT NULL DEFAULT 30 CHECK (capacity BETWEEN 1 AND 100),
    faculty_id INT NOT NULL,
    course_id INT NOT NULL,
    sem_id INT NOT NULL,
    PRIMARY KEY (section_id),
    FOREIGN KEY (faculty_id) REFERENCES FACULTY (faculty_id),
    FOREIGN KEY (course_id) REFERENCES COURSE (course_id),
    FOREIGN KEY (sem_id) REFERENCES SEMESTER (sem_id)
);

CREATE TABLE STUDENT (
    student_id CHAR(9) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    batch INT NOT NULL CHECK (batch BETWEEN 2000 AND 2100),
    dob DATE NOT NULL,
    gender ENUM('M', 'F', 'O') NOT NULL,
    address_id INT NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL CHECK (email LIKE '%@%.%'),
    degree_id INT NOT NULL,
    PRIMARY KEY (student_id),
    UNIQUE (phone),
    UNIQUE (email),
    FOREIGN KEY (degree_id) REFERENCES DEGREE (degree_id),
    FOREIGN KEY (address_id) REFERENCES ADDRESS (address_id)
);

CREATE TABLE ENROLLMENT (
    enrollment_id INT NOT NULL AUTO_INCREMENT,
    enrollment_date DATE NOT NULL DEFAULT(CURDATE()),
    final_grade ENUM('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F', 'W') DEFAULT NULL,
    student_id CHAR(9) NOT NULL,
    section_id INT NOT NULL,
    PRIMARY KEY (enrollment_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT (student_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES SECTION (section_id)
);

CREATE TABLE ATTENDANCE (
    attendance_id INT NOT NULL AUTO_INCREMENT,
    date DATE NOT NULL,
    status ENUM('P', 'A', 'L') NOT NULL DEFAULT 'A',
    enrollment_id INT NOT NULL,
    PRIMARY KEY (attendance_id),
    FOREIGN KEY (enrollment_id) REFERENCES ENROLLMENT (enrollment_id) ON DELETE CASCADE
);

CREATE TABLE FEES (
    fee_id INT NOT NULL AUTO_INCREMENT,
    amount FLOAT NOT NULL CHECK (amount >= 0),
    per_credit_rate FLOAT NOT NULL DEFAULT 0 CHECK (per_credit_rate >= 0),
    enrollment_id INT NOT NULL,
    PRIMARY KEY (fee_id),
    FOREIGN KEY (enrollment_id) REFERENCES ENROLLMENT (enrollment_id) ON DELETE CASCADE
);

CREATE TABLE FEE_PAYMENT (
    payment_id INT NOT NULL AUTO_INCREMENT,
    total_amount_due FLOAT NOT NULL CHECK (total_amount_due >= 0),
    amount_paid FLOAT NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    payment_date DATE,
    payment_method ENUM('Cash', 'Online', 'Bank Transfer', 'Cheque') DEFAULT NULL,
    payment_status ENUM('Paid', 'Partial', 'Pending', 'Overdue') NOT NULL DEFAULT 'Pending',
    student_id CHAR(9) NOT NULL,
    sem_id INT NOT NULL,
    PRIMARY KEY (payment_id),
    FOREIGN KEY (student_id) REFERENCES STUDENT (student_id),
    FOREIGN KEY (sem_id) REFERENCES SEMESTER (sem_id)
);

DELIMITER //

CREATE TRIGGER before_fee_insert
BEFORE INSERT ON FEES
FOR EACH ROW
BEGIN
    DECLARE ch INT;
    SELECT c.credit_hours INTO ch
    FROM ENROLLMENT e
    JOIN SECTION s ON e.section_id = s.section_id
    JOIN COURSE c ON s.course_id = c.course_id
    WHERE e.enrollment_id = NEW.enrollment_id;
    
    SET NEW.amount = NEW.per_credit_rate * COALESCE(ch, 0);
END //

CREATE TRIGGER before_fee_update
BEFORE UPDATE ON FEES
FOR EACH ROW
BEGIN
    DECLARE ch INT;
    SELECT c.credit_hours INTO ch
    FROM ENROLLMENT e
    JOIN SECTION s ON e.section_id = s.section_id
    JOIN COURSE c ON s.course_id = c.course_id
    WHERE e.enrollment_id = NEW.enrollment_id;
    
    SET NEW.amount = NEW.per_credit_rate * COALESCE(ch, 0);
END //

DELIMITER ;