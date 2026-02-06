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