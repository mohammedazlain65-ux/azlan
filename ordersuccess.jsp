<%-- 
    Document   : ordersuccess
    Author     : moham
    Description: Order success page — shown after OrderServlet processes the order.
                 Displays full item breakdown stored in session by OrderServlet.
                 FIX: Replaced new ArrayList<>() with new ArrayList<Map<String,String>>()
                      to support Java source level below 1.7 (Tomcat 8.0.3 / JDK 6).
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%
    HttpSession hs = request.getSession();

    // ── Read order data stored by OrderServlet ────────────────────────────
    String orderId        = (String) hs.getAttribute("lastOrderId");
    String grandTotal     = (String) hs.getAttribute("lastOrderTotal");
    String customerName   = (String) hs.getAttribute("lastCustomerName");
    String paymentMethod  = (String) hs.getAttribute("lastPaymentMethod");
    String orderSource    = (String) hs.getAttribute("lastOrderSource");
    Object itemsObj       = hs.getAttribute("lastOrderItems");
    int    totalItems     = (itemsObj != null) ? (Integer) itemsObj : 0;

    @SuppressWarnings("unchecked")
    List<Map<String,String>> itemList =
        (List<Map<String,String>>) hs.getAttribute("lastOrderItemList");

    // FIX: was  new java.util.ArrayList<>()  — diamond operator requires Java 7+
    //      changed to explicit type for Java 6 / old Tomcat compatibility
    if (itemList == null) itemList = new java.util.ArrayList<Map<String,String>>();

    // Redirect if no order data
    if (orderId == null) {
        response.sendRedirect("buyerdashboard.jsp");
        return;
    }

    // ── Clear session order data after reading ────────────────────────────
    hs.removeAttribute("lastOrderId");
    hs.removeAttribute("lastOrderTotal");
    hs.removeAttribute("lastOrderItems");
    hs.removeAttribute("lastPaymentMethod");
    hs.removeAttribute("lastCustomerName");
    hs.removeAttribute("lastOrderSource");
    hs.removeAttribute("lastOrderItemList");

    // ── Labels ────────────────────────────────────────────────────────────
    String payLabel = "Cash on Delivery";
    if ("card".equals(paymentMethod))     payLabel = "Credit / Debit Card";
    else if ("upi".equals(paymentMethod)) payLabel = "UPI Payment";

    String sourceLabel = "buynow".equals(orderSource) ? "Buy Now" : "Cart Checkout";

    // Recalculate displayed subtotal from item list for display
    double subtotalCalc = 0;
    for (Map<String,String> it : itemList) {
        try { subtotalCalc += Double.parseDouble(it.get("total")); } catch (Exception ignored) {}
    }
    double taxCalc = subtotalCalc * 0.18;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Placed! — MarketHub</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary:   #6366f1;
            --secondary: #8b5cf6;
            --success:   #10b981;
            --dark-bg:   #1e293b;
            --darker:    #0f172a;
            --text:      #0f172a;
            --muted:     #64748b;
            --border:    #e2e8f0;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body {
            font-family: 'Outfit', sans-serif;
            background: linear-gradient(135deg, #f0f4ff 0%, #e5edff 100%);
            min-height: 100vh;
        }
        /* ── Top bar ── */
        .top-header {
            background: var(--darker);
            color: rgba(255,255,255,0.75);
            padding: 11px 0;
            font-size: 13px; font-weight: 600;
        }
        /* ── Main header ── */
        .main-header {
            background: white;
            padding: 18px 0;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin-bottom: 45px;
        }
        .logo {
            font-size: 28px; font-weight: 800;
            color: var(--text); text-decoration: none;
            display: flex; align-items: center; gap: 10px;
        }
        .logo i {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        /* ── Success card ── */
        .success-card {
            background: white;
            border-radius: 24px;
            padding: 48px 44px;
            box-shadow: 0 8px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 760px;
            margin: 0 auto;
        }
        /* ── Checkmark ── */
        .checkmark-circle {
            width: 100px; height: 100px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--success), #059669);
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 22px;
            animation: popIn 0.6s ease;
            box-shadow: 0 8px 30px rgba(16,185,129,0.4);
        }
        @keyframes popIn {
            0%  { transform:scale(0); opacity:0; }
            70% { transform:scale(1.15); }
            100%{ transform:scale(1);   opacity:1; }
        }
        .checkmark-circle i { font-size: 50px; color: white; }
        .success-title    { font-size: 34px; font-weight: 800; color: var(--text); margin-bottom: 8px; }
        .success-subtitle { font-size: 15px; color: var(--muted); font-weight: 600; margin-bottom: 30px; }
        .source-badge {
            display: inline-block;
            background: linear-gradient(135deg, var(--success), #059669);
            color: white; padding: 5px 14px; border-radius: 20px;
            font-size: 12px; font-weight: 700; margin-bottom: 18px;
        }
        /* ── Order summary box ── */
        .order-box {
            background: linear-gradient(135deg, rgba(99,102,241,0.05), rgba(139,92,246,0.05));
            border: 2px solid var(--border);
            border-radius: 16px; padding: 22px 24px;
            margin-bottom: 28px; text-align: left;
        }
        .box-title {
            font-size: 13px; font-weight: 800;
            color: var(--muted); text-transform: uppercase;
            letter-spacing: 0.7px; margin-bottom: 16px;
            display: flex; align-items: center; gap: 7px;
        }
        .box-title i { color: var(--primary); }
        /* Detail rows */
        .detail-row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 11px 0; border-bottom: 1px solid var(--border);
            font-size: 15px;
        }
        .detail-row:last-child { border-bottom: none; }
        .detail-label {
            font-weight: 700; color: var(--muted);
            display: flex; align-items: center; gap: 8px;
        }
        .detail-label i { color: var(--primary); }
        .detail-value  { font-weight: 800; color: var(--text); }
        .detail-value.green  { color: var(--success); }
        .detail-value.purple { color: var(--primary); font-size: 20px; }
        /* ── Items table ── */
        .items-table {
            width: 100%; border-collapse: collapse;
            margin-top: 4px;
        }
        .items-table thead th {
            background: rgba(99,102,241,0.07);
            padding: 9px 12px;
            font-size: 12px; font-weight: 800;
            color: var(--muted); text-transform: uppercase; letter-spacing: 0.5px;
            border-bottom: 2px solid var(--border);
        }
        .items-table thead th:last-child { text-align: right; }
        .items-table tbody td {
            padding: 11px 12px; border-bottom: 1px solid var(--border);
            font-size: 14px; font-weight: 600; color: var(--text);
            vertical-align: middle;
        }
        .items-table tbody tr:last-child td { border-bottom: none; }
        .items-table td:last-child { text-align: right; font-weight: 800; }
        .prod-dot {
            width: 8px; height: 8px; border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            display: inline-block; margin-right: 7px;
        }
        .qty-chip {
            background: rgba(99,102,241,0.1); color: var(--primary);
            padding: 2px 8px; border-radius: 6px;
            font-size: 12px; font-weight: 800;
        }
        /* Totals strip */
        .totals-strip {
            background: rgba(99,102,241,0.05);
            border-radius: 10px; padding: 14px 16px;
            margin-top: 14px;
            display: flex; justify-content: space-between; flex-wrap: wrap; gap: 10px;
        }
        .tot-item { font-size: 13px; font-weight: 700; color: var(--muted); }
        .tot-item span { color: var(--text); font-weight: 800; }
        .tot-item.grand { font-size: 15px; }
        .tot-item.grand span {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text; font-size: 22px;
        }
        /* ── CTA buttons ── */
        .btn-continue {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white; border: none; padding: 15px 38px; border-radius: 14px;
            font-size: 16px; font-weight: 800; text-decoration: none;
            display: inline-block; transition: all 0.3s; margin: 7px;
        }
        .btn-continue:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(99,102,241,0.4); color: white;
        }
        .btn-orders {
            background: white; color: var(--primary);
            border: 2px solid var(--primary);
            padding: 13px 34px; border-radius: 14px;
            font-size: 16px; font-weight: 800; text-decoration: none;
            display: inline-block; transition: all 0.3s; margin: 7px;
        }
        .btn-orders:hover {
            background: var(--primary); color: white; transform: translateY(-3px);
        }
        /* ── Footer note ── */
        .footer-note {
            margin-top: 22px; color: var(--muted);
            font-size: 13px; font-weight: 600;
        }
    </style>
</head>
<body>

<!-- Top header -->
<div class="top-header">
    <div class="container d-flex justify-content-between">
        <span><i class="fas fa-phone"></i> +91 1800-123-4567
            &nbsp;&nbsp;<i class="fas fa-envelope"></i> support@markethub.com</span>
        <span><i class="fas fa-headset"></i> Customer Support</span>
    </div>
</div>

<!-- Main header -->
<header class="main-header">
    <div class="container">
        <a href="buyerdashboard.jsp" class="logo">
            <i class="fas fa-shopping-bag"></i>
            <span>MarketHub</span>
        </a>
    </div>
</header>

<div class="container pb-5">
    <div class="success-card">

        <!-- Checkmark -->
        <div class="checkmark-circle"><i class="fas fa-check"></i></div>

        <!-- Source badge -->
        <div class="source-badge">
            <i class="fas fa-<%= "Buy Now".equals(sourceLabel) ? "bolt" : "shopping-cart" %>"></i>
            &nbsp;<%= sourceLabel %>
        </div>

        <div class="success-title">Order Placed Successfully!</div>
        <div class="success-subtitle">
            Thank you, <strong><%= customerName %></strong>!
            Your order has been confirmed and will be processed shortly.
        </div>

        <!-- ── Order Meta ── -->
        <div class="order-box">
            <div class="box-title"><i class="fas fa-receipt"></i> Order Summary</div>
            <div class="detail-row">
                <div class="detail-label"><i class="fas fa-hashtag"></i> Order ID</div>
                <div class="detail-value" style="font-family:monospace; font-size:16px;"><%= orderId %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label"><i class="fas fa-credit-card"></i> Payment</div>
                <div class="detail-value"><%= payLabel %></div>
            </div>
            <div class="detail-row">
                <div class="detail-label"><i class="fas fa-truck"></i> Shipping</div>
                <div class="detail-value green"><i class="fas fa-check-circle"></i> FREE</div>
            </div>
        </div>

        <!-- ── Item Breakdown ── -->
        <% if (!itemList.isEmpty()) { %>
        <div class="order-box">
            <div class="box-title"><i class="fas fa-boxes"></i> Items Ordered (<%= totalItems %> item<%= totalItems != 1 ? "s" : "" %>)</div>
            <table class="items-table">
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Unit Price</th>
                        <th>Qty</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String,String> item : itemList) { %>
                    <tr>
                        <td>
                            <span class="prod-dot"></span>
                            <%= item.get("name") %>
                        </td>
                        <td>&#8377;<%= item.get("unitPrice") %></td>
                        <td><span class="qty-chip">x<%= item.get("qty") %></span></td>
                        <td>&#8377;<%= item.get("total") %></td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            <div class="totals-strip">
                <div class="tot-item">Subtotal: <span>&#8377;<%= String.format("%.2f", subtotalCalc) %></span></div>
                <div class="tot-item">Tax (18% GST): <span>&#8377;<%= String.format("%.2f", taxCalc) %></span></div>
                <div class="tot-item grand">Grand Total: <span>&#8377;<%= grandTotal %></span></div>
            </div>
        </div>
        <% } %>

        <!-- CTA -->
        <div>
            <a href="buyerdashboard.jsp" class="btn-continue">
                <i class="fas fa-shopping-bag"></i> Continue Shopping
            </a>
            <a href="myorders.jsp" class="btn-orders">
                <i class="fas fa-box-open"></i> My Orders
            </a>
        </div>

        <p class="footer-note">
            <i class="fas fa-envelope"></i>
            A confirmation will be sent to your registered email.
        </p>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
