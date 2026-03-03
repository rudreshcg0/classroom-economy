-- 1. Create the School
INSERT INTO schools (school_name) VALUES ('MMCC_Deccan');

-- 2. Create the Users (Admin, Teacher, Students)
INSERT INTO users (username, password, role, school_id, roll_no) VALUES 
('admin', 'admin123', 'school_admin', 1, NULL),
('profe', 'atlantis', 'teacher', 1, NULL),
('rudresh.101@vces', 'pass123', 'student', 1, '101'),
('anand.102@vces', 'pass123', 'student', 1, '102');

-- 3. Setup the Teacher's Wallet/Allowance
INSERT INTO teacher_allowance (teacher_id, monthly_budget, current_balance, school_id)
VALUES (2, 500.00, 500.00, 1);

-- 4. Create the Classes
INSERT INTO classes (class_name, school_id, teacher_id, pay_per_session)
VALUES ('Java Programming', 1, 2, 20.00),
       ('Python Basics', 1, 2, 15.00);

-- 5. LINK students to classes (The new many-to-many logic)
-- Rudresh is in both classes, Anand is only in Java
INSERT INTO student_classes (student_id, class_id) VALUES (3, 1), (3, 2), (4, 1);

-- 6. Initialize Student Wallets
INSERT INTO wallets (student_id, balance, school_id) VALUES 
(3, 0.00, 1),
(4, 0.00, 1);

-- Create a function that inserts a wallet
CREATE OR REPLACE FUNCTION initialize_student_wallet()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'student' THEN
        INSERT INTO wallets (student_id, balance, school_id)
        VALUES (NEW.user_id, 0.00, NEW.school_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger to the users table
CREATE TRIGGER trigger_create_wallet
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION initialize_student_wallet();


-- 1. Drop the existing strict constraint
ALTER TABLE transactions DROP CONSTRAINT transactions_receiver_id_fkey;

-- 2. Re-add it with CASCADE (this allows deletion)
ALTER TABLE transactions 
ADD CONSTRAINT transactions_receiver_id_fkey 
FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- 3. Do the same for sender_id just in case
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_sender_id_fkey;
ALTER TABLE transactions 
ADD CONSTRAINT transactions_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE;

DROP TABLE IF EXISTS payment_requests;

CREATE TABLE payment_requests (
    request_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id),   -- The one asking for money
    receiver_id INT REFERENCES users(user_id), -- The one who has to approve/pay
    amount DECIMAL(10,2) NOT NULL,
    note TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Final Payment Request Table
DROP TABLE IF EXISTS payment_requests;
CREATE TABLE payment_requests (
    request_id SERIAL PRIMARY KEY,
    sender_id INT REFERENCES users(user_id),   -- Student requesting money
    receiver_id INT REFERENCES users(user_id), -- Student who needs to pay
    amount DECIMAL(10,2) NOT NULL,
    note TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Final Marketplace Orders Table
DROP TABLE IF EXISTS marketplace_orders;
CREATE TABLE marketplace_orders (
    order_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES users(user_id),
    item_name VARCHAR(100),
    price DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'PENDING_TEACHER',
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure Marketplace orders are linked to transactions
ALTER TABLE marketplace_orders ADD COLUMN transaction_id INT REFERENCES transactions(transaction_id);

-- Ensure payment requests have a "DECLINED" status option
ALTER TABLE payment_requests ALTER COLUMN status SET DEFAULT 'PENDING';

-- 2. Update marketplace_orders to link to the specific item
ALTER TABLE marketplace_orders ADD COLUMN item_id INT REFERENCES marketplace_items(item_id);

ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_school_id_fkey,
ADD CONSTRAINT users_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(school_id) 
ON DELETE CASCADE;

-- Add this to your schema to track first-time logins
ALTER TABLE users ADD COLUMN must_change_password BOOLEAN DEFAULT TRUE;

-- Ensure the Root Admin is exempt by setting their flag to FALSE
UPDATE users SET must_change_password = FALSE WHERE role = 'platform_root';

ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- Fix the specific error regarding Marketplace Orders
ALTER TABLE marketplace_orders 
DROP CONSTRAINT IF EXISTS marketplace_orders_student_id_fkey;

ALTER TABLE marketplace_orders
ADD CONSTRAINT marketplace_orders_student_id_fkey 
FOREIGN KEY (student_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- Also apply to Transactions (if not already done)
ALTER TABLE transactions 
DROP CONSTRAINT IF EXISTS transactions_receiver_id_fkey;

ALTER TABLE transactions
ADD CONSTRAINT transactions_receiver_id_fkey 
FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- 1. FIX PAYMENT REQUESTS (Specifically mentioned in your last error log)
ALTER TABLE payment_requests 
DROP CONSTRAINT IF EXISTS payment_requests_sender_id_fkey,
DROP CONSTRAINT IF EXISTS payment_requests_receiver_id_fkey;

ALTER TABLE payment_requests
ADD CONSTRAINT payment_requests_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
ADD CONSTRAINT payment_requests_receiver_id_fkey 
FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- 2. FIX ATTENDANCE (If a student has been marked present, this will block deletion)
ALTER TABLE attendance 
DROP CONSTRAINT IF EXISTS attendance_student_id_fkey;

ALTER TABLE attendance
ADD CONSTRAINT attendance_student_id_fkey 
FOREIGN KEY (student_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- 3. FIX MARKETPLACE ITEMS (If you ever delete a TEACHER, this is required)
ALTER TABLE marketplace_items 
DROP CONSTRAINT IF EXISTS marketplace_items_teacher_id_fkey;

ALTER TABLE marketplace_items
ADD CONSTRAINT marketplace_items_teacher_id_fkey 
FOREIGN KEY (teacher_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE users ADD COLUMN full_name VARCHAR(100);
ALTER TABLE users ADD COLUMN birthdate DATE;

ALTER TABLE users ADD COLUMN otp_code VARCHAR(6);
ALTER TABLE users ADD COLUMN otp_expiry TIMESTAMP;

INSERT INTO reward_types (name, amount, icon, is_positive) VALUES 
('Helping Others', 5.00, '🤝', TRUE),
('On Task', 2.00, '🎯', TRUE),
('Participating', 3.00, '✋', TRUE),
('Disrupting', -5.00, '🤫', FALSE);