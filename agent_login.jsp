<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="java.sql.*" %>
<%!
    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";
    private Connection getConn() throws Exception {
        Class.forName("com.mysql.jdbc.Driver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }
%>
<%
    if (session.getAttribute("agent_id") != null) { response.sendRedirect("travel_logistics.jsp"); return; }
    String msg = ""; boolean isWarn = false;

    if ("POST".equals(request.getMethod())) {
        String email = request.getParameter("email");
        String pass  = request.getParameter("password");
        if (email==null||email.trim().isEmpty()||pass==null||pass.trim().isEmpty()) {
            msg = "Email and password are required.";
        } else {
            Connection c=null; PreparedStatement ps=null; ResultSet rs=null;
            try {
                c = getConn();
                ps = c.prepareStatement(
                    "SELECT agent_id,agent_name,agent_status,zone,vehicle_type,phone FROM delivery_agents WHERE email=? AND password=? LIMIT 1");
                ps.setString(1,email.trim().toLowerCase());
                ps.setString(2,pass.trim());
                rs = ps.executeQuery();
                if (!rs.next()) {
                    msg = "Invalid email or password.";
                } else {
                    String aid   = rs.getString("agent_id");
                    String aname = rs.getString("agent_name");
                    String astat = rs.getString("agent_status");
                    String azone = rs.getString("zone");
                    String aveh  = rs.getString("vehicle_type");
                    String aph   = rs.getString("phone");
                    if ("Pending".equals(astat)) {
                        msg = "Your account is <strong>pending admin approval</strong>. Please wait for activation.";
                        isWarn = true;
                    } else if ("Inactive".equals(astat)) {
                        msg = "Your account has been <strong>deactivated</strong>. Contact admin support.";
                    } else {
                        /* Active or On Leave — allow login */
                        session.setAttribute("agent_id",    aid);
                        session.setAttribute("agent_name",  aname);
                        session.setAttribute("agent_status",astat);
                        session.setAttribute("agent_zone",  azone);
                        session.setAttribute("agent_vehicle",aveh);
                        session.setAttribute("agent_phone", aph);
                        session.setAttribute("agent_email", email.trim().toLowerCase());
                        session.setAttribute("email",       email.trim().toLowerCase());
                        session.setAttribute("role",        "agent");
                        response.sendRedirect("travel_logistics.jsp"); return;
                    }
                }
            } catch (Exception e) {
                if (e.getMessage()!=null&&e.getMessage().contains("Unknown column")) {
                    msg = "Login columns missing — please run the DB migration SQL first.";
                } else { msg = "Login error: "+e.getMessage(); }
            } finally {
                try{if(rs!=null)rs.close();}catch(Exception ig){}
                try{if(ps!=null)ps.close();}catch(Exception ig){}
                try{if(c!=null)c.close();}catch(Exception ig){}
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Agent Login — MarketHub Logistics</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{--ink:#0b0f1a;--ink2:#1e2535;--slate:#64748b;--mist:#94a3b8;--border:#e2e8f0;--white:#ffffff;--accent:#3b82f6;--accent2:#6366f1;--success:#10b981;--danger:#ef4444;--warning:#f59e0b;}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'DM Sans',sans-serif;min-height:100vh;background:linear-gradient(135deg,#0b0f1a 0%,#1e2535 55%,#0f172a 100%);display:grid;grid-template-columns:1fr 1fr;position:relative;overflow:hidden;}
@media(max-width:800px){body{grid-template-columns:1fr;}}
body::before{content:'';position:fixed;inset:0;background:radial-gradient(ellipse at 20% 30%,rgba(59,130,246,.14) 0%,transparent 55%),radial-gradient(ellipse at 80% 70%,rgba(99,102,241,.10) 0%,transparent 55%);pointer-events:none;}
body::after{content:'';position:fixed;inset:0;background-image:linear-gradient(rgba(59,130,246,.03) 1px,transparent 1px),linear-gradient(90deg,rgba(59,130,246,.03) 1px,transparent 1px);background-size:48px 48px;pointer-events:none;}

/* LEFT */
.left{display:flex;flex-direction:column;justify-content:center;padding:60px 48px;position:relative;z-index:1;}
@media(max-width:800px){.left{display:none;}}
.left-logo{display:flex;align-items:center;gap:10px;margin-bottom:56px;text-decoration:none;}
.logo-dot{width:12px;height:12px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 0 16px rgba(99,102,241,.6);}
.logo-name{font-family:'Syne',sans-serif;font-size:22px;font-weight:800;color:#fff;}
.left-tag{display:inline-flex;align-items:center;gap:7px;background:rgba(59,130,246,.12);border:1px solid rgba(59,130,246,.2);color:rgba(255,255,255,.7);padding:5px 14px;border-radius:50px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;margin-bottom:18px;}
.left-h1{font-family:'Syne',sans-serif;font-size:40px;font-weight:800;color:#fff;line-height:1.1;margin-bottom:14px;}
.left-h1 span{background:linear-gradient(135deg,#60a5fa,#a78bfa);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;}
.left-p{font-size:14.5px;color:rgba(255,255,255,.5);line-height:1.7;max-width:400px;margin-bottom:38px;}
.feat-list{display:flex;flex-direction:column;gap:13px;}
.feat{display:flex;align-items:center;gap:13px;}
.feat-ico{width:40px;height:40px;border-radius:10px;background:rgba(59,130,246,.15);border:1px solid rgba(59,130,246,.2);display:flex;align-items:center;justify-content:center;color:#60a5fa;font-size:15px;flex-shrink:0;}
.feat-txt{font-size:13px;color:rgba(255,255,255,.65);font-weight:500;line-height:1.4;}
.feat-txt strong{color:#fff;font-weight:700;}

/* RIGHT */
.right{display:flex;flex-direction:column;justify-content:center;align-items:center;padding:40px 32px;position:relative;z-index:1;min-height:100vh;}
@media(max-width:800px){.right{padding:32px 16px;justify-content:flex-start;padding-top:40px;}}
.mobile-brand{display:none;text-align:center;margin-bottom:28px;}
@media(max-width:800px){.mobile-brand{display:block;}}
.mobile-brand a{font-family:'Syne',sans-serif;font-size:22px;font-weight:800;color:#fff;text-decoration:none;display:inline-flex;align-items:center;gap:8px;}
.mb-dot{width:9px;height:9px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));}
.mb-sub{font-size:11px;color:rgba(255,255,255,.4);margin-top:4px;text-transform:uppercase;letter-spacing:.5px;}

.card{width:100%;max-width:420px;background:rgba(255,255,255,.97);border-radius:22px;padding:38px 34px;box-shadow:0 32px 80px rgba(0,0,0,.5);}
.eyebrow{display:inline-flex;align-items:center;gap:7px;background:rgba(59,130,246,.08);border:1px solid rgba(59,130,246,.18);color:var(--accent);padding:5px 14px;border-radius:50px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;margin-bottom:12px;}
.card-title{font-family:'Syne',sans-serif;font-size:24px;font-weight:800;color:var(--ink);margin-bottom:5px;}
.card-sub{font-size:13px;color:var(--slate);margin-bottom:24px;}
.alert{padding:11px 14px;border-radius:9px;font-size:13px;font-weight:600;margin-bottom:16px;border-left:4px solid;display:flex;align-items:flex-start;gap:8px;line-height:1.5;}
.al-err{background:#fee2e2;color:#991b1b;border-color:var(--danger);}
.al-warn{background:#fef3c7;color:#92400e;border-color:var(--warning);}
.fg{margin-bottom:15px;}
.lbl{display:block;font-size:10.5px;font-weight:700;color:var(--slate);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
.iw{position:relative;}
.iw i{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:var(--mist);font-size:12px;pointer-events:none;}
.fc{width:100%;padding:11px 13px 11px 37px;border:2px solid var(--border);border-radius:10px;font-family:'DM Sans',sans-serif;font-size:14px;font-weight:500;color:var(--ink);background:#fff;transition:border-color .2s,box-shadow .2s;}
.fc:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 4px rgba(59,130,246,.1);}
.pw{position:relative;}
.pw .fc{padding-left:13px;padding-right:42px;}
.eye{position:absolute;right:12px;top:50%;transform:translateY(-50%);color:var(--mist);cursor:pointer;font-size:13px;transition:color .2s;}
.eye:hover{color:var(--accent);}
.btn-sub{width:100%;padding:13px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border:none;border-radius:11px;font-family:'Syne',sans-serif;font-size:15px;font-weight:700;cursor:pointer;transition:all .25s;display:flex;align-items:center;justify-content:center;gap:8px;margin-top:4px;}
.btn-sub:hover{transform:translateY(-2px);box-shadow:0 10px 28px rgba(99,102,241,.4);}
.divider{display:flex;align-items:center;gap:10px;margin:18px 0;}
.divider::before,.divider::after{content:'';flex:1;height:1px;background:var(--border);}
.divider span{font-size:11.5px;color:var(--mist);font-weight:600;}
.other-link{display:flex;align-items:center;gap:8px;padding:10px 14px;border-radius:9px;font-size:13px;font-weight:600;text-decoration:none;transition:all .2s;margin-bottom:8px;}
.ol-admin{background:rgba(245,158,11,.08);border:1px solid rgba(245,158,11,.2);color:#92400e;}
.ol-admin:hover{background:rgba(245,158,11,.15);}
.ol-admin i{color:var(--warning);}
.ol-seller{background:rgba(99,102,241,.08);border:1px solid rgba(99,102,241,.2);color:#4c1d95;}
.ol-seller:hover{background:rgba(99,102,241,.14);}
.ol-seller i{color:var(--accent2);}
.ol-buyer{background:rgba(16,185,129,.08);border:1px solid rgba(16,185,129,.2);color:#065f46;}
.ol-buyer:hover{background:rgba(16,185,129,.14);}
.ol-buyer i{color:var(--success);}
.ol-arr{margin-left:auto;font-size:11px;opacity:.5;}
.foot{text-align:center;margin-top:14px;font-size:13px;color:var(--slate);}
.foot a{color:var(--accent);font-weight:700;text-decoration:none;}
</style>
</head>
<body>

<!-- LEFT PANEL -->
<div class="left">
  <a href="index.jsp" class="left-logo"><div class="logo-dot"></div><span class="logo-name">MarketHub</span></a>
  <div class="left-tag"><i class="fas fa-truck-fast"></i> Delivery Agent Portal</div>
  <h1 class="left-h1">Your deliveries.<br><span>On your terms.</span></h1>
  <p class="left-p">Join the MarketHub delivery fleet. Accept orders from sellers, complete deliveries, and track every shipment in real-time.</p>
  <div class="feat-list">
    <div class="feat"><div class="feat-ico"><i class="fas fa-boxes-stacked"></i></div><div class="feat-txt"><strong>View Assigned Orders</strong> — See all shipments assigned to you</div></div>
    <div class="feat"><div class="feat-ico"><i class="fas fa-check-double"></i></div><div class="feat-txt"><strong>Mark Delivered / Cancelled</strong> — Update delivery status instantly</div></div>
    <div class="feat"><div class="feat-ico"><i class="fas fa-rotate-left"></i></div><div class="feat-txt"><strong>Handle Returns</strong> — Process approved return pickups</div></div>
    <div class="feat"><div class="feat-ico"><i class="fas fa-chart-bar"></i></div><div class="feat-txt"><strong>Performance Dashboard</strong> — Track your delivery metrics</div></div>
  </div>
</div>

<!-- RIGHT PANEL -->
<div class="right">
  <div class="mobile-brand">
    <a href="index.jsp"><div class="mb-dot"></div>MarketHub</a>
    <div class="mb-sub">Logistics Management System</div>
  </div>

  <div class="card">
    <div class="eyebrow"><i class="fas fa-user-tie"></i> Agent Login</div>
    <div class="card-title">Welcome back</div>
    <div class="card-sub">Sign in to your delivery agent account to continue.</div>

    <% if (!msg.isEmpty()) { %>
    <div class="alert <%= isWarn?"al-warn":"al-err" %>">
      <i class="fas <%= isWarn?"fa-clock":"fa-exclamation-circle" %>"></i>
      <span><%= msg %></span>
    </div>
    <% } %>

    <form method="post" action="agent_login.jsp">
      <div class="fg">
        <label class="lbl">Email Address</label>
        <div class="iw"><i class="fas fa-envelope"></i><input type="email" name="email" class="fc" placeholder="agent@email.com" required autocomplete="email"
          value="<%= request.getParameter("email")!=null?request.getParameter("email").replace("\"","&quot;"):"" %>"></div>
      </div>
      <div class="fg">
        <label class="lbl">Password</label>
        <div class="pw"><input type="password" name="password" id="pw" class="fc" placeholder="Enter your password" required autocomplete="current-password">
          <span class="eye" onclick="tog()"><i class="fas fa-eye" id="ei"></i></span></div>
      </div>
      <button type="submit" class="btn-sub"><i class="fas fa-sign-in-alt"></i> Sign In to Dashboard</button>
    </form>

    <div class="divider"><span>OTHER PORTALS</span></div>
    <a href="adlogin.jsp"     class="other-link ol-admin"><i class="fas fa-shield-alt"></i> Admin Panel Login <i class="fas fa-arrow-right ol-arr"></i></a>
    <a href="slogin.jsp"      class="other-link ol-seller"><i class="fas fa-store"></i> Seller Login <i class="fas fa-arrow-right ol-arr"></i></a>
    <a href="ulogin.jsp"      class="other-link ol-buyer"><i class="fas fa-user"></i> Customer Login <i class="fas fa-arrow-right ol-arr"></i></a>

    <div class="foot">New agent? <a href="agent_register.jsp">Register here</a></div>
  </div>
</div>

<script>
function tog(){const i=document.getElementById('pw'),ic=document.getElementById('ei');i.type=i.type==='password'?'text':'password';ic.className=i.type==='password'?'fas fa-eye':'fas fa-eye-slash';}
</script>
</body>
</html>
