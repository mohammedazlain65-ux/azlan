<%-- 
    Document   : wishlist
    Created on : Your Date
    Author     : moham
--%>

<%@page import="java.util.*"%>
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Wishlist - MarketHub</title>
    
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

        /* ── Page Header ── */
        .page-header { background:white; padding:40px 0; margin-bottom:40px; box-shadow:0 4px 20px rgba(0,0,0,.08); }
        .page-header h1 { font-size:42px; font-weight:800; color:var(--txt); margin:0; display:flex; align-items:center; gap:15px; }
        .page-header h1 i { color:var(--danger); }
        .page-header p { color:var(--txt-m); font-size:16px; margin:10px 0 0 0; font-weight:500; }

        /* ── Wishlist Card ── */
        .wishlist-card { background:white; border-radius:20px; padding:25px; margin-bottom:20px; box-shadow:0 4px 20px rgba(0,0,0,.08); border:2px solid var(--border); transition:all .3s; display:flex; gap:25px; align-items:center; }
        .wishlist-card:hover { transform:translateY(-5px); box-shadow:0 10px 35px rgba(0,0,0,.12); border-color:var(--primary); }

        .wishlist-image {
            position: relative;
            width: 180px;
            height: 180px;
            flex-shrink: 0;
            border-radius: 16px;
            overflow: hidden;
            background: #f0f4ff;
        }
        .wishlist-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center;
            transition: transform .3s;
        }
        .wishlist-card:hover .wishlist-image img { transform: scale(1.1); }
        .img-placeholder-wish {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #f0f4ff 0%, #e5edff 100%);
            color: var(--txt-m);
            gap: 10px;
        }
        .img-placeholder-wish i { font-size: 48px; opacity: .30; }
        .img-placeholder-wish span { font-size: 12px; font-weight: 700; opacity: .55; }

        .wishlist-details { flex: 1; }
        .wishlist-category { color:var(--txt-m); font-size:13px; font-weight:600; text-transform:uppercase; letter-spacing:.5px; margin-bottom:8px; }
        .wishlist-name { font-size:22px; font-weight:700; color:var(--txt); margin-bottom:10px; }
        .wishlist-desc { color:var(--txt-m); font-size:14px; margin-bottom:15px; line-height:1.6; }
        .wishlist-price { display:flex; align-items:center; gap:12px; margin-bottom:15px; flex-wrap:wrap; }
        .current-price { font-size:28px; font-weight:800; color:var(--primary); }
        .original-price { font-size:18px; color:var(--txt-m); text-decoration:line-through; font-weight:600; }
        .discount-badge { background:linear-gradient(135deg,var(--success),#059669); color:white; padding:5px 12px; border-radius:6px; font-size:13px; font-weight:700; }
        .stock-status { font-size:14px; font-weight:700; display:flex; align-items:center; gap:6px; }
        .stock-status.in { color:var(--success); }
        .stock-status.out { color:var(--danger); }
        .wishlist-added { color:var(--txt-m); font-size:13px; margin-top:10px; }

        .wishlist-actions { display:flex; flex-direction:column; gap:12px; }
        .btn-action { padding:12px 24px; border-radius:12px; font-weight:700; border:none; cursor:pointer; transition:all .3s; font-size:14px; font-family:'Outfit',sans-serif; text-decoration:none; display:flex; align-items:center; justify-content:center; gap:8px; white-space:nowrap; }
        .btn-add-cart { background:linear-gradient(135deg,var(--primary),var(--secondary)); color:white; }
        .btn-add-cart:hover { transform:translateY(-2px); box-shadow:0 6px 20px rgba(99,102,241,.4); }
        .btn-remove { background:linear-gradient(135deg,var(--danger),#dc2626); color:white; }
        .btn-remove:hover { transform:translateY(-2px); box-shadow:0 6px 20px rgba(239,68,68,.4); }
        .btn-view { background:linear-gradient(135deg,var(--info),#0891b2); color:white; }
        .btn-view:hover { transform:translateY(-2px); box-shadow:0 6px 20px rgba(6,182,212,.4); }

        /* ── Empty State ── */
        .empty-wishlist { background:white; border-radius:20px; padding:60px 40px; text-align:center; box-shadow:0 4px 20px rgba(0,0,0,.08); }
        .empty-wishlist i { font-size:80px; color:var(--txt-m); opacity:.3; margin-bottom:25px; display:block; }
        .empty-wishlist h3 { font-size:28px; font-weight:800; color:var(--txt); margin-bottom:15px; }
        .empty-wishlist p { color:var(--txt-m); font-size:16px; margin-bottom:30px; }
        .btn-shop-now { background:linear-gradient(135deg,var(--primary),var(--secondary)); color:white; padding:14px 35px; border-radius:12px; font-weight:700; text-decoration:none; display:inline-flex; align-items:center; gap:10px; transition:all .3s; font-size:16px; }
        .btn-shop-now:hover { transform:translateY(-3px); box-shadow:0 8px 25px rgba(99,102,241,.4); }

        /* ── Clear All Button ── */
        .clear-all-section { margin-bottom:30px; display:flex; justify-content:space-between; align-items:center; background:white; padding:20px 30px; border-radius:16px; box-shadow:0 2px 15px rgba(0,0,0,.05); }
        .wishlist-count { font-size:18px; font-weight:700; color:var(--txt); }
        .btn-clear-all { background:linear-gradient(135deg,var(--danger),#dc2626); color:white; border:none; padding:12px 24px; border-radius:12px; font-weight:700; cursor:pointer; transition:all .3s; font-family:'Outfit',sans-serif; }
        .btn-clear-all:hover { transform:translateY(-2px); box-shadow:0 6px 20px rgba(239,68,68,.4); }

        @media(max-width:768px){
            .wishlist-card { flex-direction:column; text-align:center; }
            .wishlist-image { width:100%; height:250px; }
            .wishlist-actions { width:100%; }
            .btn-action { width:100%; }
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
                    <input type="text" placeholder="Search for products, brands, and more...">
                    <button type="button"><i class="fas fa-search"></i></button>
                </div>
            </div>
            <div class="col-lg-4 col-md-12">
                <div class="header-actions">
                    <a href="wishlist.jsp" class="header-action">
                        <i class="fas fa-heart"></i><span>Wishlist</span>
                        <%
                        String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor";
                        String dbUser = "root";
                        String dbPass = "";
                        Connection connHeader = null;
                        PreparedStatement pstmtHeader = null;
                        ResultSet rsHeader = null;
                        int wishlistCount = 0;
                        try {
                            Class.forName("com.mysql.jdbc.Driver");
                            connHeader = DriverManager.getConnection(dbURL, dbUser, dbPass);
                            String countSql = "SELECT COUNT(*) as total FROM wishlist WHERE user_email = ?";
                            pstmtHeader = connHeader.prepareStatement(countSql);
                            pstmtHeader.setString(1, username);
                            rsHeader = pstmtHeader.executeQuery();
                            if(rsHeader.next()) wishlistCount = rsHeader.getInt("total");
                        } catch(Exception e) {
                            e.printStackTrace();
                        } finally {
                            try { if(rsHeader!=null)rsHeader.close(); if(pstmtHeader!=null)pstmtHeader.close(); if(connHeader!=null)connHeader.close(); } catch(Exception ig){}
                        }
                        if(wishlistCount > 0) {
                        %><div class="badge-count"><%= wishlistCount %></div><% } %>
                    </a>
                    <a href="cart.jsp" class="header-action">
                        <i class="fas fa-shopping-cart"></i><span>Cart</span>
                        <%
                        HashMap<Integer,Integer> headerCart = (HashMap<Integer,Integer>) session.getAttribute("cart");
                        int cartCount = 0;
                        if(headerCart != null) for(int qty : headerCart.values()) cartCount += qty;
                        if(cartCount > 0) {
                        %><div class="badge-count"><%= cartCount %></div><% } %>
                    </a>
                    <div class="profile-dropdown">
                        <a href="#" class="header-action">
                            <i class="fas fa-user-circle"></i>
                            <span><%= username != null && username.contains("@") ? username.split("@")[0] : "Account" %></span>
                        </a>
                        <div class="dropdown-menu-custom">
                            <a href="#"            class="dropdown-item-custom"><i class="fas fa-user"></i> My Profile</a>
                            <a href="myorders.jsp" class="dropdown-item-custom"><i class="fas fa-box"></i> My Orders</a>
                            <a href="wishlist.jsp" class="dropdown-item-custom"><i class="fas fa-heart"></i> My Wishlist</a>
                            <a href="#"            class="dropdown-item-custom"><i class="fas fa-cog"></i> Settings</a>
                            <a href="ulogout"      class="dropdown-item-custom"><i class="fas fa-sign-out-alt"></i> Logout</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- Page Header -->
<div class="page-header">
    <div class="container">
        <h1><i class="fas fa-heart"></i> My Wishlist</h1>
        <p>Your favorite products saved for later</p>
    </div>
</div>

<!-- Main Content -->
<div style="padding:0 0 60px 0;">
    <div class="container">

        <%
        String wishlistMessage     = (String) session.getAttribute("wishlistMessage");
        String wishlistMessageType = (String) session.getAttribute("wishlistMessageType");
        if(wishlistMessage != null && !wishlistMessage.isEmpty()) {
        %>
        <div class="alert-custom <%= wishlistMessageType %>">
            <i class="fas fa-<%= "success".equals(wishlistMessageType)?"check-circle":("error".equals(wishlistMessageType)?"times-circle":"exclamation-triangle") %>"></i>
            <span><%= wishlistMessage %></span>
        </div>
        <%
            session.removeAttribute("wishlistMessage");
            session.removeAttribute("wishlistMessageType");
        }
        %>

        <%
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        int totalWishlist = 0;
        
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
            
            // Get wishlist items with product details
            String sql = "SELECT w.id as wishlist_id, w.product_id, w.added_date, " +
                        "p.pname, p.rate, p.quantity, p.category, p.pimage, p.description " +
                        "FROM wishlist w " +
                        "INNER JOIN adprod p ON w.product_id = p.id " +
                        "WHERE w.user_email = ? " +
                        "ORDER BY w.added_date DESC";
            
            pstmt = conn.prepareStatement(sql, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            
            rs.last();
            totalWishlist = rs.getRow();
            rs.beforeFirst();
            
            if(totalWishlist > 0) {
        %>
        
        <!-- Clear All Section -->
        <div class="clear-all-section">
            <div class="wishlist-count">
                <i class="fas fa-heart" style="color:var(--danger);"></i>
                <%= totalWishlist %> item<%= totalWishlist!=1?"s":"" %> in your wishlist
            </div>
            <button class="btn-clear-all" onclick="clearAllWishlist()">
                <i class="fas fa-trash-alt"></i> Clear All
            </button>
        </div>

        <!-- Wishlist Items -->
        <%
            while(rs.next()) {
                int wishlistId = rs.getInt("wishlist_id");
                int productId  = rs.getInt("product_id");
                String pname   = rs.getString("pname");
                String rateStr = rs.getString("rate");
                String qty     = rs.getString("quantity");
                String cat     = rs.getString("category");
                String pimage  = rs.getString("pimage");
                String desc    = rs.getString("description");
                String addedDate = rs.getString("added_date");
                
                double price = 0;
                try { price = Double.parseDouble(rateStr); } catch(Exception ex) {}
                double origPrice = price * 1.35;
                int disc = origPrice>0 && price>0 ? (int)(((origPrice-price)/origPrice)*100) : 0;
                
                boolean hasImg = (pimage != null && !pimage.trim().isEmpty() 
                                  && !pimage.equalsIgnoreCase("null") && !pimage.equals("0"));
                String imgSrc = hasImg ? (ctxPath + "/" + pimage) : "";
                
                String catLow = (cat != null ? cat : "").toLowerCase();
                String catIcon = catLow.contains("cloth") || catLow.contains("fashion") ? "fa-tshirt"
                               : catLow.contains("elec")  ? "fa-laptop"
                               : catLow.contains("book")  ? "fa-book"
                               : catLow.contains("sport") ? "fa-dumbbell"
                               : catLow.contains("home")  ? "fa-couch"
                               : catLow.contains("toy")   ? "fa-gamepad"
                               : "fa-box-open";
                
                boolean inStock = qty != null && !qty.equals("0") && !qty.isEmpty();
        %>
        
        <div class="wishlist-card">
            <div class="wishlist-image">
                <% if(hasImg) { %>
                    <img src="<%= imgSrc %>" alt="<%= pname %>" 
                         onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div class="img-placeholder-wish" style="display:none;">
                        <i class="fas <%= catIcon %>"></i>
                        <span><%= pname %></span>
                    </div>
                <% } else { %>
                    <div class="img-placeholder-wish">
                        <i class="fas <%= catIcon %>"></i>
                        <span><%= pname %></span>
                    </div>
                <% } %>
            </div>
            
            <div class="wishlist-details">
                <div class="wishlist-category"><%= cat!=null&&!cat.isEmpty()?cat.toUpperCase():"GENERAL" %></div>
                <h3 class="wishlist-name"><%= pname %></h3>
                <% if(desc != null && !desc.isEmpty() && !desc.equals("null")) { %>
                <p class="wishlist-desc"><%= desc.length()>150 ? desc.substring(0,150)+"..." : desc %></p>
                <% } %>
                <div class="wishlist-price">
                    <span class="current-price">₹<%= String.format("%.0f", price) %></span>
                    <% if(disc > 0) { %>
                        <span class="original-price">₹<%= String.format("%.0f", origPrice) %></span>
                        <span class="discount-badge"><%= disc %>% OFF</span>
                    <% } %>
                </div>
                <div class="stock-status <%= inStock?"in":"out" %>">
                    <i class="fas fa-<%= inStock?"check-circle":"times-circle" %>"></i>
                    <%= inStock ? "In Stock" : "Out of Stock" %>
                </div>
                <div class="wishlist-added">
                    <i class="fas fa-clock"></i> Added on <%= addedDate %>
                </div>
            </div>
            
            <div class="wishlist-actions">
                <% if(inStock) { %>
                <button class="btn-action btn-add-cart" onclick="addToCartFromWishlist(<%= productId %>)">
                    <i class="fas fa-shopping-cart"></i> Add to Cart
                </button>
                <% } else { %>
                <button class="btn-action btn-add-cart" disabled style="opacity:0.5;cursor:not-allowed;">
                    <i class="fas fa-ban"></i> Out of Stock
                </button>
                <% } %>
                <a href="buyerdashboard.jsp" class="btn-action btn-view">
                    <i class="fas fa-eye"></i> View Product
                </a>
                <button class="btn-action btn-remove" onclick="removeFromWishlist(<%= productId %>)">
                    <i class="fas fa-trash-alt"></i> Remove
                </button>
            </div>
        </div>
        
        <%
            } // end while
        %>
        
        <%
            } else {
                // Empty wishlist
        %>
        
        <div class="empty-wishlist">
            <i class="fas fa-heart-broken"></i>
            <h3>Your Wishlist is Empty</h3>
            <p>Save your favorite items to your wishlist and shop them later!</p>
            <a href="buyerdashboard.jsp" class="btn-shop-now">
                <i class="fas fa-shopping-bag"></i> Start Shopping
            </a>
        </div>
        
        <%
            }
        } catch(Exception e) {
            out.println("<div class='alert alert-danger' style='border-radius:16px;padding:20px;'>");
            out.println("<i class='fas fa-exclamation-triangle'></i> <strong>Error:</strong> " + e.getMessage());
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
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    function addToCartFromWishlist(productId) {
        window.location.href = 'updatecart.jsp?action=add&productId=' + productId;
    }
    
    function removeFromWishlist(productId) {
        if(confirm('Are you sure you want to remove this item from your wishlist?')) {
            window.location.href = 'addtowishlist?action=remove&productId=' + productId;
        }
    }
    
    function clearAllWishlist() {
        if(confirm('Are you sure you want to clear your entire wishlist? This action cannot be undone.')) {
            window.location.href = 'clearwishlist.jsp';
        }
    }
    
    // Auto-hide alert
    const alertEl = document.querySelector('.alert-custom');
    if(alertEl) {
        setTimeout(() => {
            alertEl.style.opacity = '0';
            alertEl.style.transition = 'opacity .5s';
            setTimeout(() => alertEl.remove(), 500);
        }, 5000);
    }
</script>
</body>
</html>
