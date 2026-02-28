<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VCES | Secure Login</title>
    <style>
        :root {
            --primary: #2196F3;
            --secondary: #00C853;
            --bg-start: #f4f7f6;
            --bg-mid-blue: #e3f2fd;
            --bg-mid-green: #e8f5e9;
        }

        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
            overflow: hidden;
            background: linear-gradient(-45deg, var(--bg-start), var(--bg-mid-blue), var(--bg-mid-green), var(--bg-start));
            background-size: 400% 400%;
            animation: gradientBG 15s ease infinite;
        }

        /* Subtle Pattern Overlay */
        body::before {
            content: "";
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            background-image: url('https://www.transparenttextures.com/patterns/school-book.png'); 
            opacity: 0.3;
            z-index: 0;
        }

        /* High-Density Doodle System */
        .doodle-container {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none;
            z-index: 1;
        }

        .doodle {
            position: absolute;
            font-size: 1.8rem;
            opacity: 0.2;
            animation: floatUpDown 5s ease-in-out infinite;
            filter: grayscale(30%);
        }

        @keyframes floatUpDown {
            0%, 100% { transform: translateY(0) rotate(0deg); }
            50% { transform: translateY(-25px) rotate(15deg); }
        }

        @keyframes gradientBG {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        /* The Login Card */
        .login-card {
            background: rgba(255, 255, 255, 0.92);
            padding: 40px;
            border-radius: 24px;
            box-shadow: 0 20px 50px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 380px;
            text-align: center;
            border: 1px solid rgba(255,255,255,1);
            z-index: 10;
            backdrop-filter: blur(8px);
        }

        .logo { width: 110px; margin-bottom: 15px; }
        h2 { color: #1e293b; margin: 0 0 10px 0; font-size: 1.6rem; }
        .subtitle { color: #64748b; font-size: 0.85rem; margin-bottom: 25px; }

        input {
            width: 100%;
            padding: 14px;
            margin: 8px 0;
            border: 1.5px solid #e2e8f0;
            border-radius: 12px;
            box-sizing: border-box;
            background: white;
            transition: all 0.3s;
        }

        input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 4px rgba(33, 150, 243, 0.1);
        }

        .btn-login { 
            width: 100%; padding: 14px; border: none; border-radius: 12px;
            background: var(--primary); color: white; font-weight: bold;
            cursor: pointer; margin-top: 15px; font-size: 1rem;
            transition: 0.3s;
        }

        .btn-login:hover { 
            background: #1976D2; 
            box-shadow: 0 8px 20px rgba(33, 150, 243, 0.3);
            transform: translateY(-2px);
        }

        .error-msg { 
            background: #fee2e2; color: #ef4444; padding: 12px;
            border-radius: 10px; font-size: 0.85rem; margin-bottom: 20px; 
            border: 1px solid #fecaca;
        }

        .links { margin-top: 25px; font-size: 0.85rem; }
        .links a { color: var(--primary); text-decoration: none; font-weight: 500; }
    </style>
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
</body>
</html>