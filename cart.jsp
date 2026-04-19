<%-- 
    Document   : cart
    Created on : 6 Feb, 2026, 7:30:00 PM
    Author     : moham
--%>

<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    String password = null;
    try {
        username = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(username == null || password == null || username == "" || password == "") {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        }
    } catch(Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); 
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shopping Cart - MarketHub</title>
    
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
            color: var(--primary-color);
        }
        
        .alert-custom {
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 30px;
            border: none;
            box-shadow: 0 4px 15px rgba(0,0,0,0.08);
        }
        
        .alert-custom.success {
            background: linear-gradient(135deg, rgba(16, 185, 129, 0.1) 0%, rgba(5, 150, 105, 0.1) 100%);
            color: #059669;
            border-left: 4px solid var(--success-color);
        }
        
        .alert-custom.error {
            background: linear-gradient(135deg, rgba(239, 68, 68, 0.1) 0%, rgba(220, 38, 38, 0.1) 100%);
            color: #dc2626;
            border-left: 4px solid var(--danger-color);
        }
        
        .alert-custom.warning {
            background: linear-gradient(135deg, rgba(245, 158, 11, 0.1) 0%, rgba(217, 119, 6, 0.1) 100%);
            color: #d97706;
            border-left: 4px solid var(--warning-color);
        }
        
        .cart-item {
            background: white;
            border-radius: 20px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }
        
        .cart-item:hover {
            border-color: var(--primary-color);
            transform: translateY(-3px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.12);
        }
        
        .cart-item-image {
            width: 120px;
            height: 120px;
            border-radius: 16px;
            object-fit: cover;
            border: 2px solid var(--border-color);
        }
        
        .cart-item-details h3 {
            font-size: 20px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 8px;
        }
        
        .cart-item-category {
            color: var(--text-secondary);
            font-size: 13px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }
        
        .cart-item-price {
            font-size: 28px;
            font-weight: 800;
            color: var(--primary-color);
            margin-bottom: 15px;
        }
        
        .quantity-control {
            display: flex;
            align-items: center;
            gap: 12px;
            background: var(--light-bg);
            padding: 8px 15px;
            border-radius: 12px;
            border: 2px solid var(--border-color);
            width: fit-content;
        }
        
        .quantity-control button {
            background: white;
            border: 2px solid var(--border-color);
            color: var(--text-primary);
            width: 35px;
            height: 35px;
            border-radius: 8px;
            font-size: 18px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .quantity-control button:hover {
            background: var(--primary-color);
            color: white;
            border-color: var(--primary-color);
            transform: scale(1.1);
        }
        
        .quantity-control span {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-primary);
            min-width: 40px;
            text-align: center;
        }
        
        .btn-remove {
            background: linear-gradient(135deg, var(--danger-color) 0%, #dc2626 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 12px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-remove:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(239, 68, 68, 0.4);
        }
        
        .cart-summary {
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            position: sticky;
            top: 20px;
        }
        
        .cart-summary h3 {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 25px;
            padding-bottom: 15px;
            border-bottom: 2px solid var(--border-color);
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 15px;
            font-weight: 600;
            color: var(--text-primary);
        }
        
        .summary-row.total {
            font-size: 24px;
            font-weight: 800;
            color: var(--primary-color);
            padding-top: 15px;
            border-top: 2px solid var(--border-color);
            margin-top: 20px;
        }
        
        .btn-checkout {
            width: 100%;
            background: linear-gradient(135deg, var(--success-color) 0%, #059669 100%);
            color: white;
            border: none;
            padding: 16px;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 800;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 20px;
        }
        
        .btn-checkout:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(16, 185, 129, 0.4);
        }
        
        .btn-continue {
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
        
        .btn-continue:hover {
            background: var(--primary-color);
            color: white;
            transform: translateY(-2px);
        }
        
        .btn-clear-cart {
            width: 100%;
            background: linear-gradient(135deg, var(--danger-color) 0%, #dc2626 100%);
            color: white;
            border: none;
            padding: 12px;
            border-radius: 12px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 15px;
        }
        
        .btn-clear-cart:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(239, 68, 68, 0.4);
        }
        
        .empty-cart {
            text-align: center;
            padding: 80px 40px;
            background: white;
            border-radius: 20px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        
        .empty-cart i {
            font-size: 100px;
            color: var(--text-secondary);
            margin-bottom: 30px;
            opacity: 0.5;
        }
        
        .empty-cart h2 {
            font-size: 32px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 15px;
        }
        
        .empty-cart p {
            color: var(--text-secondary);
            font-size: 16px;
            margin-bottom: 30px;
        }
        
        .stock-info {
            font-size: 13px;
            margin-top: 10px;
            font-weight: 600;
        }
        
        .stock-info.in-stock {
            color: var(--success-color);
        }
        
        .stock-info.low-stock {
            color: var(--warning-color);
        }
        
        .stock-info.out-of-stock {
            color: var(--danger-color);
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
                    <a href="buyerdashboard.jsp" class="btn btn-outline-primary" style="border-radius: 12px; font-weight: 700; padding: 10px 24px;">
                        <i class="fas fa-arrow-left"></i> Continue Shopping
                    </a>
                </div>
            </div>
        </div>
    </header>

    <div class="container">
        <!-- Page Title -->
        <div class="page-title">
            <h1><i class="fas fa-shopping-cart"></i> Shopping Cart</h1>
        </div>
        
        <%
        // Display message if exists
        String cartMessage = (String) session.getAttribute("cartMessage");
        String cartMessageType = (String) session.getAttribute("cartMessageType");
        
        if(cartMessage != null && !cartMessage.isEmpty()) {
        %>
            <div class="alert-custom <%= cartMessageType %>">
                <i class="fas fa-<%= "success".equals(cartMessageType) ? "check-circle" : ("error".equals(cartMessageType) ? "times-circle" : "exclamation-triangle") %>"></i>
                <strong><%= cartMessage %></strong>
            </div>
        <%
            // Clear message from session
            session.removeAttribute("cartMessage");
            session.removeAttribute("cartMessageType");
        }
        
        // Get cart from session
        HashMap<Integer, Integer> cart = (HashMap<Integer, Integer>) session.getAttribute("cart");
        
        if(cart == null || cart.isEmpty()) {
        %>
            <!-- Empty Cart -->
            <div class="empty-cart">
                <i class="fas fa-shopping-cart"></i>
                <h2>Your Cart is Empty</h2>
                <p>Looks like you haven't added any items to your cart yet.</p>
                <a href="buyerdashboard.jsp" class="btn btn-primary" style="background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%); border: none; padding: 14px 40px; border-radius: 12px; font-weight: 700; font-size: 16px;">
                    <i class="fas fa-shopping-bag"></i> Start Shopping
                </a>
            </div>
        <%
        } else {
            // Database connection
            String dbURL = "jdbc:mysql://localhost:3306/multi_vendor";
            String dbUser = "root";
            String dbPassword = "";
            
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            
            double subtotal = 0;
            int totalItems = 0;
            
            try {
                Class.forName("com.mysql.jdbc.Driver");
                conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);
        %>
        
        <div class="row">
            <!-- Cart Items -->
            <div class="col-lg-8">
                <%
                for(Map.Entry<Integer, Integer> entry : cart.entrySet()) {
                    int productId = entry.getKey();
                    int quantity = entry.getValue();
                    
                    // Fetch product details
                    String query = "SELECT * FROM adprod WHERE id = ?";
                    pstmt = conn.prepareStatement(query);
                    pstmt.setInt(1, productId);
                    rs = pstmt.executeQuery();
                    
                    if(rs.next()) {
                        String productName = rs.getString("pname");
                        String category = rs.getString("category");
                        String rateStr = rs.getString("rate");
                        String availableQtyStr = rs.getString("quantity");
                        String pimage = rs.getString("pimage");
                        
                        double price = 0;
                        try {
                            price = Double.parseDouble(rateStr);
                        } catch(NumberFormatException e) {
                            price = 0;
                        }
                        
                        int availableQty = 0;
                        try {
                            availableQty = Integer.parseInt(availableQtyStr);
                        } catch(NumberFormatException e) {
                            availableQty = 100;
                        }
                        
                        double itemTotal = price * quantity;
                        subtotal += itemTotal;
                        totalItems += quantity;
                        
                        String imageUrl = (pimage != null && !pimage.isEmpty() && !pimage.equals("null")) 
                            ? pimage 
                            : "https://via.placeholder.com/120?text=" + productName.replace(" ", "+");
                %>
                
                <div class="cart-item">
                    <div class="row align-items-center">
                        <div class="col-md-2">
                            <img src="<%= imageUrl %>" alt="<%= productName %>" class="cart-item-image" onerror="this.src='https://via.placeholder.com/120?text=Product'">
                        </div>
                        <div class="col-md-4">
                            <div class="cart-item-details">
                                <div class="cart-item-category"><%= category != null && !category.isEmpty() ? category.toUpperCase() : "GENERAL" %></div>
                                <h3><%= productName %></h3>
                                <div class="cart-item-price">₹<%= String.format("%.2f", price) %></div>
                                <div class="stock-info <%= (availableQty > 10) ? "in-stock" : ((availableQty > 0) ? "low-stock" : "out-of-stock") %>">
                                    <i class="fas fa-<%= (availableQty > 10) ? "check-circle" : ((availableQty > 0) ? "exclamation-triangle" : "times-circle") %>"></i>
                                    <%= (availableQty > 10) ? "In Stock" : ((availableQty > 0) ? "Only " + availableQty + " left!" : "Out of Stock") %>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="quantity-control">
                                <button onclick="updateQuantity(<%= productId %>, 'decrease')">
                                    <i class="fas fa-minus"></i>
                                </button>
                                <span><%= quantity %></span>
                                <button onclick="updateQuantity(<%= productId %>, 'increase')" <%= (quantity >= availableQty) ? "disabled" : "" %>>
                                    <i class="fas fa-plus"></i>
                                </button>
                            </div>
                        </div>
                        <div class="col-md-2">
                            <div style="font-size: 24px; font-weight: 800; color: var(--text-primary); margin-bottom: 10px;">
                                ₹<%= String.format("%.2f", itemTotal) %>
                            </div>
                            <button class="btn-remove" onclick="removeFromCart(<%= productId %>)">
                                <i class="fas fa-trash"></i> Remove
                            </button>
                        </div>
                    </div>
                </div>
                
                <%
                    }
                    rs.close();
                    pstmt.close();
                }
                %>
            </div>
            
            <!-- Cart Summary -->
            <div class="col-lg-4">
                <div class="cart-summary">
                    <h3><i class="fas fa-receipt"></i> Order Summary</h3>
                    
                    <div class="summary-row">
                        <span>Items (<%= totalItems %>):</span>
                        <span>₹<%= String.format("%.2f", subtotal) %></span>
                    </div>
                    
                    <div class="summary-row">
                        <span>Shipping:</span>
                        <span style="color: var(--success-color);">FREE</span>
                    </div>
                    
                    <div class="summary-row">
                        <span>Tax (18%):</span>
                        <span>₹<%= String.format("%.2f", subtotal * 0.18) %></span>
                    </div>
                    
                    <div class="summary-row total">
                        <span>Total:</span>
                        <span>₹<%= String.format("%.2f", subtotal * 1.18) %></span>
                    </div>
                    
                    <a href="chekout.jsp" class="btn-checkout" style="display: block; text-decoration: none; text-align: center;">
            <i class="fas fa-lock"></i> Proceed to Checkout
        </a>
                    
                    <a href="buyerdashboard.jsp" class="btn-continue">
                        <i class="fas fa-shopping-bag"></i> Continue Shopping
                    </a>
                    
                    <button class="btn-clear-cart" onclick="clearCart()">
                        <i class="fas fa-trash-alt"></i> Clear Cart
                    </button>
                    
                    <div style="margin-top: 25px; padding: 15px; background: linear-gradient(135deg, rgba(99, 102, 241, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%); border-radius: 12px; text-align: center;">
                        <i class="fas fa-shield-alt" style="color: var(--primary-color); font-size: 24px;"></i>
                        <p style="margin: 10px 0 0 0; font-weight: 600; color: var(--text-primary); font-size: 13px;">
                            Safe & Secure Checkout
                        </p>
                    </div>
                </div>
            </div>
        </div>
        
        <%
            } catch(Exception e) {
                out.println("<div class='alert-custom error'>");
                out.println("<i class='fas fa-exclamation-triangle'></i> ");
                out.println("<strong>Error loading cart:</strong> " + e.getMessage());
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
        }
        %>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script>
        function updateQuantity(productId, action) {
            window.location.href = 'updatecart.jsp?action=' + action + '&productId=' + productId;
        }
        
        function removeFromCart(productId) {
            if(confirm('Are you sure you want to remove this item from your cart?')) {
                window.location.href = 'updatecart.jsp?action=remove&productId=' + productId;
            }
        }
        
        function clearCart() {
            if(confirm('Are you sure you want to clear your entire cart?')) {
                window.location.href = 'updatecart.jsp?action=clear&productId=0';
            }
        }
        
        function checkout() {
            // Redirect to checkout page (to be created)
            alert('Checkout functionality will be implemented soon!');
            // window.location.href = 'checkout.jsp';
        }
    </script>
</body>
</html>
