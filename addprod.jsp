<%-- 
    Document   : addprod
    Created on : 2 Feb, 2026, 4:07:10 PM
    Author     : moham
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    HttpSession hs = request.getSession();
    String loggedInEmail = null;
    String password = null;
    try {
        loggedInEmail = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(loggedInEmail == null || password == null || loggedInEmail.equals("") || password.equals("")) {
            response.sendRedirect("ulogout");
            return;
        }
    } catch(Exception e) {
        response.sendRedirect("ulogout");
        return;
    }
    
    String successMessage = (String) session.getAttribute("successMessage");
    String errorMessage   = (String) session.getAttribute("errorMessage");
    session.removeAttribute("successMessage");
    session.removeAttribute("errorMessage");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Add Product - MarketHub</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    
    <style>
        /* ============ CSS VARIABLES ============ */
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

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Outfit', sans-serif;
            background: linear-gradient(135deg, #f0f4ff 0%, #e5edff 100%);
            min-height: 100vh;
            overflow-x: hidden;
        }

        /* ============ SIDEBAR ============ */
        .sidebar {
            position: fixed; left: 0; top: 0;
            height: 100vh; width: 260px;
            background: var(--sidebar-bg);
            box-shadow: 4px 0 20px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            z-index: 1000; overflow-y: auto;
        }
        .sidebar::-webkit-scrollbar { width: 6px; }
        .sidebar::-webkit-scrollbar-track { background: rgba(255,255,255,0.05); }
        .sidebar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 3px; }

        .sidebar-header {
            padding: 25px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            background: linear-gradient(135deg, var(--dark-bg) 0%, #0f172a 100%);
        }
        .sidebar-logo {
            color: white; font-size: 24px; font-weight: 800;
            text-decoration: none; display: flex; align-items: center;
            gap: 12px; letter-spacing: -0.5px;
        }
        .sidebar-logo i { color: var(--primary-color); font-size: 28px; }
        .sidebar-logo .seller-badge {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white; font-size: 10px; padding: 3px 8px;
            border-radius: 12px; font-weight: 700; letter-spacing: 0.5px;
        }
        .sidebar-menu { padding: 20px 0; }
        .menu-section-title {
            color: rgba(255,255,255,0.4); font-size: 11px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1.5px; padding: 20px 20px 10px;
        }
        .sidebar-menu a {
            display: flex; align-items: center; padding: 14px 20px;
            color: rgba(255,255,255,0.8); text-decoration: none;
            transition: all 0.3s ease; position: relative;
            font-weight: 500; margin: 2px 10px; border-radius: 8px;
        }
        .sidebar-menu a::before {
            content: ''; position: absolute; left: 0; top: 50%;
            transform: translateY(-50%); width: 3px; height: 0;
            background: var(--primary-color); transition: height 0.3s ease;
            border-radius: 0 3px 3px 0;
        }
        .sidebar-menu a:hover, .sidebar-menu a.active {
            background: var(--sidebar-hover); color: white; padding-left: 25px;
        }
        .sidebar-menu a.active::before { height: 70%; }
        .sidebar-menu a i {
            font-size: 18px; margin-right: 15px; width: 20px;
            text-align: center; transition: all 0.3s ease;
        }
        .sidebar-menu a:hover i, .sidebar-menu a.active i {
            color: var(--primary-color); transform: scale(1.1);
        }
        .sidebar-menu .badge { margin-left: auto; font-size: 10px; padding: 4px 8px; font-weight: 700; }

        /* ============ MAIN CONTENT ============ */
        .main-content { margin-left: 260px; min-height: 100vh; transition: all 0.3s ease; }

        /* ============ TOP NAVBAR ============ */
        .top-navbar {
            background: white; padding: 20px 30px;
            box-shadow: 0 2px 15px rgba(0,0,0,0.05);
            position: sticky; top: 0; z-index: 999;
            display: flex; justify-content: space-between; align-items: center;
        }
        .navbar-left h1 { font-size: 28px; font-weight: 800; color: var(--text-primary); margin: 0; letter-spacing: -0.5px; }
        .navbar-left .breadcrumb { font-size: 13px; color: var(--text-secondary); margin: 5px 0 0; }
        .navbar-right { display: flex; align-items: center; gap: 20px; }
        .seller-info-badge {
            background: linear-gradient(135deg, rgba(99,102,241,0.1) 0%, rgba(139,92,246,0.1) 100%);
            border: 1px solid rgba(99,102,241,0.2); padding: 8px 15px;
            border-radius: 10px; font-size: 13px; color: var(--primary-color); font-weight: 600;
        }
        .seller-info-badge i { margin-right: 6px; }
        .notification-icon {
            position: relative; width: 40px; height: 40px;
            background: var(--light-bg); border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; transition: all 0.3s ease;
        }
        .notification-icon:hover { background: var(--primary-color); color: white; }
        .notification-icon .badge-notification {
            position: absolute; top: -5px; right: -5px;
            background: var(--danger-color); color: white;
            width: 20px; height: 20px; border-radius: 50%;
            font-size: 10px; display: flex; align-items: center;
            justify-content: center; font-weight: 700; border: 2px solid white;
        }

        /* ============ DASHBOARD CONTENT ============ */
        .dashboard-content { padding: 30px; }

        .signup-container {
            max-width: 900px; margin: 0 auto; background: white;
            border-radius: 20px; padding: 40px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.08);
            border: 1px solid var(--border-color);
            animation: fadeInUp 0.6s ease;
        }
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(30px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        .signup-container h1 {
            font-size: 32px; font-weight: 800; color: var(--text-primary);
            margin-bottom: 10px; display: flex; align-items: center;
            gap: 12px; letter-spacing: -0.5px;
        }
        .signup-container h1 i { color: var(--primary-color); font-size: 36px; }
        .signup-subtitle { color: var(--text-secondary); font-size: 15px; margin-bottom: 35px; font-weight: 500; }

        /* ============ FORM ELEMENTS ============ */
        .form-row {
            display: grid; grid-template-columns: repeat(2, 1fr);
            gap: 20px; margin-bottom: 20px;
        }
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block; font-weight: 600; font-size: 14px;
            color: var(--text-primary); margin-bottom: 8px; letter-spacing: 0.2px;
        }
        .form-group label i { margin-right: 6px; color: var(--primary-color); font-size: 13px; }
        .form-group input,
        .form-group textarea,
        .form-group select {
            width: 100%; padding: 14px 18px;
            border: 2px solid var(--border-color); border-radius: 12px;
            font-size: 14px; font-family: 'Outfit', sans-serif;
            transition: all 0.3s ease; background: white; color: var(--text-primary);
        }
        .form-group input:focus,
        .form-group textarea:focus,
        .form-group select:focus {
            outline: none; border-color: var(--primary-color);
            box-shadow: 0 0 0 4px rgba(99,102,241,0.1); background: #fafbff;
        }
        .form-group textarea { resize: vertical; min-height: 120px; }
        .form-group input::placeholder,
        .form-group textarea::placeholder { color: #cbd5e1; }

        /* ============ FORM ACTIONS ============ */
        .form-actions {
            display: flex; gap: 15px; margin-top: 35px;
            padding-top: 30px; border-top: 2px solid var(--border-color);
        }
        .btn {
            padding: 14px 32px; border: none; border-radius: 12px;
            font-size: 15px; font-weight: 700; cursor: pointer;
            transition: all 0.3s ease; text-decoration: none;
            display: inline-flex; align-items: center; justify-content: center;
            gap: 10px; font-family: 'Outfit', sans-serif; letter-spacing: 0.3px;
        }
        .btn i { font-size: 16px; }
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white; flex: 1; box-shadow: 0 4px 15px rgba(99,102,241,0.3);
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 6px 25px rgba(99,102,241,0.4); }
        .btn-secondary {
            background: white; color: var(--text-secondary); border: 2px solid var(--border-color);
        }
        .btn-secondary:hover { background: var(--light-bg); border-color: var(--text-secondary); color: var(--text-primary); }

        /* ============ INFO CARD ============ */
        .info-card {
            background: linear-gradient(135deg, rgba(99,102,241,0.05) 0%, rgba(139,92,246,0.05) 100%);
            border: 2px dashed rgba(99,102,241,0.3);
            border-radius: 12px; padding: 20px; margin-bottom: 25px;
        }
        .info-card h3 {
            font-size: 16px; font-weight: 700; color: var(--primary-color);
            margin-bottom: 10px; display: flex; align-items: center; gap: 8px;
        }
        .info-card p { font-size: 14px; color: var(--text-secondary); margin: 0; line-height: 1.6; }

        /* ============ ALERTS ============ */
        .alert {
            padding: 15px 20px; border-radius: 12px; margin-bottom: 20px;
            display: flex; align-items: center; gap: 12px;
            font-weight: 600; animation: slideDown 0.3s ease;
        }
        @keyframes slideDown {
            from { opacity: 0; transform: translateY(-10px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        .alert-success {
            background: linear-gradient(135deg, rgba(16,185,129,0.1) 0%, rgba(5,150,105,0.1) 100%);
            border-left: 4px solid var(--success-color); color: var(--success-color);
        }
        .alert-danger {
            background: linear-gradient(135deg, rgba(239,68,68,0.1) 0%, rgba(220,38,38,0.1) 100%);
            border-left: 4px solid var(--danger-color); color: var(--danger-color);
        }
        .alert i { font-size: 20px; }

        /* ============ RETURN POLICY SECTION ============ */
        .return-policy-section { margin: 10px 0 25px; }

        .section-divider { display: flex; align-items: center; gap: 15px; margin: 30px 0 25px; }
        .section-divider-line {
            flex: 1; height: 2px;
            background: linear-gradient(90deg, transparent, var(--border-color), transparent);
        }
        .section-divider-title {
            background: linear-gradient(135deg, rgba(99,102,241,0.1) 0%, rgba(139,92,246,0.1) 100%);
            border: 1px solid rgba(99,102,241,0.25);
            color: var(--primary-color); font-size: 13px; font-weight: 700;
            padding: 8px 18px; border-radius: 20px; white-space: nowrap;
            letter-spacing: 0.3px; display: flex; align-items: center; gap: 8px;
        }

        /* Radio Cards */
        .radio-group { display: flex; gap: 15px; }
        .radio-card { cursor: pointer; flex: 1; max-width: 160px; }
        .radio-card input[type="radio"] { display: none; }
        .radio-card-inner {
            display: flex; align-items: center; justify-content: center;
            gap: 10px; padding: 14px 20px; border: 2px solid var(--border-color);
            border-radius: 12px; font-weight: 600; font-size: 15px;
            color: var(--text-secondary); background: white; transition: all 0.25s ease;
        }
        .radio-card-inner i { font-size: 18px; }
        .radio-card input[type="radio"]:checked + .radio-card-inner {
            border-color: var(--primary-color);
            background: linear-gradient(135deg, rgba(99,102,241,0.08) 0%, rgba(139,92,246,0.08) 100%);
            color: var(--primary-color); box-shadow: 0 0 0 4px rgba(99,102,241,0.1);
        }
        #returnNo:checked + .radio-card-inner {
            border-color: var(--danger-color); background: rgba(239,68,68,0.06);
            color: var(--danger-color); box-shadow: 0 0 0 4px rgba(239,68,68,0.1);
        }

        /* Disabled sub-fields */
        .return-sub-fields { transition: all 0.4s ease; }
        .disabled-fields { opacity: 0.45; pointer-events: none; filter: grayscale(30%); }
        .disabled-fields select,
        .disabled-fields textarea,
        .disabled-fields input { background: #f1f5f9 !important; cursor: not-allowed; }

        /* Checkbox Grid */
        .checkbox-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }
        .checkbox-card { cursor: pointer; }
        .checkbox-card input[type="checkbox"] { display: none; }
        .checkbox-card-inner {
            display: flex; align-items: center; gap: 10px; padding: 12px 16px;
            border: 2px solid var(--border-color); border-radius: 10px;
            font-size: 13px; font-weight: 600; color: var(--text-secondary);
            background: white; transition: all 0.25s ease;
        }
        .checkbox-card-inner i { font-size: 16px; color: var(--text-secondary); transition: color 0.25s; }
        .checkbox-card input[type="checkbox"]:checked + .checkbox-card-inner {
            border-color: var(--primary-color);
            background: linear-gradient(135deg, rgba(99,102,241,0.07) 0%, rgba(139,92,246,0.07) 100%);
            color: var(--primary-color); box-shadow: 0 0 0 3px rgba(99,102,241,0.1);
        }
        .checkbox-card input[type="checkbox"]:checked + .checkbox-card-inner i { color: var(--primary-color); }

        /* ============ MULTI IMAGE UPLOAD ============ */
        .image-count-badge {
            display: inline-block; margin-left: 10px;
            background: linear-gradient(135deg, rgba(99,102,241,0.12), rgba(139,92,246,0.12));
            border: 1px solid rgba(99,102,241,0.3); color: var(--primary-color);
            font-size: 11px; font-weight: 700; padding: 3px 10px;
            border-radius: 20px; vertical-align: middle; letter-spacing: 0.3px;
            transition: all 0.3s ease;
        }
        .image-count-badge.full {
            background: rgba(239,68,68,0.1);
            border-color: rgba(239,68,68,0.3);
            color: var(--danger-color);
        }

        .multi-upload-dropzone {
            border: 2px dashed var(--border-color); border-radius: 16px;
            background: #fafbff; padding: 40px 20px; text-align: center;
            cursor: pointer; transition: all 0.3s ease; position: relative;
        }
        .multi-upload-dropzone:hover,
        .multi-upload-dropzone.dragover {
            border-color: var(--primary-color);
            background: rgba(99,102,241,0.04);
            box-shadow: 0 0 0 4px rgba(99,102,241,0.08);
        }
        .multi-upload-dropzone.dragover { transform: scale(1.01); }

        .dropzone-icon {
            width: 64px; height: 64px;
            background: linear-gradient(135deg, rgba(99,102,241,0.12), rgba(139,92,246,0.12));
            border-radius: 50%; display: flex; align-items: center; justify-content: center;
            margin: 0 auto 16px; transition: all 0.3s ease;
        }
        .multi-upload-dropzone:hover .dropzone-icon,
        .multi-upload-dropzone.dragover .dropzone-icon {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
        }
        .dropzone-icon i { font-size: 26px; color: var(--primary-color); transition: color 0.3s ease; }
        .multi-upload-dropzone:hover .dropzone-icon i,
        .multi-upload-dropzone.dragover .dropzone-icon i { color: white; }

        .dropzone-title { font-size: 16px; font-weight: 700; color: var(--text-primary); margin: 0 0 6px; }
        .dropzone-sub { font-size: 14px; color: var(--text-secondary); margin: 0 0 12px; }
        .dropzone-browse { color: var(--primary-color); font-weight: 700; text-decoration: underline; cursor: pointer; }
        .dropzone-hint { font-size: 12px; color: var(--text-secondary); margin: 0; opacity: 0.8; }

        .upload-error {
            display: flex; align-items: center; gap: 8px;
            background: rgba(239,68,68,0.08); border: 1px solid rgba(239,68,68,0.25);
            border-radius: 10px; padding: 10px 16px; margin-top: 12px;
            color: var(--danger-color); font-size: 13px; font-weight: 600;
            animation: slideDown 0.3s ease;
        }

        .preview-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 20px; }

        .preview-card {
            position: relative; border: 2px solid var(--border-color);
            border-radius: 14px; overflow: hidden; background: white;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            transition: all 0.3s ease; animation: fadeInUp 0.35s ease;
        }
        .preview-card:hover {
            box-shadow: 0 8px 25px rgba(0,0,0,0.1); transform: translateY(-2px);
            border-color: var(--primary-color);
        }
        .preview-card.primary-card {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(99,102,241,0.15), 0 4px 15px rgba(0,0,0,0.08);
        }
        .preview-img-wrap { width: 100%; height: 160px; overflow: hidden; background: #f8fafc; }
        .preview-img-wrap img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.4s ease; }
        .preview-card:hover .preview-img-wrap img { transform: scale(1.05); }

        .preview-card-body {
            padding: 10px 12px; display: flex; align-items: center;
            justify-content: space-between; gap: 6px;
        }
        .preview-filename {
            font-size: 11px; font-weight: 600; color: var(--text-secondary);
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis; flex: 1;
        }
        .preview-remove-btn {
            width: 26px; height: 26px; border: none; border-radius: 8px;
            background: rgba(239,68,68,0.1); color: var(--danger-color);
            cursor: pointer; display: flex; align-items: center; justify-content: center;
            flex-shrink: 0; transition: all 0.2s ease; font-size: 11px;
        }
        .preview-remove-btn:hover { background: var(--danger-color); color: white; transform: scale(1.1); }

        .primary-badge {
            position: absolute; top: 10px; left: 10px;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white; font-size: 10px; font-weight: 700;
            padding: 4px 10px; border-radius: 20px; letter-spacing: 0.4px;
            box-shadow: 0 2px 8px rgba(99,102,241,0.35);
        }

        /* ============ RESPONSIVE ============ */
        @media (max-width: 768px) {
            .sidebar { width: 70px; }
            .sidebar-header, .menu-section-title,
            .sidebar-menu a span, .sidebar-menu .badge { display: none; }
            .sidebar-menu a { justify-content: center; padding: 14px 10px; }
            .sidebar-menu a i { margin-right: 0; }
            .main-content { margin-left: 70px; }
            .navbar-left h1 { font-size: 20px; }
            .signup-container { padding: 25px; }
            .signup-container h1 { font-size: 24px; }
            .form-row { grid-template-columns: 1fr; gap: 0; }
            .form-actions { flex-direction: column; }
            .preview-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 480px) {
            .dashboard-content { padding: 15px; }
            .signup-container { padding: 20px; }
            .checkbox-grid { grid-template-columns: 1fr; }
            .radio-card { max-width: 50%; }
            .preview-grid { grid-template-columns: 1fr; }
            .preview-img-wrap { height: 200px; }
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
            <a href="sellerdashboard.jsp"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
            <a href="viewproduct.jsp"><i class="fas fa-box"></i><span>My Products</span></a>
            <a href="addprod.jsp" class="active"><i class="fas fa-plus-circle"></i><span>Add Product</span></a>
            <a href="#"><i class="fas fa-shopping-cart"></i><span>My Orders</span><span class="badge bg-danger">8</span></a>
            <a href="#"><i class="fas fa-warehouse"></i><span>Inventory</span></a>
            <a href="ulogout"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
        </nav>
    </aside>

    <!-- Main Content -->
    <div class="main-content">
        <div class="top-navbar">
            <div class="navbar-left">
                <h1>Add New Product</h1>
                <div class="breadcrumb"><i class="fas fa-home"></i> Home / Products / Add Product</div>
            </div>
            <div class="navbar-right">
                <div class="seller-info-badge">
                    <i class="fas fa-user-circle"></i><%= loggedInEmail %>
                </div>
                <div class="notification-icon">
                    <i class="fas fa-bell"></i>
                    <span class="badge-notification">3</span>
                </div>
            </div>
        </div>

        <div class="dashboard-content">
            <div class="signup-container">
                <h1><i class="fas fa-box-open"></i> Add Product</h1>
                <p class="signup-subtitle">List your product on MarketHub today! Fill in the details below.</p>

                <% if (successMessage != null) { %>
                <div class="alert alert-success">
                    <i class="fas fa-check-circle"></i><p><%= successMessage %></p>
                </div>
                <% } %>

                <% if (errorMessage != null) { %>
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-triangle"></i><p><%= errorMessage %></p>
                </div>
                <% } %>

                <div class="info-card">
                    <h3><i class="fas fa-info-circle"></i> Product Listing Guidelines</h3>
                    <p>Ensure your product details are accurate and complete. High-quality images and detailed descriptions help increase sales. Products will be linked to your account: <strong><%= loggedInEmail %></strong></p>
                </div>

                <form action="addprod" method="POST" enctype="multipart/form-data">

                    <!-- Row 1: Name + Quantity -->
                    <div class="form-row">
                        <div class="form-group">
                            <label for="productname"><i class="fas fa-tag"></i> Product Name</label>
                            <input type="text" id="productname" name="productname" placeholder="Enter product name" required>
                        </div>
                        <div class="form-group">
                            <label for="quantity"><i class="fas fa-boxes"></i> Quantity</label>
                            <input type="number" id="quantity" name="quantity" placeholder="Enter quantity" min="1" required>
                        </div>
                    </div>

                    <!-- Row 2: Rate + Category -->
                    <div class="form-row">
                        <div class="form-group">
                            <label for="rate"><i class="fas fa-rupee-sign"></i> Rate (Price per Unit)</label>
                            <input type="number" id="rate" name="rate" placeholder="Enter price" min="0" step="0.01" required>
                        </div>
                        <div class="form-group">
                            <label for="category"><i class="fas fa-list"></i> Category</label>
                            <select id="category" name="category" required>
                                <option value="">Select Category</option>
                                <option value="electronics">Electronics</option>
                                <option value="clothing">Clothing &amp; Fashion</option>
                                <option value="home">Home &amp; Kitchen</option>
                                <option value="books">Books &amp; Media</option>
                                <option value="sports">Sports &amp; Fitness</option>
                                <option value="toys">Toys &amp; Games</option>
                                <option value="beauty">Beauty &amp; Personal Care</option>
                                <option value="other">Other</option>
                            </select>
                        </div>
                    </div>

                    <!-- Description -->
                    <div class="form-group">
                        <label for="productdis"><i class="fas fa-align-left"></i> Product Description</label>
                        <textarea id="productdis" name="proddis" placeholder="Describe your product in detail... Include features, specifications, and benefits." required></textarea>
                    </div>

                    <!-- ============ RETURN & REFUND POLICY SECTION ============ -->
                    <div class="return-policy-section">
                        <div class="section-divider">
                            <div class="section-divider-line"></div>
                            <div class="section-divider-title">
                                <i class="fas fa-undo-alt"></i> Return &amp; Refund Policy
                            </div>
                            <div class="section-divider-line"></div>
                        </div>

                        <div class="form-group">
                            <label>
                                <i class="fas fa-question-circle"></i>
                                Return Available? <span style="color:var(--danger-color);">*</span>
                            </label>
                            <div class="radio-group">
                                <label class="radio-card">
                                    <input type="radio" name="returnAvailable" id="returnYes" value="yes"
                                           required onchange="toggleReturnFields(true)">
                                    <div class="radio-card-inner">
                                        <i class="fas fa-check-circle"></i><span>Yes</span>
                                    </div>
                                </label>
                                <label class="radio-card">
                                    <input type="radio" name="returnAvailable" id="returnNo" value="no"
                                           required onchange="toggleReturnFields(false)">
                                    <div class="radio-card-inner">
                                        <i class="fas fa-times-circle"></i><span>No</span>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <div id="returnSubFields" class="return-sub-fields disabled-fields">
                            <div class="form-row">
                                <div class="form-group">
                                    <label for="returnWindow"><i class="fas fa-calendar-alt"></i> Return Window</label>
                                    <select id="returnWindow" name="returnWindow" disabled>
                                        <option value="">Select Return Window</option>
                                        <option value="7">7 Days</option>
                                        <option value="10">10 Days</option>
                                        <option value="15">15 Days</option>
                                        <option value="30">30 Days</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label for="returnType"><i class="fas fa-exchange-alt"></i> Return Type</label>
                                    <select id="returnType" name="returnType" disabled>
                                        <option value="">Select Return Type</option>
                                        <option value="replacement_only">Replacement Only</option>
                                        <option value="refund_only">Refund Only</option>
                                        <option value="replacement_or_refund">Replacement or Refund</option>
                                    </select>
                                </div>
                            </div>

                            <div class="form-group">
                                <label><i class="fas fa-clipboard-list"></i> Return Conditions</label>
                                <div class="checkbox-grid">
                                    <label class="checkbox-card">
                                        <input type="checkbox" name="returnConditions" value="unopened_only" disabled>
                                        <div class="checkbox-card-inner"><i class="fas fa-box-open"></i><span>Unopened Only</span></div>
                                    </label>
                                    <label class="checkbox-card">
                                        <input type="checkbox" name="returnConditions" value="original_packaging" disabled>
                                        <div class="checkbox-card-inner"><i class="fas fa-archive"></i><span>Original Packaging Required</span></div>
                                    </label>
                                    <label class="checkbox-card">
                                        <input type="checkbox" name="returnConditions" value="damaged_accepted" disabled>
                                        <div class="checkbox-card-inner"><i class="fas fa-exclamation-triangle"></i><span>Damaged Items Accepted</span></div>
                                    </label>
                                    <label class="checkbox-card">
                                        <input type="checkbox" name="returnConditions" value="no_questions_asked" disabled>
                                        <div class="checkbox-card-inner"><i class="fas fa-smile"></i><span>No Questions Asked</span></div>
                                    </label>
                                </div>
                            </div>

                            <div class="form-group">
                                <label for="returnNotes">
                                    <i class="fas fa-sticky-note"></i>
                                    Additional Return Notes
                                    <span style="color:var(--text-secondary);font-weight:400;">(Optional)</span>
                                </label>
                                <textarea id="returnNotes" name="returnNotes"
                                          placeholder="Any specific return instructions or conditions for buyers..."
                                          disabled></textarea>
                            </div>
                        </div>
                    </div>
                    <!-- ============ END RETURN SECTION ============ -->

                    <!-- ============ MULTI-IMAGE UPLOAD SECTION ============ -->
                    <div class="form-group">
                        <label>
                            <i class="fas fa-images"></i> Product Images
                            <span class="image-count-badge" id="imageCountBadge">0 / 5</span>
                        </label>
                        <div class="multi-upload-dropzone" id="dropZone">
                            <input type="file" id="productimages" name="productimages"
                                   accept=".jpg,.jpeg,.png" multiple style="display:none;">
                            <div class="dropzone-icon"><i class="fas fa-cloud-upload-alt"></i></div>
                            <p class="dropzone-title">Drag &amp; drop images here</p>
                            <p class="dropzone-sub">or <span class="dropzone-browse" id="browseBtn">browse files</span></p>
                            <p class="dropzone-hint">
                                <i class="fas fa-info-circle"></i>
                                JPG, JPEG, PNG only &nbsp;•&nbsp; Max 5 images &nbsp;•&nbsp; 10MB each
                            </p>
                        </div>
                        <div class="upload-error" id="uploadError" style="display:none;">
                            <i class="fas fa-exclamation-circle"></i>
                            <span id="uploadErrorText"></span>
                        </div>
                        <div class="preview-grid" id="previewGrid"></div>
                    </div>
                    <!-- ============ END MULTI-IMAGE UPLOAD ============ -->

                    <div class="form-actions">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-check-circle"></i> Add Product
                        </button>
                        <a href="viewproduct.jsp" class="btn btn-secondary">
                            <i class="fas fa-times-circle"></i> Cancel
                        </a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
    /* ================================================
       MULTI-IMAGE UPLOAD — Drop zone + Live preview
       ================================================ */
    (function () {
        const MAX_FILES   = 5;
        const MAX_SIZE_MB = 10;
        const ALLOWED     = ['image/jpeg', 'image/jpg', 'image/png'];

        const dropZone    = document.getElementById('dropZone');
        const fileInput   = document.getElementById('productimages');
        const previewGrid = document.getElementById('previewGrid');
        const countBadge  = document.getElementById('imageCountBadge');
        const errorBanner = document.getElementById('uploadError');
        const errorText   = document.getElementById('uploadErrorText');
        const browseBtn   = document.getElementById('browseBtn');

        let dt = new DataTransfer();

        // ── Open file picker ──────────────────────────────────────────
        browseBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            fileInput.click();
        });
        dropZone.addEventListener('click', (e) => {
            if (e.target !== browseBtn) fileInput.click();
        });

        // ── Drag & drop ───────────────────────────────────────────────
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
        dropZone.addEventListener('dragleave', () => dropZone.classList.remove('dragover'));
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            processFiles([...e.dataTransfer.files]);
        });

        // ── File input change ─────────────────────────────────────────
        fileInput.addEventListener('change', () => {
            processFiles([...fileInput.files]);
            fileInput.value = '';
        });

        // ── Core processing ───────────────────────────────────────────
        function processFiles(incoming) {
            hideError();
            for (const file of incoming) {
                if (dt.files.length >= MAX_FILES) {
                    showError('Maximum ' + MAX_FILES + ' images allowed.');
                    break;
                }
                if (!ALLOWED.includes(file.type)) {
                    showError('"' + file.name + '" is not a valid type. Use JPG or PNG.');
                    continue;
                }
                if (file.size > MAX_SIZE_MB * 1024 * 1024) {
                    showError('"' + file.name + '" exceeds the ' + MAX_SIZE_MB + 'MB size limit.');
                    continue;
                }
                dt.items.add(file);
            }
            fileInput.files = dt.files;
            renderPreviews();
            updateBadge();
        }

        // ── Render previews ───────────────────────────────────────────
        function renderPreviews() {
            previewGrid.innerHTML = '';
            [...dt.files].forEach((file, index) => {
                const reader = new FileReader();
                reader.onload = (e) => {
                    previewGrid.appendChild(buildCard(e.target.result, file.name, index));
                };
                reader.readAsDataURL(file);
            });
        }

        // ── Build preview card ────────────────────────────────────────
        function buildCard(src, name, index) {
            const card = document.createElement('div');
            card.className = 'preview-card' + (index === 0 ? ' primary-card' : '');
            card.dataset.index = index;

            const safeName = name.replace(/&/g, '&amp;')
                                 .replace(/"/g, '&quot;')
                                 .replace(/</g, '&lt;');

            card.innerHTML =
                (index === 0 ? '<div class="primary-badge"><i class="fas fa-star"></i> Primary</div>' : '') +
                '<div class="preview-img-wrap"><img id="prev-img-' + index + '" alt="' + safeName + '"></div>' +
                '<div class="preview-card-body">' +
                  '<span class="preview-filename" title="' + safeName + '">' + safeName + '</span>' +
                  '<button type="button" class="preview-remove-btn" title="Remove image">' +
                    '<i class="fas fa-times"></i>' +
                  '</button>' +
                '</div>';

            // Set src via property (avoids XSS through inline attribute)
            card.querySelector('#prev-img-' + index).src = src;

            card.querySelector('.preview-remove-btn').addEventListener('click', (e) => {
                e.stopPropagation();
                removeFile(index);
            });

            return card;
        }

        // ── Remove file by index ──────────────────────────────────────
        function removeFile(index) {
            const newDt = new DataTransfer();
            [...dt.files].forEach((file, i) => { if (i !== index) newDt.items.add(file); });
            dt = newDt;
            fileInput.files = dt.files;
            hideError();
            renderPreviews();
            updateBadge();
        }

        // ── Badge counter ─────────────────────────────────────────────
        function updateBadge() {
            const count = dt.files.length;
            countBadge.textContent = count + ' / ' + MAX_FILES;
            countBadge.classList.toggle('full', count >= MAX_FILES);
        }

        function showError(msg) { errorText.textContent = msg; errorBanner.style.display = 'flex'; }
        function hideError()    { errorBanner.style.display = 'none'; }

    })();


    /* ================================================
       RETURN FIELD TOGGLE
       Named global — required by onchange="" in HTML
       ================================================ */
    function toggleReturnFields(isAvailable) {
        const subFields    = document.getElementById('returnSubFields');
        const returnWindow = document.getElementById('returnWindow');
        const returnType   = document.getElementById('returnType');
        const returnNotes  = document.getElementById('returnNotes');
        const checkboxes   = document.querySelectorAll('input[name="returnConditions"]');

        if (isAvailable) {
            subFields.classList.remove('disabled-fields');
            returnWindow.disabled = false;
            returnType.disabled   = false;
            returnNotes.disabled  = false;
            checkboxes.forEach(cb => cb.disabled = false);
        } else {
            subFields.classList.add('disabled-fields');
            returnWindow.disabled = true;
            returnType.disabled   = true;
            returnNotes.disabled  = true;
            checkboxes.forEach(cb => { cb.disabled = true; cb.checked = false; });
            returnWindow.value = '';
            returnType.value   = '';
            returnNotes.value  = '';
        }
    }


    /* ================================================
       UNIFIED FORM VALIDATION — single listener only
       ================================================ */
    document.querySelector('form').addEventListener('submit', function (e) {

        // Core fields
        const productName = document.getElementById('productname').value.trim();
        const quantity    = parseInt(document.getElementById('quantity').value, 10);
        const rate        = parseFloat(document.getElementById('rate').value);
        const description = document.getElementById('productdis').value.trim();

        if (productName.length < 3) {
            e.preventDefault();
            alert('Product name must be at least 3 characters long.');
            return;
        }
        if (isNaN(quantity) || quantity < 1) {
            e.preventDefault();
            alert('Quantity must be at least 1.');
            return;
        }
        if (isNaN(rate) || rate <= 0) {
            e.preventDefault();
            alert('Rate must be greater than 0.');
            return;
        }
        if (description.length < 20) {
            e.preventDefault();
            alert('Product description must be at least 20 characters long.');
            return;
        }

        // Return policy fields
        const returnAvailableEl = document.querySelector('input[name="returnAvailable"]:checked');
        if (!returnAvailableEl) {
            e.preventDefault();
            alert('Please indicate whether this product is returnable.');
            return;
        }
        if (returnAvailableEl.value === 'yes') {
            if (!document.getElementById('returnWindow').value) {
                e.preventDefault();
                alert('Please select a Return Window for returnable products.');
                return;
            }
            if (!document.getElementById('returnType').value) {
                e.preventDefault();
                alert('Please select a Return Type for returnable products.');
                return;
            }
        }

        // All validations passed — form submits normally
    });
    </script>
</body>
</html>
