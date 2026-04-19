<%-- 
    Document   : viewProducts
    Created on : 3 Feb, 2026
    Author     : moham
    Modified   : To show only logged-in seller's products
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="DataBase.dbconfig" %>
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Products - MarketHub</title>
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    
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
        
        .sidebar::-webkit-scrollbar { width: 6px; }
        .sidebar::-webkit-scrollbar-track { background: rgba(255,255,255,0.05); }
        .sidebar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 3px; }
        
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
        
        .sidebar-logo i { color: var(--primary-color); font-size: 28px; }
        
        .sidebar-logo .seller-badge {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            font-size: 10px;
            padding: 3px 8px;
            border-radius: 12px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        
        .sidebar-menu { padding: 20px 0; }
        
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
        
        .sidebar-menu a.active::before { height: 70%; }
        
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
        
        .sidebar-menu .badge { margin-left: auto; font-size: 10px; padding: 4px 8px; font-weight: 700; }
        
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
        
        .navbar-right { display: flex; align-items: center; gap: 20px; }
        
        .seller-info-badge {
            background: linear-gradient(135deg, rgba(99,102,241,0.1) 0%, rgba(139,92,246,0.1) 100%);
            border: 1px solid rgba(99,102,241,0.2);
            padding: 8px 15px;
            border-radius: 10px;
            font-size: 13px;
            color: var(--primary-color);
            font-weight: 600;
        }
        
        .seller-info-badge i {
            margin-right: 6px;
        }
        
        .notification-icon {
            position: relative;
            width: 40px;
            height: 40px;
            background: var(--light-bg);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .notification-icon:hover { background: var(--primary-color); }
        .notification-icon:hover i { color: white; }
        
        .notification-icon .badge-notification {
            position: absolute;
            top: -5px;
            right: -5px;
            background: var(--danger-color);
            color: white;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            font-size: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            border: 2px solid white;
        }
        
        .seller-profile {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 15px;
            background: var(--light-bg);
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .seller-profile:hover { background: var(--primary-color); }
        .seller-profile .profile-info { display: flex; flex-direction: column; }
        .seller-profile .profile-name { font-weight: 700; font-size: 14px; color: var(--text-primary); transition: color 0.3s; }
        .seller-profile .profile-role { font-size: 12px; color: var(--text-secondary); transition: color 0.3s; }
        .seller-profile:hover .profile-name,
        .seller-profile:hover .profile-role,
        .seller-profile:hover .chevron { color: white; }
        .chevron { transition: color 0.3s; }
        
        /* ============ DASHBOARD CONTENT ============ */
        .dashboard-content { padding: 30px; }
        
        /* ============ TOP STATS CARDS ============ */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 28px;
            animation: fadeInUp 0.5s ease;
        }
        
        .stat-card {
            background: white;
            border-radius: 16px;
            padding: 22px;
            box-shadow: 0 4px 18px rgba(0,0,0,0.06);
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 18px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.1);
        }
        
        .stat-icon {
            width: 50px;
            height: 50px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            color: white;
            flex-shrink: 0;
        }
        
        .stat-icon.purple  { background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)); }
        .stat-icon.green   { background: linear-gradient(135deg, #10b981, #059669); }
        .stat-icon.orange  { background: linear-gradient(135deg, #f59e0b, #d97706); }
        .stat-icon.blue    { background: linear-gradient(135deg, #06b6d4, #0891b2); }
        
        .stat-info { display: flex; flex-direction: column; }
        .stat-value { font-size: 24px; font-weight: 800; color: var(--text-primary); line-height: 1.2; }
        .stat-label { font-size: 13px; color: var(--text-secondary); font-weight: 500; margin-top: 2px; }
        
        /* ============ TOOLBAR ============ */
        .toolbar {
            background: white;
            border-radius: 16px;
            padding: 18px 24px;
            box-shadow: 0 4px 18px rgba(0,0,0,0.06);
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 22px;
            flex-wrap: wrap;
            animation: fadeInUp 0.55s ease;
        }
        
        .toolbar-left { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
        
        .search-box {
            position: relative;
            width: 300px;
        }
        
        .search-box i {
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
            font-size: 15px;
            pointer-events: none;
        }
        
        .search-box input {
            width: 100%;
            padding: 11px 18px 11px 44px;
            border: 2px solid var(--border-color);
            border-radius: 12px;
            font-size: 14px;
            font-family: 'Outfit', sans-serif;
            transition: all 0.3s ease;
            background: #fafbff;
            color: var(--text-primary);
        }
        
        .search-box input:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
            background: white;
        }
        
        .search-box input::placeholder { color: #cbd5e1; }
        
        .toolbar-right { display: flex; align-items: center; gap: 12px; }
        
        .btn {
            padding: 11px 22px;
            border: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-family: 'Outfit', sans-serif;
            letter-spacing: 0.3px;
        }
        
        .btn i { font-size: 14px; }
        
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 25px rgba(99, 102, 241, 0.4);
        }
        
        .btn-danger-sm {
            background: linear-gradient(135deg, #ef4444, #dc2626);
            color: white;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            box-shadow: 0 2px 8px rgba(239, 68, 68, 0.3);
            border: none;
            font-family: 'Outfit', sans-serif;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        
        .btn-danger-sm:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 14px rgba(239, 68, 68, 0.4);
        }
        
        .btn-edit-sm {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            box-shadow: 0 2px 8px rgba(99, 102, 241, 0.3);
            border: none;
            font-family: 'Outfit', sans-serif;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        
        .btn-edit-sm:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 14px rgba(99, 102, 241, 0.4);
        }
        
        /* ============ PRODUCT TABLE ============ */
        .table-container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 4px 18px rgba(0,0,0,0.06);
            border: 1px solid var(--border-color);
            overflow: hidden;
            animation: fadeInUp 0.6s ease;
        }
        
        .product-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .product-table thead {
            background: linear-gradient(135deg, #f1f5ff 0%, #eef2ff 100%);
            border-bottom: 2px solid var(--border-color);
        }
        
        .product-table th {
            padding: 16px 20px;
            text-align: left;
            font-size: 12px;
            font-weight: 700;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.8px;
            white-space: nowrap;
        }
        
        .product-table th:first-child { padding-left: 24px; }
        .product-table th:last-child  { text-align: center; }
        
        .product-table tbody tr {
            border-bottom: 1px solid var(--border-color);
            transition: background 0.2s ease;
            animation: fadeInUp 0.4s ease both;
        }
        
        .product-table tbody tr:last-child { border-bottom: none; }
        .product-table tbody tr:hover { background: #fafbff; }
        
        /* Row stagger animation */
        .product-table tbody tr:nth-child(1)  { animation-delay: 0.05s; }
        .product-table tbody tr:nth-child(2)  { animation-delay: 0.10s; }
        .product-table tbody tr:nth-child(3)  { animation-delay: 0.15s; }
        .product-table tbody tr:nth-child(4)  { animation-delay: 0.20s; }
        .product-table tbody tr:nth-child(5)  { animation-delay: 0.25s; }
        .product-table tbody tr:nth-child(6)  { animation-delay: 0.30s; }
        .product-table tbody tr:nth-child(7)  { animation-delay: 0.35s; }
        .product-table tbody tr:nth-child(8)  { animation-delay: 0.40s; }
        .product-table tbody tr:nth-child(9)  { animation-delay: 0.45s; }
        .product-table tbody tr:nth-child(10) { animation-delay: 0.50s; }
        
        .product-table td {
            padding: 18px 20px;
            font-size: 14px;
            color: var(--text-primary);
            vertical-align: middle;
        }
        
        .product-table td:first-child { padding-left: 24px; }
        
        /* Serial number */
        .serial-num {
            width: 34px;
            height: 34px;
            background: linear-gradient(135deg, rgba(99,102,241,0.1), rgba(139,92,246,0.1));
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 13px;
            color: var(--primary-color);
        }
        
        /* Product name cell */
        .product-name-cell { display: flex; align-items: center; gap: 14px; }
        
        .product-thumb {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            background: linear-gradient(135deg, #eef2ff, #e0e7ff);
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        
        .product-thumb i { font-size: 20px; color: var(--primary-color); }
        .product-name-info .pname { font-weight: 700; font-size: 14px; color: var(--text-primary); }
        
        /* Price */
        .price-cell { font-weight: 700; font-size: 15px; color: var(--primary-color); }
        
        /* Quantity colours */
        .qty-cell { font-weight: 600; }
        .qty-low { color: var(--danger-color); }
        .qty-mid { color: var(--warning-color); }
        .qty-ok  { color: var(--success-color); }
        
        /* Description */
        .desc-cell { color: var(--text-secondary); font-size: 13px; line-height: 1.5; max-width: 220px; }
        
        /* Category badge */
        .category-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            display: inline-block;
            background: rgba(99, 102, 241, 0.1);
            color: var(--primary-color);
        }
        
        /* Actions */
        .actions-cell { display: flex; align-items: center; justify-content: center; gap: 8px; }
        .actions-cell form { margin: 0; }
        
        /* ============ EMPTY STATE ============ */
        .empty-state {
            text-align: center;
            padding: 80px 20px;
        }
        
        .empty-state-icon {
            width: 100px;
            height: 100px;
            background: linear-gradient(135deg, rgba(99,102,241,0.08), rgba(139,92,246,0.08));
            border-radius: 28px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }
        
        .empty-state-icon i { font-size: 42px; color: var(--primary-color); }
        .empty-state h3 { font-size: 20px; font-weight: 700; color: var(--text-primary); margin-bottom: 8px; }
        .empty-state p { color: var(--text-secondary); font-size: 14px; max-width: 400px; margin: 0 auto 24px; line-height: 1.6; }
        
        /* ============ ERROR STATE ============ */
        .error-state {
            text-align: center;
            padding: 60px 20px;
        }
        .error-state-icon {
            width: 80px; height: 80px;
            background: linear-gradient(135deg, rgba(239,68,68,0.08), rgba(220,38,38,0.08));
            border-radius: 24px;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 20px;
        }
        .error-state-icon i { font-size: 34px; color: var(--danger-color); }
        .error-state h3 { font-size: 18px; font-weight: 700; color: var(--text-primary); margin-bottom: 6px; }
        .error-state p { color: var(--text-secondary); font-size: 13px; max-width: 380px; margin: 0 auto; font-family: 'JetBrains Mono', monospace; word-break: break-all; }
        
        /* ============ TABLE FOOTER ============ */
        .table-footer {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 24px;
            border-top: 1px solid var(--border-color);
            background: #fafbff;
            flex-wrap: wrap;
            gap: 12px;
        }
        
        .table-footer-info { font-size: 13px; color: var(--text-secondary); font-weight: 500; }
        .table-footer-info strong { color: var(--text-primary); }
        
        /* ============ ANIMATIONS ============ */
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(20px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        
        /* ============ RESPONSIVE ============ */
        @media (max-width: 1024px) {
            .stats-row { grid-template-columns: repeat(2, 1fr); }
        }
        
        @media (max-width: 768px) {
            .sidebar { width: 70px; }
            .sidebar-header, .menu-section-title, .sidebar-menu a span, .sidebar-menu .badge { display: none; }
            .sidebar-menu a { justify-content: center; padding: 14px 10px; }
            .sidebar-menu a i { margin-right: 0; }
            .main-content { margin-left: 70px; }
            .navbar-left h1 { font-size: 20px; }
            .dashboard-content { padding: 18px; }
            .stats-row { grid-template-columns: repeat(2, 1fr); gap: 12px; }
            .toolbar { flex-direction: column; align-items: stretch; }
            .search-box { width: 100%; }
            .table-container { overflow-x: auto; }
            .product-table { min-width: 1000px; }
        }
        
        @media (max-width: 480px) {
            .stats-row { grid-template-columns: 1fr 1fr; gap: 10px; }
            .stat-card { padding: 16px; gap: 12px; }
            .stat-value { font-size: 20px; }
            .dashboard-content { padding: 12px; }
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
            <a href="viewproduct.jsp" class="active">
                <i class="fas fa-box"></i>
                <span>My Products</span>
            </a>
            <a href="addprod.jsp">
                <i class="fas fa-plus-circle"></i>
                <span>Add Product</span>
            </a>
            <a href="Sellerorders.jsp">
                <i class="fas fa-shopping-cart"></i>
                <span>My Orders</span>
                <span class="badge bg-danger" style="background: var(--danger-color); border-radius: 6px; color: white;">8</span>
            </a>
            <a href="#">
                <i class="fas fa-warehouse"></i>
                <span>Inventory</span>
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
        <nav class="top-navbar">
            <div class="navbar-left">
                <h1>My Products</h1>
                <div class="breadcrumb">
                    <i class="fas fa-home"></i> Dashboard / Products
                </div>
            </div>
            <div class="navbar-right">
                <div class="seller-info-badge">
                    <i class="fas fa-user-circle"></i>
                    <%= loggedInEmail %>
                </div>
                <div class="notification-icon">
                    <i class="fas fa-bell"></i>
                    <span class="badge-notification">3</span>
                </div>
            </div>
        </nav>
        
        <!-- Dashboard Content -->
        <div class="dashboard-content">
            <%
                // Calculate statistics FOR LOGGED-IN SELLER ONLY
                int totalProducts = 0;
                int lowStockCount = 0;
                double totalValue = 0;
                
                Connection con = null;
                PreparedStatement pst = null;
                ResultSet res = null;
                
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    con = new dbconfig().getConnection();
                    
                    // Count products for this seller
                    String countQuery = "SELECT * FROM `adprod` WHERE `seller_email` = ?";
                    pst = con.prepareStatement(countQuery);
                    pst.setString(1, loggedInEmail);
                    res = pst.executeQuery();
                    
                    while (res.next()) {
                        totalProducts++;
                        int qty = Integer.parseInt(res.getString("quantity"));
                        double rate = Double.parseDouble(res.getString("rate"));
                        totalValue += (qty * rate);
                        if (qty < 10) lowStockCount++;
                    }
                } catch (Exception e) {
                    out.println("<!-- Error calculating stats: " + e.getMessage() + " -->");
                } finally {
                    if (res != null) try { res.close(); } catch(Exception e) {}
                    if (pst != null) try { pst.close(); } catch(Exception e) {}
                    if (con != null) try { con.close(); } catch(Exception e) {}
                }
            %>
            
            <!-- Stats Row -->
            <div class="stats-row">
                <div class="stat-card">
                    <div class="stat-icon purple">
                        <i class="fas fa-box"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><%= totalProducts %></div>
                        <div class="stat-label">My Products</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon green">
                        <i class="fas fa-rupee-sign"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value">₹<%= String.format("%.0f", totalValue) %></div>
                        <div class="stat-label">Inventory Value</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon orange">
                        <i class="fas fa-exclamation-triangle"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><%= lowStockCount %></div>
                        <div class="stat-label">Low Stock Items</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon blue">
                        <i class="fas fa-chart-line"></i>
                    </div>
                    <div class="stat-info">
                        <div class="stat-value"><%= totalProducts %></div>
                        <div class="stat-label">Active Listings</div>
                    </div>
                </div>
            </div>
            
            <!-- Toolbar -->
            <div class="toolbar">
                <div class="toolbar-left">
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" placeholder="Search your products..." id="searchInput">
                    </div>
                </div>
                <div class="toolbar-right">
                    <a href="addprod.jsp" class="btn btn-primary">
                        <i class="fas fa-plus"></i>
                        Add Product
                    </a>
                </div>
            </div>
            
            <!-- Product Table -->
            <div class="table-container">
                <table class="product-table">
                    <thead>
                        <tr>
                            <th>S.No</th>
                            <th>Product Name</th>
                            <th>Price</th>
                            <th>Quantity</th>
                            <th>Category</th>
                            <th>Description</th>
                            <th>Image</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="productTableBody">
                        <%
                            try {
                                Class.forName("com.mysql.jdbc.Driver");
                                con = new dbconfig().getConnection();
                                
                                // CRITICAL: Only show products for THIS seller
                                String query = "SELECT * FROM `adprod` WHERE `seller_email` = ?";
                                pst = con.prepareStatement(query);
                                pst.setString(1, loggedInEmail);
                                res = pst.executeQuery();

                                int serialNo = 1;
                                boolean hasProducts = false;
                                
                                while (res.next()) {
                                    hasProducts = true;
                                    String id = res.getString("id");
                                    String pname = res.getString("pname");
                                    String qty = res.getString("quantity");
                                    String rate = res.getString("rate");
                                    String category = res.getString("category");
                                    String pdis = res.getString("proddis");
                                    String pimage = res.getString("pimage");
                                    
                                    int qtyInt = Integer.parseInt(qty);
                                    String qtyClass = qtyInt < 10 ? "qty-low" : (qtyInt < 30 ? "qty-mid" : "qty-ok");
                        %>
                        <tr>
                            <td>
                                <div class="serial-num"><%= serialNo++ %></div>
                            </td>
                            <td>
                                <div class="product-name-cell">
                                    <div class="product-thumb">
                                        <i class="fas fa-box-open"></i>
                                    </div>
                                    <div class="product-name-info">
                                        <div class="pname"><%= pname %></div>
                                    </div>
                                </div>
                            </td>
                            <td class="price-cell">₹<%= rate %></td>
                            <td class="qty-cell <%= qtyClass %>"><%= qty %></td>
                            <td><span class="category-badge"><%= category %></span></td>
                            <td class="desc-cell"><%= pdis %></td>
                            <td><span style="font-size: 12px; color: var(--text-secondary);"><%= pimage != null && !pimage.isEmpty() ? pimage.substring(pimage.lastIndexOf("/") + 1) : "N/A" %></span></td>
                            <td>
                                <div class="actions-cell">
                                    <a href="edit.jsp?id=<%= id %>" class="btn-edit-sm">
                                        <i class="fas fa-edit"></i>
                                        Edit
                                    </a>
                                    <form action="deleteProduct" method="post" style="margin:0;" onsubmit="return confirm('Are you sure you want to delete this product?');">
                                        <input type="hidden" name="id" value="<%= id %>">
                                        <button type="submit" class="btn-danger-sm">
                                            <i class="fas fa-trash-alt"></i>
                                            Delete
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                                
                                if (!hasProducts) {
                        %>
                        <tr>
                            <td colspan="8">
                                <div class="empty-state">
                                    <div class="empty-state-icon">
                                        <i class="fas fa-box-open"></i>
                                    </div>
                                    <h3>No Products Found</h3>
                                    <p>You haven't added any products yet. Start by adding your first product to the inventory.</p>
                                    <a href="addprod.jsp" class="btn btn-primary" style="margin-top: 12px;">
                                        <i class="fas fa-plus"></i>
                                        Add Your First Product
                                    </a>
                                </div>
                            </td>
                        </tr>
                        <%
                                }
                            } catch (Exception e) {
                        %>
                        <tr>
                            <td colspan="8">
                                <div class="error-state">
                                    <div class="error-state-icon">
                                        <i class="fas fa-exclamation-circle"></i>
                                    </div>
                                    <h3>Error Loading Products</h3>
                                    <p><%= e.getMessage() %></p>
                                </div>
                            </td>
                        </tr>
                        <%
                            } finally {
                                if (res != null) try { res.close(); } catch(Exception e) {}
                                if (pst != null) try { pst.close(); } catch(Exception e) {}
                                if (con != null) try { con.close(); } catch(Exception e) {}
                            }
                        %>
                    </tbody>
                </table>
                
                <div class="table-footer">
                    <div class="table-footer-info">
                        Showing <strong><%= totalProducts %></strong> product(s) from your inventory
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Search functionality
        document.getElementById('searchInput').addEventListener('keyup', function() {
            const searchTerm = this.value.toLowerCase();
            const tableRows = document.querySelectorAll('#productTableBody tr');
            
            tableRows.forEach(row => {
                const productName = row.querySelector('.pname')?.textContent.toLowerCase() || '';
                const description = row.querySelector('.desc-cell')?.textContent.toLowerCase() || '';
                const category = row.querySelector('.category-badge')?.textContent.toLowerCase() || '';
                
                if (productName.includes(searchTerm) || description.includes(searchTerm) || category.includes(searchTerm)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    </script>
</body>
</html>
