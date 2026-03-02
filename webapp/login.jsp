<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VCES | Secure Login</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/login.css">
</head>
<body>

    <div class="doodle-container">
        <div class="doodle" style="top: 10%; left: 15%;">💰</div>
        <div class="doodle" style="top: 8%; left: 45%; animation-delay: 1s;">🎓</div>
        <div class="doodle" style="top: 12%; right: 15%; animation-delay: 2s;">📈</div>
        <div class="doodle" style="top: 25%; left: 5%; animation-delay: 0.5s;">📓</div>
        <div class="doodle" style="top: 22%; right: 8%; animation-delay: 1.5s;">🪙</div>
        
        <div class="doodle" style="top: 45%; left: 12%; animation-delay: 3s;">✏️</div>
        <div class="doodle" style="top: 50%; right: 12%; animation-delay: 0.8s;">💳</div>
        <div class="doodle" style="top: 35%; left: 25%; animation-delay: 2.2s;">🍎</div>
        <div class="doodle" style="top: 38%; right: 28%; animation-delay: 1.2s;">🏦</div>

        <div class="doodle" style="bottom: 12%; left: 18%; animation-delay: 4s;">📊</div>
        <div class="doodle" style="bottom: 15%; right: 20%; animation-delay: 0.3s;">🏫</div>
        <div class="doodle" style="bottom: 25%; left: 8%; animation-delay: 2.5s;">💸</div>
        <div class="doodle" style="bottom: 22%; right: 5%; animation-delay: 1.8s;">⭐</div>
        <div class="doodle" style="bottom: 8%; left: 48%; animation-delay: 3.5s;">📖</div>
    </div>

    <div class="login-card">
        <img src="assets/image.png" alt="VCES Logo" class="logo">
        
        <h2>LOG IN TO YOUR WALLET
        </h2>
        <p class="subtitle">Virtual Classroom Economy Management</p>

        <% if(request.getParameter("error") != null) { %>
            <div class="error-msg">
                <%= request.getParameter("error").equals("invalid") ? "Invalid Credentials" : "Access Denied" %>
            </div>
        <% } %>

        <form action="login" method="POST">
            <input type="text" name="username" placeholder="Username" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit" class="btn-login">Login</button>
        </form>

        <div class="links">
            <a href="forgot_password.jsp">Forgot Password?</a>
        </div>
    </div>
    <script src="${pageContext.request.contextPath}/js/login.js"></script>
</body>
</html>