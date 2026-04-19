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
    private void ensureAgentCols(Connection c) {
        String[] sqls = {
            "ALTER TABLE delivery_agents ADD COLUMN email VARCHAR(150) DEFAULT NULL",
            "ALTER TABLE delivery_agents ADD COLUMN password VARCHAR(255) DEFAULT NULL",
            "ALTER TABLE delivery_agents ADD COLUMN license_no VARCHAR(60) DEFAULT NULL",
            "ALTER TABLE delivery_agents MODIFY COLUMN agent_status ENUM('Active','Inactive','On Leave','Pending') DEFAULT 'Pending'"
        };
        for (String s : sqls) { try { c.createStatement().executeUpdate(s); } catch (Exception ig) {} }
    }
%>
<%
    if (session.getAttribute("agent_id") != null) { response.sendRedirect("travel_logistics.jsp"); return; }
    String msg = ""; boolean ok = false;
    String pName="",pEmail="",pPhone="",pZone="",pLic="",pVeh="Delivery Van";

    if ("POST".equals(request.getMethod())) {
        String nm=request.getParameter("agent_name"), em=request.getParameter("email"),
               ph=request.getParameter("phone"),     vt=request.getParameter("vehicle_type"),
               zn=request.getParameter("zone"),      pw=request.getParameter("password"),
               cp=request.getParameter("cpass"),     ln=request.getParameter("license_no");
        pName=nm!=null?nm:""; pEmail=em!=null?em:""; pPhone=ph!=null?ph:"";
        pZone=zn!=null?zn:""; pLic=ln!=null?ln:"";  pVeh=vt!=null?vt:"Delivery Van";

        if (nm==null||nm.trim().isEmpty()||em==null||em.trim().isEmpty()||ph==null||ph.trim().isEmpty()||pw==null||pw.trim().isEmpty()) {
            msg="Please fill in all required fields.";
        } else if (!pw.equals(cp)) { msg="Passwords do not match.";
        } else if (pw.length()<6)  { msg="Password must be at least 6 characters.";
        } else {
            Connection c=null; PreparedStatement ps=null; ResultSet rs=null;
            try {
                c=getConn(); ensureAgentCols(c);
                ps=c.prepareStatement("SELECT agent_id FROM delivery_agents WHERE email=? LIMIT 1");
                ps.setString(1,em.trim().toLowerCase()); rs=ps.executeQuery();
                if (rs.next()) { msg="Email already registered. Please login.";
                } else {
                    rs.close(); ps.close();
                    String nid=null;
                    for (int i=0;i<200;i++) {
                        String cand="MH-A"+(10+(int)(Math.random()*90));
                        ps=c.prepareStatement("SELECT 1 FROM delivery_agents WHERE agent_id=?");
                        ps.setString(1,cand); rs=ps.executeQuery();
                        if (!rs.next()) { nid=cand; rs.close(); ps.close(); break; }
                        rs.close(); ps.close();
                    }
                    if (nid==null) nid="MH-A"+(System.currentTimeMillis()%10000);
                    ps=c.prepareStatement("INSERT INTO delivery_agents (agent_id,agent_name,vehicle_type,total_deliveries,completed_deliveries,agent_status,phone,zone,email,password,license_no) VALUES (?,?,?,0,0,'Pending',?,?,?,?,?)");
                    ps.setString(1,nid); ps.setString(2,nm.trim()); ps.setString(3,vt!=null?vt:"Delivery Van");
                    ps.setString(4,ph.trim()); ps.setString(5,zn!=null?zn.trim():"");
                    ps.setString(6,em.trim().toLowerCase()); ps.setString(7,pw.trim());
                    ps.setString(8,ln!=null?ln.trim():"");
                    if (ps.executeUpdate()>0) {
                        msg="OK|Registration successful! Your Agent ID is <strong>"+nid+"</strong>. An admin will activate your account.";
                        ok=true; pName=pEmail=pPhone=pZone=pLic="";
                    }
                }
            } catch(Exception e){ msg="Error: "+e.getMessage();
            } finally {
                try{if(rs!=null)rs.close();}catch(Exception ig){}
                try{if(ps!=null)ps.close();}catch(Exception ig){}
                try{if(c!=null)c.close();}catch(Exception ig){}
            }
        }
    }
    boolean isOk=msg.startsWith("OK|"); String dMsg=isOk?msg.substring(3):msg;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Agent Register — MarketHub Logistics</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{--ink:#0b0f1a;--ink2:#1e2535;--slate:#64748b;--mist:#94a3b8;--border:#e2e8f0;--white:#ffffff;--accent:#3b82f6;--accent2:#6366f1;--success:#10b981;--danger:#ef4444;}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'DM Sans',sans-serif;min-height:100vh;background:linear-gradient(135deg,#0b0f1a 0%,#1e2535 55%,#0f172a 100%);display:flex;align-items:center;justify-content:center;padding:32px 16px;position:relative;overflow-x:hidden;}
body::before{content:'';position:fixed;inset:0;background:radial-gradient(ellipse at 15% 25%,rgba(59,130,246,.13) 0%,transparent 55%),radial-gradient(ellipse at 85% 75%,rgba(99,102,241,.10) 0%,transparent 55%);pointer-events:none;}
body::after{content:'';position:fixed;inset:0;background-image:linear-gradient(rgba(59,130,246,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(59,130,246,.04) 1px,transparent 1px);background-size:44px 44px;pointer-events:none;}
.wrap{width:100%;max-width:620px;position:relative;z-index:1;}
.brand{text-align:center;margin-bottom:24px;}
.brand a{display:inline-flex;align-items:center;gap:10px;font-family:'Syne',sans-serif;font-size:24px;font-weight:800;color:#fff;text-decoration:none;}
.brand-dot{width:10px;height:10px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 0 14px rgba(99,102,241,.6);}
.brand-sub{font-size:11.5px;color:rgba(255,255,255,.4);font-weight:600;letter-spacing:.6px;text-transform:uppercase;margin-top:6px;}
.steps{display:flex;align-items:center;margin-bottom:24px;}
.step-item{display:flex;flex-direction:column;align-items:center;gap:5px;flex:1;}
.step-dot{width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;}
.sd-active{background:linear-gradient(135deg,var(--accent),var(--accent2));}
.sd-idle{background:rgba(255,255,255,.12);color:rgba(255,255,255,.35);}
.step-lbl{font-size:10px;font-weight:700;color:rgba(255,255,255,.45);text-align:center;line-height:1.3;}
.step-line{flex:1;height:2px;background:rgba(255,255,255,.12);margin-bottom:22px;}
.card{background:rgba(255,255,255,.97);border-radius:22px;padding:34px 36px 30px;box-shadow:0 32px 80px rgba(0,0,0,.45);}
@media(max-width:500px){.card{padding:22px 18px;}}
.eyebrow{display:inline-flex;align-items:center;gap:7px;background:rgba(59,130,246,.08);border:1px solid rgba(59,130,246,.2);color:var(--accent);padding:5px 14px;border-radius:50px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;margin-bottom:12px;}
.card-title{font-family:'Syne',sans-serif;font-size:23px;font-weight:800;color:var(--ink);margin-bottom:5px;}
.card-sub{font-size:13px;color:var(--slate);margin-bottom:22px;line-height:1.5;}
.alert{padding:12px 15px;border-radius:10px;font-size:13px;font-weight:600;margin-bottom:16px;border-left:4px solid;display:flex;align-items:flex-start;gap:9px;line-height:1.5;}
.al-ok{background:#d1fae5;color:#065f46;border-color:var(--success);}
.al-err{background:#fee2e2;color:#991b1b;border-color:var(--danger);}
.sec-lbl{font-size:10.5px;font-weight:800;color:var(--mist);text-transform:uppercase;letter-spacing:1px;margin:18px 0 13px;padding-bottom:7px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:7px;}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:13px;}
@media(max-width:480px){.grid2{grid-template-columns:1fr;}}
.full{grid-column:1/-1;}
.fg{display:flex;flex-direction:column;gap:5px;}
.lbl{font-size:10.5px;font-weight:700;color:var(--slate);text-transform:uppercase;letter-spacing:.5px;}
.req{color:var(--danger);}
.iw{position:relative;}
.iw i{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:var(--mist);font-size:12px;pointer-events:none;}
.fc{width:100%;padding:10px 13px 10px 37px;border:2px solid var(--border);border-radius:10px;font-family:'DM Sans',sans-serif;font-size:13.5px;font-weight:500;color:var(--ink);background:#fff;transition:border-color .2s,box-shadow .2s;}
.fc:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 4px rgba(59,130,246,.1);}
.fc.plain{padding-left:13px;}
select.fc{cursor:pointer;}
.pw{position:relative;}
.pw .fc{padding-left:13px;padding-right:42px;}
.eye{position:absolute;right:12px;top:50%;transform:translateY(-50%);color:var(--mist);cursor:pointer;font-size:13px;transition:color .2s;}
.eye:hover{color:var(--accent);}
.info{background:rgba(59,130,246,.06);border:1px solid rgba(59,130,246,.15);border-radius:9px;padding:11px 13px;font-size:12px;color:#1e40af;margin:14px 0;display:flex;align-items:flex-start;gap:8px;line-height:1.5;}
.btn-sub{width:100%;padding:13px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border:none;border-radius:11px;font-family:'Syne',sans-serif;font-size:15px;font-weight:700;cursor:pointer;transition:all .25s;display:flex;align-items:center;justify-content:center;gap:8px;margin-top:6px;}
.btn-sub:hover{transform:translateY(-2px);box-shadow:0 10px 28px rgba(99,102,241,.4);}
.btn-go{display:inline-flex;align-items:center;gap:8px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;padding:11px 26px;border-radius:10px;font-weight:700;font-size:14px;text-decoration:none;}
.foot{text-align:center;margin-top:16px;font-size:13px;color:var(--slate);}
.foot a{color:var(--accent);font-weight:700;text-decoration:none;}
</style>
</head>
<body>
<div class="wrap">
  <div class="brand">
    <a href="index.jsp"><div class="brand-dot"></div>MarketHub</a>
    <div class="brand-sub">Logistics Management System</div>
  </div>

  <div class="steps">
    <div class="step-item"><div class="step-dot sd-active">1</div><div class="step-lbl">Register</div></div>
    <div class="step-line"></div>
    <div class="step-item"><div class="step-dot sd-idle">2</div><div class="step-lbl">Admin<br>Approval</div></div>
    <div class="step-line"></div>
    <div class="step-item"><div class="step-dot sd-idle">3</div><div class="step-lbl">Login &amp;<br>Work</div></div>
  </div>

  <div class="card">
    <div class="eyebrow"><i class="fas fa-truck-fast"></i> Delivery Agent Portal</div>
    <div class="card-title">Create Your Account</div>
    <div class="card-sub">Register to join the MarketHub delivery network. An admin will activate your account before you can log in.</div>

    <% if (!dMsg.isEmpty()) { %>
    <div class="alert <%= isOk?"al-ok":"al-err" %>">
      <i class="fas <%= isOk?"fa-check-circle":"fa-exclamation-circle" %>"></i>
      <span><%= dMsg %></span>
    </div>
    <% } %>

    <% if (isOk) { %>
      <div style="text-align:center;padding:8px 0 4px"><a href="agent_login.jsp" class="btn-go"><i class="fas fa-sign-in-alt"></i> Go to Login Page</a></div>
    <% } else { %>
    <form method="post" action="agent_register.jsp">
      <div class="sec-lbl"><i class="fas fa-user"></i> Personal Information</div>
      <div class="grid2">
        <div class="fg full">
          <label class="lbl">Full Name <span class="req">*</span></label>
          <div class="iw"><i class="fas fa-user"></i><input type="text" name="agent_name" class="fc" placeholder="e.g. Arjun Verma" required value="<%= pName.replace("\"","&quot;") %>"></div>
        </div>
        <div class="fg">
          <label class="lbl">Email Address <span class="req">*</span></label>
          <div class="iw"><i class="fas fa-envelope"></i><input type="email" name="email" class="fc" placeholder="you@email.com" required value="<%= pEmail.replace("\"","&quot;") %>"></div>
        </div>
        <div class="fg">
          <label class="lbl">Phone Number <span class="req">*</span></label>
          <div class="iw"><i class="fas fa-phone"></i><input type="text" name="phone" class="fc" placeholder="9900001234" required value="<%= pPhone.replace("\"","&quot;") %>"></div>
        </div>
      </div>

      <div class="sec-lbl"><i class="fas fa-truck"></i> Vehicle &amp; Zone</div>
      <div class="grid2">
        <div class="fg">
          <label class="lbl">Vehicle Type <span class="req">*</span></label>
          <div class="iw"><i class="fas fa-car"></i>
            <select name="vehicle_type" class="fc">
              <option value="Delivery Van"  <%= "Delivery Van".equals(pVeh)?"selected":"" %>>Delivery Van</option>
              <option value="Motorcycle"    <%= "Motorcycle".equals(pVeh)?"selected":"" %>>Motorcycle</option>
              <option value="Bicycle"       <%= "Bicycle".equals(pVeh)?"selected":"" %>>Bicycle</option>
              <option value="Mini Truck"    <%= "Mini Truck".equals(pVeh)?"selected":"" %>>Mini Truck</option>
            </select>
          </div>
        </div>
        <div class="fg">
          <label class="lbl">Delivery Zone <span class="req">*</span></label>
          <div class="iw"><i class="fas fa-map-marker-alt"></i><input type="text" name="zone" class="fc" placeholder="e.g. Bengaluru North" required value="<%= pZone.replace("\"","&quot;") %>"></div>
        </div>
        <div class="fg full">
          <label class="lbl">Driving License No.</label>
          <div class="iw"><i class="fas fa-id-card"></i><input type="text" name="license_no" class="fc" placeholder="KA0120180123456" value="<%= pLic.replace("\"","&quot;") %>"></div>
        </div>
      </div>

      <div class="sec-lbl"><i class="fas fa-lock"></i> Account Security</div>
      <div class="grid2">
        <div class="fg">
          <label class="lbl">Password <span class="req">*</span></label>
          <div class="pw"><input type="password" name="password" id="pw1" class="fc" placeholder="Min. 6 characters" required><span class="eye" onclick="tog('pw1',this)"><i class="fas fa-eye"></i></span></div>
        </div>
        <div class="fg">
          <label class="lbl">Confirm Password <span class="req">*</span></label>
          <div class="pw"><input type="password" name="cpass" id="pw2" class="fc" placeholder="Re-enter password" required><span class="eye" onclick="tog('pw2',this)"><i class="fas fa-eye"></i></span></div>
        </div>
      </div>

      <div class="info"><i class="fas fa-shield-alt"></i><span>After submitting, your account status will be <strong>Pending</strong>. You can log in only after an admin sets your status to <strong>Active</strong>.</span></div>
      <button type="submit" class="btn-sub"><i class="fas fa-paper-plane"></i> Submit Registration</button>
    </form>
    <% } %>

    <div class="foot">Already have an account? <a href="agent_login.jsp">Sign in</a> &nbsp;·&nbsp; <a href="adlogin.jsp">Admin Login</a></div>
  </div>
</div>
<script>
function tog(id,el){const i=document.getElementById(id),ic=el.querySelector('i');i.type=i.type==='password'?'text':'password';ic.className=i.type==='password'?'fas fa-eye':'fas fa-eye-slash';}
</script>
</body>
</html>
