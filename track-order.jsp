<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.util.ArrayList" %>
<%--
    track-order.jsp
    Request attributes set by OrderServlet (action=track):
      - tracking   (String) – the searched tracking number
      - orderFound (Boolean) – true if order was found
      - trackData  (String[]) – [tracking, customerName, agentName, expectedDelivery,
                                  deliveryCharges, status, badgeClass, currentStepIndex]
      - statusHistory (List<String[]>) – each row: [status, changedAt, remarks]
--%>
<%
    String tracking  = (String)  request.getAttribute("tracking");
    Boolean found    = (Boolean) request.getAttribute("orderFound");
    if (found == null) found = false;

    String[] td = (String[]) request.getAttribute("trackData");
    // stepIndex: 0=Pending,1=Accepted,2=Picked Up,3=In Transit,4=Out for Delivery,5=Delivered
    int curIdx = -1;
    if (td != null) { try { curIdx = Integer.parseInt(td[7]); } catch(Exception e){} }

    @SuppressWarnings("unchecked")
    List<String[]> history = (List<String[]>) request.getAttribute("statusHistory");
    if (history == null) history = new ArrayList<>();

    String[] steps = {"Pending","Accepted","Picked Up","In Transit","Out for Delivery","Delivered"};
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Track Order – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Track Order</div>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>Track Your Order</h2>
        <p>Enter a tracking number to get real-time delivery status.</p>
      </div>

      <!-- Search Box -->
      <div class="card" style="margin-bottom:24px;">
        <div class="card-body">
          <form action="${pageContext.request.contextPath}/orders" method="get"
                style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;">
            <input type="hidden" name="action" value="track">
            <div class="form-group" style="flex:1;min-width:200px;">
              <label class="form-label">Tracking Number</label>
              <div class="input-icon-wrap">
                <i class="fas fa-search icon"></i>
                <input type="text" name="t" class="form-input"
                       placeholder="e.g. LGX-20240001"
                       value="<%= tracking != null ? tracking : "" %>"
                       style="text-transform:uppercase;" required>
              </div>
            </div>
            <button type="submit" class="btn btn-primary" style="height:42px;">
              <i class="fas fa-search"></i> Track
            </button>
          </form>
        </div>
      </div>

      <% if (tracking != null && !tracking.isBlank() && !found) { %>
        <div class="alert alert-error">
          <i class="fas fa-exclamation-triangle"></i>
          No order found with tracking number <strong><%= tracking %></strong>. Please check and try again.
        </div>
      <% } %>

      <% if (found && td != null) {
           // td[]: 0=tracking,1=custName,2=agentName,3=expectedDelivery,4=charges,5=status,6=badgeClass,7=stepIdx
      %>
      <!-- Header Card -->
      <div style="background:linear-gradient(135deg,var(--navy),var(--navy-light));border-radius:var(--radius-lg);padding:24px 28px;margin-bottom:20px;color:var(--white);">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:12px;">
          <div>
            <p style="color:rgba(255,255,255,.55);font-size:.8rem;margin-bottom:4px;">Tracking Number</p>
            <h2 style="font-family:var(--font-display);font-size:1.8rem;font-weight:800;color:var(--orange);"><%= td[0] %></h2>
          </div>
          <span class="badge <%= td[6] %>" style="font-size:.9rem;padding:8px 16px;"><%= td[5] %></span>
        </div>
        <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:16px;margin-top:18px;">
          <div><div style="font-size:.72rem;color:rgba(255,255,255,.45);text-transform:uppercase;">Customer</div><div style="font-size:.9rem;font-weight:600;"><%= td[1] %></div></div>
          <div><div style="font-size:.72rem;color:rgba(255,255,255,.45);text-transform:uppercase;">Agent</div><div style="font-size:.9rem;font-weight:600;"><%= td[2] != null ? td[2] : "Unassigned" %></div></div>
          <div><div style="font-size:.72rem;color:rgba(255,255,255,.45);text-transform:uppercase;">Expected</div><div style="font-size:.9rem;font-weight:600;"><%= td[3] %></div></div>
          <div><div style="font-size:.72rem;color:rgba(255,255,255,.45);text-transform:uppercase;">Charges</div><div style="font-size:.9rem;font-weight:600;color:var(--orange);">₹<%= td[4] %></div></div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="card" style="margin-bottom:20px;">
        <div class="card-body">
          <div style="display:flex;align-items:center;overflow-x:auto;padding:8px 0;">
            <% for (int i = 0; i < steps.length; i++) {
                 boolean done   = i < curIdx;
                 boolean active = i == curIdx; %>
              <% if (i > 0) { %><div style="height:3px;flex:1;background:<%= i<=curIdx ? "var(--green)" : "var(--border)" %>;min-width:20px;"></div><% } %>
              <div style="display:flex;flex-direction:column;align-items:center;gap:6px;min-width:80px;">
                <div style="width:38px;height:38px;border-radius:50%;border:3px solid <%= done||active ? (done?"var(--green)":"var(--orange)") : "var(--border)" %>;
                            background:<%= done ? "var(--green)" : (active ? "var(--orange)" : "var(--white)") %>;
                            display:flex;align-items:center;justify-content:center;
                            color:<%= (done||active) ? "var(--white)" : "#ccc" %>;font-size:.8rem;z-index:1;
                            <%= active ? "box-shadow:0 0 0 5px rgba(244,112,27,.2);" : "" %>">
                  <% if (done) { %><i class="fas fa-check"></i>
                  <% } else if (active) { %><i class="fas fa-truck"></i>
                  <% } else { %><span style="font-size:.7rem;opacity:.4;"><%= i+1 %></span><% } %>
                </div>
                <div style="font-size:.68rem;font-weight:700;text-align:center;text-transform:uppercase;
                            color:<%= done ? "var(--green)" : (active ? "var(--orange)" : "var(--text-muted)") %>;">
                  <%= steps[i] %>
                </div>
              </div>
            <% } %>
          </div>
        </div>
      </div>

      <!-- Timeline -->
      <div class="card">
        <div class="card-header"><span class="card-title">📋 Status History</span></div>
        <div class="card-body">
          <div class="timeline">
            <% for (String[] h : history) {
                 // h[]: 0=status, 1=changedAt, 2=remarks %>
            <div class="timeline-item">
              <div class="timeline-dot <%= "Delivered".equals(h[0]) ? "" : (h[0].equals(td[5]) ? "active" : "") %>">
                <% if ("Delivered".equals(h[0])) { %><i class="fas fa-check"></i>
                <% } else { %><i class="fas fa-circle" style="font-size:.45rem;"></i><% } %>
              </div>
              <div class="timeline-content">
                <div class="timeline-status"><%= h[0] %></div>
                <div class="timeline-meta"><%= h[1] != null ? h[1] : "—" %></div>
                <% if (h[2] != null && !h[2].isBlank()) { %>
                  <div class="timeline-remarks"><%= h[2] %></div>
                <% } %>
              </div>
            </div>
            <% } %>
          </div>
        </div>
      </div>
      <% } %>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
document.addEventListener('DOMContentLoaded',function(){
  const t=document.querySelector('input[name="t"]');
  if(t)t.addEventListener('input',function(){this.value=this.value.toUpperCase();});
});
</script>
</body>
</html>
