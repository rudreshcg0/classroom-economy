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
    -- Increased length for secure BCrypt hashes
    password VARCHAR(255) NOT NULL, 
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student')),
    school_id INTEGER REFERENCES schools(school_id) ON DELETE CASCADE,
    roll_no VARCHAR(20) DEFAULT NULL,
    -- Security flag for forced resets
    must_change_password BOOLEAN DEFAULT FALSE,
    full_name VARCHAR(100),
    email VARCHAR(100),
    birthdate DATE,
    CONSTRAINT unique_roll_per_school UNIQUE (roll_no, school_id)
);

-- ==========================================
-- PHASE 2: ECONOMY LAYER (The Money)
-- ==========================================

CREATE TABLE wallets (
    student_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    -- SECURITY: Prevent negative balance 'money hacks'
    balance DECIMAL(10,2) DEFAULT 0.00 CHECK (balance >= 0),
    school_id INTEGER REFERENCES schools(school_id)
);

CREATE TABLE teacher_allowance (
    teacher_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_budget DECIMAL(10,2) NOT NULL CHECK (monthly_budget >= 0),
    -- SECURITY: Prevent teachers from awarding more than they have
    current_balance DECIMAL(10,2) NOT NULL CHECK (current_balance >= 0),
    temp_extension DECIMAL(10,2) DEFAULT 0.00,
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
    pay_per_session DECIMAL(10,2) DEFAULT 10.00 CHECK (pay_per_session >= 0)
);

CREATE TABLE student_classes (
    student_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INT REFERENCES classes(class_id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, class_id)
);

-- ==========================================
-- PHASE 4: TRANSACTION LAYER
-- ==========================================

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES users(user_id), 
    receiver_id INTEGER REFERENCES users(user_id), 
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    type VARCHAR(20), -- 'TRANSFER', 'SALARY', 'MARKETPLACE', 'REFUND'
    description TEXT,
    school_id INTEGER REFERENCES schools(school_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payment_requests (
    request_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id),
    receiver_id INT REFERENCES users(user_id),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    note TEXT,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    school_id INT REFERENCES schools(school_id)
);

CREATE TABLE marketplace_items (
    item_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES users(user_id),
    school_id INT REFERENCES schools(school_id),
    item_name VARCHAR(100) NOT NULL,
    item_description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    -- -1 for unlimited, 0+ for tracked stock
    stock INT DEFAULT -1 CHECK (stock >= -1), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(user_id),
    item_id INT REFERENCES marketplace_items(item_id) ON DELETE SET NULL,
    item_name VARCHAR(100),
    price DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'PENDING_TEACHER' CHECK (status IN ('PENDING_TEACHER', 'COMPLETED', 'REJECTED')),
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