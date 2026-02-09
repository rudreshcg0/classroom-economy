CREATE TABLE schools (
    school_id SERIAL PRIMARY KEY,
    school_name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student')),
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE
);

CREATE TABLE teacher_allowance (
    teacher_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_budget DECIMAL(10,2) NOT NULL,
    current_balance DECIMAL(10,2) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id)
);

CREATE TABLE wallets (
    student_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    school_id INTEGER REFERENCES schools(school_id)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES users(user_id),   -- Admin or Teacher
    receiver_id INTEGER REFERENCES users(user_id), -- Teacher or Student
    amount DECIMAL(10,2) NOT NULL,
    type VARCHAR(20), -- 'ALLOWANCE', 'REWARD', or 'SPEND'
    description TEXT,
    school_id INTEGER REFERENCES schools(school_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schools (school_name) VALUES ('MMCC_Deccan');

INSERT INTO users (username, password, role, school_id) 
VALUES ('admin', 'admin123', 'super_admin', 1);

-- 1. ADD NEW TABLES
CREATE TABLE IF NOT EXISTS classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(user_id),
    pay_per_session DECIMAL(10,2) DEFAULT 10.00
);

CREATE TABLE IF NOT EXISTS attendance (
    attendance_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(class_id) ON DELETE CASCADE,
    attendance_date DATE DEFAULT CURRENT_DATE,
    is_present BOOLEAN DEFAULT FALSE,
    processed_payment BOOLEAN DEFAULT FALSE,
    UNIQUE(student_id, class_id, attendance_date)
);

-- 2. UPDATE USERNAME LENGTH (Your unique naming convention might be longer than 50 chars)
ALTER TABLE users ALTER COLUMN username TYPE VARCHAR(100);

-- 3. INSERT A TEST CLASS FOR YOUR TEACHER (Teacher ID 3)
INSERT INTO classes (class_name, school_id, teacher_id, pay_per_session)
VALUES ('Java Programming - MMCC', 1, 3, 20.00);

-- 4. CLEAN UP/UPDATE YOUR TEST STUDENTS TO YOUR NEW FORMAT
UPDATE users 
SET username = 'rudreshGmmcc@vces' 
WHERE username = 'student_kyle';

UPDATE users 
SET username = 'anandGmmcc@vces' 
WHERE username = 'student_stan';