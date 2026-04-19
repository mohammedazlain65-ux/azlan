<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    admin-dashboard.jsp
    Request attributes set by AdminServlet:
      - totalOrders, pendingCount, inTransitCount, deliveredCount (Integer)
      - pendingOrders (List<String[]>): [tracking,custName,productDesc,pickupDate,charges,orderId]
      - allAgents    (List<String[]>): [agentId,fullName,email,phone,city,vehicleType,licenseNum,role,createdAt]
    Admin role guard is done by AuthFilter / servlet before forwarding here.
--%>
<%
    int total     = (request.getAttribute("totalOrders")    != null) ? (Integer)request.getAttribute("totalOrders")    : 0;
    int pending   = (request.getAttribute("pendingCount")   != null) ? (Integer)request.getAttribute("pendingCount")   : 0;
    int inTransit = (request.getAttribute("inTransitCount") != null) ? (Integer)request.getAttribute("inTransitCount") : 0;
    int delivered = (request.getAttribute("deliveredCount") != null) ? (Integer)request.getAttribute("deliveredCount") : 0;

    @SuppressWarnings("unchecked")
    List<String[]> pendingOrders = (List<String[]>) request.getAttribute("pendingOrders");
    if (pendingOrders == null) pendingOrders = new ArrayList<>();

    @SuppressWarnings("unchecked")
    List<String[]> allAgents = (List<String[]>) request.getAttribute("allAgents");
    if (allAgents == null) allAgents = new ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard - LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .agent-badge{display:inline-flex;align-items:center;gap:6px;background:var(--surface);border-radius:20px;padding:3px 10px;font-size:.78rem;font-weight:600;color:var(--navy);border:1px solid var(--border)}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Admin Panel</div>
      <span style="font-size:.8rem;background:var(--orange);color:var(--white);padding:4px 10px;border-radius:4px;font-weight:700;">ADMIN</span>
    </header>
    <main class="page-content">
      <div class="page-header"><h2>Admin Dashboard</h2><p>System-wide overview of all orders and agents.</p></div>

      <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon orange"><i class="fas fa-boxes"></i></div><div class="stat-info"><div class="stat-label">Total Orders</div><div class="stat-value"><%= total %></div></div></div>
        <div class="stat-card"><div class="stat-icon navy"><i class="fas fa-hourglass-half"></i></div><div class="stat-info"><div class="stat-label">Pending</div><div class="stat-value"><%= pending %></div></div></div>
        <div class="stat-card"><div class="stat-icon teal"><i class="fas fa-shipping-fast"></i></div><div class="stat-info"><div class="stat-label">In Transit</div><div class="stat-value"><%= inTransit %></div></div></div>
        <div class="stat-card"><div class="stat-icon green"><i class="fas fa-check-double"></i></div><div class="stat-info"><div class="stat-label">Delivered</div><div class="stat-value"><%= delivered %></div></div></div>
      </div>

      <!-- Assign Pending Orders -->
      <div class="card" style="margin-bottom:24px;">
        <div class="card-header">
          <span class="card-title"><i class="fas fa-user-plus" style="color:var(--orange);margin-right:8px;"></i>Assign Orders to Agents (<%= pending %> pending)</span>
        </div>
        <div class="data-table-wrap">
          <% if (pendingOrders.isEmpty()) { %>
            <div class="empty-state" style="padding:30px;"><div class="empty-icon">checkmark</div><h4>All orders assigned!</h4></div>
          <% } else { %>
          <table class="data-table">
            <thead><tr><th>Tracking #</th><th>Customer</th><th>Product</th><th>Pickup Date</th><th>Charges</th><th>Assign To Agent</th></tr></thead>
            <tbody>
              <% for (String[] r : pendingOrders) { %>
              <tr>
                <td><strong style="font-family:var(--font-display)"><%= r[0] %></strong></td>
                <td><%= r[1] %></td>
                <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><%= r[2] %></td>
                <td><%= r[3] %></td>
                <td style="color:var(--orange);font-weight:600;">Rs.<%= r[4] %></td>
                <td>
                  <form action="${pageContext.request.contextPath}/admin/assign" method="post" style="display:flex;gap:8px;align-items:center;">
                    <input type="hidden" name="orderId" value="<%= r[5] %>">
                    <select name="agentId" class="form-select" style="min-width:160px;padding:6px 10px;font-size:.82rem;" required>
                      <option value="">Select agent...</option>
                      <% for (String[] ag : allAgents) {
                           if ("AGENT".equals(ag[7])) { %>
                        <option value="<%= ag[0] %>"><%= ag[1] %> (<%= ag[5] %>)</option>
                      <% } } %>
                    </select>
                    <button type="submit" class="btn btn-primary btn-sm"><i class="fas fa-paper-plane"></i> Assign</button>
                  </form>
                </td>
              </tr>
              <% } %>
            </tbody>
          </table>
          <% } %>
        </div>
      </div>

      <!-- All Agents -->
      <div class="card">
        <div class="card-header"><span class="card-title"><i class="fas fa-users" style="color:var(--orange);margin-right:8px;"></i>All Agents (<%= allAgents.size() %>)</span></div>
        <div class="data-table-wrap">
          <table class="data-table">
            <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Phone</th><th>City</th><th>Vehicle</th><th>License</th><th>Role</th><th>Joined</th></tr></thead>
            <tbody>
              <% int rowNum=1; for (String[] ag : allAgents) {
                   String vIcon="Bike".equals(ag[5])?"Bike":"Van".equals(ag[5])?"Van":"Truck"; %>
              <tr>
                <td style="color:var(--text-muted);"><%= rowNum++ %></td>
                <td style="font-weight:600;"><%= ag[1] %></td>
                <td style="font-size:.83rem;"><%= ag[2] %></td>
                <td><%= ag[3] %></td>
                <td><%= ag[4] %></td>
                <td><span class="agent-badge"><%= vIcon %> <%= ag[5] %></span></td>
                <td style="font-size:.82rem;font-family:var(--font-display);"><%= ag[6] %></td>
                <td><span class="badge <%= "ADMIN".equals(ag[7])?"badge-transit":"badge-pending" %>"><%= ag[7] %></span></td>
                <td style="font-size:.8rem;color:var(--text-muted);"><%= ag[8]!=null?ag[8]:"--" %></td>
              </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('form').forEach(function(form){
    form.addEventListener('submit',function(){
      const btn=form.querySelector('button[type="submit"]');
      if(btn){btn.disabled=true;const h=btn.innerHTML;btn.innerHTML='<i class="fas fa-spinner fa-spin"></i> Processing...';setTimeout(function(){btn.disabled=false;btn.innerHTML=h;},8000);}
    });
  });
});
</script>
</body>
</html>
