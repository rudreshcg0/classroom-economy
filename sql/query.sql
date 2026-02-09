-- 1. Create School
INSERT INTO schools (school_name) VALUES ('MMCC_Deccan');

-- 2. Create Users (Admins, Teachers, Students)
-- NOTE: We use your new naming format
INSERT INTO users (username, password, role, school_id, roll_no) VALUES 
('admin', 'admin123', 'super_admin', 1, NULL),
('profe', 'atlantis', 'teacher', 1, NULL),
('rudresh.101@mmcc.vces', 'pass123', 'student', 1, '101'),
('anand.102@mmcc.vces', 'pass123', 'student', 1, '102');

-- 3. Setup Teacher Allowance (For Profe - ID 2)
-- Note: Check if Profe is ID 2 in your friend's DB, otherwise adjust IDs
INSERT INTO teacher_allowance (teacher_id, monthly_budget, current_balance, school_id)
VALUES (2, 500.00, 500.00, 1);

-- 4. Create Classes for the Teacher
INSERT INTO classes (class_name, school_id, teacher_id, pay_per_session)
VALUES ('Java Programming - MMCC', 1, 2, 20.00);

-- 5. Initialize Wallets for existing Students
INSERT INTO wallets (student_id, balance, school_id)
SELECT user_id, 100.00, school_id 
FROM users 
WHERE role = 'student';