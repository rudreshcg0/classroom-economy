-- ==========================================
-- PHASE 1: CORE INFRASTRUCTURE (The Basics)
-- ==========================================

CREATE TABLE schools (
    school_id SERIAL PRIMARY KEY,
    school_name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student')),
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    roll_no VARCHAR(20) DEFAULT NULL,
    CONSTRAINT unique_roll_per_school UNIQUE (roll_no, school_id)
);

-- ==========================================
-- PHASE 2: ECONOMY LAYER (The Money)
-- ==========================================

CREATE TABLE wallets (
    student_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    school_id INTEGER REFERENCES schools(school_id)
);

CREATE TABLE teacher_allowance (
    teacher_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_budget DECIMAL(10,2) NOT NULL,
    current_balance DECIMAL(10,2) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id)
);

-- ==========================================
-- PHASE 3: ACADEMIC LAYER (Classes & Junctions)
-- ==========================================

-- We added ON DELETE SET NULL here recently so classes stay if a teacher leaves
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL, 
    pay_per_session DECIMAL(10,2) DEFAULT 10.00
);

-- This is the NEWEST addition: Allows students in multiple classes
CREATE TABLE student_classes (
    student_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INT REFERENCES classes(class_id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, class_id)
);

-- ==========================================
-- PHASE 4: TRANSACTION LAYER (Logs & History)
-- ==========================================

CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(class_id) ON DELETE CASCADE,
    attendance_date DATE DEFAULT CURRENT_DATE,
    is_present BOOLEAN DEFAULT FALSE,
    processed_payment BOOLEAN DEFAULT FALSE,
    UNIQUE(student_id, class_id, attendance_date)
);

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

CREATE TABLE payment_requests (
    request_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id), -- The one who wants money
    receiver_id INT REFERENCES users(user_id), -- The one who has to pay
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, APPROVED, DECLINED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    school_id INT REFERENCES schools(school_id)
);

CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(user_id),
    item_name VARCHAR(100),
    price DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'PENDING_TEACHER', -- Teacher must acknowledge
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1. Table for items created by teachers
CREATE TABLE marketplace_items (
    item_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id),
    school_id INT REFERENCES schools(school_id),
    item_name VARCHAR(100) NOT NULL,
    item_description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT -1, -- Use -1 for unlimited, 0 for Sold Out
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reward_types (
    id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    icon VARCHAR(20) DEFAULT '⭐',
    is_positive BOOLEAN DEFAULT TRUE
);

CREATE TABLE limit_requests (
    request_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id),
    requested_amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    school_id INT REFERENCES schools(school_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);