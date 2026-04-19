<%-- 
    Document   : viewSellerProducts
    Modified   : Restyled to match adhome.jsp design system (Sora font, dark sidebar, same card styles)
                 Includes seller ratings summary, star breakdown, recent reviews, per-product ratings
--%>

<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seller Products - MarketHub Admin</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">

    <style>
        /* ═══════════════════════════════════════════
           DESIGN TOKENS — identical to adhome.jsp
        ═══════════════════════════════════════════ */
        :root {
            --primary:    #0f172a;
            --accent:     #38bdf8;
            --accent2:    #818cf8;
            --success:    #10b981;
            --warning:    #f59e0b;
            --danger:     #ef4444;
            --suspend:    #f97316;
            --info:       #06b6d4;
            --star-color: #f59e0b;
            --sidebar-bg: #0f172a;
            --sidebar-w:  270px;
            --card-bg:    #ffffff;
            --page-bg:    #f1f5f9;
            --border:     #e2e8f0;
            --txt:        #0f172a;
            --txt-m:      #64748b;
            --txt-s:      #94a3b8;
        }

        *, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Sora',sans-serif; background:var(--page-bg); color:var(--txt); min-height:100vh; }

        /* ════ SIDEBAR — same as adhome ════ */
        .sidebar {
            position:fixed; left:0; top:0;
            height:100vh; width:var(--sidebar-w);
            background:var(--sidebar-bg);
            z-index:1000; overflow-y:auto;
            display:flex; flex-direction:column;
            box-shadow:4px 0 24px rgba(0,0,0,.18);
        }
        .sidebar::-webkit-scrollbar { width:4px; }
        .sidebar::-webkit-scrollbar-thumb { background:rgba(255,255,255,.15); border-radius:4px; }

        .sidebar-header { padding:28px 22px 22px; border-bottom:1px solid rgba(255,255,255,.08); }
        .sidebar-logo { display:flex; align-items:center; gap:14px; text-decoration:none; }
        .logo-icon {
            width:44px; height:44px;
            background:linear-gradient(135deg,var(--accent),var(--accent2));
            border-radius:12px; display:flex; align-items:center; justify-content:center;
            font-size:20px; color:#fff; box-shadow:0 6px 20px rgba(56,189,248,.35);
        }
        .logo-text h3   { font-size:18px; font-weight:800; color:#fff; letter-spacing:-.3px; }
        .logo-text span { font-size:10px; color:rgba(255,255,255,.45); text-transform:uppercase; letter-spacing:1.5px; }

        .sidebar-nav { padding:18px 0; flex:1; }
        .nav-section-label { font-size:9px; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:rgba(255,255,255,.3); padding:18px 22px 8px; }
        .nav-link-item {
            display:flex; align-items:center; gap:14px;
            padding:13px 22px; color:rgba(255,255,255,.65);
            text-decoration:none; font-size:14px; font-weight:500;
            transition:all .25s; position:relative;
            margin:2px 10px; border-radius:10px;
        }
        .nav-link-item i { font-size:17px; width:20px; text-align:center; transition:all .25s; }
        .nav-link-item:hover { background:rgba(255,255,255,.08); color:#fff; }
        .nav-link-item.active {
            background:linear-gradient(135deg,rgba(56,189,248,.18),rgba(129,140,248,.18)); color:#fff;
        }
        .nav-link-item.active::before {
            content:''; position:absolute; left:0; top:50%; transform:translateY(-50%);
            width:3px; height:60%;
            background:linear-gradient(180deg,var(--accent),var(--accent2));
            border-radius:0 3px 3px 0;
        }
        .nav-link-item.active i { color:var(--accent); }

        .sidebar-footer { padding:18px 22px; border-top:1px solid rgba(255,255,255,.08); }
        .admin-chip { display:flex; align-items:center; gap:12px; padding:10px 14px; background:rgba(255,255,255,.07); border-radius:12px; }
        .admin-avatar { width:36px; height:36px; border-radius:50%; background:linear-gradient(135deg,var(--accent),var(--accent2)); display:flex; align-items:center; justify-content:center; color:#fff; font-weight:700; font-size:15px; flex-shrink:0; }
        .admin-chip-info strong { display:block; font-size:13px; color:#fff; font-weight:600; }
        .admin-chip-info span   { font-size:11px; color:rgba(255,255,255,.4); }

        /* ════ MAIN ════ */
        .main-content { margin-left:var(--sidebar-w); min-height:100vh; }

        .top-bar {
            background:#fff; padding:18px 32px;
            display:flex; justify-content:space-between; align-items:center;
            box-shadow:0 1px 12px rgba(0,0,0,.06);
            position:sticky; top:0; z-index:999;
            border-bottom:1px solid var(--border);
        }
        .top-bar-left h1 { font-size:22px; font-weight:800; color:var(--txt); letter-spacing:-.4px; }
        .top-bar-left p  { font-size:13px; color:var(--txt-m); margin-top:2px; }
        .top-bar-right { display:flex; align-items:center; gap:14px; }

        .breadcrumb-trail { display:flex; align-items:center; gap:8px; font-size:13px; color:var(--txt-s); }
        .breadcrumb-trail a { color:var(--accent); text-decoration:none; font-weight:600; transition:color .2s; }
        .breadcrumb-trail a:hover { color:var(--accent2); }
        .breadcrumb-trail i.sep { font-size:9px; opacity:.5; }

        /* Back button */
        .btn-back {
            display:inline-flex; align-items:center; gap:8px;
            padding:9px 20px; border:2px solid var(--border);
            border-radius:10px; font-size:13px; font-weight:700;
            color:var(--txt-m); text-decoration:none;
            font-family:'Sora',sans-serif; transition:all .22s;
            background:#fff;
        }
        .btn-back:hover { border-color:var(--accent); color:var(--accent); background:rgba(56,189,248,.06); transform:translateY(-1px); }

        /* ════ PAGE BODY ════ */
        .page-body { padding:28px 32px; }

        /* ════ SELLER HERO CARD ════ */
        .seller-hero {
            background:#fff; border-radius:18px;
            padding:24px 28px; margin-bottom:26px;
            box-shadow:0 2px 16px rgba(0,0,0,.06);
            border:1px solid var(--border);
            display:flex; align-items:center;
            justify-content:space-between; flex-wrap:wrap; gap:18px;
        }
        .seller-hero-left { display:flex; align-items:center; gap:18px; }
        .seller-hero-avatar {
            width:56px; height:56px; border-radius:50%;
            background:linear-gradient(135deg,var(--accent),var(--accent2));
            display:flex; align-items:center; justify-content:center;
            color:#fff; font-size:22px; font-weight:800; flex-shrink:0;
            box-shadow:0 6px 20px rgba(56,189,248,.3);
        }
        .seller-hero-name { font-size:20px; font-weight:800; color:var(--txt); letter-spacing:-.3px; margin-bottom:4px; }
        .seller-hero-email { font-size:13px; color:var(--txt-m); font-weight:500; }
        .seller-hero-email i { color:var(--accent); font-size:12px; margin-right:5px; }

        /* ════ STATS GRID ════ */
        .stats-grid {
            display:grid;
            grid-template-columns:repeat(auto-fit, minmax(190px, 1fr));
            gap:20px; margin-bottom:26px;
        }
        .stat-card {
            background:#fff; border-radius:16px; padding:22px 20px;
            box-shadow:0 2px 14px rgba(0,0,0,.05);
            border:1px solid var(--border);
            display:flex; align-items:center; gap:16px;
            transition:transform .25s, box-shadow .25s;
        }
        .stat-card:hover { transform:translateY(-4px); box-shadow:0 8px 28px rgba(0,0,0,.09); }
        .stat-icon {
            width:48px; height:48px; border-radius:13px;
            display:flex; align-items:center; justify-content:center;
            font-size:20px; color:#fff; flex-shrink:0;
        }
        .stat-icon.blue   { background:linear-gradient(135deg,var(--accent),#0ea5e9); box-shadow:0 5px 18px rgba(56,189,248,.3); }
        .stat-icon.green  { background:linear-gradient(135deg,var(--success),#059669); box-shadow:0 5px 18px rgba(16,185,129,.3); }
        .stat-icon.orange { background:linear-gradient(135deg,var(--suspend),#d97706); box-shadow:0 5px 18px rgba(249,115,22,.3); }
        .stat-icon.gold   { background:linear-gradient(135deg,var(--star-color),var(--suspend)); box-shadow:0 5px 18px rgba(245,158,11,.3); }
        .stat-icon.violet { background:linear-gradient(135deg,var(--accent2),#6366f1); box-shadow:0 5px 18px rgba(129,140,248,.3); }
        .stat-val  { font-size:26px; font-weight:800; color:var(--txt); line-height:1.1; letter-spacing:-.5px; }
        .stat-lbl  { font-size:12px; font-weight:600; color:var(--txt-m); margin-top:3px; }
        .stat-sub  { font-size:11px; color:var(--txt-s); margin-top:4px; font-family:'JetBrains Mono',monospace; }

        /* ════ SECTION CARD (shared wrapper) ════ */
        .section-card {
            background:#fff; border-radius:18px;
            box-shadow:0 2px 16px rgba(0,0,0,.06);
            border:1px solid var(--border);
            margin-bottom:26px; overflow:hidden;
        }
        .section-card-header {
            display:flex; align-items:center; justify-content:space-between;
            padding:20px 26px; border-bottom:1px solid var(--border);
            background:linear-gradient(135deg,#f8fafc,#f1f5f9);
            flex-wrap:wrap; gap:12px;
        }
        .section-card-header h3 {
            font-size:16px; font-weight:800; color:var(--txt);
            display:flex; align-items:center; gap:10px; margin:0;
        }
        .section-card-header h3 i { color:var(--accent); }
        .avg-pill {
            display:inline-flex; align-items:center; gap:8px;
            padding:7px 16px;
            background:linear-gradient(135deg,rgba(245,158,11,.12),rgba(249,115,22,.1));
            border:1px solid rgba(245,158,11,.25);
            border-radius:20px; font-size:13px; font-weight:800; color:var(--star-color);
        }

        /* ════ RATINGS OVERVIEW BODY ════ */
        .ratings-body { display:flex; gap:32px; align-items:flex-start; flex-wrap:wrap; padding:24px 26px; }

        /* Big score */
        .score-block { text-align:center; min-width:110px; }
        .score-num {
            font-size:60px; font-weight:800; color:var(--txt);
            line-height:1; letter-spacing:-3px;
        }
        .score-stars { font-size:18px; color:var(--star-color); margin:8px 0 5px; letter-spacing:2px; }
        .score-sub   { font-size:12px; font-weight:600; color:var(--txt-m); }

        /* Bar breakdown */
        .bars-block { flex:1; min-width:180px; }
        .rb-row { display:flex; align-items:center; gap:10px; margin-bottom:9px; }
        .rb-lbl { font-size:12px; font-weight:700; color:var(--txt-m); width:40px; display:flex; align-items:center; gap:3px; white-space:nowrap; }
        .rb-lbl i { color:var(--star-color); font-size:10px; }
        .rb-track { flex:1; background:var(--border); border-radius:6px; height:9px; overflow:hidden; }
        .rb-fill  { height:100%; border-radius:6px; background:linear-gradient(90deg,var(--star-color),var(--suspend)); transition:width .8s ease; }
        .rb-cnt { font-size:11px; font-weight:700; color:var(--txt-m); width:22px; text-align:right; }

        /* Recent reviews snippets */
        .snippets-block { flex:2; min-width:240px; }
        .snippets-title { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:1px; color:var(--txt-s); margin-bottom:12px; }
        .snippet {
            display:flex; align-items:flex-start; gap:12px;
            padding:12px 14px;
            background:linear-gradient(135deg,rgba(245,158,11,.04),rgba(249,115,22,.04));
            border:1px solid rgba(245,158,11,.14);
            border-radius:12px; margin-bottom:10px;
        }
        .snippet:last-child { margin-bottom:0; }
        .snippet-stars { color:var(--star-color); font-size:12px; white-space:nowrap; padding-top:2px; }
        .snippet-body  { flex:1; }
        .snippet-prod  { font-size:12px; font-weight:700; color:var(--accent2); margin-bottom:3px; }
        .snippet-prod i { font-size:10px; margin-right:3px; }
        .snippet-cmt   { font-size:13px; color:var(--txt); font-style:italic; line-height:1.5; }
        .snippet-cmt.no-cmt { color:var(--txt-s); font-style:normal; font-size:12px; }
        .snippet-meta  { font-size:11px; color:var(--txt-s); margin-top:5px; font-family:'JetBrains Mono',monospace; }

        .no-ratings {
            padding:40px 26px; text-align:center; color:var(--txt-m);
        }
        .no-ratings i { font-size:44px; opacity:.15; display:block; margin-bottom:12px; color:var(--star-color); }
        .no-ratings p { font-size:14px; font-weight:500; }

        /* ════ PRODUCT TABLE ════ */
        .product-table { width:100%; border-collapse:collapse; }
        .product-table thead { background:linear-gradient(135deg,#f8fafc,#f1f5f9); }
        .product-table th {
            padding:14px 18px; text-align:left;
            font-size:11px; font-weight:700;
            text-transform:uppercase; letter-spacing:.8px;
            color:var(--txt-m); white-space:nowrap;
            border-bottom:2px solid var(--border);
        }
        .product-table th:first-child { padding-left:24px; }
        .product-table td {
            padding:16px 18px; border-bottom:1px solid var(--border);
            font-size:14px; color:var(--txt); vertical-align:middle;
        }
        .product-table td:first-child { padding-left:24px; }
        .product-table tbody tr { transition:background .2s; }
        .product-table tbody tr:hover { background:#f8fafc; }
        .product-table tbody tr:last-child td { border-bottom:none; }

        /* Serial */
        .sno {
            width:32px; height:32px;
            background:linear-gradient(135deg,rgba(56,189,248,.1),rgba(129,140,248,.1));
            border-radius:8px; display:flex; align-items:center; justify-content:center;
            font-weight:700; font-size:12px; color:var(--accent2);
            font-family:'JetBrains Mono',monospace;
        }
        /* Product cell */
        .prod-cell { display:flex; align-items:center; gap:12px; }
        .prod-thumb {
            width:44px; height:44px; border-radius:10px;
            background:linear-gradient(135deg,rgba(56,189,248,.1),rgba(129,140,248,.1));
            border:1px solid var(--border); display:flex; align-items:center;
            justify-content:center; flex-shrink:0; font-size:18px; color:var(--accent2);
        }
        .prod-name { font-weight:700; font-size:14px; color:var(--txt); }

        /* Price */
        .price-val { font-weight:700; font-size:15px; color:var(--accent2); font-family:'JetBrains Mono',monospace; }

        /* Qty */
        .qty-val { font-weight:700; font-family:'JetBrains Mono',monospace; }
        .qty-low { color:var(--danger); }
        .qty-mid { color:var(--warning); }
        .qty-ok  { color:var(--success); }

        /* Category */
        .cat-badge {
            display:inline-flex; align-items:center; gap:5px;
            padding:5px 12px; border-radius:20px;
            background:linear-gradient(135deg,rgba(56,189,248,.1),rgba(129,140,248,.1));
            color:var(--accent2); font-size:12px; font-weight:700;
        }

        /* Per-product rating */
        .prod-rating-badge {
            display:inline-flex; align-items:center; gap:5px;
            padding:5px 11px; border-radius:20px;
            background:rgba(245,158,11,.1); color:var(--star-color);
            font-size:12px; font-weight:700;
        }
        .prod-rating-badge i { font-size:10px; }
        .no-rev { font-size:12px; color:var(--txt-s); font-weight:600; }

        /* Desc */
        .desc-val { font-size:13px; color:var(--txt-m); line-height:1.5; max-width:200px; }

        /* Empty */
        .empty-row { text-align:center; padding:60px 20px; }
        .empty-row i { font-size:48px; opacity:.15; display:block; margin-bottom:14px; color:var(--accent); }
        .empty-row p { font-size:15px; font-weight:700; color:var(--txt-m); margin:0; }
        .empty-row small { font-size:13px; color:var(--txt-s); }

        @media(max-width:1100px) {
            :root { --sidebar-w:70px; }
            .logo-text, .nav-section-label, .nav-link-item span, .admin-chip-info { display:none; }
            .nav-link-item { justify-content:center; padding:14px; }
            .admin-chip { justify-content:center; }
        }
        @media(max-width:768px) {
            :root { --sidebar-w:0px; }
            .sidebar { display:none; }
            .page-body { padding:18px 14px; }
            .top-bar { padding:14px 16px; }
            .ratings-body { flex-direction:column; }
            .section-card { overflow-x:auto; }
            .product-table { min-width:820px; }
        }
    </style>
</head>
<body>

<%
    /* ══ Params ══ */
    String sellerEmail = request.getParameter("email");
    String sellerName  = request.getParameter("name");

    if (sellerEmail == null || sellerEmail.isEmpty()) {
        response.sendRedirect("adhome.jsp");
        return;
    }
    sellerEmail = java.net.URLDecoder.decode(sellerEmail, "UTF-8");
    sellerName  = sellerName != null ? java.net.URLDecoder.decode(sellerName, "UTF-8") : sellerEmail;

    String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "";

    /* ── Product stats ── */
    int    totalProducts = 0;
    int    lowStockCount = 0;
    double totalValue    = 0;

    /* ── Ratings stats ── */
    double avgRating    = 0;
    int    totalReviews = 0;
    int[]  starCounts   = new int[6];

    /* Per-product avg: product_id → formatted avg string */
    java.util.Map<Integer,String> prodAvgMap = new java.util.HashMap<Integer,String>();

    /* Recent 3 reviews for snippets panel */
    java.util.List<java.util.Map<String,String>> recentRevs = new java.util.ArrayList<java.util.Map<String,String>>();

    Connection conn = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbURL, dbUser, dbPass);

        /* 1. Product stats */
        PreparedStatement psP = conn.prepareStatement("SELECT quantity, rate FROM adprod WHERE seller_email=?");
        psP.setString(1, sellerEmail);
        ResultSet rsP = psP.executeQuery();
        while (rsP.next()) {
            totalProducts++;
            int qty = rsP.getInt("quantity");
            totalValue += qty * rsP.getDouble("rate");
            if (qty < 10) lowStockCount++;
        }
        rsP.close(); psP.close();

        /* 2. Overall rating aggregate — with LOWER/TRIM fallback */
        try {
            PreparedStatement psRat = conn.prepareStatement(
                "SELECT rating, COUNT(*) AS cnt FROM product_ratings " +
                "WHERE LOWER(TRIM(seller_email))=LOWER(TRIM(?)) GROUP BY rating");
            psRat.setString(1, sellerEmail);
            ResultSet rsRat = psRat.executeQuery();
            double rSum = 0;
            while (rsRat.next()) {
                int star = rsRat.getInt("rating"); int cnt = rsRat.getInt("cnt");
                if (star >= 1 && star <= 5) { starCounts[star] += cnt; rSum += (double)star*cnt; totalReviews += cnt; }
            }
            rsRat.close(); psRat.close();
            if (totalReviews > 0) { avgRating = rSum / totalReviews; }

            /* adprod-join fallback if still zero */
            if (totalReviews == 0) {
                PreparedStatement psFb = conn.prepareStatement(
                    "SELECT pr.rating, COUNT(*) AS cnt FROM product_ratings pr " +
                    "JOIN adprod ap ON pr.product_id=ap.id WHERE ap.seller_email=? GROUP BY pr.rating");
                psFb.setString(1, sellerEmail);
                ResultSet rsFb = psFb.executeQuery();
                double rSum2 = 0;
                while (rsFb.next()) {
                    int star = rsFb.getInt("rating"); int cnt = rsFb.getInt("cnt");
                    if (star >= 1 && star <= 5) { starCounts[star] += cnt; rSum2 += (double)star*cnt; totalReviews += cnt; }
                }
                rsFb.close(); psFb.close();
                if (totalReviews > 0) avgRating = rSum2 / totalReviews;
            }
        } catch (Exception ig) {}

        /* 3. Per-product avg */
        try {
            PreparedStatement psPr = conn.prepareStatement(
                "SELECT product_id, ROUND(AVG(rating),1) AS avg_r FROM product_ratings " +
                "WHERE LOWER(TRIM(seller_email))=LOWER(TRIM(?)) GROUP BY product_id");
            psPr.setString(1, sellerEmail);
            ResultSet rsPr = psPr.executeQuery();
            while (rsPr.next()) prodAvgMap.put(rsPr.getInt("product_id"), String.format("%.1f", rsPr.getDouble("avg_r")));
            rsPr.close(); psPr.close();
        } catch (Exception ig) {}

        /* 4. Recent 3 reviews */
        try {
            PreparedStatement psRec = conn.prepareStatement(
                "SELECT pr.product_name, pr.rating, pr.review_comment, pr.rated_at, " +
                "       COALESCE(o.full_name, pr.customer_email) AS cname " +
                "FROM product_ratings pr LEFT JOIN orders o ON pr.order_id=o.order_id " +
                "WHERE LOWER(TRIM(pr.seller_email))=LOWER(TRIM(?)) ORDER BY pr.rated_at DESC LIMIT 3");
            psRec.setString(1, sellerEmail);
            ResultSet rsRec = psRec.executeQuery();
            while (rsRec.next()) {
                java.util.Map<String,String> r = new java.util.HashMap<String,String>();
                String ra = rsRec.getString("rated_at");
                r.put("product_name",   rsRec.getString("product_name"));
                r.put("rating",         String.valueOf(rsRec.getInt("rating")));
                r.put("review_comment", rsRec.getString("review_comment") != null ? rsRec.getString("review_comment").trim() : "");
                r.put("rated_at",       ra != null && ra.length() >= 10 ? ra.substring(0,10) : (ra != null ? ra : ""));
                r.put("cname",          rsRec.getString("cname") != null ? rsRec.getString("cname") : "Customer");
                recentRevs.add(r);
            }
            rsRec.close(); psRec.close();
        } catch (Exception ig) {}

    } catch (Exception e) {
        out.println("<!-- DB error: " + e.getMessage() + " -->");
    }

    String ratingLabel = totalReviews > 0 ? String.format("%.1f", avgRating) : "—";
    String avatarLetter = sellerName.length() > 0 ? String.valueOf(sellerName.charAt(0)).toUpperCase() : "S";
%>

<!-- ═══ SIDEBAR ═══ -->
<aside class="sidebar">
    <div class="sidebar-header">
        <a href="#" class="sidebar-logo">
            <div class="logo-icon"><i class="fas fa-shopping-bag"></i></div>
            <div class="logo-text">
                <h3>MarketHub</h3>
                <span>Admin Panel</span>
            </div>
        </a>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="adhome.jsp" class="nav-link-item"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
        <div class="nav-section-label">Management</div>
        <a href="#" class="nav-link-item active"><i class="fas fa-box"></i><span>Seller Products</span></a>
        <a href="adminProducts.jsp" class="nav-link-item"><i class="fas fa-boxes"></i><span>All Products</span></a>
        <div class="nav-section-label">Account</div>
        <a href="adlogin.jsp" class="nav-link-item"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-chip">
            <div class="admin-avatar">A</div>
            <div class="admin-chip-info">
                <strong>Admin User</strong>
                <span>Super Admin</span>
            </div>
        </div>
    </div>
</aside>

<!-- ═══ MAIN CONTENT ═══ -->
<main class="main-content">

    <!-- Top Bar -->
    <div class="top-bar">
        <div class="top-bar-left">
            <h1><%= sellerName %>'s Store</h1>
            <p>
                <span class="breadcrumb-trail">
                    <a href="adhome.jsp"><i class="fas fa-home"></i> Dashboard</a>
                    <i class="fas fa-chevron-right sep"></i>
                    <span>Seller Products</span>
                    <i class="fas fa-chevron-right sep"></i>
                    <span><%= sellerName %></span>
                </span>
            </p>
        </div>
        <div class="top-bar-right">
            <% if (totalReviews > 0) { %>
            <div class="avg-pill">
                <i class="fas fa-star"></i> <%= ratingLabel %> &bull; <%= totalReviews %> review<%= totalReviews!=1?"s":"" %>
            </div>
            <% } %>
            <a href="adhome.jsp" class="btn-back">
                <i class="fas fa-arrow-left"></i> Back
            </a>
        </div>
    </div>

    <div class="page-body">

        <!-- Seller Hero -->
        <div class="seller-hero">
            <div class="seller-hero-left">
                <div class="seller-hero-avatar"><%= avatarLetter %></div>
                <div>
                    <div class="seller-hero-name"><%= sellerName %></div>
                    <div class="seller-hero-email"><i class="fas fa-envelope"></i><%= sellerEmail %></div>
                </div>
            </div>
            <a href="adhome.jsp" class="btn-back"><i class="fas fa-arrow-left"></i> Back to Dashboard</a>
        </div>

        <!-- ════ STATS GRID ════ -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-box-open"></i></div>
                <div>
                    <div class="stat-val"><%= totalProducts %></div>
                    <div class="stat-lbl">Total Products</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-rupee-sign"></i></div>
                <div>
                    <div class="stat-val">₹<%= String.format("%.0f", totalValue) %></div>
                    <div class="stat-lbl">Inventory Value</div>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon orange"><i class="fas fa-exclamation-triangle"></i></div>
                <div>
                    <div class="stat-val"><%= lowStockCount %></div>
                    <div class="stat-lbl">Low Stock Items</div>
                    <div class="stat-sub">qty &lt; 10</div>
                </div>
            </div>

            <!-- ⭐ Avg Rating -->
            <div class="stat-card">
                <div class="stat-icon gold"><i class="fas fa-star"></i></div>
                <div>
                    <div class="stat-val" style="color:<%= totalReviews>0 ? "var(--star-color)" : "var(--txt-s)" %>;"><%= ratingLabel %></div>
                    <div class="stat-lbl">Avg Rating</div>
                    <div class="stat-sub"><%= totalReviews > 0 ? totalReviews+" review"+(totalReviews!=1?"s":"") : "No reviews yet" %></div>
                </div>
            </div>

            <!-- 💬 Total Reviews -->
            <div class="stat-card">
                <div class="stat-icon violet"><i class="fas fa-comment-dots"></i></div>
                <div>
                    <div class="stat-val"><%= totalReviews %></div>
                    <div class="stat-lbl">Customer Reviews</div>
                    <div class="stat-sub">from delivered orders</div>
                </div>
            </div>
        </div>

        <!-- ════ RATINGS OVERVIEW ════ -->
        <div class="section-card">
            <div class="section-card-header">
                <h3><i class="fas fa-star"></i> Customer Ratings Overview</h3>
                <% if (totalReviews > 0) { %>
                <div class="avg-pill">
                    <i class="fas fa-star"></i> <%= String.format("%.1f",avgRating) %> / 5 &nbsp;&bull;&nbsp; <%= totalReviews %> review<%= totalReviews!=1?"s":"" %>
                </div>
                <% } %>
            </div>

            <% if (totalReviews == 0) { %>
            <div class="no-ratings">
                <i class="fas fa-star"></i>
                <p>No customer reviews yet for this seller's products.</p>
            </div>
            <% } else { %>

            <div class="ratings-body">

                <!-- Big score -->
                <div class="score-block">
                    <div class="score-num"><%= String.format("%.1f", avgRating) %></div>
                    <div class="score-stars">
                        <% int fs = (int)Math.round(avgRating); for(int s=1;s<=5;s++) { %>
                        <i class="fas fa-star" style="<%= s>fs?"color:#d1d5db;":"" %>"></i>
                        <% } %>
                    </div>
                    <div class="score-sub"><%= totalReviews %> review<%= totalReviews!=1?"s":"" %></div>
                </div>

                <!-- Bar breakdown -->
                <div class="bars-block">
                    <% for (int s=5; s>=1; s--) {
                           int cnt = starCounts[s];
                           int pct = totalReviews > 0 ? (int)((double)cnt/totalReviews*100) : 0;
                    %>
                    <div class="rb-row">
                        <span class="rb-lbl"><i class="fas fa-star"></i> <%= s %></span>
                        <div class="rb-track"><div class="rb-fill" style="width:<%= pct %>%;"></div></div>
                        <span class="rb-cnt"><%= cnt %></span>
                    </div>
                    <% } %>
                </div>

                <!-- Recent snippets -->
                <% if (!recentRevs.isEmpty()) { %>
                <div class="snippets-block">
                    <div class="snippets-title">Recent Reviews</div>
                    <% for (java.util.Map<String,String> rv : recentRevs) {
                           int rvStar = 0;
                           try { rvStar = Integer.parseInt(rv.get("rating")); } catch(Exception ig){}
                           String rvCmt = rv.get("review_comment");
                           boolean hasCmt = rvCmt != null && !rvCmt.isEmpty();
                    %>
                    <div class="snippet">
                        <div class="snippet-stars">
                            <% for(int s=1;s<=5;s++) { %>
                            <i class="fas fa-star" style="<%= s>rvStar?"color:#d1d5db;":"" %>font-size:11px;"></i>
                            <% } %>
                        </div>
                        <div class="snippet-body">
                            <div class="snippet-prod"><i class="fas fa-tag"></i><%= rv.get("product_name") %></div>
                            <div class="snippet-cmt <%= hasCmt?"":"no-cmt" %>">
                                <%= hasCmt ? rv.get("review_comment") : "No written review" %>
                            </div>
                            <div class="snippet-meta">
                                <i class="fas fa-user"></i> <%= rv.get("cname") %>
                                &nbsp;&bull;&nbsp;
                                <i class="fas fa-calendar-alt"></i> <%= rv.get("rated_at") %>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                <% } %>

            </div><!-- ratings-body -->
            <% } %>
        </div>

        <!-- ════ PRODUCT TABLE ════ -->
        <div class="section-card">
            <div class="section-card-header">
                <h3><i class="fas fa-box-open"></i> <%= sellerName %>'s Products</h3>
                <span style="font-size:12px;font-weight:700;color:var(--txt-m);
                    background:linear-gradient(135deg,rgba(56,189,248,.1),rgba(129,140,248,.1));
                    padding:5px 14px;border-radius:20px;color:var(--accent2);">
                    <%= totalProducts %> products
                </span>
            </div>

            <table class="product-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Product</th>
                        <th>Price</th>
                        <th>Qty</th>
                        <th>Rating</th>
                        <th>Category</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    try {
                        PreparedStatement pstmt = conn.prepareStatement(
                            "SELECT * FROM adprod WHERE seller_email=? ORDER BY id DESC");
                        pstmt.setString(1, sellerEmail);
                        ResultSet res = pstmt.executeQuery();

                        int sno = 1;
                        boolean hasProd = false;

                        while (res.next()) {
                            hasProd = true;
                            int    pid  = res.getInt("id");
                            String pnm  = res.getString("pname");
                            int    qty  = res.getInt("quantity");
                            double rate = res.getDouble("rate");
                            String cat  = res.getString("category");
                            String dis  = res.getString("proddis");

                            String qCls = qty < 10 ? "qty-low" : qty < 30 ? "qty-mid" : "qty-ok";
                            String pRat = prodAvgMap.get(pid);
                %>
                <tr>
                    <td><div class="sno"><%= sno++ %></div></td>
                    <td>
                        <div class="prod-cell">
                            <div class="prod-thumb"><i class="fas fa-box-open"></i></div>
                            <div class="prod-name"><%= pnm %></div>
                        </div>
                    </td>
                    <td><span class="price-val">₹<%= String.format("%.0f", rate) %></span></td>
                    <td><span class="qty-val <%= qCls %>"><%= qty %></span></td>
                    <td>
                        <% if (pRat != null) { %>
                        <span class="prod-rating-badge"><i class="fas fa-star"></i> <%= pRat %></span>
                        <% } else { %>
                        <span class="no-rev"><i class="far fa-star"></i> —</span>
                        <% } %>
                    </td>
                    <td><span class="cat-badge"><i class="fas fa-tag"></i> <%= cat %></span></td>
                    <td><div class="desc-val"><%= dis %></div></td>
                </tr>
                <%
                        }

                        if (!hasProd) {
                %>
                <tr>
                    <td colspan="7">
                        <div class="empty-row">
                            <i class="fas fa-box-open"></i>
                            <p>No products listed yet</p>
                            <small>This seller hasn't added any products.</small>
                        </div>
                    </td>
                </tr>
                <%
                        }
                        res.close(); pstmt.close();
                    } catch (Exception e) {
                        out.println("<tr><td colspan='7' style='padding:30px;text-align:center;color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                    } finally {
                        try { if (conn != null) conn.close(); } catch (Exception ig) {}
                    }
                %>
                </tbody>
            </table>
        </div>

    </div><!-- page-body -->
</main>

<script>
    document.addEventListener('DOMContentLoaded', function () {
        /* Animate rating bars */
        document.querySelectorAll('.rb-fill').forEach(function (bar) {
            var w = bar.style.width;
            bar.style.width = '0';
            bar.style.transition = 'width 0.85s cubic-bezier(.4,0,.2,1)';
            setTimeout(function () { bar.style.width = w; }, 250);
        });
    });
</script>
</body>
</html>
