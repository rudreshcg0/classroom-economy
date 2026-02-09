-- 1. Schools (The foundation)
CREATE TABLE schools (
    school_id SERIAL PRIMARY KEY,
    school_name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users (Includes the Roll No update)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student')),
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    roll_no VARCHAR(20) DEFAULT NULL,
    CONSTRAINT unique_roll_per_school UNIQUE (roll_no, school_id)
);

-- 3. Teacher Allowance
CREATE TABLE teacher_allowance (
    teacher_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_budget DECIMAL(10,2) NOT NULL,
    current_balance DECIMAL(10,2) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id)
);

-- 4. Wallets
CREATE TABLE wallets (
    student_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    school_id INTEGER REFERENCES schools(school_id)
);

-- 5. Classes
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(user_id),
    pay_per_session DECIMAL(10,2) DEFAULT 10.00
);

-- 6. Attendance (The transaction link)
CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(class_id) ON DELETE CASCADE,
    attendance_date DATE DEFAULT CURRENT_DATE,
    is_present BOOLEAN DEFAULT FALSE,
    processed_payment BOOLEAN DEFAULT FALSE,
    UNIQUE(student_id, class_id, attendance_date)
);

-- 7. Transactions (The history log)
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES users(user_id), 
    receiver_id INTEGER REFERENCES users(user_id), 
    amount DECIMAL(10,2) NOT NULL,
    type VARCHAR(20), -- 'ALLOWANCE', 'ATTENDANCE_PAY', 'TRANSFER'
    description TEXT,
    school_id INTEGER REFERENCES schools(school_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);