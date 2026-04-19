<%-- 
    Document   : sellerlogin
    Created on : 28 Jan, 2026, 11:39:41 PM
    Author     : moham
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seller Login - MarketHub</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <style>
        :root {
            --primary-color: #FF9900;
            --secondary-color: #146EB4;
            --dark-bg: #232F3E;
            --light-bg: #F3F3F3;
            --success-color: #28a745;
            --danger-color: #dc3545;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .login-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            max-width: 1000px;
            width: 100%;
            display: flex;
            min-height: 600px;
        }
        
        .login-left {
            flex: 1;
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            padding: 60px 40px;
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }
        
        .login-left::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: pulse 15s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
        }
        
        .login-left-content {
            position: relative;
            z-index: 1;
        }
        
        .login-left h2 {
            font-size: 36px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        
        .login-left p {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 30px;
        }
        
        .login-left .features {
            list-style: none;
            padding: 0;
        }
        
        .login-left .features li {
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .login-left .features li i {
            font-size: 20px;
            color: white;
        }
        
        .login-right {
            flex: 1;
            padding: 60px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        
        .logo-section {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .logo-section i {
            font-size: 60px;
            color: #11998e;
            margin-bottom: 10px;
        }
        
        .logo-section h3 {
            color: var(--dark-bg);
            font-weight: bold;
            font-size: 28px;
        }
        
        .logo-section p {
            color: #666;
            font-size: 14px;
        }
        
        .form-group {
            margin-bottom: 25px;
        }
        
        .form-label {
            font-weight: 600;
            color: var(--dark-bg);
            margin-bottom: 8px;
            display: block;
        }
        
        .form-control {
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            padding: 12px 15px;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            border-color: #11998e;
            box-shadow: 0 0 0 0.2rem rgba(17, 153, 142, 0.25);
        }
        
        .input-group {
            position: relative;
        }
        
        .input-group i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #999;
        }
        
        .input-group .form-control {
            padding-left: 45px;
        }
        
        .password-toggle {
            position: absolute;
            right: 15px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            color: #999;
        }
        
        .password-toggle:hover {
            color: #11998e;
        }
        
        .btn-login {
            background: #11998e;
            color: white;
            border: none;
            padding: 14px;
            border-radius: 10px;
            font-weight: 600;
            font-size: 16px;
            width: 100%;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .btn-login:hover {
            background: #0d7a70;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(17, 153, 142, 0.4);
        }
        
        .divider {
            text-align: center;
            margin: 25px 0;
            position: relative;
        }
        
        .divider::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 1px;
            background: #e0e0e0;
        }
        
        .divider span {
            background: white;
            padding: 0 15px;
            position: relative;
            color: #999;
            font-size: 14px;
        }
        
        .social-login {
            display: flex;
            gap: 15px;
            margin-bottom: 25px;
        }
        
        .social-btn {
            flex: 1;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            background: white;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-weight: 600;
            color: #333;
        }
        
        .social-btn:hover {
            border-color: #11998e;
            color: #11998e;
        }
        
        .social-btn i {
            font-size: 18px;
        }
        
        .forgot-password {
            text-align: right;
            margin-bottom: 20px;
        }
        
        .forgot-password a {
            color: var(--secondary-color);
            text-decoration: none;
            font-size: 14px;
        }
        
        .forgot-password a:hover {
            color: #11998e;
        }
        
        .register-link {
            text-align: center;
            margin-top: 20px;
            color: #666;
            font-size: 14px;
        }
        
        .register-link a {
            color: #11998e;
            text-decoration: none;
            font-weight: 600;
        }
        
        .register-link a:hover {
            color: #0d7a70;
        }
        
        .back-home {
            text-align: center;
            margin-top: 15px;
        }
        
        .back-home a {
            color: #999;
            text-decoration: none;
            font-size: 14px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        
        .back-home a:hover {
            color: #11998e;
        }
        
        @media (max-width: 768px) {
            .login-container {
                flex-direction: column;
            }
            
            .login-left {
                padding: 40px 30px;
                min-height: 250px;
            }
            
            .login-right {
                padding: 40px 30px;
            }
            
            .login-left h2 {
                font-size: 28px;
            }
        }
    </style>
</head>
<body>

    <div class="login-container">
        <!-- Left Side -->
        <div class="login-left">
            <div class="login-left-content">
                <h2>Seller Portal</h2>
                <p>Access your seller dashboard to manage products, track sales, and grow your business.</p>
                
                <ul class="features">
                    <li>
                        <i class="fas fa-check-circle"></i>
                        <span>Manage your product inventory</span>
                    </li>
                    <li>
                        <i class="fas fa-check-circle"></i>
                        <span>Track orders and sales analytics</span>
                    </li>
                    <li>
                        <i class="fas fa-check-circle"></i>
                        <span>Communicate with customers</span>
                    </li>
                    <li>
                        <i class="fas fa-check-circle"></i>
                        <span>Access seller support 24/7</span>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Right Side -->
        <div class="login-right">
            <div class="logo-section">
                <i class="fas fa-store"></i>
                <h3>Seller Login</h3>
                <p>Sign in to your seller account</p>
            </div>
            
            <form action="sellerlogin" method="post" onsubmit="return validateForm()">
                <div class="form-group">
                    <label class="form-label">Email Address / Seller ID</label>
                    <div class="input-group">
                        <i class="fas fa-envelope"></i>
                        <input type="text" class="form-control" name="email" placeholder="Enter your email or seller ID" required>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Password</label>
                    <div class="input-group">
                        <i class="fas fa-lock"></i>
                        <input type="password" class="form-control" id="password" name="password" placeholder="Enter your password" required>
                        <i class="fas fa-eye password-toggle" onclick="togglePassword()"></i>
                    </div>
                </div>
                
                
                
                <button type="submit" class="btn-login">
                    <i class="fas fa-sign-in-alt"></i> Login to Dashboard
                </button>
            </form>
            
            <div class="divider">
                <span>OR</span>
            </div>
            
            
            
            <div class="register-link">
                Not a seller yet? <a href="sellerReg.jsp">Register as Seller</a>
            </div>
            
            <div class="back-home">
                <a href="index.html">
                    <i class="fas fa-arrow-left"></i> Back to Home
                </a>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.querySelector('.password-toggle');
            
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggleIcon.classList.remove('fa-eye');
                toggleIcon.classList.add('fa-eye-slash');
            } else {
                passwordInput.type = 'password';
                toggleIcon.classList.remove('fa-eye-slash');
                toggleIcon.classList.add('fa-eye');
            }
        }
        
        function handleLogin(event) {
            event.preventDefault();
            
            const formData = new FormData(event.target);
            const email = formData.get('email');
            const password = formData.get('password');
            
            // Here you would normally send data to your backend
            console.log('Seller login attempt:', { email, password });
            
            alert(`Seller login successful!\n\nEmail/ID: ${email}\n\nThis would normally:\n1. Authenticate with backend\n2. Store session/token\n3. Redirect to seller dashboard`);
            
            // Simulate redirect
            // window.location.href = 'seller-dashboard.html';
            
            return false;
        }
        
        function handleForgotPassword() {
            const email = prompt('Enter your email address to reset password:');
            if (email) {
                alert(`Password reset link has been sent to ${email}\n\nThis would normally send a reset email.`);
            }
            return false;
        }
        
        function handleSocialLogin(provider) {
            alert(`${provider.charAt(0).toUpperCase() + provider.slice(1)} login clicked!\n\nThis would redirect to ${provider} OAuth.`);
        }
    </script>
</body>
</html>
