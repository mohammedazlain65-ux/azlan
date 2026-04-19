<%-- 
    Document   : buyerReg
    Created on : 28 Jan, 2026, 11:46:46 PM
    Author     : moham
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Registration - MarketHub</title>
    
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 40px 20px;
        }
        
        .register-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            max-width: 900px;
            margin: 0 auto;
        }
        
        .register-header {
            background: linear-gradient(135deg, var(--primary-color) 0%, #ff7700 100%);
            padding: 40px;
            text-align: center;
            color: white;
        }
        
        .register-header i {
            font-size: 50px;
            margin-bottom: 15px;
        }
        
        .register-header h2 {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .register-header p {
            opacity: 0.9;
            font-size: 16px;
        }
        
        .register-body {
            padding: 50px;
        }
        
        .form-section {
            margin-bottom: 30px;
        }
        
        .form-section-title {
            font-size: 18px;
            font-weight: 600;
            color: var(--dark-bg);
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--light-bg);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .form-section-title i {
            color: var(--primary-color);
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            font-weight: 600;
            color: var(--dark-bg);
            margin-bottom: 8px;
            display: block;
            font-size: 14px;
        }
        
        .form-label .required {
            color: var(--danger-color);
        }
        
        .form-control, .form-select {
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            padding: 12px 15px;
            font-size: 14px;
            transition: all 0.3s ease;
            width: 100%;
        }
        
        .form-control:focus, .form-select:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 0.2rem rgba(255, 153, 0, 0.25);
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
            color: var(--primary-color);
        }
        
        .password-strength {
            margin-top: 8px;
            height: 4px;
            background: #e0e0e0;
            border-radius: 2px;
            overflow: hidden;
        }
        
        .password-strength-bar {
            height: 100%;
            width: 0;
            transition: all 0.3s ease;
        }
        
        .password-strength-bar.weak {
            width: 33%;
            background: var(--danger-color);
        }
        
        .password-strength-bar.medium {
            width: 66%;
            background: var(--primary-color);
        }
        
        .password-strength-bar.strong {
            width: 100%;
            background: var(--success-color);
        }
        
        .password-hint {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        
        .checkbox-group {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            margin-bottom: 20px;
        }
        
        .checkbox-group input[type="checkbox"] {
            margin-top: 3px;
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .checkbox-group label {
            font-size: 14px;
            color: #666;
            cursor: pointer;
        }
        
        .checkbox-group label a {
            color: var(--primary-color);
            text-decoration: none;
        }
        
        .checkbox-group label a:hover {
            text-decoration: underline;
        }
        
        .btn-register {
            background: var(--primary-color);
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
        
        .btn-register:hover {
            background: #ff7700;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(255, 153, 0, 0.4);
        }
        
        .btn-register:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
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
        
        .social-register {
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
            border-color: var(--primary-color);
            color: var(--primary-color);
        }
        
        .social-btn i {
            font-size: 18px;
        }
        
        .login-link {
            text-align: center;
            margin-top: 20px;
            color: #666;
            font-size: 14px;
        }
        
        .login-link a {
            color: var(--primary-color);
            text-decoration: none;
            font-weight: 600;
        }
        
        .login-link a:hover {
            color: #ff7700;
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
            color: var(--primary-color);
        }
        
        @media (max-width: 768px) {
            .register-body {
                padding: 30px 20px;
            }
            
            .register-header {
                padding: 30px 20px;
            }
            
            .social-register {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>

    <div class="register-container">
        <!-- Header -->
        <div class="register-header">
            <i class="fas fa-user-plus"></i>
            <h2>Create Customer Account</h2>
            <p>Join thousands of happy shoppers on MarketHub</p>
        </div>
        
        <!-- Body -->
        <div class="register-body">
            
            <form action="buyerReg" method="post" onsubmit="return validateForm()">   
                <!-- Personal Information -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-user"></i>
                        Personal Information
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Full Name <span class="required">*</span></label>
                        <input type="text" class="form-control" name="name" placeholder="Enter your full name" required>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Email Address <span class="required">*</span></label>
                        <div class="input-group">
                            <i class="fas fa-envelope"></i>
                            <input type="email" class="form-control" name="email" placeholder="your.email@example.com" required>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Phone Number <span class="required">*</span></label>
                        <div class="input-group">
                            <i class="fas fa-phone"></i>
                            <input type="tel" class="form-control" name="phno" placeholder="+91 9876543210" required>
                        </div>
                    </div>
                </div>
                
                <!-- Account Security -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-lock"></i>
                        Account Security
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Password <span class="required">*</span></label>
                        <div class="input-group">
                            <i class="fas fa-lock"></i>
                            <input type="password" class="form-control" id="password" name="password" placeholder="Create a strong password" required onkeyup="checkPasswordStrength()">
                            <i class="fas fa-eye password-toggle" onclick="togglePassword('password')"></i>
                        </div>
                        <div class="password-strength">
                            <div class="password-strength-bar" id="passwordStrengthBar"></div>
                        </div>
                        <div class="password-hint">Use at least 8 characters with letters, numbers, and symbols</div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Confirm Password <span class="required">*</span></label>
                        <div class="input-group">
                            <i class="fas fa-lock"></i>
                            <input type="password" class="form-control" id="confirmPassword" name="confirmpassword" placeholder="Re-enter your password" required>
                            <i class="fas fa-eye password-toggle" onclick="togglePassword('confirmPassword')"></i>
                        </div>
                    </div>
                </div>
                
                <!-- Terms and Conditions -->
                <div class="checkbox-group">
                    <input type="checkbox" id="terms" name="terms" required>
                    <label for="terms">
                        I agree to the <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a> <span class="required">*</span>
                    </label>
                </div>
                
                <div class="checkbox-group">
                    <input type="checkbox" id="newsletter" name="newsletter">
                    <label for="newsletter">
                        Subscribe to our newsletter for exclusive deals and updates
                    </label>
                </div>
                
                <button type="submit" class="btn-register">
                    <i class="fas fa-user-plus"></i> Create Account
                </button>
            </form>
           
            <div class="divider">
                <span>OR REGISTER WITH</span>
            </div>
            
            
            
            <div class="login-link">
                Already have an account? <a href="buyerlogin.jsp">Login here</a>
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
        function togglePassword(fieldId) {
            const passwordInput = document.getElementById(fieldId);
            const toggleIcon = passwordInput.parentElement.querySelector('.password-toggle');
            
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
        
        function checkPasswordStrength() {
            const password = document.getElementById('password').value;
            const strengthBar = document.getElementById('passwordStrengthBar');
            
            let strength = 0;
            if (password.length >= 8) strength++;
            if (password.match(/[a-z]/) && password.match(/[A-Z]/)) strength++;
            if (password.match(/[0-9]/)) strength++;
            if (password.match(/[^a-zA-Z0-9]/)) strength++;
            
            strengthBar.className = 'password-strength-bar';
            if (strength === 1 || strength === 2) {
                strengthBar.classList.add('weak');
            } else if (strength === 3) {
                strengthBar.classList.add('medium');
            } else if (strength >= 4) {
                strengthBar.classList.add('strong');
            }
        }
        
        function validateForm() {
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (password !== confirmPassword) {
                alert('Passwords do not match! Please try again.');
                return false;
            }
            
            return true;
        }
        
        function handleSocialRegister(provider) {
            alert(`${provider.charAt(0).toUpperCase() + provider.slice(1)} registration clicked!\n\nThis would redirect to ${provider} OAuth.`);
        }
    </script>
</body>
</html>
