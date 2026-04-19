<%-- 
    Document   : edit
    Created on : 4 Feb, 2026, 4:08:31 PM
    Author     : moham
--%>

<%@page import="DataBase.dbconfig"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.Statement"%>
<%@page import="java.sql.Connection"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    String password = null;
    try {
        username = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(username == null || password == null || username.equals("") || password.equals("")) {
            response.sendRedirect("ulogout");
            return;
        }
    } catch(Exception e) {
        response.sendRedirect("ulogout");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Product - MarketHub Seller</title>
    
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #6366f1;
            --secondary-color: #8b5cf6;
            --dark-bg: #1e293b;
            --light-bg: #F3F3F3;
            --success-color: #10b981;
            --danger-color: #ef4444;
            --warning-color: #f59e0b;
            --info-color: #06b6d4;
            --card-bg: #ffffff;
            --sidebar-bg: #0f172a;
            --sidebar-hover: #1e293b;
            --text-primary: #0f172a;
            --text-secondary: #64748b;
            --border-color: #e2e8f0;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Outfit', sans-serif;
            background: linear-gradient(135deg, #f0f4ff 0%, #e5edff 100%);
            min-height: 100vh;
            overflow-x: hidden;
        }
        
        /* ============ SIDEBAR ============ */
        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            height: 100vh;
            width: 260px;
            background: var(--sidebar-bg);
            box-shadow: 4px 0 20px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            z-index: 1000;
            overflow-y: auto;
        }
        
        .sidebar::-webkit-scrollbar {
            width: 6px;
        }
        
        .sidebar::-webkit-scrollbar-track {
            background: rgba(255,255,255,0.05);
        }
        
        .sidebar::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,0.2);
            border-radius: 3px;
        }
        
        .sidebar-header {
            padding: 25px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            background: linear-gradient(135deg, var(--dark-bg) 0%, #0f172a 100%);
        }
        
        .sidebar-logo {
            color: white;
            font-size: 24px;
            font-weight: 800;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 12px;
            letter-spacing: -0.5px;
        }
        
        .sidebar-logo i {
            color: var(--primary-color);
            font-size: 28px;
        }
        
        .sidebar-logo .seller-badge {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        
        .sidebar-menu {
            padding: 20px 0;
        }
        
        .menu-section-title {
            color: rgba(255,255,255,0.4);
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            padding: 20px 20px 10px;
        }
        
        .sidebar-menu a {
            display: flex;
            align-items: center;
            padding: 14px 20px;
            color: rgba(255,255,255,0.8);
            text-decoration: none;
            transition: all 0.3s ease;
            position: relative;
            font-weight: 500;
            margin: 2px 10px;
            border-radius: 8px;
        }
        
        .sidebar-menu a::before {
            content: '';
            position: absolute;
            left: 0;
            top: 50%;
            transform: translateY(-50%);
            width: 3px;
            height: 0;
            background: var(--primary-color);
            transition: height 0.3s ease;
            border-radius: 0 3px 3px 0;
        }
        
        .sidebar-menu a:hover,
        .sidebar-menu a.active {
            background: var(--sidebar-hover);
            color: white;
            padding-left: 25px;
        }
        
        .sidebar-menu a.active::before {
            height: 70%;
        }
        
        .sidebar-menu a i {
            font-size: 18px;
            margin-right: 15px;
            width: 20px;
            text-align: center;
            transition: all 0.3s ease;
        }
        
        .sidebar-menu a:hover i,
        .sidebar-menu a.active i {
            color: var(--primary-color);
            transform: scale(1.1);
        }
        
        .sidebar-menu .badge {
            margin-left: auto;
            font-size: 10px;
            padding: 4px 8px;
            font-weight: 700;
        }
        
        /* ============ MAIN CONTENT ============ */
        .main-content {
            margin-left: 260px;
            min-height: 100vh;
            transition: all 0.3s ease;
        }
        
        /* ============ TOP NAVBAR ============ */
        .top-navbar {
            background: white;
            padding: 20px 30px;
            box-shadow: 0 2px 15px rgba(0,0,0,0.05);
            position: sticky;
            top: 0;
            z-index: 999;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .navbar-left h1 {
            font-size: 28px;
            font-weight: 800;
            color: var(--text-primary);
            margin: 0;
            letter-spacing: -0.5px;
        }
        
        .navbar-left .breadcrumb {
            font-size: 13px;
            color: var(--text-secondary);
            margin: 5px 0 0;
        }
        
        .navbar-right {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        
        .back-btn {
            padding: 10px 20px;
            background: var(--light-bg);
            border: 2px solid var(--border-color);
            border-radius: 10px;
            color: var(--text-primary);
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .back-btn:hover {
            background: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
        }
        
        /* ============ FORM CONTENT ============ */
        .form-content {
            padding: 30px;
        }
        
        .form-container {
            background: white;
            border-radius: 16px;
            padding: 35px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.04);
            border: 1px solid var(--border-color);
            max-width: 1000px;
            margin: 0 auto;
        }
        
        .form-header {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid var(--border-color);
        }
        
        .form-header h2 {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 8px;
            letter-spacing: -0.5px;
        }
        
        .form-header p {
            color: var(--text-secondary);
            font-size: 14px;
        }
        
        .product-form {
            display: flex;
            flex-direction: column;
            gap: 25px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 25px;
        }
        
        .form-group {
            display: flex;
            flex-direction: column;
        }
        
        .form-group label {
            margin-bottom: 10px;
            font-weight: 700;
            color: var(--text-primary);
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .form-group label i {
            color: var(--primary-color);
            font-size: 16px;
        }
        
        .form-group .required {
            color: var(--danger-color);
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            padding: 12px 15px;
            border: 2px solid var(--border-color);
            border-radius: 10px;
            font-size: 14px;
            font-family: 'Outfit', sans-serif;
            transition: all 0.3s ease;
            background: white;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 120px;
        }
        
        .form-group small {
            margin-top: 6px;
            color: var(--text-secondary);
            font-size: 13px;
        }
        
        /* Current Image Preview */
        .current-image {
            margin-top: 15px;
            padding: 20px;
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.05) 0%, rgba(139, 92, 246, 0.05) 100%);
            border-radius: 12px;
            border: 2px dashed var(--border-color);
            text-align: center;
        }
        
        .current-image img {
            max-width: 250px;
            max-height: 250px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            border: 3px solid white;
        }
        
        .current-image p {
            margin-top: 12px;
            color: var(--text-secondary);
            font-size: 13px;
            font-weight: 600;
        }
        
        /* File Upload */
        .file-upload-wrapper {
            position: relative;
        }
        
        .file-upload-wrapper input[type="file"] {
            opacity: 0;
            position: absolute;
            z-index: -1;
        }
        
        .file-upload-label {
            display: block;
            padding: 30px;
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.05) 0%, rgba(139, 92, 246, 0.05) 100%);
            border: 2px dashed var(--border-color);
            border-radius: 12px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .file-upload-label:hover {
            border-color: var(--primary-color);
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%);
        }
        
        .file-upload-label i {
            font-size: 48px;
            color: var(--primary-color);
            margin-bottom: 15px;
            display: block;
        }
        
        .file-upload-text strong {
            display: block;
            color: var(--text-primary);
            font-size: 16px;
            margin-bottom: 5px;
        }
        
        .file-upload-text span {
            color: var(--text-secondary);
            font-size: 13px;
        }
        
        /* Form Actions */
        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 20px;
            padding-top: 25px;
            border-top: 2px solid var(--border-color);
        }
        
        .btn {
            padding: 14px 28px;
            border: none;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            transition: all 0.3s ease;
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            font-family: 'Outfit', sans-serif;
        }
        
        .btn i {
            font-size: 18px;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4);
        }
        
        .btn-secondary {
            background: var(--light-bg);
            color: var(--text-primary);
            border: 2px solid var(--border-color);
        }
        
        .btn-secondary:hover {
            background: var(--text-secondary);
            color: white;
            border-color: var(--text-secondary);
        }
        
        .btn-danger {
            background: var(--danger-color);
            color: white;
            box-shadow: 0 4px 15px rgba(239, 68, 68, 0.3);
        }
        
        .btn-danger:hover {
            background: #dc2626;
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(239, 68, 68, 0.4);
        }
        
        /* Info Card */
        .info-card {
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.05) 0%, rgba(139, 92, 246, 0.05) 100%);
            border-left: 4px solid var(--primary-color);
            padding: 20px;
            border-radius: 12px;
            margin-bottom: 25px;
        }
        
        .info-card i {
            color: var(--primary-color);
            font-size: 20px;
            margin-right: 12px;
        }
        
        .info-card p {
            margin: 0;
            color: var(--text-primary);
            font-size: 14px;
            font-weight: 500;
        }
        
        /* Alert Messages */
        .alert {
            padding: 15px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-weight: 600;
        }
        
        .alert-danger {
            background: rgba(239, 68, 68, 0.1);
            border-left: 4px solid var(--danger-color);
            color: var(--danger-color);
        }
        
        .alert i {
            font-size: 20px;
        }
        
        /* Animations */
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .form-container {
            animation: fadeInUp 0.6s ease forwards;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .sidebar {
                width: 70px;
            }
            
            .sidebar-header,
            .menu-section-title,
            .sidebar-menu a span,
            .sidebar-menu .badge {
                display: none;
            }
            
            .sidebar-menu a {
                justify-content: center;
                padding: 14px 10px;
            }
            
            .sidebar-menu a i {
                margin-right: 0;
            }
            
            .main-content {
                margin-left: 70px;
            }
            
            .navbar-left h1 {
                font-size: 20px;
            }
            
            .form-row {
                grid-template-columns: 1fr;
            }
            
            .form-actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>

    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <a href="sellerdashboard.jsp" class="sidebar-logo">
                <i class="fas fa-store"></i>
                <div>
                    MarketHub
                    <div class="seller-badge">SELLER</div>
                </div>
            </a>
        </div>
        
        <nav class="sidebar-menu">
            <div class="menu-section-title">Main Menu</div>
            <a href="sellerdashboard.jsp">
                <i class="fas fa-th-large"></i>
                <span>Dashboard</span>
            </a>
            <a href="#">
                <i class="fas fa-shopping-cart"></i>
                <span>My Orders</span>
                <span class="badge bg-danger">8</span>
            </a>
            <a href="viewproduct.jsp" class="active">
                <i class="fas fa-box"></i>
                <span>My Products</span>
            </a>
            <a href="addprod.jsp">
                <i class="fas fa-plus-circle"></i>
                <span>Add Product</span>
            </a>
            <a href="#">
                <i class="fas fa-warehouse"></i>
                <span>Inventory</span>
            </a>
            
            <div class="menu-section-title">Sales & Revenue</div>
            <a href="#">
                <i class="fas fa-chart-line"></i>
                <span>Sales Report</span>
            </a>
            <a href="#">
                <i class="fas fa-dollar-sign"></i>
                <span>Earnings</span>
            </a>
            
            <div class="menu-section-title">Settings</div>
            <a href="#">
                <i class="fas fa-user-circle"></i>
                <span>My Profile</span>
            </a>
            <a href="ulogout">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </nav>
    </aside>

    <!-- Main Content -->
    <div class="main-content">
        <!-- Top Navbar -->
        <div class="top-navbar">
            <div class="navbar-left">
                <h1>Edit Product</h1>
                <div class="breadcrumb">
                    <i class="fas fa-home"></i> Home / Products / Edit Product
                </div>
            </div>
            
            <div class="navbar-right">
                <a href="viewproduct.jsp" class="back-btn">
                    <i class="fas fa-arrow-left"></i>
                    Back to Products
                </a>
            </div>
        </div>

        <!-- Form Content -->
        <div class="form-content">
            <%
                // Get the product ID from parameter
                String productId = request.getParameter("id");
                String oname = request.getParameter("oname");
                
                // Validate that we have either ID or name
                if ((productId == null || productId.trim().isEmpty()) && 
                    (oname == null || oname.trim().isEmpty())) {
            %>
                <div class="form-container">
                    <div class="alert alert-danger">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p><strong>Error:</strong> No product specified. Please select a product to edit.</p>
                    </div>
                    <a href="viewproduct.jsp" class="btn btn-primary">
                        <i class="fas fa-arrow-left"></i>
                        Back to Products
                    </a>
                </div>
            <%
                } else {
                    String name = null; 
                    String quantity = null;
                    String rate = null;
                    String category = null;
                    String dis = null;
                    String image = null;
                    String description = null;
                    String id = null;
                    boolean productFound = false;
                    
                    Connection con = null;
                    Statement stat = null;
                    ResultSet res = null;
                    
                    try {
                        // Load MySQL Driver
                        Class.forName("com.mysql.jdbc.Driver");
                        
                        // Get database connection
                        con = new dbconfig().getConnection();
                        stat = con.createStatement();
                        
                        // Build query based on what parameter we have
                        String query = "";
                        if (productId != null && !productId.trim().isEmpty()) {
                            query = "SELECT * FROM `adprod` WHERE `id`='" + productId + "'";
                        } else {
                            query = "SELECT * FROM `adprod` WHERE `pname`='" + oname + "'";
                        }
                        
                        res = stat.executeQuery(query);
                        
                        if(res.next()) {
                            productFound = true;
                            id = res.getString("id");
                            name = res.getString("pname");
                            quantity = res.getString("quantity");
                            rate = res.getString("rate");
                            category = res.getString("category");
                            dis = res.getString("proddis");
                            image = res.getString("pimage");
                            description = res.getString("description");
                        }
                        
                        if (!productFound) {
            %>
                            <div class="form-container">
                                <div class="alert alert-danger">
                                    <i class="fas fa-exclamation-triangle"></i>
                                    <p><strong>Error:</strong> Product not found in database.</p>
                                </div>
                                <a href="viewproduct.jsp" class="btn btn-primary">
                                    <i class="fas fa-arrow-left"></i>
                                    Back to Products
                                </a>
                            </div>
            <%
                        } else {
            %>
            
            <div class="form-container">
                <div class="form-header">
                    <h2><i class="fas fa-edit"></i> Edit Product Details</h2>
                    <p>Update the information for: <strong><%= name %></strong></p>
                </div>
                
                <div class="info-card">
                    <i class="fas fa-info-circle"></i>
                    <p>Make sure all required fields are filled out correctly. Changes will be reflected immediately after saving.</p>
                </div>
                
                <form action="edit" method="POST" class="product-form" enctype="multipart/form-data">
                    <!-- Hidden field to pass product ID -->
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="oname" value="<%= name %>">
                    
                    <div class="form-row">   
                        <div class="form-group">
                            <label for="pname">
                                <i class="fas fa-tag"></i>
                                Product Name <span class="required">*</span>
                            </label>
                            <input type="text" id="pname" name="pname" value="<%= name != null ? name : "" %>" placeholder="Enter product name" required>
                        </div>
                        <div class="form-group">
                            <label for="quantity">
                                <i class="fas fa-boxes"></i>
                                Quantity <span class="required">*</span>
                            </label>
                            <input type="number" id="quantity" name="quantity" value="<%= quantity != null ? quantity : "" %>" placeholder="Enter quantity" min="0" required>
                            <small>Available units in stock</small>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="rate">
                                <i class="fas fa-rupee-sign"></i>
                                Rate (Price per Unit) <span class="required">*</span>
                            </label>
                            <input type="number" id="rate" name="rate" value="<%= rate != null ? rate : "" %>" placeholder="Enter price" min="0" step="0.01" required>
                            <small>Price in INR (₹)</small>
                        </div>
                        <div class="form-group">
                            <label for="category">
                                <i class="fas fa-list"></i>
                                Category <span class="required">*</span>
                            </label>
                            <select id="category" name="category" required>
                                <option value="">Select Category</option>
                                <option value="electronics" <%= "electronics".equals(category) ? "selected" : "" %>>Electronics</option>
                                <option value="clothing" <%= "clothing".equals(category) ? "selected" : "" %>>Clothing & Fashion</option>
                                <option value="home" <%= "home".equals(category) ? "selected" : "" %>>Home & Kitchen</option>
                                <option value="books" <%= "books".equals(category) ? "selected" : "" %>>Books & Media</option>
                                <option value="sports" <%= "sports".equals(category) ? "selected" : "" %>>Sports & Fitness</option>
                                <option value="toys" <%= "toys".equals(category) ? "selected" : "" %>>Toys & Games</option>
                                <option value="beauty" <%= "beauty".equals(category) ? "selected" : "" %>>Beauty & Personal Care</option>
                                <option value="other" <%= "other".equals(category) ? "selected" : "" %>>Other</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="proddis">
                            <i class="fas fa-align-left"></i>
                            Product Description <span class="required">*</span>
                        </label>
                        <textarea id="proddis" name="proddis" placeholder="Describe your product in detail..." required><%= dis != null ? dis : "" %></textarea>
                        <small>Include features, specifications, and benefits (minimum 50 characters)</small>
                    </div>
                    
                    <div class="form-group">
                        <label for="description">
                            <i class="fas fa-file-alt"></i>
                            Additional Description
                        </label>
                        <textarea id="description" name="description" placeholder="Any additional details..." rows="3"><%= description != null && !description.equals("null") ? description : "" %></textarea>
                        <small>Optional field for extra product information</small>
                    </div>
                    
                    <div class="form-group">
                        <label>
                            <i class="fas fa-image"></i>
                            Product Image
                        </label>
                        
                        <% if (image != null && !image.isEmpty() && !image.equals("null")) { %>
                        <div class="current-image">
                            <img src="<%= image %>" alt="Current Product Image" onerror="this.src='https://via.placeholder.com/250x250?text=No+Image'">
                            <p><i class="fas fa-check-circle"></i> Current Product Image</p>
                        </div>
                        <% } %>
                        
                        <div class="file-upload-wrapper">
                            <input type="file" id="productimage" name="productimage" accept="image/*">
                            <label for="productimage" class="file-upload-label">
                                <i class="fas fa-cloud-upload-alt"></i>
                                <div class="file-upload-text">
                                    <strong>Click to upload a new image</strong>
                                    <span>or drag and drop (PNG, JPG, JPEG - Max 5MB)</span>
                                </div>
                            </label>
                        </div>
                        <small>Leave empty to keep the current image</small>
                    </div>
                    
                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save"></i>
                            Update Product
                        </button>
                        <a href="viewproduct.jsp" class="btn btn-secondary">
                            <i class="fas fa-times"></i>
                            Cancel
                        </a>
                    </div>
                </form>
            </div>
            
            <% 
                        } // end if productFound
                    } catch(ClassNotFoundException e) {
                        out.println("<div class='form-container'>");
                        out.println("<div class='alert alert-danger'>");
                        out.println("<i class='fas fa-exclamation-triangle'></i>");
                        out.println("<p><strong>Database Driver Error:</strong> MySQL JDBC Driver not found. Please add mysql-connector-java to your project libraries.</p>");
                        out.println("</div>");
                        out.println("</div>");
                        e.printStackTrace();
                    } catch(Exception e) {
                        out.println("<div class='form-container'>");
                        out.println("<div class='alert alert-danger'>");
                        out.println("<i class='fas fa-exclamation-triangle'></i>");
                        out.println("<p><strong>Error:</strong> " + e.getMessage() + "</p>");
                        out.println("</div>");
                        out.println("</div>");
                        e.printStackTrace();
                    } finally {
                        // Close database resources
                        try {
                            if (res != null) res.close();
                            if (stat != null) stat.close();
                            if (con != null) con.close();
                        } catch(Exception e) {
                            e.printStackTrace();
                        }
                    }
                } // end else (has productId or oname)
            %>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        // File upload preview
        document.getElementById('productimage').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                const label = document.querySelector('.file-upload-label .file-upload-text strong');
                label.textContent = 'Selected: ' + file.name;
            }
        });
        
        // Form validation
        document.querySelector('.product-form').addEventListener('submit', function(e) {
            const description = document.getElementById('proddis').value;
            if (description.length < 50) {
                e.preventDefault();
                alert('Product description must be at least 50 characters long.');
                document.getElementById('proddis').focus();
                return false;
            }
        });
    </script>
</body>
</html>
