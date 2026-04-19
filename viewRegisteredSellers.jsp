<%--
    viewRegisteredSellers.jsp
    Shows all sellerreg applications WITH approve / reject / suspend / reactivate actions.
    Approving a reg seller also INSERTs (or re-activates) the row in the sellers table.
--%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registered Sellers — MarketHub Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
        :root{
            --accent:#38bdf8;--accent2:#818cf8;--success:#10b981;--warning:#f59e0b;
            --danger:#ef4444;--suspend:#f97316;--sidebar-bg:#0f172a;--sidebar-w:270px;
            --page-bg:#f1f5f9;--border:#e2e8f0;--txt:#0f172a;--txt-m:#64748b;--txt-s:#94a3b8;
        }
        *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Sora',sans-serif;background:var(--page-bg);color:var(--txt);min-height:100vh;}

        /* ── Sidebar ── */
        .sidebar{position:fixed;left:0;top:0;height:100vh;width:var(--sidebar-w);background:var(--sidebar-bg);z-index:1000;overflow-y:auto;display:flex;flex-direction:column;box-shadow:4px 0 24px rgba(0,0,0,.18);}
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

        /* ── Main ── */
        .main-content{margin-left:var(--sidebar-w);min-height:100vh;}
        .top-bar{background:#fff;padding:18px 32px;display:flex;justify-content:space-between;align-items:center;box-shadow:0 1px 12px rgba(0,0,0,.06);position:sticky;top:0;z-index:999;border-bottom:1px solid var(--border);}
        .top-bar-left h1{font-size:22px;font-weight:800;color:var(--txt);letter-spacing:-.4px;}
        .top-bar-left p{font-size:13px;color:var(--txt-m);margin-top:2px;}
        .stat-pills{display:flex;gap:12px;align-items:center;flex-wrap:wrap;}
        .stat-pill{display:flex;align-items:center;gap:8px;padding:8px 16px;border-radius:20px;font-size:13px;font-weight:700;}
        .stat-pill.total{background:rgba(56,189,248,.1);color:var(--accent);}
        .stat-pill.approved{background:rgba(16,185,129,.1);color:var(--success);}
        .stat-pill.pending{background:rgba(245,158,11,.1);color:var(--warning);}
        .stat-pill.suspend{background:rgba(249,115,22,.1);color:var(--suspend);}

        /* ── Page body ── */
        .page-body{padding:28px 32px;}
        .flash-msg{display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:14px;margin-bottom:24px;font-weight:600;font-size:14px;animation:slideDown .4s ease;}
        @keyframes slideDown{from{opacity:0;transform:translateY(-12px)}to{opacity:1;transform:translateY(0)}}
        .flash-msg.success{background:rgba(16,185,129,.1);color:#059669;border-left:4px solid var(--success);}
        .flash-msg.error{background:rgba(239,68,68,.1);color:#dc2626;border-left:4px solid var(--danger);}

        /* ── Controls ── */
        .table-controls{display:flex;gap:14px;align-items:center;margin-bottom:20px;flex-wrap:wrap;}
        .search-box{display:flex;align-items:center;gap:10px;background:#fff;border:2px solid var(--border);border-radius:12px;padding:10px 16px;flex:1;min-width:220px;transition:border-color .25s;}
        .search-box:focus-within{border-color:var(--accent);}
        .search-box i{color:var(--txt-s);font-size:15px;}
        .search-box input{border:none;outline:none;font-family:'Sora',sans-serif;font-size:14px;font-weight:500;color:var(--txt);background:transparent;width:100%;}
        .search-box input::placeholder{color:var(--txt-s);}
        .filter-select{padding:10px 14px;border:2px solid var(--border);border-radius:12px;font-family:'Sora',sans-serif;font-size:13px;font-weight:600;color:var(--txt);background:#fff;cursor:pointer;outline:none;transition:border-color .25s;}
        .filter-select:focus{border-color:var(--accent);}

        /* ── Table card ── */
        .table-card{background:#fff;border-radius:18px;box-shadow:0 2px 16px rgba(0,0,0,.06);overflow:hidden;border:1px solid var(--border);margin-bottom:32px;}
        .table-card-header{display:flex;justify-content:space-between;align-items:center;padding:20px 24px;border-bottom:1px solid var(--border);}
        .table-card-header h3{font-size:17px;font-weight:700;color:var(--txt);}
        .total-badge{background:linear-gradient(135deg,rgba(56,189,248,.12),rgba(129,140,248,.12));color:var(--accent);padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700;}
        table.reg-table{width:100%;border-collapse:collapse;}
        table.reg-table thead{background:linear-gradient(135deg,#f8fafc,#f1f5f9);}
        table.reg-table th{padding:14px 16px;text-align:left;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;color:var(--txt-m);white-space:nowrap;}
        table.reg-table td{padding:14px 16px;border-bottom:1px solid var(--border);font-size:13px;color:var(--txt);vertical-align:middle;}
        table.reg-table tbody tr{transition:background .2s;}
        table.reg-table tbody tr:hover{background:#f8fafc;}
        table.reg-table tbody tr:last-child td{border-bottom:none;}

        /* ── Cells ── */
        .seller-cell{display:flex;align-items:center;gap:12px;}
        .seller-avatar{width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:16px;color:#fff;flex-shrink:0;}
        .seller-name{font-weight:700;font-size:14px;}
        .seller-sub{font-size:11px;color:var(--txt-m);margin-top:2px;}

        /* ── Badges ── */
        .sbadge{display:inline-flex;align-items:center;gap:6px;padding:6px 13px;border-radius:20px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;}
        .sbadge::before{content:'';width:6px;height:6px;border-radius:50%;flex-shrink:0;}
        .sbadge.approved{background:rgba(16,185,129,.1);color:#059669;}.sbadge.approved::before{background:var(--success);}
        .sbadge.pending{background:rgba(245,158,11,.1);color:#d97706;}.sbadge.pending::before{background:var(--warning);}
        .sbadge.rejected{background:rgba(239,68,68,.1);color:#dc2626;}.sbadge.rejected::before{background:var(--danger);}
        .sbadge.suspended{background:rgba(249,115,22,.1);color:#ea580c;}.sbadge.suspended::before{background:var(--suspend);}
        .cbadge{display:inline-flex;align-items:center;gap:5px;padding:4px 11px;border-radius:20px;font-size:11px;font-weight:700;text-transform:capitalize;white-space:nowrap;}
        .cbadge.fashion{background:rgba(129,140,248,.12);color:#6366f1;}
        .cbadge.beauty{background:rgba(249,115,22,.12);color:#ea580c;}
        .cbadge.electronics{background:rgba(56,189,248,.12);color:#0284c7;}
        .cbadge.food{background:rgba(16,185,129,.12);color:#059669;}
        .cbadge.health{background:rgba(245,158,11,.12);color:#d97706;}
        .cbadge.other{background:rgba(148,163,184,.12);color:#64748b;}
        .btype-pill{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border-radius:8px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;}
        .btype-pill.individual{background:rgba(99,102,241,.1);color:#6366f1;}
        .btype-pill.pvt_ltd{background:rgba(14,165,233,.1);color:#0284c7;}
        .btype-pill.ltd{background:rgba(16,185,129,.1);color:#059669;}
        .btype-pill.llp{background:rgba(245,158,11,.1);color:#d97706;}
        .btype-pill.other{background:rgba(148,163,184,.1);color:#64748b;}
        .detail-tag{display:inline-flex;align-items:center;gap:5px;padding:3px 9px;border-radius:6px;font-size:10px;font-weight:600;background:rgba(56,189,248,.08);color:#0284c7;font-family:'JetBrains Mono',monospace;margin:2px 0;}

        /* ── Activeness ── */
        .activeness-wrap{display:flex;flex-direction:column;gap:5px;min-width:110px;}
        .activeness-label{font-size:11px;font-weight:700;}
        .activeness-label.hot{color:var(--success);}.activeness-label.warm{color:var(--warning);}
        .activeness-label.cold{color:var(--txt-m);}.activeness-label.frozen{color:var(--danger);}
        .activeness-bar-bg{height:6px;background:var(--border);border-radius:6px;overflow:hidden;width:100%;}
        .activeness-bar{height:100%;border-radius:6px;}
        .activeness-bar.hot{background:linear-gradient(90deg,#10b981,#34d399);}
        .activeness-bar.warm{background:linear-gradient(90deg,#f59e0b,#fbbf24);}
        .activeness-bar.cold{background:linear-gradient(90deg,#94a3b8,#cbd5e1);}
        .activeness-bar.frozen{background:linear-gradient(90deg,#ef4444,#f87171);}
        .last-order-txt{font-size:11px;color:var(--txt-s);margin-top:2px;font-family:'JetBrains Mono',monospace;}

        /* ── Action buttons ── */
        .actions-wrap{display:flex;gap:7px;flex-wrap:wrap;align-items:center;}
        .abtn{display:inline-flex;align-items:center;gap:5px;padding:7px 13px;border:none;border-radius:8px;font-size:12px;font-weight:700;cursor:pointer;font-family:'Sora',sans-serif;transition:all .22s;text-decoration:none;white-space:nowrap;}
        .abtn.approve{background:rgba(16,185,129,.1);color:#059669;}
        .abtn.approve:hover{background:var(--success);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(16,185,129,.3);}
        .abtn.reject{background:rgba(239,68,68,.1);color:#dc2626;}
        .abtn.reject:hover{background:var(--danger);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(239,68,68,.3);}
        .abtn.suspend{background:rgba(249,115,22,.1);color:#ea580c;}
        .abtn.suspend:hover{background:var(--suspend);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(249,115,22,.3);}
        .abtn.unsuspend{background:rgba(16,185,129,.1);color:#059669;}
        .abtn.unsuspend:hover{background:var(--success);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(16,185,129,.3);}
        .abtn.view{background:rgba(56,189,248,.1);color:#0284c7;}
        .abtn.view:hover{background:var(--accent);color:#fff;transform:translateY(-1px);box-shadow:0 4px 14px rgba(56,189,248,.3);}

        .empty-row td{text-align:center;padding:50px 20px!important;}
        .empty-row i{font-size:52px;opacity:.18;display:block;margin-bottom:14px;}

        /* ── Confirm Modal ── */
        .modal-overlay{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:9999;display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px);}
        .modal-overlay.open{display:flex;animation:fadeIn .25s ease;}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        .modal-box{background:#fff;border-radius:20px;padding:32px 36px;max-width:420px;width:90%;box-shadow:0 24px 60px rgba(0,0,0,.18);animation:popIn .3s ease;}
        @keyframes popIn{from{transform:scale(.92);opacity:0}to{transform:scale(1);opacity:1}}
        .modal-icon{width:60px;height:60px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:26px;margin:0 auto 18px;}
        .modal-icon.warn{background:rgba(249,115,22,.12);color:var(--suspend);}
        .modal-icon.danger{background:rgba(239,68,68,.12);color:var(--danger);}
        .modal-icon.success{background:rgba(16,185,129,.12);color:var(--success);}
        .modal-box h4{text-align:center;font-size:18px;font-weight:800;color:var(--txt);margin-bottom:10px;}
        .modal-box p{text-align:center;font-size:14px;color:var(--txt-m);line-height:1.6;margin-bottom:24px;}
        .modal-actions{display:flex;gap:12px;justify-content:center;}
        .modal-btn{padding:11px 28px;border:none;border-radius:10px;font-size:14px;font-weight:700;cursor:pointer;font-family:'Sora',sans-serif;transition:all .2s;}
        .modal-btn.cancel{background:var(--border);color:var(--txt-m);}
        .modal-btn.cancel:hover{background:#cbd5e1;}
        .modal-btn.confirm-suspend{background:var(--suspend);color:#fff;}
        .modal-btn.confirm-reject{background:var(--danger);color:#fff;}
        .modal-btn.confirm-approve{background:var(--success);color:#fff;}
        .modal-btn.confirm-unsuspend{background:var(--success);color:#fff;}

        /* ── Detail Drawer ── */
        .drawer-overlay{position:fixed;inset:0;background:rgba(15,23,42,.5);z-index:9998;display:none;backdrop-filter:blur(4px);}
        .drawer-overlay.open{display:block;animation:fadeIn .25s ease;}
        .drawer{position:fixed;right:0;top:0;height:100vh;width:480px;max-width:95vw;background:#fff;z-index:9999;transform:translateX(100%);transition:transform .35s cubic-bezier(.4,0,.2,1);overflow-y:auto;display:flex;flex-direction:column;box-shadow:-8px 0 40px rgba(0,0,0,.12);}
        .drawer.open{transform:translateX(0);}
        .drawer::-webkit-scrollbar{width:4px;}.drawer::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px;}
        .drawer-header{padding:24px 28px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:#fff;z-index:1;}
        .drawer-header h3{font-size:18px;font-weight:800;color:var(--txt);}
        .drawer-close{width:36px;height:36px;border-radius:50%;border:none;background:var(--border);color:var(--txt-m);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:16px;transition:all .2s;}
        .drawer-close:hover{background:var(--danger);color:#fff;}
        .drawer-body{padding:24px 28px;flex:1;}
        .drawer-avatar-row{display:flex;align-items:center;gap:18px;margin-bottom:28px;padding-bottom:24px;border-bottom:1px solid var(--border);}
        .drawer-avatar{width:64px;height:64px;border-radius:18px;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:26px;color:#fff;}
        .drawer-avatar-info h4{font-size:20px;font-weight:800;color:var(--txt);}
        .drawer-avatar-info p{font-size:13px;color:var(--txt-m);margin-top:4px;}
        .section-title{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:1.5px;color:var(--txt-s);margin:20px 0 12px;}
        .info-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
        .info-item{background:var(--page-bg);border-radius:12px;padding:14px;}
        .info-item label{display:block;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.8px;color:var(--txt-s);margin-bottom:5px;}
        .info-item span{font-size:13px;font-weight:600;color:var(--txt);word-break:break-all;}
        .info-item.full{grid-column:1/-1;}
        .desc-box{background:var(--page-bg);border-radius:12px;padding:14px;font-size:13px;color:var(--txt-m);line-height:1.7;}
        .bank-card{background:linear-gradient(135deg,#0f172a,#1e3a5f);border-radius:16px;padding:20px 22px;color:#fff;position:relative;overflow:hidden;margin-top:4px;}
        .bank-card::before{content:'';position:absolute;right:-20px;top:-20px;width:120px;height:120px;border-radius:50%;background:rgba(56,189,248,.12);}
        .bank-card-label{font-size:10px;color:rgba(255,255,255,.5);letter-spacing:1px;text-transform:uppercase;margin-bottom:6px;}
        .bank-card-acct{font-size:18px;font-weight:700;font-family:'JetBrains Mono',monospace;letter-spacing:2px;}
        .bank-card-row{display:flex;justify-content:space-between;align-items:flex-end;margin-top:16px;}
        .bank-card-field label{font-size:9px;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.8px;}
        .bank-card-field span{display:block;font-size:13px;font-weight:700;margin-top:2px;}
        .created-chip{display:inline-flex;align-items:center;gap:8px;padding:8px 16px;border-radius:20px;background:rgba(56,189,248,.08);color:#0284c7;font-size:12px;font-weight:600;margin-top:20px;}

        @media(max-width:1100px){:root{--sidebar-w:70px;}.logo-text,.nav-section-label,.nav-link-item span,.admin-chip-info{display:none;}.nav-link-item{justify-content:center;padding:14px;}.admin-chip{justify-content:center;}}
        @media(max-width:768px){:root{--sidebar-w:0px;}.sidebar{display:none;}.page-body{padding:18px 16px;}.top-bar{padding:14px 16px;flex-direction:column;gap:12px;align-items:flex-start;}.stat-pills{display:none;}.info-grid{grid-template-columns:1fr;}.drawer{width:100vw;}}
    </style>
</head>
<body>

<%!
    int daysSinceDateReg(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return 9999;
        try {
            String d = dateStr.substring(0, 10);
            java.time.LocalDate ld  = java.time.LocalDate.parse(d);
            java.time.LocalDate now = java.time.LocalDate.now();
            return (int) java.time.temporal.ChronoUnit.DAYS.between(ld, now);
        } catch (Exception e) { return 9999; }
    }
%>

<%
/* ════════════════════════════════════════════════════════════════
   ACTION HANDLER
   approve  → UPDATE sellerreg + INSERT/UPDATE sellers table
   reject   → UPDATE sellerreg (+ mirror in sellers if exists)
   suspend  → UPDATE sellerreg (+ mirror in sellers if exists)
   unsuspend→ UPDATE sellerreg to 'approved' + re-activate sellers
════════════════════════════════════════════════════════════════ */
String action    = request.getParameter("action");
String sellerIdP = request.getParameter("sellerId");
String flashMsg  = "";
String flashType = "";

String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
String dbUser = "root";
String dbPass = "";

if (action != null && sellerIdP != null) {
    Connection ac = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        ac = DriverManager.getConnection(dbURL, dbUser, dbPass);

        String newStatus = "";
        if      ("approve".equals(action))   { newStatus = "approved";  flashMsg = "Seller approved — now visible in Active Sellers."; flashType = "success"; }
        else if ("reject".equals(action))    { newStatus = "rejected";  flashMsg = "Seller application rejected.";                     flashType = "error";   }
        else if ("suspend".equals(action))   { newStatus = "suspended"; flashMsg = "Seller account suspended.";                        flashType = "error";   }
        else if ("unsuspend".equals(action)) { newStatus = "approved";  flashMsg = "Seller account reactivated.";                      flashType = "success"; }

        if (!newStatus.isEmpty()) {
            // Step 1: update sellerreg status
            PreparedStatement upReg = ac.prepareStatement("UPDATE sellerreg SET status=? WHERE id=?");
            upReg.setString(1, newStatus);
            upReg.setInt(2, Integer.parseInt(sellerIdP));
            upReg.executeUpdate(); upReg.close();

            // Step 2: fetch applicant details
            PreparedStatement fetchReg = ac.prepareStatement(
                "SELECT Fname, Lname, email, phono, Bname FROM sellerreg WHERE id=?");
            fetchReg.setInt(1, Integer.parseInt(sellerIdP));
            ResultSet regRow = fetchReg.executeQuery();

            if (regRow.next()) {
                String rFname    = regRow.getString("Fname") != null ? regRow.getString("Fname") : "";
                String rLname    = regRow.getString("Lname") != null ? regRow.getString("Lname") : "";
                String rEmail    = regRow.getString("email") != null ? regRow.getString("email") : "";
                String rPhone    = regRow.getString("phono") != null ? regRow.getString("phono") : "";
                String rBname    = regRow.getString("Bname") != null ? regRow.getString("Bname") : "";
                String rFullName = (rFname + " " + rLname).trim();

                // Step 3: check if email already in sellers
                PreparedStatement chk = ac.prepareStatement("SELECT id FROM sellers WHERE email=?");
                chk.setString(1, rEmail);
                ResultSet chkRes = chk.executeQuery();
                boolean alreadyInSellers = chkRes.next();
                chkRes.close(); chk.close();

                if ("approved".equals(newStatus)) {
                    if (alreadyInSellers) {
                        PreparedStatement upS = ac.prepareStatement(
                            "UPDATE sellers SET status='approved', name=?, phone=?, business_name=? WHERE email=?");
                        upS.setString(1, rFullName); upS.setString(2, rPhone);
                        upS.setString(3, rBname);    upS.setString(4, rEmail);
                        upS.executeUpdate(); upS.close();
                    } else {
                        PreparedStatement ins = ac.prepareStatement(
                            "INSERT INTO sellers (name, email, phone, business_name, status) VALUES (?,?,?,?,'approved')");
                        ins.setString(1, rFullName); ins.setString(2, rEmail);
                        ins.setString(3, rPhone);    ins.setString(4, rBname);
                        ins.executeUpdate(); ins.close();
                    }
                } else if (alreadyInSellers) {
                    PreparedStatement upS2 = ac.prepareStatement("UPDATE sellers SET status=? WHERE email=?");
                    upS2.setString(1, newStatus); upS2.setString(2, rEmail);
                    upS2.executeUpdate(); upS2.close();
                }
            }
            regRow.close(); fetchReg.close();
        }
    } catch (Exception ex) {
        flashMsg  = "Error: " + ex.getMessage();
        flashType = "error";
    } finally {
        try { if (ac != null) ac.close(); } catch (Exception ig) {}
    }
}

/* ════════════════════════════════════════════════════════════
   Fetch all registered sellers from sellerreg
════════════════════════════════════════════════════════════ */
List<Map<String,String>> regSellers = new ArrayList<Map<String,String>>();
int rTotal=0, rPending=0, rApproved=0, rSuspended=0;

Connection sc = null; Statement ss = null; ResultSet sr = null;
String errMsg = "";

try {
    Class.forName("com.mysql.jdbc.Driver");
    sc = DriverManager.getConnection(dbURL, dbUser, dbPass);
    ss = sc.createStatement();
    sr = ss.executeQuery("SELECT * FROM sellerreg ORDER BY id DESC");

    while (sr.next()) {
        Map<String,String> row = new HashMap<String,String>();
        row.put("id",        String.valueOf(sr.getInt("id")));
        row.put("fname",     sr.getString("Fname")     != null ? sr.getString("Fname")     : "");
        row.put("lname",     sr.getString("Lname")     != null ? sr.getString("Lname")     : "");
        row.put("email",     sr.getString("email")     != null ? sr.getString("email")     : "");
        row.put("phono",     sr.getString("phono")     != null ? sr.getString("phono")     : "—");
        row.put("bname",     sr.getString("Bname")     != null ? sr.getString("Bname")     : "—");
        row.put("btype",     sr.getString("Btype")     != null ? sr.getString("Btype")     : "other");
        row.put("category",  sr.getString("category")  != null ? sr.getString("category")  : "other");
        row.put("gst",       sr.getString("gst")       != null ? sr.getString("gst")       : "—");
        row.put("pan",       sr.getString("pan")       != null ? sr.getString("pan")       : "—");
        row.put("disc",      sr.getString("disc")      != null ? sr.getString("disc")      : "");
        row.put("address1",  sr.getString("address1")  != null ? sr.getString("address1")  : "");
        row.put("address2",  sr.getString("address2")  != null ? sr.getString("address2")  : "");
        row.put("city",      sr.getString("city")      != null ? sr.getString("city")      : "");
        row.put("state",     sr.getString("state")     != null ? sr.getString("state")     : "");
        row.put("pin",       sr.getString("pin")       != null ? sr.getString("pin")       : "");
        row.put("accountno", sr.getString("accountno") != null ? sr.getString("accountno") : "");
        row.put("ifsc",      sr.getString("ifsc")      != null ? sr.getString("ifsc")      : "");
        row.put("bankname",  sr.getString("bankname")  != null ? sr.getString("bankname")  : "");

        // status
        String rstat = "pending";
        try { String tmp=sr.getString("status"); if(tmp!=null&&!tmp.trim().isEmpty()) rstat=tmp.trim().toLowerCase(); } catch(Exception se){}
        row.put("status", rstat);

        // mask account
        String acct = row.get("accountno");
        String maskedAcct;
        if (acct.length() > 4) {
            StringBuilder sb = new StringBuilder();
            for (int m=0; m<acct.length()-4; m++) sb.append("*");
            sb.append(acct.substring(acct.length()-4));
            maskedAcct = sb.toString();
        } else { maskedAcct = acct; }
        row.put("maskedAcct", maskedAcct);

        // created
        try {
            java.sql.Timestamp ts = sr.getTimestamp("created");
            row.put("created", ts != null ? ts.toString().substring(0,10) : "—");
        } catch (Exception te) { row.put("created","—"); }

        // full name
        String fullName = (row.get("fname")+" "+row.get("lname")).trim();
        if (fullName.isEmpty()) fullName = "Unknown";
        row.put("fullName", fullName);

        // activeness
        String lor = "";
        try {
            PreparedStatement pa=sc.prepareStatement("SELECT MAX(o.order_date) AS ld FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap.seller_email=?");
            pa.setString(1, row.get("email")); ResultSet ra=pa.executeQuery();
            if(ra.next()&&ra.getString("ld")!=null) lor=ra.getString("ld");
            ra.close(); pa.close();
        } catch(Exception ae){}
        String ab = lor.isEmpty() ? row.get("created") : lor;
        int d2 = daysSinceDateReg(ab);
        String ll;
        if(lor.isEmpty()&&row.get("created").equals("—")) ll="No activity";
        else if(lor.isEmpty()) ll="Registered "+d2+"d ago";
        else if(d2==0) ll="Today";
        else if(d2==1) ll="Yesterday";
        else ll=d2+" days ago";
        String rtier; int rb;
        if(ab.isEmpty()||ab.equals("—")){rtier="frozen";rb=5;}
        else if(d2<=7){rtier="hot";rb=100;}
        else if(d2<=30){rtier="warm";rb=65;}
        else if(d2<=90){rtier="cold";rb=30;}
        else{rtier="frozen";rb=10;}
        row.put("tier",rtier); row.put("barPct",String.valueOf(rb)); row.put("lastLabel",ll);

        regSellers.add(row);
        rTotal++;
        if("approved".equals(rstat))  rApproved++;
        else if("pending".equals(rstat))   rPending++;
        else if("suspended".equals(rstat)) rSuspended++;
    }
} catch (Exception ex) {
    errMsg = "DB Error: " + ex.getMessage();
} finally {
    try { if(sr!=null)sr.close(); if(ss!=null)ss.close(); if(sc!=null)sc.close(); } catch(Exception ig){}
}
%>

<!-- SIDEBAR -->
<aside class="sidebar">
    <div class="sidebar-header">
        <a href="#" class="sidebar-logo">
            <div class="logo-icon"><i class="fas fa-shopping-bag"></i></div>
            <div class="logo-text"><h3>MarketHub</h3><span>Admin Panel</span></div>
        </a>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="adhome.jsp" class="nav-link-item"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
        <div class="nav-section-label">Management</div>
        <a href="adminProducts.jsp" class="nav-link-item"><i class="fas fa-box"></i><span>Products</span></a>
        <div class="nav-section-label">Sellers</div>
        <a href="viewRegisteredSellers.jsp" class="nav-link-item active"><i class="fas fa-user-plus"></i><span>Registered Sellers</span></a>
        <div class="nav-section-label">Travels</div>
        <a href="travel_logistics.jsp" class="nav-link-item"><i class="fas fa-truck"></i><span>Travels</span></a>
        <a href="adminReturns.jsp" class="nav-link-item"><i class="fas fa-undo-alt"></i><span>Returns</span></a>
        <div class="nav-section-label">Account</div>
        <a href="adlogin.jsp" class="nav-link-item"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
    </nav>
    <div class="sidebar-footer">
        <div class="admin-chip">
            <div class="admin-avatar">A</div>
            <div class="admin-chip-info"><strong>Admin User</strong><span>Super Admin</span></div>
        </div>
    </div>
</aside>

<!-- MAIN -->
<main class="main-content">
    <div class="top-bar">
        <div class="top-bar-left">
            <h1><i class="fas fa-user-plus" style="color:var(--accent);margin-right:10px;font-size:20px;"></i>Registered Seller Applications</h1>
            <p>Review, approve, reject or suspend seller registration requests</p>
        </div>
        <div class="stat-pills">
            <div class="stat-pill total"><i class="fas fa-clipboard-list"></i> <%= rTotal %> Total</div>
            <div class="stat-pill approved"><i class="fas fa-check-circle"></i> <%= rApproved %> Approved</div>
            <div class="stat-pill pending"><i class="fas fa-clock"></i> <%= rPending %> Pending</div>
            <div class="stat-pill suspend"><i class="fas fa-ban"></i> <%= rSuspended %> Suspended</div>
        </div>
    </div>

    <div class="page-body">

        <% if (!flashMsg.isEmpty()) { %>
        <div class="flash-msg <%= flashType %>">
            <i class="fas fa-<%= "success".equals(flashType)?"check-circle":"exclamation-circle" %>"></i>
            <span><%= flashMsg %></span>
        </div>
        <% } %>

        <% if (!errMsg.isEmpty()) { %>
        <div class="flash-msg error">
            <i class="fas fa-exclamation-circle"></i><span><%= errMsg %></span>
        </div>
        <% } %>

        <!-- Controls -->
        <div class="table-controls">
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search by name, email, business, city...">
            </div>
            <select class="filter-select" id="statusFilter" onchange="filterTable()">
                <option value="all">All Statuses</option>
                <option value="pending">Pending</option>
                <option value="approved">Approved</option>
                <option value="suspended">Suspended</option>
                <option value="rejected">Rejected</option>
            </select>
            <select class="filter-select" id="catFilter" onchange="filterTable()">
                <option value="all">All Categories</option>
                <option value="fashion">Fashion</option>
                <option value="beauty">Beauty</option>
                <option value="electronics">Electronics</option>
                <option value="food">Food</option>
                <option value="health">Health</option>
                <option value="other">Other</option>
            </select>
            <select class="filter-select" id="activityFilter" onchange="filterTable()">
                <option value="all">All Activity</option>
                <option value="hot">&#x1F525; Hot</option>
                <option value="warm">&#x26A1; Warm</option>
                <option value="cold">&#x2744; Cold</option>
                <option value="frozen">&#x1F9CA; Inactive</option>
            </select>
        </div>

        <!-- Table -->
        <div class="table-card">
            <div class="table-card-header">
                <h3><i class="fas fa-clipboard-list" style="color:var(--accent2);margin-right:10px;"></i>Registered Sellers</h3>
                <span class="total-badge" id="visibleCount"><%= rTotal %> registrations</span>
            </div>
            <div style="overflow-x:auto;">
                <table class="reg-table">
                    <thead>
                        <tr>
                            <th>#</th><th>Seller</th><th>Business</th><th>Category</th>
                            <th>Type</th><th>Location</th><th>Tax IDs</th>
                            <th>Activeness</th><th>Status</th><th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="regBody">
                    <% if (regSellers.isEmpty()) { %>
                        <tr class="empty-row">
                            <td colspan="10">
                                <i class="fas fa-user-slash"></i>
                                <p style="font-size:16px;font-weight:700;color:var(--txt-m);">No registrations found</p>
                            </td>
                        </tr>
                    <% } else {
                        String[] avatarColors={"#6366f1","#8b5cf6","#ec4899","#0ea5e9","#10b981","#f59e0b","#ef4444","#14b8a6"};
                        int ci=0;
                        for (Map<String,String> s : regSellers) {
                            String sid      = s.get("id");
                            String fullName = s.get("fullName");
                            String semail   = s.get("email");
                            String sphono   = s.get("phono");
                            String sbname   = s.get("bname");
                            String sbtype   = s.get("btype").toLowerCase();
                            String scat     = s.get("category").toLowerCase();
                            String scity    = s.get("city");
                            String sstate   = s.get("state");
                            String sgstn    = s.get("gst");
                            String span_    = s.get("pan");
                            String screated = s.get("created");
                            String sdisc    = s.get("disc");
                            String sadd1    = s.get("address1");
                            String sadd2    = s.get("address2");
                            String spin     = s.get("pin");
                            String sacct    = s.get("accountno");
                            String smasked  = s.get("maskedAcct");
                            String sifsc    = s.get("ifsc");
                            String sbank    = s.get("bankname");
                            String sstat    = s.get("status");
                            String stier    = s.get("tier");
                            String sbp      = s.get("barPct");
                            String sll      = s.get("lastLabel");

                            String avc = avatarColors[ci % avatarColors.length];
                            String avl = (fullName.length()>0) ? String.valueOf(fullName.charAt(0)).toUpperCase() : "?";

                            String catCls;
                            if(scat.contains("fashion"))catCls="fashion";
                            else if(scat.contains("beauty"))catCls="beauty";
                            else if(scat.contains("electronics"))catCls="electronics";
                            else if(scat.contains("food"))catCls="food";
                            else if(scat.contains("health"))catCls="health";
                            else catCls="other";

                            String btypeDisplay;
                            if(sbtype.equals("pvt_ltd"))btypeDisplay="Pvt Ltd";
                            else if(sbtype.equals("individual"))btypeDisplay="Individual";
                            else if(sbtype.equals("ltd"))btypeDisplay="Ltd";
                            else if(sbtype.equals("llp"))btypeDisplay="LLP";
                            else btypeDisplay=sbtype;

                            String tl;
                            if("hot".equals(stier))tl="&#x1F525; Hot";
                            else if("warm".equals(stier))tl="&#x26A1; Warm";
                            else if("cold".equals(stier))tl="&#x2744; Cold";
                            else tl="&#x1F9CA; Inactive";

                            String safeDisc  = sdisc.replace("'","&#39;").replace("\n"," ");
                            String safeAddr2 = sadd2.replace("'","&#39;");
                            String safeName  = fullName.replace("'","&#39;");
                            ci++;
                    %>
                        <tr data-status="<%= sstat %>"
                            data-category="<%= scat %>"
                            data-tier="<%= stier %>"
                            data-search="<%= fullName.toLowerCase()+" "+semail.toLowerCase()+" "+sbname.toLowerCase()+" "+scity.toLowerCase() %>">

                            <td style="color:var(--txt-s);font-family:'JetBrains Mono',monospace;font-size:12px;">#<%= sid %></td>

                            <td>
                                <div class="seller-cell">
                                    <div class="seller-avatar" style="background:<%= avc %>;"><%= avl %></div>
                                    <div>
                                        <div class="seller-name"><%= fullName %></div>
                                        <div class="seller-sub"><%= semail %></div>
                                        <div class="seller-sub"><i class="fas fa-phone" style="font-size:9px;"></i> <%= sphono %></div>
                                    </div>
                                </div>
                            </td>

                            <td><div style="font-weight:700;font-size:13px;"><%= sbname %></div></td>

                            <td><span class="cbadge <%= catCls %>"><%= scat %></span></td>

                            <td><span class="btype-pill <%= sbtype %>"><%= btypeDisplay %></span></td>

                            <td>
                                <div style="font-size:13px;font-weight:600;"><%= scity %>, <%= sstate %></div>
                                <div style="font-size:11px;color:var(--txt-s);">PIN: <%= spin %></div>
                            </td>

                            <td>
                                <div style="display:flex;flex-direction:column;gap:4px;">
                                    <span class="detail-tag"><i class="fas fa-file-invoice" style="font-size:9px;"></i> <%= sgstn %></span>
                                    <span class="detail-tag"><i class="fas fa-id-card" style="font-size:9px;"></i> <%= span_ %></span>
                                </div>
                            </td>

                            <td>
                                <div class="activeness-wrap">
                                    <span class="activeness-label <%= stier %>"><%= tl %></span>
                                    <div class="activeness-bar-bg"><div class="activeness-bar <%= stier %>" style="width:<%= sbp %>%;"></div></div>
                                    <span class="last-order-txt"><%= sll %></span>
                                </div>
                            </td>

                            <td><span class="sbadge <%= sstat %>"><%= sstat.toUpperCase() %></span></td>

                            <td>
                                <div class="actions-wrap">
                                    <% if("pending".equals(sstat)){ %>
                                        <button class="abtn approve" onclick="openModal('approve','<%= sid %>','<%= safeName %>')"><i class="fas fa-check"></i> Approve</button>
                                        <button class="abtn reject"  onclick="openModal('reject','<%= sid %>','<%= safeName %>')"><i class="fas fa-times"></i> Reject</button>
                                    <% } %>
                                    <% if("approved".equals(sstat)){ %>
                                        <button class="abtn suspend" onclick="openModal('suspend','<%= sid %>','<%= safeName %>')"><i class="fas fa-ban"></i> Suspend</button>
                                    <% } %>
                                    <% if("suspended".equals(sstat)){ %>
                                        <button class="abtn unsuspend" onclick="openModal('unsuspend','<%= sid %>','<%= safeName %>')"><i class="fas fa-redo"></i> Reactivate</button>
                                    <% } %>
                                    <button class="abtn view"
                                        onclick="openDrawer(
                                            '<%= sid %>','<%= safeName %>','<%= semail %>',
                                            '<%= sphono %>','<%= sbname.replace("'","&#39;") %>',
                                            '<%= sbtype %>','<%= scat %>','<%= sgstn %>',
                                            '<%= span_ %>','<%= safeDisc %>',
                                            '<%= sadd1.replace("'","&#39;") %>','<%= safeAddr2 %>',
                                            '<%= scity %>','<%= sstate %>','<%= spin %>',
                                            '<%= sacct %>','<%= sifsc %>','<%= sbank.replace("'","&#39;") %>',
                                            '<%= screated %>','<%= avc %>','<%= avl %>'
                                        )">
                                        <i class="fas fa-eye"></i> View
                                    </button>
                                </div>
                            </td>
                        </tr>
                    <% } } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>
</main>

<!-- CONFIRM MODAL -->
<div class="modal-overlay" id="confirmModal">
    <div class="modal-box">
        <div class="modal-icon" id="modalIcon"><i id="modalIconI" class="fas fa-question"></i></div>
        <h4 id="modalTitle">Confirm Action</h4>
        <p id="modalDesc">Are you sure?</p>
        <div class="modal-actions">
            <button class="modal-btn cancel" onclick="closeModal()">Cancel</button>
            <button class="modal-btn" id="modalConfirmBtn" onclick="submitAction()">Confirm</button>
        </div>
    </div>
</div>

<!-- DETAIL DRAWER -->
<div class="drawer-overlay" id="drawerOverlay" onclick="closeDrawer()"></div>
<div class="drawer" id="detailDrawer">
    <div class="drawer-header">
        <h3 id="drawerTitle">Seller Details</h3>
        <button class="drawer-close" onclick="closeDrawer()"><i class="fas fa-times"></i></button>
    </div>
    <div class="drawer-body" id="drawerBody"></div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Search & Filter ── */
document.getElementById('searchInput').addEventListener('input', filterTable);
function filterTable() {
    var q      = document.getElementById('searchInput').value.toLowerCase();
    var stat   = document.getElementById('statusFilter').value;
    var cat    = document.getElementById('catFilter').value;
    var act    = document.getElementById('activityFilter').value;
    var visible = 0;
    document.querySelectorAll('#regBody tr[data-status]').forEach(function(row) {
        var mQ  = !q    || row.getAttribute('data-search').indexOf(q) !== -1;
        var mS  = stat  === 'all' || row.getAttribute('data-status')   === stat;
        var mC  = cat   === 'all' || row.getAttribute('data-category').indexOf(cat) !== -1;
        var mA  = act   === 'all' || row.getAttribute('data-tier')     === act;
        var show = mQ && mS && mC && mA;
        row.style.display = show ? '' : 'none';
        if (show) visible++;
    });
    var el = document.getElementById('visibleCount');
    if (el) el.textContent = visible + ' registration' + (visible !== 1 ? 's' : '');
}

/* ── Confirm Modal ── */
var pendingAction='', pendingSellerId='';
var iconMap = {
    approve:  {icon:'check-circle', cls:'success', label:'Approve',    btnCls:'confirm-approve',   title:'Approve Seller',   desc:'This seller will be approved and will appear in <strong>Active Sellers</strong> on the dashboard.'},
    reject:   {icon:'times-circle', cls:'danger',  label:'Reject',     btnCls:'confirm-reject',    title:'Reject Application',desc:'This application will be rejected.'},
    suspend:  {icon:'ban',          cls:'warn',    label:'Suspend',    btnCls:'confirm-suspend',   title:'Suspend Account',  desc:"This seller's account will be suspended immediately."},
    unsuspend:{icon:'redo',         cls:'success', label:'Reactivate', btnCls:'confirm-unsuspend', title:'Reactivate Account',desc:"This seller's account will be restored and they can resume selling."}
};
function openModal(action, sellerId, sellerName) {
    pendingAction = action; pendingSellerId = sellerId;
    var m = iconMap[action];
    document.getElementById('modalIcon').className       = 'modal-icon ' + m.cls;
    document.getElementById('modalIconI').className      = 'fas fa-' + m.icon;
    document.getElementById('modalTitle').textContent    = m.title;
    document.getElementById('modalDesc').innerHTML       = '<strong>' + sellerName + '</strong>: ' + m.desc;
    var btn = document.getElementById('modalConfirmBtn');
    btn.className   = 'modal-btn ' + m.btnCls;
    btn.textContent = m.label;
    document.getElementById('confirmModal').classList.add('open');
}
function closeModal() {
    document.getElementById('confirmModal').classList.remove('open');
    pendingAction=''; pendingSellerId='';
}
function submitAction() {
    if (pendingAction && pendingSellerId)
        window.location.href = 'viewRegisteredSellers.jsp?action=' + pendingAction + '&sellerId=' + pendingSellerId;
}
document.getElementById('confirmModal').addEventListener('click', function(e) { if(e.target===this) closeModal(); });

/* ── Detail Drawer ── */
function openDrawer(id,fname,email,phono,bname,btype,category,gst,pan,disc,
                    add1,add2,city,state,pin,accountno,ifsc,bankname,created,color,letter) {
    document.getElementById('drawerTitle').textContent = fname + ' — Details';
    var catColors = {fashion:'#6366f1',beauty:'#ea580c',electronics:'#0284c7',food:'#059669',health:'#d97706',other:'#64748b'};
    var catBg     = {fashion:'rgba(99,102,241,.1)',beauty:'rgba(249,115,22,.1)',electronics:'rgba(56,189,248,.1)',food:'rgba(16,185,129,.1)',health:'rgba(245,158,11,.1)',other:'rgba(148,163,184,.1)'};
    var cc  = catColors[category] || '#64748b';
    var ccb = catBg[category]     || 'rgba(148,163,184,.1)';
    var btypeMap = {individual:'Individual',pvt_ltd:'Pvt Ltd',ltd:'Ltd',llp:'LLP'};
    var btypeLabel = btypeMap[btype] || btype;
    var masked = accountno.length > 4 ? '●'.repeat(accountno.length-4) + accountno.slice(-4) : accountno;
    var discHtml = disc ? '<div class="desc-box">'+disc+'</div>' : '<p style="color:var(--txt-s);font-style:italic;font-size:13px;">No description provided.</p>';
    var add2Html = add2 ? '<br><span style="color:var(--txt-m);">'+add2+'</span>' : '';

    document.getElementById('drawerBody').innerHTML = `
        <div class="drawer-avatar-row">
            <div class="drawer-avatar" style="background:${color};">${letter}</div>
            <div class="drawer-avatar-info">
                <h4>${fname}</h4>
                <p><i class="fas fa-envelope" style="margin-right:5px;"></i>${email}</p>
                <p style="margin-top:4px;"><i class="fas fa-phone" style="margin-right:5px;"></i>${phono}</p>
            </div>
        </div>
        <div class="section-title"><i class="fas fa-building" style="margin-right:5px;"></i>Business Information</div>
        <div class="info-grid">
            <div class="info-item full"><label>Business Name</label><span style="font-size:16px;">${bname}</span></div>
            <div class="info-item">
                <label>Category</label>
                <span style="display:inline-block;padding:4px 11px;border-radius:20px;background:${ccb};color:${cc};font-weight:700;text-transform:capitalize;">${category}</span>
            </div>
            <div class="info-item">
                <label>Business Type</label>
                <span style="display:inline-block;padding:4px 10px;border-radius:8px;background:rgba(56,189,248,.1);color:#0284c7;font-weight:700;font-size:11px;text-transform:uppercase;">${btypeLabel}</span>
            </div>
        </div>
        <div class="section-title"><i class="fas fa-align-left" style="margin-right:5px;"></i>Description</div>
        ${discHtml}
        <div class="section-title"><i class="fas fa-map-marker-alt" style="margin-right:5px;"></i>Address</div>
        <div class="info-grid">
            <div class="info-item full"><label>Street Address</label><span>${add1}${add2Html}</span></div>
            <div class="info-item"><label>City</label><span>${city}</span></div>
            <div class="info-item"><label>State</label><span>${state}</span></div>
            <div class="info-item"><label>PIN Code</label><span style="font-family:'JetBrains Mono',monospace;">${pin}</span></div>
        </div>
        <div class="section-title"><i class="fas fa-file-invoice-dollar" style="margin-right:5px;"></i>Tax Details</div>
        <div class="info-grid">
            <div class="info-item"><label>GST Number</label><span style="font-family:'JetBrains Mono',monospace;">${gst}</span></div>
            <div class="info-item"><label>PAN Number</label><span style="font-family:'JetBrains Mono',monospace;">${pan}</span></div>
        </div>
        <div class="section-title"><i class="fas fa-university" style="margin-right:5px;"></i>Bank Details</div>
        <div class="bank-card">
            <div class="bank-card-label">Account Number</div>
            <div class="bank-card-acct">${masked}</div>
            <div class="bank-card-row">
                <div class="bank-card-field"><label>Bank</label><span>${bankname}</span></div>
                <div class="bank-card-field"><label>IFSC</label><span style="font-family:'JetBrains Mono',monospace;">${ifsc}</span></div>
            </div>
        </div>
        <div class="created-chip">
            <i class="fas fa-calendar-alt"></i> Registered on ${created} &nbsp;|&nbsp; ID: #${id}
        </div>
    `;
    document.getElementById('drawerOverlay').classList.add('open');
    setTimeout(function(){ document.getElementById('detailDrawer').classList.add('open'); }, 10);
}
function closeDrawer() {
    document.getElementById('detailDrawer').classList.remove('open');
    setTimeout(function(){ document.getElementById('drawerOverlay').classList.remove('open'); }, 350);
}

/* ── Auto-dismiss flash ── */
var flash = document.querySelector('.flash-msg');
if (flash) {
    setTimeout(function(){
        flash.style.transition='opacity .6s'; flash.style.opacity='0';
        setTimeout(function(){ if(flash.parentNode) flash.parentNode.removeChild(flash); },600);
    }, 5000);
}
</script>
</body>
</html>
