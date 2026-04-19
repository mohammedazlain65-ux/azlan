<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
    profile.jsp
    Agent info read from session attributes (set by LoginServlet & ProfileServlet):
      agentName, agentEmail, agentPhone, agentCity, agentVehicleType,
      agentLicenseNumber, agentAddress, agentRole, agentMemberSince
    Success/error messages set as request attributes by ProfileServlet.
--%>
<%
    String paName    = (String) session.getAttribute("agentName");
    String paEmail   = (String) session.getAttribute("agentEmail");
    String paPhone   = (String) session.getAttribute("agentPhone");
    String paCity    = (String) session.getAttribute("agentCity");
    String paVehicle = (String) session.getAttribute("agentVehicleType");
    String paLicense = (String) session.getAttribute("agentLicenseNumber");
    String paAddress = (String) session.getAttribute("agentAddress");
    String paRole    = (String) session.getAttribute("agentRole");
    String paSince   = (String) session.getAttribute("agentMemberSince");
    if (paName    == null) paName    = "";
    if (paEmail   == null) paEmail   = "";
    if (paPhone   == null) paPhone   = "";
    if (paCity    == null) paCity    = "";
    if (paVehicle == null) paVehicle = "";
    if (paLicense == null) paLicense = "";
    if (paAddress == null) paAddress = "";
    if (paRole    == null) paRole    = "AGENT";
    if (paSince   == null) paSince   = "—";

    String[] pts = paName.trim().split("\\s+");
    String initials = pts[0].length() > 0 ? pts[0].substring(0,1).toUpperCase() : "A";
    if (pts.length > 1) initials += pts[pts.length-1].substring(0,1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Profile – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .profile-layout{display:grid;grid-template-columns:300px 1fr;gap:24px}
    @media(max-width:900px){.profile-layout{grid-template-columns:1fr}}
    .profile-card{background:var(--white);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow-card);overflow:hidden;height:fit-content}
    .profile-hero{background:linear-gradient(135deg,var(--navy),var(--navy-light));padding:32px 24px;text-align:center}
    .avatar-big{width:80px;height:80px;border-radius:50%;background:var(--orange);margin:0 auto 12px;display:flex;align-items:center;justify-content:center;font-family:var(--font-display);font-size:2rem;font-weight:800;color:var(--white);border:4px solid rgba(255,255,255,.2)}
    .profile-name{font-family:var(--font-display);font-size:1.3rem;font-weight:700;color:var(--white)}
    .profile-role{color:var(--orange);font-size:.8rem;text-transform:uppercase;letter-spacing:.5px}
    .profile-detail-list{padding:16px}
    .pd-item{display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid var(--border)}
    .pd-item:last-child{border-bottom:none}
    .pd-icon{width:32px;height:32px;border-radius:8px;background:var(--orange-pale);display:flex;align-items:center;justify-content:center;color:var(--orange);font-size:.85rem}
    .pd-label{font-size:.72rem;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.3px}
    .pd-value{font-size:.88rem;color:var(--navy);font-weight:500}
    .tab-nav{display:flex;gap:0;border-bottom:2px solid var(--border);margin-bottom:24px}
    .tab-btn{padding:10px 20px;background:none;border:none;font-family:var(--font-body);font-size:.9rem;font-weight:600;color:var(--text-muted);cursor:pointer;border-bottom:3px solid transparent;margin-bottom:-2px;transition:all .2s}
    .tab-btn.active{color:var(--orange);border-bottom-color:var(--orange)}
    .tab-panel{display:none}
    .tab-panel.active{display:block}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">My Profile</div>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>Profile Settings</h2>
        <p>Manage your account information and security settings.</p>
      </div>
      <div class="profile-layout">
        <!-- Left Card -->
        <div>
          <div class="profile-card">
            <div class="profile-hero">
              <div class="avatar-big"><%= initials %></div>
              <div class="profile-name"><%= paName %></div>
              <div class="profile-role"><%= paRole %></div>
            </div>
            <div class="profile-detail-list">
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-envelope"></i></div><div><div class="pd-label">Email</div><div class="pd-value"><%= paEmail %></div></div></div>
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-phone"></i></div><div><div class="pd-label">Phone</div><div class="pd-value"><%= paPhone %></div></div></div>
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-map-marker-alt"></i></div><div><div class="pd-label">City</div><div class="pd-value"><%= paCity %></div></div></div>
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-truck"></i></div><div><div class="pd-label">Vehicle</div><div class="pd-value"><%= paVehicle %></div></div></div>
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-id-card"></i></div><div><div class="pd-label">License</div><div class="pd-value"><%= paLicense %></div></div></div>
              <div class="pd-item"><div class="pd-icon"><i class="fas fa-calendar"></i></div><div><div class="pd-label">Member Since</div><div class="pd-value"><%= paSince %></div></div></div>
            </div>
          </div>
        </div>
        <!-- Right Forms -->
        <div>
          <div class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('editProfile',this)"><i class="fas fa-user-edit"></i> Edit Profile</button>
            <button class="tab-btn" onclick="switchTab('changePassword',this)"><i class="fas fa-lock"></i> Change Password</button>
          </div>
          <!-- Edit Profile -->
          <div class="tab-panel active" id="tab-editProfile">
            <% if (request.getAttribute("success") != null) { %>
              <div class="alert alert-success"><i class="fas fa-check-circle"></i> ${success}</div>
            <% } %>
            <% if (request.getAttribute("error") != null) { %>
              <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> ${error}</div>
            <% } %>
            <form action="${pageContext.request.contextPath}/profile" method="post">
              <input type="hidden" name="action" value="updateProfile">
              <div class="form-grid">
                <div class="form-group"><label class="form-label">Full Name *</label><input type="text" name="fullName" class="form-input" value="<%= paName %>" required></div>
                <div class="form-group"><label class="form-label">Phone *</label><input type="tel" name="phone" class="form-input" value="<%= paPhone %>" required pattern="[6-9][0-9]{9}"></div>
                <div class="form-group"><label class="form-label">City *</label><input type="text" name="city" class="form-input" value="<%= paCity %>" required></div>
                <div class="form-group">
                  <label class="form-label">Vehicle Type *</label>
                  <select name="vehicleType" class="form-select" required>
                    <option value="Bike"  <%= "Bike" .equals(paVehicle) ? "selected" : "" %>>🏍️ Bike</option>
                    <option value="Van"   <%= "Van"  .equals(paVehicle) ? "selected" : "" %>>🚐 Van</option>
                    <option value="Truck" <%= "Truck".equals(paVehicle) ? "selected" : "" %>>🚛 Truck</option>
                  </select>
                </div>
                <div class="form-group full"><label class="form-label">Address *</label><textarea name="address" class="form-textarea" required><%= paAddress %></textarea></div>
                <div class="full" style="display:flex;justify-content:flex-end;">
                  <button type="submit" class="btn btn-primary"><i class="fas fa-save"></i> Save Changes</button>
                </div>
              </div>
            </form>
          </div>
          <!-- Change Password -->
          <div class="tab-panel" id="tab-changePassword">
            <% if (request.getAttribute("pwdSuccess") != null) { %>
              <div class="alert alert-success"><i class="fas fa-check-circle"></i> ${pwdSuccess}</div>
            <% } %>
            <% if (request.getAttribute("pwdError") != null) { %>
              <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> ${pwdError}</div>
            <% } %>
            <form action="${pageContext.request.contextPath}/profile" method="post" novalidate id="pwdForm">
              <input type="hidden" name="action" value="changePassword">
              <div class="form-grid" style="grid-template-columns:1fr;">
                <div class="form-group"><label class="form-label">Current Password *</label><div class="input-icon-wrap"><i class="fas fa-lock icon"></i><input type="password" name="currentPassword" id="cpwd0" class="form-input" placeholder="Your current password" required></div></div>
                <div class="form-group"><label class="form-label">New Password *</label><div class="input-icon-wrap"><i class="fas fa-key icon"></i><input type="password" name="newPassword" id="cpwd1" class="form-input" placeholder="At least 8 characters" required minlength="8"></div></div>
                <div class="form-group"><label class="form-label">Confirm New Password *</label><div class="input-icon-wrap"><i class="fas fa-key icon"></i><input type="password" name="confirmPassword" id="cpwd2" class="form-input" placeholder="Repeat new password" required></div></div>
                <div style="display:flex;justify-content:flex-end;"><button type="submit" class="btn btn-secondary"><i class="fas fa-lock"></i> Update Password</button></div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
function switchTab(tabId,btn){
  document.querySelectorAll('.tab-panel').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  document.getElementById('tab-'+tabId).classList.add('active');
  btn.classList.add('active');
}
document.getElementById('pwdForm').addEventListener('submit',function(e){
  if(document.getElementById('cpwd1').value!==document.getElementById('cpwd2').value){
    e.preventDefault();alert('New passwords do not match!');
  }
});
<% if (request.getAttribute("pwdError") != null || request.getAttribute("pwdSuccess") != null) { %>
document.addEventListener('DOMContentLoaded',()=>document.querySelectorAll('.tab-btn')[1].click());
<% } %>
document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('.alert').forEach(function(a){
    setTimeout(function(){a.style.transition='opacity 0.5s ease';a.style.opacity='0';setTimeout(function(){a.remove();},500);},5000);
  });
});
</script>
</body>
</html>
