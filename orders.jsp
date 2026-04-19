<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    orders.jsp  –  My Deliveries page
    Request attributes set by OrderServlet (action=list):
      - orders  (List<String[]>)  each row: [tracking, customerName, customerContact,
                  productDesc, weightKg, pickupDate, expectedDelivery, daysRemaining,
                  paymentType, deliveryCharges, status, badgeClass, orderId]
      - filter  (String)
      - keyword (String)
--%>
<%
    @SuppressWarnings("unchecked")
    List<String[]> orders = (List<String[]>) request.getAttribute("orders");
    if (orders == null) orders = new ArrayList<>();
    String currentFilter  = (String) request.getAttribute("filter");
    String currentKeyword = (String) request.getAttribute("keyword");
    if (currentFilter  == null) currentFilter  = "";
    if (currentKeyword == null) currentKeyword = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Deliveries – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .orders-toolbar{display:flex;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:20px}
    .search-input-bar{display:flex;align-items:center;gap:8px;background:var(--white);border:1.5px solid var(--border);border-radius:8px;padding:8px 14px;flex:1;min-width:200px;max-width:340px}
    .search-input-bar input{border:none;outline:none;background:none;font-family:var(--font-body);font-size:.88rem;width:100%}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">My Deliveries</div>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>My Deliveries</h2>
        <p>Manage and update the status of your assigned orders.</p>
      </div>

      <!-- Search + Filter -->
      <div class="orders-toolbar">
        <form action="${pageContext.request.contextPath}/orders" method="get"
              style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;width:100%;">
          <div class="search-input-bar">
            <i class="fas fa-search" style="color:var(--text-muted);font-size:.82rem;"></i>
            <input type="text" name="keyword" placeholder="Search tracking #, customer…" value="<%= currentKeyword %>">
          </div>
          <div class="filter-bar" style="margin:0;">
            <button type="submit" name="status" value=""          class="filter-chip <%= currentFilter.isEmpty()            ? "active" : "" %>">All</button>
            <button type="submit" name="status" value="Pending"   class="filter-chip <%= "Pending".equals(currentFilter)   ? "active" : "" %>">Pending</button>
            <button type="submit" name="status" value="Accepted"  class="filter-chip <%= "Accepted".equals(currentFilter)  ? "active" : "" %>">Accepted</button>
            <button type="submit" name="status" value="Picked Up" class="filter-chip <%= "Picked Up".equals(currentFilter) ? "active" : "" %>">Picked Up</button>
            <button type="submit" name="status" value="In Transit"class="filter-chip <%= "In Transit".equals(currentFilter)? "active" : "" %>">In Transit</button>
            <button type="submit" name="status" value="Out for Delivery" class="filter-chip <%= "Out for Delivery".equals(currentFilter) ? "active" : "" %>">Out for Delivery</button>
            <button type="submit" name="status" value="Delivered" class="filter-chip <%= "Delivered".equals(currentFilter) ? "active" : "" %>">Delivered</button>
          </div>
        </form>
      </div>

      <!-- Orders Table -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">
            <i class="fas fa-truck" style="color:var(--orange);margin-right:8px;"></i>
            Orders <span style="font-size:.8rem;font-weight:400;color:var(--text-muted);margin-left:6px;">(<%= orders.size() %> found)</span>
          </span>
        </div>
        <div class="data-table-wrap">
          <% if (orders.isEmpty()) { %>
            <div class="empty-state">
              <div class="empty-icon">📋</div>
              <h4>No orders found</h4>
              <p>Try adjusting your filter or search keyword.</p>
            </div>
          <% } else { %>
          <table class="data-table">
            <thead>
              <tr>
                <th>Tracking #</th><th>Customer</th><th>Product</th><th>Pickup</th>
                <th>Expected</th><th>Payment</th><th>Charges</th><th>Status</th><th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <% for (String[] r : orders) {
                   // r[]: 0=tracking,1=custName,2=custContact,3=productDesc,
                   //       4=weightKg,5=pickupDate,6=expectedDelivery,7=daysRemaining,
                   //       8=paymentType,9=deliveryCharges,10=status,11=badgeClass,12=orderId
                   int daysLeft = 0;
                   try { daysLeft = Integer.parseInt(r[7]); } catch(Exception e){}
              %>
              <tr>
                <td><strong style="font-family:var(--font-display);color:var(--navy);font-size:.9rem;"><%= r[0] %></strong></td>
                <td>
                  <div style="font-weight:600;font-size:.88rem;"><%= r[1] %></div>
                  <div style="font-size:.75rem;color:var(--text-muted);"><i class="fas fa-phone" style="font-size:.65rem;"></i> <%= r[2] %></div>
                </td>
                <td style="max-width:160px;">
                  <div style="font-size:.82rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:150px;" title="<%= r[3] %>"><%= r[3] %></div>
                  <div style="font-size:.74rem;color:var(--text-muted);"><%= r[4] %> kg</div>
                </td>
                <td style="font-size:.83rem;"><%= r[5] %></td>
                <td style="font-size:.83rem;">
                  <%= r[6] %>
                  <% if (!"Delivered".equals(r[10]) && daysLeft >= 0) { %>
                    <div style="font-size:.72rem;color:<%= daysLeft <= 1 ? "var(--red)" : "var(--teal)" %>;">
                      <%= daysLeft == 0 ? "Today!" : daysLeft + "d left" %>
                    </div>
                  <% } %>
                </td>
                <td><span class="pay-badge <%= "COD".equals(r[8]) ? "cod" : "prepaid" %>"><%= r[8] %></span></td>
                <td style="font-weight:600;color:var(--orange);">₹<%= r[9] %></td>
                <td><span class="badge <%= r[11] %>"><%= r[10] %></span></td>
                <td>
                  <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;">
                    <a href="${pageContext.request.contextPath}/orders?action=view&id=<%= r[12] %>"
                       class="btn btn-outline btn-sm"><i class="fas fa-eye"></i></a>
                    <% if ("Accepted".equals(r[10]) || "Pending".equals(r[10])) { %>
                      <button class="btn btn-danger btn-sm" onclick="rejectOrder(<%= r[12] %>)"><i class="fas fa-times"></i></button>
                    <% } %>
                    <% if (!"Delivered".equals(r[10]) && !"Rejected".equals(r[10])) { %>
                      <button class="btn btn-primary btn-sm" onclick="openStatusModal(<%= r[12] %>,'<%= r[10] %>')">
                        <i class="fas fa-sync-alt"></i> Update
                      </button>
                    <% } %>
                  </div>
                </td>
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

<!-- Status Update Modal -->
<div class="modal-overlay" id="statusModal">
  <div class="modal">
    <h3><i class="fas fa-sync-alt" style="color:var(--orange);margin-right:8px;"></i>Update Order Status</h3>
    <p style="color:var(--text-secondary);margin-bottom:18px;font-size:.9rem;">Select the new delivery status for this order.</p>
    <form action="${pageContext.request.contextPath}/orders" method="post" id="statusForm">
      <input type="hidden" name="action" value="updateStatus">
      <input type="hidden" name="orderId" id="modalOrderId">
      <div class="form-group" style="margin-bottom:14px;">
        <label class="form-label">New Status</label>
        <select name="newStatus" id="modalNewStatus" class="form-select" required></select>
      </div>
      <div class="form-group" style="margin-bottom:18px;">
        <label class="form-label">Remarks (Optional)</label>
        <textarea name="remarks" class="form-textarea" placeholder="Any notes about this update…"></textarea>
      </div>
      <div style="display:flex;gap:10px;">
        <button type="button" class="btn btn-outline" onclick="closeStatusModal()">Cancel</button>
        <button type="submit" class="btn btn-primary" style="flex:1;"><i class="fas fa-check"></i> Update Status</button>
      </div>
    </form>
  </div>
</div>

<!-- Reject Modal -->
<div class="modal-overlay" id="rejectModal">
  <div class="modal">
    <h3><i class="fas fa-times-circle" style="color:var(--red);margin-right:8px;"></i>Reject Order</h3>
    <p style="color:var(--text-secondary);margin-bottom:18px;font-size:.9rem;">Please provide a reason for rejecting this order.</p>
    <form action="${pageContext.request.contextPath}/orders" method="post">
      <input type="hidden" name="action" value="reject">
      <input type="hidden" name="orderId" id="rejectOrderId">
      <div class="form-group" style="margin-bottom:18px;">
        <label class="form-label">Reason</label>
        <textarea name="reason" class="form-textarea" required placeholder="e.g. Out of service area…"></textarea>
      </div>
      <div style="display:flex;gap:10px;">
        <button type="button" class="btn btn-outline" onclick="closeRejectModal()">Cancel</button>
        <button type="submit" class="btn btn-danger" style="flex:1;"><i class="fas fa-times"></i> Reject Order</button>
      </div>
    </form>
  </div>
</div>

<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
const STATUS_FLOW={
  'Pending':['Picked Up','In Transit','Out for Delivery','Delivered'],
  'Accepted':['Picked Up','In Transit','Out for Delivery','Delivered'],
  'Picked Up':['In Transit','Out for Delivery','Delivered'],
  'In Transit':['Out for Delivery','Delivered'],
  'Out for Delivery':['Delivered']
};
function openStatusModal(orderId,currentStatus){
  document.getElementById('modalOrderId').value=orderId;
  const sel=document.getElementById('modalNewStatus');
  const opts=STATUS_FLOW[currentStatus]||['Delivered'];
  const icons={'Picked Up':'📤','In Transit':'🚚','Out for Delivery':'🏃','Delivered':'✅'};
  sel.innerHTML=opts.map(s=>`<option value="${s}">${icons[s]||''} ${s}</option>`).join('');
  document.getElementById('statusModal').classList.add('open');
}
function closeStatusModal(){document.getElementById('statusModal').classList.remove('open');}
function rejectOrder(orderId){document.getElementById('rejectOrderId').value=orderId;document.getElementById('rejectModal').classList.add('open');}
function closeRejectModal(){document.getElementById('rejectModal').classList.remove('open');}
document.querySelectorAll('.modal-overlay').forEach(o=>o.addEventListener('click',e=>{if(e.target===o)o.classList.remove('open');}));
document.addEventListener('DOMContentLoaded',function(){
  document.querySelectorAll('.alert').forEach(function(a){
    setTimeout(function(){a.style.transition='opacity 0.5s ease';a.style.opacity='0';setTimeout(function(){a.remove();},500);},5000);
  });
});
</script>
</body>
</html>
