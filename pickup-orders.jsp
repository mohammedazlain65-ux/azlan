<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    pickup-orders.jsp
    Request attributes set by OrderServlet (action=pickup):
      - pickupOrders (List<String[]>)  each row: [tracking, paymentType,
          sellerName, sellerAddress, sellerContact, customerName, customerAddress,
          customerContact, productDesc, weightKg, pickupDate, expectedDelivery,
          deliveryCharges, specialInstructions, orderId]
--%>
<%
    @SuppressWarnings("unchecked")
    List<String[]> pickupOrders = (List<String[]>) request.getAttribute("pickupOrders");
    if (pickupOrders == null) pickupOrders = new ArrayList<>();
    String flash = (String) session.getAttribute("flashSuccess");
    if (flash != null) session.removeAttribute("flashSuccess");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pickup Orders – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .pickup-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px}
    .pickup-card{background:var(--white);border-radius:var(--radius);border:1px solid var(--border);overflow:hidden;box-shadow:var(--shadow-card);transition:transform var(--transition),box-shadow var(--transition)}
    .pickup-card:hover{transform:translateY(-3px);box-shadow:var(--shadow-md)}
    .pickup-card-header{padding:14px 18px;background:var(--navy);display:flex;align-items:center;justify-content:space-between}
    .pickup-card-header .track-num{font-family:var(--font-display);font-size:.95rem;font-weight:700;color:var(--white)}
    .pickup-card-body{padding:18px}
    .pickup-row{display:flex;gap:12px;margin-bottom:14px}
    .pickup-section{flex:1}
    .pickup-section-label{font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--text-muted);margin-bottom:4px}
    .pickup-section-value{font-size:.88rem;font-weight:600;color:var(--navy)}
    .pickup-section-sub{font-size:.78rem;color:var(--text-secondary)}
    .pickup-product{background:var(--surface);border-radius:8px;padding:10px 14px;font-size:.85rem;color:var(--text-secondary);margin-bottom:14px}
    .pickup-actions{display:flex;gap:8px}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Pickup Orders</div>
      <a href="${pageContext.request.contextPath}/pages/pickup-form.jsp" class="btn btn-primary btn-sm">
        <i class="fas fa-plus"></i> New Order
      </a>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>Available Pickup Orders</h2>
        <p>Accept orders to start delivering. Orders are first-come, first-served.</p>
      </div>

      <% if (flash != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= flash %></div>
      <% } %>

      <% if (pickupOrders.isEmpty()) { %>
        <div class="card">
          <div class="empty-state">
            <div class="empty-icon">📭</div>
            <h4>No available orders</h4>
            <p>All pending orders have been assigned. Check back later or create a new order.</p><br>
            <a href="${pageContext.request.contextPath}/pages/pickup-form.jsp" class="btn btn-primary">
              <i class="fas fa-plus"></i> Create New Order
            </a>
          </div>
        </div>
      <% } else { %>
      <div class="pickup-grid">
        <% for (String[] r : pickupOrders) {
             // r[]: 0=tracking,1=paymentType,2=sellerName,3=sellerAddr,4=sellerContact,
             //       5=custName,6=custAddr,7=custContact,8=productDesc,9=weightKg,
             //       10=pickupDate,11=expectedDelivery,12=deliveryCharges,
             //       13=specialInstructions,14=orderId
        %>
        <div class="pickup-card fade-up">
          <div class="pickup-card-header">
            <span class="track-num"><i class="fas fa-hashtag" style="opacity:.6;margin-right:4px;"></i><%= r[0] %></span>
            <span class="pay-badge <%= "COD".equals(r[1]) ? "cod" : "prepaid" %>"><%= r[1] %></span>
          </div>
          <div class="pickup-card-body">
            <div class="pickup-row">
              <div class="pickup-section">
                <div class="pickup-section-label">📤 Pickup From</div>
                <div class="pickup-section-value"><%= r[2] %></div>
                <div class="pickup-section-sub"><%= r[3] %></div>
                <div class="pickup-section-sub"><i class="fas fa-phone" style="color:var(--orange);font-size:.7rem;"></i> <%= r[4] %></div>
              </div>
              <div class="pickup-section">
                <div class="pickup-section-label">📥 Deliver To</div>
                <div class="pickup-section-value"><%= r[5] %></div>
                <div class="pickup-section-sub"><%= r[6] %></div>
                <div class="pickup-section-sub"><i class="fas fa-phone" style="color:var(--orange);font-size:.7rem;"></i> <%= r[7] %></div>
              </div>
            </div>
            <div class="pickup-product">
              <i class="fas fa-box" style="color:var(--orange);margin-right:6px;"></i>
              <%= r[8] %> &nbsp;·&nbsp; <strong><%= r[9] %> kg</strong>
            </div>
            <div class="pickup-row" style="margin-bottom:10px;">
              <div class="pickup-section"><div class="pickup-section-label">Pickup Date</div><div class="pickup-section-value"><%= r[10] %></div></div>
              <div class="pickup-section"><div class="pickup-section-label">Expected By</div><div class="pickup-section-value"><%= r[11] %></div></div>
              <div class="pickup-section"><div class="pickup-section-label">Charges</div><div class="pickup-section-value" style="color:var(--orange);">₹<%= r[12] %></div></div>
            </div>
            <% if (r[13] != null && !r[13].isBlank()) { %>
            <div style="background:#fffbeb;border-radius:6px;padding:8px 12px;font-size:.8rem;color:#92400e;margin-bottom:12px;border-left:3px solid var(--yellow);">
              <i class="fas fa-exclamation-triangle" style="margin-right:4px;"></i><%= r[13] %>
            </div>
            <% } %>
            <div class="pickup-actions">
              <form action="${pageContext.request.contextPath}/orders" method="post" style="flex:1;">
                <input type="hidden" name="action" value="accept">
                <input type="hidden" name="orderId" value="<%= r[14] %>">
                <button type="submit" class="btn btn-success" style="width:100%;"><i class="fas fa-check"></i> Accept Order</button>
              </form>
              <a href="${pageContext.request.contextPath}/orders?action=view&id=<%= r[14] %>"
                 class="btn btn-outline btn-icon"><i class="fas fa-eye"></i></a>
            </div>
          </div>
        </div>
        <% } %>
      </div>
      <% } %>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('.alert').forEach(function(a){
    setTimeout(function(){a.style.transition='opacity 0.5s ease';a.style.opacity='0';setTimeout(function(){a.remove();},500);},5000);
  });
});
</script>
</body>
</html>
