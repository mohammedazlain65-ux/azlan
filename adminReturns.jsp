<%-- 
    Document   : adminReturns.jsp
    Description: Admin view of all return requests — filter by status,
                 update status (Approve / Reject / Complete) per request.
                 Sellers only see their own items; admin sees everything.
--%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
/* ══════════════════════════════════════════════════════
   Handle status-update action (POST-style via GET redirect)
   action = approve | reject | complete
   returnId = int
══════════════════════════════════════════════════════ */
String action    = request.getParameter("action");
String returnIdP = request.getParameter("returnId");
String flashMsg  = "";
String flashType = "";

String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor";
String dbUser = "root";
String dbPass = "";

if (action != null && returnIdP != null) {
    Connection ac = null; PreparedStatement ap = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        ac = DriverManager.getConnection(dbURL, dbUser, dbPass);
        String newStatus = "";
        if      ("approve".equals(action))  { newStatus = "Approved";  flashMsg = "Return request approved.";  flashType = "success"; }
        else if ("reject".equals(action))   { newStatus = "Rejected";  flashMsg = "Return request rejected.";  flashType = "error";   }
        else if ("complete".equals(action)) { newStatus = "Completed"; flashMsg = "Return marked as completed."; flashType = "success";}
        if (!newStatus.isEmpty()) {
            ap = ac.prepareStatement("UPDATE return_requests SET return_status=? WHERE return_id=?");
            ap.setString(1, newStatus);
            ap.setInt(2, Integer.parseInt(returnIdP));
            ap.executeUpdate();
        }
    } catch (Exception ex) {
        flashMsg = "Error: " + ex.getMessage(); flashType = "error";
    } finally {
        try { if(ap!=null)ap.close(); if(ac!=null)ac.close(); } catch(Exception ig){}
    }
}

/* ══════════════════════════════════════════════════════
   Fetch all return requests with related info
══════════════════════════════════════════════════════ */
List<Map<String,String>> returns = new ArrayList<Map<String,String>>();
int cAll=0, cPending=0, cApproved=0, cRejected=0, cCompleted=0;

Connection sc = null; PreparedStatement ss = null; ResultSet sr = null;
try {
    Class.forName("com.mysql.jdbc.Driver");
    sc = DriverManager.getConnection(dbURL, dbUser, dbPass);

    String sql =
        "SELECT rr.return_id, rr.order_id, rr.product_id, rr.customer_email, " +
        "       rr.seller_email, rr.return_reason, rr.return_description, " +
        "       rr.return_status, rr.created_at, rr.updated_at, " +
        "       ap.pname AS product_name, " +
        "       oi.quantity, oi.unit_price, oi.item_total, " +
        "       o.full_name AS customer_name, o.phone AS customer_phone, " +
        "       o.shipping_address, o.city, o.state, o.order_date, " +
        "       s.name AS seller_name, s.business_name " +
        "FROM return_requests rr " +
        "LEFT JOIN adprod ap      ON rr.product_id = ap.id " +
        "LEFT JOIN order_items oi ON rr.order_id   COLLATE utf8mb4_unicode_ci = oi.order_id   COLLATE utf8mb4_unicode_ci " +
        "                        AND rr.product_id = oi.product_id " +
        "LEFT JOIN orders o       ON rr.order_id   COLLATE utf8mb4_unicode_ci = o.order_id    COLLATE utf8mb4_unicode_ci " +
        "LEFT JOIN sellers s      ON rr.seller_email COLLATE utf8mb4_unicode_ci = s.email     COLLATE utf8mb4_unicode_ci " +
        "ORDER BY rr.created_at DESC";

    ss = sc.prepareStatement(sql);
    sr = ss.executeQuery();
    while (sr.next()) {
        Map<String,String> row = new HashMap<String,String>();
        row.put("return_id",          String.valueOf(sr.getInt("return_id")));
        row.put("order_id",           sr.getString("order_id")           != null ? sr.getString("order_id")           : "—");
        row.put("product_id",         String.valueOf(sr.getInt("product_id")));
        row.put("product_name",       sr.getString("product_name")       != null ? sr.getString("product_name")       : "Unknown Product");
        row.put("customer_email",     sr.getString("customer_email")     != null ? sr.getString("customer_email")     : "—");
        row.put("customer_name",      sr.getString("customer_name")      != null ? sr.getString("customer_name")      : "—");
        row.put("customer_phone",     sr.getString("customer_phone")     != null ? sr.getString("customer_phone")     : "—");
        row.put("shipping_address",   sr.getString("shipping_address")   != null ? sr.getString("shipping_address")   : "—");
        row.put("city",               sr.getString("city")               != null ? sr.getString("city")               : "");
        row.put("state",              sr.getString("state")              != null ? sr.getString("state")              : "");
        row.put("seller_email",       sr.getString("seller_email")       != null ? sr.getString("seller_email")       : "—");
        row.put("seller_name",        sr.getString("seller_name")        != null ? sr.getString("seller_name")        : "Unknown Seller");
        row.put("business_name",      sr.getString("business_name")      != null ? sr.getString("business_name")      : "—");
        row.put("return_reason",      sr.getString("return_reason")      != null ? sr.getString("return_reason")      : "—");
        row.put("return_description", sr.getString("return_description") != null ? sr.getString("return_description") : "");
        row.put("return_status",      sr.getString("return_status")      != null ? sr.getString("return_status")      : "Pending");
        row.put("quantity",           String.valueOf(sr.getInt("quantity")));
        row.put("unit_price",         String.valueOf(sr.getDouble("unit_price")));
        row.put("item_total",         String.valueOf(sr.getDouble("item_total")));
        row.put("order_date",         sr.getString("order_date")         != null ? sr.getString("order_date")         : "—");
        row.put("created_at",         sr.getString("created_at")         != null ? sr.getString("created_at")         : "—");
        row.put("updated_at",         sr.getString("updated_at")         != null ? sr.getString("updated_at")         : "—");
        returns.add(row);

        cAll++;
        String st = row.get("return_status");
        if      ("Pending".equalsIgnoreCase(st))   cPending++;
        else if ("Approved".equalsIgnoreCase(st))  cApproved++;
        else if ("Rejected".equalsIgnoreCase(st))  cRejected++;
        else if ("Completed".equalsIgnoreCase(st)) cCompleted++;
    }
} catch (Exception ex) {
    if (flashMsg.isEmpty()) { flashMsg = "DB Error: " + ex.getMessage(); flashType = "error"; }
} finally {
    try{if(sr!=null)sr.close();if(ss!=null)ss.close();if(sc!=null)sc.close();}catch(Exception ig){}
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Return Requests — Admin | MarketHub</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary:    #0f172a;
            --accent:     #38bdf8;
            --accent2:    #818cf8;
            --success:    #10b981;
            --warning:    #f59e0b;
            --danger:     #ef4444;
            --return:     #f97316;
            --info:       #06b6d4;
            --completed:  #8b5cf6;
            --sidebar-w:  270px;
            --page-bg:    #f1f5f9;
            --border:     #e2e8f0;
            --txt:        #0f172a;
            --txt-m:      #64748b;
            --txt-s:      #94a3b8;
        }
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Sora',sans-serif;background:var(--page-bg);color:var(--txt);min-height:100vh;}

        /* ── SIDEBAR ── */
        .sidebar{position:fixed;left:0;top:0;height:100vh;width:var(--sidebar-w);background:#0f172a;z-index:1000;overflow-y:auto;display:flex;flex-direction:column;box-shadow:4px 0 24px rgba(0,0,0,.18);}
        .sidebar::-webkit-scrollbar{width:4px;}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.15);border-radius:4px;}
        .sidebar-header{padding:28px 22px 22px;border-bottom:1px solid rgba(255,255,255,.08);}
        .sidebar-logo{display:flex;align-items:center;gap:14px;text-decoration:none;}
        .logo-icon{width:44px;height:44px;background:linear-gradient(135deg,var(--accent),var(--accent2));border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;color:#fff;box-shadow:0 6px 20px rgba(56,189,248,.35);}
        .logo-text h3{font-size:18px;font-weight:800;color:#fff;letter-spacing:-.3px;}
        .logo-text span{font-size:10px;color:rgba(255,255,255,.45);text-transform:uppercase;letter-spacing:1.5px;}
        .sidebar-nav{padding:18px 0;flex:1;}
        .nav-section-label{font-size:9px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.3);padding:18px 22px 8px;}
        .nav-link-item{display:flex;align-items:center;gap:14px;padding:13px 22px;color:rgba(255,255,255,.65);text-decoration:none;font-size:14px;font-weight:500;transition:all .25s;position:relative;margin:2px 10px;border-radius:10px;}
        .nav-link-item i{font-size:17px;width:20px;text-align:center;}
        .nav-link-item:hover{background:rgba(255,255,255,.08);color:#fff;}
        .nav-link-item.active{background:linear-gradient(135deg,rgba(56,189,248,.18),rgba(129,140,248,.18));color:#fff;}
        .nav-link-item.active::before{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:3px;height:60%;background:linear-gradient(180deg,var(--accent),var(--accent2));border-radius:0 3px 3px 0;}
        .nav-link-item.active i{color:var(--accent);}
        .sidebar-footer{padding:18px 22px;border-top:1px solid rgba(255,255,255,.08);}
        .admin-chip{display:flex;align-items:center;gap:12px;padding:10px 14px;background:rgba(255,255,255,.07);border-radius:12px;}
        .admin-avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:15px;flex-shrink:0;}
        .admin-chip-info strong{display:block;font-size:13px;color:#fff;font-weight:600;}
        .admin-chip-info span{font-size:11px;color:rgba(255,255,255,.4);}

        /* ── MAIN ── */
        .main-content{margin-left:var(--sidebar-w);min-height:100vh;}
        .top-bar{background:#fff;padding:18px 32px;display:flex;justify-content:space-between;align-items:center;box-shadow:0 1px 12px rgba(0,0,0,.06);position:sticky;top:0;z-index:999;border-bottom:1px solid var(--border);}
        .top-bar-left h1{font-size:22px;font-weight:800;color:var(--txt);letter-spacing:-.4px;}
        .top-bar-left p{font-size:13px;color:var(--txt-m);margin-top:2px;}

        /* Summary pills */
        .stat-pills{display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
        .stat-pill{display:flex;align-items:center;gap:8px;padding:8px 14px;border-radius:20px;font-size:13px;font-weight:700;}
        .stat-pill.all       {background:rgba(56,189,248,.1);  color:var(--accent);}
        .stat-pill.pending   {background:rgba(245,158,11,.1);  color:var(--warning);}
        .stat-pill.approved  {background:rgba(16,185,129,.1);  color:var(--success);}
        .stat-pill.rejected  {background:rgba(239,68,68,.1);   color:var(--danger);}
        .stat-pill.completed {background:rgba(139,92,246,.1);  color:var(--completed);}

        /* ── PAGE BODY ── */
        .page-body{padding:28px 32px;}

        .flash-msg{display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:14px;margin-bottom:24px;font-weight:600;font-size:14px;animation:slideDown .4s ease;}
        @keyframes slideDown{from{opacity:0;transform:translateY(-12px)}to{opacity:1;transform:translateY(0)}}
        .flash-msg.success{background:rgba(16,185,129,.1);color:#059669;border-left:4px solid var(--success);}
        .flash-msg.error  {background:rgba(239,68,68,.1); color:#dc2626;border-left:4px solid var(--danger);}

        /* Controls */
        .table-controls{display:flex;gap:12px;align-items:center;margin-bottom:20px;flex-wrap:wrap;}
        .search-box{display:flex;align-items:center;gap:10px;background:#fff;border:2px solid var(--border);border-radius:12px;padding:10px 16px;flex:1;min-width:220px;transition:border-color .25s;}
        .search-box:focus-within{border-color:var(--accent);}
        .search-box i{color:var(--txt-s);font-size:15px;}
        .search-box input{border:none;outline:none;font-family:'Sora',sans-serif;font-size:14px;font-weight:500;color:var(--txt);background:transparent;width:100%;}
        .filter-select{padding:10px 14px;border:2px solid var(--border);border-radius:12px;font-family:'Sora',sans-serif;font-size:13px;font-weight:600;color:var(--txt);background:#fff;cursor:pointer;outline:none;transition:border-color .25s;}
        .filter-select:focus{border-color:var(--accent);}

        /* KPI cards row */
        .kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;margin-bottom:28px;}
        .kpi-card{background:#fff;border-radius:16px;padding:20px 18px;border:1px solid var(--border);box-shadow:0 2px 12px rgba(0,0,0,.05);display:flex;align-items:center;gap:14px;transition:all .25s;}
        .kpi-card:hover{transform:translateY(-3px);box-shadow:0 8px 24px rgba(0,0,0,.1);}
        .kpi-icon{width:48px;height:48px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;}
        .kpi-icon.all      {background:rgba(56,189,248,.12); color:var(--accent);}
        .kpi-icon.pending  {background:rgba(245,158,11,.12); color:var(--warning);}
        .kpi-icon.approved {background:rgba(16,185,129,.12); color:var(--success);}
        .kpi-icon.rejected {background:rgba(239,68,68,.12);  color:var(--danger);}
        .kpi-icon.completed{background:rgba(139,92,246,.12); color:var(--completed);}
        .kpi-val{font-size:26px;font-weight:800;color:var(--txt);line-height:1;}
        .kpi-lbl{font-size:12px;font-weight:600;color:var(--txt-m);margin-top:2px;text-transform:uppercase;letter-spacing:.5px;}

        /* Table card */
        .table-card{background:#fff;border-radius:18px;box-shadow:0 2px 16px rgba(0,0,0,.06);overflow:hidden;border:1px solid var(--border);}
        .table-card-header{display:flex;justify-content:space-between;align-items:center;padding:20px 24px;border-bottom:1px solid var(--border);}
        .table-card-header h3{font-size:17px;font-weight:700;color:var(--txt);}
        .total-badge{background:linear-gradient(135deg,rgba(56,189,248,.12),rgba(129,140,248,.12));color:var(--accent);padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700;}

        table.rt{width:100%;border-collapse:collapse;}
        table.rt thead{background:linear-gradient(135deg,#f8fafc,#f1f5f9);}
        table.rt th{padding:14px 16px;text-align:left;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;color:var(--txt-m);white-space:nowrap;}
        table.rt td{padding:15px 16px;border-bottom:1px solid var(--border);font-size:13px;color:var(--txt);vertical-align:middle;}
        table.rt tbody tr{transition:background .2s;}
        table.rt tbody tr:hover{background:#f8fafc;}
        table.rt tbody tr:last-child td{border-bottom:none;}

        /* Status badges */
        .sbadge{display:inline-flex;align-items:center;gap:6px;padding:5px 12px;border-radius:20px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;white-space:nowrap;}
        .sbadge::before{content:'';width:6px;height:6px;border-radius:50%;flex-shrink:0;}
        .sbadge.Pending  {background:rgba(245,158,11,.12);color:#d97706;}   .sbadge.Pending::before  {background:var(--warning);}
        .sbadge.Approved {background:rgba(16,185,129,.12);color:#059669;}   .sbadge.Approved::before {background:var(--success);}
        .sbadge.Rejected {background:rgba(239,68,68,.12); color:#dc2626;}   .sbadge.Rejected::before {background:var(--danger);}
        .sbadge.Completed{background:rgba(139,92,246,.12);color:#7c3aed;}   .sbadge.Completed::before{background:var(--completed);}

        /* Reason chip */
        .reason-chip{background:rgba(249,115,22,.08);color:#ea580c;border:1px solid rgba(249,115,22,.2);border-radius:8px;padding:4px 10px;font-size:11px;font-weight:700;display:inline-block;max-width:160px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

        /* People cells */
        .person-cell{display:flex;flex-direction:column;gap:1px;}
        .person-name{font-weight:700;font-size:13px;color:var(--txt);}
        .person-sub{font-size:11px;color:var(--txt-m);}

        /* Action buttons */
        .actions-wrap{display:flex;gap:6px;flex-wrap:nowrap;align-items:center;}
        .abtn{display:inline-flex;align-items:center;gap:5px;padding:6px 12px;border:none;border-radius:8px;font-size:11px;font-weight:700;cursor:pointer;font-family:'Sora',sans-serif;transition:all .22s;text-decoration:none;white-space:nowrap;}
        .abtn i{font-size:11px;}
        .abtn.approve  {background:rgba(16,185,129,.1); color:#059669;}
        .abtn.approve:hover  {background:var(--success);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(16,185,129,.3);}
        .abtn.reject   {background:rgba(239,68,68,.1);  color:#dc2626;}
        .abtn.reject:hover   {background:var(--danger); color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(239,68,68,.3);}
        .abtn.complete {background:rgba(139,92,246,.1); color:#7c3aed;}
        .abtn.complete:hover {background:var(--completed);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(139,92,246,.3);}
        .abtn.detail   {background:rgba(56,189,248,.1); color:#0284c7;}
        .abtn.detail:hover   {background:var(--accent); color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(56,189,248,.3);}
        .status-done{font-size:12px;font-weight:700;color:var(--txt-m);display:flex;align-items:center;gap:5px;}

        /* Modal */
        .modal-overlay{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:9999;display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px);}
        .modal-overlay.open{display:flex;animation:fadeIn .25s ease;}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        .modal-box{background:#fff;border-radius:20px;width:90%;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:popIn .3s ease;overflow:hidden;}
        @keyframes popIn{from{transform:scale(.92);opacity:0}to{transform:scale(1);opacity:1}}

        /* Confirm modal */
        #confirmModal .modal-box{max-width:420px;padding:32px 36px;}
        .modal-icon{width:60px;height:60px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;margin:0 auto 18px;}
        .modal-icon.warn   {background:rgba(245,158,11,.12);color:var(--warning);}
        .modal-icon.danger {background:rgba(239,68,68,.12); color:var(--danger);}
        .modal-icon.success{background:rgba(16,185,129,.12);color:var(--success);}
        .modal-icon.purple {background:rgba(139,92,246,.12);color:var(--completed);}
        #confirmModal .modal-box h4{text-align:center;font-size:18px;font-weight:800;margin-bottom:10px;}
        #confirmModal .modal-box p {text-align:center;font-size:14px;color:var(--txt-m);line-height:1.6;margin-bottom:24px;}
        .modal-actions{display:flex;gap:12px;justify-content:center;}
        .modal-btn{padding:11px 28px;border:none;border-radius:10px;font-size:14px;font-weight:700;cursor:pointer;font-family:'Sora',sans-serif;transition:all .2s;}
        .modal-btn.cancel          {background:var(--border);color:var(--txt-m);}
        .modal-btn.cancel:hover    {background:#cbd5e1;}
        .modal-btn.conf-approve    {background:var(--success);  color:#fff;box-shadow:0 4px 14px rgba(16,185,129,.3);}
        .modal-btn.conf-reject     {background:var(--danger);   color:#fff;box-shadow:0 4px 14px rgba(239,68,68,.3);}
        .modal-btn.conf-complete   {background:var(--completed);color:#fff;box-shadow:0 4px 14px rgba(139,92,246,.3);}

        /* Detail modal */
        #detailModal .modal-box{max-width:700px;}
        .dm-header{background:linear-gradient(135deg,var(--return),#ea580c);padding:22px 28px;display:flex;justify-content:space-between;align-items:center;}
        .dm-header h5{font-size:18px;font-weight:800;color:#fff;margin:0;display:flex;align-items:center;gap:10px;}
        .dm-close{background:rgba(255,255,255,.2);border:none;color:#fff;width:34px;height:34px;border-radius:50%;cursor:pointer;font-size:16px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
        .dm-close:hover{background:rgba(255,255,255,.35);transform:rotate(90deg);}
        .dm-body{padding:28px;}
        .dm-grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;}
        .dm-section{background:var(--page-bg);border-radius:14px;padding:16px 18px;border:1px solid var(--border);}
        .dm-section-title{font-size:11px;font-weight:700;color:var(--txt-m);text-transform:uppercase;letter-spacing:.8px;margin-bottom:12px;display:flex;align-items:center;gap:7px;}
        .dm-section-title i{color:var(--return);}
        .dm-row{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;margin-bottom:8px;font-size:13px;}
        .dm-row:last-child{margin-bottom:0;}
        .dm-label{color:var(--txt-m);font-weight:600;white-space:nowrap;}
        .dm-val{font-weight:700;color:var(--txt);text-align:right;word-break:break-word;}
        .dm-desc{background:#fff;border:1.5px solid var(--border);border-radius:10px;padding:12px 14px;font-size:13px;color:var(--txt);line-height:1.6;font-style:italic;margin-top:10px;border-left:3px solid var(--return);}
        .dm-footer{padding:16px 28px;border-top:1px solid var(--border);display:flex;gap:10px;justify-content:flex-end;background:linear-gradient(135deg,rgba(249,115,22,.02),rgba(251,146,60,.02));}

        .empty-state{text-align:center;padding:60px 20px;}
        .empty-state i{font-size:56px;opacity:.15;display:block;margin-bottom:16px;}
        .empty-state h4{font-size:18px;font-weight:700;color:var(--txt-m);}

        @media(max-width:1100px){
            :root{--sidebar-w:70px;}
            .logo-text,.nav-section-label,.nav-link-item span,.admin-chip-info{display:none;}
            .nav-link-item{justify-content:center;padding:14px;}
            .admin-chip{justify-content:center;}
            .dm-grid{grid-template-columns:1fr;}
        }
        @media(max-width:768px){
            :root{--sidebar-w:0px;}
            .sidebar{display:none;}
            .page-body{padding:16px;}
            .top-bar{padding:14px 16px;}
            .stat-pills{display:none;}
            .kpi-grid{grid-template-columns:repeat(2,1fr);}
        }
    </style>
</head>
<body>

<!-- ═══════════════════════════════
     CONFIRM MODAL
═══════════════════════════════ -->
<div class="modal-overlay" id="confirmModal">
    <div class="modal-box" style="max-width:420px;padding:32px 36px;">
        <div class="modal-icon" id="modalIcon"><i id="modalIconI" class="fas fa-question"></i></div>
        <h4 id="modalTitle">Confirm</h4>
        <p  id="modalDesc">Are you sure?</p>
        <div class="modal-actions">
            <button class="modal-btn cancel" onclick="closeConfirm()">Cancel</button>
            <button class="modal-btn" id="modalConfirmBtn" onclick="submitConfirm()">Confirm</button>
        </div>
    </div>
</div>

<!-- ═══════════════════════════════
     DETAIL MODAL
═══════════════════════════════ -->
<div class="modal-overlay" id="detailModal">
    <div class="modal-box" style="max-width:700px;">
        <div class="dm-header">
            <h5><i class="fas fa-undo-alt"></i> Return Request Details</h5>
            <button class="dm-close" onclick="closeDetail()"><i class="fas fa-times"></i></button>
        </div>
        <div class="dm-body" id="dmBody"><!-- filled by JS --></div>
        <div class="dm-footer" id="dmFooter"><!-- filled by JS --></div>
    </div>
</div>

<!-- ═══════════════════════════════
     SIDEBAR
═══════════════════════════════ -->
<aside class="sidebar">
    <div class="sidebar-header">
        <a href="#" class="sidebar-logo">
            <div class="logo-icon"><i class="fas fa-shopping-bag"></i></div>
            <div class="logo-text"><h3>MarketHub</h3><span>Admin Panel</span></div>
        </a>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="adhome.jsp"       class="nav-link-item"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
        <div class="nav-section-label">Management</div>
        <a href="adminProducts.jsp"  class="nav-link-item"><i class="fas fa-box"></i><span>Products</span></a>
        <a href="adminReturns.jsp"   class="nav-link-item active"><i class="fas fa-undo-alt"></i><span>Returns</span></a>
        <a href="adminOrders.jsp"    class="nav-link-item"><i class="fas fa-receipt"></i><span>Orders</span></a>
        <div class="nav-section-label">Account</div>
        <a href="adlogin.jsp"      class="nav-link-item"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-chip">
            <div class="admin-avatar">A</div>
            <div class="admin-chip-info"><strong>Admin User</strong><span>Super Admin</span></div>
        </div>
    </div>
</aside>

<!-- ═══════════════════════════════
     MAIN
═══════════════════════════════ -->
<main class="main-content">
    <div class="top-bar">
        <div class="top-bar-left">
            <h1><i class="fas fa-undo-alt" style="color:var(--return);margin-right:10px;font-size:20px;"></i>Return Requests</h1>
            <p>Manage all customer return requests across sellers</p>
        </div>
        <div class="stat-pills">
            <div class="stat-pill all">     <i class="fas fa-layer-group"></i> <%= cAll %>  Total</div>
            <div class="stat-pill pending"> <i class="fas fa-clock"></i>       <%= cPending %> Pending</div>
            <div class="stat-pill approved"><i class="fas fa-check-circle"></i><%= cApproved %> Approved</div>
            <div class="stat-pill rejected"><i class="fas fa-times-circle"></i><%= cRejected %> Rejected</div>
            <div class="stat-pill completed"><i class="fas fa-check-double"></i><%= cCompleted %> Completed</div>
        </div>
    </div>

    <div class="page-body">

        <!-- Flash -->
        <% if (!flashMsg.isEmpty()) { %>
        <div class="flash-msg <%= flashType %>">
            <i class="fas fa-<%= "success".equals(flashType)?"check-circle":"exclamation-circle" %>"></i>
            <span><%= flashMsg %></span>
        </div>
        <% } %>

        <!-- KPI cards -->
        <div class="kpi-grid">
            <div class="kpi-card">
                <div class="kpi-icon all"><i class="fas fa-layer-group"></i></div>
                <div><div class="kpi-val"><%= cAll %></div><div class="kpi-lbl">Total Requests</div></div>
            </div>
            <div class="kpi-card">
                <div class="kpi-icon pending"><i class="fas fa-hourglass-half"></i></div>
                <div><div class="kpi-val"><%= cPending %></div><div class="kpi-lbl">Pending</div></div>
            </div>
            <div class="kpi-card">
                <div class="kpi-icon approved"><i class="fas fa-check-circle"></i></div>
                <div><div class="kpi-val"><%= cApproved %></div><div class="kpi-lbl">Approved</div></div>
            </div>
            <div class="kpi-card">
                <div class="kpi-icon rejected"><i class="fas fa-times-circle"></i></div>
                <div><div class="kpi-val"><%= cRejected %></div><div class="kpi-lbl">Rejected</div></div>
            </div>
            <div class="kpi-card">
                <div class="kpi-icon completed"><i class="fas fa-check-double"></i></div>
                <div><div class="kpi-val"><%= cCompleted %></div><div class="kpi-lbl">Completed</div></div>
            </div>
        </div>

        <!-- Controls -->
        <div class="table-controls">
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search order ID, product, customer, seller...">
            </div>
            <select class="filter-select" id="statusFilter" onchange="filterTable()">
                <option value="all">All Statuses</option>
                <option value="Pending">Pending</option>
                <option value="Approved">Approved</option>
                <option value="Rejected">Rejected</option>
                <option value="Completed">Completed</option>
            </select>
            <select class="filter-select" id="reasonFilter" onchange="filterTable()">
                <option value="all">All Reasons</option>
                <option value="Damaged">Damaged / Defective</option>
                <option value="Wrong">Wrong Item</option>
                <option value="not as described">Not as Described</option>
                <option value="Changed">Changed Mind</option>
                <option value="Size">Size / Fit</option>
                <option value="Missing">Missing Parts</option>
                <option value="Poor">Poor Quality</option>
            </select>
        </div>

        <!-- Table -->
        <div class="table-card">
            <div class="table-card-header">
                <h3><i class="fas fa-undo-alt" style="color:var(--return);margin-right:8px;"></i>All Return Requests</h3>
                <span class="total-badge" id="visibleCount"><%= cAll %> requests</span>
            </div>
            <div style="overflow-x:auto;">
                <table class="rt">
                    <thead>
                        <tr>
                            <th>#ID</th>
                            <th>Order / Product</th>
                            <th>Customer</th>
                            <th>Seller</th>
                            <th>Reason</th>
                            <th>Value</th>
                            <th>Requested</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="returnsBody">
                    <% if (returns.isEmpty()) { %>
                        <tr><td colspan="9">
                            <div class="empty-state">
                                <i class="fas fa-inbox"></i>
                                <h4>No return requests yet</h4>
                            </div>
                        </td></tr>
                    <% } else {
                        for (Map<String,String> r : returns) {
                            String rid    = r.get("return_id");
                            String status = r.get("return_status");
                            String reason = r.get("return_reason");
                            String createdRaw = r.get("created_at");
                            String createdDisplay = createdRaw.length() >= 10 ? createdRaw.substring(0,10) : createdRaw;
                            double itemTotal = 0;
                            try { itemTotal = Double.parseDouble(r.get("item_total")); } catch(Exception ig){}

                            /* Build safe JS-string data for detail modal */
                            String jsOid    = r.get("order_id")          .replace("'","\\x27");
                            String jsPname  = r.get("product_name")      .replace("'","\\x27");
                            String jsCname  = r.get("customer_name")     .replace("'","\\x27");
                            String jsCemail = r.get("customer_email")    .replace("'","\\x27");
                            String jsCphone = r.get("customer_phone")    .replace("'","\\x27");
                            String jsSname  = r.get("seller_name")       .replace("'","\\x27");
                            String jsSemail = r.get("seller_email")      .replace("'","\\x27");
                            String jsBiz    = r.get("business_name")     .replace("'","\\x27");
                            String jsReason = reason                      .replace("'","\\x27");
                            String jsDesc   = r.get("return_description").replace("'","\\x27").replace("\n","\\n");
                            String jsAddr   = r.get("shipping_address")  .replace("'","\\x27");
                            String jsCity   = r.get("city");
                            String jsState  = r.get("state");
                            String jsOdate  = r.get("order_date");
                            String jsQty    = r.get("quantity");
                            String jsPrice  = String.format("%.2f", itemTotal);
                            String jsUpd    = r.get("updated_at").length()>=10 ? r.get("updated_at").substring(0,10) : r.get("updated_at");
                    %>
                        <tr data-status="<%= status %>"
                            data-reason="<%= reason.toLowerCase() %>"
                            data-search="<%= (r.get("order_id")+r.get("product_name")+r.get("customer_email")+r.get("customer_name")+r.get("seller_email")+r.get("seller_name")+reason).toLowerCase() %>">

                            <td style="font-family:'JetBrains Mono',monospace;font-size:12px;color:var(--txt-m);">#<%= rid %></td>

                            <td>
                                <div class="person-cell">
                                    <span class="person-name"><i class="fas fa-hashtag" style="font-size:10px;color:var(--accent);"></i> <%= r.get("order_id") %></span>
                                    <span class="person-sub"><i class="fas fa-box" style="font-size:10px;color:var(--return);"></i> <%= r.get("product_name") %></span>
                                </div>
                            </td>

                            <td>
                                <div class="person-cell">
                                    <span class="person-name"><%= r.get("customer_name") %></span>
                                    <span class="person-sub"><%= r.get("customer_email") %></span>
                                </div>
                            </td>

                            <td>
                                <div class="person-cell">
                                    <span class="person-name"><%= r.get("seller_name") %></span>
                                    <span class="person-sub"><%= r.get("seller_email") %></span>
                                </div>
                            </td>

                            <td><span class="reason-chip" title="<%= reason %>"><%= reason %></span></td>

                            <td style="font-weight:800;color:var(--txt);">&#8377;<%= String.format("%.2f", itemTotal) %></td>

                            <td style="font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--txt-m);"><%= createdDisplay %></td>

                            <td><span class="sbadge <%= status %>"><%= status %></span></td>

                            <td>
                                <div class="actions-wrap">
                                    <!-- Detail btn always shown -->
                                    <button class="abtn detail" onclick="openDetail(
                                        '<%= rid %>','<%= jsOid %>','<%= jsPname %>',
                                        '<%= jsCname %>','<%= jsCemail %>','<%= jsCphone %>',
                                        '<%= jsSname %>','<%= jsSemail %>','<%= jsBiz %>',
                                        '<%= jsReason %>','<%= jsDesc %>',
                                        '<%= jsAddr %>','<%= jsCity %>','<%= jsState %>',
                                        '<%= jsOdate %>','<%= jsQty %>','<%= jsPrice %>',
                                        '<%= status %>','<%= createdDisplay %>','<%= jsUpd %>'
                                    )"><i class="fas fa-eye"></i> Detail</button>

                                    <% if ("Pending".equalsIgnoreCase(status)) { %>
                                        <button class="abtn approve"
                                            onclick="openConfirm('approve','<%= rid %>','<%= jsPname %>')">
                                            <i class="fas fa-check"></i> Approve
                                        </button>
                                        <button class="abtn reject"
                                            onclick="openConfirm('reject','<%= rid %>','<%= jsPname %>')">
                                            <i class="fas fa-times"></i> Reject
                                        </button>
                                    <% } else if ("Approved".equalsIgnoreCase(status)) { %>
                                        <button class="abtn complete"
                                            onclick="openConfirm('complete','<%= rid %>','<%= jsPname %>')">
                                            <i class="fas fa-check-double"></i> Complete
                                        </button>
                                    <% } else { %>
                                        <span class="status-done">
                                            <i class="fas fa-<%= "Completed".equalsIgnoreCase(status)?"check-double":"times-circle" %>"></i>
                                            <%= status %>
                                        </span>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                    <%  } } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ════ CONFIRM MODAL ════ */
var pendingAction='', pendingReturnId='';
var confirmMap = {
    approve:  { icon:'check-circle', cls:'success', label:'Approve', btnCls:'conf-approve',
                title:'Approve Return', desc:'The customer will be notified that their return has been approved.' },
    reject:   { icon:'times-circle', cls:'danger',  label:'Reject',  btnCls:'conf-reject',
                title:'Reject Return',  desc:'The return request will be rejected. The customer will be informed.' },
    complete: { icon:'check-double', cls:'purple',  label:'Complete', btnCls:'conf-complete',
                title:'Mark as Completed', desc:'Mark this return as fully processed. Refund should be issued to customer.' }
};

function openConfirm(action, returnId, productName) {
    pendingAction   = action;
    pendingReturnId = returnId;
    var m = confirmMap[action];
    document.getElementById('modalIcon').className  = 'modal-icon ' + m.cls;
    document.getElementById('modalIconI').className = 'fas fa-' + m.icon;
    document.getElementById('modalTitle').textContent = m.title;
    document.getElementById('modalDesc').innerHTML  = '<strong>' + productName + '</strong>: ' + m.desc;
    var btn = document.getElementById('modalConfirmBtn');
    btn.className   = 'modal-btn ' + m.btnCls;
    btn.textContent = m.label;
    document.getElementById('confirmModal').classList.add('open');
}
function closeConfirm() {
    document.getElementById('confirmModal').classList.remove('open');
    pendingAction=''; pendingReturnId='';
}
function submitConfirm() {
    if (pendingAction && pendingReturnId) {
        window.location.href = 'adminReturns.jsp?action=' + pendingAction + '&returnId=' + pendingReturnId;
    }
}
document.getElementById('confirmModal').addEventListener('click', function(e){ if(e.target===this) closeConfirm(); });

/* ════ DETAIL MODAL ════ */
function openDetail(rid,oid,pname,cname,cemail,cphone,sname,semail,biz,reason,desc,addr,city,state,odate,qty,price,status,created,updated) {
    var statusColor = {Pending:'#d97706',Approved:'#059669',Rejected:'#dc2626',Completed:'#7c3aed'};
    var col = statusColor[status] || '#64748b';

    var descBlock = desc.trim()
        ? '<div class="dm-desc">&ldquo;' + escHtml(desc) + '&rdquo;</div>'
        : '<div style="font-size:13px;color:#94a3b8;font-style:italic;">No additional details provided.</div>';

    document.getElementById('dmBody').innerHTML =
        '<div class="dm-grid">' +
        /* Order / Product */
        '<div class="dm-section">' +
            '<div class="dm-section-title"><i class="fas fa-box"></i> Product & Order</div>' +
            dmRow('Product', escHtml(pname)) +
            dmRow('Order ID', '<code style="font-size:12px;background:#f1f5f9;padding:2px 8px;border-radius:6px;">' + escHtml(oid) + '</code>') +
            dmRow('Qty', qty) +
            dmRow('Item Value', '&#8377;' + price) +
            dmRow('Order Date', odate) +
        '</div>' +
        /* Customer */
        '<div class="dm-section">' +
            '<div class="dm-section-title"><i class="fas fa-user"></i> Customer</div>' +
            dmRow('Name',    escHtml(cname)) +
            dmRow('Email',   escHtml(cemail)) +
            dmRow('Phone',   escHtml(cphone)) +
            dmRow('Address', escHtml(addr + (city?', '+city:'') + (state?', '+state:''))) +
        '</div>' +
        /* Seller */
        '<div class="dm-section">' +
            '<div class="dm-section-title"><i class="fas fa-store"></i> Seller</div>' +
            dmRow('Name',     escHtml(sname)) +
            dmRow('Email',    escHtml(semail)) +
            dmRow('Business', escHtml(biz)) +
        '</div>' +
        /* Return Info */
        '<div class="dm-section">' +
            '<div class="dm-section-title"><i class="fas fa-undo-alt"></i> Return Info</div>' +
            dmRow('Return #',   '#' + rid) +
            dmRow('Reason',     '<span style="background:rgba(249,115,22,.1);color:#ea580c;border-radius:6px;padding:2px 8px;font-size:12px;font-weight:700;">' + escHtml(reason) + '</span>') +
            dmRow('Status',     '<span style="color:' + col + ';font-weight:800;">' + status + '</span>') +
            dmRow('Requested',  created) +
            dmRow('Last Update',updated) +
        '</div>' +
        '</div>' +
        '<div style="margin-top:18px;">' +
            '<div style="font-size:11px;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px;"><i class="fas fa-comment-alt" style="color:var(--return);margin-right:6px;"></i>Customer Description</div>' +
            descBlock +
        '</div>';

    /* Footer action buttons based on status */
    var footer = '';
    if (status === 'Pending') {
        footer = '<button class="modal-btn cancel" onclick="closeDetail()">Close</button>' +
                 '<button class="abtn approve" style="padding:10px 20px;font-size:13px;" onclick="closeDetail();openConfirm(\'approve\',\''+rid+'\',\''+escHtml(pname)+'\')"><i class="fas fa-check"></i> Approve</button>' +
                 '<button class="abtn reject"  style="padding:10px 20px;font-size:13px;" onclick="closeDetail();openConfirm(\'reject\', \''+rid+'\',\''+escHtml(pname)+'\')"><i class="fas fa-times"></i> Reject</button>';
    } else if (status === 'Approved') {
        footer = '<button class="modal-btn cancel" onclick="closeDetail()">Close</button>' +
                 '<button class="abtn complete" style="padding:10px 20px;font-size:13px;" onclick="closeDetail();openConfirm(\'complete\',\''+rid+'\',\''+escHtml(pname)+'\')"><i class="fas fa-check-double"></i> Mark Complete</button>';
    } else {
        footer = '<button class="modal-btn cancel" onclick="closeDetail()">Close</button>';
    }
    document.getElementById('dmFooter').innerHTML = footer;
    document.getElementById('detailModal').classList.add('open');
}
function closeDetail() { document.getElementById('detailModal').classList.remove('open'); }
document.getElementById('detailModal').addEventListener('click', function(e){ if(e.target===this) closeDetail(); });

function dmRow(label, val) {
    return '<div class="dm-row"><span class="dm-label">' + label + '</span><span class="dm-val">' + val + '</span></div>';
}
function escHtml(s) {
    return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ════ SEARCH & FILTER ════ */
document.getElementById('searchInput').addEventListener('input', filterTable);

function filterTable() {
    var q      = document.getElementById('searchInput').value.toLowerCase();
    var status = document.getElementById('statusFilter').value;
    var reason = document.getElementById('reasonFilter').value.toLowerCase();
    var vis    = 0;
    document.querySelectorAll('#returnsBody tr[data-status]').forEach(function(row) {
        var mQ = !q      || row.getAttribute('data-search').includes(q);
        var mS = status === 'all' || row.getAttribute('data-status') === status;
        var mR = reason === 'all' || row.getAttribute('data-reason').includes(reason);
        var show = mQ && mS && mR;
        row.style.display = show ? '' : 'none';
        if (show) vis++;
    });
    var el = document.getElementById('visibleCount');
    if (el) el.textContent = vis + ' request' + (vis!==1?'s':'');
}

/* ════ Auto-hide flash ════ */
var flash = document.querySelector('.flash-msg');
if (flash) setTimeout(function(){
    flash.style.transition='opacity .6s'; flash.style.opacity='0';
    setTimeout(function(){if(flash.parentNode)flash.parentNode.removeChild(flash);},600);
}, 5000);
</script>
</body>
</html>
