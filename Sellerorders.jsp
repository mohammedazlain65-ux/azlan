<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    HttpSession hs = request.getSession();
    String sellerEmail = null, sellerName = null;
    try {
        sellerEmail = hs.getAttribute("email").toString();
        sellerName  = hs.getAttribute("username") != null ? hs.getAttribute("username").toString() : sellerEmail;
        if (sellerEmail == null || sellerEmail.trim().equals("")) { out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); return; }
    } catch (Exception e) { out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Sales Orders - MarketHub</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root{--primary:#6366f1;--secondary:#8b5cf6;--dark-bg:#1e293b;--light-bg:#F3F3F3;--success:#10b981;--danger:#ef4444;--warning:#f59e0b;--info:#06b6d4;--sidebar-bg:#0f172a;--sidebar-hov:#1e293b;--txt:#0f172a;--txt-m:#64748b;--border:#e2e8f0;}
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Outfit',sans-serif;background:linear-gradient(135deg,#f0f4ff,#e5edff);min-height:100vh;overflow-x:hidden;}
.sidebar{position:fixed;left:0;top:0;height:100vh;width:260px;background:var(--sidebar-bg);box-shadow:4px 0 20px rgba(0,0,0,.1);z-index:1000;overflow-y:auto;}
.sidebar::-webkit-scrollbar{width:6px;}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.2);border-radius:3px;}
.sidebar-header{padding:25px 20px;border-bottom:1px solid rgba(255,255,255,.1);}
.sidebar-logo{color:white;font-size:24px;font-weight:800;text-decoration:none;display:flex;align-items:center;gap:12px;}
.sidebar-logo i{color:var(--primary);font-size:28px;}
.seller-badge{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;font-size:10px;padding:3px 8px;border-radius:12px;font-weight:700;}
.sidebar-menu{padding:20px 0;}
.menu-sec{color:rgba(255,255,255,.4);font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1.5px;padding:20px 20px 10px;}
.sidebar-menu a{display:flex;align-items:center;padding:14px 20px;color:rgba(255,255,255,.8);text-decoration:none;transition:all .3s;position:relative;font-weight:500;margin:2px 10px;border-radius:8px;}
.sidebar-menu a::before{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:3px;height:0;background:var(--primary);transition:height .3s;border-radius:0 3px 3px 0;}
.sidebar-menu a:hover,.sidebar-menu a.active{background:var(--sidebar-hov);color:white;padding-left:25px;}
.sidebar-menu a.active::before{height:70%;}
.sidebar-menu a i{font-size:18px;margin-right:15px;width:20px;text-align:center;}
.sidebar-menu a:hover i,.sidebar-menu a.active i{color:var(--primary);}
.sidebar-menu .badge{margin-left:auto;font-size:10px;padding:4px 8px;font-weight:700;}
.main-content{margin-left:260px;min-height:100vh;}
.top-navbar{background:white;padding:20px 30px;box-shadow:0 2px 15px rgba(0,0,0,.05);position:sticky;top:0;z-index:999;display:flex;justify-content:space-between;align-items:center;}
.navbar-left h1{font-size:28px;font-weight:800;color:var(--txt);margin:0;}
.navbar-left .bc{font-size:13px;color:var(--txt-m);margin:5px 0 0;}
.navbar-right{display:flex;align-items:center;gap:20px;}
.search-box{position:relative;}
.search-box input{padding:10px 40px 10px 15px;border:2px solid var(--border);border-radius:10px;width:280px;font-size:14px;font-family:'Outfit',sans-serif;}
.search-box input:focus{outline:none;border-color:var(--primary);}
.search-box i{position:absolute;right:15px;top:50%;transform:translateY(-50%);color:var(--txt-m);}
.sel-prof{display:flex;align-items:center;gap:12px;padding:8px 15px;background:var(--light-bg);border-radius:12px;cursor:pointer;}
.sel-prof .pname{font-weight:700;font-size:14px;color:var(--txt);}
.sel-prof .prole{font-size:12px;color:var(--txt-m);}
.dash-content{padding:30px;}
.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:20px;margin-bottom:30px;}
.stat-card{background:white;border-radius:16px;padding:20px;box-shadow:0 4px 20px rgba(0,0,0,.04);border:1px solid var(--border);opacity:0;animation:fadeInUp .6s ease forwards;}
.stat-card:nth-child(1){animation-delay:.1s}.stat-card:nth-child(2){animation-delay:.2s}.stat-card:nth-child(3){animation-delay:.3s}.stat-card:nth-child(4){animation-delay:.4s}.stat-card:nth-child(5){animation-delay:.5s}
.scard-hd{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:12px;}
.scard-icon{width:50px;height:50px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:22px;}
.si-amber{background:rgba(245,158,11,.15);color:var(--warning);}.si-green{background:rgba(16,185,129,.15);color:var(--success);}.si-blue{background:rgba(99,102,241,.15);color:var(--primary);}.si-cyan{background:rgba(6,182,212,.15);color:var(--info);}
.scard-val{font-size:28px;font-weight:800;color:var(--txt);margin-bottom:5px;}.scard-lbl{color:var(--txt-m);font-size:13px;}
.toolbar-card{background:white;border-radius:16px;padding:20px;box-shadow:0 4px 20px rgba(0,0,0,.04);border:1px solid var(--border);margin-bottom:25px;}
.toolbar{display:flex;align-items:center;gap:12px;flex-wrap:wrap;}
.toolbar-label{font-weight:700;color:var(--txt);font-size:14px;display:flex;align-items:center;gap:8px;}
.toolbar-label i{color:var(--primary);}
.tb-btn{padding:8px 18px;border-radius:10px;border:2px solid var(--border);background:white;font-family:'Outfit',sans-serif;font-weight:700;font-size:13px;color:var(--txt-m);cursor:pointer;transition:all .25s;}
.tb-btn:hover,.tb-btn.active{background:var(--primary);color:white;border-color:var(--primary);}
.tb-search{margin-left:auto;position:relative;min-width:240px;}
.tb-search input{padding:9px 40px 9px 15px;border:2px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;width:100%;}
.tb-search input:focus{outline:none;border-color:var(--primary);}
.tb-search i{position:absolute;right:13px;top:50%;transform:translateY(-50%);color:var(--txt-m);font-size:13px;}
/* ── ORDER CARD ── */
.order-card{background:white;border-radius:16px;box-shadow:0 4px 20px rgba(0,0,0,.04);margin-bottom:20px;overflow:hidden;border:1px solid var(--border);transition:all .3s;}
.order-card:hover{box-shadow:0 8px 30px rgba(0,0,0,.1);border-color:var(--primary);transform:translateY(-3px);}
.order-card[data-status="shipped"]{border-left:5px solid #6366f1;}
.card-top{background:linear-gradient(135deg,rgba(99,102,241,.04),rgba(139,92,246,.04));padding:16px 24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;border-bottom:1px solid var(--border);}
.card-order-id{font-size:15px;font-weight:800;color:var(--txt);display:flex;align-items:center;gap:7px;}
.card-order-id i{color:var(--primary);}
.card-date{font-size:13px;font-weight:600;color:var(--txt-m);display:flex;align-items:center;gap:6px;}
.src-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:700;}
.src-cart{background:rgba(99,102,241,.1);color:var(--primary);}.src-buynow{background:rgba(16,185,129,.1);color:var(--success);}
.status-pill{display:inline-flex;align-items:center;gap:6px;padding:5px 14px;border-radius:20px;font-size:12px;font-weight:800;}
.sp-pending{background:rgba(245,158,11,.15);color:#d97706;}.sp-processing{background:rgba(6,182,212,.15);color:#0891b2;}.sp-shipped{background:rgba(99,102,241,.15);color:var(--primary);}.sp-delivered{background:rgba(16,185,129,.15);color:var(--success);}.sp-cancelled{background:rgba(239,68,68,.15);color:var(--danger);}
.status-form{display:flex;align-items:center;gap:8px;}
.status-form select{padding:6px 12px;border:2px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;background:white;}
.status-form select:focus{outline:none;border-color:var(--primary);}
.status-form button{padding:7px 16px;background:var(--primary);color:white;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:800;cursor:pointer;}
.status-form button:disabled{opacity:.6;cursor:not-allowed;}
.card-body-section{padding:20px 24px;}
.section-label{font-size:12px;font-weight:800;color:var(--txt-m);text-transform:uppercase;letter-spacing:.6px;margin-bottom:12px;display:flex;align-items:center;gap:7px;}
.section-label i{color:var(--primary);}
.my-items-table{width:100%;border-collapse:collapse;}
.my-items-table thead th{background:var(--light-bg);padding:10px 14px;font-size:12px;font-weight:800;color:var(--txt-m);text-transform:uppercase;letter-spacing:.5px;border-bottom:2px solid var(--border);}
.my-items-table thead th:last-child{text-align:right;}
.my-items-table tbody td{padding:12px 14px;border-bottom:1px solid var(--border);font-size:14px;font-weight:600;color:var(--txt);vertical-align:middle;}
.my-items-table tbody tr:last-child td{border-bottom:none;}
.my-items-table td:last-child{text-align:right;font-weight:800;}
.prod-name-cell{display:flex;align-items:center;gap:9px;}
.prod-dot{width:8px;height:8px;border-radius:50%;background:var(--primary);flex-shrink:0;}
.qty-chip{background:rgba(99,102,241,.1);color:var(--primary);padding:3px 9px;border-radius:6px;font-size:12px;font-weight:800;}
.earnings-box{background:linear-gradient(135deg,rgba(99,102,241,.05),rgba(139,92,246,.03));border:2px solid rgba(99,102,241,.15);border-radius:14px;padding:18px 20px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:14px;margin-top:15px;}
.earn-line{display:flex;align-items:center;gap:8px;font-size:14px;font-weight:600;color:var(--txt-m);}
.earn-line strong{color:var(--txt);font-size:16px;}
.earn-total-val{font-size:24px;font-weight:900;color:var(--primary);}
/* ═══ LOGISTICS BANNER ═══ */
.logistics-banner{background:linear-gradient(135deg,rgba(99,102,241,.07),rgba(139,92,246,.04));border:2px dashed rgba(99,102,241,.5);border-radius:14px;padding:16px 20px;margin-top:16px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;}
.logistics-banner-txt{display:flex;align-items:center;gap:10px;font-size:13px;font-weight:700;color:#4338ca;}
.logistics-banner-txt i{font-size:20px;color:#6366f1;flex-shrink:0;}
.btn-logistics{display:inline-flex;align-items:center;gap:8px;background:linear-gradient(135deg,#6366f1,#8b5cf6);color:white;border:none;padding:10px 22px;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:800;cursor:pointer;transition:all .25s;text-decoration:none;white-space:nowrap;}
.btn-logistics:hover{transform:translateY(-2px);box-shadow:0 8px 20px rgba(99,102,241,.45);color:white;}
.btn-logistics:disabled{opacity:.55;cursor:not-allowed;transform:none;box-shadow:none;}
.btn-logistics.sent{background:linear-gradient(135deg,#10b981,#059669);}
/* ─── */
.card-footer-section{border-top:1px solid var(--border);padding:16px 24px;background:rgba(248,250,252,.5);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:14px;}
.buyer-info{display:flex;align-items:center;gap:10px;}
.buyer-avatar{width:38px;height:38px;background:linear-gradient(135deg,var(--primary),var(--secondary));border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:16px;font-weight:800;}
.buyer-detail .buyer-name{font-size:14px;font-weight:800;color:var(--txt);}
.buyer-detail .buyer-addr{font-size:12px;font-weight:600;color:var(--txt-m);}
.payment-tag{display:inline-flex;align-items:center;gap:5px;background:rgba(16,185,129,.1);color:var(--success);padding:5px 12px;border-radius:8px;font-size:12px;font-weight:800;}
.empty-box{background:white;border-radius:16px;padding:60px 40px;text-align:center;box-shadow:0 4px 20px rgba(0,0,0,.04);border:1px solid var(--border);}
.empty-icon-wrap{width:100px;height:100px;background:rgba(99,102,241,.08);border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 20px;}
.empty-icon-wrap i{font-size:44px;color:var(--primary);}
.empty-box h3{font-size:24px;font-weight:800;color:var(--txt);margin-bottom:10px;}
.empty-box p{font-size:15px;color:var(--txt-m);font-weight:500;margin-bottom:24px;}
.btn-go-dash{background:var(--primary);color:white;border:none;padding:12px 32px;border-radius:12px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;text-decoration:none;display:inline-block;}
.btn-go-dash:hover{color:white;}
.toast-wrap{position:fixed;bottom:28px;right:28px;z-index:9999;display:flex;flex-direction:column;gap:10px;}
.toast-msg{padding:14px 20px;border-radius:12px;font-weight:700;font-size:14px;display:flex;align-items:center;gap:10px;animation:slideUp .35s ease;box-shadow:0 8px 28px rgba(0,0,0,.15);min-width:280px;}
.toast-success{background:#ecfdf5;color:#065f46;border-left:4px solid var(--success);}
.toast-error{background:#fef2f2;color:#991b1b;border-left:4px solid var(--danger);}
.diag-box{background:#fffbeb;border:2px solid #f59e0b;border-radius:14px;padding:18px 22px;margin-bottom:22px;font-size:13px;font-weight:600;color:#92400e;}
.diag-box code{background:#fef3c7;padding:2px 6px;border-radius:4px;font-size:12px;}
.err-box{background:#fef2f2;border-left:4px solid #ef4444;border-radius:14px;padding:16px 22px;margin-bottom:22px;color:#dc2626;font-weight:700;display:flex;align-items:center;gap:12px;}
@keyframes fadeInUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
@keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}
@media(max-width:768px){.sidebar{width:70px;}.sidebar-header,.menu-sec,.sidebar-menu a span,.sidebar-menu .badge{display:none;}.sidebar-menu a{justify-content:center;padding:14px 10px;}.sidebar-menu a i{margin-right:0;}.main-content{margin-left:70px;}.search-box input{width:160px;}}
</style>
</head>
<body>
<%
String dbURL="jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
String dbUser="root",dbPass="";
String emailCol=null,diagInfo=null,dbError=null;
Connection conn=null;
try{
    Class.forName("com.mysql.jdbc.Driver");
    conn=DriverManager.getConnection(dbURL,dbUser,dbPass);
    PreparedStatement psS=conn.prepareStatement("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='multi_vendor' AND TABLE_NAME='adprod' ORDER BY ORDINAL_POSITION");
    ResultSet rsS=psS.executeQuery();
    StringBuilder allC=new StringBuilder();
    String[] cands={"seller_email","email","user_email","semail","seller_id"};
    while(rsS.next()){String col=rsS.getString("COLUMN_NAME");if(allC.length()>0)allC.append(", ");allC.append(col);for(String c:cands){if(col.equalsIgnoreCase(c)){emailCol=col;break;}}}
    rsS.close();psS.close();
    if(emailCol==null)diagInfo=allC.toString();
}catch(Exception ex){dbError="Connection failed: "+ex.getMessage();}

int totalOrders=0,pendingCount=0,shippedCount=0,deliveredCount=0;
double totalRevenue=0;
java.util.List<java.util.Map<String,String>> orderList=new java.util.ArrayList<java.util.Map<String,String>>();
java.util.Map<String,java.util.List<String[]>> orderItemsMap=new java.util.HashMap<String,java.util.List<String[]>>();
java.util.Map<String,Double> orderRevenueMap=new java.util.HashMap<String,Double>();
java.util.Set<String> alreadySentSet=new java.util.HashSet<String>();

if(emailCol!=null&&dbError==null){
    try{
        String orderSql="SELECT DISTINCT o.order_id,o.full_name,o.phone,o.shipping_address,o.city,o.state,o.pincode,o.payment_method,o.subtotal,o.tax_amount,o.grand_total,o.total_items,o.order_status,o.source,o.order_date,o.customer_email FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=? ORDER BY o.order_date DESC";
        PreparedStatement ps=conn.prepareStatement(orderSql);
        ps.setString(1,sellerEmail);
        ResultSet rs=ps.executeQuery();
        while(rs.next()){
            java.util.Map<String,String> row=new java.util.HashMap<String,String>();
            String oid=rs.getString("order_id");
            row.put("order_id",oid);row.put("full_name",rs.getString("full_name"));row.put("phone",rs.getString("phone"));
            row.put("shipping_address",rs.getString("shipping_address"));row.put("city",rs.getString("city"));
            row.put("state",rs.getString("state"));row.put("pincode",rs.getString("pincode"));
            row.put("payment_method",rs.getString("payment_method"));row.put("subtotal",rs.getString("subtotal"));
            row.put("tax_amount",rs.getString("tax_amount"));row.put("grand_total",rs.getString("grand_total"));
            row.put("total_items",rs.getString("total_items"));row.put("order_status",rs.getString("order_status"));
            row.put("source",rs.getString("source"));row.put("order_date",rs.getString("order_date"));
            row.put("customer_email",rs.getString("customer_email"));
            orderList.add(row);
            totalOrders++;
            String st=rs.getString("order_status");
            if("Pending".equalsIgnoreCase(st)||"Processing".equalsIgnoreCase(st))pendingCount++;
            if("Shipped".equalsIgnoreCase(st))shippedCount++;
            if("Delivered".equalsIgnoreCase(st))deliveredCount++;
        }
        rs.close();ps.close();
        for(java.util.Map<String,String> order:orderList){
            String oid=order.get("order_id");
            PreparedStatement psIt=conn.prepareStatement("SELECT oi.product_name,oi.quantity,oi.unit_price,oi.item_total FROM order_items oi JOIN adprod ap ON oi.product_id=ap.id WHERE oi.order_id=? AND ap."+emailCol+"=?");
            psIt.setString(1,oid);psIt.setString(2,sellerEmail);
            ResultSet rsIt=psIt.executeQuery();
            java.util.List<String[]> items=new java.util.ArrayList<String[]>();
            double myRevenue=0;
            while(rsIt.next()){String[] item={rsIt.getString("product_name"),String.valueOf(rsIt.getInt("quantity")),String.format("%.2f",rsIt.getDouble("unit_price")),String.format("%.2f",rsIt.getDouble("item_total"))};items.add(item);myRevenue+=rsIt.getDouble("item_total");}
            rsIt.close();psIt.close();
            orderItemsMap.put(oid,items);orderRevenueMap.put(oid,myRevenue);totalRevenue+=myRevenue;
        }
        /* Check which Shipped orders already exist in shipments */
        PreparedStatement psSh=conn.prepareStatement("SELECT order_id FROM shipments WHERE order_id=?");
        for(java.util.Map<String,String> ord:orderList){
            if("Shipped".equalsIgnoreCase(ord.get("order_status"))){
                psSh.setString(1,ord.get("order_id"));
                ResultSet rsSh=psSh.executeQuery();
                if(rsSh.next())alreadySentSet.add(ord.get("order_id"));
                rsSh.close();
            }
        }
        psSh.close();
    }catch(Exception dbEx){dbError=dbEx.getMessage();}
    finally{try{if(conn!=null)conn.close();}catch(Exception ignored){}}
}
%>
<aside class="sidebar">
    <div class="sidebar-header"><a href="sellerdashboard.jsp" class="sidebar-logo"><i class="fas fa-store"></i><div>MarketHub <div class="seller-badge">SELLER</div></div></a></div>
    <nav class="sidebar-menu">
        <div class="menu-sec">Main Menu</div>
        <a href="sellerdashboard.jsp"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
        <a href="sellerorders.jsp" class="active"><i class="fas fa-shopping-cart"></i><span>My Orders</span><% if(totalOrders>0){%><span class="badge bg-danger"><%=totalOrders%></span><%}%></a>
        <a href="myproducts.jsp"><i class="fas fa-box"></i><span>My Products</span></a>
        <a href="addproduct.jsp"><i class="fas fa-plus-circle"></i><span>Add Product</span></a>
        <a href="#"><i class="fas fa-warehouse"></i><span>Inventory</span></a>
        <div class="menu-sec">Account</div>
        <a href="sellerprofile.jsp"><i class="fas fa-user-circle"></i><span>My Profile</span></a>
        <a href="ulogout"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
    </nav>
</aside>
<div class="main-content">
    <div class="top-navbar">
        <div class="navbar-left"><h1>Sales Orders</h1><div class="bc"><i class="fas fa-home"></i> Home / Orders</div></div>
        <div class="navbar-right">
            <div class="search-box"><input type="text" placeholder="Search orders..." oninput="searchCards(this.value)"><i class="fas fa-search"></i></div>
            <div class="sel-prof" onclick="window.location='sellerprofile.jsp'">
                <div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,var(--primary),var(--secondary));display:flex;align-items:center;justify-content:center;color:white;font-weight:700;font-size:16px;"><%=(sellerName!=null&&sellerName.length()>0)?String.valueOf(sellerName.charAt(0)).toUpperCase():"S"%></div>
                <div><div class="pname"><%=sellerName!=null?sellerName:"Seller"%></div><div class="prole">Seller Account</div></div>
                <i class="fas fa-chevron-down"></i>
            </div>
        </div>
    </div>
    <div class="dash-content">
<%if(dbError!=null){%><div class="err-box"><i class="fas fa-times-circle"></i><span><strong>Database Error:</strong> <%=dbError%></span></div><%}%>
<%if(diagInfo!=null){%><div class="diag-box"><strong>Column Not Found.</strong> adprod columns: <code><%=diagInfo%></code></div><%}%>
        <div class="stats-grid">
            <div class="stat-card"><div class="scard-hd"><div class="scard-icon si-amber"><i class="fas fa-shopping-bag"></i></div></div><div class="scard-val"><%=totalOrders%></div><div class="scard-lbl">Total Orders</div></div>
            <div class="stat-card"><div class="scard-hd"><div class="scard-icon si-cyan"><i class="fas fa-clock"></i></div></div><div class="scard-val"><%=pendingCount%></div><div class="scard-lbl">Pending</div></div>
            <div class="stat-card"><div class="scard-hd"><div class="scard-icon si-blue"><i class="fas fa-truck"></i></div></div><div class="scard-val"><%=shippedCount%></div><div class="scard-lbl">Shipped</div></div>
            <div class="stat-card"><div class="scard-hd"><div class="scard-icon si-green"><i class="fas fa-check-circle"></i></div></div><div class="scard-val"><%=deliveredCount%></div><div class="scard-lbl">Delivered</div></div>
            <div class="stat-card"><div class="scard-hd"><div class="scard-icon si-amber"><i class="fas fa-rupee-sign"></i></div></div><div class="scard-val" style="font-size:22px;">&#8377;<%=String.format("%.0f",totalRevenue)%></div><div class="scard-lbl">My Revenue</div></div>
        </div>
        <div class="toolbar-card">
            <div class="toolbar">
                <span class="toolbar-label"><i class="fas fa-filter"></i> Filter:</span>
                <button class="tb-btn active" onclick="filterCards('all',this)">All</button>
                <button class="tb-btn" onclick="filterCards('pending',this)">Pending</button>
                <button class="tb-btn" onclick="filterCards('processing',this)">Processing</button>
                <button class="tb-btn" onclick="filterCards('shipped',this)"><i class="fas fa-truck" style="color:#6366f1;margin-right:4px;"></i>Shipped</button>
                <button class="tb-btn" onclick="filterCards('delivered',this)">Delivered</button>
                <button class="tb-btn" onclick="filterCards('cancelled',this)">Cancelled</button>
                <div class="tb-search"><input type="text" placeholder="Search Order ID..." oninput="searchCards(this.value)"><i class="fas fa-search"></i></div>
            </div>
        </div>
        <div id="cardsWrap">
<%if(orderList.isEmpty()){%>
            <div class="empty-box"><div class="empty-icon-wrap"><i class="fas fa-inbox"></i></div><h3>No Orders Yet</h3><p>No customers have ordered your products yet.</p><a href="sellerdashboard.jsp" class="btn-go-dash"><i class="fas fa-th-large"></i> Dashboard</a></div>
<%}else{for(java.util.Map<String,String> order:orderList){
    String oid=order.get("order_id")!=null?order.get("order_id"):"-";
    String fullName=order.get("full_name")!=null?order.get("full_name"):"-";
    String phone=order.get("phone")!=null?order.get("phone"):"-";
    String shipAddr=order.get("shipping_address")!=null?order.get("shipping_address"):"-";
    String city=order.get("city")!=null?order.get("city"):"";
    String state=order.get("state")!=null?order.get("state"):"";
    String pincode=order.get("pincode")!=null?order.get("pincode"):"";
    String orderStatus=order.get("order_status")!=null?order.get("order_status"):"Pending";
    String source=order.get("source")!=null?order.get("source"):"checkout";
    String orderDate=order.get("order_date")!=null?order.get("order_date"):"-";
    String payMethod=order.get("payment_method")!=null?order.get("payment_method"):"cod";
    String custEmail=order.get("customer_email")!=null?order.get("customer_email"):"-";
    String grandTotal=order.get("grand_total")!=null?order.get("grand_total"):"0";
    String payLabel="Cash on Delivery",payIcon="money-bill-wave";
    if("card".equals(payMethod)){payLabel="Credit/Debit Card";payIcon="credit-card";}
    else if("upi".equals(payMethod)){payLabel="UPI Payment";payIcon="mobile-alt";}
    String spClass="sp-pending",spIcon="clock";
    if("Processing".equalsIgnoreCase(orderStatus)){spClass="sp-processing";spIcon="cog";}
    if("Shipped".equalsIgnoreCase(orderStatus)){spClass="sp-shipped";spIcon="truck";}
    if("Delivered".equalsIgnoreCase(orderStatus)){spClass="sp-delivered";spIcon="check-circle";}
    if("Cancelled".equalsIgnoreCase(orderStatus)){spClass="sp-cancelled";spIcon="times-circle";}
    String srcLabel="buynow".equals(source)?"Buy Now":"Cart";
    String srcCss="buynow".equals(source)?"src-buynow":"src-cart";
    String srcIcon="buynow".equals(source)?"bolt":"shopping-cart";
    String safeStatus=orderStatus.toLowerCase().replace(" ","");
    String safeId=oid.replace("-","_").replace(" ","");
    String avatarChar=(fullName.length()>0)?String.valueOf(fullName.charAt(0)).toUpperCase():"?";
    java.util.List<String[]> myItems=orderItemsMap.get(oid);
    if(myItems==null)myItems=new java.util.ArrayList<String[]>();
    double myRev=orderRevenueMap.containsKey(oid)?orderRevenueMap.get(oid):0.0;
    String fullAddr=shipAddr;
    if(city!=null&&!city.isEmpty())fullAddr+=", "+city;
    if(state!=null&&!state.isEmpty())fullAddr+=", "+state;
    if(pincode!=null&&!pincode.isEmpty())fullAddr+=" - "+pincode;
    StringBuilder prodSB=new StringBuilder();
    for(String[] it:myItems){if(prodSB.length()>0)prodSB.append(", ");prodSB.append(it[0]);}
    String productNames=prodSB.length()>0?prodSB.toString():"Order "+oid;
    boolean isShipped="Shipped".equalsIgnoreCase(orderStatus);
    boolean alreadySent=alreadySentSet.contains(oid);
    String jsProduct=productNames.replace("\\","\\\\").replace("'","\\'").replace("\"","\\\"");
    String jsName=fullName.replace("\\","\\\\").replace("'","\\'");
    String jsAddr=fullAddr.replace("\\","\\\\").replace("'","\\'").replace("\n"," ").replace("\r"," ");
%>
<div class="order-card" data-status="<%=safeStatus%>" data-orderid="<%=oid.toLowerCase()%>">
    <div class="card-top">
        <div class="d-flex align-items-center gap-3 flex-wrap">
            <div class="card-order-id"><i class="fas fa-hashtag"></i> <%=oid%></div>
            <span class="src-badge <%=srcCss%>"><i class="fas fa-<%=srcIcon%>"></i> <%=srcLabel%></span>
            <span class="status-pill <%=spClass%> pill-<%=safeId%>"><i class="fas fa-<%=spIcon%>"></i><span class="pill-text-<%=safeId%>"><%=orderStatus%></span></span>
        </div>
        <div class="d-flex align-items-center gap-3 flex-wrap">
            <div class="card-date"><i class="fas fa-calendar-alt"></i> <%=orderDate%></div>
            <div class="status-form">
                <select id="sel-<%=safeId%>">
                    <option value="Pending" <%="Pending".equalsIgnoreCase(orderStatus)?"selected":""%>>Pending</option>
                    <option value="Processing" <%="Processing".equalsIgnoreCase(orderStatus)?"selected":""%>>Processing</option>
                    <option value="Shipped" <%="Shipped".equalsIgnoreCase(orderStatus)?"selected":""%>>Shipped</option>
                    <option value="Delivered" <%="Delivered".equalsIgnoreCase(orderStatus)?"selected":""%>>Delivered</option>
                    <option value="Cancelled" <%="Cancelled".equalsIgnoreCase(orderStatus)?"selected":""%>>Cancelled</option>
                </select>
                <button type="button" onclick="updateStatus('<%=oid%>','<%=safeId%>',this)"><i class="fas fa-sync-alt"></i> Update</button>
            </div>
        </div>
    </div>
    <div class="card-body-section">
        <div class="section-label"><i class="fas fa-box"></i> Your Products in This Order</div>
        <table class="my-items-table">
            <thead><tr><th>Product Name</th><th>Unit Price</th><th>Qty</th><th>Item Total</th></tr></thead>
            <tbody>
            <%for(String[] item:myItems){%>
                <tr><td><div class="prod-name-cell"><div class="prod-dot"></div><%=item[0]%></div></td><td>&#8377;<%=item[2]%></td><td><span class="qty-chip">x<%=item[1]%></span></td><td>&#8377;<%=item[3]%></td></tr>
            <%}%>
            </tbody>
        </table>
        <div class="earnings-box">
            <div class="d-flex gap-4 flex-wrap">
                <div class="earn-line"><i class="fas fa-box" style="color:var(--primary);"></i><span>Items: <strong><%=myItems.size()%></strong></span></div>
                <div class="earn-line"><i class="fas fa-receipt" style="color:var(--txt-m);"></i><span>Total: <strong>&#8377;<%=grandTotal%></strong></span></div>
            </div>
            <div><div style="font-size:12px;font-weight:700;color:var(--txt-m);margin-bottom:2px;">Your Revenue</div><div class="earn-total-val">&#8377;<%=String.format("%.2f",myRev)%></div></div>
        </div>

        <%-- ═══ LOGISTICS BANNER — only when status = Shipped ═══ --%>
        <%if(isShipped){%>
        <div class="logistics-banner" id="lb-<%=safeId%>">
            <div class="logistics-banner-txt">
                <i class="fas fa-truck-fast"></i>
                <%if(alreadySent){%>
                    <span>This order is already in the <strong>Logistics system</strong>.</span>
                <%}else{%>
                    <span>Status is <strong>Shipped</strong> &mdash; send this order to the Logistics system to create a shipment &amp; tracking record.</span>
                <%}%>
            </div>
            <%if(alreadySent){%>
                <a href="travel_logistics.jsp?section=shipments&sf=dispatched" class="btn-logistics sent" style="text-decoration:none;">
                    <i class="fas fa-eye"></i> View in Logistics
                </a>
            <%}else{%>
                <button class="btn-logistics" id="logbtn-<%=safeId%>"
                    onclick="sendToLogistics('<%=oid%>','<%=jsProduct%>','<%=jsName%>','<%=phone%>','<%=jsAddr%>','<%=safeId%>')">
                    <i class="fas fa-paper-plane"></i> Send to Logistics
                </button>
            <%}%>
        </div>
        <%}%>

    </div>
    <div class="card-footer-section">
        <div class="buyer-info">
            <div class="buyer-avatar"><%=avatarChar%></div>
            <div class="buyer-detail">
                <div class="buyer-name"><i class="fas fa-user" style="color:var(--txt-m);font-size:12px;"></i> <%=fullName%></div>
                <div class="buyer-addr"><i class="fas fa-map-marker-alt" style="font-size:11px;"></i> <%=fullAddr%></div>
                <div class="buyer-addr" style="margin-top:2px;"><i class="fas fa-phone" style="font-size:11px;"></i> <%=phone%> &nbsp; <i class="fas fa-envelope" style="font-size:11px;"></i> <%=custEmail%></div>
            </div>
        </div>
        <div class="payment-tag"><i class="fas fa-<%=payIcon%>"></i> <%=payLabel%></div>
    </div>
</div>
<%}}%>
        </div>
        <div id="noResult" style="display:none;">
            <div class="empty-box" style="padding:50px 40px;"><div class="empty-icon-wrap"><i class="fas fa-search"></i></div><h3>No Orders Found</h3><p>No orders match your filter or search.</p></div>
        </div>
    </div>
</div>
<div class="toast-wrap" id="toastWrap"></div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
var statusStyles={'Pending':{cls:'sp-pending',icon:'fas fa-clock'},'Processing':{cls:'sp-processing',icon:'fas fa-cog'},'Shipped':{cls:'sp-shipped',icon:'fas fa-truck'},'Delivered':{cls:'sp-delivered',icon:'fas fa-check-circle'},'Cancelled':{cls:'sp-cancelled',icon:'fas fa-times-circle'}};
var spClasses=['sp-pending','sp-processing','sp-shipped','sp-delivered','sp-cancelled'];

function updateStatus(orderId,safeId,btn){
    var newStatus=document.getElementById('sel-'+safeId).value;
    btn.disabled=true;btn.innerHTML='<i class="fas fa-spinner fa-spin"></i> Saving...';
    fetch('updateorderstatus',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'orderId='+encodeURIComponent(orderId)+'&newStatus='+encodeURIComponent(newStatus)})
    .then(function(r){return r.json();})
    .then(function(data){
        btn.disabled=false;btn.innerHTML='<i class="fas fa-sync-alt"></i> Update';
        if(data.success){
            var pill=document.querySelector('.pill-'+safeId);
            var txt=document.querySelector('.pill-text-'+safeId);
            var style=statusStyles[data.newStatus]||statusStyles['Pending'];
            spClasses.forEach(function(c){pill.classList.remove(c);});
            pill.classList.add(style.cls);txt.textContent=data.newStatus;
            pill.querySelector('i').className=style.icon;
            var card=pill.closest('.order-card');
            card.setAttribute('data-status',data.newStatus.toLowerCase());
            /* Show/hide logistics banner based on new status */
            var lb=document.getElementById('lb-'+safeId);
            if(data.newStatus==='Shipped'){
                if(lb){lb.style.display='flex';}
                else{
                    var body=card.querySelector('.card-body-section');
                    var nb=document.createElement('div');nb.className='logistics-banner';nb.id='lb-'+safeId;
                    nb.innerHTML='<div class="logistics-banner-txt"><i class="fas fa-truck-fast"></i><span>Status is <strong>Shipped</strong> &mdash; send this order to the Logistics system.</span></div>'
                        +'<button class="btn-logistics" id="logbtn-'+safeId+'" onclick="sendToLogistics(\''+orderId+'\',\'Order '+orderId+'\',\'\',\'\',\'\',\''+safeId+'\')">'
                        +'<i class="fas fa-paper-plane"></i> Send to Logistics</button>';
                    body.appendChild(nb);
                }
            }else{if(lb)lb.style.display='none';}
            showToast('success','Order '+orderId+' updated to "'+data.newStatus+'"');
        }else{showToast('error',data.message||'Update failed.');}
    })
    .catch(function(){btn.disabled=false;btn.innerHTML='<i class="fas fa-sync-alt"></i> Update';showToast('error','Network error.');});
}

/* ================================================================
   SEND TO LOGISTICS
   Posts to travel_logistics.jsp, then redirects to shipments.
   ================================================================ */
/**
 * DROP-IN REPLACEMENT for the sendToLogistics() function in sellerorders.jsp
 *
 * Key fixes vs. the original:
 *  1. Sends X-Requested-With header so travel_logistics.jsp returns JSON (not HTML)
 *  2. Parses JSON response instead of scanning raw HTML for 'MH-TRK-' strings
 *  3. Shows the real error message from the server on failure
 *  4. Handles the duplicate-shipment case ("already exists") gracefully
 *
 * Drop this into the <script> block of sellerorders.jsp, replacing the old function.
 */
function sendToLogistics(orderId, productName, customerName, phone, address, safeId) {
    var btn = document.getElementById('logbtn-' + safeId);
    if (!btn) return;

    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';

    var today  = new Date();
    var future = new Date(today);
    future.setDate(future.getDate() + 3);
    var fmt = function (d) { return d.toISOString().split('T')[0]; };

    var params = new URLSearchParams();
    params.append('action',           'dispatch');
    params.append('section',          'shipments');
    params.append('d_orderid',        orderId);
    params.append('d_product',        productName);
    params.append('d_customer',       customerName);
    params.append('d_phone',          phone);
    params.append('d_address',        address);
    params.append('d_date',           fmt(today));
    params.append('d_time',           today.toTimeString().slice(0, 5));
    params.append('d_delivery_date',  fmt(future));
    params.append('d_agent',          '');              // no agent pre-selected
    params.append('d_transport',      'Road -- Delivery Van');
    params.append('d_seller_source',  'seller');
    params.append('ajax',             'true');          // triggers JSON response

    fetch('travel_logistics.jsp', {
        method: 'POST',
        headers: {
            'Content-Type':     'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest'        // signals AJAX to the server
        },
        body: params.toString()
    })
    .then(function (r) { return r.json(); })
    .then(function (data) {
        btn.disabled = false;

        if (data.success) {
            // ✅ Success path
            btn.innerHTML = '<i class="fas fa-check"></i> Sent!';
            btn.classList.add('sent');
            btn.disabled  = true;

            var lb = document.getElementById('lb-' + safeId);
            if (lb) {
                lb.querySelector('.logistics-banner-txt').innerHTML =
                    '<i class="fas fa-truck-fast"></i>'
                    + '<span>Order pushed to <strong>Logistics</strong>! '
                    + 'Tracking: <strong>' + (data.tracking || '') + '</strong>. Redirecting...</span>';

                // Replace button with a "View in Logistics" link
                btn.outerHTML =
                    '<a href="travel_logistics.jsp?section=shipments&sf=dispatched" '
                    + 'class="btn-logistics sent" style="text-decoration:none;">'
                    + '<i class="fas fa-eye"></i> View in Logistics</a>';
            }

            showToast('success', 'Order ' + orderId + ' sent to Logistics! Tracking: ' + (data.tracking || ''));
            setTimeout(function () {
                window.location.href = 'travel_logistics.jsp?section=shipments&sf=dispatched';
            }, 2000);

        } else {
            // ❌ Server-side error (including duplicate shipment warning)
            btn.innerHTML = '<i class="fas fa-paper-plane"></i> Send to Logistics';
            showToast('error', data.message || 'Could not create shipment. Please try again.');
        }
    })
    .catch(function (err) {
        btn.disabled  = false;
        btn.innerHTML = '<i class="fas fa-paper-plane"></i> Send to Logistics';
        showToast('error', 'Network error. Please check your connection and try again.');
        console.error('sendToLogistics error:', err);
    });
}

function filterCards(status,btn){
    document.querySelectorAll('.tb-btn').forEach(function(b){b.classList.remove('active');});btn.classList.add('active');
    var visible=0;
    document.querySelectorAll('.order-card').forEach(function(card){var show=(status==='all')||card.getAttribute('data-status').includes(status);card.style.display=show?'block':'none';if(show)visible++;});
    document.getElementById('noResult').style.display=visible===0?'block':'none';
}
function searchCards(q){
    q=q.toLowerCase().trim();var visible=0;
    document.querySelectorAll('.order-card').forEach(function(card){var show=(q==='')||card.getAttribute('data-orderid').includes(q);card.style.display=show?'block':'none';if(show)visible++;});
    document.getElementById('noResult').style.display=visible===0?'block':'none';
}
function showToast(type,msg){
    var wrap=document.getElementById('toastWrap');var t=document.createElement('div');
    t.className='toast-msg toast-'+type;
    t.innerHTML='<i class="fas fa-'+(type==='success'?'check-circle':'exclamation-circle')+'"></i> '+msg;
    wrap.appendChild(t);
    setTimeout(function(){t.style.transition='opacity .4s';t.style.opacity='0';setTimeout(function(){t.remove();},450);},4500);
}
var observer=new IntersectionObserver(function(entries){entries.forEach(function(e){if(e.isIntersecting){e.target.style.opacity='1';e.target.style.transform='translateY(0)';}});},{threshold:0.07,rootMargin:'0px 0px -30px 0px'});
document.querySelectorAll('.order-card').forEach(function(card,i){card.style.opacity='0';card.style.transform='translateY(22px)';card.style.transition='all .45s ease '+(i*0.07)+'s';observer.observe(card);});
</script>
</body>
</html>