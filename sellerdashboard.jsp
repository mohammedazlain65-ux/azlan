<%-- 
    Document   : sellerdashboard
    Modified   : Fixed ratings query — robust multi-fallback approach
                 Added debug panel to diagnose seller_email mismatch
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%
    HttpSession hs = request.getSession();
    String username    = null;
    String sellerEmail = null;
    try {
        sellerEmail = hs.getAttribute("email").toString();
        username    = hs.getAttribute("username") != null
                      ? hs.getAttribute("username").toString() : sellerEmail;
        if (sellerEmail == null || sellerEmail.trim().equals("")) {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
            return;
        }
    } catch (Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        return;
    }

    String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "";

    /* ── auto-detect seller email column in adprod ── */
    String emailCol = null;
    Connection conn = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
        PreparedStatement psS = conn.prepareStatement(
            "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS " +
            "WHERE TABLE_SCHEMA='multi_vendor' AND TABLE_NAME='adprod' ORDER BY ORDINAL_POSITION");
        ResultSet rsS = psS.executeQuery();
        String[] cands = {"seller_email","email","user_email","semail","seller_id"};
        while (rsS.next()) {
            String col = rsS.getString("COLUMN_NAME");
            for (String c : cands) { if (col.equalsIgnoreCase(c)) { emailCol = col; break; } }
            if (emailCol != null) break;
        }
        rsS.close(); psS.close();
    } catch (Exception ex) { /* silent */ }

    int    totalOrders   = 0;
    double totalRevenue  = 0;
    int    totalProducts = 0;

    StringBuilder dailyLabels    = new StringBuilder();
    StringBuilder dailyRevenue   = new StringBuilder();
    StringBuilder dailyOrders    = new StringBuilder();
    StringBuilder monthlyLabels  = new StringBuilder();
    StringBuilder monthlyRevenue = new StringBuilder();
    StringBuilder monthlyOrders  = new StringBuilder();
    StringBuilder yearlyLabels   = new StringBuilder();
    StringBuilder yearlyRevenue  = new StringBuilder();
    StringBuilder yearlyOrders   = new StringBuilder();

    List<Map<String,String>> recentOrders   = new ArrayList<Map<String,String>>();
    List<Map<String,String>> recentActivity = new ArrayList<Map<String,String>>();

    /* ════════════ RATINGS DATA ════════════ */
    List<Map<String,String>> reviewList      = new ArrayList<Map<String,String>>();
    double avgRating    = 0;
    int    totalReviews = 0;
    int[]  starCounts   = new int[6];

    /* ════════════ DEBUG DATA ════════════ */
    String debugInfo           = "";
    int    totalRatingsInTable = 0;
    String sampleSellerEmails  = "";
    String ratingsQueryError   = "";

    if (emailCol != null && conn != null) {
        try {
            PreparedStatement psSt = conn.prepareStatement(
                "SELECT COUNT(DISTINCT o.order_id) AS total_orders, " +
                "       COALESCE(SUM(oi.item_total),0) AS my_revenue " +
                "FROM orders o JOIN order_items oi ON o.order_id=oi.order_id " +
                "JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=?");
            psSt.setString(1, sellerEmail);
            ResultSet rsSt = psSt.executeQuery();
            if (rsSt.next()) { totalOrders = rsSt.getInt("total_orders"); totalRevenue = rsSt.getDouble("my_revenue"); }
            rsSt.close(); psSt.close();

            PreparedStatement psP = conn.prepareStatement("SELECT COUNT(*) AS cnt FROM adprod WHERE "+emailCol+"=?");
            psP.setString(1, sellerEmail);
            ResultSet rsP = psP.executeQuery();
            if (rsP.next()) totalProducts = rsP.getInt("cnt");
            rsP.close(); psP.close();

            /* ════ DAILY chart ════ */
            Map<String,double[]> dailyMap = new LinkedHashMap<String,double[]>();
            Calendar cal = Calendar.getInstance();
            SimpleDateFormat sdfDay   = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat labelDay = new SimpleDateFormat("dd MMM");
            for (int i = 29; i >= 0; i--) {
                Calendar c = (Calendar) cal.clone(); c.add(Calendar.DAY_OF_YEAR, -i);
                dailyMap.put(sdfDay.format(c.getTime()), new double[]{0.0, 0.0});
            }
            PreparedStatement psD = conn.prepareStatement(
                "SELECT DATE(o.order_date) AS lbl, COALESCE(SUM(oi.item_total),0) AS rev, COUNT(DISTINCT o.order_id) AS cnt " +
                "FROM orders o JOIN order_items oi ON o.order_id=oi.order_id " +
                "JOIN adprod ap ON oi.product_id=ap.id " +
                "WHERE ap."+emailCol+"=? AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 29 DAY) " +
                "GROUP BY DATE(o.order_date) ORDER BY DATE(o.order_date) ASC");
            psD.setString(1, sellerEmail);
            ResultSet rsD = psD.executeQuery();
            while (rsD.next()) { String k=rsD.getString("lbl"); if(dailyMap.containsKey(k)){dailyMap.get(k)[0]=rsD.getDouble("rev");dailyMap.get(k)[1]=rsD.getInt("cnt");} }
            rsD.close(); psD.close();
            boolean df = true;
            for (Map.Entry<String,double[]> e : dailyMap.entrySet()) {
                try { String lab=labelDay.format(sdfDay.parse(e.getKey())); if(!df){dailyLabels.append(",");dailyRevenue.append(",");dailyOrders.append(",");}
                    dailyLabels.append("\"").append(lab).append("\""); dailyRevenue.append(String.format("%.2f",e.getValue()[0])); dailyOrders.append((int)e.getValue()[1]); df=false;
                } catch(Exception ig){}
            }

            /* ════ MONTHLY chart ════ */
            Map<String,double[]> monthMap = new LinkedHashMap<String,double[]>();
            SimpleDateFormat sdfMon=new SimpleDateFormat("yyyy-MM"); SimpleDateFormat labelMon=new SimpleDateFormat("MMM yy");
            for(int i=11;i>=0;i--){Calendar c=(Calendar)cal.clone();c.set(Calendar.DAY_OF_MONTH,1);c.add(Calendar.MONTH,-i);monthMap.put(sdfMon.format(c.getTime()),new double[]{0.0,0.0});}
            PreparedStatement psM=conn.prepareStatement("SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS lbl,COALESCE(SUM(oi.item_total),0) AS rev,COUNT(DISTINCT o.order_id) AS cnt FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=? AND o.order_date>=DATE_SUB(CURDATE(),INTERVAL 11 MONTH) GROUP BY DATE_FORMAT(o.order_date,'%Y-%m') ORDER BY lbl ASC");
            psM.setString(1,sellerEmail); ResultSet rsM=psM.executeQuery();
            while(rsM.next()){String k=rsM.getString("lbl");if(monthMap.containsKey(k)){monthMap.get(k)[0]=rsM.getDouble("rev");monthMap.get(k)[1]=rsM.getInt("cnt");}} rsM.close();psM.close();
            boolean mf=true;
            for(Map.Entry<String,double[]> e:monthMap.entrySet()){try{String lab=labelMon.format(sdfMon.parse(e.getKey()));if(!mf){monthlyLabels.append(",");monthlyRevenue.append(",");monthlyOrders.append(",");}monthlyLabels.append("\"").append(lab).append("\"");monthlyRevenue.append(String.format("%.2f",e.getValue()[0]));monthlyOrders.append((int)e.getValue()[1]);mf=false;}catch(Exception ig){}}

            /* ════ YEARLY chart ════ */
            Map<String,double[]> yearMap=new LinkedHashMap<String,double[]>();
            int curYear=Calendar.getInstance().get(Calendar.YEAR);
            for(int i=4;i>=0;i--)yearMap.put(String.valueOf(curYear-i),new double[]{0.0,0.0});
            PreparedStatement psY=conn.prepareStatement("SELECT YEAR(o.order_date) AS lbl,COALESCE(SUM(oi.item_total),0) AS rev,COUNT(DISTINCT o.order_id) AS cnt FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=? AND YEAR(o.order_date)>=YEAR(CURDATE())-4 GROUP BY YEAR(o.order_date) ORDER BY lbl ASC");
            psY.setString(1,sellerEmail); ResultSet rsY=psY.executeQuery();
            while(rsY.next()){String k=rsY.getString("lbl");if(yearMap.containsKey(k)){yearMap.get(k)[0]=rsY.getDouble("rev");yearMap.get(k)[1]=rsY.getInt("cnt");}} rsY.close();psY.close();
            boolean yf=true;
            for(Map.Entry<String,double[]> e:yearMap.entrySet()){if(!yf){yearlyLabels.append(",");yearlyRevenue.append(",");yearlyOrders.append(",");}yearlyLabels.append("\"").append(e.getKey()).append("\"");yearlyRevenue.append(String.format("%.2f",e.getValue()[0]));yearlyOrders.append((int)e.getValue()[1]);yf=false;}

            /* ════ Recent orders ════ */
            PreparedStatement psR=conn.prepareStatement("SELECT DISTINCT o.order_id,o.full_name,o.grand_total,o.order_status,o.order_date,o.source FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=? ORDER BY o.order_date DESC LIMIT 5");
            psR.setString(1,sellerEmail); ResultSet rsR=psR.executeQuery();
            while(rsR.next()){Map<String,String> row=new HashMap<String,String>();String oid=rsR.getString("order_id");row.put("order_id",oid);row.put("full_name",rsR.getString("full_name"));row.put("grand_total",String.format("%.0f",rsR.getDouble("grand_total")));row.put("order_status",rsR.getString("order_status"));row.put("order_date",rsR.getString("order_date"));PreparedStatement psPn=conn.prepareStatement("SELECT oi.product_name FROM order_items oi JOIN adprod ap ON oi.product_id=ap.id WHERE oi.order_id=? AND ap."+emailCol+"=? LIMIT 1");psPn.setString(1,oid);psPn.setString(2,sellerEmail);ResultSet rsPn=psPn.executeQuery();row.put("product_name",rsPn.next()?rsPn.getString("product_name"):"—");rsPn.close();psPn.close();recentOrders.add(row);} rsR.close();psR.close();

            /* ════ Recent activity ════ */
            PreparedStatement psA=conn.prepareStatement("SELECT DISTINCT o.order_id,o.order_status,o.order_date,o.full_name,oi.item_total FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN adprod ap ON oi.product_id=ap.id WHERE ap."+emailCol+"=? ORDER BY o.order_date DESC LIMIT 5");
            psA.setString(1,sellerEmail); ResultSet rsA=psA.executeQuery();
            while(rsA.next()){Map<String,String> act=new HashMap<String,String>();act.put("order_id",rsA.getString("order_id"));act.put("order_status",rsA.getString("order_status"));act.put("order_date",rsA.getString("order_date"));act.put("full_name",rsA.getString("full_name"));act.put("item_total",String.format("%.0f",rsA.getDouble("item_total")));recentActivity.add(act);} rsA.close();psA.close();

        } catch (Exception ex) { /* silent fallback */ }
        finally { try { if (conn!=null) conn.close(); } catch (Exception ig) {} }
    }

    /* ══════════════════════════════════════════════════════════════════════
       ROBUST RATINGS QUERY
       Strategy:
         1. Try exact match on seller_email column
         2. If zero results, try case-insensitive LOWER() match
         3. If still zero, try joining through adprod (seller owns the product)
         4. Collect debug info throughout to help diagnose mismatches
    ══════════════════════════════════════════════════════════════════════ */
    Connection rConn = null;
    try {
        Class.forName("com.mysql.jdbc.Driver");
        rConn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true",
            "root", "");

        /* ── STEP 1: Check if product_ratings table exists at all ── */
        boolean tableExists = false;
        try {
            PreparedStatement psCheck = rConn.prepareStatement(
                "SELECT COUNT(*) AS cnt FROM information_schema.tables " +
                "WHERE table_schema='multi_vendor' AND table_name='product_ratings'");
            ResultSet rsCheck = psCheck.executeQuery();
            if (rsCheck.next()) tableExists = rsCheck.getInt("cnt") > 0;
            rsCheck.close(); psCheck.close();
        } catch (Exception ex) {
            debugInfo += "Table check error: " + ex.getMessage() + "; ";
        }

        if (!tableExists) {
            ratingsQueryError = "Table 'product_ratings' does not exist yet. Run the CREATE TABLE SQL first.";
        } else {

            /* ── STEP 2: Count ALL rows in table + sample seller_emails ── */
            try {
                PreparedStatement psAll = rConn.prepareStatement(
                    "SELECT COUNT(*) AS cnt FROM product_ratings");
                ResultSet rsAll = psAll.executeQuery();
                if (rsAll.next()) totalRatingsInTable = rsAll.getInt("cnt");
                rsAll.close(); psAll.close();

                /* Get distinct seller_emails stored in the table */
                PreparedStatement psSample = rConn.prepareStatement(
                    "SELECT DISTINCT seller_email FROM product_ratings LIMIT 10");
                ResultSet rsSample = psSample.executeQuery();
                StringBuilder sb = new StringBuilder();
                while (rsSample.next()) {
                    if (sb.length() > 0) sb.append(", ");
                    sb.append("[").append(rsSample.getString("seller_email")).append("]");
                }
                sampleSellerEmails = sb.toString();
                rsSample.close(); psSample.close();
            } catch (Exception ex) {
                debugInfo += "Count error: " + ex.getMessage() + "; ";
            }

            /* ── STEP 3a: Try exact match first ── */
            boolean foundWithExact = false;
            try {
                PreparedStatement psAgg = rConn.prepareStatement(
                    "SELECT rating, COUNT(*) AS cnt " +
                    "FROM product_ratings " +
                    "WHERE seller_email = ? " +
                    "GROUP BY rating");
                psAgg.setString(1, sellerEmail);
                ResultSet rsAgg = psAgg.executeQuery();
                double rSum = 0;
                while (rsAgg.next()) {
                    int star = rsAgg.getInt("rating");
                    int cnt  = rsAgg.getInt("cnt");
                    if (star >= 1 && star <= 5) {
                        starCounts[star] += cnt;
                        rSum        += (double) star * cnt;
                        totalReviews += cnt;
                    }
                }
                rsAgg.close(); psAgg.close();
                if (totalReviews > 0) {
                    foundWithExact = true;
                    avgRating = rSum / totalReviews;
                    debugInfo += "Found with EXACT match. ";
                }
            } catch (Exception ex) {
                debugInfo += "Exact match error: " + ex.getMessage() + "; ";
            }

            /* ── STEP 3b: Try LOWER() case-insensitive match if exact failed ── */
            if (!foundWithExact && totalRatingsInTable > 0) {
                try {
                    PreparedStatement psAgg2 = rConn.prepareStatement(
                        "SELECT rating, COUNT(*) AS cnt " +
                        "FROM product_ratings " +
                        "WHERE LOWER(TRIM(seller_email)) = LOWER(TRIM(?)) " +
                        "GROUP BY rating");
                    psAgg2.setString(1, sellerEmail);
                    ResultSet rsAgg2 = psAgg2.executeQuery();
                    double rSum2 = 0; int tr2 = 0; int[] sc2 = new int[6];
                    while (rsAgg2.next()) {
                        int star = rsAgg2.getInt("rating");
                        int cnt  = rsAgg2.getInt("cnt");
                        if (star >= 1 && star <= 5) {
                            sc2[star] += cnt;
                            rSum2    += (double) star * cnt;
                            tr2      += cnt;
                        }
                    }
                    rsAgg2.close(); psAgg2.close();
                    if (tr2 > 0) {
                        totalReviews = tr2;
                        starCounts   = sc2;
                        avgRating    = rSum2 / tr2;
                        foundWithExact = true;
                        debugInfo += "Found with LOWER/TRIM match (case/space mismatch fixed). ";
                    }
                } catch (Exception ex) {
                    debugInfo += "Lower match error: " + ex.getMessage() + "; ";
                }
            }

            /* ── STEP 3c: If seller_email column in product_ratings stores seller_id
                           or product_id, try joining through adprod ── */
            if (!foundWithExact && totalRatingsInTable > 0 && emailCol != null) {
                try {
                    PreparedStatement psAgg3 = rConn.prepareStatement(
                        "SELECT pr.rating, COUNT(*) AS cnt " +
                        "FROM product_ratings pr " +
                        "JOIN adprod ap ON pr.product_id = ap.id " +
                        "WHERE ap." + emailCol + " = ? " +
                        "GROUP BY pr.rating");
                    psAgg3.setString(1, sellerEmail);
                    ResultSet rsAgg3 = psAgg3.executeQuery();
                    double rSum3 = 0; int tr3 = 0; int[] sc3 = new int[6];
                    while (rsAgg3.next()) {
                        int star = rsAgg3.getInt("rating");
                        int cnt  = rsAgg3.getInt("cnt");
                        if (star >= 1 && star <= 5) {
                            sc3[star] += cnt;
                            rSum3    += (double) star * cnt;
                            tr3      += cnt;
                        }
                    }
                    rsAgg3.close(); psAgg3.close();
                    if (tr3 > 0) {
                        totalReviews = tr3;
                        starCounts   = sc3;
                        avgRating    = rSum3 / tr3;
                        foundWithExact = true;
                        debugInfo += "Found via adprod JOIN (seller_email stored differently). ";
                    }
                } catch (Exception ex) {
                    debugInfo += "adprod join error: " + ex.getMessage() + "; ";
                }
            }

            /* ── STEP 4: Fetch review cards — try same 3-tier strategy ── */
            if (totalReviews > 0) {
                /* Build the right WHERE clause depending on which strategy succeeded */
                String whereClause;
                boolean useAdprodJoin = debugInfo.contains("adprod JOIN");

                if (useAdprodJoin) {
                    whereClause = "JOIN adprod ap ON pr.product_id = ap.id WHERE ap." + emailCol + " = ?";
                } else {
                    whereClause = "WHERE LOWER(TRIM(pr.seller_email)) = LOWER(TRIM(?))";
                }

                try {
                    String revSql =
                        "SELECT pr.product_name, pr.product_id, pr.rating, " +
                        "       pr.review_comment, pr.rated_at, pr.customer_email, " +
                        "       pr.order_id, " +
                        "       COALESCE(o.full_name, pr.customer_email) AS customer_name " +
                        "FROM product_ratings pr " +
                        "LEFT JOIN orders o ON pr.order_id = o.order_id " +
                        (useAdprodJoin ? "JOIN adprod ap ON pr.product_id = ap.id " : "") +
                        (useAdprodJoin
                            ? "WHERE ap." + emailCol + " = ? "
                            : "WHERE LOWER(TRIM(pr.seller_email)) = LOWER(TRIM(?)) ") +
                        "ORDER BY pr.rated_at DESC LIMIT 50";

                    PreparedStatement psRev = rConn.prepareStatement(revSql);
                    psRev.setString(1, sellerEmail);
                    ResultSet rsRev = psRev.executeQuery();
                    while (rsRev.next()) {
                        Map<String,String> rev = new HashMap<String,String>();
                        int star = rsRev.getInt("rating");
                        String rc = rsRev.getString("review_comment");
                        String ra = rsRev.getString("rated_at");
                        String cn = rsRev.getString("customer_name");
                        rev.put("product_name",    rsRev.getString("product_name"));
                        rev.put("product_id",      String.valueOf(rsRev.getInt("product_id")));
                        rev.put("order_id",        rsRev.getString("order_id") != null ? rsRev.getString("order_id") : "");
                        rev.put("rating",          String.valueOf(star));
                        rev.put("review_comment",  rc != null ? rc.trim() : "");
                        rev.put("rated_at",        ra != null ? ra : "");
                        rev.put("customer_name",   cn != null && !cn.trim().isEmpty() ? cn : "Customer");
                        rev.put("customer_email",  rsRev.getString("customer_email") != null ? rsRev.getString("customer_email") : "");
                        reviewList.add(rev);
                    }
                    rsRev.close(); psRev.close();
                } catch (Exception ex) {
                    ratingsQueryError += "Review fetch error: " + ex.getMessage();
                }
            }
        }

    } catch (Exception revEx) {
        ratingsQueryError = "Connection error: " + revEx.getMessage();
    } finally {
        try { if (rConn != null) rConn.close(); } catch (Exception ig) {}
    }

    String revenueDisplay;
    if      (totalRevenue >= 100000) revenueDisplay = "₹" + String.format("%.1f", totalRevenue/100000) + "L";
    else if (totalRevenue >= 1000)   revenueDisplay = "₹" + String.format("%.1f", totalRevenue/1000)   + "K";
    else                             revenueDisplay = "₹" + String.format("%.0f", totalRevenue);

    /* ── Show debug panel only if ratings exist in table but none shown ── */
    boolean showDebug = (totalRatingsInTable > 0 && totalReviews == 0)
                     || (request.getParameter("debug") != null);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seller Dashboard - MarketHub</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary:    #6366f1; --primary-dark:#4f46e5;
            --secondary:  #8b5cf6;
            --dark-bg:    #1e293b;
            --light-bg:   #F3F3F3;
            --success:    #10b981;
            --danger:     #ef4444;
            --warning:    #f59e0b;
            --star-color: #f59e0b;
            --info:       #06b6d4;
            --sidebar-bg: #0f172a;
            --sidebar-hov:#1e293b;
            --txt:        #0f172a;
            --txt-m:      #64748b;
            --border:     #e2e8f0;
        }
        *{margin:0;padding:0;box-sizing:border-box;}
        body{font-family:'Outfit',sans-serif;background:linear-gradient(135deg,#f0f4ff,#e5edff);min-height:100vh;overflow-x:hidden;}

        .sidebar{position:fixed;left:0;top:0;height:100vh;width:260px;background:var(--sidebar-bg);box-shadow:4px 0 20px rgba(0,0,0,.1);z-index:1000;overflow-y:auto;}
        .sidebar::-webkit-scrollbar{width:6px;}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.2);border-radius:3px;}
        .sidebar-header{padding:25px 20px;border-bottom:1px solid rgba(255,255,255,.1);background:linear-gradient(135deg,var(--dark-bg),#0f172a);}
        .sidebar-logo{color:white;font-size:24px;font-weight:800;text-decoration:none;display:flex;align-items:center;gap:12px;}
        .sidebar-logo i{color:var(--primary);font-size:28px;}
        .seller-badge{background:linear-gradient(135deg,var(--primary),var(--secondary));color:white;font-size:10px;padding:3px 8px;border-radius:12px;font-weight:700;}
        .sidebar-menu{padding:20px 0;}
        .menu-sec{color:rgba(255,255,255,.4);font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1.5px;padding:20px 20px 10px;}
        .sidebar-menu a{display:flex;align-items:center;padding:14px 20px;color:rgba(255,255,255,.8);text-decoration:none;transition:all .3s;position:relative;font-weight:500;margin:2px 10px;border-radius:8px;}
        .sidebar-menu a:hover,.sidebar-menu a.active{background:var(--sidebar-hov);color:white;padding-left:25px;}
        .sidebar-menu a.active::before{content:'';position:absolute;left:0;top:50%;transform:translateY(-50%);width:3px;height:70%;background:var(--primary);border-radius:0 3px 3px 0;}
        .sidebar-menu a i{font-size:18px;margin-right:15px;width:20px;text-align:center;transition:all .3s;}
        .sidebar-menu a:hover i,.sidebar-menu a.active i{color:var(--primary);transform:scale(1.1);}
        .sidebar-menu .badge{margin-left:auto;font-size:10px;padding:4px 8px;font-weight:700;}

        .main-content{margin-left:260px;min-height:100vh;}
        .top-navbar{background:white;padding:20px 30px;box-shadow:0 2px 15px rgba(0,0,0,.05);position:sticky;top:0;z-index:999;display:flex;justify-content:space-between;align-items:center;}
        .navbar-left h1{font-size:28px;font-weight:800;color:var(--txt);margin:0;}
        .navbar-left .bc{font-size:13px;color:var(--txt-m);margin:5px 0 0;}
        .navbar-right{display:flex;align-items:center;gap:20px;}
        .sel-prof{display:flex;align-items:center;gap:12px;padding:8px 15px;background:var(--light-bg);border-radius:12px;cursor:pointer;transition:all .3s;}
        .sel-prof:hover{background:var(--primary);color:white;}
        .sel-prof .pname{font-weight:700;font-size:14px;color:var(--txt);}
        .sel-prof:hover .pname,.sel-prof:hover .prole{color:white;}
        .sel-prof .prole{font-size:12px;color:var(--txt-m);}

        .dash-content{padding:30px;}
        .stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:25px;margin-bottom:30px;}
        .stat-card{background:white;border-radius:16px;padding:25px;box-shadow:0 4px 20px rgba(0,0,0,.04);transition:all .3s;position:relative;overflow:hidden;border:1px solid var(--border);opacity:0;animation:fadeInUp .6s ease forwards;}
        .stat-card:nth-child(1){animation-delay:.1s}.stat-card:nth-child(2){animation-delay:.2s}.stat-card:nth-child(3){animation-delay:.3s}.stat-card:nth-child(4){animation-delay:.4s}
        .stat-card:hover{transform:translateY(-5px);box-shadow:0 8px 30px rgba(0,0,0,.1);}
        .scard-hd{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:15px;}
        .scard-icon{width:55px;height:55px;border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:24px;background:linear-gradient(135deg,var(--sc),var(--sc2));color:white;box-shadow:0 6px 20px rgba(0,0,0,.15);}
        .scard-trend{padding:6px 12px;border-radius:20px;font-size:12px;font-weight:700;display:flex;align-items:center;gap:5px;}
        .scard-trend.up{background:rgba(16,185,129,.1);color:var(--success);}
        .scard-val{font-size:32px;font-weight:800;color:var(--txt);margin-bottom:5px;letter-spacing:-1px;}
        .scard-lbl{color:var(--txt-m);font-size:14px;font-weight:500;}
        .scard-ft{margin-top:15px;padding-top:15px;border-top:1px solid var(--border);font-size:13px;color:var(--txt-m);}

        .chart-card{background:white;border-radius:16px;padding:25px;box-shadow:0 4px 20px rgba(0,0,0,.04);border:1px solid var(--border);}
        .chart-hd{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:10px;}
        .chart-ttl{font-size:20px;font-weight:700;color:var(--txt);}
        .chart-acts{display:flex;gap:8px;}
        .btn-ch{padding:8px 18px;border:2px solid var(--border);background:white;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;transition:all .3s;color:var(--txt-m);font-family:'Outfit',sans-serif;}
        .btn-ch:hover,.btn-ch.active{border-color:var(--primary);background:var(--primary);color:white;}
        .chart-strip{display:flex;align-items:center;gap:16px;padding:12px 16px;background:linear-gradient(135deg,rgba(99,102,241,.04),rgba(139,92,246,.04));border-radius:12px;margin-bottom:16px;flex-wrap:wrap;}
        .cs-pill{display:flex;align-items:center;gap:8px;font-size:13px;font-weight:700;}
        .cs-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0;}
        .cs-pill.rev .cs-dot{background:var(--primary);}.cs-pill.ord .cs-dot{background:var(--success);}
        .cs-pill.rev{color:var(--primary);}.cs-pill.ord{color:var(--success);}
        .cs-period{margin-left:auto;font-size:12px;font-weight:600;color:var(--txt-m);}
        .canvas-wrap{position:relative;height:300px;}
        .no-data-ov{position:absolute;inset:0;display:none;flex-direction:column;align-items:center;justify-content:center;background:rgba(255,255,255,.93);border-radius:12px;z-index:10;}
        .no-data-ov i{font-size:52px;opacity:.2;margin-bottom:12px;color:var(--txt-m);}

        .act-list{list-style:none;padding:0;margin:0;}
        .act-item{display:flex;gap:15px;padding:15px 0;border-bottom:1px solid var(--border);transition:all .3s;}
        .act-item:last-child{border-bottom:none;}
        .act-item:hover{background:var(--light-bg);margin:0 -15px;padding:15px;border-radius:8px;}
        .act-ic{width:45px;height:45px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
        .act-ic.new{background:rgba(16,185,129,.1);color:var(--success);}.act-ic.shp{background:rgba(6,182,212,.1);color:var(--info);}
        .act-ic.dlv{background:rgba(16,185,129,.1);color:var(--success);}.act-ic.can{background:rgba(239,68,68,.1);color:var(--danger);}
        .act-ic.pnd{background:rgba(245,158,11,.1);color:var(--warning);}
        .act-det{flex:1;}.act-ttl{font-weight:600;color:var(--txt);font-size:14px;margin-bottom:3px;}
        .act-desc{font-size:13px;color:var(--txt-m);}.act-time{font-size:12px;color:var(--txt-m);white-space:nowrap;}

        .data-tbl{width:100%;border-collapse:separate;border-spacing:0;}
        .data-tbl thead th{background:var(--light-bg);padding:15px;text-align:left;font-weight:700;font-size:13px;text-transform:uppercase;letter-spacing:.5px;color:var(--txt-m);border-bottom:2px solid var(--border);}
        .data-tbl tbody td{padding:15px;border-bottom:1px solid var(--border);color:var(--txt);font-size:14px;}
        .data-tbl tbody tr:hover{background:var(--light-bg);}
        .sbadge{padding:6px 12px;border-radius:20px;font-size:12px;font-weight:700;display:inline-block;}
        .sbadge.pending{background:rgba(245,158,11,.1);color:var(--warning);}.sbadge.processing{background:rgba(6,182,212,.1);color:var(--info);}
        .sbadge.shipped{background:rgba(99,102,241,.1);color:var(--primary);}.sbadge.delivered,.sbadge.completed{background:rgba(16,185,129,.1);color:var(--success);}
        .sbadge.cancelled{background:rgba(239,68,68,.1);color:var(--danger);}

        .qacts{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;margin-top:30px;}
        .qact{background:white;border:2px dashed var(--border);border-radius:12px;padding:20px;text-align:center;cursor:pointer;transition:all .3s;text-decoration:none;color:var(--txt);}
        .qact:hover{border-color:var(--primary);border-style:solid;background:linear-gradient(135deg,rgba(99,102,241,.05),rgba(139,92,246,.1));transform:translateY(-3px);box-shadow:0 6px 20px rgba(99,102,241,.15);}
        .qact i{font-size:32px;color:var(--primary);margin-bottom:10px;display:block;}
        .qact span{display:block;font-weight:600;font-size:14px;}

        .empty-st{text-align:center;padding:40px 20px;color:var(--txt-m);}
        .empty-st i{font-size:48px;opacity:.25;margin-bottom:12px;display:block;}

        /* REVIEWS */
        .reviews-panel { margin-top: 30px; }
        .rating-overview {
            background: white; border-radius: 20px; padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,.06); border: 1px solid var(--border);
            margin-bottom: 24px; display: flex; align-items: center; gap: 40px; flex-wrap: wrap;
        }
        .rating-big { text-align: center; min-width: 140px; }
        .rating-big .num { font-size: 72px; font-weight: 800; color: var(--txt); line-height: 1; letter-spacing: -3px; }
        .rating-big .stars-display { color: var(--star-color); font-size: 22px; margin: 8px 0 6px; letter-spacing: 3px; }
        .rating-big .rev-count { font-size: 13px; font-weight: 600; color: var(--txt-m); }
        .rating-breakdown { flex: 1; min-width: 220px; }
        .rb-row { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }
        .rb-label { font-size: 13px; font-weight: 700; color: var(--txt-m); width: 50px; white-space: nowrap; }
        .rb-bar-wrap { flex: 1; background: var(--light-bg); border-radius: 6px; height: 10px; overflow: hidden; }
        .rb-bar { height: 100%; border-radius: 6px; background: linear-gradient(90deg, var(--star-color), #f97316); transition: width .8s ease; }
        .rb-count { font-size: 12px; font-weight: 700; color: var(--txt-m); width: 28px; text-align: right; }
        .rev-filters { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 20px; }
        .rev-filter-btn { padding: 8px 18px; border: 2px solid var(--border); border-radius: 20px; background: white; font-size: 13px; font-weight: 700; color: var(--txt-m); cursor: pointer; transition: all .25s; display: flex; align-items: center; gap: 6px; }
        .rev-filter-btn:hover,.rev-filter-btn.active { background: linear-gradient(135deg, var(--star-color), #f97316); color: white; border-color: transparent; box-shadow: 0 4px 14px rgba(245,158,11,.35); }
        .rev-filter-btn .star-i { color: var(--star-color); }
        .rev-filter-btn.active .star-i { color: white; }
        .review-card { background: white; border-radius: 16px; padding: 22px 24px; border: 1px solid var(--border); margin-bottom: 14px; transition: all .3s; position: relative; overflow: hidden; }
        .review-card::before { content: ''; position: absolute; left: 0; top: 0; width: 4px; height: 100%; background: linear-gradient(180deg, var(--star-color), #f97316); }
        .review-card:hover { box-shadow: 0 8px 30px rgba(0,0,0,.1); transform: translateY(-2px); }
        .rev-card-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; margin-bottom: 12px; }
        .rev-customer { display: flex; align-items: center; gap: 14px; }
        .rev-avatar { width: 44px; height: 44px; border-radius: 50%; background: linear-gradient(135deg, var(--primary), var(--secondary)); display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 18px; flex-shrink: 0; }
        .rev-cname { font-weight: 800; font-size: 15px; color: var(--txt); }
        .rev-product { font-size: 12px; font-weight: 600; color: var(--txt-m); margin-top: 2px; }
        .rev-product i { color: var(--primary); }
        .rev-meta { text-align: right; }
        .rev-stars { color: var(--star-color); font-size: 17px; letter-spacing: 2px; }
        .rev-date  { font-size: 12px; font-weight: 600; color: var(--txt-m); margin-top: 4px; }
        .rev-comment { font-size: 14px; font-weight: 500; color: var(--txt); line-height: 1.7; font-style: italic; padding: 12px 16px; background: linear-gradient(135deg, rgba(245,158,11,.04), rgba(249,115,22,.04)); border-radius: 10px; border-left: 3px solid rgba(245,158,11,.3); }
        .rev-comment.no-comment { color: var(--txt-m); font-size: 13px; }
        .empty-reviews { text-align: center; padding: 60px 20px; background: white; border-radius: 16px; border: 1px solid var(--border); }
        .empty-reviews i { font-size: 60px; color: var(--star-color); opacity: .25; display: block; margin-bottom: 16px; }
        .empty-reviews h4 { font-size: 20px; font-weight: 800; color: var(--txt); margin-bottom: 8px; }
        .empty-reviews p  { font-size: 14px; color: var(--txt-m); font-weight: 500; }

        /* DEBUG PANEL */
        .debug-panel {
            background: #1e293b;
            border-radius: 14px;
            padding: 20px 24px;
            margin-bottom: 24px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            color: #94a3b8;
            border: 1px solid #334155;
        }
        .debug-panel h5 { color: #f59e0b; font-size: 14px; margin-bottom: 12px; font-weight: 700; }
        .debug-panel .drow { margin-bottom: 6px; display: flex; gap: 10px; }
        .debug-panel .dkey { color: #6366f1; min-width: 180px; flex-shrink: 0; }
        .debug-panel .dval { color: #e2e8f0; word-break: break-all; }
        .debug-panel .dval.ok  { color: #10b981; }
        .debug-panel .dval.err { color: #ef4444; }
        .debug-panel .dval.warn{ color: #f59e0b; }
        .debug-toggle { background: none; border: 1px solid #334155; color: #94a3b8; border-radius: 8px; padding: 6px 14px; font-size: 12px; cursor: pointer; font-family: 'JetBrains Mono', monospace; margin-bottom: 16px; transition: all .2s; }
        .debug-toggle:hover { border-color: #f59e0b; color: #f59e0b; }

        @keyframes fadeInUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}
        @media(max-width:768px){
            .sidebar{width:70px;}.sidebar-header,.menu-sec,.sidebar-menu a span,.sidebar-menu .badge{display:none;}
            .sidebar-menu a{justify-content:center;padding:14px 10px;}.sidebar-menu a i{margin-right:0;}
            .main-content{margin-left:70px;}.navbar-left h1{font-size:20px;}
            .rating-overview{gap:20px;}.rating-big .num{font-size:52px;}
        }
    </style>
</head>
<body>

<aside class="sidebar">
    <div class="sidebar-header">
        <a href="#" class="sidebar-logo">
            <i class="fas fa-store"></i>
            <div>MarketHub <div class="seller-badge">SELLER</div></div>
        </a>
    </div>
    <nav class="sidebar-menu">
        <div class="menu-sec">Main Menu</div>
        <a href="sellerdashboard.jsp" class="active"><i class="fas fa-th-large"></i><span>Dashboard</span></a>
        <a href="Sellerorders.jsp"><i class="fas fa-shopping-cart"></i><span>My Orders</span>
            <% if (totalOrders > 0) { %><span class="badge bg-danger"><%= totalOrders %></span><% } %></a>
        <a href="viewproduct.jsp"><i class="fas fa-box"></i><span>My Products</span></a>
        <a href="addprod.jsp"><i class="fas fa-plus-circle"></i><span>Add Product</span></a>
        <a href="#"><i class="fas fa-warehouse"></i><span>Inventory</span><span class="badge bg-warning">Low</span></a>
        <div class="menu-sec">Sales &amp; Revenue</div>
        <a href="#"><i class="fas fa-star"></i><span>Reviews &amp; Ratings</span>
            <% if (totalReviews > 0) { %><span class="badge bg-warning text-dark"><%= totalReviews %></span><% } %></a>
        <a href="updatesellerprofile.jsp"><i class="fas fa-user-circle"></i><span>My Profile</span></a>
        <a href="ulogout"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
    </nav>
</aside>

<div class="main-content">
    <div class="top-navbar">
        <div class="navbar-left">
            <h1>Seller Dashboard</h1>
            <div class="bc"><i class="fas fa-home"></i> Home / Dashboard</div>
        </div>
        <div class="navbar-right">
            <div class="sel-prof" onclick="window.location='sellerprofile.jsp'">
                <div style="width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,var(--primary),var(--secondary));display:flex;align-items:center;justify-content:center;color:white;font-weight:700;font-size:16px;">
                    <%= (username!=null&&username.length()>0) ? String.valueOf(username.charAt(0)).toUpperCase() : "S" %>
                </div>
                <div>
                    <div class="pname"><%= username!=null ? username : "Your Store" %></div>
                    <div class="prole">Seller Account</div>
                </div>
                <i class="fas fa-chevron-down"></i>
            </div>
        </div>
    </div>

    <div class="dash-content">

        <!-- STATS -->
        <div class="stats-grid">
            <div class="stat-card" style="--sc:#10b981;--sc2:#059669;">
                <div class="scard-hd"><div class="scard-icon"><i class="fas fa-shopping-bag"></i></div><div class="scard-trend up"><i class="fas fa-arrow-up"></i> Live</div></div>
                <div class="scard-val"><%= totalOrders %></div><div class="scard-lbl">Total Orders</div>
                <div class="scard-ft"><i class="fas fa-calendar"></i> All time</div>
            </div>
            <div class="stat-card" style="--sc:#6366f1;--sc2:#4f46e5;">
                <div class="scard-hd"><div class="scard-icon"><i class="fas fa-rupee-sign"></i></div><div class="scard-trend up"><i class="fas fa-arrow-up"></i> Live</div></div>
                <div class="scard-val"><%= revenueDisplay %></div><div class="scard-lbl">Total Revenue</div>
                <div class="scard-ft"><i class="fas fa-calendar"></i> All time</div>
            </div>
            <div class="stat-card" style="--sc:#8b5cf6;--sc2:#7c3aed;">
                <div class="scard-hd"><div class="scard-icon"><i class="fas fa-box-open"></i></div><div class="scard-trend up"><i class="fas fa-arrow-up"></i> Live</div></div>
                <div class="scard-val"><%= totalProducts %></div><div class="scard-lbl">Products Listed</div>
                <div class="scard-ft"><i class="fas fa-box"></i> Active products</div>
            </div>
            <div class="stat-card" style="--sc:#f59e0b;--sc2:#d97706;">
                <div class="scard-hd"><div class="scard-icon"><i class="fas fa-star"></i></div><div class="scard-trend up"><i class="fas fa-arrow-up"></i></div></div>
                <div class="scard-val"><%= totalReviews > 0 ? String.format("%.1f", avgRating) : "—" %></div>
                <div class="scard-lbl">Store Rating</div>
                <div class="scard-ft"><i class="fas fa-users"></i> <%= totalReviews %> review<%= totalReviews != 1 ? "s" : "" %></div>
            </div>
        </div>

        <!-- CHART + ACTIVITY -->
        <div class="row g-4 mb-4">
            <div class="col-lg-8">
                <div class="chart-card">
                    <div class="chart-hd">
                        <div class="chart-ttl"><i class="fas fa-chart-area me-2" style="color:var(--primary);"></i>Sales Overview</div>
                        <div class="chart-acts">
                            <button class="btn-ch active" onclick="switchChart('week',this)"><i class="fas fa-calendar-week me-1"></i>Week</button>
                            <button class="btn-ch" onclick="switchChart('month',this)"><i class="fas fa-calendar-alt me-1"></i>Month</button>
                            <button class="btn-ch" onclick="switchChart('year',this)"><i class="fas fa-calendar me-1"></i>Year</button>
                        </div>
                    </div>
                    <div class="chart-strip">
                        <div class="cs-pill rev"><div class="cs-dot"></div>Revenue:&nbsp;<span id="pillRev">—</span></div>
                        <div class="cs-pill ord"><div class="cs-dot"></div>Orders:&nbsp;<span id="pillOrd">—</span></div>
                        <div class="cs-period" id="pillPeriod"></div>
                    </div>
                    <div class="canvas-wrap">
                        <canvas id="salesChart"></canvas>
                        <div class="no-data-ov" id="noDataOv">
                            <i class="fas fa-chart-bar"></i>
                            <p>No sales data for this period yet.</p>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="chart-card">
                    <div class="chart-hd"><div class="chart-ttl"><i class="fas fa-clock me-2" style="color:var(--secondary);"></i>Recent Activity</div></div>
                    <ul class="act-list">
<%
if (recentActivity.isEmpty()) {
%>      <li style="padding:30px 0;text-align:center;color:var(--txt-m);"><i class="fas fa-inbox" style="font-size:32px;opacity:.25;display:block;margin-bottom:8px;"></i><span style="font-size:13px;font-weight:600;">No activity yet</span></li>
<%
} else { for(Map<String,String> act:recentActivity){
    String as=act.getOrDefault("order_status","Pending"); String adate=act.getOrDefault("order_date","");
    String aoid=act.getOrDefault("order_id",""); String aamt=act.getOrDefault("item_total","0");
    String aic,aii,att,adc;
    if("Shipped".equalsIgnoreCase(as)){aic="shp";aii="fa-truck";att="Order Shipped";adc=aoid+" dispatched";}
    else if("Delivered".equalsIgnoreCase(as)){aic="dlv";aii="fa-check-circle";att="Order Delivered";adc=aoid+" completed";}
    else if("Processing".equalsIgnoreCase(as)){aic="new";aii="fa-shopping-cart";att="Order Processing";adc="Order "+aoid;}
    else if("Cancelled".equalsIgnoreCase(as)){aic="can";aii="fa-times-circle";att="Order Cancelled";adc="Order "+aoid;}
    else{aic="pnd";aii="fa-clock";att="New Order";adc="Order "+aoid;}
    String rt="";
    try{java.util.Date od=new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse(adate);long dm=(System.currentTimeMillis()-od.getTime())/60000;rt=dm<60?dm+"m ago":dm<1440?(dm/60)+"h ago":(dm/1440)+"d ago";}catch(Exception ex){rt=adate.length()>10?adate.substring(0,10):adate;}
%>
                        <li class="act-item">
                            <div class="act-ic <%= aic %>"><i class="fas <%= aii %>"></i></div>
                            <div class="act-det"><div class="act-ttl"><%= att %></div><div class="act-desc"><%= adc %> &bull; ₹<%= aamt %></div></div>
                            <div class="act-time"><%= rt %></div>
                        </li>
<%  }} %>
                    </ul>
                </div>
            </div>
        </div>

        <!-- RECENT ORDERS TABLE -->
        <div class="chart-card">
            <div class="chart-hd">
                <div class="chart-ttl"><i class="fas fa-list-alt me-2" style="color:var(--success);"></i>Recent Orders</div>
                <a href="Sellerorders.jsp" style="color:var(--primary);text-decoration:none;font-weight:600;font-size:14px;">View All <i class="fas fa-arrow-right ms-1"></i></a>
            </div>
<%
if (recentOrders.isEmpty()) {
%>          <div class="empty-st"><i class="fas fa-inbox"></i><p>No orders yet.</p></div>
<%} else {%>
            <div class="table-responsive">
                <table class="data-tbl">
                    <thead><tr><th>Order ID</th><th>Customer</th><th>Product</th><th>Amount</th><th>Status</th><th>Date</th><th>Action</th></tr></thead>
                    <tbody>
<%  for(Map<String,String> ord:recentOrders){
        String oid=ord.getOrDefault("order_id","—");String onam=ord.getOrDefault("full_name","—");String oprd=ord.getOrDefault("product_name","—");
        String otot=ord.getOrDefault("grand_total","0");String osta=ord.getOrDefault("order_status","Pending");
        String odat=ord.getOrDefault("order_date","—");if(odat.length()>10)odat=odat.substring(0,10);
        String sc=osta.toLowerCase().replaceAll("\\s","");if(!sc.matches("processing|shipped|delivered|cancelled|completed"))sc="pending";
%>          <tr><td><strong><%= oid %></strong></td><td><%= onam %></td><td><%= oprd.length()>28?oprd.substring(0,28)+"…":oprd %></td><td><strong>₹<%= otot %></strong></td><td><span class="sbadge <%= sc %>"><%= osta %></span></td><td><%= odat %></td><td><a href="Sellerorders.jsp" class="btn btn-sm btn-outline-primary" style="border-radius:8px;"><i class="fas fa-eye"></i></a></td></tr>
<%  } %>
                    </tbody>
                </table>
            </div>
<% } %>
        </div>

        <!-- ════════════════════════════════════════════════
             DIAGNOSTIC DEBUG PANEL
             Shows automatically when ratings exist in DB
             but aren't displaying, or when ?debug appended
        ════════════════════════════════════════════════ -->
        <% if (showDebug || !ratingsQueryError.isEmpty()) { %>
        <div class="reviews-panel">
            
        </div>
        <% } %>

        <!-- CUSTOMER REVIEWS & RATINGS SECTION -->
        <div class="reviews-panel">

            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:10px;">
                <div>
                    <h2 style="font-size:24px;font-weight:800;color:var(--txt);margin:0;">
                        <i class="fas fa-star me-2" style="color:var(--star-color);"></i>Customer Reviews
                    </h2>
                    <p style="font-size:14px;color:var(--txt-m);font-weight:500;margin:4px 0 0;">
                        What buyers are saying about your products
                    </p>
                </div>
                <% if (totalReviews > 0) { %>
                <div style="background:linear-gradient(135deg,rgba(245,158,11,.12),rgba(249,115,22,.12));padding:10px 20px;border-radius:12px;border:1px solid rgba(245,158,11,.25);">
                    <span style="font-size:13px;font-weight:700;color:var(--star-color);">
                        <i class="fas fa-star"></i> <%= String.format("%.1f", avgRating) %> avg &bull; <%= totalReviews %> total review<%= totalReviews!=1?"s":"" %>
                    </span>
                </div>
                <% } %>
            </div>

            <% if (totalReviews == 0) { %>
            <div class="empty-reviews">
                <i class="fas fa-star"></i>
                <h4>No Reviews Yet</h4>
                <% if (totalRatingsInTable > 0) { %>
                <p style="color:#ef4444;font-weight:700;">
                    ⚠ <%= totalRatingsInTable %> rating(s) exist in the database but none match your account.<br>
                    <span style="font-size:13px;font-weight:500;color:var(--txt-m);">
                        Check the Diagnostic Panel above — your session email may not match what was stored.
                    </span>
                </p>
                <% } else { %>
                <p>When customers rate their delivered orders, reviews will appear here.<br>Keep delivering great products to earn your first review!</p>
                <% } %>
                <a href="?debug=1" style="display:inline-block;margin-top:14px;font-size:13px;font-weight:700;color:var(--primary);text-decoration:none;border:1px solid var(--primary);padding:6px 16px;border-radius:8px;">
                    <i class="fas fa-bug"></i> Run Diagnostic
                </a>
            </div>

            <% } else { %>

            <!-- Rating Overview -->
            <div class="rating-overview">
                <div class="rating-big">
                    <div class="num"><%= String.format("%.1f", avgRating) %></div>
                    <div class="stars-display">
                        <%  int fullStars = (int) Math.round(avgRating);
                            for (int s = 1; s <= 5; s++) { %>
                        <i class="fas fa-star" style="<%= s > fullStars ? "color:#d1d5db;" : "" %>"></i>
                        <%  } %>
                    </div>
                    <div class="rev-count"><%= totalReviews %> review<%= totalReviews!=1?"s":"" %></div>
                </div>

                <div class="rating-breakdown">
                    <% for (int s = 5; s >= 1; s--) {
                           int cnt  = starCounts[s];
                           int pct  = totalReviews > 0 ? (int)((double)cnt/totalReviews*100) : 0;
                    %>
                    <div class="rb-row">
                        <span class="rb-label"><i class="fas fa-star" style="color:var(--star-color);font-size:11px;"></i> <%= s %></span>
                        <div class="rb-bar-wrap">
                            <div class="rb-bar" style="width:<%= pct %>%;"></div>
                        </div>
                        <span class="rb-count"><%= cnt %></span>
                    </div>
                    <% } %>
                </div>
            </div>

            <!-- Filter Pills + Sort -->
            <div style="display:flex;align-items:center;flex-wrap:wrap;gap:12px;margin-bottom:20px;">
                <div class="rev-filters" id="revFilters" style="margin-bottom:0;flex:1;min-width:0;">
                    <button class="rev-filter-btn active" onclick="filterReviews('all',this)">
                        <i class="fas fa-list"></i> All
                        <span style="background:rgba(0,0,0,.08);border-radius:10px;padding:1px 7px;font-size:11px;"><%= totalReviews %></span>
                    </button>
                    <% for (int s = 5; s >= 1; s--) { if (starCounts[s] > 0) { %>
                    <button class="rev-filter-btn" onclick="filterReviews('<%= s %>',this)">
                        <i class="fas fa-star star-i"></i> <%= s %> Star
                        <span style="background:rgba(0,0,0,.08);border-radius:10px;padding:1px 7px;font-size:11px;"><%= starCounts[s] %></span>
                    </button>
                    <% }} %>
                </div>
                <div style="display:flex;align-items:center;gap:8px;flex-shrink:0;">
                    <span style="font-size:13px;font-weight:700;color:var(--txt-m);">Sort:</span>
                    <select id="revSort" onchange="sortReviews(this.value)"
                        style="padding:8px 14px;border:2px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--txt);background:white;cursor:pointer;outline:none;">
                        <option value="newest">Newest First</option>
                        <option value="oldest">Oldest First</option>
                        <option value="highest">Highest Rating</option>
                        <option value="lowest">Lowest Rating</option>
                    </select>
                </div>
            </div>

            <!-- Review Cards -->
            <div id="reviewCards">
            <% for (Map<String,String> rev : reviewList) {
                   int rStar      = 0;
                   try { rStar = Integer.parseInt(rev.get("rating")); } catch(Exception ig){}
                   String rComment   = rev.get("review_comment");
                   String rProduct   = rev.get("product_name");
                   String rCust      = rev.get("customer_name");
                   String rEmail     = rev.get("customer_email");
                   String rOrderId   = rev.get("order_id");
                   String rDate      = rev.get("rated_at");
                   String rDateFmt   = rDate != null && rDate.length() >= 10 ? rDate.substring(0,10) : "—";
                   String avatarLet  = rCust != null && rCust.length() > 0 ? String.valueOf(rCust.charAt(0)).toUpperCase() : "C";
                   boolean hasComment = rComment != null && !rComment.trim().isEmpty();

                   String maskedEmail = "";
                   if (rEmail != null && rEmail.contains("@")) {
                       String[] ep = rEmail.split("@", 2);
                       String prefix = ep[0].length() > 3 ? ep[0].substring(0,3) + "***" : ep[0] + "***";
                       maskedEmail = prefix + "@" + ep[1];
                   }

                   String starColor = rStar >= 4 ? "#10b981" : rStar == 3 ? "#f59e0b" : "#ef4444";
            %>
            <div class="review-card" data-star="<%= rStar %>" data-date="<%= rDate != null ? rDate : "" %>">
                <div class="rev-card-top">
                    <div class="rev-customer">
                        <div class="rev-avatar" style="background:linear-gradient(135deg,<%= starColor %>,<%= starColor %>cc);">
                            <%= avatarLet %>
                        </div>
                        <div>
                            <div class="rev-cname">
                                <%= rCust %>
                                <span style="display:inline-flex;align-items:center;gap:4px;background:rgba(16,185,129,.1);color:#10b981;font-size:10px;font-weight:700;padding:2px 8px;border-radius:10px;margin-left:6px;">
                                    <i class="fas fa-check-circle" style="font-size:9px;"></i> Verified Purchase
                                </span>
                            </div>
                            <div class="rev-product" style="margin-top:3px;">
                                <i class="fas fa-tag"></i> <%= rProduct %>
                            </div>
                            <% if (!maskedEmail.isEmpty()) { %>
                            <div style="font-size:11px;color:var(--txt-m);margin-top:2px;font-weight:500;">
                                <i class="fas fa-envelope" style="font-size:10px;opacity:.6;"></i> <%= maskedEmail %>
                                <% if (rOrderId != null && !rOrderId.isEmpty()) { %>
                                &nbsp;&bull;&nbsp;<i class="fas fa-hashtag" style="font-size:10px;opacity:.6;"></i>
                                <span style="font-family:'JetBrains Mono',monospace;font-size:11px;"><%= rOrderId %></span>
                                <% } %>
                            </div>
                            <% } %>
                        </div>
                    </div>
                    <div class="rev-meta">
                        <div class="rev-stars">
                            <% for (int s=1; s<=5; s++) { %>
                            <i class="fas fa-star" style="color:<%= s <= rStar ? "var(--star-color)" : "#d1d5db" %>;"></i>
                            <% } %>
                        </div>
                        <div style="font-size:13px;font-weight:800;color:<%= starColor %>;margin-top:4px;">
                            <%= rStar %>/5
                        </div>
                        <div class="rev-date" style="margin-top:4px;">
                            <i class="fas fa-calendar-alt" style="font-size:10px;"></i> <%= rDateFmt %>
                        </div>
                    </div>
                </div>

                <div class="rev-comment <%= hasComment ? "" : "no-comment" %>">
                    <% if (hasComment) { %>
                        <i class="fas fa-quote-left" style="opacity:.25;margin-right:6px;font-size:12px;"></i><%= rComment %><i class="fas fa-quote-right" style="opacity:.25;margin-left:6px;font-size:12px;"></i>
                    <% } else { %>
                        <i class="fas fa-comment-slash" style="opacity:.3;"></i>&nbsp;No written review left
                    <% } %>
                </div>
            </div>
            <% } %>
            </div>
            <% } %>
        </div>

        <!-- QUICK ACTIONS -->
        <div class="qacts">
            <a href="addprod.jsp"            class="qact"><i class="fas fa-plus-circle"></i><span>Add New Product</span></a>
            <a href="#"                       class="qact"><i class="fas fa-warehouse"></i><span>Manage Inventory</span></a>
            <a href="Sellerorders.jsp"        class="qact"><i class="fas fa-shipping-fast"></i><span>Process Orders</span></a>
            <a href="#"                       class="qact"><i class="fas fa-chart-bar"></i><span>View Reports</span></a>
            <a href="updatesellerprofile.jsp" class="qact"><i class="fas fa-store-alt"></i><span>My Profile</span></a>
        </div>

    </div><!-- dash-content -->
</div><!-- main-content -->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
const chartData = {
    week:  { labels:[<%= dailyLabels %>],   revenue:[<%= dailyRevenue %>],   orders:[<%= dailyOrders %>],   period:"Last 30 Days" },
    month: { labels:[<%= monthlyLabels %>],  revenue:[<%= monthlyRevenue %>],  orders:[<%= monthlyOrders %>],  period:"Last 12 Months" },
    year:  { labels:[<%= yearlyLabels %>],   revenue:[<%= yearlyRevenue %>],   orders:[<%= yearlyOrders %>],   period:"Last 5 Years" }
};

function fmtRupee(v){if(v>=100000)return'₹'+(v/100000).toFixed(1)+'L';if(v>=1000)return'₹'+(v/1000).toFixed(1)+'K';return'₹'+Math.round(v).toLocaleString('en-IN');}
function sumArr(a){return a.reduce((s,x)=>s+parseFloat(x||0),0);}
function hasData(d){return d.revenue.some(v=>parseFloat(v||0)>0);}
function makeGrad(ctx,r,g,b){const gr=ctx.createLinearGradient(0,0,0,300);gr.addColorStop(0,`rgba(${r},${g},${b},0.40)`);gr.addColorStop(0.5,`rgba(${r},${g},${b},0.12)`);gr.addColorStop(1,`rgba(${r},${g},${b},0.00)`);return gr;}

let chart=null;
const canvas=document.getElementById('salesChart');
const ctx=canvas.getContext('2d');

function buildChart(mode){
    const d=chartData[mode];
    const noData=!hasData(d);
    document.getElementById('noDataOv').style.display=noData?'flex':'none';
    document.getElementById('pillRev').textContent=fmtRupee(sumArr(d.revenue));
    document.getElementById('pillOrd').textContent=Math.round(sumArr(d.orders))+' orders';
    document.getElementById('pillPeriod').textContent=d.period;
    const revData=d.revenue.map(v=>parseFloat(v||0));
    const ordData=d.orders.map(v=>parseFloat(v||0));
    const tooMany=d.labels.length>20;
    const cfg={data:{labels:d.labels,datasets:[{type:'line',label:'Revenue (₹)',data:revData,borderColor:'#6366f1',backgroundColor:makeGrad(ctx,99,102,241),borderWidth:2.5,pointBackgroundColor:'#6366f1',pointBorderColor:'#ffffff',pointRadius:d.labels.length<=14?5:3,pointHoverRadius:8,pointBorderWidth:2,tension:0.42,fill:true,yAxisID:'yRev',order:1},{type:'bar',label:'Orders',data:ordData,backgroundColor:'rgba(16,185,129,0.18)',borderColor:'rgba(16,185,129,0.55)',borderWidth:1.5,borderRadius:{topLeft:6,topRight:6},borderSkipped:false,yAxisID:'yOrd',order:2}]},options:{responsive:true,maintainAspectRatio:false,interaction:{mode:'index',intersect:false},animation:{duration:550},plugins:{legend:{display:false},tooltip:{backgroundColor:'rgba(15,23,42,0.93)',titleColor:'#e2e8f0',bodyColor:'#cbd5e1',padding:14,cornerRadius:12,titleFont:{family:'Outfit',size:13,weight:'700'},bodyFont:{family:'Outfit',size:12,weight:'500'},callbacks:{label(c){if(c.datasetIndex===0)return'  Revenue : ₹'+parseFloat(c.raw||0).toLocaleString('en-IN',{maximumFractionDigits:0});return'  Orders  : '+c.raw;}}}},scales:{x:{grid:{display:false},border:{display:false},ticks:{color:'#94a3b8',font:{family:'Outfit',size:tooMany?10:12},maxRotation:tooMany?40:0,autoSkip:true,maxTicksLimit:tooMany?12:undefined}},yRev:{position:'left',grid:{color:'rgba(226,232,240,0.65)'},border:{display:false},ticks:{color:'#6366f1',font:{family:'Outfit',size:11,weight:'600'},callback:v=>fmtRupee(v)},beginAtZero:true},yOrd:{position:'right',grid:{display:false},border:{display:false},ticks:{color:'#10b981',font:{family:'Outfit',size:11,weight:'600'},stepSize:1,callback:v=>(v%1===0)?v:''},beginAtZero:true}}}};
    if(chart)chart.destroy();
    chart=new Chart(ctx,cfg);
}

function switchChart(mode,btn){
    document.querySelectorAll('.btn-ch').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
    buildChart(mode);
}

buildChart('week');

/* Review filter + sort */
let activeStarFilter = 'all';
function filterReviews(star, btn) {
    document.querySelectorAll('.rev-filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeStarFilter = star;
    applyFilterAndSort();
}
function sortReviews(mode) { applyFilterAndSort(); }
function applyFilterAndSort() {
    const container = document.getElementById('reviewCards');
    if (!container) return;
    const cards = Array.from(container.querySelectorAll('.review-card'));
    const mode  = document.getElementById('revSort') ? document.getElementById('revSort').value : 'newest';
    cards.forEach(card => {
        const cs = card.getAttribute('data-star');
        card.style.display = (activeStarFilter === 'all' || cs === activeStarFilter) ? '' : 'none';
    });
    const visible = cards.filter(c => c.style.display !== 'none');
    visible.sort((a, b) => {
        const sa = parseInt(a.getAttribute('data-star') || '0');
        const sb = parseInt(b.getAttribute('data-star') || '0');
        const da = a.getAttribute('data-date') || '';
        const db = b.getAttribute('data-date') || '';
        if (mode === 'highest') return sb - sa;
        if (mode === 'lowest')  return sa - sb;
        if (mode === 'oldest')  return da.localeCompare(db);
        return db.localeCompare(da);
    });
    visible.forEach(c => container.appendChild(c));
}

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.rb-bar').forEach(bar => {
        const w = bar.style.width;
        bar.style.width = '0';
        setTimeout(() => { bar.style.width = w; }, 300);
    });
});
</script>
</body>
</html>
