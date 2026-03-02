<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Reset Password - VCES Pay</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/forgot_password.css">
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
<script src="${pageContext.request.contextPath}/js/forgot_password.js"></script>
</body>
</html>