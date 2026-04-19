<%-- 
    Document   : sellerReturns.jsp
    Description: Seller view — only return requests for their own products.
                 Seller can Approve / Reject Pending requests.
                 Admin completes them after physical return received.
--%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
/* ── Auth ── */
HttpSession hs = request.getSession();
String sellerEmail = null;
try { sellerEmail = hs.getAttribute("email").toString(); } catch(Exception e){}
if (sellerEmail == null || sellerEmail.trim().isEmpty()) {
    out.print("<meta http-equiv='refresh' content='0;url=ulogout'/>");
    return;
}

String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor";
String dbUser = "root";
String dbPass = "";
String flashMsg="", flashType="";

/* ── Handle Approve / Reject action ── */
String action    = request.getParameter("action");
String returnIdP = request.getParameter("returnId");
if (action != null && returnIdP != null) {
    Connection ac=null; PreparedStatement ap=null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        ac = DriverManager.getConnection(dbURL,dbUser,dbPass);
        String newStatus="";
        if      ("approve".equals(action)) { newStatus="Approved"; flashMsg="Return approved. Please instruct customer to ship item back."; flashType="success"; }
        else if ("reject".equals(action))  { newStatus="Rejected"; flashMsg="Return request rejected."; flashType="error"; }
        if (!newStatus.isEmpty()) {
            /* Verify this return belongs to this seller */
            ap = ac.prepareStatement(
                "UPDATE return_requests SET return_status=? WHERE return_id=? AND seller_email=? AND return_status='Pending'");
            ap.setString(1, newStatus);
            ap.setInt(2, Integer.parseInt(returnIdP));
            ap.setString(3, sellerEmail);
            int rows = ap.executeUpdate();
            if (rows==0 && flashType.equals("success")) { flashMsg="Could not update — request may already be processed or not yours."; flashType="error"; }
        }
    } catch(Exception ex){ flashMsg="Error: "+ex.getMessage(); flashType="error"; }
    finally { try{if(ap!=null)ap.close();if(ac!=null)ac.close();}catch(Exception ig){} }
}

/* ── Fetch returns for this seller only ── */
List<Map<String,String>> returns = new ArrayList<Map<String,String>>();
int cAll=0,cPending=0,cApproved=0,cRejected=0,cCompleted=0;

Connection sc=null; PreparedStatement ss=null; ResultSet sr=null;
try {
    Class.forName("com.mysql.jdbc.Driver");
    sc = DriverManager.getConnection(dbURL,dbUser,dbPass);
    String sql =
        "SELECT rr.return_id, rr.order_id, rr.product_id, rr.customer_email, " +
        "       rr.return_reason, rr.return_description, rr.return_status, " +
        "       rr.created_at, rr.updated_at, " +
        "       ap.pname AS product_name, " +
        "       oi.quantity, oi.unit_price, oi.item_total, " +
        "       o.full_name AS customer_name, o.phone AS customer_phone, " +
        "       o.shipping_address, o.city, o.state, o.order_date " +
        "FROM return_requests rr " +
        "LEFT JOIN adprod ap      ON rr.product_id = ap.id " +
        "LEFT JOIN order_items oi ON rr.order_id   = oi.order_id AND rr.product_id = oi.product_id " +
        "LEFT JOIN orders o       ON rr.order_id   = o.order_id " +
        "WHERE rr.seller_email = ? " +
        "ORDER BY rr.created_at DESC";
    ss = sc.prepareStatement(sql);
    ss.setString(1, sellerEmail);
    sr = ss.executeQuery();
    while (sr.next()) {
        Map<String,String> row = new HashMap<String,String>();
        row.put("return_id",          String.valueOf(sr.getInt("return_id")));
        row.put("order_id",           sr.getString("order_id")           !=null?sr.getString("order_id"):"—");
        row.put("product_name",       sr.getString("product_name")       !=null?sr.getString("product_name"):"Unknown");
        row.put("customer_email",     sr.getString("customer_email")     !=null?sr.getString("customer_email"):"—");
        row.put("customer_name",      sr.getString("customer_name")      !=null?sr.getString("customer_name"):"—");
        row.put("customer_phone",     sr.getString("customer_phone")     !=null?sr.getString("customer_phone"):"—");
        row.put("shipping_address",   sr.getString("shipping_address")   !=null?sr.getString("shipping_address"):"—");
        row.put("city",               sr.getString("city")               !=null?sr.getString("city"):"");
        row.put("state",              sr.getString("state")              !=null?sr.getString("state"):"");
        row.put("return_reason",      sr.getString("return_reason")      !=null?sr.getString("return_reason"):"—");
        row.put("return_description", sr.getString("return_description") !=null?sr.getString("return_description"):"");
        row.put("return_status",      sr.getString("return_status")      !=null?sr.getString("return_status"):"Pending");
        row.put("quantity",           String.valueOf(sr.getInt("quantity")));
        row.put("item_total",         String.valueOf(sr.getDouble("item_total")));
        row.put("order_date",         sr.getString("order_date")         !=null?sr.getString("order_date"):"—");
        row.put("created_at",         sr.getString("created_at")         !=null?sr.getString("created_at"):"—");
        row.put("updated_at",         sr.getString("updated_at")         !=null?sr.getString("updated_at"):"—");
        returns.add(row);
        cAll++;
        String st = row.get("return_status");
        if      ("Pending".equalsIgnoreCase(st))   cPending++;
        else if ("Approved".equalsIgnoreCase(st))  cApproved++;
        else if ("Rejected".equalsIgnoreCase(st))  cRejected++;
        else if ("Completed".equalsIgnoreCase(st)) cCompleted++;
    }
} catch(Exception ex){ if(flashMsg.isEmpty()){ flashMsg="DB Error: "+ex.getMessage(); flashType="error"; } }
finally { try{if(sr!=null)sr.close();if(ss!=null)ss.close();if(sc!=null)sc.close();}catch(Exception ig){} }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Return Requests — Seller | MarketHub</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root{
            --primary:#6366f1;--secondary:#8b5cf6;--success:#10b981;
            --danger:#ef4444;--warning:#f59e0b;--return:#f97316;
            --completed:#8b5cf6;--info:#06b6d4;
            --txt:#0f172a;--txt-m:#64748b;--border:#e2e8f0;--bg:#f0f4ff;
        }
        *{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Outfit',sans-serif;background:var(--bg);min-height:100vh;}

        /* HEADER */
        .main-header{background:white;padding:18px 0;box-shadow:0 4px 20px rgba(0,0,0,.08);position:sticky;top:0;z-index:999;}
        .logo{font-size:28px;font-weight:800;color:var(--txt);text-decoration:none;display:flex;align-items:center;gap:10px;}
        .logo i{background:linear-gradient(135deg,var(--primary),var(--secondary));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;}
        .header-nav{display:flex;gap:12px;align-items:center;}
        .hnav-btn{display:flex;align-items:center;gap:6px;padding:9px 18px;border-radius:10px;text-decoration:none;font-size:14px;font-weight:700;transition:all .25s;border:2px solid var(--border);color:var(--txt);background:white;}
        .hnav-btn:hover{border-color:var(--primary);color:var(--primary);}
        .hnav-btn.active{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;border-color:transparent;}

        /* HERO */
        .page-hero{background:linear-gradient(135deg,var(--return),#ea580c);color:white;padding:36px 0;margin-bottom:32px;}
        .page-hero h1{font-size:32px;font-weight:800;margin-bottom:6px;}
        .page-hero p{font-size:15px;opacity:.85;}
        .breadcrumb-c{display:flex;align-items:center;gap:8px;margin-top:14px;font-size:13px;font-weight:600;}
        .breadcrumb-c a{color:rgba(255,255,255,.75);text-decoration:none;}
        .breadcrumb-c a:hover{color:white;}

        /* KPI */
        .kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:14px;margin-bottom:26px;}
        .kpi-card{background:white;border-radius:16px;padding:18px 16px;border:2px solid var(--border);box-shadow:0 2px 12px rgba(0,0,0,.05);display:flex;align-items:center;gap:12px;transition:all .25s;}
        .kpi-card:hover{transform:translateY(-3px);box-shadow:0 8px 24px rgba(0,0,0,.1);}
        .kpi-icon{width:46px;height:46px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
        .kpi-icon.all      {background:rgba(99,102,241,.1);  color:var(--primary);}
        .kpi-icon.pending  {background:rgba(245,158,11,.1);  color:var(--warning);}
        .kpi-icon.approved {background:rgba(16,185,129,.1);  color:var(--success);}
        .kpi-icon.rejected {background:rgba(239,68,68,.1);   color:var(--danger);}
        .kpi-icon.completed{background:rgba(139,92,246,.1);  color:var(--completed);}
        .kpi-val{font-size:24px;font-weight:800;color:var(--txt);}
        .kpi-lbl{font-size:11px;font-weight:600;color:var(--txt-m);text-transform:uppercase;letter-spacing:.4px;}

        /* Flash */
        .flash{display:flex;align-items:center;gap:12px;padding:14px 18px;border-radius:12px;margin-bottom:22px;font-weight:600;font-size:14px;}
        .flash.success{background:rgba(16,185,129,.1);color:#059669;border-left:4px solid var(--success);}
        .flash.error  {background:rgba(239,68,68,.1); color:#dc2626;border-left:4px solid var(--danger);}

        /* Controls */
        .controls{display:flex;gap:12px;margin-bottom:18px;flex-wrap:wrap;}
        .search-box{display:flex;align-items:center;gap:8px;background:white;border:2px solid var(--border);border-radius:12px;padding:10px 14px;flex:1;min-width:200px;transition:border-color .25s;}
        .search-box:focus-within{border-color:var(--primary);}
        .search-box i{color:var(--txt-m);font-size:14px;}
        .search-box input{border:none;outline:none;font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;color:var(--txt);background:transparent;width:100%;}
        .filter-sel{padding:10px 14px;border:2px solid var(--border);border-radius:12px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--txt);background:white;cursor:pointer;outline:none;transition:border-color .25s;}
        .filter-sel:focus{border-color:var(--primary);}

        /* Table */
        .table-card{background:white;border-radius:18px;box-shadow:0 4px 20px rgba(0,0,0,.07);overflow:hidden;border:2px solid var(--border);}
        .table-card-hdr{display:flex;justify-content:space-between;align-items:center;padding:18px 22px;border-bottom:1px solid var(--border);}
        .table-card-hdr h3{font-size:16px;font-weight:700;color:var(--txt);}
        .count-badge{background:linear-gradient(135deg,rgba(99,102,241,.1),rgba(139,92,246,.1));color:var(--primary);padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700;}

        table.rt{width:100%;border-collapse:collapse;}
        table.rt thead{background:linear-gradient(135deg,#f8fafc,#f1f5f9);}
        table.rt th{padding:12px 16px;text-align:left;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.7px;color:var(--txt-m);white-space:nowrap;}
        table.rt td{padding:14px 16px;border-bottom:1px solid var(--border);font-size:13px;color:var(--txt);vertical-align:middle;}
        table.rt tbody tr{transition:background .2s;}
        table.rt tbody tr:hover{background:#f8fafc;}
        table.rt tbody tr:last-child td{border-bottom:none;}

        .sbadge{display:inline-flex;align-items:center;gap:5px;padding:5px 12px;border-radius:20px;font-size:11px;font-weight:700;text-transform:uppercase;white-space:nowrap;}
        .sbadge::before{content:'';width:6px;height:6px;border-radius:50%;flex-shrink:0;}
        .sbadge.Pending  {background:rgba(245,158,11,.12);color:#d97706;}  .sbadge.Pending::before  {background:var(--warning);}
        .sbadge.Approved {background:rgba(16,185,129,.12);color:#059669;}  .sbadge.Approved::before {background:var(--success);}
        .sbadge.Rejected {background:rgba(239,68,68,.12); color:#dc2626;}  .sbadge.Rejected::before {background:var(--danger);}
        .sbadge.Completed{background:rgba(139,92,246,.12);color:#7c3aed;}  .sbadge.Completed::before{background:var(--completed);}

        .reason-chip{background:rgba(249,115,22,.08);color:#ea580c;border:1px solid rgba(249,115,22,.2);border-radius:7px;padding:3px 9px;font-size:11px;font-weight:700;display:inline-block;max-width:140px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

        .actions-wrap{display:flex;gap:6px;flex-wrap:nowrap;}
        .abtn{display:inline-flex;align-items:center;gap:5px;padding:6px 12px;border:none;border-radius:8px;font-size:11px;font-weight:700;cursor:pointer;font-family:'Outfit',sans-serif;transition:all .22s;text-decoration:none;white-space:nowrap;}
        .abtn.approve {background:rgba(16,185,129,.1);color:#059669;}
        .abtn.approve:hover{background:var(--success);color:white;transform:translateY(-1px);box-shadow:0 4px 12px rgba(16,185,129,.3);}
        .abtn.reject  {background:rgba(239,68,68,.1); color:#dc2626;}
        .abtn.reject:hover {background:var(--danger); color:white;transform:translateY(-1px);box-shadow:0 4px 12px rgba(239,68,68,.3);}
        .abtn.detail  {background:rgba(99,102,241,.1);color:var(--primary);}
        .abtn.detail:hover {background:var(--primary);color:white;transform:translateY(-1px);box-shadow:0 4px 12px rgba(99,102,241,.3);}

        /* Modal */
        .modal-overlay{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:9999;display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px);padding:20px;}
        .modal-overlay.open{display:flex;animation:fadeIn .25s ease;}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        .modal-box{background:white;border-radius:20px;width:100%;box-shadow:0 24px 60px rgba(0,0,0,.2);animation:popIn .3s ease;overflow:hidden;}
        @keyframes popIn{from{transform:scale(.92);opacity:0}to{transform:scale(1);opacity:1}}

        /* Confirm modal */
        #confirmModal .modal-box{max-width:400px;padding:30px;}
        .m-icon{width:56px;height:56px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;margin:0 auto 16px;}
        .m-icon.success{background:rgba(16,185,129,.12);color:var(--success);}
        .m-icon.danger {background:rgba(239,68,68,.12); color:var(--danger);}
        #confirmModal h4{text-align:center;font-size:17px;font-weight:800;margin-bottom:8px;}
        #confirmModal p {text-align:center;font-size:13px;color:var(--txt-m);line-height:1.6;margin-bottom:22px;}
        .m-actions{display:flex;gap:10px;justify-content:center;}
        .m-btn{padding:10px 24px;border:none;border-radius:10px;font-size:13px;font-weight:700;cursor:pointer;font-family:'Outfit',sans-serif;transition:all .2s;}
        .m-btn.cancel        {background:var(--border);color:var(--txt-m);}
        .m-btn.conf-approve  {background:var(--success);color:white;}
        .m-btn.conf-reject   {background:var(--danger); color:white;}

        /* Detail modal */
        #detailModal .modal-box{max-width:660px;}
        .dm-hdr{background:linear-gradient(135deg,var(--return),#ea580c);padding:20px 26px;display:flex;justify-content:space-between;align-items:center;}
        .dm-hdr h5{font-size:16px;font-weight:800;color:white;margin:0;display:flex;align-items:center;gap:8px;}
        .dm-close{background:rgba(255,255,255,.2);border:none;color:white;width:32px;height:32px;border-radius:50%;cursor:pointer;font-size:14px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
        .dm-close:hover{background:rgba(255,255,255,.35);transform:rotate(90deg);}
        .dm-body{padding:24px;}
        .dm-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
        .dm-sec{background:var(--bg);border-radius:12px;padding:14px 16px;border:1px solid var(--border);}
        .dm-sec-title{font-size:10px;font-weight:700;color:var(--txt-m);text-transform:uppercase;letter-spacing:.8px;margin-bottom:10px;display:flex;align-items:center;gap:6px;}
        .dm-sec-title i{color:var(--return);}
        .dm-row{display:flex;justify-content:space-between;gap:8px;font-size:13px;margin-bottom:7px;}
        .dm-row:last-child{margin-bottom:0;}
        .dm-lbl{color:var(--txt-m);font-weight:600;white-space:nowrap;}
        .dm-val{font-weight:700;color:var(--txt);text-align:right;word-break:break-word;}
        .dm-desc{background:white;border:1.5px solid var(--border);border-radius:10px;padding:10px 14px;font-size:13px;color:var(--txt);line-height:1.6;font-style:italic;margin-top:12px;border-left:3px solid var(--return);}
        .dm-foot{padding:14px 24px;border-top:1px solid var(--border);display:flex;gap:10px;justify-content:flex-end;}

        .empty-s{text-align:center;padding:60px 20px;}
        .empty-s i{font-size:52px;opacity:.15;display:block;margin-bottom:14px;}
        .empty-s h4{font-size:17px;font-weight:700;color:var(--txt-m);}

        /* Pending banner */
        .pending-alert{background:rgba(245,158,11,.1);border:1.5px solid rgba(245,158,11,.3);border-radius:12px;padding:14px 18px;display:flex;align-items:center;gap:12px;margin-bottom:22px;font-size:14px;font-weight:600;color:#d97706;}
        .pending-alert i{font-size:20px;}

        @media(max-width:768px){
            .dm-grid{grid-template-columns:1fr;}
            .header-nav{gap:8px;}
            .hnav-btn span{display:none;}
        }
    </style>
</head>
<body>

<!-- CONFIRM MODAL -->
<div class="modal-overlay" id="confirmModal">
    <div class="modal-box" style="max-width:400px;padding:30px;">
        <div class="m-icon" id="mIcon"><i id="mIconI" class="fas fa-question"></i></div>
        <h4 id="mTitle">Confirm</h4>
        <p  id="mDesc">Are you sure?</p>
        <div class="m-actions">
            <button class="m-btn cancel" onclick="closeConfirm()">Cancel</button>
            <button class="m-btn" id="mConfirmBtn" onclick="submitConfirm()">Confirm</button>
        </div>
    </div>
</div>

<!-- DETAIL MODAL -->
<div class="modal-overlay" id="detailModal">
    <div class="modal-box" style="max-width:660px;">
        <div class="dm-hdr">
            <h5><i class="fas fa-undo-alt"></i> Return Request Details</h5>
            <button class="dm-close" onclick="closeDetail()"><i class="fas fa-times"></i></button>
        </div>
        <div class="dm-body" id="dmBody"></div>
        <div class="dm-foot" id="dmFoot"></div>
    </div>
</div>

<!-- HEADER -->
<header class="main-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-lg-4">
                <a href="sellerdashboard.jsp" class="logo">
                    <i class="fas fa-shopping-bag"></i><span>MarketHub</span>
                </a>
            </div>
            <div class="col-lg-8">
                <div class="header-nav justify-content-end d-flex flex-wrap">
                    <a href="sellerdashboard.jsp" class="hnav-btn"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
                    <a href="viewproduct.jsp"     class="hnav-btn"><i class="fas fa-box"></i><span>Products</span></a>
                    <a href="sellerReturns.jsp"   class="hnav-btn active"><i class="fas fa-undo-alt"></i><span>Returns</span></a>
                    <a href="ulogout"             class="hnav-btn"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- HERO -->
<div class="page-hero">
    <div class="container">
        <h1><i class="fas fa-undo-alt"></i> Return Requests</h1>
        <p>Review and manage return requests from your customers.</p>
        <div class="breadcrumb-c">
            <a href="sellerdashboard.jsp"><i class="fas fa-home"></i> Dashboard</a>
            <i class="fas fa-chevron-right" style="font-size:10px;opacity:.6;"></i>
            <span>Returns</span>
        </div>
    </div>
</div>

<!-- BODY -->
<div class="container pb-5">

    <% if (!flashMsg.isEmpty()) { %>
    <div class="flash <%= flashType %>">
        <i class="fas fa-<%= "success".equals(flashType)?"check-circle":"exclamation-circle" %>"></i>
        <span><%= flashMsg %></span>
    </div>
    <% } %>

    <% if (cPending > 0) { %>
    <div class="pending-alert">
        <i class="fas fa-bell"></i>
        You have <strong><%= cPending %> pending</strong> return request<%= cPending>1?"s":"" %> awaiting your review.
    </div>
    <% } %>

    <!-- KPI -->
    <div class="kpi-grid">
        <div class="kpi-card"><div class="kpi-icon all"><i class="fas fa-layer-group"></i></div><div><div class="kpi-val"><%= cAll %></div><div class="kpi-lbl">Total</div></div></div>
        <div class="kpi-card"><div class="kpi-icon pending"><i class="fas fa-hourglass-half"></i></div><div><div class="kpi-val"><%= cPending %></div><div class="kpi-lbl">Pending</div></div></div>
        <div class="kpi-card"><div class="kpi-icon approved"><i class="fas fa-check-circle"></i></div><div><div class="kpi-val"><%= cApproved %></div><div class="kpi-lbl">Approved</div></div></div>
        <div class="kpi-card"><div class="kpi-icon rejected"><i class="fas fa-times-circle"></i></div><div><div class="kpi-val"><%= cRejected %></div><div class="kpi-lbl">Rejected</div></div></div>
        <div class="kpi-card"><div class="kpi-icon completed"><i class="fas fa-check-double"></i></div><div><div class="kpi-val"><%= cCompleted %></div><div class="kpi-lbl">Completed</div></div></div>
    </div>

    <!-- Controls -->
    <div class="controls">
        <div class="search-box">
            <i class="fas fa-search"></i>
            <input type="text" id="searchInput" placeholder="Search by order, product, customer...">
        </div>
        <select class="filter-sel" id="statusFilter" onchange="filterTable()">
            <option value="all">All Statuses</option>
            <option value="Pending">Pending</option>
            <option value="Approved">Approved</option>
            <option value="Rejected">Rejected</option>
            <option value="Completed">Completed</option>
        </select>
    </div>

    <!-- Table -->
    <div class="table-card">
        <div class="table-card-hdr">
            <h3><i class="fas fa-undo-alt" style="color:var(--return);margin-right:8px;"></i>My Return Requests</h3>
            <span class="count-badge" id="visibleCount"><%= cAll %> requests</span>
        </div>
        <div style="overflow-x:auto;">
            <table class="rt">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Product / Order</th>
                        <th>Customer</th>
                        <th>Reason</th>
                        <th>Value</th>
                        <th>Requested</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="returnsBody">
                <% if (returns.isEmpty()) { %>
                    <tr><td colspan="8">
                        <div class="empty-s">
                            <i class="fas fa-inbox"></i>
                            <h4>No return requests for your products</h4>
                        </div>
                    </td></tr>
                <% } else {
                    for (Map<String,String> r : returns) {
                        String rid    = r.get("return_id");
                        String status = r.get("return_status");
                        String reason = r.get("return_reason");
                        String createdRaw     = r.get("created_at");
                        String createdDisplay = createdRaw.length()>=10?createdRaw.substring(0,10):createdRaw;
                        double itemTotal=0; try{itemTotal=Double.parseDouble(r.get("item_total"));}catch(Exception ig){}

                        String jsOid   = r.get("order_id")          .replace("'","\\x27");
                        String jsPname = r.get("product_name")      .replace("'","\\x27");
                        String jsCname = r.get("customer_name")     .replace("'","\\x27");
                        String jsCemail= r.get("customer_email")    .replace("'","\\x27");
                        String jsCphone= r.get("customer_phone")    .replace("'","\\x27");
                        String jsReason= reason                      .replace("'","\\x27");
                        String jsDesc  = r.get("return_description").replace("'","\\x27").replace("\n","\\n");
                        String jsAddr  = r.get("shipping_address")  .replace("'","\\x27");
                        String jsCity  = r.get("city");
                        String jsState = r.get("state");
                        String jsQty   = r.get("quantity");
                        String jsPrice = String.format("%.2f", itemTotal);
                        String jsOdate = r.get("order_date");
                        String jsUpd   = r.get("updated_at").length()>=10?r.get("updated_at").substring(0,10):r.get("updated_at");
                %>
                    <tr data-status="<%= status %>"
                        data-search="<%= (r.get("order_id")+r.get("product_name")+r.get("customer_email")+r.get("customer_name")+reason).toLowerCase() %>">

                        <td style="font-size:12px;color:var(--txt-m);">#<%= rid %></td>

                        <td>
                            <div style="font-weight:700;font-size:13px;"><%= r.get("product_name") %></div>
                            <div style="font-size:11px;color:var(--txt-m);"><i class="fas fa-hashtag" style="font-size:9px;"></i> <%= r.get("order_id") %></div>
                        </td>

                        <td>
                            <div style="font-weight:700;font-size:13px;"><%= r.get("customer_name") %></div>
                            <div style="font-size:11px;color:var(--txt-m);"><%= r.get("customer_email") %></div>
                        </td>

                        <td><span class="reason-chip" title="<%= reason %>"><%= reason %></span></td>

                        <td style="font-weight:800;">&#8377;<%= String.format("%.2f", itemTotal) %></td>

                        <td style="font-size:11px;color:var(--txt-m);"><%= createdDisplay %></td>

                        <td><span class="sbadge <%= status %>"><%= status %></span></td>

                        <td>
                            <div class="actions-wrap">
                                <button class="abtn detail" onclick="openDetail(
                                    '<%= rid %>','<%= jsOid %>','<%= jsPname %>',
                                    '<%= jsCname %>','<%= jsCemail %>','<%= jsCphone %>',
                                    '<%= jsReason %>','<%= jsDesc %>',
                                    '<%= jsAddr %>','<%= jsCity %>','<%= jsState %>',
                                    '<%= jsOdate %>','<%= jsQty %>','<%= jsPrice %>',
                                    '<%= status %>','<%= createdDisplay %>','<%= jsUpd %>'
                                )"><i class="fas fa-eye"></i> View</button>

                                <% if ("Pending".equalsIgnoreCase(status)) { %>
                                    <button class="abtn approve"
                                        onclick="openConfirm('approve','<%= rid %>','<%= jsPname %>')">
                                        <i class="fas fa-check"></i> Approve
                                    </button>
                                    <button class="abtn reject"
                                        onclick="openConfirm('reject','<%= rid %>','<%= jsPname %>')">
                                        <i class="fas fa-times"></i> Reject
                                    </button>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

</div><!-- /container -->

<!-- FOOTER -->
<div style="background:#0f172a;color:white;padding:30px 0;margin-top:40px;text-align:center;">
    <p style="color:rgba(255,255,255,.5);font-size:14px;">&copy; 2025 MarketHub. All rights reserved.</p>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Confirm modal ── */
var pendingAction='', pendingReturnId='';
function openConfirm(action, returnId, productName) {
    pendingAction=action; pendingReturnId=returnId;
    var isApprove = action==='approve';
    document.getElementById('mIcon').className = 'm-icon ' + (isApprove?'success':'danger');
    document.getElementById('mIconI').className= 'fas fa-'+(isApprove?'check-circle':'times-circle');
    document.getElementById('mTitle').textContent = isApprove?'Approve Return':'Reject Return';
    document.getElementById('mDesc').innerHTML  = '<strong>'+productName+'</strong>: '+(isApprove?'Customer will be notified to ship the item back.':'The return request will be rejected.');
    var btn=document.getElementById('mConfirmBtn');
    btn.className   = 'm-btn conf-'+(isApprove?'approve':'reject');
    btn.textContent = isApprove?'Approve':'Reject';
    document.getElementById('confirmModal').classList.add('open');
}
function closeConfirm(){document.getElementById('confirmModal').classList.remove('open');}
function submitConfirm(){
    if(pendingAction&&pendingReturnId)
        window.location.href='sellerReturns.jsp?action='+pendingAction+'&returnId='+pendingReturnId;
}
document.getElementById('confirmModal').addEventListener('click',function(e){if(e.target===this)closeConfirm();});

/* ── Detail modal ── */
function openDetail(rid,oid,pname,cname,cemail,cphone,reason,desc,addr,city,state,odate,qty,price,status,created,updated){
    var colMap={Pending:'#d97706',Approved:'#059669',Rejected:'#dc2626',Completed:'#7c3aed'};
    var col=colMap[status]||'#64748b';
    var descBlock=desc.trim()
        ?'<div class="dm-desc">&ldquo;'+escHtml(desc)+'&rdquo;</div>'
        :'<div style="font-size:13px;color:#94a3b8;font-style:italic;">No additional details.</div>';

    document.getElementById('dmBody').innerHTML=
        '<div class="dm-grid">'+
        '<div class="dm-sec">'+
            '<div class="dm-sec-title"><i class="fas fa-box"></i> Product & Order</div>'+
            dr('Product',escHtml(pname))+dr('Order ID','<code style="font-size:11px;">'+escHtml(oid)+'</code>')+
            dr('Qty',qty)+dr('Value','&#8377;'+price)+dr('Order Date',odate)+
        '</div>'+
        '<div class="dm-sec">'+
            '<div class="dm-sec-title"><i class="fas fa-user"></i> Customer</div>'+
            dr('Name',escHtml(cname))+dr('Email',escHtml(cemail))+dr('Phone',escHtml(cphone))+
            dr('Address',escHtml(addr+(city?', '+city:'')+(state?', '+state:'')))+
        '</div>'+
        '</div>'+
        '<div class="dm-sec" style="margin-top:16px;">'+
            '<div class="dm-sec-title"><i class="fas fa-undo-alt"></i> Return Info</div>'+
            '<div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">'+
            dr('Return #','#'+rid)+dr('Reason','<span style="background:rgba(249,115,22,.1);color:#ea580c;border-radius:6px;padding:2px 8px;font-size:11px;font-weight:700;">'+escHtml(reason)+'</span>')+
            dr('Status','<span style="color:'+col+';font-weight:800;">'+status+'</span>')+
            dr('Requested',created)+dr('Last Update',updated)+'</div>'+
        '</div>'+
        '<div style="margin-top:16px;"><div style="font-size:10px;font-weight:700;color:var(--txt-m);text-transform:uppercase;letter-spacing:.8px;margin-bottom:6px;">Customer Description</div>'+descBlock+'</div>';

    var foot='<button class="m-btn cancel" onclick="closeDetail()">Close</button>';
    if(status==='Pending'){
        foot+='<button class="abtn approve" style="padding:9px 18px;font-size:12px;" onclick="closeDetail();openConfirm(\'approve\',\''+rid+'\',\''+escHtml(pname)+'\')"><i class="fas fa-check"></i> Approve</button>'+
              '<button class="abtn reject"  style="padding:9px 18px;font-size:12px;" onclick="closeDetail();openConfirm(\'reject\', \''+rid+'\',\''+escHtml(pname)+'\')"><i class="fas fa-times"></i> Reject</button>';
    }
    document.getElementById('dmFoot').innerHTML=foot;
    document.getElementById('detailModal').classList.add('open');
}
function closeDetail(){document.getElementById('detailModal').classList.remove('open');}
document.getElementById('detailModal').addEventListener('click',function(e){if(e.target===this)closeDetail();});
function dr(label,val){return '<div class="dm-row"><span class="dm-lbl">'+label+'</span><span class="dm-val">'+val+'</span></div>';}
function escHtml(s){return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}

/* ── Filter / Search ── */
document.getElementById('searchInput').addEventListener('input', filterTable);
function filterTable(){
    var q=document.getElementById('searchInput').value.toLowerCase();
    var st=document.getElementById('statusFilter').value;
    var vis=0;
    document.querySelectorAll('#returnsBody tr[data-status]').forEach(function(row){
        var mQ=!q||row.getAttribute('data-search').includes(q);
        var mS=st==='all'||row.getAttribute('data-status')===st;
        var show=mQ&&mS; row.style.display=show?'':'none'; if(show)vis++;
    });
    var el=document.getElementById('visibleCount');
    if(el)el.textContent=vis+' request'+(vis!==1?'s':'');
}

/* Auto-hide flash */
var flash=document.querySelector('.flash');
if(flash)setTimeout(function(){flash.style.transition='opacity .6s';flash.style.opacity='0';setTimeout(function(){if(flash.parentNode)flash.parentNode.removeChild(flash);},600);},5000);
</script>
</body>
</html>
