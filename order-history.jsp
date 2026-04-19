<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    order-history.jsp
    Request attributes set by OrderServlet (action=history):
      - orders (List<String[]>)  each row: [tracking, customerName, customerContact,
                                  productDesc, expectedDelivery, paymentType,
                                  deliveryCharges, orderId]
--%>
<%
    @SuppressWarnings("unchecked")
    List<String[]> orders = (List<String[]>) request.getAttribute("orders");
    if (orders == null) orders = new ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order History – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Order History</div>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>Completed Deliveries</h2>
        <p>Your full delivery history — <%= orders.size() %> completed order(s).</p>
      </div>
      <div class="card">
        <div class="data-table-wrap">
          <% if (orders.isEmpty()) { %>
            <div class="empty-state">
              <div class="empty-icon">📋</div>
              <h4>No completed deliveries yet</h4>
              <p>Your completed deliveries will appear here.</p>
            </div>
          <% } else { %>
          <table class="data-table">
            <thead>
              <tr><th>Tracking #</th><th>Customer</th><th>Product</th><th>Delivered</th><th>Payment</th><th>Charges</th><th></th></tr>
            </thead>
            <tbody>
              <% for (String[] r : orders) {
                   // r[]: 0=tracking,1=custName,2=custContact,3=productDesc,
                   //       4=expectedDelivery,5=paymentType,6=deliveryCharges,7=orderId %>
              <tr>
                <td><strong style="font-family:var(--font-display);color:var(--navy);"><%= r[0] %></strong></td>
                <td>
                  <div style="font-weight:600;"><%= r[1] %></div>
                  <div style="font-size:.77rem;color:var(--text-muted);"><%= r[2] %></div>
                </td>
                <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:.83rem;"><%= r[3] %></td>
                <td style="font-size:.83rem;"><%= r[4] %></td>
                <td><span class="pay-badge <%= "COD".equals(r[5]) ? "cod" : "prepaid" %>"><%= r[5] %></span></td>
                <td style="font-weight:600;color:var(--orange);">₹<%= r[6] %></td>
                <td><a href="${pageContext.request.contextPath}/orders?action=view&id=<%= r[7] %>" class="btn btn-outline btn-sm"><i class="fas fa-eye"></i></a></td>
              </tr>
              <% } %>
            </tbody>
          </table>
          <% } %>
        </div>
      </div>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
</script>
</body>
</html>
