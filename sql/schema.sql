CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE schools (
    school_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_name VARCHAR(100) UNIQUE NOT NULL,
    subdomain VARCHAR(50) UNIQUE, -- For school-specific login portals
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    public_id UUID UNIQUE DEFAULT uuid_generate_v4(), -- Use this for API/AJAX calls
    school_id UUID REFERENCES schools(school_id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Renamed to emphasize hashing
    role VARCHAR(20) CHECK (role IN ('super_admin', 'school_admin', 'teacher', 'student')),
    is_active BOOLEAN DEFAULT TRUE,
    must_change_password BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Separate profile data to keep the 'users' table lean for auth checks
CREATE TABLE user_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    full_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    birthdate DATE,
    roll_no VARCHAR(20),
    avatar_url TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallets (
    student_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance DECIMAL(12,2) DEFAULT 0.00 CHECK (balance >= 0), -- Prevent negative balances
    currency_name VARCHAR(20) DEFAULT 'Credits',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE teacher_budgets (
    teacher_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_limit DECIMAL(12,2) NOT NULL,
    current_available DECIMAL(12,2) NOT NULL CHECK (current_available >= 0),
    last_refill_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- The "Single Source of Truth" for all money movement
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(school_id),
    sender_id INTEGER REFERENCES users(user_id),
    receiver_id INTEGER REFERENCES users(user_id),
    amount DECIMAL(12,2) NOT NULL,
    type VARCHAR(30), -- 'REWARD', 'ATTENDANCE_PAY', 'MARKETPLACE_PURCHASE', 'FINE'
    description TEXT,
    metadata JSONB, -- Professional addition: store context like { "class_id": 5, "item_id": 10 }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    school_id UUID REFERENCES schools(school_id) ON DELETE CASCADE,
    teacher_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    class_name VARCHAR(100) NOT NULL,
    base_pay_rate DECIMAL(10,2) DEFAULT 10.00,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE class_enrollments (
    student_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(class_id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, class_id)
);

CREATE TABLE attendance_records (
    record_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    class_id INTEGER REFERENCES classes(class_id) ON DELETE CASCADE,
    attendance_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) CHECK (status IN ('PRESENT', 'ABSENT', 'TARDY')),
    payout_transaction_id UUID REFERENCES transactions(transaction_id), -- Links to the payment
    UNIQUE(student_id, class_id, attendance_date)
);

CREATE TABLE marketplace_items (
    item_id SERIAL PRIMARY KEY,
    teacher_id INTEGER REFERENCES users(user_id),
    school_id UUID REFERENCES schools(school_id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT -1, -- -1 for infinite
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE marketplace_orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id INTEGER REFERENCES users(user_id),
    item_id INTEGER REFERENCES marketplace_items(item_id),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DENIED', 'FULFILLED')),
    purchase_price DECIMAL(10,2) NOT NULL, -- Price at time of purchase
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

