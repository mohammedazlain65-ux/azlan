<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%--
  ╔════════════════════════════════════════════════════════════════════╗
  ║  admin/sellerApprovals.jsp                                         ║
  ║  Seller Approvals & Activeness — Admin Dashboard                   ║
  ║  DB columns: id, name, email, phone, business_name, status         ║
  ╚════════════════════════════════════════════════════════════════════╝
--%>
<%!
    private static final String DB_URL  =
        "jdbc:mysql://localhost:3306/multi_vendor" +
        "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    Connection getConn() throws Exception {
        Class.forName("com.mysql.jdbc.Driver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }
    void closeAll(AutoCloseable... res) {
        for (AutoCloseable r : res) { try { if (r != null) r.close(); } catch (Exception ignored){} }
    }
%>

<%
    // String adminRole = (String) session.getAttribute("adminRole");
    // if (!"admin".equals(adminRole)) { response.sendRedirect("../login.jsp"); return; }

    String actionMsg  = "";
    String actionType = "ok";

    String action = request.getParameter("action");
    if (action == null) action = "";

    /* ══════════════════════════════════════════════════════
       POST ACTIONS  —  uses real column: status, id
    ══════════════════════════════════════════════════════ */
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String sellerId = request.getParameter("sellerId");

        if ("approve".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='approved' WHERE id=? AND status='pending'");
                ps.setString(1, sellerId);
                int rows = ps.executeUpdate();
                if (rows > 0) { actionMsg = "✅ Seller <strong>#" + sellerId + "</strong> has been <strong>Approved</strong>."; actionType = "ok"; }
                else          { actionMsg = "⚠️ Seller not found or already processed."; actionType = "wrn"; }
            } catch (Exception e) { actionMsg = "❌ Error approving: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("reject".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='rejected' WHERE id=?");
                ps.setString(1, sellerId); ps.executeUpdate();
                actionMsg = "🚫 Seller <strong>#" + sellerId + "</strong> has been <strong>Rejected</strong>."; actionType = "wrn";
            } catch (Exception e) { actionMsg = "❌ Error rejecting: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("suspend".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='suspended' WHERE id=?");
                ps.setString(1, sellerId); ps.executeUpdate();
                actionMsg = "⏸️ Seller <strong>#" + sellerId + "</strong> has been <strong>Suspended</strong>."; actionType = "wrn";
            } catch (Exception e) { actionMsg = "❌ Error suspending: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("reactivate".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='approved' WHERE id=?");
                ps.setString(1, sellerId); ps.executeUpdate();
                actionMsg = "✅ Seller <strong>#" + sellerId + "</strong> reactivated to <strong>Approved</strong>."; actionType = "ok";
            } catch (Exception e) { actionMsg = "❌ Error: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("delete".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("DELETE FROM sellers WHERE id=?");
                ps.setString(1, sellerId); ps.executeUpdate();
                actionMsg = "🗑️ Seller <strong>#" + sellerId + "</strong> permanently deleted."; actionType = "err";
            } catch (Exception e) { actionMsg = "❌ Error deleting: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("bulkApprove".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='approved' WHERE status='pending'");
                int rows = ps.executeUpdate();
                actionMsg = "✅ <strong>" + rows + "</strong> pending seller(s) approved."; actionType = "ok";
            } catch (Exception e) { actionMsg = "❌ Bulk approve failed: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }

        } else if ("bulkReject".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("UPDATE sellers SET status='rejected' WHERE status='pending'");
                int rows = ps.executeUpdate();
                actionMsg = "🚫 <strong>" + rows + "</strong> pending seller(s) rejected."; actionType = "wrn";
            } catch (Exception e) { actionMsg = "❌ Bulk reject failed: " + e.getMessage(); actionType = "err"; }
            finally { closeAll(ps, c); }
        }
    }

    /* ── Tab & search params ── */
    String tab = request.getParameter("tab");
    if (tab == null || tab.isEmpty()) tab = "pending";

    String search = request.getParameter("search");
    if (search == null) search = "";

    /* ══════════════════════════════════════════════════════
       STATS  —  count by status value in DB
    ══════════════════════════════════════════════════════ */
    int cntPending = 0, cntApproved = 0, cntRejected = 0, cntSuspended = 0, cntTotal = 0;
    Connection cStat = null; PreparedStatement psStat = null; ResultSet rsStat = null;
    try {
        cStat  = getConn();
        psStat = cStat.prepareStatement("SELECT status, COUNT(*) AS cnt FROM sellers GROUP BY status");
        rsStat = psStat.executeQuery();
        while (rsStat.next()) {
            String st  = rsStat.getString("status");
            int    cnt = rsStat.getInt("cnt");
            cntTotal += cnt;
            if (st == null) continue;
            if (st.equalsIgnoreCase("pending"))   cntPending   = cnt;
            if (st.equalsIgnoreCase("approved"))  cntApproved  = cnt;
            if (st.equalsIgnoreCase("rejected"))  cntRejected  = cnt;
            if (st.equalsIgnoreCase("suspended")) cntSuspended = cnt;
        }
    } catch (Exception e) { actionMsg = "⚠️ DB error: " + e.getMessage(); actionType = "err"; }
    finally { closeAll(rsStat, psStat, cStat); }

    /* ── Status filter value ── */
    String statusFilter = "";
    if      ("approved".equals(tab))  statusFilter = "approved";
    else if ("rejected".equals(tab))  statusFilter = "rejected";
    else if ("suspended".equals(tab)) statusFilter = "suspended";
    else if ("all".equals(tab))       statusFilter = "";
    else                              statusFilter = "pending";

    /* ── Build SELECT query (no category/zone columns exist) ── */
    StringBuilder sql = new StringBuilder("SELECT id, name, email, phone, business_name, status FROM sellers WHERE 1=1");
    List<String> params = new ArrayList<String>();

    if (!statusFilter.isEmpty()) {
        sql.append(" AND status=?");
        params.add(statusFilter);
    }
    if (!search.trim().isEmpty()) {
        sql.append(" AND (name LIKE ? OR CAST(id AS CHAR) LIKE ? OR email LIKE ? OR phone LIKE ? OR business_name LIKE ?)");
        String like = "%" + search.trim() + "%";
        params.add(like); params.add(like); params.add(like); params.add(like); params.add(like);
    }
    sql.append(" ORDER BY id DESC");

    List<Map<String,String>> sellers = new ArrayList<Map<String,String>>();

    Connection cSeller = null; PreparedStatement psSeller = null; ResultSet rsSeller = null;
    try {
        cSeller  = getConn();
        psSeller = cSeller.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) psSeller.setString(i+1, params.get(i));
        rsSeller = psSeller.executeQuery();
        while (rsSeller.next()) {
            Map<String,String> row = new LinkedHashMap<String,String>();
            row.put("id",            String.valueOf(rsSeller.getInt("id")));
            row.put("name",          rsSeller.getString("name"));
            row.put("email",         rsSeller.getString("email"));
            row.put("phone",         rsSeller.getString("phone"));
            row.put("business_name", rsSeller.getString("business_name"));
            row.put("status",        rsSeller.getString("status"));
            sellers.add(row);
        }
    } catch (Exception e) {
        if (actionMsg.isEmpty()) { actionMsg = "❌ Error loading sellers: " + e.getMessage(); actionType = "err"; }
    } finally { closeAll(rsSeller, psSeller, cSeller); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Seller Approvals — Admin Dashboard</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap');
:root {
    --navy:#0f1c2e; --navy-lt:#1a2f4a; --navy-bd:#243b55;
    --amber:#f59e0b; --amber-lt:#fcd34d;
    --white:#ffffff; --gray-50:#f8fafc; --gray-100:#f1f5f9;
    --gray-200:#e2e8f0; --gray-400:#94a3b8; --gray-500:#64748b;
    --gray-700:#334155; --gray-900:#0f172a;
    --green:#059669; --green-lt:#d1fae5;
    --red:#dc2626; --red-lt:#fee2e2;
    --orange:#ea580c; --orange-lt:#ffedd5;
    --blue:#2563eb; --blue-lt:#dbeafe;
    --purple:#7c3aed; --purple-lt:#ede9fe;
    --shadow-sm:0 1px 3px rgba(0,0,0,.08),0 1px 2px rgba(0,0,0,.06);
    --shadow:0 4px 16px rgba(0,0,0,.10);
    --shadow-lg:0 12px 40px rgba(0,0,0,.15);
    --r:10px; --r-sm:6px; --r-lg:14px; --t:.2s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'Inter',system-ui,sans-serif;background:var(--gray-100);color:var(--gray-700);font-size:14px;line-height:1.6;}
a{text-decoration:none;color:inherit;}
.layout{display:flex;min-height:100vh;}

/* Sidebar */
.sidebar{width:250px;flex-shrink:0;background:var(--navy);display:flex;flex-direction:column;position:sticky;top:0;height:100vh;overflow-y:auto;}
.sidebar-logo{padding:1.4rem 1.2rem;border-bottom:1px solid var(--navy-bd);display:flex;align-items:center;gap:.7rem;}
.logo-icon{width:36px;height:36px;border-radius:8px;background:var(--amber);display:flex;align-items:center;justify-content:center;font-size:1.1rem;flex-shrink:0;}
.logo-text{color:var(--white);font-weight:700;font-size:.95rem;}
.logo-sub{color:var(--gray-400);font-size:.72rem;}
.nav-section{padding:.6rem .8rem .2rem;font-size:.65rem;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--gray-400);}
.nav-item{display:flex;align-items:center;gap:.65rem;padding:.6rem 1rem;margin:.1rem .5rem;border-radius:var(--r-sm);color:rgba(255,255,255,.6);font-size:.855rem;transition:var(--t);cursor:pointer;}
.nav-item:hover{background:rgba(255,255,255,.07);color:var(--white);}
.nav-item.active{background:rgba(245,158,11,.15);color:var(--amber);border-left:3px solid var(--amber);}
.nav-item .ni{font-size:1rem;width:18px;text-align:center;}
.nav-badge{margin-left:auto;background:var(--amber);color:var(--navy);font-size:.65rem;font-weight:700;padding:.1rem .4rem;border-radius:20px;min-width:18px;text-align:center;}
.nav-badge.red{background:var(--red);color:#fff;}
.sidebar-bottom{margin-top:auto;padding:1rem;border-top:1px solid var(--navy-bd);}

/* Main */
.main{flex:1;display:flex;flex-direction:column;overflow-x:hidden;}
.topbar{background:var(--white);border-bottom:1px solid var(--gray-200);padding:0 1.8rem;height:60px;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;z-index:100;box-shadow:var(--shadow-sm);}
.topbar-left h1{font-size:1.05rem;font-weight:700;color:var(--gray-900);}
.topbar-left p{font-size:.78rem;color:var(--gray-400);margin-top:.05rem;}
.topbar-right{display:flex;align-items:center;gap:.8rem;}
.admin-chip{display:flex;align-items:center;gap:.5rem;background:var(--gray-100);border-radius:20px;padding:.3rem .8rem .3rem .4rem;}
.admin-avatar{width:28px;height:28px;border-radius:50%;background:var(--navy);display:flex;align-items:center;justify-content:center;color:var(--amber);font-size:.8rem;font-weight:700;}
.admin-name{font-size:.82rem;font-weight:600;color:var(--gray-700);}
.content{padding:1.6rem 1.8rem;flex:1;}

/* Stats */
.stats-row{display:grid;grid-template-columns:repeat(5,1fr);gap:1rem;margin-bottom:1.6rem;}
.stat{background:var(--white);border-radius:var(--r);padding:1.1rem 1.2rem;box-shadow:var(--shadow-sm);display:flex;flex-direction:column;gap:.3rem;border-top:3px solid transparent;transition:var(--t);cursor:pointer;text-decoration:none;}
.stat:hover{box-shadow:var(--shadow);transform:translateY(-1px);}
.stat.s-pending{border-color:var(--amber);}
.stat.s-approved{border-color:var(--green);}
.stat.s-rejected{border-color:var(--red);}
.stat.s-suspended{border-color:var(--purple);}
.stat.s-total{border-color:var(--blue);}
.stat-num{font-size:1.75rem;font-weight:700;color:var(--gray-900);line-height:1;}
.stat-lbl{font-size:.73rem;color:var(--gray-400);font-weight:500;text-transform:uppercase;letter-spacing:.5px;}
.stat-icon2{font-size:1.3rem;margin-bottom:.1rem;}

/* Alert */
.alert{display:flex;align-items:flex-start;gap:.6rem;padding:.85rem 1.1rem;border-radius:var(--r-sm);margin-bottom:1.2rem;font-size:.87rem;font-weight:500;border:1px solid transparent;animation:slideIn .3s ease;}
@keyframes slideIn{from{opacity:0;transform:translateY(-8px);}to{opacity:1;transform:translateY(0);}}
.alert.ok{background:var(--green-lt);color:#065f46;border-color:#6ee7b7;}
.alert.err{background:var(--red-lt);color:#7f1d1d;border-color:#fca5a5;}
.alert.wrn{background:var(--orange-lt);color:#7c2d12;border-color:#fdba74;}

/* Card */
.card{background:var(--white);border-radius:var(--r);box-shadow:var(--shadow-sm);overflow:hidden;}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:.8rem;padding:1rem 1.3rem;border-bottom:1px solid var(--gray-200);}
.card-title{font-size:.95rem;font-weight:700;color:var(--gray-900);display:flex;align-items:center;gap:.5rem;}

/* Tabs */
.tab-bar{display:flex;gap:.1rem;padding:0 1.3rem;border-bottom:1px solid var(--gray-200);background:var(--gray-50);overflow-x:auto;}
.tab{background:none;border:none;padding:.75rem 1.1rem;font-size:.84rem;font-weight:600;color:var(--gray-400);cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-1px;transition:var(--t);display:flex;align-items:center;gap:.4rem;font-family:'Inter',sans-serif;white-space:nowrap;}
.tab:hover{color:var(--gray-700);}
.tab.active{color:var(--navy);border-bottom-color:var(--amber);}
.tab .tb{background:var(--gray-200);color:var(--gray-500);font-size:.68rem;font-weight:700;padding:.1rem .4rem;border-radius:20px;}
.tab.active .tb{background:var(--amber);color:var(--navy);}

/* Toolbar */
.toolbar{display:flex;align-items:center;gap:.7rem;flex-wrap:wrap;padding:.9rem 1.3rem;background:var(--gray-50);border-bottom:1px solid var(--gray-200);}
.search-wrap{position:relative;flex:1;min-width:200px;}
.search-input{width:100%;padding:.5rem .85rem .5rem 2.1rem;border:1.5px solid var(--gray-200);border-radius:var(--r-sm);font-size:.85rem;background:var(--white);transition:var(--t);font-family:inherit;}
.search-input:focus{outline:none;border-color:var(--amber);box-shadow:0 0 0 3px rgba(245,158,11,.12);}
.search-icon{position:absolute;left:.7rem;top:50%;transform:translateY(-50%);font-size:.85rem;}

/* Buttons */
.btn{display:inline-flex;align-items:center;gap:.35rem;padding:.46rem 1rem;border-radius:var(--r-sm);font-size:.82rem;font-weight:600;border:none;cursor:pointer;transition:var(--t);font-family:'Inter',sans-serif;white-space:nowrap;}
.btn-navy{background:var(--navy);color:var(--white);} .btn-navy:hover{background:var(--navy-lt);}
.btn-green{background:var(--green);color:var(--white);} .btn-green:hover{background:#047857;}
.btn-red{background:var(--red);color:var(--white);} .btn-red:hover{background:#b91c1c;}
.btn-orange{background:var(--orange);color:var(--white);} .btn-orange:hover{background:#c2410c;}
.btn-ghost{background:var(--gray-100);color:var(--gray-700);border:1px solid var(--gray-200);} .btn-ghost:hover{background:var(--gray-200);}
.btn-sm{padding:.3rem .65rem;font-size:.76rem;}
.btn-xs{padding:.2rem .5rem;font-size:.72rem;}

/* Table */
.tbl-wrap{overflow-x:auto;}
table{width:100%;border-collapse:collapse;font-size:.845rem;}
thead th{background:var(--gray-50);color:var(--gray-500);font-size:.72rem;font-weight:700;text-transform:uppercase;letter-spacing:.6px;padding:.7rem 1rem;border-bottom:1px solid var(--gray-200);white-space:nowrap;text-align:left;}
tbody td{padding:.8rem 1rem;border-bottom:1px solid var(--gray-100);vertical-align:middle;}
tbody tr:last-child td{border-bottom:none;}
tbody tr:hover td{background:var(--gray-50);}
.seller-cell{display:flex;align-items:center;gap:.7rem;}
.seller-avatar{width:36px;height:36px;border-radius:8px;background:linear-gradient(135deg,var(--navy-lt),var(--navy-bd));display:flex;align-items:center;justify-content:center;color:var(--amber);font-weight:700;font-size:.9rem;flex-shrink:0;}
.seller-name{font-weight:600;color:var(--gray-900);font-size:.87rem;}
.seller-biz{font-size:.72rem;color:var(--gray-500);margin-top:.05rem;}
.seller-id{font-size:.7rem;color:var(--gray-400);font-family:'JetBrains Mono',monospace;}
.mono{font-family:'JetBrains Mono',monospace;font-size:.8rem;}

/* Badges */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.22rem .6rem;border-radius:20px;font-size:.72rem;font-weight:700;white-space:nowrap;}
.b-pending{background:#fef3c7;color:#92400e;}
.b-approved{background:var(--green-lt);color:#065f46;}
.b-rejected{background:var(--red-lt);color:#7f1d1d;}
.b-suspended{background:var(--purple-lt);color:#4c1d95;}
.badge::before{content:'';width:6px;height:6px;border-radius:50%;background:currentColor;}
.action-group{display:flex;gap:.3rem;flex-wrap:wrap;}

/* Empty */
.empty{text-align:center;padding:3.5rem 2rem;display:flex;flex-direction:column;align-items:center;gap:.6rem;}
.empty-icon{font-size:3rem;opacity:.4;}
.empty-title{font-weight:700;color:var(--gray-500);font-size:1rem;}
.empty-sub{font-size:.83rem;color:var(--gray-400);}

/* Drawer */
.drawer-overlay{position:fixed;inset:0;background:rgba(0,0,0,.4);z-index:500;opacity:0;pointer-events:none;transition:opacity .25s;}
.drawer-overlay.open{opacity:1;pointer-events:all;}
.drawer{position:fixed;top:0;right:0;bottom:0;width:420px;max-width:95vw;background:var(--white);z-index:501;box-shadow:var(--shadow-lg);transform:translateX(100%);transition:transform .28s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden;}
.drawer-overlay.open .drawer{transform:translateX(0);}
.drawer-head{background:var(--navy);padding:1.2rem 1.4rem;color:var(--white);display:flex;justify-content:space-between;align-items:flex-start;}
.drawer-body{padding:1.4rem;flex:1;overflow-y:auto;}
.drawer-close{background:none;border:none;color:rgba(255,255,255,.6);font-size:1.3rem;cursor:pointer;}
.drawer-close:hover{color:var(--white);}
.detail-block{background:var(--gray-50);border-radius:var(--r-sm);padding:1rem;margin-bottom:1rem;}
.detail-row{display:flex;gap:.5rem;padding:.45rem 0;border-bottom:1px solid var(--gray-200);font-size:.87rem;}
.detail-row:last-child{border:none;}
.detail-lbl{width:130px;flex-shrink:0;color:var(--gray-400);font-size:.8rem;}
.detail-val{font-weight:500;color:var(--gray-800);word-break:break-all;}
.drawer-foot{padding:1rem 1.4rem;border-top:1px solid var(--gray-200);display:flex;gap:.6rem;flex-wrap:wrap;}

/* Responsive */
@media(max-width:1100px){.stats-row{grid-template-columns:repeat(3,1fr);}}
@media(max-width:768px){.sidebar{display:none;}.stats-row{grid-template-columns:1fr 1fr;}.content{padding:1rem;}.topbar{padding:0 1rem;}}
</style>
</head>
<body>
<div class="layout">

<!-- ═══ SIDEBAR ═══ -->
<aside class="sidebar">
    <div class="sidebar-logo">
        <div class="logo-icon">🛍️</div>
        <div>
            <div class="logo-text">MultiVendor</div>
            <div class="logo-sub">Admin Portal</div>
        </div>
    </div>
    <div class="nav-section">Overview</div>
    <a href="adhome.jsp" class="nav-item"><span class="ni">📊</span> Dashboard</a>
    <a href="#" class="nav-item"><span class="ni">🛒</span> Orders</a>
    <div class="nav-section">Marketplace</div>
    <a href="sellerApprovals.jsp" class="nav-item active">
        <span class="ni">🏪</span> Seller Approvals
        <% if (cntPending > 0) { %><span class="nav-badge red"><%= cntPending %></span><% } %>
    </a>
    <a href="#" class="nav-item"><span class="ni">📦</span> Products</a>
    <a href="#" class="nav-item"><span class="ni">💰</span> Payouts</a>
    <div class="nav-section">Logistics</div>
    <a href="agentApprovals.jsp" class="nav-item"><span class="ni">🪪</span> Agent Approvals</a>
    
    <a href="#" class="nav-item"><span class="ni">⚙️</span> Settings</a>
    <div class="sidebar-bottom">
        <div class="nav-item" style="cursor:default;opacity:.7;">
            <span class="ni">🔒</span>
            <div>
                <div style="color:var(--white);font-size:.8rem;font-weight:600;">Admin</div>
                <div style="font-size:.7rem;color:var(--gray-400);">Superadmin</div>
            </div>
        </div>
    </div>
</aside>

<!-- ═══ MAIN ═══ -->
<div class="main">
    <div class="topbar">
        <div class="topbar-left">
            <h1>🏪 Seller Approval Management</h1>
            <p>Review and manage seller registrations &amp; activeness</p>
        </div>
        <div class="topbar-right">
            <% if (cntPending > 0) { %>
            <span style="background:var(--red-lt);color:var(--red);font-size:.78rem;font-weight:700;padding:.3rem .75rem;border-radius:20px;display:flex;align-items:center;gap:.4rem;">
                🔔 <strong><%= cntPending %></strong> pending review
            </span>
            <% } %>
            <div class="admin-chip">
                <div class="admin-avatar">A</div>
                <span class="admin-name">Admin</span>
            </div>
        </div>
    </div>

    <div class="content">

        <% if (!actionMsg.isEmpty()) { %>
        <div class="alert <%= actionType %>">
            <div><%= actionMsg %></div>
            <button onclick="this.parentElement.remove()" style="margin-left:auto;background:none;border:none;cursor:pointer;font-size:1rem;opacity:.5;">✕</button>
        </div>
        <% } %>

        <!-- STAT CARDS -->
        <div class="stats-row">
            <a href="?tab=pending" class="stat s-pending">
                <div class="stat-icon2">⏳</div>
                <div class="stat-num"><%= cntPending %></div>
                <div class="stat-lbl">Pending Review</div>
            </a>
            <a href="?tab=approved" class="stat s-approved">
                <div class="stat-icon2">✅</div>
                <div class="stat-num"><%= cntApproved %></div>
                <div class="stat-lbl">Approved Active</div>
            </a>
            <a href="?tab=rejected" class="stat s-rejected">
                <div class="stat-icon2">🚫</div>
                <div class="stat-num"><%= cntRejected %></div>
                <div class="stat-lbl">Rejected</div>
            </a>
            <a href="?tab=suspended" class="stat s-suspended">
                <div class="stat-icon2">⏸️</div>
                <div class="stat-num"><%= cntSuspended %></div>
                <div class="stat-lbl">Suspended</div>
            </a>
            <a href="?tab=all" class="stat s-total">
                <div class="stat-icon2">🏪</div>
                <div class="stat-num"><%= cntTotal %></div>
                <div class="stat-lbl">Total Sellers</div>
            </a>
        </div>

        <!-- MAIN CARD -->
        <div class="card">
            <div class="card-head">
                <span class="card-title">
                    🗂️ Seller Registry
                    <span style="font-size:.78rem;color:var(--gray-400);font-weight:400;margin-left:.3rem;">
                        — showing <%= sellers.size() %> record<%= sellers.size()!=1?"s":"" %>
                    </span>
                </span>
                <% if ("pending".equals(tab) && cntPending > 0) { %>
                <div style="display:flex;gap:.5rem;">
                    <form method="post" action="" style="display:inline;"
                          onsubmit="return confirm('Approve ALL <%= cntPending %> pending sellers?')">
                        <input type="hidden" name="action" value="bulkApprove">
                        <button type="submit" class="btn btn-green btn-sm">✅ Approve All (<%= cntPending %>)</button>
                    </form>
                    <form method="post" action="" style="display:inline;"
                          onsubmit="return confirm('Reject ALL pending sellers?')">
                        <input type="hidden" name="action" value="bulkReject">
                        <button type="submit" class="btn btn-red btn-sm">🚫 Reject All</button>
                    </form>
                </div>
                <% } %>
            </div>

            <!-- TABS -->
            <div class="tab-bar">
                <button class="tab <%= "pending".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=pending&search=<%= search %>'">
                    ⏳ Pending <span class="tb"><%= cntPending %></span>
                </button>
                <button class="tab <%= "approved".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=approved&search=<%= search %>'">
                    ✅ Approved <span class="tb"><%= cntApproved %></span>
                </button>
                <button class="tab <%= "rejected".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=rejected&search=<%= search %>'">
                    🚫 Rejected <span class="tb"><%= cntRejected %></span>
                </button>
                <button class="tab <%= "suspended".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=suspended&search=<%= search %>'">
                    ⏸️ Suspended <span class="tb"><%= cntSuspended %></span>
                </button>
                <button class="tab <%= "all".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=all&search=<%= search %>'">
                    🏪 All <span class="tb"><%= cntTotal %></span>
                </button>
            </div>

            <!-- TOOLBAR (search only — no category column in DB) -->
            <form method="get" action="">
                <input type="hidden" name="tab" value="<%= tab %>">
                <div class="toolbar">
                    <div class="search-wrap">
                        <span class="search-icon">🔍</span>
                        <input type="text" name="search" class="search-input"
                               placeholder="Search by name, business, ID, email, phone…"
                               value="<%= search %>">
                    </div>
                    <button type="submit" class="btn btn-navy">Search</button>
                    <a href="?tab=<%= tab %>" class="btn btn-ghost">Clear</a>
                </div>
            </form>

            <!-- TABLE -->
            <div class="tbl-wrap">
            <% if (sellers.isEmpty()) { %>
                <div class="empty">
                    <div class="empty-icon">📭</div>
                    <div class="empty-title">No sellers found</div>
                    <div class="empty-sub">
                        <% if (!search.isEmpty()) { %>
                            No results for "<%= search %>". <a href="?tab=<%= tab %>" style="color:var(--amber);">Clear search</a>
                        <% } else { %>
                            No sellers in this status yet.
                        <% } %>
                    </div>
                </div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th style="width:28px;"><input type="checkbox" id="checkAll" onclick="toggleAll(this)"></th>
                            <th>Seller</th>
                            <th>Business Name</th>
                            <th>Contact</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                    for (Map<String,String> row : sellers) {
                        String sid     = row.get("id");
                        String sname   = row.get("name")          != null ? row.get("name")          : "";
                        String bizName = row.get("business_name") != null ? row.get("business_name") : "—";
                        String sstat   = row.get("status")        != null ? row.get("status")        : "";
                        String phone   = row.get("phone")         != null ? row.get("phone")         : "—";
                        String email   = row.get("email")         != null ? row.get("email")         : "—";

                        // Badge CSS class mapped to DB status values
                        String badgeCls;
                        String badgeLabel;
                        if      (sstat.equalsIgnoreCase("approved"))  { badgeCls = "b-approved";  badgeLabel = "Approved"; }
                        else if (sstat.equalsIgnoreCase("pending"))   { badgeCls = "b-pending";   badgeLabel = "Pending"; }
                        else if (sstat.equalsIgnoreCase("rejected"))  { badgeCls = "b-rejected";  badgeLabel = "Rejected"; }
                        else if (sstat.equalsIgnoreCase("suspended")) { badgeCls = "b-suspended"; badgeLabel = "Suspended"; }
                        else                                          { badgeCls = "b-pending";   badgeLabel = sstat; }

                        String initLetter = sname.length() > 0 ? sname.substring(0,1).toUpperCase() : "S";
                        String snameJs  = sname.replace("'","&#39;").replace("\"","&quot;");
                        String bizJs    = bizName.replace("'","&#39;").replace("\"","&quot;");
                    %>
                    <tr>
                        <td><input type="checkbox" class="row-check" value="<%= sid %>"></td>

                        <!-- Seller name + ID -->
                        <td>
                            <div class="seller-cell">
                                <div class="seller-avatar"><%= initLetter %></div>
                                <div>
                                    <div class="seller-name"><%= sname %></div>
                                    <div class="seller-id">#<%= sid %></div>
                                </div>
                            </div>
                        </td>

                        <!-- Business name -->
                        <td>
                            <span style="font-size:.85rem;font-weight:500;">🛍️ <%= bizName %></span>
                        </td>

                        <!-- Contact -->
                        <td>
                            <div style="font-size:.82rem;">📱 <%= phone %></div>
                            <div style="font-size:.76rem;color:var(--gray-400);margin-top:.15rem;">✉️ <%= email %></div>
                        </td>

                        <!-- Status badge -->
                        <td><span class="badge <%= badgeCls %>"><%= badgeLabel %></span></td>

                        <!-- Actions -->
                        <td>
                            <div class="action-group">
                                <!-- VIEW drawer -->
                                <button class="btn btn-ghost btn-xs"
                                    onclick="openDrawer('<%= sid %>','<%= snameJs %>','<%= bizJs %>','<%= sstat %>','<%= phone %>','<%= email %>')">
                                    👁 View
                                </button>

                                <% if (sstat.equalsIgnoreCase("pending")) { %>
                                    <form method="post" style="display:inline;" onsubmit="return confirm('Approve seller #<%= sid %>?')">
                                        <input type="hidden" name="action" value="approve">
                                        <input type="hidden" name="sellerId" value="<%= sid %>">
                                        <input type="hidden" name="tab" value="<%= tab %>">
                                        <button type="submit" class="btn btn-green btn-xs">✅ Approve</button>
                                    </form>
                                    <form method="post" style="display:inline;" onsubmit="return confirm('Reject seller #<%= sid %>?')">
                                        <input type="hidden" name="action" value="reject">
                                        <input type="hidden" name="sellerId" value="<%= sid %>">
                                        <input type="hidden" name="tab" value="<%= tab %>">
                                        <button type="submit" class="btn btn-red btn-xs">🚫 Reject</button>
                                    </form>

                                <% } else if (sstat.equalsIgnoreCase("approved")) { %>
                                    <form method="post" style="display:inline;" onsubmit="return confirm('Suspend seller #<%= sid %>?')">
                                        <input type="hidden" name="action" value="suspend">
                                        <input type="hidden" name="sellerId" value="<%= sid %>">
                                        <input type="hidden" name="tab" value="<%= tab %>">
                                        <button type="submit" class="btn btn-orange btn-xs">⏸ Suspend</button>
                                    </form>

                                <% } else if (sstat.equalsIgnoreCase("rejected") || sstat.equalsIgnoreCase("suspended")) { %>
                                    <form method="post" style="display:inline;" onsubmit="return confirm('Reactivate seller #<%= sid %>?')">
                                        <input type="hidden" name="action" value="reactivate">
                                        <input type="hidden" name="sellerId" value="<%= sid %>">
                                        <input type="hidden" name="tab" value="<%= tab %>">
                                        <button type="submit" class="btn btn-green btn-xs">♻️ Reactivate</button>
                                    </form>
                                <% } %>

                                <!-- DELETE -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('PERMANENTLY DELETE seller #<%= sid %>? Cannot be undone!')">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="sellerId" value="<%= sid %>">
                                    <input type="hidden" name="tab" value="<%= tab %>">
                                    <button type="submit" class="btn btn-ghost btn-xs" style="color:var(--red);">🗑</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <% } /* end for */ %>
                    </tbody>
                </table>
            <% } %>
            </div><!-- /tbl-wrap -->

            <% if (!sellers.isEmpty()) { %>
            <div style="padding:.75rem 1.3rem;border-top:1px solid var(--gray-200);font-size:.78rem;color:var(--gray-400);">
                Showing <strong><%= sellers.size() %></strong>
                <%= statusFilter.isEmpty() ? "total" : "\"" + statusFilter + "\"" %>
                seller<%= sellers.size()!=1?"s":"" %>
                <% if (!search.isEmpty()) { %> matching "<%= search %>"<% } %>
            </div>
            <% } %>

        </div><!-- /card -->
    </div><!-- /content -->
</div><!-- /main -->
</div><!-- /layout -->

<!-- ═══ DETAIL DRAWER ═══ -->
<div class="drawer-overlay" id="drawerOverlay" onclick="closeDrawer()">
    <div class="drawer" onclick="event.stopPropagation()">
        <div class="drawer-head">
            <div>
                <div id="dName"   style="font-weight:700;font-size:1.05rem;"></div>
                <div id="dId"     style="font-size:.72rem;opacity:.5;margin-top:.1rem;font-family:'JetBrains Mono',monospace;"></div>
                <div id="dStatus" style="margin-top:.5rem;"></div>
            </div>
            <button class="drawer-close" onclick="closeDrawer()">✕</button>
        </div>
        <div class="drawer-body">
            <div class="detail-block">
                <h4 style="font-size:.78rem;text-transform:uppercase;letter-spacing:1px;color:var(--gray-400);margin-bottom:.7rem;">Seller Information</h4>
                <div class="detail-row"><span class="detail-lbl">Seller ID</span>      <span class="detail-val mono" id="dd-id"></span></div>
                <div class="detail-row"><span class="detail-lbl">Full Name</span>      <span class="detail-val" id="dd-name"></span></div>
                <div class="detail-row"><span class="detail-lbl">Business Name</span>  <span class="detail-val" id="dd-biz"></span></div>
                <div class="detail-row"><span class="detail-lbl">Phone</span>          <span class="detail-val" id="dd-phone"></span></div>
                <div class="detail-row"><span class="detail-lbl">Email</span>          <span class="detail-val" id="dd-email"></span></div>
                <div class="detail-row"><span class="detail-lbl">Current Status</span> <span class="detail-val" id="dd-status"></span></div>
            </div>
        </div>
        <div class="drawer-foot" id="drawerFoot"></div>
    </div>
</div>

<script>
function openDrawer(id, name, biz, status, phone, email) {
    document.getElementById('dName').textContent = name;
    document.getElementById('dId').textContent   = '#' + id;

    const badges = {
        'pending':   '<span class="badge b-pending">⏳ Pending</span>',
        'approved':  '<span class="badge b-approved">✅ Approved</span>',
        'rejected':  '<span class="badge b-rejected">🚫 Rejected</span>',
        'suspended': '<span class="badge b-suspended">⏸️ Suspended</span>',
    };
    const statusLower = status.toLowerCase();
    document.getElementById('dStatus').innerHTML       = badges[statusLower] || status;
    document.getElementById('dd-id').textContent       = id;
    document.getElementById('dd-name').textContent     = name;
    document.getElementById('dd-biz').textContent      = biz;
    document.getElementById('dd-phone').textContent    = phone;
    document.getElementById('dd-email').textContent    = email;
    document.getElementById('dd-status').textContent   = status;

    const foot = document.getElementById('drawerFoot');
    const tab  = new URLSearchParams(window.location.search).get('tab') || 'pending';
    foot.innerHTML = '';

    if (statusLower === 'pending') {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Approve seller #${id}?')">
                <input type="hidden" name="action" value="approve">
                <input type="hidden" name="sellerId" value="${id}">
                <input type="hidden" name="tab" value="${tab}">
                <button type="submit" class="btn btn-green">✅ Approve Seller</button>
            </form>
            <form method="post" onsubmit="return confirm('Reject seller #${id}?')">
                <input type="hidden" name="action" value="reject">
                <input type="hidden" name="sellerId" value="${id}">
                <input type="hidden" name="tab" value="${tab}">
                <button type="submit" class="btn btn-red">🚫 Reject Seller</button>
            </form>`;
    } else if (statusLower === 'approved') {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Suspend seller #${id}?')">
                <input type="hidden" name="action" value="suspend">
                <input type="hidden" name="sellerId" value="${id}">
                <input type="hidden" name="tab" value="${tab}">
                <button type="submit" class="btn btn-orange">⏸ Suspend Seller</button>
            </form>`;
    } else {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Reactivate seller #${id}?')">
                <input type="hidden" name="action" value="reactivate">
                <input type="hidden" name="sellerId" value="${id}">
                <input type="hidden" name="tab" value="${tab}">
                <button type="submit" class="btn btn-green">♻️ Reactivate Seller</button>
            </form>`;
    }
    foot.innerHTML += `
        <form method="post" onsubmit="return confirm('PERMANENTLY DELETE seller #${id}? Cannot undo!')">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="sellerId" value="${id}">
            <input type="hidden" name="tab" value="${tab}">
            <button type="submit" class="btn btn-ghost" style="color:var(--red);">🗑 Delete</button>
        </form>`;

    document.getElementById('drawerOverlay').classList.add('open');
    document.body.style.overflow = 'hidden';
}

function closeDrawer() {
    document.getElementById('drawerOverlay').classList.remove('open');
    document.body.style.overflow = '';
}

function toggleAll(master) {
    document.querySelectorAll('.row-check').forEach(cb => cb.checked = master.checked);
}

const alertEl = document.querySelector('.alert');
if (alertEl) setTimeout(() => alertEl.remove(), 5000);

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDrawer(); });

const si = document.querySelector('.search-input');
if (si) si.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') this.closest('form').submit();
});
</script>
</body>
</html>
