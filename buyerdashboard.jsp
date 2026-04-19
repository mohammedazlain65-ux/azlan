<%-- 
    Document   : buyerdashboard
    Modified   : Multi-image sliding gallery per product card + ProductImagesServlet
--%>

<%@page import="java.util.HashMap"%>
<%@page import="java.util.HashSet"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    String password = null;
    try {
        username = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(username == null || password == null || username.equals("") || password.equals("")) {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        }
    } catch(Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); 
    }

    String ctxPath = request.getContextPath();
    
    HashSet<Integer> wishlistIds = new HashSet<Integer>();
    Connection connWishCheck = null;
    PreparedStatement pstmtWishCheck = null;
    ResultSet rsWishCheck = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        connWishCheck = DriverManager.getConnection("jdbc:mysql://localhost:3306/multi_vendor", "root", "");
        String wishCheckSql = "SELECT product_id FROM wishlist WHERE user_email = ?";
        pstmtWishCheck = connWishCheck.prepareStatement(wishCheckSql);
        pstmtWishCheck.setString(1, username);
        rsWishCheck = pstmtWishCheck.executeQuery();
        while(rsWishCheck.next()) {
            wishlistIds.add(rsWishCheck.getInt("product_id"));
        }
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        try { 
            if(rsWishCheck!=null) rsWishCheck.close(); 
            if(pstmtWishCheck!=null) pstmtWishCheck.close(); 
            if(connWishCheck!=null) connWishCheck.close(); 
        } catch(Exception ig){}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MarketHub - Shop</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary:   #6366f1;
            --secondary: #8b5cf6;
            --dark-bg:   #1e293b;
            --light-bg:  #f8fafc;
            --success:   #10b981;
            --danger:    #ef4444;
            --warning:   #f59e0b;
            --info:      #06b6d4;
            --txt:       #0f172a;
            --txt-m:     #64748b;
            --border:    #e2e8f0;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Outfit',sans-serif; background:linear-gradient(135deg,#f0f4ff,#e5edff); min-height:100vh; }

        /* ── Alert ── */
        .alert-custom { border-radius:16px; padding:20px 25px; margin-bottom:30px; border:none; box-shadow:0 4px 15px rgba(0,0,0,.08); animation:slideInDown .5s ease; display:flex; align-items:center; gap:15px; font-weight:600; }
        @keyframes slideInDown { from{opacity:0;transform:translateY(-20px)} to{opacity:1;transform:translateY(0)} }
        .alert-custom.success { background:linear-gradient(135deg,rgba(16,185,129,.15),rgba(5,150,105,.15)); color:#059669; border-left:4px solid var(--success); }
        .alert-custom.error   { background:linear-gradient(135deg,rgba(239,68,68,.15),rgba(220,38,38,.15));   color:#dc2626; border-left:4px solid var(--danger); }
        .alert-custom.warning { background:linear-gradient(135deg,rgba(245,158,11,.15),rgba(217,119,6,.15));  color:#d97706; border-left:4px solid var(--warning); }
        .alert-custom i { font-size:24px; }

        /* ── Top strip ── */
        .top-header { background:var(--dark-bg); color:white; padding:12px 0; font-size:13px; }
        .top-header a { color:rgba(255,255,255,.75); text-decoration:none; transition:color .3s; }
        .top-header a:hover { color:var(--primary); }

        /* ── Main header ── */
        .main-header { background:white; padding:20px 0; box-shadow:0 4px 20px rgba(0,0,0,.08); position:sticky; top:0; z-index:999; }
        .logo { font-size:32px; font-weight:800; color:var(--txt); text-decoration:none; display:flex; align-items:center; gap:12px; letter-spacing:-.5px; transition:all .3s; }
        .logo i { background:linear-gradient(135deg,var(--primary),var(--secondary)); -webkit-background-clip:text; -webkit-text-fill-color:transparent; background-clip:text; }
        .logo:hover { transform:translateY(-2px); }
        .search-bar { position:relative; flex:1; max-width:600px; margin:0 30px; }
        .search-bar input { width:100%; padding:14px 50px 14px 20px; border:2px solid var(--border); border-radius:12px; font-size:15px; transition:all .3s; font-weight:500; font-family:'Outfit',sans-serif; }
        .search-bar input:focus { outline:none; border-color:var(--primary); box-shadow:0 0 0 4px rgba(99,102,241,.1); }
        .search-bar button { position:absolute; right:5px; top:50%; transform:translateY(-50%); background:linear-gradient(135deg,var(--primary),var(--secondary)); border:none; padding:10px 20px; border-radius:8px; color:white; cursor:pointer; transition:all .3s; }
        .search-bar button:hover { transform:translateY(-50%) scale(1.05); box-shadow:0 4px 15px rgba(99,102,241,.4); }
        .header-actions { display:flex; gap:20px; align-items:center; }
        .header-action { color:var(--txt); text-decoration:none; display:flex; flex-direction:column; align-items:center; transition:all .3s; position:relative; padding:10px 15px; border-radius:12px; }
        .header-action:hover { background:linear-gradient(135deg,rgba(99,102,241,.1),rgba(139,92,246,.1)); transform:translateY(-2px); }
        .header-action i { font-size:24px; margin-bottom:3px; color:var(--primary); }
        .header-action span { font-size:12px; font-weight:600; color:var(--txt-m); }
        .badge-count { position:absolute; top:5px; right:10px; background:linear-gradient(135deg,var(--danger),#dc2626); color:white; border-radius:50%; width:22px; height:22px; display:flex; align-items:center; justify-content:center; font-size:11px; font-weight:700; border:2px solid white; }
        .profile-dropdown { position:relative; display:inline-block; }
        .dropdown-menu-custom { display:none; position:absolute; top:100%; right:0; background:white; min-width:240px; box-shadow:0 10px 40px rgba(0,0,0,.15); border-radius:16px; margin-top:12px; z-index:1000; overflow:hidden; border:1px solid var(--border); }
        .profile-dropdown:hover .dropdown-menu-custom { display:block; animation:fadeInDown .3s ease; }
        @keyframes fadeInDown { from{opacity:0;transform:translateY(-10px)} to{opacity:1;transform:translateY(0)} }
        .dropdown-item-custom { display:flex; align-items:center; padding:14px 18px; color:var(--txt); text-decoration:none; transition:all .3s; border-bottom:1px solid var(--border); gap:12px; font-weight:600; font-size:14px; }
        .dropdown-item-custom:last-child { border-bottom:none; }
        .dropdown-item-custom:hover { background:linear-gradient(135deg,rgba(99,102,241,.08),rgba(139,92,246,.08)); padding-left:23px; }
        .dropdown-item-custom i { font-size:18px; width:20px; text-align:center; color:var(--primary); }

        /* ── Categories nav ── */
        .categories-bar { background:white; box-shadow:0 2px 10px rgba(0,0,0,.05); }
        .categories-bar .nav { display:flex; justify-content:center; flex-wrap:wrap; }
        .categories-bar .nav-link { color:var(--txt); padding:16px 24px; transition:all .3s; font-weight:600; font-size:15px; position:relative; }
        .categories-bar .nav-link::after { content:''; position:absolute; bottom:0; left:50%; transform:translateX(-50%); width:0; height:3px; background:linear-gradient(90deg,var(--primary),var(--secondary)); transition:width .3s; }
        .categories-bar .nav-link:hover, .categories-bar .nav-link.active { color:var(--primary); }
        .categories-bar .nav-link:hover::after, .categories-bar .nav-link.active::after { width:80%; }
        .categories-bar .nav-link i { margin-right:8px; }

        /* ── Products header ── */
        .products-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:30px; background:white; padding:20px 30px; border-radius:16px; box-shadow:0 2px 15px rgba(0,0,0,.05); flex-wrap:wrap; gap:15px; }
        .products-header h2 { font-size:28px; font-weight:800; color:var(--txt); margin:0; }
        .products-count { color:var(--txt-m); font-weight:600; font-size:15px; }
        .sort-dropdown { display:flex; align-items:center; gap:12px; }
        .sort-dropdown label { font-weight:600; color:var(--txt); font-size:15px; }
        .sort-dropdown select { padding:10px 16px; border:2px solid var(--border); border-radius:10px; font-weight:600; color:var(--txt); cursor:pointer; transition:all .3s; background:white; font-family:'Outfit',sans-serif; }
        .sort-dropdown select:focus { outline:none; border-color:var(--primary); box-shadow:0 0 0 4px rgba(99,102,241,.1); }

        /* ── Product Card ── */
        .product-card { background:white; border-radius:20px; overflow:hidden; transition:all .3s; border:2px solid var(--border); height:100%; display:flex; flex-direction:column; }
        .product-card:hover { transform:translateY(-8px); box-shadow:0 15px 40px rgba(0,0,0,.12); border-color:var(--primary); }

        /* ══════════════════════════════════════════
           IMAGE SLIDER
        ══════════════════════════════════════════ */
        .product-image {
            position: relative;
            width: 100%;
            aspect-ratio: 1 / 1;
            overflow: hidden;
            background: #f0f4ff;
        }

        /* Slider track — all slides laid out horizontally */
        .slider-track {
            display: flex;
            width: 100%;
            height: 100%;
            transition: transform 0.45s cubic-bezier(.4,0,.2,1);
        }

        /* Each slide fills the container exactly */
        .slide {
            flex: 0 0 100%;
            width: 100%;
            height: 100%;
            position: relative;
        }

        .slide img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center;
            display: block;
        }

        /* Skeleton shimmer shown while image loads */
        .img-skeleton {
            position: absolute;
            inset: 0;
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200% 100%;
            animation: shimmer 1.4s infinite;
            z-index: 1;
        }
        @keyframes shimmer { 0%{background-position:200% 0} 100%{background-position:-200% 0} }

        /* Placeholder when no image */
        .img-placeholder {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #f0f4ff 0%, #e5edff 100%);
            color: var(--txt-m);
            gap: 10px;
        }
        .img-placeholder i    { font-size: 52px; opacity: .30; }
        .img-placeholder span { font-size: 13px; font-weight: 700; opacity: .55; text-align: center; padding: 0 14px; letter-spacing: .3px; }

        /* Prev / Next arrow buttons */
        .slider-btn {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            width: 32px;
            height: 32px;
            border-radius: 50%;
            border: none;
            background: rgba(255,255,255,0.92);
            color: var(--txt);
            font-size: 13px;
            cursor: pointer;
            z-index: 10;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 10px rgba(0,0,0,.15);
            transition: all .25s ease;
            opacity: 0;
            pointer-events: none;
        }
        .product-image:hover .slider-btn { opacity: 1; pointer-events: all; }
        .slider-btn:hover { background: var(--primary); color: white; transform: translateY(-50%) scale(1.08); box-shadow: 0 4px 16px rgba(99,102,241,.4); }
        .slider-btn.prev { left: 10px; }
        .slider-btn.next { right: 10px; }
        /* Hide arrows when only 1 image — controlled via JS by adding .single */
        .product-image.single .slider-btn { display: none !important; }

        /* Dot navigation */
        .slider-dots {
            position: absolute;
            bottom: 10px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 6px;
            z-index: 10;
        }
        .dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: rgba(255,255,255,0.55);
            border: 1.5px solid rgba(255,255,255,0.8);
            cursor: pointer;
            transition: all .25s ease;
        }
        .dot.active {
            background: white;
            transform: scale(1.25);
            box-shadow: 0 0 6px rgba(99,102,241,.5);
        }
        /* Hide dots when only 1 image */
        .product-image.single .slider-dots { display: none !important; }

        /* Image count badge top-right (shown when >1 image) */
        .img-count-badge {
            position: absolute;
            top: 10px;
            right: 56px; /* offset from wishlist button */
            background: rgba(0,0,0,0.55);
            color: white;
            font-size: 11px;
            font-weight: 700;
            padding: 3px 9px;
            border-radius: 20px;
            z-index: 10;
            backdrop-filter: blur(4px);
            display: none; /* shown by JS when >1 image */
        }

        /* Loading spinner for async image fetch */
        .slider-loading {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #f0f4ff, #e5edff);
            z-index: 5;
        }
        .spinner {
            width: 36px;
            height: 36px;
            border: 3px solid rgba(99,102,241,.2);
            border-top-color: var(--primary);
            border-radius: 50%;
            animation: spin .7s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* Badges */
        .product-badge { position:absolute; top:15px; left:15px; background:linear-gradient(135deg,var(--danger),#dc2626); color:white; padding:6px 14px; border-radius:8px; font-weight:700; font-size:12px; z-index:8; box-shadow:0 4px 12px rgba(239,68,68,.3); }
        .product-badge.new { background:linear-gradient(135deg,var(--success),#059669); box-shadow:0 4px 12px rgba(16,185,129,.3); }

        /* Wishlist button */
        .product-wishlist { 
            position:absolute; top:15px; right:15px; background:white; 
            width:40px; height:40px; border-radius:50%; 
            display:flex; align-items:center; justify-content:center; 
            cursor:pointer; transition:all .3s; z-index:8; 
            box-shadow:0 4px 12px rgba(0,0,0,.1); 
        }
        .product-wishlist:hover { background:var(--primary); transform:scale(1.1); }
        .product-wishlist i { color:var(--txt-m); font-size:18px; transition:all .3s; }
        .product-wishlist:hover i { color:white; }
        .product-wishlist.active { background:linear-gradient(135deg, #fce7f3, #fbcfe8); }
        .product-wishlist.active i { color:var(--danger); }
        .product-wishlist.active:hover { background:var(--danger); }
        .product-wishlist.active:hover i { color:white; }

        /* Product info */
        .product-info { padding:20px; flex:1; display:flex; flex-direction:column; }
        .product-category { color:var(--txt-m); font-size:13px; font-weight:600; text-transform:uppercase; letter-spacing:.5px; margin-bottom:8px; }
        .product-name { font-size:16px; font-weight:700; color:var(--txt); margin-bottom:10px; line-height:1.4; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
        .product-rating { display:flex; align-items:center; gap:8px; margin-bottom:12px; }
        .stars { color:var(--warning); font-size:14px; }
        .rating-count { color:var(--txt-m); font-size:13px; font-weight:600; }
        .product-price { display:flex; align-items:center; gap:10px; margin-bottom:15px; flex-wrap:wrap; }
        .current-price { font-size:24px; font-weight:800; color:var(--primary); }
        .original-price { font-size:16px; color:var(--txt-m); text-decoration:line-through; font-weight:600; }
        .discount-badge { background:linear-gradient(135deg,var(--success),#059669); color:white; padding:4px 10px; border-radius:6px; font-size:12px; font-weight:700; }
        .product-actions { display:flex; gap:10px; margin-top:auto; }
        .btn-add-cart { flex:1; background:linear-gradient(135deg,var(--primary),var(--secondary)); color:white; border:none; padding:12px; border-radius:12px; font-weight:700; transition:all .3s; cursor:pointer; font-size:14px; font-family:'Outfit',sans-serif; }
        .btn-add-cart:hover { transform:translateY(-2px); box-shadow:0 8px 25px rgba(99,102,241,.4); }
        .btn-buy-now { background:linear-gradient(135deg,var(--success),#059669); color:white; border:none; padding:12px 18px; border-radius:12px; font-weight:700; transition:all .3s; cursor:pointer; font-size:14px; white-space:nowrap; font-family:'Outfit',sans-serif; }
        .btn-buy-now:hover { transform:translateY(-2px); box-shadow:0 8px 25px rgba(16,185,129,.4); }
        .stock-tag { font-size:12px; font-weight:700; margin-bottom:10px; display:flex; align-items:center; gap:5px; }
        .stock-tag.in  { color:var(--success); }
        .stock-tag.out { color:var(--danger); }

        /* ── Empty state ── */
        .no-results { text-align:center; padding:60px 20px; background:white; border-radius:20px; border:2px dashed var(--border); display:none; }
        .no-results i { font-size:64px; color:var(--primary); opacity:.25; display:block; margin-bottom:16px; }
        .no-results h3 { font-size:22px; font-weight:800; color:var(--txt); margin-bottom:8px; }
        .no-results p  { color:var(--txt-m); font-weight:500; }

        /* ── Pagination ── */
        .pagination-wrapper { display:flex; justify-content:center; margin-top:50px; }
        .pagination-custom { display:flex; gap:10px; list-style:none; padding:0; }
        .pagination-custom li a { display:flex; align-items:center; justify-content:center; width:45px; height:45px; border:2px solid var(--border); border-radius:12px; color:var(--txt); text-decoration:none; font-weight:700; transition:all .3s; }
        .pagination-custom li a:hover, .pagination-custom li.active a { background:linear-gradient(135deg,var(--primary),var(--secondary)); color:white; border-color:transparent; transform:translateY(-3px); box-shadow:0 6px 20px rgba(99,102,241,.4); }

        /* ── Footer ── */
        .footer { background:var(--dark-bg); color:white; padding:60px 0 30px; margin-top:60px; }
        .footer-bottom { border-top:1px solid rgba(255,255,255,.1); margin-top:50px; padding-top:30px; text-align:center; color:rgba(255,255,255,.6); font-weight:500; }

        @media(max-width:768px) { 
            .products-header { flex-direction:column; gap:15px; align-items:flex-start; }
            .slider-btn { opacity: 1; pointer-events: all; width:28px; height:28px; font-size:11px; }
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
                <a href="#"><i class="fas fa-map-marker-alt"></i> Track Order</a>
                <a href="#" class="ms-3"><i class="fas fa-headset"></i> Customer Support</a>
            </div>
        </div>
    </div>
</div>

<!-- Main Header -->
<header class="main-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-lg-2 col-md-12 text-center text-lg-start mb-3 mb-lg-0">
                <a href="buyerdashboard.jsp" class="logo">
                    <i class="fas fa-shopping-bag"></i><span>MarketHub</span>
                </a>
            </div>
            <div class="col-lg-6 col-md-12 mb-3 mb-lg-0">
                <div class="search-bar">
                    <input type="text" id="searchInput" placeholder="Search for products, brands, and more...">
                    <button type="button" onclick="applyFilters()"><i class="fas fa-search"></i></button>
                </div>
            </div>
            <div class="col-lg-4 col-md-12">
                <div class="header-actions">
                    <a href="Wishlist.jsp" class="header-action">
                        <i class="fas fa-heart"></i><span>Wishlist</span>
                        <%
                        Connection connWish = null; PreparedStatement pstmtWish = null; ResultSet rsWish = null; int wishCount = 0;
                        try {
                            Class.forName("com.mysql.jdbc.Driver");
                            connWish = DriverManager.getConnection("jdbc:mysql://localhost:3306/multi_vendor","root","");
                            String wishSql = "SELECT COUNT(*) as total FROM wishlist WHERE user_email = ?";
                            pstmtWish = connWish.prepareStatement(wishSql);
                            pstmtWish.setString(1, username);
                            rsWish = pstmtWish.executeQuery();
                            if(rsWish.next()) wishCount = rsWish.getInt("total");
                        } catch(Exception e) { e.printStackTrace(); }
                        finally { try{if(rsWish!=null)rsWish.close();if(pstmtWish!=null)pstmtWish.close();if(connWish!=null)connWish.close();}catch(Exception ig){} }
                        if(wishCount>0) { %><div class="badge-count"><%= wishCount %></div><% } %>
                    </a>
                    <a href="cart.jsp" class="header-action">
                        <i class="fas fa-shopping-cart"></i><span>Cart</span>
                        <%
                        HashMap<Integer,Integer> headerCart = (HashMap<Integer,Integer>) session.getAttribute("cart");
                        int cartCount = 0;
                        if(headerCart!=null) for(int qty:headerCart.values()) cartCount+=qty;
                        if(cartCount>0){%><div class="badge-count"><%= cartCount %></div><%}%>
                    </a>
                    <div class="profile-dropdown">
                        <a href="#" class="header-action">
                            <i class="fas fa-user-circle"></i>
                            <span><%= username!=null&&username.contains("@")?username.split("@")[0]:"Account" %></span>
                        </a>
                        <div class="dropdown-menu-custom">
                            <a href="updatesellerprofile.jsp" class="dropdown-item-custom"><i class="fas fa-user"></i> My Profile</a>
                            <a href="myorders.jsp"            class="dropdown-item-custom"><i class="fas fa-box"></i> My Orders</a>
                            <a href="Wishlist.jsp"            class="dropdown-item-custom"><i class="fas fa-heart"></i> My Wishlist</a>
                            <a href="#"                       class="dropdown-item-custom"><i class="fas fa-cog"></i> Settings</a>
                            <a href="ulogout"                 class="dropdown-item-custom"><i class="fas fa-sign-out-alt"></i> Logout</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- Categories Bar -->
<nav class="categories-bar">
    <div class="container">
        <ul class="nav" id="catNav">
            <li class="nav-item"><a class="nav-link active" href="#" data-cat="all"><i class="fas fa-th-large"></i> All Categories</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="electronics"><i class="fas fa-laptop"></i> Electronics</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="clothing"><i class="fas fa-tshirt"></i> Fashion</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="books"><i class="fas fa-book"></i> Books</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="home"><i class="fas fa-home"></i> Home &amp; Kitchen</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="sports"><i class="fas fa-dumbbell"></i> Sports</a></li>
            <li class="nav-item"><a class="nav-link" href="#" data-cat="toys"><i class="fas fa-gamepad"></i> Toys &amp; Games</a></li>
        </ul>
    </div>
</nav>

<!-- Main Content -->
<div style="padding:40px 0;">
    <div class="container">

        <%
        String wishlistMessage = (String)session.getAttribute("wishlistMessage");
        String wishlistMessageType = (String)session.getAttribute("wishlistMessageType");
        if(wishlistMessage!=null&&!wishlistMessage.isEmpty()){%>
        <div class="alert-custom <%= wishlistMessageType %>">
            <i class="fas fa-<%= "success".equals(wishlistMessageType)?"check-circle":("error".equals(wishlistMessageType)?"times-circle":"exclamation-triangle") %>"></i>
            <span><%= wishlistMessage %></span>
        </div><%
            session.removeAttribute("wishlistMessage"); session.removeAttribute("wishlistMessageType");
        }
        String cartMessage = (String)session.getAttribute("cartMessage");
        String cartMessageType = (String)session.getAttribute("cartMessageType");
        if(cartMessage!=null&&!cartMessage.isEmpty()){%>
        <div class="alert-custom <%= cartMessageType %>">
            <i class="fas fa-<%= "success".equals(cartMessageType)?"check-circle":("error".equals(cartMessageType)?"times-circle":"exclamation-triangle") %>"></i>
            <span><%= cartMessage %></span>
        </div><%
            session.removeAttribute("cartMessage"); session.removeAttribute("cartMessageType");
        }%>

        <%
        String dbURL="jdbc:mysql://localhost:3306/multi_vendor"; String dbUser="root"; String dbPass="";
        Connection conn=null; Statement stmt=null; ResultSet rs=null; int totalProducts=0;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(dbURL,dbUser,dbPass);
            stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_READ_ONLY);
            rs   = stmt.executeQuery("SELECT * FROM adprod ORDER BY id DESC");
            rs.last(); totalProducts=rs.getRow(); rs.beforeFirst();
        %>

        <!-- Products header -->
        <div class="products-header">
            <div>
                <h2>Featured Products</h2>
                <span class="products-count">Showing <strong id="visibleCount"><%= totalProducts %></strong> of <%= totalProducts %> product<%= totalProducts!=1?"s":"" %></span>
            </div>
            <div class="sort-dropdown">
                <label>Sort by:</label>
                <select id="sortSelect" onchange="sortProducts()">
                    <option value="default">Popularity</option>
                    <option value="low">Price: Low to High</option>
                    <option value="high">Price: High to Low</option>
                    <option value="name">Name A–Z</option>
                    <option value="newest">Newest First</option>
                </select>
            </div>
        </div>

        <!-- Products Grid -->
        <div class="row g-4" id="productsGrid">
        <%
        if(totalProducts>0){
            while(rs.next()){
                int    pid     = rs.getInt("id");
                String pname   = rs.getString("pname");
                String qty     = rs.getString("quantity");
                String rateStr = rs.getString("rate");
                String cat     = rs.getString("category");
                String pimage  = rs.getString("pimage");

                double price = 0;
                try { price = Double.parseDouble(rateStr); } catch(Exception ex){}
                double origPrice = price*1.35;
                int disc = origPrice>0&&price>0?(int)(((origPrice-price)/origPrice)*100):0;

                boolean hasImg = (pimage!=null&&!pimage.trim().isEmpty()&&!pimage.equalsIgnoreCase("null")&&!pimage.equals("0"));
                String imgSrc  = hasImg?(ctxPath+"/"+pimage):"";

                String catLow  = (cat!=null?cat:"").toLowerCase();
                String catIcon = catLow.contains("cloth")||catLow.contains("fashion")?"fa-tshirt"
                               : catLow.contains("elec") ?"fa-laptop"
                               : catLow.contains("book") ?"fa-book"
                               : catLow.contains("sport")?"fa-dumbbell"
                               : catLow.contains("home") ?"fa-couch"
                               : catLow.contains("toy")  ?"fa-gamepad"
                               :"fa-box-open";

                String safeName  = pname.replace("'","").replace("\"","");
                boolean inStock  = qty!=null&&!qty.equals("0")&&!qty.isEmpty();
                boolean isWished = wishlistIds.contains(pid);
        %>

        <div class="col-xl-3 col-lg-4 col-md-6 col-sm-6 product-col"
             data-price="<%= price %>"
             data-category="<%= catLow %>"
             data-name="<%= safeName.toLowerCase() %>"
             data-pid="<%= pid %>">
            <div class="product-card">

                <%-- ════ IMAGE SLIDER ════
                     - data-pid used by JS to call /productImages?productId=X
                     - Initialised lazily via IntersectionObserver
                --%>
                <div class="product-image" id="imgBox_<%= pid %>" data-pid="<%= pid %>"
                     data-fallback="<%= imgSrc %>"
                     data-caticon="<%= catIcon %>"
                     data-pname="<%= safeName %>">

                    <%-- Loading spinner shown until JS replaces it --%>
                    <div class="slider-loading" id="spin_<%= pid %>">
                        <div class="spinner"></div>
                    </div>

                    <%-- Prev / Next buttons (shown on hover via CSS) --%>
                    <button class="slider-btn prev" onclick="slideImage('<%= pid %>',-1,event)" aria-label="Previous image">
                        <i class="fas fa-chevron-left"></i>
                    </button>
                    <button class="slider-btn next" onclick="slideImage('<%= pid %>',1,event)" aria-label="Next image">
                        <i class="fas fa-chevron-right"></i>
                    </button>

                    <%-- Dot container — dots injected by JS --%>
                    <div class="slider-dots" id="dots_<%= pid %>"></div>

                    <%-- Image count badge --%>
                    <div class="img-count-badge" id="countBadge_<%= pid %>"></div>

                    <%-- Discount / NEW badge --%>
                    <% if(disc>0){ %><div class="product-badge">-<%= disc %>%</div>
                    <% }else{ %><div class="product-badge new">NEW</div><% } %>

                    <%-- Wishlist button --%>
                    <div class="product-wishlist <%= isWished?"active":"" %>"
                         onclick="toggleWishlist(<%= pid %>,this,event)">
                        <i class="<%= isWished?"fas":"far" %> fa-heart"></i>
                    </div>
                </div><%-- /product-image --%>

                <div class="product-info">
                    <div class="product-category"><%= cat!=null&&!cat.isEmpty()?cat.toUpperCase():"GENERAL" %></div>
                    <h3 class="product-name"><%= pname %></h3>
                    <div class="product-rating">
                        <div class="stars">★★★★<span style="opacity:.4;">★</span></div>
                        <span class="rating-count">(4.5)</span>
                    </div>
                    <div class="product-price">
                        <span class="current-price">₹<%= String.format("%.0f",price) %></span>
                        <% if(disc>0){ %>
                            <span class="original-price">₹<%= String.format("%.0f",origPrice) %></span>
                            <span class="discount-badge"><%= disc %>% OFF</span>
                        <% } %>
                    </div>
                    <div class="stock-tag <%= inStock?"in":"out" %>">
                        <i class="fas fa-<%= inStock?"check-circle":"times-circle" %>"></i>
                        <%= inStock?"In Stock: "+qty+" units":"Out of Stock" %>
                    </div>
                    <div class="product-actions">
                        <button class="btn-add-cart" onclick="addToCart(<%= pid %>)" <%= inStock?"":"disabled style='opacity:.5;cursor:not-allowed;'" %>>
                            <i class="fas fa-shopping-cart"></i> Add to Cart
                        </button>
                        <button class="btn-buy-now" onclick="buyNow(<%= pid %>)" <%= inStock?"":"disabled style='opacity:.5;cursor:not-allowed;'" %>>
                            <i class="fas fa-bolt"></i> Buy
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <%  } // end while
        } else { %>
            <div class="col-12">
                <div class="alert alert-info text-center" style="padding:40px;border-radius:16px;">
                    <i class="fas fa-info-circle" style="font-size:48px;color:#06b6d4;margin-bottom:20px;display:block;"></i>
                    <h3>No Products Yet</h3>
                    <p>No products in the database. Sellers need to add products first.</p>
                </div>
            </div>
        <% } %>
        </div><%-- /productsGrid --%>

        <div class="no-results" id="noResults">
            <i class="fas fa-search"></i>
            <h3>No Products Found</h3>
            <p>Try adjusting your search or filters.</p>
        </div>

        <%
        } catch(Exception e) {
            out.println("<div class='alert alert-danger' style='border-radius:16px;padding:20px;'>");
            out.println("<i class='fas fa-exclamation-triangle'></i> <strong>DB Error:</strong> "+e.getMessage());
            out.println("</div>");
        } finally {
            try{if(rs!=null)rs.close();if(stmt!=null)stmt.close();if(conn!=null)conn.close();}catch(Exception ig){}
        }
        %>

        <!-- Pagination -->
        <div class="pagination-wrapper">
            <ul class="pagination-custom">
                <li><a href="#"><i class="fas fa-chevron-left"></i></a></li>
                <li class="active"><a href="#">1</a></li>
                <li><a href="#">2</a></li>
                <li><a href="#">3</a></li>
                <li><a href="#"><i class="fas fa-chevron-right"></i></a></li>
            </ul>
        </div>
    </div>
</div>

<!-- Footer -->
<footer class="footer">
    <div class="container">
        <div class="footer-bottom"><p>&copy; 2025 MarketHub. All rights reserved.</p></div>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ════════════════════════════════════════════════════════════════
   IMAGE SLIDER ENGINE
   - Per-product state stored in sliderState map (pid → {imgs,idx})
   - Images fetched from /productImages?productId=X (JSON array)
   - Lazy initialisation via IntersectionObserver
════════════════════════════════════════════════════════════════ */
const sliderState = {};  // pid → { imgs:[], idx:0 }
const CTX_PATH    = '<%= ctxPath %>';

/**
 * Fetch images for a product from the servlet and build the slider.
 * Called once per card when it first enters the viewport.
 */
function initSlider(pid) {
    const box = document.getElementById('imgBox_' + pid);
    if (!box || box.dataset.loaded === '1') return;
    box.dataset.loaded = '1';

    const fallback = box.dataset.fallback   || '';
    const catIcon  = box.dataset.caticon    || 'fa-box-open';
    const pname    = box.dataset.pname      || '';

    fetch(CTX_PATH + '/productImages?productId=' + pid)
        .then(function(r) { return r.json(); })
        .then(function(images) {
            buildSlider(pid, images, fallback, catIcon, pname);
        })
        .catch(function() {
            // Network error — degrade gracefully with fallback
            buildSlider(pid, [], fallback, catIcon, pname);
        });
}

/**
 * Build slider DOM from the images array returned by the servlet.
 */
function buildSlider(pid, images, fallback, catIcon, pname) {
    const box     = document.getElementById('imgBox_' + pid);
    const spinEl  = document.getElementById('spin_' + pid);
    const dotsEl  = document.getElementById('dots_' + pid);
    const badgeEl = document.getElementById('countBadge_' + pid);

    if (!box) return;

    // Remove spinner
    if (spinEl) spinEl.remove();

    // If servlet returns empty array, use fallback pimage
    if (!images || images.length === 0) {
        if (fallback && fallback.trim() !== '') {
            images = [fallback.replace(/^\//, '')];   // strip leading slash if any
        } else {
            images = [];
        }
    }

    // Store state
    sliderState[pid] = { imgs: images, idx: 0 };

    if (images.length === 0) {
        // No image at all — show placeholder
        const ph = document.createElement('div');
        ph.className = 'img-placeholder';
        ph.innerHTML = '<i class="fas ' + catIcon + '"></i><span>' + escHtml(pname) + '</span>';
        box.insertBefore(ph, box.querySelector('.slider-btn.prev'));
        box.classList.add('single');
        return;
    }

    // Build slider track with one slide per image
    const track = document.createElement('div');
    track.className = 'slider-track';
    track.id = 'track_' + pid;

    images.forEach(function(imgPath, i) {
        const slide = document.createElement('div');
        slide.className = 'slide';

        // Skeleton shimmer
        const sk = document.createElement('div');
        sk.className = 'img-skeleton';
        sk.id = 'sk_' + pid + '_' + i;

        const img = document.createElement('img');
        img.loading = 'lazy';
        img.alt     = pname;

        // Build absolute URL — handle paths with or without ctxPath
        if (imgPath.startsWith('http')) {
            img.src = imgPath;
        } else {
            img.src = CTX_PATH + '/' + imgPath.replace(/^\//, '');
        }

        img.onload  = function() { sk.style.display = 'none'; };
        img.onerror = function() {
            sk.style.display = 'none';
            img.style.display = 'none';
            // inject placeholder into slide
            var ph2 = document.createElement('div');
            ph2.className = 'img-placeholder';
            ph2.innerHTML = '<i class="fas ' + catIcon + '"></i><span>' + escHtml(pname) + '</span>';
            slide.appendChild(ph2);
        };

        slide.appendChild(sk);
        slide.appendChild(img);
        track.appendChild(slide);
    });

    // Insert track before the first .slider-btn
    const firstBtn = box.querySelector('.slider-btn.prev');
    box.insertBefore(track, firstBtn);

    // Build dots
    images.forEach(function(_, i) {
        const dot = document.createElement('div');
        dot.className = 'dot' + (i === 0 ? ' active' : '');
        dot.onclick   = function(e) { e.stopPropagation(); goToSlide(pid, i); };
        dotsEl.appendChild(dot);
    });

    // Show count badge if more than 1 image
    if (images.length > 1) {
        badgeEl.textContent  = '1 / ' + images.length;
        badgeEl.style.display = 'block';
    } else {
        box.classList.add('single');   // hides arrows + dots via CSS
    }
}

/** Navigate by delta (-1 = prev, +1 = next) */
function slideImage(pid, delta, evt) {
    if (evt) { evt.stopPropagation(); evt.preventDefault(); }
    const state = sliderState[pid];
    if (!state || state.imgs.length <= 1) return;
    const newIdx = (state.idx + delta + state.imgs.length) % state.imgs.length;
    goToSlide(pid, newIdx);
}

/** Jump directly to a slide index */
function goToSlide(pid, idx) {
    const state = sliderState[pid];
    if (!state) return;

    state.idx = idx;

    // Move track
    const track = document.getElementById('track_' + pid);
    if (track) track.style.transform = 'translateX(-' + (idx * 100) + '%)';

    // Update dots
    const dotsEl = document.getElementById('dots_' + pid);
    if (dotsEl) {
        dotsEl.querySelectorAll('.dot').forEach(function(d, i) {
            d.classList.toggle('active', i === idx);
        });
    }

    // Update count badge
    const badgeEl = document.getElementById('countBadge_' + pid);
    if (badgeEl && state.imgs.length > 1) {
        badgeEl.textContent = (idx + 1) + ' / ' + state.imgs.length;
    }
}

/** Minimal HTML escape for pname in DOM injection */
function escHtml(s) {
    return (s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ── Lazy-initialise sliders as cards enter viewport ── */
(function() {
    const obs = new IntersectionObserver(function(entries) {
        entries.forEach(function(en) {
            if (en.isIntersecting) {
                const box = en.target;
                const pid = box.dataset.pid;
                if (pid) initSlider(pid);
                obs.unobserve(box);
            }
        });
    }, { threshold: 0.05, rootMargin: '100px 0px' });

    document.querySelectorAll('.product-image[data-pid]').forEach(function(box) {
        obs.observe(box);
    });
})();

/* Touch / swipe support for mobile */
(function() {
    document.querySelectorAll('.product-image[data-pid]').forEach(function(box) {
        var startX = 0;
        box.addEventListener('touchstart', function(e) { startX = e.touches[0].clientX; }, { passive: true });
        box.addEventListener('touchend',   function(e) {
            var diff = startX - e.changedTouches[0].clientX;
            if (Math.abs(diff) > 40) slideImage(box.dataset.pid, diff > 0 ? 1 : -1, null);
        }, { passive: true });
    });
})();


/* ════════════════════════════════════════════════════════════════
   WISHLIST / CART / BUY-NOW
════════════════════════════════════════════════════════════════ */
function toggleWishlist(productId, element, evt) {
    evt.stopPropagation(); evt.preventDefault();
    var isActive = element.classList.contains('active');
    window.location.href = 'addtowishlist?action=' + (isActive?'remove':'add') + '&productId=' + productId;
}
function addToCart(id) { window.location.href = 'updatecart.jsp?action=add&productId=' + id; }
function buyNow(id)    { window.location.href = 'buynow.jsp?action=buynow&productId=' + id; }


/* ════════════════════════════════════════════════════════════════
   FILTERS + SORT
════════════════════════════════════════════════════════════════ */
document.getElementById('searchInput').addEventListener('input', applyFilters);

document.querySelectorAll('#catNav .nav-link').forEach(function(link) {
    link.addEventListener('click', function(e) {
        e.preventDefault();
        document.querySelectorAll('#catNav .nav-link').forEach(function(l){ l.classList.remove('active'); });
        this.classList.add('active');
        applyFilters();
    });
});

function applyFilters() {
    var q      = (document.getElementById('searchInput').value || '').toLowerCase().trim();
    var navCat = (document.querySelector('#catNav .nav-link.active') || {dataset:{cat:'all'}}).dataset.cat || 'all';
    var visible = 0;
    document.querySelectorAll('.product-col').forEach(function(col) {
        var name  = col.dataset.name     || '';
        var cat   = col.dataset.category || '';
        var ok = (q===''||name.includes(q)||cat.includes(q)) && (navCat==='all'||cat.includes(navCat));
        col.style.display = ok ? '' : 'none';
        if (ok) visible++;
    });
    var countEl = document.getElementById('visibleCount');
    if (countEl) countEl.textContent = visible;
    var noRes = document.getElementById('noResults');
    if (noRes) noRes.style.display = visible===0?'block':'none';
}

function sortProducts() {
    var mode = document.getElementById('sortSelect').value;
    var grid = document.getElementById('productsGrid');
    var cols = Array.from(grid.querySelectorAll('.product-col'));
    cols.sort(function(a,b){
        var pa=parseFloat(a.dataset.price)||0, pb=parseFloat(b.dataset.price)||0;
        var na=a.dataset.name||'',             nb=b.dataset.name||'';
        var ia=parseInt(a.dataset.pid)||0,     ib=parseInt(b.dataset.pid)||0;
        if(mode==='low')    return pa-pb;
        if(mode==='high')   return pb-pa;
        if(mode==='name')   return na.localeCompare(nb);
        if(mode==='newest') return ib-ia;
        return 0;
    });
    cols.forEach(function(c){ grid.appendChild(c); });
}

/* ── Scroll-in animation for product cards ── */
(function() {
    var cardObs = new IntersectionObserver(function(entries) {
        entries.forEach(function(en) {
            if (en.isIntersecting) {
                en.target.style.opacity   = '1';
                en.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });

    document.querySelectorAll('.product-card').forEach(function(c, i) {
        c.style.opacity    = '0';
        c.style.transform  = 'translateY(30px)';
        c.style.transition = 'all 0.5s ease ' + (i % 8 * 0.06) + 's';
        cardObs.observe(c);
    });
})();

/* ── Auto-hide alerts ── */
document.querySelectorAll('.alert-custom').forEach(function(el) {
    setTimeout(function() {
        el.style.opacity = '0'; el.style.transition = 'opacity .5s';
        setTimeout(function(){ el.remove(); }, 500);
    }, 5000);
});
</script>
</body>
</html>
