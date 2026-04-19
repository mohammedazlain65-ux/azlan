<%-- 
    Document   : sellerReg
    Created on : 28 Jan, 2026, 11:48:04 PM
    Author     : moham
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seller Registration - MarketHub</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <style>
        :root {
            --primary-color: #11998e;
            --secondary-color: #38ef7d;
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
            padding: 40px 20px;
        }
        
        .register-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .register-header {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
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
            color: var(--primary-color);
        }
        
        .file-upload {
            border: 2px dashed #e0e0e0;
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .file-upload:hover {
            border-color: var(--primary-color);
            background: #f8f9fa;
        }
        
        .file-upload i {
            font-size: 30px;
            color: var(--primary-color);
            margin-bottom: 10px;
        }
        
        .file-upload input[type="file"] {
            display: none;
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
            background: #0d7a70;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(17, 153, 142, 0.4);
        }
        
        .btn-register:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
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
            color: var(--primary-color);
        }
        
        .info-box {
            background: #e8f5f3;
            border-left: 4px solid var(--primary-color);
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        
        .info-box i {
            color: var(--primary-color);
            margin-right: 10px;
        }
        
        .info-box p {
            margin: 0;
            font-size: 14px;
            color: #666;
        }
        
        @media (max-width: 768px) {
            .register-body {
                padding: 30px 20px;
            }
            
            .register-header {
                padding: 30px 20px;
            }
        }
    </style>
</head>
<body>

    <div class="register-container">
        <!-- Header -->
        <div class="register-header">
            <i class="fas fa-store"></i>
            <h2>Become a Seller</h2>
            <p>Start selling your products to millions of customers</p>
        </div>
        
        <!-- Body -->
        <div class="register-body">
            <div class="info-box">
                <i class="fas fa-info-circle"></i>
                <p><strong>Before you start:</strong> Please have your business documents ready (GST certificate, PAN card, business license, bank account details)</p>
            </div>
            
            <form action="sellerReg" method="post" onsubmit="return validateForm()">
                <!-- Personal Information -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-user"></i>
                        Personal Information
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">First Name <span class="required">*</span></label>
                                <input type="text" class="form-control" name="firstName" placeholder="Enter your first name" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Last Name <span class="required">*</span></label>
                                <input type="text" class="form-control" name="lastName" placeholder="Enter your last name" required>
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Email Address <span class="required">*</span></label>
                                <div class="input-group">
                                    <i class="fas fa-envelope"></i>
                                    <input type="email" class="form-control" name="email" placeholder="your.email@example.com" required>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Phone Number <span class="required">*</span></label>
                                <div class="input-group">
                                    <i class="fas fa-phone"></i>
                                    <input type="tel" class="form-control" name="phno" placeholder="+91 9876543210" required>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Business Information -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-briefcase"></i>
                        Business Information
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Business Name <span class="required">*</span></label>
                        <div class="input-group">
                            <i class="fas fa-building"></i>
                            <input type="text" class="form-control" name="businessName" placeholder="Your business or company name" required>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Business Type <span class="required">*</span></label>
                                <select class="form-select" name="businessType" required>
                                    <option value="">Select Business Type</option>
                                    <option value="individual">Individual / Sole Proprietor</option>
                                    <option value="partnership">Partnership</option>
                                    <option value="pvt_ltd">Private Limited</option>
                                    <option value="ltd">Limited Company</option>
                                    <option value="llp">LLP</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Product Category <span class="required">*</span></label>
                                <select class="form-select" name="category" required>
                                    <option value="">Select Category</option>
                                    <option value="electronics">Electronics</option>
                                    <option value="fashion">Fashion & Apparel</option>
                                    <option value="home">Home & Living</option>
                                    <option value="books">Books & Stationery</option>
                                    <option value="beauty">Beauty & Health</option>
                                    <option value="sports">Sports & Fitness</option>
                                </select>
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">GST Number <span class="required">*</span></label>
                                <input type="text" class="form-control" name="gst" placeholder="22AAAAA0000A1Z5" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">PAN Number <span class="required">*</span></label>
                                <input type="text" class="form-control" name="pan" placeholder="ABCDE1234F" required>
                            </div>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Business Description <span class="required">*</span></label>
                        <textarea class="form-control" name="desc" rows="4" placeholder="Tell us about your business and what you sell..." required></textarea>
                    </div>
                </div>
                
                <!-- Business Address -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-map-marker-alt"></i>
                        Business Address
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Address Line 1 <span class="required">*</span></label>
                        <input type="text" class="form-control" name="address1" placeholder="Street address" required>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">Address Line 2</label>
                        <input type="text" class="form-control" name="address2" placeholder="Floor, building name (optional)">
                    </div>
                    
                    <div class="row">
                        <div class="col-md-4">
                            <div class="form-group">
                                <label class="form-label">City <span class="required">*</span></label>
                                <input type="text" class="form-control" name="city" placeholder="City" required>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-group">
                                <label class="form-label">State <span class="required">*</span></label>
                                <select class="form-select" name="state" required>
                                    <option value="">Select State</option>
                                    <option value="Karnataka">Karnataka</option>
                                    <option value="Maharashtra">Maharashtra</option>
                                    <option value="Tamil Nadu">Tamil Nadu</option>
                                    <option value="Delhi">Delhi</option>
                                    <option value="Gujarat">Gujarat</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-group">
                                <label class="form-label">PIN Code <span class="required">*</span></label>
                                <input type="text" class="form-control" name="pincode" placeholder="PIN code" required pattern="[0-9]{6}">
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Bank Details -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-university"></i>
                        Bank Account Details
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Account Holder Name <span class="required">*</span></label>
                                <input type="text" class="form-control" name="accountName" placeholder="As per bank records" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Account Number <span class="required">*</span></label>
                                <input type="text" class="form-control" name="accountNumber" placeholder="Bank account number" required>
                            </div>
                        </div>
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">IFSC Code <span class="required">*</span></label>
                                <input type="text" class="form-control" name="ifsc" placeholder="IFSC Code" required>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Bank Name <span class="required">*</span></label>
                                <input type="text" class="form-control" name="bankName" placeholder="Bank name" required>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Account Security -->
                <div class="form-section">
                    <div class="form-section-title">
                        <i class="fas fa-lock"></i>
                        Account Security
                    </div>
                    
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Password <span class="required">*</span></label>
                                <div class="input-group">
                                    <i class="fas fa-lock"></i>
                                    <input type="password" class="form-control" id="password" name="password" placeholder="Create a strong password" required>
                                    <i class="fas fa-eye password-toggle" onclick="togglePassword('password')"></i>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="form-label">Confirm Password <span class="required">*</span></label>
                                <div class="input-group">
                                    <i class="fas fa-lock"></i>
                                    <input type="password" class="form-control" id="confirmPassword" name="confirmpassword" placeholder="Re-enter password" required>
                                    <i class="fas fa-eye password-toggle" onclick="togglePassword('confirmPassword')"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Terms and Conditions -->
                <div class="checkbox-group">
                    <input type="checkbox" id="terms" name="terms" required>
                    <label for="terms">
                        I agree to the <a href="#">Seller Terms & Conditions</a> and <a href="#">Privacy Policy</a> <span class="required">*</span>
                    </label>
                </div>
                
                <div class="checkbox-group">
                    <input type="checkbox" id="sellerPolicy" name="sellerPolicy" required>
                    <label for="sellerPolicy">
                        I have read and agree to the <a href="#">Seller Policy</a> and <a href="#">Commission Structure</a> <span class="required">*</span>
                    </label>
                </div>
                
                <button type="submit" class="btn-register">
                    <i class="fas fa-rocket"></i> Submit Application
                </button>
            </form>
            
            <div class="login-link">
                Already a seller? <a href="sellerlogin.jsp">Login here</a>
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
        
        function validateForm() {
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (password !== confirmPassword) {
                alert('Passwords do not match! Please try again.');
                return false;
            }
            
            return true;
        }
    </script>
</body>
</html>
