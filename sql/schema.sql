-- ==========================================
-- PHASE 1: CORE INFRASTRUCTURE
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
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student', 'platform_root')),
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    full_name VARCHAR(150),
    email VARCHAR(150) UNIQUE,
    birthdate DATE,
    roll_no VARCHAR(20) DEFAULT NULL,
    must_change_password BOOLEAN DEFAULT TRUE,
    otp_code VARCHAR(10),
    otp_expiry TIMESTAMP,
    CONSTRAINT unique_roll_per_school UNIQUE (roll_no, school_id)
);

-- ==========================================
-- PHASE 2: ECONOMY LAYER
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
-- PHASE 3: ACADEMIC LAYER
-- ==========================================

CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL, 
    pay_per_session DECIMAL(10,2) DEFAULT 10.00
);

CREATE TABLE student_classes (
    student_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INT REFERENCES classes(class_id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, class_id)
);

-- ==========================================
-- PHASE 4: TRANSACTION & REQUEST LAYER
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
    type VARCHAR(50), -- 'ALLOWANCE', 'ATTENDANCE_PAY', 'TRANSFER', 'REWARD'
    description TEXT,
    school_id INTEGER REFERENCES schools(school_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payment_requests (
    request_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id),
    receiver_id INT REFERENCES users(user_id),
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    school_id INT REFERENCES schools(school_id)
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

-- ==========================================
-- PHASE 5: MARKETPLACE & REWARDS
-- ==========================================

CREATE TABLE marketplace_items (
    item_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id),
    school_id INT REFERENCES schools(school_id),
    item_name VARCHAR(100) NOT NULL,
    item_description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT -1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(user_id),
    item_id INT REFERENCES marketplace_items(item_id),
    status VARCHAR(20) DEFAULT 'PENDING_TEACHER',
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reward_types (
    id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    icon VARCHAR(20) DEFAULT '⭐',
    is_positive BOOLEAN DEFAULT TRUE
);
