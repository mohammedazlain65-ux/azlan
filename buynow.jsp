<%-- 
    Document   : buynow
    Created on : 12 Feb, 2026
    Author     : moham
    Description: Buy Now page - Direct checkout for a single product
--%>

<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="java.sql.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.Date"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    String password = null;
    String customerEmail = null;

    try {
        customerEmail = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(customerEmail == null || password == null || customerEmail.equals("") || password.equals("")) {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        }
        username = customerEmail;
    } catch(Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); 
    }

    // Get productId from request parameter
    String productIdParam = request.getParameter("productId");
    int productId = 0;

    if(productIdParam == null || productIdParam.isEmpty()) {
        response.sendRedirect("buyerdashboard.jsp");
        return;
    }

    try {
        productId = Integer.parseInt(productIdParam);
    } catch(NumberFormatException e) {
        response.sendRedirect("buyerdashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Buy Now - MarketHub</title>

    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --primary-color: #6366f1;
            --secondary-color: #8b5cf6;
            --dark-bg: #1e293b;
            --light-bg: #f8fafc;
            --success-color: #10b981;
            --danger-color: #ef4444;
            --warning-color: #f59e0b;
            --info-color: #06b6d4;
            --card-bg: #ffffff;
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
            padding-bottom: 50px;
        }

        .top-header {
            background: var(--dark-bg);
            color: white;
            padding: 12px 0;
            font-size: 13px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .main-header {
            background: white;
            padding: 20px 0;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 40px;
        }

        .logo {
            font-size: 32px;
            font-weight: 800;
            color: var(--text-primary);
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo i {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        /* ============ PROGRESS STEPS ============ */
        .checkout-progress {
            background: white;
            padding: 25px;
            border-radius: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }

        .progress-steps {
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: relative;
        }

        .progress-line {
            position: absolute;
            top: 25px;
            left: 10%;
            right: 10%;
            height: 3px;
            background: var(--border-color);
            z-index: 0;
        }

        .progress-line-active {
            position: absolute;
            top: 25px;
            left: 10%;
            width: 40%;
            height: 3px;
            background: linear-gradient(90deg, var(--success-color), var(--primary-color));
            z-index: 1;
        }

        .progress-step {
            text-align: center;
            position: relative;
            z-index: 2;
            flex: 1;
        }

        .progress-icon {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            background: white;
            border: 3px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 10px;
            font-size: 20px;
            color: var(--text-secondary);
            transition: all 0.3s ease;
        }

        .progress-step.active .progress-icon {
            background: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.4);
        }

        .progress-step.completed .progress-icon {
            background: var(--success-color);
            border-color: var(--success-color);
            color: white;
            box-shadow: 0 4px 15px rgba(16, 185, 129, 0.4);
        }

        .progress-label {
            font-weight: 600;
            color: var(--text-secondary);
            font-size: 14px;
        }

        .progress-step.active .progress-label {
            color: var(--primary-color);
        }

        .progress-step.completed .progress-label {
            color: var(--success-color);
        }

        /* ============ PAGE TITLE ============ */
        .page-title {
            background: white;
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }

        .page-title h1 {
            font-size: 36px;
            font-weight: 800;
            color: var(--text-primary);
            margin: 0;
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .page-title h1 i {
            color: var(--success-color);
        }

        .page-title .subtitle {
            margin-top: 8px;
            color: var(--text-secondary);
            font-weight: 600;
            font-size: 15px;
        }

        /* ============ SECTION CARDS ============ */
        .section-card {
            background: white;
            border-radius: 20px;
            padding: 30px;
            margin-bottom: 25px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }

        .section-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
        }

        .section-header i {
            font-size: 24px;
            color: var(--primary-color);
        }

        .section-header h2 {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-primary);
            margin: 0;
        }

        /* ============ CUSTOMER INFO ============ */
        .customer-info {
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.05) 0%, rgba(139, 92, 246, 0.05) 100%);
            padding: 20px;
            border-radius: 16px;
            border: 2px solid var(--border-color);
        }

        .info-row {
            display: flex;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--border-color);
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .info-label {
            font-weight: 700;
            color: var(--text-secondary);
            min-width: 120px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .info-label i {
            color: var(--primary-color);
        }

        .info-value {
            font-weight: 600;
            color: var(--text-primary);
            font-size: 16px;
        }

        /* ============ PRODUCT ITEM ============ */
        .product-item {
            display: flex;
            align-items: center;
            padding: 20px;
            background: var(--light-bg);
            border-radius: 16px;
            margin-bottom: 15px;
            border: 2px solid var(--border-color);
            transition: all 0.3s ease;
        }

        .product-item:hover {
            border-color: var(--primary-color);
            transform: translateX(5px);
        }

        .product-image {
            width: 100px;
            height: 100px;
            border-radius: 14px;
            object-fit: cover;
            border: 2px solid var(--border-color);
            margin-right: 20px;
            flex-shrink: 0;
        }

        .product-details {
            flex: 1;
        }

        .product-name {
            font-size: 20px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 6px;
        }

        .product-category {
            color: var(--text-secondary);
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }

        .product-meta {
            display: flex;
            gap: 20px;
            align-items: center;
            flex-wrap: wrap;
        }

        .meta-item {
            font-size: 14px;
            font-weight: 600;
            color: var(--text-secondary);
        }

        .meta-item span {
            color: var(--primary-color);
            font-weight: 800;
        }

        .product-total {
            text-align: right;
        }

        .product-price {
            font-size: 28px;
            font-weight: 800;
            color: var(--primary-color);
        }

        .product-price-label {
            font-size: 12px;
            color: var(--text-secondary);
            font-weight: 600;
            margin-top: 4px;
        }

        /* Quantity Selector */
        .qty-selector {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-top: 10px;
        }

        .qty-selector label {
            font-weight: 700;
            color: var(--text-secondary);
            font-size: 14px;
        }

        .qty-btn {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            border: 2px solid var(--primary-color);
            background: white;
            color: var(--primary-color);
            font-size: 18px;
            font-weight: 800;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
            line-height: 1;
        }

        .qty-btn:hover {
            background: var(--primary-color);
            color: white;
        }

        .qty-display {
            width: 45px;
            text-align: center;
            font-size: 18px;
            font-weight: 800;
            color: var(--text-primary);
            border: 2px solid var(--border-color);
            border-radius: 8px;
            padding: 4px;
        }

        /* ============ FORM STYLES ============ */
        .shipping-form {
            margin-top: 5px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-label {
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .form-label i {
            color: var(--primary-color);
            font-size: 14px;
        }

        .form-label .required {
            color: var(--danger-color);
        }

        .form-control {
            border: 2px solid var(--border-color);
            border-radius: 12px;
            padding: 12px 15px;
            font-weight: 600;
            transition: all 0.3s ease;
            font-family: 'Outfit', sans-serif;
            font-size: 15px;
        }

        .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
            outline: none;
        }

        /* ============ ORDER SUMMARY ============ */
        .order-summary {
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            position: sticky;
            top: 20px;
        }

        .order-summary h3 {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .order-summary h3 i {
            color: var(--primary-color);
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 15px;
            font-weight: 600;
            color: var(--text-primary);
            font-size: 15px;
        }

        .summary-row.total {
            font-size: 26px;
            font-weight: 800;
            color: var(--primary-color);
            padding-top: 20px;
            border-top: 2px solid var(--border-color);
            margin-top: 20px;
        }

        /* ============ PAYMENT METHODS ============ */
        .payment-methods {
            display: flex;
            gap: 10px;
            margin-top: 10px;
            flex-wrap: wrap;
        }

        .payment-method {
            flex: 1;
            min-width: 80px;
            padding: 12px;
            border: 2px solid var(--border-color);
            border-radius: 12px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
            background: white;
        }

        .payment-method:hover {
            border-color: var(--primary-color);
            transform: translateY(-2px);
        }

        .payment-method.active {
            border-color: var(--primary-color);
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%);
        }

        .payment-method i {
            font-size: 24px;
            color: var(--primary-color);
            margin-bottom: 5px;
            display: block;
        }

        .payment-method span {
            font-size: 11px;
            font-weight: 700;
            color: var(--text-primary);
        }

        /* ============ BUTTONS ============ */
        .btn-place-order {
            width: 100%;
            background: linear-gradient(135deg, var(--success-color) 0%, #059669 100%);
            color: white;
            border: none;
            padding: 18px;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 800;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 20px;
            font-family: 'Outfit', sans-serif;
        }

        .btn-place-order:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(16, 185, 129, 0.4);
        }

        .btn-back {
            width: 100%;
            background: white;
            color: var(--primary-color);
            border: 2px solid var(--primary-color);
            padding: 14px;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 12px;
            text-decoration: none;
            display: block;
            text-align: center;
        }

        .btn-back:hover {
            background: var(--primary-color);
            color: white;
            transform: translateY(-2px);
        }

        /* ============ SECURITY BADGE ============ */
        .security-badge {
            margin-top: 25px;
            padding: 15px;
            background: linear-gradient(135deg, rgba(99, 102, 241, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%);
            border-radius: 12px;
            text-align: center;
        }

        .security-badge i {
            color: var(--primary-color);
            font-size: 24px;
        }

        .security-badge p {
            margin: 10px 0 0 0;
            font-weight: 600;
            color: var(--text-primary);
            font-size: 13px;
        }

        /* Buy Now highlight banner */
        .buynow-banner {
            background: linear-gradient(135deg, var(--success-color) 0%, #059669 100%);
            color: white;
            padding: 14px 20px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 25px;
            font-weight: 700;
            font-size: 15px;
        }

        .buynow-banner i {
            font-size: 22px;
        }

        /* Error box */
        .error-box {
            background: linear-gradient(135deg, rgba(239,68,68,0.12) 0%, rgba(220,38,38,0.12) 100%);
            border: 2px solid var(--danger-color);
            border-radius: 16px;
            padding: 30px;
            text-align: center;
            color: #dc2626;
            font-weight: 700;
            font-size: 18px;
        }
    </style>
</head>
<body>

    <!-- Top Header -->
    <div class="top-header">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <span><i class="fas fa-phone"></i> +91 1800-123-4567</span>
                    <span class="ms-3"><i class="fas fa-envelope"></i> support@markethub.com</span>
                </div>
                <div class="col-md-6 text-end">
                    <span><i class="fas fa-map-marker-alt"></i> Track Order</span>
                    <span class="ms-3"><i class="fas fa-headset"></i> Customer Support</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Header -->
    <header class="main-header">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <a href="buyerdashboard.jsp" class="logo">
                        <i class="fas fa-shopping-bag"></i>
                        <span>MarketHub</span>
                    </a>
                </div>
                <div class="col-md-6 text-end">
                    <a href="buyerdashboard.jsp" class="btn btn-outline-secondary" style="border-radius: 12px; font-weight: 700; padding: 10px 24px; margin-right: 10px;">
                        <i class="fas fa-arrow-left"></i> Back to Shop
                    </a>
                    <span style="font-weight: 700; color: var(--text-secondary);">
                        <i class="fas fa-user-circle"></i> <%= customerEmail %>
                    </span>
                </div>
            </div>
        </div>
    </header>

    <div class="container">

        <!-- Progress Steps -->
        <div class="checkout-progress">
            <div class="progress-steps">
                <div class="progress-line"></div>
                <div class="progress-line-active"></div>

                <div class="progress-step completed">
                    <div class="progress-icon">
                        <i class="fas fa-shopping-bag"></i>
                    </div>
                    <div class="progress-label">Product Selected</div>
                </div>

                <div class="progress-step active">
                    <div class="progress-icon">
                        <i class="fas fa-bolt"></i>
                    </div>
                    <div class="progress-label">Buy Now</div>
                </div>

                <div class="progress-step">
                    <div class="progress-icon">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div class="progress-label">Order Complete</div>
                </div>
            </div>
        </div>

        <!-- Page Title -->
        <div class="page-title">
            <h1><i class="fas fa-bolt"></i> Buy Now</h1>
            <div class="subtitle">Complete your purchase quickly and securely</div>
        </div>

        <%
        String dbURL = "jdbc:mysql://localhost:3306/multi_vendor";
        String dbUser = "root";
        String dbPassword = "";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        double price = 0;
        double subtotal = 0;
        String productName = "";
        String category = "";
        String pimage = "";
        String description = "";
        String quantityInStock = "";
        boolean productFound = false;

        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);

            String query = "SELECT * FROM adprod WHERE id = ?";
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, productId);
            rs = pstmt.executeQuery();

            if(rs.next()) {
                productFound = true;
                productName = rs.getString("pname");
                category = rs.getString("category");
                String rateStr = rs.getString("rate");
                pimage = rs.getString("pimage");
                description = rs.getString("description");
                quantityInStock = rs.getString("quantity");

                try {
                    price = Double.parseDouble(rateStr);
                } catch(NumberFormatException e) {
                    price = 0;
                }
                subtotal = price; // default qty = 1
            }

            String imageUrl = (pimage != null && !pimage.isEmpty() && !pimage.equals("null"))
                ? pimage
                : "https://via.placeholder.com/100?text=" + productName.replace(" ", "+");

            if(productFound) {
        %>

        <!-- Buy Now Banner -->
        <div class="buynow-banner">
            <i class="fas fa-bolt"></i>
            <span>You're one step away! Fill in your details and place your order instantly.</span>
        </div>

        <div class="row">
            <!-- Left Column -->
            <div class="col-lg-8">

                <!-- Customer Information -->
                <div class="section-card">
                    <div class="section-header">
                        <i class="fas fa-user-circle"></i>
                        <h2>Customer Information</h2>
                    </div>
                    <div class="customer-info">
                        <div class="info-row">
                            <div class="info-label">
                                <i class="fas fa-envelope"></i> Email:
                            </div>
                            <div class="info-value"><%= customerEmail %></div>
                        </div>
                        <div class="info-row">
                            <div class="info-label">
                                <i class="fas fa-calendar"></i> Order Date:
                            </div>
                            <div class="info-value"><%= new SimpleDateFormat("MMM dd, yyyy hh:mm a").format(new Date()) %></div>
                        </div>
                        <div class="info-row">
                            <div class="info-label">
                                <i class="fas fa-hashtag"></i> Order ID:
                            </div>
                            <div class="info-value">ORD-<%= System.currentTimeMillis() %></div>
                        </div>
                    </div>
                </div>

                <!-- Shipping Address -->
                <div class="section-card">
                    <div class="section-header">
                        <i class="fas fa-shipping-fast"></i>
                        <h2>Shipping Address</h2>
                    </div>
                    <form id="buyNowForm" action="OrderServlet?source=buynow" method="POST">
                        <input type="hidden" name="customerEmail" value="<%= customerEmail %>">
                        <input type="hidden" name="productId" value="<%= productId %>">
                        <input type="hidden" name="productName" value="<%= productName.replace("\"", "&quot;") %>">
                        <input type="hidden" name="productPrice" value="<%= price %>">
                        <input type="hidden" id="hiddenQty" name="quantity" value="1">

                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="form-label">
                                        <i class="fas fa-user"></i>
                                        Full Name <span class="required">*</span>
                                    </label>
                                    <input type="text" class="form-control" name="fullName" required placeholder="Enter your full name">
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label class="form-label">
                                        <i class="fas fa-phone"></i>
                                        Phone Number <span class="required">*</span>
                                    </label>
                                    <input type="tel" class="form-control" name="phone" required placeholder="+91 XXXXX XXXXX">
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">
                                <i class="fas fa-map-marker-alt"></i>
                                Address Line 1 <span class="required">*</span>
                            </label>
                            <input type="text" class="form-control" name="address1" required placeholder="House/Flat No., Building Name">
                        </div>

                        <div class="form-group">
                            <label class="form-label">
                                <i class="fas fa-map-marker-alt"></i>
                                Address Line 2
                            </label>
                            <input type="text" class="form-control" name="address2" placeholder="Street, Area, Locality">
                        </div>

                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label class="form-label">
                                        <i class="fas fa-city"></i>
                                        City <span class="required">*</span>
                                    </label>
                                    <input type="text" class="form-control" name="city" required placeholder="City">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label class="form-label">
                                        <i class="fas fa-map"></i>
                                        State <span class="required">*</span>
                                    </label>
                                    <input type="text" class="form-control" name="state" required placeholder="State">
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label class="form-label">
                                        <i class="fas fa-mail-bulk"></i>
                                        PIN Code <span class="required">*</span>
                                    </label>
                                    <input type="text" class="form-control" name="pincode" required placeholder="XXXXXX" maxlength="6">
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="form-label">
                                <i class="fas fa-sticky-note"></i>
                                Order Notes (Optional)
                            </label>
                            <textarea class="form-control" name="orderNotes" rows="3" placeholder="Any special instructions for delivery"></textarea>
                        </div>
                    </form>
                </div>

                <!-- Product Details -->
                <div class="section-card">
                    <div class="section-header">
                        <i class="fas fa-box-open"></i>
                        <h2>Product Details</h2>
                    </div>

                    <div class="product-item">
                        <img src="<%= imageUrl %>"
                             alt="<%= productName %>"
                             class="product-image"
                             onerror="this.src='https://via.placeholder.com/100?text=Product'">
                        <div class="product-details">
                            <div class="product-category">
                                <%= category != null && !category.isEmpty() ? category.toUpperCase() : "GENERAL" %>
                            </div>
                            <div class="product-name"><%= productName %></div>
                            <div class="product-meta">
                                <div class="meta-item">
                                    <i class="fas fa-tag"></i> Unit Price: <span>₹<%= String.format("%.2f", price) %></span>
                                </div>
                                <% if(quantityInStock != null && !quantityInStock.isEmpty()) { %>
                                <div class="meta-item">
                                    <i class="fas fa-warehouse"></i> In Stock: <span><%= quantityInStock %> units</span>
                                </div>
                                <% } %>
                            </div>
                            <!-- Quantity Selector -->
                            <div class="qty-selector">
                                <label>Quantity:</label>
                                <button type="button" class="qty-btn" onclick="changeQty(-1)">−</button>
                                <input type="text" id="qtyDisplay" class="qty-display" value="1" readonly>
                                <button type="button" class="qty-btn" onclick="changeQty(1)">+</button>
                            </div>
                        </div>
                        <div class="product-total">
                            <div class="product-price" id="itemTotalDisplay">₹<%= String.format("%.2f", price) %></div>
                            <div class="product-price-label">Item Total</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right Column - Order Summary -->
            <div class="col-lg-4">
                <div class="order-summary">
                    <h3><i class="fas fa-file-invoice-dollar"></i> Order Summary</h3>

                    <div class="summary-row">
                        <span>Product:</span>
                        <span style="max-width: 160px; text-align: right; font-size: 13px;"><%= productName %></span>
                    </div>

                    <div class="summary-row">
                        <span>Unit Price:</span>
                        <span>₹<%= String.format("%.2f", price) %></span>
                    </div>

                    <div class="summary-row">
                        <span>Quantity:</span>
                        <span id="summaryQty">1</span>
                    </div>

                    <div class="summary-row">
                        <span>Subtotal:</span>
                        <span id="summarySubtotal">₹<%= String.format("%.2f", price) %></span>
                    </div>

                    <div class="summary-row">
                        <span>Shipping:</span>
                        <span style="color: var(--success-color); font-weight: 800;">FREE</span>
                    </div>

                    <div class="summary-row">
                        <span>Tax (18%):</span>
                        <span id="summaryTax">₹<%= String.format("%.2f", price * 0.18) %></span>
                    </div>

                    <div class="summary-row total">
                        <span>Total:</span>
                        <span id="summaryTotal">₹<%= String.format("%.2f", price * 1.18) %></span>
                    </div>

                    <!-- Payment Methods -->
                    <div style="margin-top: 25px; margin-bottom: 20px;">
                        <label class="form-label">
                            <i class="fas fa-credit-card"></i>
                            Payment Method <span class="required" style="color:var(--danger-color);">*</span>
                        </label>
                        <div class="payment-methods">
                            <div class="payment-method active" onclick="selectPayment('cod', this)">
                                <i class="fas fa-money-bill-wave"></i>
                                <span>Cash on Delivery</span>
                            </div>
                            <div class="payment-method" onclick="selectPayment('card', this)">
                                <i class="fas fa-credit-card"></i>
                                <span>Card</span>
                            </div>
                            <div class="payment-method" onclick="selectPayment('upi', this)">
                                <i class="fas fa-mobile-alt"></i>
                                <span>UPI</span>
                            </div>
                        </div>
                        <input type="hidden" name="paymentMethod" id="paymentMethod" value="cod" form="buyNowForm">
                    </div>

                    <button type="submit" class="btn-place-order" form="buyNowForm">
                        <i class="fas fa-bolt"></i> Place Order Now
                    </button>

                    <a href="buyerdashboard.jsp" class="btn-back">
                        <i class="fas fa-arrow-left"></i> Continue Shopping
                    </a>

                    <div class="security-badge">
                        <i class="fas fa-shield-alt"></i>
                        <p>Safe &amp; Secure Checkout<br>
                        <span style="font-size: 11px; color: var(--text-secondary);">Your data is protected with SSL encryption</span></p>
                    </div>
                </div>
            </div>
        </div>

        <%
            } else {
        %>
        <div class="error-box">
            <i class="fas fa-exclamation-triangle" style="font-size: 48px; margin-bottom: 15px; display: block;"></i>
            Product not found. Please go back and try again.
            <br><br>
            <a href="buyerdashboard.jsp" class="btn-back" style="display: inline-block; width: auto; padding: 12px 30px;">
                <i class="fas fa-arrow-left"></i> Back to Shop
            </a>
        </div>
        <%
            }
        } catch(Exception e) {
            out.println("<div class='alert alert-danger' style='border-radius:16px; padding:20px;'>");
            out.println("<strong>Error:</strong> " + e.getMessage());
            out.println("</div>");
            e.printStackTrace();
        } finally {
            try {
                if(rs != null) rs.close();
                if(pstmt != null) pstmt.close();
                if(conn != null) conn.close();
            } catch(SQLException e) {
                e.printStackTrace();
            }
        }
        %>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        const unitPrice = <%= price %>;
        let currentQty = 1;

        function changeQty(delta) {
            currentQty += delta;
            if(currentQty < 1) currentQty = 1;
            if(currentQty > 99) currentQty = 99;

            document.getElementById('qtyDisplay').value = currentQty;
            document.getElementById('hiddenQty').value = currentQty;

            const itemTotal = unitPrice * currentQty;
            const tax = itemTotal * 0.18;
            const grandTotal = itemTotal * 1.18;

            document.getElementById('itemTotalDisplay').textContent = '₹' + itemTotal.toFixed(2);
            document.getElementById('summaryQty').textContent = currentQty;
            document.getElementById('summarySubtotal').textContent = '₹' + itemTotal.toFixed(2);
            document.getElementById('summaryTax').textContent = '₹' + tax.toFixed(2);
            document.getElementById('summaryTotal').textContent = '₹' + grandTotal.toFixed(2);
        }

        function selectPayment(method, element) {
            document.querySelectorAll('.payment-method').forEach(pm => {
                pm.classList.remove('active');
            });
            element.classList.add('active');
            document.getElementById('paymentMethod').value = method;
        }

        // Form Validation
        document.getElementById('buyNowForm').addEventListener('submit', function(e) {
            const pincode = document.querySelector('input[name="pincode"]').value;
            if(pincode.length !== 6 || isNaN(pincode)) {
                e.preventDefault();
                alert('Please enter a valid 6-digit PIN code');
                return false;
            }

            const phone = document.querySelector('input[name="phone"]').value.replace(/\s/g, '');
            if(phone.length < 10) {
                e.preventDefault();
                alert('Please enter a valid phone number (minimum 10 digits)');
                return false;
            }

            return true;
        });
    </script>
</body>
</html>
