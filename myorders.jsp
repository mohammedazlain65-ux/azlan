<%-- 
    Document   : myorders
    Modified   : Added Return Request feature for delivered orders
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%
    HttpSession hs = request.getSession();
    String username      = null;
    String password      = null;
    String customerEmail = null;
    try {
        username      = hs.getAttribute("email").toString();
        password      = hs.getAttribute("password").toString();
        customerEmail = username;
        if (username == null || password == null || username.equals("") || password.equals("")) {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        }
    } catch (Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
    }

    /* ── Flash messages ── */
    String ratingMsg = null; boolean ratingOk = false;
    { Object fm = hs.getAttribute("ratingMsg"); Object fo = hs.getAttribute("ratingOk");
      if (fm != null) { ratingMsg = fm.toString(); ratingOk = (fo instanceof Boolean) ? (Boolean)fo : false;
        hs.removeAttribute("ratingMsg"); hs.removeAttribute("ratingOk"); } }

    String returnMsg = null; boolean returnOk = false;
    { Object fm = hs.getAttribute("returnMsg"); Object fo = hs.getAttribute("returnOk");
      if (fm != null) { returnMsg = fm.toString(); returnOk = (fo instanceof Boolean) ? (Boolean)fo : false;
        hs.removeAttribute("returnMsg"); hs.removeAttribute("returnOk"); } }

    /* ── DB ── */
    String dbURL = "jdbc:mysql://localhost:3306/multi_vendor";
    String dbUser = "root"; String dbPassword = "";
    Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
    int totalOrders=0,pendingOrders=0,shippedOrders=0,deliveredOrders=0;
    double totalSpent=0; String dbErrMsg=null;
    List<Map<String,String>> orderList = new ArrayList<Map<String,String>>();

    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);
        String sql =
            "SELECT order_id, full_name, phone, shipping_address, city, state, pincode, " +
            "order_notes, payment_method, subtotal, tax_amount, grand_total, " +
            "total_items, order_status, source, order_date " +
            "FROM orders WHERE customer_email=? ORDER BY order_date DESC";
        pstmt = conn.prepareStatement(sql);
        pstmt.setString(1, customerEmail);
        rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String,String> row = new HashMap<String,String>();
            row.put("order_id",         rs.getString("order_id"));
            row.put("full_name",        rs.getString("full_name"));
            row.put("phone",            rs.getString("phone"));
            row.put("shipping_address", rs.getString("shipping_address"));
            row.put("city",             rs.getString("city"));
            row.put("state",            rs.getString("state"));
            row.put("pincode",          rs.getString("pincode"));
            row.put("payment_method",   rs.getString("payment_method"));
            row.put("subtotal",         rs.getString("subtotal"));
            row.put("tax_amount",       rs.getString("tax_amount"));
            row.put("grand_total",      rs.getString("grand_total"));
            row.put("total_items",      rs.getString("total_items"));
            row.put("order_status",     rs.getString("order_status"));
            row.put("source",           rs.getString("source"));
            row.put("order_date",       rs.getString("order_date"));
            orderList.add(row);
            totalOrders++;
            double gt=0; try{gt=Double.parseDouble(rs.getString("grand_total"));}catch(Exception ig){}
            totalSpent+=gt;
            String st=rs.getString("order_status");
            if("Pending".equalsIgnoreCase(st)||"Processing".equalsIgnoreCase(st)) pendingOrders++;
            if("Shipped".equalsIgnoreCase(st))   shippedOrders++;
            if("Delivered".equalsIgnoreCase(st)) deliveredOrders++;
        }
    } catch(Exception dbEx){ dbErrMsg=dbEx.getMessage(); }
    finally { try{if(rs!=null)rs.close();}catch(Exception ig){} try{if(pstmt!=null)pstmt.close();}catch(Exception ig){} }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Orders - MarketHub</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary:   #6366f1; --secondary: #8b5cf6; --dark-bg: #1e293b;
            --light-bg:  #f8fafc; --success:   #10b981; --danger:  #ef4444;
            --warning:   #f59e0b; --star:       #f59e0b; --info:    #06b6d4;
            --txt:       #0f172a; --txt-m:      #64748b; --border:  #e2e8f0;
            --return:    #f97316;
        }
        *{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Outfit',sans-serif;background:linear-gradient(135deg,#f0f4ff,#e5edff);min-height:100vh;}

        /* TOP / MAIN HEADER */
        .top-header{background:var(--dark-bg);color:white;padding:12px 0;font-size:13px;}
        .main-header{background:white;padding:20px 0;box-shadow:0 4px 20px rgba(0,0,0,.08);position:sticky;top:0;z-index:999;}
        .logo{font-size:32px;font-weight:800;color:var(--txt);text-decoration:none;display:flex;align-items:center;gap:12px;}
        .logo i{background:linear-gradient(135deg,var(--primary),var(--secondary));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;}
        .header-actions{display:flex;gap:20px;align-items:center;}
        .header-action{color:var(--txt);text-decoration:none;display:flex;flex-direction:column;align-items:center;transition:all .3s;padding:10px 15px;border-radius:12px;}
        .header-action:hover{background:linear-gradient(135deg,rgba(99,102,241,.1),rgba(139,92,246,.1));transform:translateY(-2px);}
        .header-action i{font-size:24px;margin-bottom:3px;color:var(--primary);}
        .header-action span{font-size:12px;font-weight:600;color:var(--txt-m);}
        .profile-dropdown{position:relative;}
        .dropdown-menu-custom{display:none;position:absolute;top:100%;right:0;background:white;min-width:240px;box-shadow:0 10px 40px rgba(0,0,0,.15);border-radius:16px;margin-top:12px;z-index:1000;overflow:hidden;border:1px solid var(--border);}
        .profile-dropdown:hover .dropdown-menu-custom{display:block;}
        .dropdown-item-custom{display:flex;align-items:center;padding:14px 18px;color:var(--txt);text-decoration:none;border-bottom:1px solid var(--border);gap:12px;font-weight:600;font-size:14px;transition:all .3s;}
        .dropdown-item-custom:last-child{border-bottom:none;}
        .dropdown-item-custom:hover{background:rgba(99,102,241,.08);padding-left:23px;}
        .dropdown-item-custom i{font-size:18px;width:20px;color:var(--primary);}

        /* HERO */
        .page-hero{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;padding:45px 0;margin-bottom:40px;}
        .page-hero h1{font-size:38px;font-weight:800;margin-bottom:8px;}
        .page-hero p{font-size:16px;opacity:.85;}
        .breadcrumb-custom{display:flex;align-items:center;gap:8px;margin-top:16px;font-size:14px;font-weight:600;}
        .breadcrumb-custom a{color:rgba(255,255,255,.75);text-decoration:none;}
        .breadcrumb-custom a:hover{color:white;}

        /* STATS */
        .stat-card{background:white;border-radius:20px;padding:28px 24px;box-shadow:0 4px 20px rgba(0,0,0,.07);display:flex;align-items:center;gap:20px;transition:all .3s;border:2px solid transparent;height:100%;}
        .stat-card:hover{transform:translateY(-5px);box-shadow:0 12px 35px rgba(0,0,0,.12);border-color:var(--primary);}
        .stat-icon{width:60px;height:60px;border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:26px;flex-shrink:0;}
        .stat-icon.purple{background:linear-gradient(135deg,rgba(99,102,241,.15),rgba(139,92,246,.15));color:var(--primary);}
        .stat-icon.green{background:linear-gradient(135deg,rgba(16,185,129,.15),rgba(5,150,105,.15));color:var(--success);}
        .stat-icon.orange{background:linear-gradient(135deg,rgba(245,158,11,.15),rgba(217,119,6,.15));color:var(--warning);}
        .stat-icon.red{background:linear-gradient(135deg,rgba(239,68,68,.15),rgba(220,38,38,.15));color:var(--danger);}
        .stat-label{font-size:13px;font-weight:600;color:var(--txt-m);margin-bottom:4px;text-transform:uppercase;letter-spacing:.5px;}
        .stat-value{font-size:30px;font-weight:800;color:var(--txt);line-height:1;}

        /* FILTER */
        .filter-bar{background:white;border-radius:16px;padding:20px 25px;box-shadow:0 4px 20px rgba(0,0,0,.06);margin-bottom:25px;display:flex;align-items:center;gap:15px;flex-wrap:wrap;}
        .filter-bar label{font-weight:700;color:var(--txt);font-size:15px;white-space:nowrap;}
        .filter-btn{padding:9px 20px;border-radius:10px;border:2px solid var(--border);background:white;font-weight:700;font-size:14px;color:var(--txt-m);cursor:pointer;transition:all .3s;}
        .filter-btn:hover,.filter-btn.active{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;border-color:transparent;transform:translateY(-2px);box-shadow:0 5px 15px rgba(99,102,241,.35);}
        .search-orders{margin-left:auto;position:relative;}
        .search-orders input{padding:10px 42px 10px 16px;border:2px solid var(--border);border-radius:10px;font-size:14px;font-weight:500;width:250px;transition:all .3s;}
        .search-orders input:focus{outline:none;border-color:var(--primary);box-shadow:0 0 0 4px rgba(99,102,241,.1);}
        .search-orders i{position:absolute;right:14px;top:50%;transform:translateY(-50%);color:var(--txt-m);}

        /* ORDER CARDS */
        .order-card{background:white;border-radius:20px;box-shadow:0 4px 20px rgba(0,0,0,.07);margin-bottom:24px;overflow:hidden;border:2px solid var(--border);transition:all .35s;}
        .order-card:hover{box-shadow:0 12px 40px rgba(0,0,0,.12);border-color:var(--primary);transform:translateY(-3px);}
        .order-header{background:linear-gradient(135deg,rgba(99,102,241,.05),rgba(139,92,246,.05));padding:18px 28px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;border-bottom:2px solid var(--border);}
        .order-id{font-size:16px;font-weight:800;color:var(--txt);display:flex;align-items:center;gap:8px;}
        .order-id i{color:var(--primary);}
        .order-date{font-size:13px;font-weight:600;color:var(--txt-m);display:flex;align-items:center;gap:6px;}
        .order-source-badge{display:inline-flex;align-items:center;gap:5px;padding:5px 12px;border-radius:20px;font-size:12px;font-weight:700;}
        .source-cart{background:rgba(99,102,241,.12);color:var(--primary);}
        .source-buynow{background:rgba(16,185,129,.12);color:var(--success);}
        .status-badge{display:inline-flex;align-items:center;gap:6px;padding:6px 16px;border-radius:20px;font-size:13px;font-weight:700;}
        .status-pending{background:rgba(245,158,11,.15);color:#d97706;}
        .status-processing{background:rgba(6,182,212,.15);color:#0891b2;}
        .status-shipped{background:rgba(99,102,241,.15);color:var(--primary);}
        .status-delivered{background:rgba(16,185,129,.15);color:var(--success);}
        .status-cancelled{background:rgba(239,68,68,.15);color:var(--danger);}
        .order-body{padding:24px 28px;}
        .items-title{font-size:14px;font-weight:700;color:var(--txt-m);text-transform:uppercase;letter-spacing:.5px;margin-bottom:14px;display:flex;align-items:center;gap:8px;}
        .items-title i{color:var(--primary);}
        .order-item-row{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;border-radius:12px;background:var(--light-bg);margin-bottom:8px;flex-wrap:wrap;gap:6px;transition:background .2s;}
        .order-item-row:hover{background:rgba(99,102,241,.06);}
        .item-name{font-weight:700;color:var(--txt);font-size:15px;flex:1;}
        .item-qty{background:rgba(99,102,241,.1);color:var(--primary);padding:4px 10px;border-radius:8px;font-size:13px;font-weight:700;margin:0 14px;}
        .item-price{font-weight:800;color:var(--txt);font-size:15px;min-width:90px;text-align:right;}
        .more-items-chip{display:inline-flex;align-items:center;gap:5px;background:rgba(99,102,241,.08);color:var(--primary);padding:6px 14px;border-radius:20px;font-size:13px;font-weight:700;cursor:pointer;}
        .more-items-chip:hover{background:rgba(99,102,241,.15);}
        .order-footer{border-top:2px solid var(--border);padding:18px 28px;display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:20px;background:linear-gradient(135deg,rgba(99,102,241,.02),rgba(139,92,246,.02));}
        .address-block{flex:1;min-width:220px;}
        .address-block .label{font-size:12px;font-weight:700;color:var(--txt-m);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;display:flex;align-items:center;gap:6px;}
        .address-block .label i{color:var(--primary);}
        .address-block p{font-size:14px;font-weight:600;color:var(--txt);line-height:1.6;margin:0;}
        .totals-block{text-align:right;min-width:200px;}
        .total-line{display:flex;justify-content:space-between;gap:30px;font-size:14px;font-weight:600;color:var(--txt-m);margin-bottom:6px;}
        .total-line.grand{font-size:20px;font-weight:800;color:var(--primary);border-top:2px solid var(--border);padding-top:8px;margin-top:4px;}
        .total-line span:last-child{color:var(--txt);font-weight:700;}
        .total-line.grand span:last-child{color:var(--primary);}
        .payment-chip{display:inline-flex;align-items:center;gap:6px;background:rgba(16,185,129,.1);color:var(--success);padding:5px 12px;border-radius:8px;font-size:13px;font-weight:700;margin-top:10px;}

        /* ═══════════════════════════════════
           RETURN REQUEST SECTION
        ═══════════════════════════════════ */
        .return-section {
            border-top: 2px solid var(--border);
            padding: 22px 28px;
            background: linear-gradient(135deg, rgba(249,115,22,.04), rgba(251,146,60,.04));
        }
        .return-section-title {
            font-size: 14px; font-weight: 800; color: var(--txt);
            margin-bottom: 16px; display: flex; align-items: center; gap: 8px;
        }
        .return-section-title i { color: var(--return); }

        .return-item-card {
            background: white; border: 2px solid var(--border);
            border-radius: 14px; padding: 18px 20px; margin-bottom: 14px;
            transition: all .3s;
        }
        .return-item-card:hover { border-color: var(--return); box-shadow: 0 4px 20px rgba(249,115,22,.1); }
        .return-item-card.already-returned { border-color: var(--info); background: rgba(6,182,212,.02); }
        .return-item-card.return-approved  { border-color: var(--success); background: rgba(16,185,129,.02); }
        .return-item-card.return-rejected  { border-color: var(--danger);  background: rgba(239,68,68,.02); }

        .return-item-header {
            display: flex; align-items: center; justify-content: space-between;
            flex-wrap: wrap; gap:10px; margin-bottom: 14px;
        }
        .return-item-name { font-size: 15px; font-weight: 700; color: var(--txt); display: flex; align-items: center; gap: 8px; }
        .return-item-name i { color: var(--return); font-size: 13px; }

        /* Return status pill */
        .return-status-pill {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 700;
        }
        .pill-pending   { background: rgba(245,158,11,.15); color: #d97706; }
        .pill-approved  { background: rgba(16,185,129,.15); color: var(--success); }
        .pill-rejected  { background: rgba(239,68,68,.15);  color: var(--danger); }
        .pill-completed { background: rgba(6,182,212,.15);  color: var(--info); }

        /* Reason select */
        .return-reason-select {
            width: 100%; padding: 11px 14px;
            border: 2px solid var(--border); border-radius: 10px;
            font-family: 'Outfit', sans-serif; font-size: 14px; font-weight: 500;
            color: var(--txt); background: white; cursor: pointer;
            transition: all .3s; margin-bottom: 10px; appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' fill='%236366f1' viewBox='0 0 16 16'%3E%3Cpath d='M7.247 11.14L2.451 5.658C1.885 5.013 2.345 4 3.204 4h9.592a1 1 0 0 1 .753 1.659l-4.796 5.48a1 1 0 0 1-1.506 0z'/%3E%3C/svg%3E");
            background-repeat: no-repeat; background-position: right 14px center;
        }
        .return-reason-select:focus { outline: none; border-color: var(--return); box-shadow: 0 0 0 4px rgba(249,115,22,.12); }

        .return-textarea {
            width: 100%; border: 2px solid var(--border); border-radius: 10px;
            padding: 10px 14px; font-family: 'Outfit', sans-serif; font-size: 14px;
            font-weight: 500; resize: vertical; min-height: 70px;
            transition: all .3s; margin-bottom: 12px; color: var(--txt);
        }
        .return-textarea:focus { outline: none; border-color: var(--return); box-shadow: 0 0 0 4px rgba(249,115,22,.12); }
        .return-textarea::placeholder { color: #94a3b8; }

        .btn-return {
            background: linear-gradient(135deg, var(--return), #ea580c);
            color: white; border: none; padding: 10px 24px; border-radius: 10px;
            font-size: 14px; font-weight: 800; cursor: pointer; transition: all .3s;
            font-family: 'Outfit', sans-serif; display: inline-flex; align-items: center; gap: 7px;
        }
        .btn-return:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(249,115,22,.4); }

        /* Existing return info block */
        .return-info-block { display: flex; align-items: flex-start; gap: 14px; }
        .return-info-block .ri-icon { font-size: 28px; }
        .return-info-title { font-size: 14px; font-weight: 700; color: var(--txt); margin-bottom:4px; }
        .return-info-detail { font-size:13px; font-weight:500; color:var(--txt-m); line-height:1.6; }
        .return-info-reason { font-size: 13px; font-weight: 600; color: var(--txt); margin-top: 6px;
            background: var(--light-bg); padding: 8px 12px; border-radius:8px; border-left: 3px solid var(--return); }

        /* Window warning */
        .return-window-warn {
            background: rgba(239,68,68,.08); border: 1.5px solid rgba(239,68,68,.25);
            border-radius: 10px; padding: 10px 14px; font-size:13px; font-weight:600;
            color: var(--danger); display: flex; align-items: center; gap: 8px;
        }
        .return-window-ok {
            background: rgba(16,185,129,.08); border: 1.5px solid rgba(16,185,129,.25);
            border-radius: 10px; padding: 10px 14px; font-size:13px; font-weight:600;
            color: var(--success); display: flex; align-items: center; gap: 8px; margin-bottom:12px;
        }
        .return-policy-note {
            font-size: 12px; font-weight: 600; color: var(--txt-m);
            margin-top: 8px; display: flex; align-items: center; gap: 6px;
        }

        /* RATING SECTION (unchanged) */
        .rate-section{border-top:2px solid var(--border);padding:20px 28px;background:linear-gradient(135deg,rgba(245,158,11,.04),rgba(251,191,36,.04));}
        .rate-section-title{font-size:14px;font-weight:800;color:var(--txt);margin-bottom:14px;display:flex;align-items:center;gap:8px;}
        .rate-section-title i{color:var(--star);}
        .rate-item-card{background:white;border:2px solid var(--border);border-radius:14px;padding:16px 20px;margin-bottom:12px;transition:all .3s;}
        .rate-item-card:hover{border-color:var(--star);box-shadow:0 4px 20px rgba(245,158,11,.12);}
        .rate-item-card.already-rated{border-color:var(--success);background:rgba(16,185,129,.02);}
        .rate-item-name{font-size:14px;font-weight:700;color:var(--txt);margin-bottom:10px;display:flex;align-items:center;gap:8px;}
        .star-row{display:flex;align-items:center;gap:6px;margin-bottom:10px;flex-wrap:wrap;}
        .star-label{font-size:13px;font-weight:600;color:var(--txt-m);margin-right:4px;}
        .stars-input{display:flex;flex-direction:row-reverse;gap:4px;}
        .stars-input input[type="radio"]{display:none;}
        .stars-input label{font-size:26px;color:#d1d5db;cursor:pointer;transition:color .15s,transform .15s;}
        .stars-input label:hover,.stars-input label:hover~label,.stars-input input:checked~label{color:var(--star);}
        .stars-input label:hover{transform:scale(1.25);}
        .rate-textarea{width:100%;border:2px solid var(--border);border-radius:10px;padding:10px 14px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;resize:vertical;min-height:70px;transition:all .3s;margin-bottom:10px;color:var(--txt);}
        .rate-textarea:focus{outline:none;border-color:var(--star);box-shadow:0 0 0 4px rgba(245,158,11,.12);}
        .btn-submit-rating{background:linear-gradient(135deg,var(--star),#f97316);color:white;border:none;padding:10px 24px;border-radius:10px;font-size:14px;font-weight:800;cursor:pointer;transition:all .3s;font-family:'Outfit',sans-serif;display:inline-flex;align-items:center;gap:7px;}
        .btn-submit-rating:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(245,158,11,.4);}
        .existing-rating{display:flex;align-items:flex-start;gap:14px;}
        .exist-stars{color:var(--star);font-size:20px;letter-spacing:2px;}
        .exist-comment{font-size:13px;color:var(--txt-m);font-weight:500;font-style:italic;margin-top:4px;}
        .exist-badge{background:rgba(16,185,129,.12);color:var(--success);padding:4px 10px;border-radius:8px;font-size:12px;font-weight:700;white-space:nowrap;}

        /* TOAST */
        .toast-overlay{position:fixed;top:30px;right:30px;z-index:99999;animation:slideToast .4s ease;}
        @keyframes slideToast{from{opacity:0;transform:translateX(60px)}to{opacity:1;transform:translateX(0)}}
        .toast-box{background:white;border-radius:16px;padding:18px 24px;box-shadow:0 10px 40px rgba(0,0,0,.18);display:flex;align-items:center;gap:14px;min-width:320px;border-left:5px solid var(--success);}
        .toast-box.error{border-left-color:var(--danger);}
        .toast-box.warn{border-left-color:var(--return);}
        .toast-box .t-title{font-weight:800;font-size:15px;color:var(--txt);}
        .toast-box .t-sub{font-size:13px;font-weight:500;color:var(--txt-m);margin-top:2px;}

        /* EMPTY + ALERT + FOOTER */
        .empty-state{background:white;border-radius:24px;padding:80px 40px;text-align:center;box-shadow:0 4px 20px rgba(0,0,0,.07);}
        .empty-icon{width:110px;height:110px;background:linear-gradient(135deg,rgba(99,102,241,.1),rgba(139,92,246,.1));border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 25px;}
        .empty-icon i{font-size:50px;color:var(--primary);}
        .empty-state h3{font-size:28px;font-weight:800;color:var(--txt);margin-bottom:10px;}
        .empty-state p{font-size:16px;color:var(--txt-m);font-weight:500;margin-bottom:30px;}
        .btn-shop-now{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;border:none;padding:15px 40px;border-radius:14px;font-size:16px;font-weight:800;text-decoration:none;display:inline-block;transition:all .3s;}
        .btn-shop-now:hover{transform:translateY(-3px);box-shadow:0 10px 30px rgba(99,102,241,.4);color:white;}
        .alert-custom{border-radius:16px;padding:20px 25px;margin-bottom:25px;border:none;box-shadow:0 4px 15px rgba(0,0,0,.08);display:flex;align-items:center;gap:15px;font-weight:600;}
        .alert-custom.error{background:linear-gradient(135deg,rgba(239,68,68,.15),rgba(220,38,38,.15));color:#dc2626;border-left:4px solid var(--danger);}
        .footer{background:var(--dark-bg);color:white;padding:40px 0 30px;margin-top:60px;}
        .footer-bottom{border-top:1px solid rgba(255,255,255,.1);margin-top:30px;padding-top:25px;text-align:center;color:rgba(255,255,255,.6);}

        /* RETURN MODAL */
        .modal-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(15,23,42,.55); z-index: 10000;
            align-items: center; justify-content: center; padding: 20px;
            backdrop-filter: blur(4px);
        }
        .modal-overlay.open { display: flex; animation: fadeIn .25s ease; }
        @keyframes fadeIn { from{opacity:0}to{opacity:1} }
        .modal-box {
            background: white; border-radius: 24px; max-width: 520px; width: 100%;
            box-shadow: 0 20px 60px rgba(0,0,0,.25); overflow: hidden;
            animation: slideUp .3s ease;
        }
        @keyframes slideUp { from{transform:translateY(30px);opacity:0}to{transform:translateY(0);opacity:1} }
        .modal-header-custom {
            background: linear-gradient(135deg,var(--return),#ea580c);
            padding: 22px 28px; display: flex; align-items: center; justify-content: space-between;
        }
        .modal-header-custom h5 { font-size: 18px; font-weight: 800; color: white; margin: 0; display: flex; align-items: center; gap: 10px; }
        .modal-close { background: rgba(255,255,255,.2); border: none; color: white; width: 34px; height: 34px; border-radius: 50%; cursor: pointer; font-size: 16px; display: flex; align-items: center; justify-content: center; transition: all .2s; }
        .modal-close:hover { background: rgba(255,255,255,.35); transform: rotate(90deg); }
        .modal-body-custom { padding: 28px; }
        .modal-product-tag { background: rgba(249,115,22,.08); border: 1.5px solid rgba(249,115,22,.2); border-radius: 10px; padding: 10px 14px; font-size: 14px; font-weight: 700; color: var(--txt); display: flex; align-items: center; gap: 8px; margin-bottom: 20px; }
        .modal-product-tag i { color: var(--return); }
        .form-label-custom { font-size: 13px; font-weight: 700; color: var(--txt); margin-bottom: 6px; display: block; text-transform: uppercase; letter-spacing: .4px; }
        .modal-footer-custom { padding: 16px 28px; border-top: 1.5px solid var(--border); display: flex; gap: 12px; justify-content: flex-end; }
        .btn-cancel-modal { background: var(--light-bg); border: 2px solid var(--border); color: var(--txt-m); padding: 10px 22px; border-radius: 10px; font-weight: 700; font-size: 14px; cursor: pointer; font-family: 'Outfit', sans-serif; transition: all .2s; }
        .btn-cancel-modal:hover { border-color: var(--txt-m); color: var(--txt); }

        @media(max-width:768px){
            .order-header,.order-footer{flex-direction:column;}
            .totals-block{text-align:left;width:100%;}
            .filter-bar{gap:10px;}
            .search-orders input,.search-orders{width:100%;margin-left:0;}
            .modal-box { border-radius: 16px; }
        }
    </style>
</head>
<body>

<%-- ══ Rating Toast ══ --%>
<% if (ratingMsg != null) { %>
<div class="toast-overlay" id="ratingToast">
    <div class="toast-box <%= ratingOk ? "" : "error" %>">
        <% if (ratingOk) { %><i class="fas fa-check-circle" style="color:var(--success);font-size:28px;"></i>
        <% } else { %><i class="fas fa-times-circle" style="color:var(--danger);font-size:28px;"></i><% } %>
        <div><div class="t-title"><%= ratingOk ? "Review Submitted!" : "Submission Failed" %></div><div class="t-sub"><%= ratingMsg %></div></div>
    </div>
</div>
<script>setTimeout(function(){var t=document.getElementById('ratingToast');if(t){t.style.transition='all .4s';t.style.opacity='0';t.style.transform='translateX(60px)';setTimeout(function(){t.remove();},400);}},3500);</script>
<% } %>

<%-- ══ Return Toast ══ --%>
<% if (returnMsg != null) { %>
<div class="toast-overlay" id="returnToast" style="top:100px;">
    <div class="toast-box <%= returnOk ? "warn" : "error" %>">
        <% if (returnOk) { %><i class="fas fa-undo-alt" style="color:var(--return);font-size:28px;"></i>
        <% } else { %><i class="fas fa-times-circle" style="color:var(--danger);font-size:28px;"></i><% } %>
        <div><div class="t-title"><%= returnOk ? "Return Requested!" : "Return Failed" %></div><div class="t-sub"><%= returnMsg %></div></div>
    </div>
</div>
<script>setTimeout(function(){var t=document.getElementById('returnToast');if(t){t.style.transition='all .4s';t.style.opacity='0';t.style.transform='translateX(60px)';setTimeout(function(){t.remove();},400);}},4000);</script>
<% } %>

<!-- ══ RETURN MODAL ══ -->
<div class="modal-overlay" id="returnModal">
    <div class="modal-box">
        <div class="modal-header-custom">
            <h5><i class="fas fa-undo-alt"></i> Request Return</h5>
            <button class="modal-close" onclick="closeReturnModal()"><i class="fas fa-times"></i></button>
        </div>
        <form method="POST" action="ReturnServlet" id="returnForm">
            <input type="hidden" name="action"       value="submit">
            <input type="hidden" name="redirect"     value="myorders.jsp">
            <input type="hidden" name="r_order_id"   id="modal_order_id">
            <input type="hidden" name="r_product_id" id="modal_product_id">
            <input type="hidden" name="r_seller_email" id="modal_seller_email">
            <div class="modal-body-custom">
                <div class="modal-product-tag">
                    <i class="fas fa-box"></i>
                    <span id="modal_product_name">Product Name</span>
                </div>
                <label class="form-label-custom"><i class="fas fa-list-ul"></i> Reason for Return *</label>
                <select name="r_reason" class="return-reason-select" required style="margin-bottom:16px;">
                    <option value="">— Select a reason —</option>
                    <option value="Damaged or defective product">Damaged or defective product</option>
                    <option value="Wrong item delivered">Wrong item delivered</option>
                    <option value="Product not as described">Product not as described</option>
                    <option value="Changed my mind">Changed my mind</option>
                    <option value="Size or fit issue">Size or fit issue</option>
                    <option value="Missing parts or accessories">Missing parts or accessories</option>
                    <option value="Poor quality">Poor quality</option>
                    <option value="Other">Other</option>
                </select>
                <label class="form-label-custom"><i class="fas fa-comment-alt"></i> Additional Details</label>
                <textarea name="r_description" class="return-textarea"
                    placeholder="Please describe the issue in more detail... (optional)"></textarea>
                <div class="return-policy-note">
                    <i class="fas fa-info-circle" style="color:var(--return);"></i>
                    Returns are subject to seller approval. You'll be notified once reviewed.
                </div>
            </div>
            <div class="modal-footer-custom">
                <button type="button" class="btn-cancel-modal" onclick="closeReturnModal()">Cancel</button>
                <button type="submit" class="btn-return"><i class="fas fa-paper-plane"></i> Submit Return</button>
            </div>
        </form>
    </div>
</div>

<!-- TOP HEADER -->
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

<!-- MAIN HEADER -->
<header class="main-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-lg-3 col-md-12 mb-3 mb-lg-0">
                <a href="buyerdashboard.jsp" class="logo"><i class="fas fa-shopping-bag"></i><span>MarketHub</span></a>
            </div>
            <div class="col-lg-5 col-md-12 mb-3 mb-lg-0">
                <div style="font-size:16px;font-weight:700;color:var(--txt-m);">
                    <i class="fas fa-box-open" style="color:var(--primary);"></i>&nbsp; My Orders &mdash; Order History
                </div>
            </div>
            <div class="col-lg-4 col-md-12">
                <div class="header-actions">
                    <a href="buyerdashboard.jsp" class="header-action"><i class="fas fa-store"></i><span>Shop</span></a>
                    <a href="cart.jsp" class="header-action"><i class="fas fa-shopping-cart"></i><span>Cart</span></a>
                    <div class="profile-dropdown">
                        <a href="#" class="header-action"><i class="fas fa-user-circle"></i><span>Account</span></a>
                        <div class="dropdown-menu-custom">
                            <a href="#"            class="dropdown-item-custom"><i class="fas fa-user"></i> My Profile</a>
                            <a href="myorders.jsp" class="dropdown-item-custom"><i class="fas fa-box"></i> My Orders</a>
                            <a href="Wishlist.jsp" class="dropdown-item-custom"><i class="fas fa-heart"></i> My Wishlist</a>
                            <a href="#"            class="dropdown-item-custom"><i class="fas fa-cog"></i> Settings</a>
                            <a href="ulogout"      class="dropdown-item-custom"><i class="fas fa-sign-out-alt"></i> Logout</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- HERO -->
<div class="page-hero">
    <div class="container">
        <h1><i class="fas fa-box-open"></i> My Orders</h1>
        <p>Track, manage, review, and return your orders all in one place.</p>
        <div class="breadcrumb-custom">
            <a href="buyerdashboard.jsp"><i class="fas fa-home"></i> Home</a>
            <i class="fas fa-chevron-right" style="font-size:10px;opacity:.6;"></i>
            <span>My Orders</span>
        </div>
    </div>
</div>

<!-- MAIN CONTENT -->
<div class="container pb-5">

    <% if (dbErrMsg != null) { %>
    <div class="alert-custom error">
        <i class="fas fa-times-circle"></i>
        <span><strong>Database Error:</strong> <%= dbErrMsg %></span>
    </div>
    <% } %>

    <!-- STATS -->
    <div class="row g-4 mb-4">
        <div class="col-lg-3 col-md-6"><div class="stat-card">
            <div class="stat-icon purple"><i class="fas fa-shopping-bag"></i></div>
            <div><div class="stat-label">Total Orders</div><div class="stat-value"><%= totalOrders %></div></div>
        </div></div>
        <div class="col-lg-3 col-md-6"><div class="stat-card">
            <div class="stat-icon orange"><i class="fas fa-clock"></i></div>
            <div><div class="stat-label">Pending / Processing</div><div class="stat-value"><%= pendingOrders %></div></div>
        </div></div>
        <div class="col-lg-3 col-md-6"><div class="stat-card">
            <div class="stat-icon green"><i class="fas fa-check-circle"></i></div>
            <div><div class="stat-label">Delivered</div><div class="stat-value"><%= deliveredOrders %></div></div>
        </div></div>
        <div class="col-lg-3 col-md-6"><div class="stat-card">
            <div class="stat-icon red"><i class="fas fa-rupee-sign"></i></div>
            <div><div class="stat-label">Total Spent</div><div class="stat-value" style="font-size:22px;">&#8377;<%= String.format("%.0f",totalSpent) %></div></div>
        </div></div>
    </div>

    <!-- FILTER -->
    <div class="filter-bar">
        <label><i class="fas fa-filter" style="color:var(--primary);"></i> Filter:</label>
        <button class="filter-btn active" onclick="filterOrders('all',this)">All Orders</button>
        <button class="filter-btn" onclick="filterOrders('pending',this)">Pending</button>
        <button class="filter-btn" onclick="filterOrders('processing',this)">Processing</button>
        <button class="filter-btn" onclick="filterOrders('shipped',this)">Shipped</button>
        <button class="filter-btn" onclick="filterOrders('delivered',this)">Delivered</button>
        <button class="filter-btn" onclick="filterOrders('cancelled',this)">Cancelled</button>
        <div class="search-orders">
            <input type="text" id="orderSearch" placeholder="Search by Order ID..." oninput="searchOrders(this.value)">
            <i class="fas fa-search"></i>
        </div>
    </div>

    <!-- ORDERS LIST -->
    <div id="ordersContainer">
    <%
    if (orderList.isEmpty()) { %>
        <div class="empty-state">
            <div class="empty-icon"><i class="fas fa-box-open"></i></div>
            <h3>No Orders Yet</h3>
            <p>You haven't placed any orders yet. Start shopping to see them here!</p>
            <a href="buyerdashboard.jsp" class="btn-shop-now"><i class="fas fa-shopping-bag"></i> Start Shopping</a>
        </div>
    <%
    } else {
        for (Map<String,String> order : orderList) {
            String orderId      = order.get("order_id")        != null ? order.get("order_id")        : "-";
            String fullName     = order.get("full_name")        != null ? order.get("full_name")        : "-";
            String phone        = order.get("phone")            != null ? order.get("phone")            : "-";
            String shippingAddr = order.get("shipping_address") != null ? order.get("shipping_address") : "-";
            String orderStatus  = order.get("order_status")     != null ? order.get("order_status")     : "Pending";
            String source       = order.get("source")           != null ? order.get("source")           : "checkout";
            String orderDate    = order.get("order_date")       != null ? order.get("order_date")       : "-";
            String payMethod    = order.get("payment_method")   != null ? order.get("payment_method")   : "cod";
            String grandTotal   = order.get("grand_total")      != null ? order.get("grand_total")      : "0.00";
            String subtotal     = order.get("subtotal")         != null ? order.get("subtotal")         : "0.00";
            String taxAmount    = order.get("tax_amount")       != null ? order.get("tax_amount")       : "0.00";

            String payLabel = "Cash on Delivery"; String payIcon = "money-bill-wave";
            if ("card".equals(payMethod)) { payLabel = "Credit / Debit Card"; payIcon = "credit-card"; }
            else if ("upi".equals(payMethod)) { payLabel = "UPI Payment"; payIcon = "mobile-alt"; }

            String statusClass = "status-pending"; String statusIcon = "clock";
            if ("Processing".equalsIgnoreCase(orderStatus)) { statusClass="status-processing"; statusIcon="cog"; }
            if ("Shipped".equalsIgnoreCase(orderStatus))    { statusClass="status-shipped";    statusIcon="truck"; }
            if ("Delivered".equalsIgnoreCase(orderStatus))  { statusClass="status-delivered";  statusIcon="check-circle"; }
            if ("Cancelled".equalsIgnoreCase(orderStatus))  { statusClass="status-cancelled";  statusIcon="times-circle"; }

            String sourceLabel = "buynow".equals(source) ? "Buy Now" : "Cart";
            String sourceCss   = "buynow".equals(source) ? "source-buynow" : "source-cart";
            String sourceIcon  = "buynow".equals(source) ? "bolt" : "shopping-cart";
            String safeStatus  = orderStatus.toLowerCase().replace(" ","");
            boolean isDelivered = "Delivered".equalsIgnoreCase(orderStatus);
    %>
        <div class="order-card" data-status="<%= safeStatus %>" data-orderid="<%= orderId.toLowerCase() %>">

            <!-- Header -->
            <div class="order-header">
                <div class="d-flex align-items-center gap-3 flex-wrap">
                    <div class="order-id"><i class="fas fa-hashtag"></i> <%= orderId %></div>
                    <span class="order-source-badge <%= sourceCss %>"><i class="fas fa-<%= sourceIcon %>"></i> <%= sourceLabel %></span>
                </div>
                <div class="d-flex align-items-center gap-3 flex-wrap">
                    <div class="order-date"><i class="fas fa-calendar-alt"></i> <%= orderDate %></div>
                    <span class="status-badge <%= statusClass %>"><i class="fas fa-<%= statusIcon %>"></i> <%= orderStatus %></span>
                </div>
            </div>

            <!-- Body -->
            <div class="order-body">
                <div class="items-title"><i class="fas fa-box"></i> Order Items</div>
<%
                /* ── Fetch items + ratings + return status ── */
                List<Map<String,String>> itemList = new ArrayList<Map<String,String>>();
                try {
                    String itemSql =
                        "SELECT oi.product_id, oi.product_name, oi.quantity, oi.unit_price, oi.item_total, " +
                        "ap.seller_email, " +
                        "pr.rating, pr.review_comment, " +
                        "rr.return_id, rr.return_status, rr.return_reason, rr.return_description, rr.created_at AS return_date " +
                        "FROM order_items oi " +
                        "LEFT JOIN adprod ap ON oi.product_id = ap.id " +
                        "LEFT JOIN product_ratings pr ON pr.order_id=oi.order_id AND pr.product_id=oi.product_id AND pr.customer_email=? " +
                        "LEFT JOIN return_requests rr ON rr.order_id=oi.order_id AND rr.product_id=oi.product_id AND rr.customer_email=? " +
                        "WHERE oi.order_id=? ORDER BY oi.id ASC";
                    PreparedStatement psi = conn.prepareStatement(itemSql);
                    psi.setString(1, customerEmail);
                    psi.setString(2, customerEmail);
                    psi.setString(3, orderId);
                    ResultSet rsi = psi.executeQuery();
                    while (rsi.next()) {
                        Map<String,String> item = new HashMap<String,String>();
                        item.put("product_id",         String.valueOf(rsi.getInt("product_id")));
                        item.put("product_name",       rsi.getString("product_name"));
                        item.put("quantity",           String.valueOf(rsi.getInt("quantity")));
                        item.put("unit_price",         String.valueOf(rsi.getDouble("unit_price")));
                        item.put("item_total",         String.valueOf(rsi.getDouble("item_total")));
                        item.put("seller_email",       rsi.getString("seller_email") != null ? rsi.getString("seller_email") : "");
                        item.put("rating",             rsi.getString("rating")         != null ? rsi.getString("rating")         : "0");
                        item.put("review_comment",     rsi.getString("review_comment") != null ? rsi.getString("review_comment") : "");
                        item.put("return_id",          rsi.getString("return_id")      != null ? rsi.getString("return_id")      : "");
                        item.put("return_status",      rsi.getString("return_status")  != null ? rsi.getString("return_status")  : "");
                        item.put("return_reason",      rsi.getString("return_reason")  != null ? rsi.getString("return_reason")  : "");
                        item.put("return_description", rsi.getString("return_description") != null ? rsi.getString("return_description") : "");
                        item.put("return_date",        rsi.getString("return_date")    != null ? rsi.getString("return_date")    : "");
                        itemList.add(item);
                    }
                    rsi.close(); psi.close();
                } catch(Exception eItem) {
                    /* fallback without JOIN */
                    try {
                        PreparedStatement psi2 = conn.prepareStatement(
                            "SELECT product_id, product_name, quantity, unit_price, item_total FROM order_items WHERE order_id=? ORDER BY id ASC");
                        psi2.setString(1, orderId);
                        ResultSet rsi2 = psi2.executeQuery();
                        while (rsi2.next()) {
                            Map<String,String> item = new HashMap<String,String>();
                            item.put("product_id",    String.valueOf(rsi2.getInt("product_id")));
                            item.put("product_name",  rsi2.getString("product_name"));
                            item.put("quantity",      String.valueOf(rsi2.getInt("quantity")));
                            item.put("unit_price",    String.valueOf(rsi2.getDouble("unit_price")));
                            item.put("item_total",    String.valueOf(rsi2.getDouble("item_total")));
                            item.put("seller_email",""); item.put("rating","0"); item.put("review_comment","");
                            item.put("return_id",""); item.put("return_status",""); item.put("return_reason","");
                            item.put("return_description",""); item.put("return_date","");
                            itemList.add(item);
                        }
                        rsi2.close(); psi2.close();
                    } catch(Exception ig2){}
                }

                int itemCount=itemList.size(); int displayed=0;
                for (Map<String,String> item : itemList) {
                    displayed++;
                    String hiddenClass = displayed>2 ? "extra-item-"+orderId.replace("-","")+" d-none" : "";
%>
                <div class="order-item-row <%= hiddenClass %>">
                    <span class="item-name"><i class="fas fa-tag" style="color:var(--primary);font-size:12px;"></i>&nbsp;<%= item.get("product_name") %></span>
                    <span class="item-qty">x<%= item.get("quantity") %></span>
                    <span class="item-price">&#8377;<%= String.format("%.2f", Double.parseDouble(item.get("item_total"))) %></span>
                </div>
<%              } /* end item display loop */
                if (itemCount > 2) {
                    int extra = itemCount - 2; String safeOid = orderId.replace("-",""); %>
                <div id="moreChip_<%= safeOid %>" class="mt-2">
                    <span class="more-items-chip" onclick="toggleExtraItems('<%= safeOid %>')">
                        <i class="fas fa-plus-circle"></i> +<%= extra %> more item<%= extra>1?"s":"" %>
                    </span>
                </div>
<%              } %>
            </div><!-- /order-body -->

            <!-- Footer -->
            <div class="order-footer">
                <div class="address-block">
                    <div class="label"><i class="fas fa-map-marker-alt"></i> Shipped To</div>
                    <p>
                        <strong><%= fullName %></strong><br>
                        <%= shippingAddr %><br>
                        <i class="fas fa-phone" style="color:var(--txt-m);font-size:12px;"></i>&nbsp;<%= phone %>
                    </p>
                </div>
                <div class="totals-block">
                    <div class="total-line"><span><i class="fas fa-list"></i> Subtotal</span><span>&#8377;<%= String.format("%.2f",Double.parseDouble(subtotal)) %></span></div>
                    <div class="total-line"><span><i class="fas fa-percent"></i> Tax (18%)</span><span>&#8377;<%= String.format("%.2f",Double.parseDouble(taxAmount)) %></span></div>
                    <div class="total-line"><span><i class="fas fa-truck"></i> Shipping</span><span style="color:var(--success);font-weight:800;">FREE</span></div>
                    <div class="total-line grand"><span>Grand Total</span><span>&#8377;<%= String.format("%.2f",Double.parseDouble(grandTotal)) %></span></div>
                    <div class="payment-chip"><i class="fas fa-<%= payIcon %>"></i> <%= payLabel %></div>
                </div>
            </div>

            <%-- ════════════════════════════════════════
                 RETURN REQUEST SECTION (Delivered only)
            ════════════════════════════════════════ --%>
            <% if (isDelivered && !itemList.isEmpty()) { %>
            <div class="return-section">
                <div class="return-section-title">
                    <i class="fas fa-undo-alt"></i> Return Items
                    <span style="font-size:12px;font-weight:600;color:var(--txt-m);margin-left:6px;">
                        &mdash; Select the item you want to return to the seller
                    </span>
                </div>

                <% for (Map<String,String> item : itemList) {
                       String retId     = item.get("return_id");
                       String retStatus = item.get("return_status");
                       String retReason = item.get("return_reason");
                       String retDesc   = item.get("return_description");
                       String retDate   = item.get("return_date");
                       String sellerEm  = item.get("seller_email");
                       boolean hasReturn = retId != null && !retId.isEmpty();

                       String cardCss = "";
                       if (hasReturn) {
                           if ("Approved".equalsIgnoreCase(retStatus))  cardCss = "return-approved";
                           else if ("Rejected".equalsIgnoreCase(retStatus)) cardCss = "return-rejected";
                           else if ("Completed".equalsIgnoreCase(retStatus)) cardCss = "return-completed";
                           else cardCss = "already-returned";
                       }
                %>
                <div class="return-item-card <%= cardCss %>">
                    <div class="return-item-header">
                        <div class="return-item-name">
                            <i class="fas fa-box"></i>
                            <%= item.get("product_name") %>
                        </div>
                        <% if (hasReturn) {
                               String pillCss = "pill-pending"; String pillIcon = "clock"; String pillLabel = "Return Pending";
                               if ("Approved".equalsIgnoreCase(retStatus))  { pillCss="pill-approved";  pillIcon="check-circle"; pillLabel="Return Approved"; }
                               if ("Rejected".equalsIgnoreCase(retStatus))  { pillCss="pill-rejected";  pillIcon="times-circle"; pillLabel="Return Rejected"; }
                               if ("Completed".equalsIgnoreCase(retStatus)) { pillCss="pill-completed"; pillIcon="check-double"; pillLabel="Return Completed"; }
                        %>
                        <span class="return-status-pill <%= pillCss %>">
                            <i class="fas fa-<%= pillIcon %>"></i> <%= pillLabel %>
                        </span>
                        <% } %>
                    </div>

                    <% if (hasReturn) { %>
                    <!-- Show existing return info -->
                    <div class="return-info-block">
                        <div>
                            <div class="return-info-title">Return Request #<%= retId %></div>
                            <div class="return-info-detail">
                                <i class="fas fa-calendar-alt" style="color:var(--return);"></i> Requested on <%= retDate %>
                                <% if (sellerEm != null && !sellerEm.isEmpty()) { %>
                                &nbsp;&nbsp;<i class="fas fa-store" style="color:var(--primary);"></i> Seller: <strong><%= sellerEm %></strong>
                                <% } %>
                            </div>
                            <% if (retReason != null && !retReason.isEmpty()) { %>
                            <div class="return-info-reason">
                                <i class="fas fa-tag" style="color:var(--return);font-size:12px;"></i>
                                <strong>Reason:</strong> <%= retReason %>
                                <% if (retDesc != null && !retDesc.isEmpty()) { %>
                                <br><span style="color:var(--txt-m);">&ldquo;<%= retDesc %>&rdquo;</span>
                                <% } %>
                            </div>
                            <% } %>
                            <!-- Show seller messages based on status -->
                            <% if ("Approved".equalsIgnoreCase(retStatus)) { %>
                            <div class="return-window-ok mt-2">
                                <i class="fas fa-check-circle"></i>
                                Your return has been approved! Please ship the item back to the seller.
                            </div>
                            <% } else if ("Rejected".equalsIgnoreCase(retStatus)) { %>
                            <div class="return-window-warn mt-2">
                                <i class="fas fa-exclamation-triangle"></i>
                                Your return request was rejected by the seller. Contact support for help.
                            </div>
                            <% } else if ("Completed".equalsIgnoreCase(retStatus)) { %>
                            <div class="return-window-ok mt-2">
                                <i class="fas fa-check-double"></i>
                                Return completed! Refund will be processed within 5–7 business days.
                            </div>
                            <% } else { %>
                            <div style="margin-top:8px;" class="return-policy-note">
                                <i class="fas fa-hourglass-half" style="color:var(--warning);"></i>
                                Awaiting seller review. We'll notify you once processed.
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <% } else { %>
                    <!-- Show return request button -->
                    <div class="return-window-ok">
                        <i class="fas fa-shield-alt"></i>
                        This item is eligible for return. Contact the seller if you have any issues.
                    </div>
                    <button class="btn-return" type="button"
                        onclick="openReturnModal(
                            '<%= orderId %>',
                            '<%= item.get("product_id") %>',
                            '<%= item.get("product_name").replace("'","\\x27") %>',
                            '<%= sellerEm.replace("'","\\x27") %>'
                        )">
                        <i class="fas fa-undo-alt"></i> Request Return
                    </button>
                    <div class="return-policy-note">
                        <i class="fas fa-info-circle" style="color:var(--return);"></i>
                        Returns are reviewed by the seller within 2–3 business days.
                    </div>
                    <% } %>
                </div>
                <% } /* end return item loop */ %>
            </div>
            <% } /* end isDelivered */ %>

            <%-- RATE SECTION --%>
            <% if (isDelivered && !itemList.isEmpty()) { %>
            <div class="rate-section">
                <div class="rate-section-title"><i class="fas fa-star"></i> Rate Your Order
                    <span style="font-size:12px;font-weight:600;color:var(--txt-m);margin-left:6px;">&mdash; Share your experience</span>
                </div>
                <% for (Map<String,String> item : itemList) {
                       int existRating=0; try{existRating=Integer.parseInt(item.get("rating"));}catch(Exception ig){}
                       String existComment=item.get("review_comment");
                       String sellerEmailItem=item.get("seller_email");
                       String safeFormId="rf_"+orderId.replace("-","")+"_"+item.get("product_id");
                       boolean alreadyRated=existRating>0;
                %>
                <div class="rate-item-card <%= alreadyRated?"already-rated":"" %>">
                    <div class="rate-item-name">
                        <i class="fas fa-box" style="color:var(--star);"></i>
                        <%= item.get("product_name") %>
                        <% if (alreadyRated) { %><span class="exist-badge ms-2"><i class="fas fa-check-circle"></i> Reviewed</span><% } %>
                    </div>
                    <% if (alreadyRated) { %>
                    <div class="existing-rating">
                        <div>
                            <div class="exist-stars">
                                <% for(int s=1;s<=5;s++){%><i class="fas fa-star" style="<%= s>existRating?"color:#d1d5db;":"" %>"></i><%}%>
                            </div>
                            <% if(existComment!=null&&!existComment.trim().isEmpty()){%><div class="exist-comment">&ldquo;<%= existComment %>&rdquo;</div><%}%>
                            <div style="margin-top:8px;">
                                <a href="#" onclick="document.getElementById('form_<%= safeFormId %>').style.display='block';return false;"
                                   style="font-size:12px;font-weight:700;color:var(--primary);text-decoration:none;">
                                    <i class="fas fa-edit"></i> Edit Review
                                </a>
                            </div>
                        </div>
                    </div>
                    <form method="POST" action="RatingServlet" id="form_<%= safeFormId %>" style="display:none;margin-top:14px;">
                        <input type="hidden" name="action" value="submit">
                        <input type="hidden" name="redirect" value="myorders.jsp">
                        <input type="hidden" name="r_order_id"     value="<%= orderId %>">
                        <input type="hidden" name="r_product_id"   value="<%= item.get("product_id") %>">
                        <input type="hidden" name="r_product_name" value="<%= item.get("product_name") %>">
                        <input type="hidden" name="r_seller_email" value="<%= sellerEmailItem %>">
                        <div class="star-row"><span class="star-label">Your rating:</span>
                            <div class="stars-input">
                                <% for(int s=5;s>=1;s--){%>
                                <input type="radio" name="r_star" id="s<%= s %>_<%= safeFormId %>" value="<%= s %>" <%= s==existRating?"checked":"" %>>
                                <label for="s<%= s %>_<%= safeFormId %>">&#9733;</label>
                                <%}%>
                            </div>
                        </div>
                        <textarea class="rate-textarea" name="r_comment" placeholder="Update your review..."><%= existComment!=null?existComment:"" %></textarea>
                        <button type="submit" class="btn-submit-rating"><i class="fas fa-paper-plane"></i> Update Review</button>
                        <a href="#" onclick="document.getElementById('form_<%= safeFormId %>').style.display='none';return false;"
                           style="margin-left:12px;font-size:13px;font-weight:600;color:var(--txt-m);text-decoration:none;">Cancel</a>
                    </form>
                    <% } else { %>
                    <form method="POST" action="RatingServlet">
                        <input type="hidden" name="action" value="submit">
                        <input type="hidden" name="redirect" value="myorders.jsp">
                        <input type="hidden" name="r_order_id"     value="<%= orderId %>">
                        <input type="hidden" name="r_product_id"   value="<%= item.get("product_id") %>">
                        <input type="hidden" name="r_product_name" value="<%= item.get("product_name") %>">
                        <input type="hidden" name="r_seller_email" value="<%= sellerEmailItem %>">
                        <div class="star-row"><span class="star-label">Your rating:</span>
                            <div class="stars-input">
                                <% for(int s=5;s>=1;s--){%>
                                <input type="radio" name="r_star" id="ns<%= s %>_<%= safeFormId %>" value="<%= s %>" required>
                                <label for="ns<%= s %>_<%= safeFormId %>">&#9733;</label>
                                <%}%>
                            </div>
                        </div>
                        <textarea class="rate-textarea" name="r_comment" placeholder="Tell others what you liked or didn't like..."></textarea>
                        <button type="submit" class="btn-submit-rating"><i class="fas fa-star"></i> Submit Review</button>
                    </form>
                    <% } %>
                </div>
                <% } %>
            </div>
            <% } %>

        </div><!-- .order-card -->
    <%  } /* end order loop */
        try{if(conn!=null)conn.close();}catch(Exception ig){}
    } %>
    </div><!-- #ordersContainer -->

    <div id="noFilterResult" style="display:none;">
        <div class="empty-state" style="padding:50px 40px;">
            <div class="empty-icon"><i class="fas fa-search"></i></div>
            <h3>No Orders Found</h3>
            <p>No orders match your current filter or search.</p>
        </div>
    </div>
</div>

<!-- FOOTER -->
<footer class="footer">
    <div class="container">
        <div class="footer-bottom"><p>&copy; 2025 MarketHub. All rights reserved.</p></div>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* ── Return Modal ── */
function openReturnModal(orderId, productId, productName, sellerEmail) {
    document.getElementById('modal_order_id').value     = orderId;
    document.getElementById('modal_product_id').value   = productId;
    document.getElementById('modal_product_name').textContent = productName;
    document.getElementById('modal_seller_email').value = sellerEmail;
    document.getElementById('returnModal').classList.add('open');
    document.body.style.overflow = 'hidden';
}
function closeReturnModal() {
    document.getElementById('returnModal').classList.remove('open');
    document.body.style.overflow = '';
}
document.getElementById('returnModal').addEventListener('click', function(e) {
    if (e.target === this) closeReturnModal();
});
document.addEventListener('keydown', function(e){ if(e.key==='Escape') closeReturnModal(); });

/* ── Filters / Search ── */
function filterOrders(status, btn) {
    document.querySelectorAll('.filter-btn').forEach(function(b){b.classList.remove('active');});
    btn.classList.add('active');
    var vis=0;
    document.querySelectorAll('.order-card').forEach(function(c){
        var show = status==='all' || c.getAttribute('data-status').includes(status);
        c.style.display = show?'block':'none';
        if(show) vis++;
    });
    document.getElementById('noFilterResult').style.display = vis===0?'block':'none';
}
function searchOrders(q) {
    q=q.toLowerCase().trim(); var vis=0;
    document.querySelectorAll('.order-card').forEach(function(c){
        var show = q===''||c.getAttribute('data-orderid').includes(q);
        c.style.display=show?'block':'none';
        if(show) vis++;
    });
    document.getElementById('noFilterResult').style.display = vis===0?'block':'none';
}
function toggleExtraItems(safeId){
    var extras=document.querySelectorAll('.extra-item-'+safeId);
    var chip=document.getElementById('moreChip_'+safeId);
    var hidden=extras[0]&&extras[0].classList.contains('d-none');
    extras.forEach(function(el){el.classList.toggle('d-none',!hidden);});
    if(chip){
        var count=extras.length;
        chip.innerHTML=hidden
            ?'<span class="more-items-chip" onclick="toggleExtraItems(\''+safeId+'\')"><i class="fas fa-minus-circle"></i> Show less</span>'
            :'<span class="more-items-chip" onclick="toggleExtraItems(\''+safeId+'\')"><i class="fas fa-plus-circle"></i> +'+count+' more item'+(count>1?'s':'')+'</span>';
    }
}

/* ── Scroll animation ── */
var obs=new IntersectionObserver(function(entries){
    entries.forEach(function(e){
        if(e.isIntersecting){e.target.style.opacity='1';e.target.style.transform='translateY(0)';}
    });
},{threshold:0.06});
document.querySelectorAll('.order-card').forEach(function(c,i){
    c.style.opacity='0';c.style.transform='translateY(25px)';
    c.style.transition='all .5s ease '+(i*0.07)+'s';
    obs.observe(c);
});
</script>
</body>
</html>
