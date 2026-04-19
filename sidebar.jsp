<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%-- ============================================================
     sidebar.jsp  –  Included by all dashboard pages
     Reads 'agent' object from session (set by LoginServlet).
     No DAO / DB calls here.
     ============================================================ --%>
<%
    // Safely read agent info from session (set by LoginServlet)
    String sidebarName = (String) session.getAttribute("agentName");
    String sidebarRole = (String) session.getAttribute("agentRole");
    if (sidebarName == null) sidebarName = "Agent";
    if (sidebarRole == null) sidebarRole = "AGENT";

    // Build initials
    String sidebarInitials = "";
    String[] parts = sidebarName.trim().split("\\s+");
    sidebarInitials = parts[0].substring(0, 1).toUpperCase();
    if (parts.length > 1) sidebarInitials += parts[parts.length - 1].substring(0, 1).toUpperCase();

    String currentURI = request.getRequestURI();
    boolean isAdmin   = "ADMIN".equals(sidebarRole);
%>
<aside class="sidebar" id="sidebar">
  <div class="sidebar-header">
    <div class="sidebar-logo-icon">🚚</div>
    <div class="sidebar-brand">Logi<span>X</span></div>
  </div>

  <div class="sidebar-agent-card">
    <div class="agent-avatar"><%= sidebarInitials %></div>
    <div class="agent-info">
      <div class="agent-name"><%= sidebarName %></div>
      <div class="agent-role"><%= sidebarRole %></div>
    </div>
  </div>

  <nav class="sidebar-nav">
    <div class="nav-section-label">Main</div>

    <a href="${pageContext.request.contextPath}/pages/dashboard.jsp"
       class="nav-link <%= currentURI.contains("dashboard") ? "active" : "" %>">
      <span class="nav-icon">📊</span> Dashboard
    </a>

    <a href="${pageContext.request.contextPath}/orders?action=pickup"
       class="nav-link <%= currentURI.contains("pickup") ? "active" : "" %>">
      <span class="nav-icon">📦</span> Pickup Orders
    </a>

    <a href="${pageContext.request.contextPath}/orders"
       class="nav-link <%= currentURI.contains("orders") && !currentURI.contains("pickup") && !currentURI.contains("history") ? "active" : "" %>">
      <span class="nav-icon">🚚</span> My Deliveries
    </a>

    <a href="${pageContext.request.contextPath}/orders?action=history"
       class="nav-link <%= currentURI.contains("history") ? "active" : "" %>">
      <span class="nav-icon">📋</span> Order History
    </a>

    <a href="${pageContext.request.contextPath}/orders?action=track" class="nav-link">
      <span class="nav-icon">🔍</span> Track Order
    </a>

    <% if (isAdmin) { %>
    <div class="nav-section-label">Admin</div>
    <a href="${pageContext.request.contextPath}/pages/admin-dashboard.jsp"
       class="nav-link <%= currentURI.contains("admin") ? "active" : "" %>">
      <span class="nav-icon">🛡️</span> Admin Panel
    </a>
    <a href="${pageContext.request.contextPath}/orders?action=list" class="nav-link">
      <span class="nav-icon">📑</span> All Orders
    </a>
    <% } %>

    <div class="nav-section-label">Account</div>
    <a href="${pageContext.request.contextPath}/profile"
       class="nav-link <%= currentURI.contains("profile") ? "active" : "" %>">
      <span class="nav-icon">👤</span> My Profile
    </a>
  </nav>

  <div class="sidebar-footer">
    <form action="${pageContext.request.contextPath}/logout" method="get" style="margin:0;">
      <button type="submit" class="logout-btn">
        <i class="fas fa-sign-out-alt"></i> Logout
      </button>
    </form>
  </div>
</aside>
