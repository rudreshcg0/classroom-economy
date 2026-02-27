<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>VCES | Secure Your Account</title>
    <style>
        /* Reuse your root variables and background animations from login.jsp */
        :root { --primary: #2196F3; --bg-start: #f4f7f6; --bg-mid-blue: #e3f2fd; }
        
        body { 
            font-family: 'Segoe UI', sans-serif; margin: 0; height: 100vh;
            display: flex; justify-content: center; align-items: center;
            background: linear-gradient(-45deg, var(--bg-start), var(--bg-mid-blue), #e8f5e9, var(--bg-start));
            background-size: 400% 400%; animation: gradientBG 15s ease infinite;
        }

        .reset-card {
            background: rgba(255, 255, 255, 0.95); padding: 40px;
            border-radius: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            width: 100%; max-width: 400px; text-align: center; z-index: 10;
        }

        input {
            width: 100%; padding: 14px; margin: 10px 0;
            border: 1.5px solid #e2e8f0; border-radius: 12px; box-sizing: border-box;
        }

        .btn-reset {
            width: 100%; padding: 14px; border: none; border-radius: 12px;
            background: var(--primary); color: white; font-weight: bold;
            cursor: pointer; margin-top: 15px; transition: 0.3s;
        }
    </style>
</head>
<body>
    <div class="reset-card">
        <img src="assets/image.png" alt="VCES Logo" style="width: 100px; margin-bottom: 15px;">
        <h2>Secure Your Account</h2>
        <p style="color: #64748b; font-size: 14px; margin-bottom: 25px;">
            This is your first login. Please set a personalized password to continue.
        </p>

        <form action="changePassword" method="POST">
            <input type="password" name="newPassword" placeholder="New Password" required minlength="6">
            <input type="password" name="confirmPassword" placeholder="Confirm New Password" required>
            <button type="submit" class="btn-reset">Update & Access Wallet</button>
        </form>
    </div>
</body>
</html>