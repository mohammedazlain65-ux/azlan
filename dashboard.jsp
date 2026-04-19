<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    dashboard.jsp
    Data is set as request attributes by OrderServlet (action=dashboard):
      - totalOrders   (Integer)
      - pendingCount  (Integer)
      - inTransitCount(Integer)
      - deliveredCount(Integer)
      - recentOrders  (List<String[]>)  each row: [trackingNum, customerName,
                                          customerContact, pickupDate, expectedDelivery,
                                          paymentType, status, statusBadgeClass, orderId]
      - agentName, agentCity, agentVehicleType (Strings from session via servlet)
    Redirect to login is handled by AuthFilter.
--%>
<%
    // Read servlet-provided attributes (fallback to 0 / empty if null)
    int totalOrders   = (request.getAttribute("totalOrders")    != null) ? (Integer) request.getAttribute("totalOrders")    : 0;
    int pendingCount  = (request.getAttribute("pendingCount")   != null) ? (Integer) request.getAttribute("pendingCount")   : 0;
    int inTransit     = (request.getAttribute("inTransitCount") != null) ? (Integer) request.getAttribute("inTransitCount") : 0;
    int delivered     = (request.getAttribute("deliveredCount") != null) ? (Integer) request.getAttribute("deliveredCount") : 0;

    String agentName    = (String) session.getAttribute("agentName");
    String agentCity    = (String) session.getAttribute("agentCity");
    String agentVehicle = (String) session.getAttribute("agentVehicleType");
    if (agentName    == null) agentName    = "Agent";
    if (agentCity    == null) agentCity    = "";
    if (agentVehicle == null) agentVehicle = "";

    @SuppressWarnings("unchecked")
    List<String[]> recentOrders = (List<String[]>) request.getAttribute("recentOrders");
    if (recentOrders == null) recentOrders = new ArrayList<>();
    int recentCount = Math.min(5, recentOrders.size());
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>

  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Dashboard</div>
      <div class="search-bar">
        <i class="fas fa-search" style="color:var(--text-muted);font-size:.85rem;"></i>
        <input type="text" placeholder="Search orders..." id="quickSearch"
               onkeydown="if(event.key==='Enter') location.href='${pageContext.request.contextPath}/orders?keyword='+this.value">
      </div>
      <button class="notif-btn" title="Notifications">
        <i class="fas fa-bell"></i><span class="notif-dot"></span>
      </button>
    </header>

    <main class="page-content">
      <!-- Welcome Banner -->
      <div style="background:linear-gradient(135deg,var(--navy) 0%,var(--navy-light) 100%);
                  border-radius:var(--radius-lg);padding:28px 32px;margin-bottom:28px;
                  display:flex;align-items:center;justify-content:space-between;
                  color:var(--white);overflow:hidden;position:relative;">
        <div style="position:absolute;right:-30px;top:-30px;width:200px;height:200px;background:rgba(244,112,27,.15);border-radius:50%;"></div>
        <div style="position:absolute;right:80px;bottom:-50px;width:140px;height:140px;background:rgba(0,180,216,.1);border-radius:50%;"></div>
        <div style="z-index:1;">
          <p style="color:rgba(255,255,255,.6);font-size:.85rem;margin-bottom:6px;">Welcome back,</p>
          <h2 style="font-family:var(--font-display);font-size:1.8rem;font-weight:800;margin-bottom:6px;">
            <%= agentName %> 👋
          </h2>
          <p style="color:rgba(255,255,255,.6);font-size:.9rem;">
            <i class="fas fa-map-marker-alt" style="color:var(--orange);"></i> <%= agentCity %>
            &nbsp;·&nbsp;
            <i class="fas fa-truck" style="color:var(--orange);"></i> <%= agentVehicle %> Agent
          </p>
        </div>
        <div style="z-index:1;text-align:right;">
          <div style="font-family:var(--font-display);font-size:2.6rem;font-weight:800;color:var(--orange);"><%= delivered %></div>
          <div style="font-size:.8rem;color:rgba(255,255,255,.55);text-transform:uppercase;letter-spacing:.5px;">Deliveries Completed</div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon orange"><i class="fas fa-boxes"></i></div>
          <div class="stat-info"><div class="stat-label">Total Orders</div><div class="stat-value"><%= totalOrders %></div><div class="stat-sub">All assigned orders</div></div>
        </div>
        <div class="stat-card">
          <div class="stat-icon navy"><i class="fas fa-clock"></i></div>
          <div class="stat-info"><div class="stat-label">Pending</div><div class="stat-value"><%= pendingCount %></div><div class="stat-sub">Awaiting action</div></div>
        </div>
        <div class="stat-card">
          <div class="stat-icon teal"><i class="fas fa-shipping-fast"></i></div>
          <div class="stat-info"><div class="stat-label">In Transit</div><div class="stat-value"><%= inTransit %></div><div class="stat-sub">Out for delivery</div></div>
        </div>
        <div class="stat-card">
          <div class="stat-icon green"><i class="fas fa-check-circle"></i></div>
          <div class="stat-info"><div class="stat-label">Delivered</div><div class="stat-value"><%= delivered %></div><div class="stat-sub" style="color:var(--green);">✓ Completed</div></div>
        </div>
      </div>

      <!-- Recent Orders -->
      <div class="card">
        <div class="card-header">
          <span class="card-title"><i class="fas fa-list" style="color:var(--orange);margin-right:8px;"></i>Recent Orders</span>
          <a href="${pageContext.request.contextPath}/orders" class="btn btn-outline btn-sm">View All</a>
        </div>
        <div class="data-table-wrap">
          <% if (recentCount == 0) { %>
            <div class="empty-state">
              <div class="empty-icon">📦</div>
              <h4>No orders yet</h4>
              <p>Check the Pickup Orders section to accept new deliveries.</p>
            </div>
          <% } else { %>
          <table class="data-table">
            <thead>
              <tr>
                <th>Tracking #</th><th>Customer</th><th>Pickup Date</th>
                <th>Expected</th><th>Payment</th><th>Status</th><th>Action</th>
              </tr>
            </thead>
            <tbody>
              <% for (int i = 0; i < recentCount; i++) {
                   String[] r = recentOrders.get(i);
                   // r[]: 0=tracking, 1=customerName, 2=customerContact,
                   //       3=pickupDate, 4=expectedDelivery, 5=paymentType,
                   //       6=status, 7=badgeClass, 8=orderId %>
              <tr>
                <td><strong style="font-family:var(--font-display);color:var(--navy);"><%= r[0] %></strong></td>
                <td>
                  <div style="font-weight:600;"><%= r[1] %></div>
                  <div style="font-size:.78rem;color:var(--text-muted);"><%= r[2] %></div>
                </td>
                <td><%= r[3] %></td>
                <td><%= r[4] %></td>
                <td><span class="pay-badge <%= "COD".equals(r[5]) ? "cod" : "prepaid" %>"><%= r[5] %></span></td>
                <td><span class="badge <%= r[7] %>"><%= r[6] %></span></td>
                <td>
                  <a href="${pageContext.request.contextPath}/orders?action=view&id=<%= r[8] %>"
                     class="btn btn-outline btn-sm"><i class="fas fa-eye"></i> View</a>
                </td>
              </tr>
              <% } %>
            </tbody>
          </table>
          <% } %>
        </div>
      </div>

      <!-- Quick Actions -->
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;margin-top:24px;">
        <a href="${pageContext.request.contextPath}/orders?action=pickup" class="card"
           style="padding:20px;display:flex;align-items:center;gap:14px;transition:transform var(--transition);"
           onmouseover="this.style.transform='translateY(-3px)'" onmouseout="this.style.transform=''">
          <div style="font-size:2rem;">📦</div>
          <div><div style="font-weight:700;color:var(--navy);">Pickup Orders</div><div style="font-size:.8rem;color:var(--text-muted);">Accept new orders</div></div>
        </a>
        <a href="${pageContext.request.contextPath}/orders?status=In+Transit" class="card"
           style="padding:20px;display:flex;align-items:center;gap:14px;transition:transform var(--transition);"
           onmouseover="this.style.transform='translateY(-3px)'" onmouseout="this.style.transform=''">
          <div style="font-size:2rem;">🚚</div>
          <div><div style="font-weight:700;color:var(--navy);">Active Deliveries</div><div style="font-size:.8rem;color:var(--text-muted);">Update status</div></div>
        </a>
        <a href="${pageContext.request.contextPath}/orders?action=track" class="card"
           style="padding:20px;display:flex;align-items:center;gap:14px;transition:transform var(--transition);"
           onmouseover="this.style.transform='translateY(-3px)'" onmouseout="this.style.transform=''">
          <div style="font-size:2rem;">🔍</div>
          <div><div style="font-weight:700;color:var(--navy);">Track Order</div><div style="font-size:.8rem;color:var(--text-muted);">Search by tracking #</div></div>
        </a>
        <a href="${pageContext.request.contextPath}/profile" class="card"
           style="padding:20px;display:flex;align-items:center;gap:14px;transition:transform var(--transition);"
           onmouseover="this.style.transform='translateY(-3px)'" onmouseout="this.style.transform=''">
          <div style="font-size:2rem;">👤</div>
          <div><div style="font-weight:700;color:var(--navy);">My Profile</div><div style="font-size:.8rem;color:var(--text-muted);">Edit info & password</div></div>
        </a>
      </div>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
document.addEventListener('click',function(e){
  const s=document.getElementById('sidebar'),h=document.querySelector('.hamburger');
  if(s&&s.classList.contains('open')&&!s.contains(e.target)&&h&&!h.contains(e.target))s.classList.remove('open');
});
document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('.alert').forEach(function(a){
    setTimeout(function(){a.style.transition='opacity 0.5s ease';a.style.opacity='0';setTimeout(function(){a.remove();},500);},5000);
  });
});
</script>
</body>
</html>
