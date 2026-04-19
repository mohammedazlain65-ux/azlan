<%-- 
    Document   : adlogin
    Created on : 28 Jan, 2026, 11:42:11 PM
    Author     : moham
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - MarketHub</title>
    
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
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
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
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
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
            color: var(--primary-color);
        }
        
        .security-badge {
            background: rgba(255, 153, 0, 0.2);
            border: 2px solid var(--primary-color);
            border-radius: 10px;
            padding: 15px;
            margin-top: 30px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .security-badge i {
            font-size: 30px;
            color: var(--primary-color);
        }
        
        .security-badge div {
            flex: 1;
        }
        
        .security-badge strong {
            display: block;
            margin-bottom: 5px;
        }
        
        .security-badge small {
            opacity: 0.8;
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
            color: #2c3e50;
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
        
        .alert-warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 10px;
            padding: 12px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: #856404;
        }
        
        .alert-warning i {
            font-size: 20px;
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
            border-color: #2c3e50;
            box-shadow: 0 0 0 0.2rem rgba(44, 62, 80, 0.25);
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
            color: #2c3e50;
        }
        
        .btn-login {
            background: #2c3e50;
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
            background: #1a252f;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(44, 62, 80, 0.4);
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
            color: #2c3e50;
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
            color: #2c3e50;
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
                <h2>Admin Control Panel</h2>
                <p>Secure access to the marketplace administration dashboard with full platform control.</p>
                
                <ul class="features">
                    <li>
                        <i class="fas fa-shield-alt"></i>
                        <span>Platform-wide management access</span>
                    </li>
                    <li>
                        <i class="fas fa-users-cog"></i>
                        <span>User & seller management</span>
                    </li>
                    <li>
                        <i class="fas fa-chart-line"></i>
                        <span>Analytics & reporting tools</span>
                    </li>
                    <li>
                        <i class="fas fa-cog"></i>
                        <span>System configuration</span>
                    </li>
                </ul>
                
                <div class="security-badge">
                    <i class="fas fa-lock"></i>
                    <div>
                        <strong>Secure Login</strong>
                        <small>All admin activities are logged and monitored</small>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Right Side -->
        <div class="login-right">
            <div class="logo-section">
                <i class="fas fa-user-shield"></i>
                <h3>Administrator Login</h3>
                <p>Authorized access only</p>
            </div>
            
            <div class="alert-warning">
                <i class="fas fa-exclamation-triangle"></i>
                <span>This is a restricted area. Unauthorized access is prohibited.</span>
            </div>
            
            <form action="adminReg" method="post" onsubmit="return validateForm()"> 
                <div class="form-group">
                    <label class="form-label">Admin ID / Email</label>
                    <div class="input-group">
                        <i class="fas fa-user-shield"></i>
                        <input type="text" class="form-control" name="adminId" placeholder="Enter your admin ID or email" required>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Password</label>
                    <div class="input-group">
                        <i class="fas fa-lock"></i>
                        <input type="password" class="form-control" id="password" name="password" placeholder="Enter your secure password" required>
                        <i class="fas fa-eye password-toggle" onclick="togglePassword()"></i>
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Two-Factor Authentication Code (Optional)</label>
                    <div class="input-group">
                        <i class="fas fa-mobile-alt"></i>
                        <input type="text" class="form-control" name="twofa" placeholder="Enter 6-digit code" maxlength="6" pattern="[0-9]{6}">
                    </div>
                </div>
                
                <div class="forgot-password">
                    <a href="#" onclick="handleForgotPassword()">Contact Support</a>
                </div>
                
                <button type="submit" class="btn-login">
                    <i class="fas fa-sign-in-alt"></i> Secure Login
                </button>
            </form>
            
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
            const adminId = formData.get('adminId');
            const password = formData.get('password');
            const twofa = formData.get('twofa');
            
            // Here you would normally send data to your backend
            console.log('Admin login attempt:', { adminId, password, twofa });
            
            let message = `Admin login successful!\n\nAdmin ID: ${adminId}`;
            if (twofa) {
                message += `\n2FA Code: ${twofa}`;
            }
            message += `\n\nThis would normally:\n1. Authenticate with backend\n2. Verify 2FA if provided\n3. Store session/token\n4. Redirect to admin dashboard`;
            
            alert(message);
            
            // Simulate redirect
            // window.location.href = 'admin-dashboard.html';
            
            return false;
        }
        
        function handleForgotPassword() {
            alert('For security reasons, please contact the system administrator or IT support team to reset your admin password.\n\nSupport: admin-support@markethub.com\nPhone: +91 1800-ADMIN-24');
            return false;
        }
    </script>
</body>
</html>