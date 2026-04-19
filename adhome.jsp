<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%--
  ╔════════════════════════════════════════════════════════════════════╗
  ║  admin/agentApprovals.jsp                                          ║
  ║  Delivery Agent Login Approvals — Admin Dashboard                  ║
  ╚════════════════════════════════════════════════════════════════════╝
--%>

<%!

    private static final String DB_URL  =
        "jdbc:mysql://localhost:3306/multi_vendor" +
        "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    Connection getConn() throws Exception {
        Class.forName("com.mysql.jdbc.Driver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }
    void closeAll(AutoCloseable... res) {
        for (AutoCloseable r : res) { try { if (r != null) r.close(); } catch (Exception ignored){} }
    }
%>

<%-- ═══════════════════ ACTION HANDLER ═════════════════════════════════ --%>
<%
    String actionMsg  = "";
    String actionType = "ok";

    String action = request.getParameter("action");
    if (action == null) action = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String agentId = request.getParameter("agentId");

        if ("approve".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Active' WHERE agent_id=? AND agent_status='Pending'"
                );
                ps.setString(1, agentId);
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    actionMsg  = "✅ Agent <strong>" + agentId + "</strong> has been <strong>Approved</strong> and is now Active.";
                    actionType = "ok";
                } else {
                    actionMsg  = "⚠️ Agent not found or already processed.";
                    actionType = "wrn";
                }
            } catch (Exception e) {
                actionMsg  = "❌ Error approving agent: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("reject".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Inactive' WHERE agent_id=?"
                );
                ps.setString(1, agentId);
                ps.executeUpdate();
                actionMsg  = "🚫 Agent <strong>" + agentId + "</strong> has been <strong>Rejected</strong>.";
                actionType = "wrn";
            } catch (Exception e) {
                actionMsg  = "❌ Error rejecting: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("suspend".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='On Leave' WHERE agent_id=?"
                );
                ps.setString(1, agentId);
                ps.executeUpdate();
                actionMsg  = "⏸️ Agent <strong>" + agentId + "</strong> has been <strong>Suspended</strong>.";
                actionType = "wrn";
            } catch (Exception e) {
                actionMsg  = "❌ Error suspending: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("reactivate".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Active' WHERE agent_id=?"
                );
                ps.setString(1, agentId);
                ps.executeUpdate();
                actionMsg  = "✅ Agent <strong>" + agentId + "</strong> reactivated to <strong>Active</strong>.";
                actionType = "ok";
            } catch (Exception e) {
                actionMsg  = "❌ Error: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("delete".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement("DELETE FROM delivery_agents WHERE agent_id=?");
                ps.setString(1, agentId);
                ps.executeUpdate();
                actionMsg  = "🗑️ Agent <strong>" + agentId + "</strong> permanently deleted.";
                actionType = "err";
            } catch (Exception e) {
                actionMsg  = "❌ Error deleting: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("bulkApprove".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Active' WHERE agent_status='Pending'"
                );
                int rows = ps.executeUpdate();
                actionMsg  = "✅ <strong>" + rows + "</strong> pending agent(s) approved.";
                actionType = "ok";
            } catch (Exception e) {
                actionMsg  = "❌ Bulk approve failed: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }

        } else if ("bulkReject".equals(action)) {
            Connection c = null; PreparedStatement ps = null;
            try {
                c  = getConn();
                ps = c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Inactive' WHERE agent_status='Pending'"
                );
                int rows = ps.executeUpdate();
                actionMsg  = "🚫 <strong>" + rows + "</strong> pending agent(s) rejected.";
                actionType = "wrn";
            } catch (Exception e) {
                actionMsg  = "❌ Bulk reject failed: " + e.getMessage();
                actionType = "err";
            } finally { closeAll(ps, c); }
        }
    }

    /* ── Filter tab ──────────────────────────────────────────────── */
    String tab = request.getParameter("tab");
    if (tab == null || tab.isEmpty()) tab = "pending";

    String search     = request.getParameter("search");
    String zoneFilter = request.getParameter("zone");
    if (search     == null) search     = "";
    if (zoneFilter == null) zoneFilter = "";

    /* ── Stats ───────────────────────────────────────────────────── */
    int cntPending = 0, cntActive = 0, cntInactive = 0, cntOnLeave = 0, cntTotal = 0;
    {
        Connection c = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            c  = getConn();
            ps = c.prepareStatement(
                "SELECT agent_status, COUNT(*) AS cnt FROM delivery_agents GROUP BY agent_status"
            );
            rs = ps.executeQuery();
            while (rs.next()) {
                String s   = rs.getString("agent_status");
                int    cnt = rs.getInt("cnt");
                cntTotal += cnt;
                if ("Pending".equals(s))  cntPending  = cnt;
                if ("Active".equals(s))   cntActive   = cnt;
                if ("Inactive".equals(s)) cntInactive = cnt;
                if ("On Leave".equals(s)) cntOnLeave  = cnt;
            }
        } catch (Exception e) {
            actionMsg  = "⚠️ DB connection error: " + e.getMessage();
            actionType = "err";
        } finally { closeAll(rs, ps, c); }
    }

    /* ── Build query ─────────────────────────────────────────────── */
    String statusFilter = "";
    if      ("active".equals(tab))   statusFilter = "Active";
    else if ("inactive".equals(tab)) statusFilter = "Inactive";
    else if ("onleave".equals(tab))  statusFilter = "On Leave";
    else if ("all".equals(tab))      statusFilter = "";
    else                             statusFilter = "Pending";

    StringBuilder agentSql = new StringBuilder("SELECT * FROM delivery_agents WHERE 1=1");
    List<String> agentParams = new ArrayList<String>();

    if (!statusFilter.isEmpty()) {
        agentSql.append(" AND agent_status = ?");
        agentParams.add(statusFilter);
    }
    if (!search.trim().isEmpty()) {
        agentSql.append(" AND (agent_name LIKE ? OR agent_id LIKE ? OR email LIKE ? OR phone LIKE ?)");
        String like = "%" + search.trim() + "%";
        agentParams.add(like); agentParams.add(like);
        agentParams.add(like); agentParams.add(like);
    }
    if (!zoneFilter.trim().isEmpty()) {
        agentSql.append(" AND zone = ?");
        agentParams.add(zoneFilter);
    }
    agentSql.append(" ORDER BY FIELD(agent_status,'Pending','Active','On Leave','Inactive'), created_at DESC");

    List<Map<String,String>> agents = new ArrayList<Map<String,String>>();
    List<String> zones = new ArrayList<String>();

    /* ── Load agent rows ─────────────────────────────────────────── */
    {
        Connection c = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            c  = getConn();
            ps = c.prepareStatement(agentSql.toString());
            for (int i = 0; i < agentParams.size(); i++) ps.setString(i+1, agentParams.get(i));
            rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,String> a = new LinkedHashMap<String,String>();
                a.put("agent_id",             rs.getString("agent_id"));
                a.put("agent_name",           rs.getString("agent_name"));
                a.put("vehicle_type",         rs.getString("vehicle_type"));
                a.put("total_deliveries",     String.valueOf(rs.getInt("total_deliveries")));
                a.put("completed_deliveries", String.valueOf(rs.getInt("completed_deliveries")));
                a.put("agent_status",         rs.getString("agent_status"));
                a.put("phone",                rs.getString("phone")      != null ? rs.getString("phone")      : "—");
                a.put("zone",                 rs.getString("zone")       != null ? rs.getString("zone")       : "—");
                a.put("created_at",           rs.getString("created_at") != null ? rs.getString("created_at") : "—");
                a.put("email",                rs.getString("email")      != null ? rs.getString("email")      : "—");
                a.put("license_no",           rs.getString("license_no") != null ? rs.getString("license_no") : "—");
                agents.add(a);
            }
        } catch (Exception e) {
            if (actionMsg.isEmpty()) { actionMsg = "❌ Error loading agents: " + e.getMessage(); actionType = "err"; }
        } finally { closeAll(rs, ps, c); }
    }

    /* ── Distinct zones ──────────────────────────────────────────── */
    {
        Connection c = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            c  = getConn();
            ps = c.prepareStatement(
                "SELECT DISTINCT zone FROM delivery_agents WHERE zone IS NOT NULL ORDER BY zone"
            );
            rs = ps.executeQuery();
            while (rs.next()) { String z = rs.getString("zone"); if (z != null) zones.add(z); }
        } finally { closeAll(rs, ps, c); }
    }

    SimpleDateFormat inFmt  = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    SimpleDateFormat outFmt = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Agent Approvals — Admin Dashboard</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;600&display=swap');

:root {
    --navy:       #0f1c2e;
    --navy-lt:    #1a2f4a;
    --navy-bd:    #243b55;
    --amber:      #f59e0b;
    --amber-lt:   #fcd34d;
    --amber-dk:   #b45309;
    --white:      #ffffff;
    --gray-50:    #f8fafc;
    --gray-100:   #f1f5f9;
    --gray-200:   #e2e8f0;
    --gray-300:   #cbd5e1;
    --gray-400:   #94a3b8;
    --gray-500:   #64748b;
    --gray-700:   #334155;
    --gray-900:   #0f172a;
    --green:      #059669;
    --green-lt:   #d1fae5;
    --red:        #dc2626;
    --red-lt:     #fee2e2;
    --orange:     #ea580c;
    --orange-lt:  #ffedd5;
    --blue:       #2563eb;
    --blue-lt:    #dbeafe;
    --purple:     #7c3aed;
    --purple-lt:  #ede9fe;
    --shadow-sm:  0 1px 3px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06);
    --shadow:     0 4px 16px rgba(0,0,0,.10);
    --shadow-lg:  0 12px 40px rgba(0,0,0,.15);
    --r:          10px;
    --r-sm:       6px;
    --r-lg:       14px;
    --t:          .2s ease;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: 'Inter', system-ui, sans-serif; background: var(--gray-100);
       color: var(--gray-700); font-size: 14px; line-height: 1.6; }
a { text-decoration: none; color: inherit; }

/* ── Layout ─────────────────────────────────────────────────── */
.layout { display: flex; min-height: 100vh; }

/* ── Sidebar ────────────────────────────────────────────────── */
.sidebar {
    width: 250px; flex-shrink: 0; background: var(--navy);
    display: flex; flex-direction: column;
    position: sticky; top: 0; height: 100vh; overflow-y: auto;
}
.sidebar-logo {
    padding: 1.4rem 1.2rem; border-bottom: 1px solid var(--navy-bd);
    display: flex; align-items: center; gap: .7rem;
}
.logo-icon {
    width: 36px; height: 36px; border-radius: 8px; background: var(--amber);
    display: flex; align-items: center; justify-content: center; font-size: 1.1rem; flex-shrink: 0;
}
.logo-text { color: var(--white); font-weight: 700; font-size: .95rem; }
.logo-sub  { color: var(--gray-400); font-size: .72rem; }
.nav-section { padding: .6rem .8rem .2rem; font-size: .65rem; font-weight: 700;
               letter-spacing: 1.5px; text-transform: uppercase; color: var(--gray-400); }
.nav-item {
    display: flex; align-items: center; gap: .65rem; padding: .6rem 1rem;
    margin: .1rem .5rem; border-radius: var(--r-sm); color: rgba(255,255,255,.6);
    font-size: .855rem; transition: var(--t); cursor: pointer;
}
.nav-item:hover  { background: rgba(255,255,255,.07); color: var(--white); }
.nav-item.active { background: rgba(245,158,11,.15); color: var(--amber); border-left: 3px solid var(--amber); }
.nav-item .ni    { font-size: 1rem; width: 18px; text-align: center; }
.nav-badge { margin-left: auto; background: var(--amber); color: var(--navy);
             font-size: .65rem; font-weight: 700; padding: .1rem .4rem; border-radius: 20px; min-width: 18px; text-align: center; }
.nav-badge.red { background: var(--red); color: #fff; }
.sidebar-bottom { margin-top: auto; padding: 1rem; border-top: 1px solid var(--navy-bd); }

/* ── Main ───────────────────────────────────────────────────── */
.main { flex: 1; display: flex; flex-direction: column; overflow-x: hidden; }

/* ── Topbar ─────────────────────────────────────────────────── */
.topbar {
    background: var(--white); border-bottom: 1px solid var(--gray-200);
    padding: 0 1.8rem; height: 60px;
    display: flex; align-items: center; justify-content: space-between;
    position: sticky; top: 0; z-index: 100; box-shadow: var(--shadow-sm);
}
.topbar-left h1 { font-size: 1.05rem; font-weight: 700; color: var(--gray-900); }
.topbar-left p  { font-size: .78rem; color: var(--gray-400); margin-top: .05rem; }
.topbar-right   { display: flex; align-items: center; gap: .8rem; }
.admin-chip { display: flex; align-items: center; gap: .5rem; background: var(--gray-100);
              border-radius: 20px; padding: .3rem .8rem .3rem .4rem; }
.admin-avatar { width: 28px; height: 28px; border-radius: 50%; background: var(--navy);
                display: flex; align-items: center; justify-content: center;
                color: var(--amber); font-size: .8rem; font-weight: 700; }
.admin-name { font-size: .82rem; font-weight: 600; color: var(--gray-700); }

/* ── Content ────────────────────────────────────────────────── */
.content { padding: 1.6rem 1.8rem; flex: 1; }

/* ── Stat Cards ─────────────────────────────────────────────── */
.stats-row { display: grid; grid-template-columns: repeat(5,1fr); gap: 1rem; margin-bottom: 1.6rem; }
.stat {
    background: var(--white); border-radius: var(--r); padding: 1.1rem 1.2rem;
    box-shadow: var(--shadow-sm); display: flex; flex-direction: column; gap: .3rem;
    border-top: 3px solid transparent; transition: var(--t); cursor: pointer; text-decoration: none;
}
.stat:hover { box-shadow: var(--shadow); transform: translateY(-1px); }
.stat.s-pending  { border-color: var(--amber); }
.stat.s-active   { border-color: var(--green); }
.stat.s-inactive { border-color: var(--red);   }
.stat.s-onleave  { border-color: var(--purple);}
.stat.s-total    { border-color: var(--blue);  }
.stat-num  { font-size: 1.75rem; font-weight: 700; color: var(--gray-900); line-height: 1; }
.stat-lbl  { font-size: .73rem; color: var(--gray-400); font-weight: 500; text-transform: uppercase; letter-spacing: .5px; }
.stat-icon2{ font-size: 1.3rem; margin-bottom: .1rem; }

/* ── Alert ──────────────────────────────────────────────────── */
.alert {
    display: flex; align-items: flex-start; gap: .6rem;
    padding: .85rem 1.1rem; border-radius: var(--r-sm); margin-bottom: 1.2rem;
    font-size: .87rem; font-weight: 500; border: 1px solid transparent;
    animation: slideIn .3s ease;
}
@keyframes slideIn { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
.alert.ok  { background: var(--green-lt);  color: #065f46; border-color: #6ee7b7; }
.alert.err { background: var(--red-lt);    color: #7f1d1d; border-color: #fca5a5; }
.alert.wrn { background: var(--orange-lt); color: #7c2d12; border-color: #fdba74; }

/* ── Card ───────────────────────────────────────────────────── */
.card { background: var(--white); border-radius: var(--r); box-shadow: var(--shadow-sm); overflow: hidden; }
.card-head {
    display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: .8rem;
    padding: 1rem 1.3rem; border-bottom: 1px solid var(--gray-200);
}
.card-title { font-size: .95rem; font-weight: 700; color: var(--gray-900); display: flex; align-items: center; gap: .5rem; }

/* ── Tabs ───────────────────────────────────────────────────── */
.tab-bar { display: flex; gap: .1rem; padding: 0 1.3rem; border-bottom: 1px solid var(--gray-200); background: var(--gray-50); overflow-x: auto; }
.tab {
    background: none; border: none; padding: .75rem 1.1rem; font-size: .84rem; font-weight: 600;
    color: var(--gray-400); cursor: pointer; border-bottom: 2px solid transparent;
    margin-bottom: -1px; transition: var(--t); display: flex; align-items: center; gap: .4rem;
    font-family: 'Inter', sans-serif; white-space: nowrap;
}
.tab:hover { color: var(--gray-700); }
.tab.active { color: var(--navy); border-bottom-color: var(--amber); }
.tab .tb { background: var(--gray-200); color: var(--gray-500); font-size: .68rem; font-weight: 700;
           padding: .1rem .4rem; border-radius: 20px; }
.tab.active .tb { background: var(--amber); color: var(--navy); }

/* ── Toolbar ────────────────────────────────────────────────── */
.toolbar {
    display: flex; align-items: center; gap: .7rem; flex-wrap: wrap; padding: .9rem 1.3rem;
    background: var(--gray-50); border-bottom: 1px solid var(--gray-200);
}
.search-input {
    flex: 1; min-width: 200px; padding: .5rem .85rem .5rem 2.1rem; border: 1.5px solid var(--gray-200);
    border-radius: var(--r-sm); font-size: .85rem; background: var(--white); transition: var(--t); font-family: inherit;
}
.search-input:focus { outline: none; border-color: var(--amber); box-shadow: 0 0 0 3px rgba(245,158,11,.12); }
.search-wrap { position: relative; flex: 1; min-width: 200px; }
.search-icon { position: absolute; left: .7rem; top: 50%; transform: translateY(-50%); font-size: .85rem; }
.sel { padding: .5rem .85rem; border: 1.5px solid var(--gray-200); border-radius: var(--r-sm);
       font-size: .84rem; background: var(--white); cursor: pointer; font-family: inherit; }
.sel:focus { outline: none; border-color: var(--amber); }

/* ── Buttons ────────────────────────────────────────────────── */
.btn {
    display: inline-flex; align-items: center; gap: .35rem; padding: .46rem 1rem;
    border-radius: var(--r-sm); font-size: .82rem; font-weight: 600; border: none;
    cursor: pointer; transition: var(--t); font-family: 'Inter', sans-serif; white-space: nowrap;
}
.btn-navy   { background: var(--navy);   color: var(--white); }
.btn-navy:hover   { background: var(--navy-lt); }
.btn-green  { background: var(--green);  color: var(--white); }
.btn-green:hover  { background: #047857; }
.btn-red    { background: var(--red);    color: var(--white); }
.btn-red:hover    { background: #b91c1c; }
.btn-orange { background: var(--orange); color: var(--white); }
.btn-orange:hover { background: #c2410c; }
.btn-ghost  { background: var(--gray-100); color: var(--gray-700); border: 1px solid var(--gray-200); }
.btn-ghost:hover  { background: var(--gray-200); }
.btn-sm { padding: .3rem .65rem; font-size: .76rem; }
.btn-xs { padding: .2rem .5rem;  font-size: .72rem; }

/* ── Table ──────────────────────────────────────────────────── */
.tbl-wrap { overflow-x: auto; overflow-y: auto; max-height: 520px; }
table { width: 100%; border-collapse: collapse; font-size: .845rem; min-width: 960px; }
thead th {
    background: var(--gray-50); color: var(--gray-500); font-size: .72rem; font-weight: 700;
    text-transform: uppercase; letter-spacing: .6px; padding: .7rem 1rem;
    border-bottom: 1px solid var(--gray-200); white-space: nowrap; text-align: left;
    position: sticky; top: 0; z-index: 2;
}
tbody td { padding: .8rem 1rem; border-bottom: 1px solid var(--gray-100); vertical-align: middle; }
tbody tr:last-child td { border-bottom: none; }
tbody tr:hover td { background: var(--gray-50); }
.agent-cell { display: flex; align-items: center; gap: .7rem; }
.agent-avatar {
    width: 34px; height: 34px; border-radius: 50%;
    background: linear-gradient(135deg,var(--navy-lt),var(--navy-bd));
    display: flex; align-items: center; justify-content: center;
    color: var(--amber); font-weight: 700; font-size: .85rem; flex-shrink: 0;
}
.agent-name { font-weight: 600; color: var(--gray-900); font-size: .87rem; }
.agent-id   { font-size: .72rem; color: var(--gray-400); font-family: 'JetBrains Mono', monospace; margin-top: .05rem; }
.mono       { font-family: 'JetBrains Mono', monospace; font-size: .8rem; }

/* ── Status Badges ──────────────────────────────────────────── */
.badge {
    display: inline-flex; align-items: center; gap: .3rem; padding: .22rem .6rem;
    border-radius: 20px; font-size: .72rem; font-weight: 700; white-space: nowrap;
}
.badge::before { content:''; width:6px; height:6px; border-radius:50%; background:currentColor; }
.b-pending  { background: #fef3c7;         color: #92400e; }
.b-active   { background: var(--green-lt); color: #065f46; }
.b-inactive { background: var(--red-lt);   color: #7f1d1d; }
.b-onleave  { background: var(--purple-lt);color: #4c1d95; }

/* ── Action group ───────────────────────────────────────────── */
.action-group { display: flex; gap: .3rem; flex-wrap: wrap; }

/* ── Empty state ────────────────────────────────────────────── */
.empty { text-align: center; padding: 3.5rem 2rem; display: flex; flex-direction: column; align-items: center; gap: .6rem; }
.empty-icon  { font-size: 3rem; opacity: .4; }
.empty-title { font-weight: 700; color: var(--gray-500); font-size: 1rem; }
.empty-sub   { font-size: .83rem; color: var(--gray-400); }

/* ── Drawer ─────────────────────────────────────────────────── */
.drawer-overlay {
    position: fixed; inset: 0; background: rgba(0,0,0,.4); z-index: 500;
    opacity: 0; pointer-events: none; transition: opacity .25s;
}
.drawer-overlay.open { opacity: 1; pointer-events: all; }
.drawer {
    position: fixed; top: 0; right: 0; bottom: 0; width: 420px; max-width: 95vw;
    background: var(--white); z-index: 501; box-shadow: var(--shadow-lg);
    transform: translateX(100%); transition: transform .28s cubic-bezier(.4,0,.2,1);
    display: flex; flex-direction: column; overflow: hidden;
}
.drawer-overlay.open .drawer { transform: translateX(0); }
.drawer-head {
    background: var(--navy); padding: 1.2rem 1.4rem; color: var(--white);
    display: flex; justify-content: space-between; align-items: flex-start;
}
.drawer-body  { padding: 1.4rem; flex: 1; overflow-y: auto; }
.drawer-close { background: none; border: none; color: rgba(255,255,255,.6); font-size: 1.3rem; cursor: pointer; }
.drawer-close:hover { color: var(--white); }
.detail-block { background: var(--gray-50); border-radius: var(--r-sm); padding: 1rem; margin-bottom: 1rem; }
.detail-row   { display: flex; gap: .5rem; padding: .45rem 0; border-bottom: 1px solid var(--gray-200); font-size: .87rem; }
.detail-row:last-child { border: none; }
.detail-lbl   { width: 130px; flex-shrink: 0; color: var(--gray-400); font-size: .8rem; }
.detail-val   { font-weight: 500; color: var(--gray-800); word-break: break-all; }
.drawer-foot  { padding: 1rem 1.4rem; border-top: 1px solid var(--gray-200); display: flex; gap: .6rem; flex-wrap: wrap; }

/* ── Responsive ─────────────────────────────────────────────── */
@media (max-width: 1100px) { .stats-row { grid-template-columns: repeat(3,1fr); } }
@media (max-width: 768px)  {
    .sidebar { display: none; }
    .stats-row { grid-template-columns: 1fr 1fr; }
    .content { padding: 1rem; }
    .topbar  { padding: 0 1rem; }
}
</style>
</head>
<body>
<div class="layout">

<!-- ════════════════════════════════════════════════════════════
     SIDEBAR
═════════════════════════════════════════════════════════════════ -->
<!-- ════════════════════════════════════════════════════════════
     SIDEBAR
═════════════════════════════════════════════════════════════════ -->
<aside class="sidebar">
    <div class="sidebar-logo">
        <div class="logo-icon">🚚</div>
        <div>
            <div class="logo-text">MultiVendor</div>
            <div class="logo-sub">Admin Portal</div>
        </div>
    </div>

    <div class="nav-section">Overview</div>
    <a href="adhome.jsp"         class="nav-item"><span class="ni">📊</span> Dashboard</a>
    
    <a href="sellerApprovals.jsp" class="nav-item"><span class="ni">🏪</span> Sellers</a>

    <div class="nav-section">Logistics</div>
    <a href="agentApprovals.jsp" class="nav-item active">
        <span class="ni">🪪</span> Agent Approvals
        <% if (cntPending > 0) { %><span class="nav-badge red"><%= cntPending %></span><% } %>
    </a>
    

    <div class="nav-section">System</div>
    
    <a href="#" class="nav-item"><span class="ni">⚙️</span> Settings</a>
    
    <!-- Logout Button -->
    <a href="ulogout" class="nav-item" onclick="return confirm('Are you sure you want to logout?');">
        <span class="ni">🚪</span> Logout
    </a>

    <div class="sidebar-bottom">
        <div class="nav-item" style="cursor:default;opacity:.7;">
            <span class="ni">🔒</span>
            <div>
                <div style="color:var(--white);font-size:.8rem;font-weight:600;">Admin</div>
                <div style="font-size:.7rem;color:var(--gray-400);">Superadmin</div>
            </div>
        </div>
    </div>
</aside>

<!-- ════════════════════════════════════════════════════════════
     MAIN
═════════════════════════════════════════════════════════════════ -->
<div class="main">

    <!-- Topbar -->
    <div class="topbar">
        <div class="topbar-left">
            <h1>🪪 Agent Approval Management</h1>
            <p>Review and manage delivery agent registrations</p>
        </div>
        <div class="topbar-right">
            <% if (cntPending > 0) { %>
            <span style="background:var(--red-lt);color:var(--red);font-size:.78rem;font-weight:700;
                         padding:.3rem .75rem;border-radius:20px;display:flex;align-items:center;gap:.4rem;">
                🔔 <strong><%= cntPending %></strong> pending review
            </span>
            <% } %>
            <div class="admin-chip">
                <div class="admin-avatar">A</div>
                <span class="admin-name">Admin</span>
            </div>
        </div>
    </div>

    <div class="content">

        <!-- Flash message -->
        <% if (!actionMsg.isEmpty()) { %>
        <div class="alert <%= actionType %>" id="flashAlert">
            <div><%=actionMsg%></div>
            <button onclick="this.parentElement.remove()"
                    style="margin-left:auto;background:none;border:none;cursor:pointer;font-size:1rem;opacity:.5;">✕</button>
        </div>
        <% } %>

        <!-- Stat cards -->
        <div class="stats-row">
            <a href="?tab=pending" class="stat s-pending">
                <div class="stat-icon2">⏳</div>
                <div class="stat-num"><%= cntPending %></div>
                <div class="stat-lbl">Pending Review</div>
            </a>
            <a href="?tab=active" class="stat s-active">
                <div class="stat-icon2">✅</div>
                <div class="stat-num"><%= cntActive %></div>
                <div class="stat-lbl">Active Agents</div>
            </a>
            <a href="?tab=inactive" class="stat s-inactive">
                <div class="stat-icon2">🚫</div>
                <div class="stat-num"><%= cntInactive %></div>
                <div class="stat-lbl">Rejected / Inactive</div>
            </a>
            <a href="?tab=onleave" class="stat s-onleave">
                <div class="stat-icon2">⏸️</div>
                <div class="stat-num"><%= cntOnLeave %></div>
                <div class="stat-lbl">Suspended</div>
            </a>
            <a href="?tab=all" class="stat s-total">
                <div class="stat-icon2">👥</div>
                <div class="stat-num"><%= cntTotal %></div>
                <div class="stat-lbl">Total Agents</div>
            </a>
        </div>

        <!-- Main card -->
        <div class="card">

            <!-- Card header + bulk actions -->
            <div class="card-head">
                <span class="card-title">
                    🗂️ Agent Registry
                    <span style="font-size:.78rem;color:var(--gray-400);font-weight:400;margin-left:.3rem;">
                        — showing <%= agents.size() %> record<%= agents.size()!=1?"s":"" %>
                    </span>
                </span>
                <% if ("pending".equals(tab) && cntPending > 0) { %>
                <div style="display:flex;gap:.5rem;">
                    <form method="post" style="display:inline;"
                          onsubmit="return confirm('Approve ALL <%= cntPending %> pending agents?')">
                        <input type="hidden" name="action" value="bulkApprove">
                        <button type="submit" class="btn btn-green btn-sm">✅ Approve All (<%= cntPending %>)</button>
                    </form>
                    <form method="post" style="display:inline;"
                          onsubmit="return confirm('Reject ALL <%= cntPending %> pending agents?')">
                        <input type="hidden" name="action" value="bulkReject">
                        <button type="submit" class="btn btn-red btn-sm">🚫 Reject All</button>
                    </form>
                </div>
                <% } %>
            </div>

            <!-- Tabs -->
            <div class="tab-bar">
                <button class="tab <%= "pending".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=pending&search=<%= search %>&zone=<%= zoneFilter %>'">
                    ⏳ Pending <span class="tb"><%= cntPending %></span>
                </button>
                <button class="tab <%= "active".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=active&search=<%= search %>&zone=<%= zoneFilter %>'">
                    ✅ Active <span class="tb"><%= cntActive %></span>
                </button>
                <button class="tab <%= "inactive".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=inactive&search=<%= search %>&zone=<%= zoneFilter %>'">
                    🚫 Inactive <span class="tb"><%= cntInactive %></span>
                </button>
                <button class="tab <%= "onleave".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=onleave&search=<%= search %>&zone=<%= zoneFilter %>'">
                    ⏸️ Suspended <span class="tb"><%= cntOnLeave %></span>
                </button>
                <button class="tab <%= "all".equals(tab)?"active":"" %>"
                    onclick="window.location='?tab=all&search=<%= search %>&zone=<%= zoneFilter %>'">
                    👥 All <span class="tb"><%= cntTotal %></span>
                </button>
            </div>

            <!-- Toolbar: search + zone filter -->
            <form method="get" action="">
                <input type="hidden" name="tab" value="<%= tab %>">
                <div class="toolbar">
                    <div class="search-wrap">
                        <span class="search-icon">🔍</span>
                        <input type="text" name="search" class="search-input"
                               placeholder="Search by name, ID, email, phone…"
                               value="<%= search %>">
                    </div>
                    <select name="zone" class="sel">
                        <option value="">All Zones</option>
                        <% for (String z : zones) { %>
                        <option value="<%= z %>" <%= z.equals(zoneFilter)?"selected":"" %>><%= z %></option>
                        <% } %>
                    </select>
                    <button type="submit" class="btn btn-navy">🔍 Filter</button>
                    <a href="?tab=<%= tab %>" class="btn btn-ghost">✕ Clear</a>
                </div>
            </form>

            <!-- Agent table -->
            <div class="tbl-wrap">
            <% if (agents.isEmpty()) { %>
                <div class="empty">
                    <div class="empty-icon">📭</div>
                    <div class="empty-title">No agents found</div>
                    <div class="empty-sub">
                        <% if (!search.isEmpty() || !zoneFilter.isEmpty()) { %>
                            No results match your search/filter.
                            <a href="?tab=<%= tab %>" style="color:var(--amber);">Clear filters</a>
                        <% } else { %>
                            No agents in this category yet.
                        <% } %>
                    </div>
                </div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th style="width:28px;"><input type="checkbox" id="checkAll" onclick="toggleAll(this)"></th>
                            <th>Agent</th>
                            <th>Contact</th>
                            <th>Vehicle</th>
                            <th>Zone</th>
                            <th>License No.</th>
                            <th>Deliveries</th>
                            <th>Status</th>
                            <th>Registered</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        for (Map<String,String> a : agents) {
                            String aid   = a.get("agent_id");
                            String aname = a.get("agent_name");
                            String astat = a.get("agent_status");
                            String phone = a.get("phone");
                            String email = a.get("email");
                            String zone  = a.get("zone");
                            String lic   = a.get("license_no");
                            String veh   = a.get("vehicle_type");
                            String total = a.get("total_deliveries");
                            String comp  = a.get("completed_deliveries");
                            String creat = a.get("created_at");

                            String badgeCls = "Active".equals(astat)   ? "b-active"
                                            : "Pending".equals(astat)  ? "b-pending"
                                            : "Inactive".equals(astat) ? "b-inactive"
                                            : "b-onleave";

                            String createdFmt = creat;
                            try { createdFmt = outFmt.format(inFmt.parse(creat)); } catch (Exception ignored) {}

                            int t2 = 0, c2 = 0;
                            try { t2 = Integer.parseInt(total); c2 = Integer.parseInt(comp); } catch (Exception e2) {}
                            int pct = t2 > 0 ? (c2 * 100 / t2) : 0;
                    %>
                    <tr>
                        <td><input type="checkbox" class="row-check" value="<%= aid %>"></td>

                        <td>
                            <div class="agent-cell">
                                <div class="agent-avatar"><%= aname.substring(0,1).toUpperCase() %></div>
                                <div>
                                    <div class="agent-name"><%= aname %></div>
                                    <div class="agent-id">#<%= aid %></div>
                                </div>
                            </div>
                        </td>

                        <td>
                            <div style="font-size:.82rem;">📱 <%= phone %></div>
                            <div style="font-size:.76rem;color:var(--gray-400);margin-top:.15rem;">✉️ <%= email %></div>
                        </td>

                        <td>
                            <span style="font-size:.82rem;">
                                <%= "Motorcycle".equals(veh)   ? "🏍️"
                                  : "Delivery Van".equals(veh) ? "🚐"
                                  : "Mini Truck".equals(veh)   ? "🚚" : "🚗" %>
                                <%= veh %>
                            </span>
                        </td>

                        <td><span style="font-size:.82rem;font-weight:500;">📍 <%= zone %></span></td>

                        <td><span class="mono"><%= lic %></span></td>

                        <td>
                            <div style="font-size:.82rem;">
                                <strong style="color:var(--navy);"><%= comp %></strong>
                                <span style="color:var(--gray-400);">/ <%= total %></span>
                            </div>
                            <div style="background:var(--gray-200);border-radius:4px;height:4px;margin-top:.3rem;overflow:hidden;width:80px;">
                                <div style="width:<%= pct %>%;height:100%;background:var(--green);transition:.3s;"></div>
                            </div>
                        </td>

                        <td><span class="badge <%= badgeCls %>"><%= astat %></span></td>

                        <td style="font-size:.78rem;color:var(--gray-400);white-space:nowrap;"><%= createdFmt %></td>

                        <td>
                            <div class="action-group">

                                <!-- VIEW drawer -->
                                <button class="btn btn-ghost btn-xs"
                                    onclick="openDrawer(
                                        '<%= aid %>',
                                        '<%= aname.replace("'","\\'"  ) %>',
                                        '<%= astat %>',
                                        '<%= phone %>',
                                        '<%= email %>',
                                        '<%= veh %>',
                                        '<%= zone %>',
                                        '<%= lic %>',
                                        '<%= total %>',
                                        '<%= comp %>',
                                        '<%= createdFmt %>'
                                    )">👁 View</button>

                                <% if ("Pending".equals(astat)) { %>
                                    <form method="post" style="display:inline;"
                                          onsubmit="return confirm('Approve agent <%= aid %>?')">
                                        <input type="hidden" name="action"  value="approve">
                                        <input type="hidden" name="agentId" value="<%= aid %>">
                                        <input type="hidden" name="tab"     value="<%= tab %>">
                                        <button type="submit" class="btn btn-green btn-xs">✅ Approve</button>
                                    </form>
                                    <form method="post" style="display:inline;"
                                          onsubmit="return confirm('Reject agent <%= aid %>?')">
                                        <input type="hidden" name="action"  value="reject">
                                        <input type="hidden" name="agentId" value="<%= aid %>">
                                        <input type="hidden" name="tab"     value="<%= tab %>">
                                        <button type="submit" class="btn btn-red btn-xs">🚫 Reject</button>
                                    </form>

                                <% } else if ("Active".equals(astat)) { %>
                                    <form method="post" style="display:inline;"
                                          onsubmit="return confirm('Suspend agent <%= aid %>?')">
                                        <input type="hidden" name="action"  value="suspend">
                                        <input type="hidden" name="agentId" value="<%= aid %>">
                                        <input type="hidden" name="tab"     value="<%= tab %>">
                                        <button type="submit" class="btn btn-orange btn-xs">⏸ Suspend</button>
                                    </form>

                                <% } else if ("Inactive".equals(astat) || "On Leave".equals(astat)) { %>
                                    <form method="post" style="display:inline;"
                                          onsubmit="return confirm('Reactivate agent <%= aid %>?')">
                                        <input type="hidden" name="action"  value="reactivate">
                                        <input type="hidden" name="agentId" value="<%= aid %>">
                                        <input type="hidden" name="tab"     value="<%= tab %>">
                                        <button type="submit" class="btn btn-green btn-xs">♻️ Reactivate</button>
                                    </form>
                                <% } %>

                                <!-- DELETE always shown -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('PERMANENTLY DELETE agent <%= aid %>? This cannot be undone!')">
                                    <input type="hidden" name="action"  value="delete">
                                    <input type="hidden" name="agentId" value="<%= aid %>">
                                    <input type="hidden" name="tab"     value="<%= tab %>">
                                    <button type="submit" class="btn btn-ghost btn-xs" style="color:var(--red);">🗑</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                    </tbody>
                </table>
            <% } %>
            </div><!-- /tbl-wrap -->

            <!-- Footer row count -->
            <% if (!agents.isEmpty()) { %>
            <div style="padding:.75rem 1.3rem;border-top:1px solid var(--gray-200);
                        font-size:.78rem;color:var(--gray-400);display:flex;justify-content:space-between;align-items:center;">
                <span>
                    Showing <strong><%= agents.size() %></strong>
                    <%= statusFilter.isEmpty() ? "total" : "\""+statusFilter+"\"" %>
                    agent<%= agents.size()!=1?"s":"" %>
                    <% if (!search.isEmpty()) { %> matching "<%= search %>"<% } %>
                    <% if (!zoneFilter.isEmpty()) { %> in zone "<%= zoneFilter %>"<% } %>
                </span>
                <a href="adhome.jsp" style="color:var(--amber);font-weight:600;">← Back to Dashboard</a>
            </div>
            <% } %>

        </div><!-- /card -->
    </div><!-- /content -->
</div><!-- /main -->
</div><!-- /layout -->

<!-- ════════════════════════════════════════════════════════════
     DETAIL DRAWER
═════════════════════════════════════════════════════════════════ -->
<div class="drawer-overlay" id="drawerOverlay" onclick="closeDrawer()">
    <div class="drawer" onclick="event.stopPropagation()">
        <div class="drawer-head">
            <div>
                <div id="dName"   style="font-weight:700;font-size:1.05rem;"></div>
                <div id="dId"     style="font-size:.75rem;opacity:.6;margin-top:.2rem;font-family:'JetBrains Mono',monospace;"></div>
                <div id="dStatus" style="margin-top:.5rem;"></div>
            </div>
            <button class="drawer-close" onclick="closeDrawer()">✕</button>
        </div>
        <div class="drawer-body">
            <div class="detail-block">
                <h4 style="font-size:.78rem;text-transform:uppercase;letter-spacing:1px;color:var(--gray-400);margin-bottom:.7rem;">Agent Information</h4>
                <div class="detail-row"><span class="detail-lbl">Agent ID</span>    <span class="detail-val mono" id="dd-id"></span></div>
                <div class="detail-row"><span class="detail-lbl">Full Name</span>   <span class="detail-val"      id="dd-name"></span></div>
                <div class="detail-row"><span class="detail-lbl">Phone</span>       <span class="detail-val"      id="dd-phone"></span></div>
                <div class="detail-row"><span class="detail-lbl">Email</span>       <span class="detail-val"      id="dd-email"></span></div>
                <div class="detail-row"><span class="detail-lbl">Vehicle Type</span><span class="detail-val"      id="dd-vehicle"></span></div>
                <div class="detail-row"><span class="detail-lbl">Zone</span>        <span class="detail-val"      id="dd-zone"></span></div>
                <div class="detail-row"><span class="detail-lbl">License No.</span> <span class="detail-val mono" id="dd-license"></span></div>
                <div class="detail-row"><span class="detail-lbl">Registered</span>  <span class="detail-val"      id="dd-date"></span></div>
            </div>
            <div class="detail-block">
                <h4 style="font-size:.78rem;text-transform:uppercase;letter-spacing:1px;color:var(--gray-400);margin-bottom:.7rem;">Performance</h4>
                <div class="detail-row"><span class="detail-lbl">Total Deliveries</span> <span class="detail-val" id="dd-total"></span></div>
                <div class="detail-row"><span class="detail-lbl">Completed</span>        <span class="detail-val" id="dd-comp"></span></div>
                <div class="detail-row"><span class="detail-lbl">Completion Rate</span>  <span class="detail-val" id="dd-rate"></span></div>
            </div>
        </div>
        <div class="drawer-foot" id="drawerFoot"></div>
    </div>
</div>

<script>
function openDrawer(id, name, status, phone, email, vehicle, zone, license, total, comp, date) {
    document.getElementById('dName').textContent  = name;
    document.getElementById('dId').textContent    = '#' + id;

    const badges = {
        'Pending':  '<span class="badge b-pending">⏳ Pending</span>',
        'Active':   '<span class="badge b-active">✅ Active</span>',
        'Inactive': '<span class="badge b-inactive">🚫 Inactive</span>',
        'On Leave': '<span class="badge b-onleave">⏸️ Suspended</span>'
    };
    document.getElementById('dStatus').innerHTML  = badges[status] || status;
    document.getElementById('dd-id').textContent      = id;
    document.getElementById('dd-name').textContent    = name;
    document.getElementById('dd-phone').textContent   = phone;
    document.getElementById('dd-email').textContent   = email;
    document.getElementById('dd-vehicle').textContent = vehicle;
    document.getElementById('dd-zone').textContent    = zone;
    document.getElementById('dd-license').textContent = license;
    document.getElementById('dd-date').textContent    = date;
    document.getElementById('dd-total').textContent   = total;
    document.getElementById('dd-comp').textContent    = comp;
    document.getElementById('dd-rate').textContent    =
        (parseInt(total) > 0 ? Math.round(parseInt(comp)/parseInt(total)*100) : 0) + '%';

    const t   = new URLSearchParams(window.location.search).get('tab') || 'pending';
    const foot = document.getElementById('drawerFoot');
    foot.innerHTML = '';

    if (status === 'Pending') {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Approve ${id}?')">
                <input type="hidden" name="action" value="approve">
                <input type="hidden" name="agentId" value="${id}">
                <input type="hidden" name="tab" value="${t}">
                <button type="submit" class="btn btn-green">✅ Approve Agent</button>
            </form>
            <form method="post" onsubmit="return confirm('Reject ${id}?')">
                <input type="hidden" name="action" value="reject">
                <input type="hidden" name="agentId" value="${id}">
                <input type="hidden" name="tab" value="${t}">
                <button type="submit" class="btn btn-red">🚫 Reject Agent</button>
            </form>`;
    } else if (status === 'Active') {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Suspend ${id}?')">
                <input type="hidden" name="action" value="suspend">
                <input type="hidden" name="agentId" value="${id}">
                <input type="hidden" name="tab" value="${t}">
                <button type="submit" class="btn btn-orange">⏸ Suspend Agent</button>
            </form>`;
    } else {
        foot.innerHTML = `
            <form method="post" onsubmit="return confirm('Reactivate ${id}?')">
                <input type="hidden" name="action" value="reactivate">
                <input type="hidden" name="agentId" value="${id}">
                <input type="hidden" name="tab" value="${t}">
                <button type="submit" class="btn btn-green">♻️ Reactivate</button>
            </form>`;
    }
    foot.innerHTML += `
        <form method="post" onsubmit="return confirm('PERMANENTLY DELETE ${id}? Cannot be undone!')">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="agentId" value="${id}">
            <input type="hidden" name="tab" value="${t}">
            <button type="submit" class="btn btn-ghost" style="color:var(--red);">🗑 Delete</button>
        </form>`;

    document.getElementById('drawerOverlay').classList.add('open');
    document.body.style.overflow = 'hidden';
}

function closeDrawer() {
    document.getElementById('drawerOverlay').classList.remove('open');
    document.body.style.overflow = '';
}

function toggleAll(master) {
    document.querySelectorAll('.row-check').forEach(cb => cb.checked = master.checked);
}

const flashAlert = document.getElementById('flashAlert');
if (flashAlert) setTimeout(() => flashAlert.remove(), 5000);

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDrawer(); });

const si = document.querySelector('.search-input');
if (si) si.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') this.closest('form').submit();
});
</script>
</body>
</html>