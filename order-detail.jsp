<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    order-detail.jsp
    Request attributes set by OrderServlet (action=view):
      - orderData (String[]) – [tracking, createdAt, agentName, status, badgeClass,
                                 paymentType, sellerName, sellerAddr, sellerContact,
                                 custName, custAddr, custContact, productDesc, weightKg,
                                 pickupDate, expectedDelivery, specialNotes, deliveryCharges,
                                 isPaid, orderId, agentId, currentStepIndex]
      - statusHistory (List<String[]>) – each: [status, changedAt, agentName, remarks, dotClass]
      - canUpdate  (Boolean) – true if session agent owns this order and it's not complete
      - nextStatuses (String[]) – valid next statuses for update
--%>
<%
    String[] od = (String[]) request.getAttribute("orderData");
    if (od == null) { response.sendRedirect(request.getContextPath() + "/orders"); return; }

    int curIdx = -1;
    try { curIdx = Integer.parseInt(od[21]); } catch(Exception e){}
    String[] steps = {"Pending","Accepted","Picked Up","In Transit","Out for Delivery","Delivered"};

    @SuppressWarnings("unchecked")
    List<String[]> history = (List<String[]>) request.getAttribute("statusHistory");
    if (history == null) history = new ArrayList<>();

    boolean canUpdate = Boolean.TRUE.equals(request.getAttribute("canUpdate"));
    String[] nextStatuses = (String[]) request.getAttribute("nextStatuses");
    if (nextStatuses == null) nextStatuses = new String[]{};
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Order <%= od[0] %> – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px}
    @media(max-width:768px){.detail-grid{grid-template-columns:1fr}}
    .info-block{background:var(--white);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow-card);overflow:hidden}
    .info-block-header{padding:12px 18px;background:var(--surface);border-bottom:1px solid var(--border);font-family:var(--font-display);font-size:.9rem;font-weight:700;color:var(--navy)}
    .info-block-body{padding:16px 18px}
    .info-row{display:flex;justify-content:space-between;align-items:flex-start;padding:8px 0;border-bottom:1px solid var(--border)}
    .info-row:last-child{border-bottom:none}
    .info-key{font-size:.8rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.3px}
    .info-val{font-size:.9rem;font-weight:500;color:var(--navy);text-align:right;max-width:60%}
    .progress-dot{width:36px;height:36px;border-radius:50%;border:3px solid var(--border);background:var(--white);display:flex;align-items:center;justify-content:center;font-size:.85rem;z-index:1}
    .progress-dot.done{background:var(--green);border-color:var(--green);color:var(--white)}
    .progress-dot.active{background:var(--orange);border-color:var(--orange);color:var(--white);box-shadow:0 0 0 5px rgba(244,112,27,.2)}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Order Details</div>
      <a href="${pageContext.request.contextPath}/orders" class="btn btn-outline btn-sm"><i class="fas fa-arrow-left"></i> Back</a>
    </header>
    <main class="page-content">

      <!-- Order Header -->
      <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:24px;">
        <div>
          <h2 style="font-family:var(--font-display);font-size:1.6rem;font-weight:800;color:var(--navy);"><%= od[0] %></h2>
          <p style="color:var(--text-secondary);font-size:.88rem;">
            Created: <%= od[1] %> &nbsp;·&nbsp; Agent: <%= od[2] != null ? od[2] : "Unassigned" %>
          </p>
        </div>
        <div style="display:flex;align-items:center;gap:10px;">
          <span class="badge <%= od[4] %>" style="font-size:.85rem;padding:7px 14px;"><%= od[3] %></span>
          <span class="pay-badge <%= "COD".equals(od[5]) ? "cod" : "prepaid" %>" style="font-size:.85rem;"><%= od[5] %></span>
        </div>
      </div>

      <!-- Progress Tracker -->
      <div class="card" style="margin-bottom:20px;">
        <div class="card-header"><span class="card-title">📍 Delivery Progress</span></div>
        <div class="card-body">
          <div style="display:flex;align-items:center;overflow-x:auto;padding:8px 0;">
            <% for (int i = 0; i < steps.length; i++) {
                 boolean done   = i < curIdx;
                 boolean active = i == curIdx; %>
              <% if (i > 0) { %><div style="height:3px;flex:1;background:<%= i<=curIdx?"var(--green)":"var(--border)" %>;"></div><% } %>
              <div style="display:flex;flex-direction:column;align-items:center;gap:6px;min-width:80px;">
                <div class="progress-dot <%= done?"done":(active?"active":"") %>">
                  <% if (done) { %><i class="fas fa-check"></i>
                  <% } else if (active) { %><i class="fas fa-circle-dot"></i>
                  <% } else { %><span style="opacity:.3;font-size:.7rem;"><%= i+1 %></span><% } %>
                </div>
                <div style="font-size:.72rem;font-weight:700;text-align:center;text-transform:uppercase;
                            color:<%= done?"var(--green)":(active?"var(--orange)":"var(--text-muted)") %>;">
                  <%= steps[i] %>
                </div>
              </div>
            <% } %>
          </div>

          <!-- Inline Update Form (only for assigned agent) -->
          <% if (canUpdate && nextStatuses.length > 0) { %>
          <form action="${pageContext.request.contextPath}/orders" method="post"
                style="display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap;margin-top:16px;">
            <input type="hidden" name="action" value="updateStatus">
            <input type="hidden" name="orderId" value="<%= od[19] %>">
            <div class="form-group" style="flex:1;min-width:180px;">
              <label class="form-label">Update to</label>
              <select name="newStatus" class="form-select">
                <% for (String opt : nextStatuses) { %>
                  <option value="<%= opt %>"><%= opt %></option>
                <% } %>
              </select>
            </div>
            <div class="form-group" style="flex:2;min-width:220px;">
              <label class="form-label">Remarks</label>
              <input type="text" name="remarks" class="form-input" placeholder="Optional notes…">
            </div>
            <button type="submit" class="btn btn-primary"><i class="fas fa-sync-alt"></i> Update</button>
          </form>
          <% } %>
        </div>
      </div>

      <!-- Info Grid -->
      <div class="detail-grid">
        <div class="info-block">
          <div class="info-block-header">🏪 Seller Information</div>
          <div class="info-block-body">
            <div class="info-row"><span class="info-key">Name</span><span class="info-val"><%= od[6] %></span></div>
            <div class="info-row"><span class="info-key">Address</span><span class="info-val"><%= od[7] %></span></div>
            <div class="info-row"><span class="info-key">Contact</span><span class="info-val"><%= od[8] %></span></div>
          </div>
        </div>
        <div class="info-block">
          <div class="info-block-header">🏠 Customer Information</div>
          <div class="info-block-body">
            <div class="info-row"><span class="info-key">Name</span><span class="info-val"><%= od[9] %></span></div>
            <div class="info-row"><span class="info-key">Address</span><span class="info-val"><%= od[10] %></span></div>
            <div class="info-row"><span class="info-key">Contact</span><span class="info-val"><%= od[11] %></span></div>
          </div>
        </div>
        <div class="info-block">
          <div class="info-block-header">📦 Product Details</div>
          <div class="info-block-body">
            <div class="info-row"><span class="info-key">Description</span><span class="info-val"><%= od[12] %></span></div>
            <div class="info-row"><span class="info-key">Weight</span><span class="info-val"><%= od[13] %> kg</span></div>
            <div class="info-row"><span class="info-key">Pickup Date</span><span class="info-val"><%= od[14] %></span></div>
            <div class="info-row"><span class="info-key">Expected Delivery</span><span class="info-val"><%= od[15] %></span></div>
            <% if (od[16] != null && !od[16].isBlank()) { %>
              <div class="info-row"><span class="info-key">Special Notes</span><span class="info-val"><%= od[16] %></span></div>
            <% } %>
          </div>
        </div>
        <div class="info-block">
          <div class="info-block-header">💳 Payment Details</div>
          <div class="info-block-body">
            <div class="info-row"><span class="info-key">Type</span><span class="info-val"><%= od[5] %></span></div>
            <div class="info-row"><span class="info-key">Charges</span><span class="info-val" style="color:var(--orange);font-size:1.1rem;font-family:var(--font-display);">₹<%= od[17] %></span></div>
            <div class="info-row">
              <span class="info-key">Payment Status</span>
              <span class="info-val">
                <% if ("1".equals(od[18])) { %><span style="color:var(--green);font-weight:700;">✓ Paid</span>
                <% } else { %><span style="color:var(--red);font-weight:700;">⏳ Pending</span><% } %>
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Timeline -->
      <div class="card">
        <div class="card-header"><span class="card-title">🕓 Status History</span></div>
        <div class="card-body">
          <% if (history.isEmpty()) { %>
            <p style="color:var(--text-muted);text-align:center;padding:20px;">No status history available.</p>
          <% } else { %>
          <div class="timeline">
            <% for (String[] h : history) {
                 // h[]: 0=status,1=changedAt,2=agentName,3=remarks,4=dotClass %>
            <div class="timeline-item">
              <div class="timeline-dot <%= h[4] != null ? h[4] : "" %>">
                <% if ("Delivered".equals(h[0])) { %><i class="fas fa-check"></i>
                <% } else if ("Rejected".equals(h[0])) { %><i class="fas fa-times"></i>
                <% } else { %><i class="fas fa-circle" style="font-size:.5rem;"></i><% } %>
              </div>
              <div class="timeline-content">
                <div class="timeline-status"><%= h[0] %></div>
                <div class="timeline-meta">
                  <%= h[1] != null ? h[1] : "—" %>
                  <% if (h[2] != null && !h[2].isBlank()) { %> &nbsp;·&nbsp; by <%= h[2] %><% } %>
                </div>
                <% if (h[3] != null && !h[3].isBlank()) { %>
                  <div class="timeline-remarks"><%= h[3] %></div>
                <% } %>
              </div>
            </div>
            <% } %>
          </div>
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
