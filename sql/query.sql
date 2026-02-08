-- 1. Insert the Teacher Allowance (Teacher ID is 3)
-- We must include school_id because your schema requires it
INSERT INTO teacher_allowance (teacher_id, monthly_budget, current_balance, school_id)
VALUES (3, 500.00, 500.00, 1)
ON CONFLICT (teacher_id) 
DO UPDATE SET 
    monthly_budget = 500.00,
    current_balance = 500.00,
    school_id = 1;

-- 2. Insert Test Students (Linked to School 1)
INSERT INTO users (username, password, role, school_id) 
VALUES 
('student_kyle', 'pass123', 'student', 1),
('student_stan', 'pass123', 'student', 1)
ON CONFLICT (username) DO NOTHING;

-- 3. Create Wallets for these students
-- We pull the user_id and school_id directly from the users table
INSERT INTO wallets (student_id, balance, school_id)
SELECT user_id, 100.00, school_id 
FROM users 
WHERE role = 'student' AND school_id = 1
ON CONFLICT (student_id) DO NOTHING;