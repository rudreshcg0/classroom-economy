<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Reset Password - VCES Pay</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f1f5f9; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); width: 100%; max-width: 400px; box-sizing: border-box; }
        h2 { color: #1e293b; margin-top: 0; text-align: center; font-size: 24px; }
        p { color: #64748b; font-size: 14px; text-align: center; margin-bottom: 30px; line-height: 1.5; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 8px; font-weight: 600; color: #475569; font-size: 13px; }
        input { width: 100%; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 14px; box-sizing: border-box; transition: 0.3s; }
        input:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1); }
        .btn { width: 100%; padding: 14px; border: none; background: #3b82f6; color: white; border-radius: 8px; cursor: pointer; font-weight: bold; font-size: 15px; transition: 0.3s; }
        .btn:hover { background: #2563eb; transform: translateY(-1px); }
        .error { background: #fee2e2; color: #ef4444; padding: 10px; border-radius: 8px; font-size: 13px; text-align: center; margin-bottom: 20px; border: 1px solid #fecaca; }
        .success { background: #dcfce7; color: #16a34a; padding: 10px; border-radius: 8px; font-size: 13px; text-align: center; margin-bottom: 20px; border: 1px solid #bbf7d0; }
        .back-link { display: block; text-align: center; margin-top: 20px; color: #64748b; text-decoration: none; font-size: 13px; }
        .back-link:hover { color: #1e293b; text-decoration: underline; }
        .otp-display { background: #f8fafc; border: 1px dashed #cbd5e0; padding: 10px; border-radius: 8px; text-align: center; margin-bottom: 20px; font-size: 13px; color: #1e293b; }
    </style>
</head>
<body>

<div class="card">
    <h2>Reset Password</h2>
    
    <% 
        String step = request.getParameter("step"); 
        String error = request.getParameter("error");
        String email = request.getParameter("email");
    %>

    <%-- Error Handling Messages --%>
    <% if ("notfound".equals(error)) { %>
        <div class="error">Email not found in our system.</div>
    <% } else if ("invalid".equals(error)) { %>
        <div class="error">Invalid or expired OTP. Please try again.</div>
    <% } else if ("db".equals(error)) { %>
        <div class="error">Database error. Please contact admin.</div>
    <% } %>

    <%-- UI Step 1: Request OTP --%>
    <% if (step == null) { %>
        <p>Enter the email address associated with your account and we'll send you a code to reset your password.</p>
        
        <form action="/classroom-economy/forgotPassword" method="POST">
            <input type="hidden" name="phase" value="sendOTP">
            <div class="form-group">
                <label>Registered Email Address</label>
                <input type="email" name="email" placeholder="e.g. name@student.vces" required>
            </div>
            <button type="submit" class="btn">Send Verification Code</button>
        </form>

    <%-- UI Step 2: Verify OTP and Reset --%>
    <% } else if ("2".equals(step)) { %>
        <div class="success">Code sent successfully!</div>
        <div class="otp-display">Verification code sent to:<br><strong><%= email %></strong></div>
        
        <form action="forgotPassword" method="POST">
            <input type="hidden" name="phase" value="verifyOTP">
            <input type="hidden" name="email" value="<%= email %>">
            
            <div class="form-group">
                <label>6-Digit Reset Code</label>
                <input type="text" name="otp" placeholder="Enter OTP" required maxlength="6" pattern="\d{6}">
            </div>
            
            <div class="form-group">
                <label>New Password</label>
                <input type="password" name="newPassword" placeholder="Minimum 6 characters" required minlength="6">
            </div>
            
            <button type="submit" class="btn">Update Password</button>
        </form>
    <% } %>

    <a href="login.jsp" class="back-link">← Back to Login</a>
</div>

</body>
</html>