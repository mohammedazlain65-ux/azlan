<%-- 
    Document   : sellerprofile
    Description: Seller profile page — shows logged-in seller's data from `sellers` table.
                 Inline edit with AJAX update via updatesellerprofile servlet.
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    /* ── Session Auth ─────────────────────────────────────────────── */
    HttpSession hs = request.getSession();
    String sessionEmail = null;
    try {
        sessionEmail = hs.getAttribute("email").toString();
        if (sessionEmail == null || sessionEmail.trim().equals("")) {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
            return;
        }
    } catch (Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        return;
    }

    /* ── DB Config ────────────────────────────────────────────────── */
    String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "";

    /* ── Fetch seller from DB ─────────────────────────────────────── */
    int    sellerId      = 0;
    String sellerName    = "";
    String sellerEmail   = "";
    String sellerPhone   = "";
    String businessName  = "";
    String sellerStatus  = "";
    String dbError       = null;

    Connection conn = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbURL, dbUser, dbPass);

        PreparedStatement ps = conn.prepareStatement(
            "SELECT id, name, email, phone, business_name, status FROM sellers WHERE email = ? LIMIT 1"
        );
        ps.setString(1, sessionEmail);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            sellerId     = rs.getInt("id");
            sellerName   = rs.getString("name")          != null ? rs.getString("name")          : "";
            sellerEmail  = rs.getString("email")         != null ? rs.getString("email")         : "";
            sellerPhone  = rs.getString("phone")         != null ? rs.getString("phone")         : "";
            businessName = rs.getString("business_name") != null ? rs.getString("business_name") : "";
            sellerStatus = rs.getString("status")        != null ? rs.getString("status")        : "";
        } else {
            dbError = "No seller profile found for: " + sessionEmail;
        }
        rs.close(); ps.close();
    } catch (Exception ex) {
        dbError = "Database error: " + ex.getMessage();
    } finally {
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }

    /* ── Avatar initial ── */
    String avatarChar = (sellerName != null && sellerName.length() > 0)
                        ? String.valueOf(sellerName.charAt(0)).toUpperCase() : "S";
    boolean isApproved = "approved".equalsIgnoreCase(sellerStatus);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile — MarketHub Seller</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">

    <style>
        :root {
            --ink:        #0d0d14;
            --ink-soft:   #3d3d52;
            --muted:      #8b8ba0;
            --border:     #e8e8f0;
            --surface:    #ffffff;
            --canvas:     #f5f5fa;
            --accent:     #5b4bdb;
            --accent-2:   #9b59b6;
            --accent-glow:rgba(91,75,219,0.18);
            --success:    #0fa872;
            --danger:     #e5294e;
            --warning:    #e8900a;
            --sidebar-bg: #0d0d14;
            --sidebar-w:  260px;
            --radius:     16px;
            --shadow-sm:  0 2px 12px rgba(13,13,20,.06);
            --shadow-md:  0 8px 32px rgba(13,13,20,.10);
            --shadow-lg:  0 20px 60px rgba(13,13,20,.14);
        }

        *, *::before, *::after { margin:0; padding:0; box-sizing:border-box; }

        body {
            font-family: 'Sora', sans-serif;
            background: var(--canvas);
            color: var(--ink);
            min-height: 100vh;
            overflow-x: hidden;
        }

        /* ── Sidebar ──────────────────────────────────── */
        .sidebar {
            position: fixed; left:0; top:0;
            height: 100vh; width: var(--sidebar-w);
            background: var(--sidebar-bg);
            z-index: 1000; overflow-y: auto;
            display: flex; flex-direction: column;
        }
        .sidebar::-webkit-scrollbar { width:4px; }
        .sidebar::-webkit-scrollbar-thumb { background:rgba(255,255,255,.12); border-radius:2px; }

        .sb-brand {
            padding: 28px 22px 22px;
            border-bottom: 1px solid rgba(255,255,255,.07);
            display: flex; align-items: center; gap: 12px;
            text-decoration: none;
        }
        .sb-brand-icon {
            width: 40px; height: 40px; border-radius: 12px;
            background: linear-gradient(135deg, var(--accent), var(--accent-2));
            display: flex; align-items: center; justify-content: center;
            color: white; font-size: 18px;
        }
        .sb-brand-text { color: white; font-size: 18px; font-weight: 800; letter-spacing: -.4px; }
        .sb-brand-pill {
            background: linear-gradient(90deg, var(--accent), var(--accent-2));
            color: white; font-size: 9px; font-weight: 700;
            padding: 3px 7px; border-radius: 8px; letter-spacing: .8px;
            text-transform: uppercase; margin-left: 4px;
        }

        .sb-section { padding: 22px 14px 8px; }
        .sb-section-label {
            color: rgba(255,255,255,.28); font-size: 10px; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1.4px; padding: 0 8px 10px;
        }
        .sb-link {
            display: flex; align-items: center; gap: 13px;
            padding: 11px 14px; border-radius: 10px;
            color: rgba(255,255,255,.6); text-decoration: none;
            font-size: 13.5px; font-weight: 500; transition: all .22s;
            margin-bottom: 2px;
        }
        .sb-link i { font-size: 16px; width: 18px; text-align: center; }
        .sb-link:hover { background: rgba(255,255,255,.07); color: white; }
        .sb-link.active { background: linear-gradient(90deg,rgba(91,75,219,.35),rgba(155,89,182,.2)); color: white; }
        .sb-link.active i { color: #a78bfa; }
        .sb-badge {
            margin-left: auto; background: var(--danger); color: white;
            font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 8px;
        }

        /* ── Main layout ──────────────────────────────── */
        .main { margin-left: var(--sidebar-w); min-height: 100vh; }

        /* ── Top bar ──────────────────────────────────── */
        .topbar {
            background: var(--surface); padding: 18px 36px;
            display: flex; align-items: center; justify-content: space-between;
            border-bottom: 1px solid var(--border);
            position: sticky; top:0; z-index: 900;
            box-shadow: var(--shadow-sm);
        }
        .topbar-left h2 {
            font-size: 22px; font-weight: 800; color: var(--ink); letter-spacing: -.4px;
        }
        .topbar-left .crumb {
            font-size: 12px; color: var(--muted); font-weight: 500; margin-top: 2px;
        }
        .topbar-left .crumb a { color: var(--accent); text-decoration: none; }
        .topbar-right { display: flex; align-items: center; gap: 14px; }
        .topbar-avatar {
            width: 40px; height: 40px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent), var(--accent-2));
            display: flex; align-items: center; justify-content: center;
            color: white; font-size: 16px; font-weight: 700;
            border: 2px solid var(--border);
        }

        /* ── Page body ────────────────────────────────── */
        .page-body { padding: 36px; max-width: 1100px; }

        /* ── Profile hero card ────────────────────────── */
        .profile-hero {
            background: var(--surface);
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--shadow-md);
            margin-bottom: 28px;
            position: relative;
        }
        .hero-banner {
            height: 130px;
            background: linear-gradient(135deg, #1a0533 0%, #2d1464 40%, #0d0d2e 100%);
            position: relative; overflow: hidden;
        }
        .hero-banner::before {
            content: '';
            position: absolute; inset: 0;
            background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
        }
        /* Floating orbs */
        .hero-banner::after {
            content: '';
            position: absolute; top: -30px; right: -30px;
            width: 200px; height: 200px; border-radius: 50%;
            background: radial-gradient(circle, rgba(91,75,219,.4) 0%, transparent 70%);
        }

        .hero-content {
            padding: 0 32px 28px;
            display: flex; align-items: flex-end; gap: 24px;
            position: relative;
        }
        .profile-avatar-wrap {
            flex-shrink: 0; margin-top: -44px; position: relative;
        }
        .profile-avatar {
            width: 88px; height: 88px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent), var(--accent-2));
            display: flex; align-items: center; justify-content: center;
            font-size: 34px; font-weight: 800; color: white;
            border: 4px solid var(--surface);
            box-shadow: var(--shadow-md);
            font-family: 'JetBrains Mono', monospace;
        }
        .avatar-status {
            position: absolute; bottom: 4px; right: 4px;
            width: 20px; height: 20px; border-radius: 50%;
            border: 3px solid var(--surface);
        }
        .avatar-status.approved  { background: var(--success); }
        .avatar-status.pending   { background: var(--warning); }
        .avatar-status.suspended { background: var(--danger); }

        .profile-meta { flex: 1; padding-top: 16px; }
        .profile-meta h1 {
            font-size: 24px; font-weight: 800; color: var(--ink); letter-spacing: -.5px;
            margin-bottom: 4px;
        }
        .profile-meta .biz-name {
            font-size: 14px; color: var(--muted); font-weight: 500;
            display: flex; align-items: center; gap: 7px;
        }
        .profile-meta .biz-name i { color: var(--accent); font-size: 13px; }

        .status-chip {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 700;
            text-transform: uppercase; letter-spacing: .5px;
        }
        .status-chip.approved  { background: rgba(15,168,114,.12); color: var(--success); border: 1px solid rgba(15,168,114,.3); }
        .status-chip.pending   { background: rgba(232,144,10,.12);  color: var(--warning); border: 1px solid rgba(232,144,10,.3); }
        .status-chip.suspended { background: rgba(229,41,78,.12);   color: var(--danger);  border: 1px solid rgba(229,41,78,.3); }

        .hero-actions { display: flex; gap: 10px; align-items: center; margin-left: auto; padding-top: 16px; }

        /* ── Profile sections ─────────────────────────── */
        .profile-grid {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 24px;
        }

        .section-card {
            background: var(--surface); border-radius: var(--radius);
            box-shadow: var(--shadow-sm); overflow: hidden;
            border: 1px solid var(--border);
        }
        .section-head {
            padding: 20px 26px 16px;
            display: flex; align-items: center; justify-content: space-between;
            border-bottom: 1px solid var(--border);
        }
        .section-head h3 {
            font-size: 15px; font-weight: 700; color: var(--ink);
            display: flex; align-items: center; gap: 9px;
        }
        .section-head h3 i { color: var(--accent); font-size: 16px; }
        .section-body { padding: 24px 26px; }

        /* ── Field rows ───────────────────────────────── */
        .field-row {
            display: flex; align-items: center;
            padding: 14px 0;
            border-bottom: 1px dashed var(--border);
            gap: 16px;
        }
        .field-row:last-child { border-bottom: none; }

        .field-icon {
            width: 38px; height: 38px; border-radius: 10px;
            background: rgba(91,75,219,.08); color: var(--accent);
            display: flex; align-items: center; justify-content: center;
            font-size: 15px; flex-shrink: 0;
        }
        .field-content { flex: 1; min-width: 0; }
        .field-label { font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .6px; margin-bottom: 4px; }

        /* View mode */
        .field-value {
            font-size: 15px; font-weight: 600; color: var(--ink);
            display: flex; align-items: center; gap: 8px;
        }
        .field-value.mono { font-family: 'JetBrains Mono', monospace; font-size: 14px; }

        /* Edit mode */
        .field-input {
            width: 100%; padding: 9px 13px;
            border: 2px solid var(--border); border-radius: 10px;
            font-family: 'Sora', sans-serif; font-size: 14px; font-weight: 500;
            color: var(--ink); background: var(--canvas);
            transition: all .2s; outline: none;
            display: none;
        }
        .field-input:focus { border-color: var(--accent); background: white; box-shadow: 0 0 0 4px var(--accent-glow); }

        .field-edit-btn {
            width: 34px; height: 34px; border-radius: 9px; border: none;
            background: rgba(91,75,219,.08); color: var(--accent);
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; transition: all .2s; flex-shrink: 0;
            font-size: 13px;
        }
        .field-edit-btn:hover { background: var(--accent); color: white; transform: scale(1.08); }

        /* ── Edit / Save bar ──────────────────────────── */
        .edit-bar {
            display: none;
            background: linear-gradient(90deg, rgba(91,75,219,.07), rgba(155,89,182,.07));
            border-top: 1px solid rgba(91,75,219,.15);
            padding: 16px 26px;
            align-items: center; justify-content: space-between; gap: 14px;
        }
        .edit-bar.show { display: flex; }
        .edit-bar .note { font-size: 13px; color: var(--ink-soft); font-weight: 500; }
        .edit-bar .note i { color: var(--accent); margin-right: 5px; }
        .btn-save {
            padding: 10px 28px; border-radius: 10px; border: none;
            background: linear-gradient(135deg, var(--accent), var(--accent-2));
            color: white; font-family: 'Sora', sans-serif;
            font-size: 13px; font-weight: 700; cursor: pointer;
            transition: all .25s; display: flex; align-items: center; gap: 8px;
            box-shadow: 0 6px 20px rgba(91,75,219,.3);
        }
        .btn-save:hover { transform: translateY(-2px); box-shadow: 0 10px 28px rgba(91,75,219,.4); }
        .btn-save:disabled { opacity: .65; cursor: not-allowed; transform: none; }
        .btn-cancel {
            padding: 10px 20px; border-radius: 10px;
            border: 2px solid var(--border); background: white;
            font-family: 'Sora', sans-serif; font-size: 13px; font-weight: 600;
            color: var(--ink-soft); cursor: pointer; transition: all .2s;
        }
        .btn-cancel:hover { border-color: var(--danger); color: var(--danger); }

        /* ── Info sidebar card ────────────────────────── */
        .info-item {
            display: flex; align-items: flex-start; gap: 13px;
            padding: 16px 0; border-bottom: 1px solid var(--border);
        }
        .info-item:last-child { border-bottom: none; }
        .info-icon {
            width: 36px; height: 36px; border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 15px; flex-shrink: 0;
        }
        .info-icon.green  { background: rgba(15,168,114,.1); color: var(--success); }
        .info-icon.purple { background: rgba(91,75,219,.1);  color: var(--accent); }
        .info-icon.amber  { background: rgba(232,144,10,.1); color: var(--warning); }
        .info-icon.red    { background: rgba(229,41,78,.1);  color: var(--danger); }
        .info-text-label { font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .5px; margin-bottom: 3px; }
        .info-text-val   { font-size: 14px; font-weight: 600; color: var(--ink); }

        /* ── Security section ─────────────────────────── */
        .security-item {
            display: flex; align-items: center; justify-content: space-between;
            padding: 15px 0; border-bottom: 1px solid var(--border);
        }
        .security-item:last-child { border-bottom: none; }
        .sec-left { display: flex; align-items: center; gap: 12px; }
        .sec-icon {
            width: 38px; height: 38px; border-radius: 10px; font-size: 16px;
            display: flex; align-items: center; justify-content: center;
        }
        .sec-icon.green  { background: rgba(15,168,114,.1); color: var(--success); }
        .sec-icon.purple { background: rgba(91,75,219,.1);  color: var(--accent); }
        .sec-title { font-size: 14px; font-weight: 700; color: var(--ink); }
        .sec-sub   { font-size: 12px; color: var(--muted); font-weight: 500; }
        .sec-status {
            font-size: 12px; font-weight: 700; padding: 4px 11px; border-radius: 8px;
        }
        .sec-status.ok   { background: rgba(15,168,114,.1); color: var(--success); }
        .sec-status.warn { background: rgba(232,144,10,.1);  color: var(--warning); }

        /* ── Toast ────────────────────────────────────── */
        .toast-wrap { position: fixed; bottom: 28px; right: 28px; z-index: 9999; display: flex; flex-direction: column; gap: 10px; }
        .toast-msg {
            padding: 14px 20px; border-radius: 12px;
            font-size: 14px; font-weight: 600;
            display: flex; align-items: center; gap: 10px;
            min-width: 280px; box-shadow: var(--shadow-lg);
            animation: toastIn .35s cubic-bezier(.34,1.56,.64,1);
        }
        .toast-success { background: #ecfdf5; color: #065f46; border-left: 4px solid var(--success); }
        .toast-error   { background: #fef2f2; color: #991b1b; border-left: 4px solid var(--danger); }
        @keyframes toastIn { from { opacity:0; transform: translateY(16px) scale(.95); } to { opacity:1; transform: translateY(0) scale(1); } }

        /* ── Animations ───────────────────────────────── */
        @keyframes fadeUp { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
        .profile-hero    { animation: fadeUp .5s ease forwards; }
        .section-card    { animation: fadeUp .5s ease forwards; }
        .section-card:nth-child(2) { animation-delay: .1s; }

        /* ── Responsive ───────────────────────────────── */
        @media (max-width: 960px) {
            .sidebar { display: none; }
            .main    { margin-left: 0; }
            .profile-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 600px) {
            .page-body { padding: 20px; }
            .hero-content { flex-direction: column; align-items: flex-start; }
            .hero-actions { margin-left: 0; }
        }
    </style>
</head>
<body>

<!-- ══════════════════ SIDEBAR ══════════════════ -->
<aside class="sidebar">
    <a href="sellerdashboard.jsp" class="sb-brand">
        <div class="sb-brand-icon"><i class="fas fa-store"></i></div>
        <span class="sb-brand-text">MarketHub <span class="sb-brand-pill">Seller</span></span>
    </a>

    <div class="sb-section">
        <div class="sb-section-label">Main</div>
        <a href="sellerdashboard.jsp" class="sb-link"><i class="fas fa-th-large"></i> Dashboard</a>
        <a href="Sellerorders.jsp"    class="sb-link"><i class="fas fa-shopping-cart"></i> My Orders <span class="sb-badge">New</span></a>
        <a href="viewproduct.jsp"     class="sb-link"><i class="fas fa-box"></i> My Products</a>
        <a href="addprod.jsp"         class="sb-link"><i class="fas fa-plus-circle"></i> Add Product</a>
        <a href="#"                   class="sb-link"><i class="fas fa-warehouse"></i> Inventory</a>
    </div>

    

    <div class="sb-section">
        <div class="sb-section-label">Account</div>
        <a href="updatesellerprofile.jsp" class="sb-link active"><i class="fas fa-user-circle"></i> My Profile</a>
        
        <a href="ulogout"           class="sb-link"><i class="fas fa-sign-out-alt"></i> Logout</a>
    </div>
</aside>

<!-- ══════════════════ MAIN ══════════════════ -->
<div class="main">

    <!-- Top bar -->
    <div class="topbar">
        <div class="topbar-left">
            <h2>My Profile</h2>
            <div class="crumb">
                <a href="sellerdashboard.jsp">Dashboard</a>
                &nbsp;/&nbsp; Profile
            </div>
        </div>
        <div class="topbar-right">
            <span style="font-size:13px;font-weight:600;color:var(--muted);"><%= sessionEmail %></span>
            <div class="topbar-avatar"><%= avatarChar %></div>
        </div>
    </div>

    <!-- Page body -->
    <div class="page-body">

        <% if (dbError != null) { %>
        <div style="background:#fef2f2;border:2px solid var(--danger);border-radius:12px;padding:18px 22px;margin-bottom:24px;color:var(--danger);font-weight:600;font-size:14px;display:flex;align-items:center;gap:12px;">
            <i class="fas fa-exclamation-circle"></i>
            <%= dbError %>
        </div>
        <% } %>

        <!-- ── Profile Hero Card ── -->
        <div class="profile-hero">
            <div class="hero-banner">
                <!-- decorative circles -->
                <div style="position:absolute;bottom:-40px;left:60px;width:160px;height:160px;border-radius:50%;background:radial-gradient(circle,rgba(155,89,182,.2) 0%,transparent 70%);"></div>
            </div>
            <div class="hero-content">
                <div class="profile-avatar-wrap">
                    <div class="profile-avatar"><%= avatarChar %></div>
                    <div class="avatar-status <%= isApproved ? "approved" : "pending" %>"></div>
                </div>
                <div class="profile-meta">
                    <h1><%= sellerName.isEmpty() ? "Seller Name" : sellerName %></h1>
                    <div class="biz-name">
                        <i class="fas fa-store"></i>
                        <%= businessName.isEmpty() ? "Business Name" : businessName %>
                    </div>
                </div>
                <div class="hero-actions">
                    <span class="status-chip <%= sellerStatus.toLowerCase() %>">
                        <i class="fas fa-<%= isApproved ? "check-circle" : "clock" %>"></i>
                        <%= sellerStatus.substring(0,1).toUpperCase() + sellerStatus.substring(1) %>
                    </span>
                    <button class="btn-save" onclick="enterEditMode()" id="heroEditBtn" style="padding:9px 20px;font-size:13px;">
                        <i class="fas fa-pen"></i> Edit Profile
                    </button>
                </div>
            </div>
        </div>

        <!-- ── Profile grid ── -->
        <div class="profile-grid">

            <!-- LEFT: Editable fields -->
            <div>
                <div class="section-card" id="profileCard">
                    <div class="section-head">
                        <h3><i class="fas fa-id-card"></i> Profile Information</h3>
                        <span style="font-size:12px;font-weight:600;color:var(--muted);">Seller ID: #<%= sellerId %></span>
                    </div>
                    <div class="section-body">

                        <!-- Full Name -->
                        <div class="field-row">
                            <div class="field-icon"><i class="fas fa-user"></i></div>
                            <div class="field-content">
                                <div class="field-label">Full Name</div>
                                <div class="field-value" id="view-name"><%= sellerName %></div>
                                <input class="field-input" id="edit-name" type="text"
                                       value="<%= sellerName %>" placeholder="Enter your full name" maxlength="40">
                            </div>
                            <button class="field-edit-btn edit-trigger" onclick="focusField('edit-name')" title="Edit"><i class="fas fa-pen"></i></button>
                        </div>

                        <!-- Email (read-only) -->
                        <div class="field-row">
                            <div class="field-icon"><i class="fas fa-envelope"></i></div>
                            <div class="field-content">
                                <div class="field-label">Email Address</div>
                                <div class="field-value mono" id="view-email"><%= sellerEmail %></div>
                                <input class="field-input" id="edit-email" type="email"
                                       value="<%= sellerEmail %>" placeholder="Email address" disabled
                                       style="opacity:.6;cursor:not-allowed;">
                            </div>
                            <button class="field-edit-btn" title="Email cannot be changed" style="opacity:.35;cursor:default;">
                                <i class="fas fa-lock"></i>
                            </button>
                        </div>

                        <!-- Phone -->
                        <div class="field-row">
                            <div class="field-icon"><i class="fas fa-phone"></i></div>
                            <div class="field-content">
                                <div class="field-label">Phone Number</div>
                                <div class="field-value mono" id="view-phone"><%= sellerPhone %></div>
                                <input class="field-input" id="edit-phone" type="tel"
                                       value="<%= sellerPhone %>" placeholder="10-digit phone" maxlength="15">
                            </div>
                            <button class="field-edit-btn edit-trigger" onclick="focusField('edit-phone')" title="Edit"><i class="fas fa-pen"></i></button>
                        </div>

                        <!-- Business Name -->
                        <div class="field-row">
                            <div class="field-icon"><i class="fas fa-store"></i></div>
                            <div class="field-content">
                                <div class="field-label">Business Name</div>
                                <div class="field-value" id="view-business"><%= businessName %></div>
                                <input class="field-input" id="edit-business" type="text"
                                       value="<%= businessName %>" placeholder="Your store / business name" maxlength="400">
                            </div>
                            <button class="field-edit-btn edit-trigger" onclick="focusField('edit-business')" title="Edit"><i class="fas fa-pen"></i></button>
                        </div>

                        <!-- Account Status (read-only display) -->
                        <div class="field-row">
                            <div class="field-icon"><i class="fas fa-shield-alt"></i></div>
                            <div class="field-content">
                                <div class="field-label">Account Status</div>
                                <div class="field-value">
                                    <span class="status-chip <%= sellerStatus.toLowerCase() %>">
                                        <i class="fas fa-<%= isApproved ? "check-circle" : "clock" %>"></i>
                                        <%= sellerStatus.substring(0,1).toUpperCase() + sellerStatus.substring(1) %>
                                    </span>
                                </div>
                            </div>
                            <button class="field-edit-btn" title="Status set by admin" style="opacity:.35;cursor:default;">
                                <i class="fas fa-lock"></i>
                            </button>
                        </div>

                    </div><!-- /section-body -->

                    <!-- Save / Cancel bar -->
                    <div class="edit-bar" id="editBar">
                        <span class="note"><i class="fas fa-info-circle"></i> Changes will update your seller profile immediately.</span>
                        <div style="display:flex;gap:10px;">
                            <button class="btn-cancel" onclick="cancelEdit()">Cancel</button>
                            <button class="btn-save" id="saveBtn" onclick="saveProfile()">
                                <i class="fas fa-save"></i> Save Changes
                            </button>
                        </div>
                    </div>

                </div><!-- /section-card -->
            </div><!-- /left col -->

            <!-- RIGHT: Info + Security sidebar -->
            <div style="display:flex;flex-direction:column;gap:22px;">

                <!-- Account Summary -->
                <div class="section-card">
                    <div class="section-head">
                        <h3><i class="fas fa-chart-pie"></i> Account Summary</h3>
                    </div>
                    <div class="section-body">
                        <div class="info-item">
                            <div class="info-icon purple"><i class="fas fa-hashtag"></i></div>
                            <div>
                                <div class="info-text-label">Seller ID</div>
                                <div class="info-text-val" style="font-family:'JetBrains Mono',monospace;">#<%= sellerId %></div>
                            </div>
                        </div>
                        <div class="info-item">
                            <div class="info-icon green"><i class="fas fa-store"></i></div>
                            <div>
                                <div class="info-text-label">Store Name</div>
                                <div class="info-text-val" id="side-business"><%= businessName.isEmpty() ? "—" : businessName %></div>
                            </div>
                        </div>
                        <div class="info-item">
                            <div class="info-icon purple"><i class="fas fa-envelope"></i></div>
                            <div>
                                <div class="info-text-label">Email</div>
                                <div class="info-text-val" style="font-size:13px;word-break:break-all;"><%= sellerEmail %></div>
                            </div>
                        </div>
                        <div class="info-item">
                            <div class="info-icon amber"><i class="fas fa-phone"></i></div>
                            <div>
                                <div class="info-text-label">Contact</div>
                                <div class="info-text-val" id="side-phone" style="font-family:'JetBrains Mono',monospace;"><%= sellerPhone.isEmpty() ? "—" : sellerPhone %></div>
                            </div>
                        </div>
                        <div class="info-item">
                            <div class="info-icon <%= isApproved ? "green" : "amber" %>"><i class="fas fa-shield-alt"></i></div>
                            <div>
                                <div class="info-text-label">Approval Status</div>
                                <div class="info-text-val">
                                    <span class="status-chip <%= sellerStatus.toLowerCase() %>">
                                        <%= sellerStatus.substring(0,1).toUpperCase() + sellerStatus.substring(1) %>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Security -->
                <div class="section-card">
                    <div class="section-head">
                        <h3><i class="fas fa-lock"></i> Security</h3>
                    </div>
                    <div class="section-body">
                        <div class="security-item">
                            <div class="sec-left">
                                <div class="sec-icon green"><i class="fas fa-envelope-open-text"></i></div>
                                <div>
                                    <div class="sec-title">Email Verified</div>
                                    <div class="sec-sub"><%= sellerEmail %></div>
                                </div>
                            </div>
                            <span class="sec-status ok"><i class="fas fa-check"></i> Verified</span>
                        </div>
                        <div class="security-item">
                            <div class="sec-left">
                                <div class="sec-icon purple"><i class="fas fa-key"></i></div>
                                <div>
                                    <div class="sec-title">Password</div>
                                    <div class="sec-sub">Last changed: Unknown</div>
                                </div>
                            </div>
                            <a href="#" style="font-size:12px;font-weight:700;color:var(--accent);text-decoration:none;padding:4px 11px;border:1px solid rgba(91,75,219,.3);border-radius:8px;transition:all .2s;"
                               onmouseover="this.style.background='rgba(91,75,219,.08)'"
                               onmouseout="this.style.background='transparent'">Change</a>
                        </div>
                        <div class="security-item">
                            <div class="sec-left">
                                <div class="sec-icon amber"><i class="fas fa-mobile-alt"></i></div>
                                <div>
                                    <div class="sec-title">Two-Factor Auth</div>
                                    <div class="sec-sub">SMS / Authenticator</div>
                                </div>
                            </div>
                            <span class="sec-status warn">Not set</span>
                        </div>
                    </div>
                </div>

                <!-- Danger zone -->
                <div class="section-card" style="border-color:rgba(229,41,78,.2);">
                    <div class="section-head" style="border-color:rgba(229,41,78,.15);">
                        <h3 style="color:var(--danger);"><i class="fas fa-exclamation-triangle" style="color:var(--danger);"></i> Danger Zone</h3>
                    </div>
                    <div class="section-body">
                        <p style="font-size:13px;color:var(--muted);font-weight:500;margin-bottom:14px;line-height:1.6;">
                            These actions are irreversible. Please proceed with caution.
                        </p>
                        <button onclick="confirmLogout()" style="width:100%;padding:11px;border-radius:10px;border:2px solid rgba(229,41,78,.3);background:rgba(229,41,78,.05);color:var(--danger);font-family:'Sora',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:all .2s;display:flex;align-items:center;justify-content:center;gap:8px;"
                                onmouseover="this.style.background='rgba(229,41,78,.1)'"
                                onmouseout="this.style.background='rgba(229,41,78,.05)'">
                            <i class="fas fa-sign-out-alt"></i> Logout from Account
                        </button>
                    </div>
                </div>

            </div><!-- /right col -->
        </div><!-- /profile-grid -->
    </div><!-- /page-body -->
</div><!-- /main -->

<div class="toast-wrap" id="toastWrap"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    /* ── State ──────────────────────────────────────── */
    let editMode = false;
    const editableFields = ['name', 'phone', 'business'];

    /* ── Enter edit mode ───────────────────────────── */
    function enterEditMode() {
        editMode = true;
        editableFields.forEach(f => {
            document.getElementById('view-' + f).style.display    = 'none';
            document.getElementById('edit-' + f).style.display    = 'block';
        });
        document.getElementById('editBar').classList.add('show');
        document.getElementById('heroEditBtn').style.display = 'none';
        document.querySelectorAll('.edit-trigger').forEach(btn => {
            btn.style.background = 'rgba(91,75,219,.15)';
        });
        document.getElementById('edit-name').focus();
    }

    /* ── Focus a specific field (via row-level pen icon) */
    function focusField(id) {
        if (!editMode) enterEditMode();
        document.getElementById(id).focus();
    }

    /* ── Cancel ────────────────────────────────────── */
    function cancelEdit() {
        editMode = false;
        editableFields.forEach(f => {
            document.getElementById('view-' + f).style.display    = '';
            document.getElementById('edit-' + f).style.display    = 'none';
        });
        document.getElementById('editBar').classList.remove('show');
        document.getElementById('heroEditBtn').style.display = '';
        document.querySelectorAll('.edit-trigger').forEach(btn => btn.style.background = '');
    }

    /* ── Save via AJAX ──────────────────────────────── */
    function saveProfile() {
        const name     = document.getElementById('edit-name').value.trim();
        const phone    = document.getElementById('edit-phone').value.trim();
        const business = document.getElementById('edit-business').value.trim();

        if (!name)     { showToast('error', '✗ Full name cannot be empty.'); document.getElementById('edit-name').focus(); return; }
        if (!phone)    { showToast('error', '✗ Phone number cannot be empty.'); document.getElementById('edit-phone').focus(); return; }
        if (!business) { showToast('error', '✗ Business name cannot be empty.'); document.getElementById('edit-business').focus(); return; }
        if (!/^\d{7,15}$/.test(phone)) { showToast('error', '✗ Enter a valid phone number (7–15 digits).'); document.getElementById('edit-phone').focus(); return; }

        const saveBtn = document.getElementById('saveBtn');
        saveBtn.disabled = true;
        saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving…';

        fetch('updatesellerprofile', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'name='         + encodeURIComponent(name)
                + '&phone='      + encodeURIComponent(phone)
                + '&businessName=' + encodeURIComponent(business)
        })
        .then(r => r.json())
        .then(data => {
            saveBtn.disabled = false;
            saveBtn.innerHTML = '<i class="fas fa-save"></i> Save Changes';

            if (data.success) {
                /* Update view values */
                document.getElementById('view-name').textContent     = name;
                document.getElementById('view-phone').textContent    = phone;
                document.getElementById('view-business').textContent = business;

                /* Update hero card */
                document.querySelector('.profile-meta h1').textContent = name;
                document.querySelector('.profile-meta .biz-name').innerHTML =
                    '<i class="fas fa-store"></i> ' + business;

                /* Update sidebar summary */
                document.getElementById('side-business').textContent = business;
                document.getElementById('side-phone').textContent    = phone;

                /* Update avatar char */
                const char = name.charAt(0).toUpperCase();
                document.querySelectorAll('.profile-avatar, .topbar-avatar').forEach(el => {
                    if (el.children.length === 0) el.textContent = char;
                });

                cancelEdit();
                showToast('success', '✓ Profile updated successfully!');
            } else {
                showToast('error', '✗ ' + (data.message || 'Update failed. Try again.'));
            }
        })
        .catch(() => {
            saveBtn.disabled = false;
            saveBtn.innerHTML = '<i class="fas fa-save"></i> Save Changes';
            showToast('error', '✗ Network error. Please try again.');
        });
    }

    /* ── Toast ──────────────────────────────────────── */
    function showToast(type, msg) {
        const wrap = document.getElementById('toastWrap');
        const t    = document.createElement('div');
        t.className = 'toast-msg toast-' + type;
        t.innerHTML = '<i class="fas fa-' + (type === 'success' ? 'check-circle' : 'exclamation-circle') + '"></i> ' + msg;
        wrap.appendChild(t);
        setTimeout(() => { t.style.transition = 'opacity .4s'; t.style.opacity = '0'; setTimeout(() => t.remove(), 450); }, 4000);
    }

    /* ── Logout confirm ─────────────────────────────── */
    function confirmLogout() {
        if (confirm('Are you sure you want to logout?')) {
            window.location.href = 'ulogout';
        }
    }

    /* ── Enter key shortcut in fields ──────────────── */
    ['edit-name','edit-phone','edit-business'].forEach(id => {
        document.getElementById(id).addEventListener('keydown', e => {
            if (e.key === 'Enter') saveProfile();
            if (e.key === 'Escape') cancelEdit();
        });
    });
</script>
</body>
</html>
