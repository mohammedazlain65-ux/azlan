<%-- ???????????????????????????????????????????????????????????????
     ADD THESE IMPORTS AT TOP OF YOUR adhome.jsp page directive
     <%@ page import="java.sql.*, java.util.*, java.text.*" %>
???????????????????????????????????????????????????????????????? --%>

<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.LinkedHashMap"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.DriverManager"%>
<%@page import="java.sql.Connection"%>
<%-- ???????????????????????????????????????????????????????????????
     JAVA BLOCK ? paste near top of adhome.jsp (after session check)
???????????????????????????????????????????????????????????????? --%>
<%!
    private static final String AGENT_DB_URL =
        "jdbc:mysql://localhost:3306/multi_vendor" +
        "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String AGENT_DB_USER = "root";
    private static final String AGENT_DB_PASS = "";

    Connection getAgentConn() throws Exception {
        Class.forName("com.mysql.jdbc.Driver");
        return DriverManager.getConnection(AGENT_DB_URL, AGENT_DB_USER, AGENT_DB_PASS);
    }
    void closeAgentRes(AutoCloseable... res) {
        for (AutoCloseable r : res) {
            try { if (r != null) r.close(); } catch (Exception ignored) {}
        }
    }
%>

<%-- ???????????????????????????????????????????????????????????????
     ACTION HANDLER ? paste near top of adhome.jsp scriptlet block
     (after your existing session/action checks, or as a new block)
???????????????????????????????????????????????????????????????? --%>
<%
    /* ?? Agent quick-action handler ???????????????????????????? */
    String agentActionMsg  = "";
    String agentActionType = "ok";

    String agentAction = request.getParameter("agentAction");
    if (agentAction == null) agentAction = "";

    if ("POST".equalsIgnoreCase(request.getMethod()) && !agentAction.isEmpty()) {
        String agentId = request.getParameter("agentId");

        if ("approve".equals(agentAction)) {
            Connection _c = null; PreparedStatement _ps = null;
            try {
                _c  = getAgentConn();
                _ps = _c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Active' WHERE agent_id=? AND agent_status='Pending'"
                );
                _ps.setString(1, agentId);
                int rows = _ps.executeUpdate();
                agentActionMsg  = rows > 0
                    ? "? Agent <strong>" + agentId + "</strong> approved and is now Active."
                    : "?? Agent not found or already processed.";
                agentActionType = rows > 0 ? "ok" : "wrn";
            } catch (Exception ex) {
                agentActionMsg  = "? Error: " + ex.getMessage();
                agentActionType = "err";
            } finally { closeAgentRes(_ps, _c); }

        } else if ("reject".equals(agentAction)) {
            Connection _c = null; PreparedStatement _ps = null;
            try {
                _c  = getAgentConn();
                _ps = _c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Inactive' WHERE agent_id=?"
                );
                _ps.setString(1, agentId);
                _ps.executeUpdate();
                agentActionMsg  = "? Agent <strong>" + agentId + "</strong> rejected.";
                agentActionType = "wrn";
            } catch (Exception ex) {
                agentActionMsg  = "? Error: " + ex.getMessage();
                agentActionType = "err";
            } finally { closeAgentRes(_ps, _c); }

        } else if ("suspend".equals(agentAction)) {
            Connection _c = null; PreparedStatement _ps = null;
            try {
                _c  = getAgentConn();
                _ps = _c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='On Leave' WHERE agent_id=?"
                );
                _ps.setString(1, agentId);
                _ps.executeUpdate();
                agentActionMsg  = "?? Agent <strong>" + agentId + "</strong> suspended.";
                agentActionType = "wrn";
            } catch (Exception ex) {
                agentActionMsg  = "? Error: " + ex.getMessage();
                agentActionType = "err";
            } finally { closeAgentRes(_ps, _c); }

        } else if ("reactivate".equals(agentAction)) {
            Connection _c = null; PreparedStatement _ps = null;
            try {
                _c  = getAgentConn();
                _ps = _c.prepareStatement(
                    "UPDATE delivery_agents SET agent_status='Active' WHERE agent_id=?"
                );
                _ps.setString(1, agentId);
                _ps.executeUpdate();
                agentActionMsg  = "? Agent <strong>" + agentId + "</strong> reactivated.";
                agentActionType = "ok";
            } catch (Exception ex) {
                agentActionMsg  = "? Error: " + ex.getMessage();
                agentActionType = "err";
            } finally { closeAgentRes(_ps, _c); }
        }
    }

    /* ?? Load agent stats ???????????????????????????????????????? */
    int aCntPending = 0, aCntActive = 0, aCntInactive = 0, aCntOnLeave = 0, aCntTotal = 0;
    {
        Connection _c = null; PreparedStatement _ps = null; ResultSet _rs = null;
        try {
            _c  = getAgentConn();
            _ps = _c.prepareStatement(
                "SELECT agent_status, COUNT(*) AS cnt FROM delivery_agents GROUP BY agent_status"
            );
            _rs = _ps.executeQuery();
            while (_rs.next()) {
                String s   = _rs.getString("agent_status");
                int    cnt = _rs.getInt("cnt");
                aCntTotal += cnt;
                if ("Pending".equals(s))  aCntPending  = cnt;
                if ("Active".equals(s))   aCntActive   = cnt;
                if ("Inactive".equals(s)) aCntInactive = cnt;
                if ("On Leave".equals(s)) aCntOnLeave  = cnt;
            }
        } catch (Exception ex) {
            agentActionMsg  = "?? DB error loading agent stats: " + ex.getMessage();
            agentActionType = "err";
        } finally { closeAgentRes(_rs, _ps, _c); }
    }

    /* ?? Load ALL agents for table ??????????????????????????????? */
    List<Map<String,String>> agentList = new ArrayList<Map<String,String>>();
    {
        Connection _c = null; PreparedStatement _ps = null; ResultSet _rs = null;
        try {
            _c  = getAgentConn();
            _ps = _c.prepareStatement(
                "SELECT agent_id, agent_name, vehicle_type, total_deliveries, " +
                "completed_deliveries, agent_status, phone, zone, email, license_no, created_at " +
                "FROM delivery_agents ORDER BY " +
                "FIELD(agent_status,'Pending','Active','On Leave','Inactive'), created_at DESC"
            );
            _rs = _ps.executeQuery();
            while (_rs.next()) {
                Map<String,String> row = new LinkedHashMap<String,String>();
                row.put("agent_id",             _rs.getString("agent_id"));
                row.put("agent_name",           _rs.getString("agent_name"));
                row.put("vehicle_type",         _rs.getString("vehicle_type"));
                row.put("total_deliveries",     String.valueOf(_rs.getInt("total_deliveries")));
                row.put("completed_deliveries", String.valueOf(_rs.getInt("completed_deliveries")));
                row.put("agent_status",         _rs.getString("agent_status"));
                row.put("phone",                _rs.getString("phone")      != null ? _rs.getString("phone")      : "?");
                row.put("zone",                 _rs.getString("zone")       != null ? _rs.getString("zone")       : "?");
                row.put("email",                _rs.getString("email")      != null ? _rs.getString("email")      : "?");
                row.put("license_no",           _rs.getString("license_no") != null ? _rs.getString("license_no") : "?");
                row.put("created_at",           _rs.getString("created_at") != null ? _rs.getString("created_at") : "?");
                agentList.add(row);
            }
        } catch (Exception ex) {
            if (agentActionMsg.isEmpty()) {
                agentActionMsg  = "? Error loading agents: " + ex.getMessage();
                agentActionType = "err";
            }
        } finally { closeAgentRes(_rs, _ps, _c); }
    }

    SimpleDateFormat aInFmt  = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    SimpleDateFormat aOutFmt = new SimpleDateFormat("dd MMM yyyy");
%>

<%-- ???????????????????????????????????????????????????????????????
     CSS ? paste inside your <head> or alongside your existing styles
???????????????????????????????????????????????????????????????? --%>
<style>
/* ?? Agent Approvals Section ???????????????????????????????????? */
.agent-section        { margin: 1.8rem 0; }
.agent-section-title  {
    font-size: 1rem; font-weight: 700; color: #0f172a;
    display: flex; align-items: center; gap: .5rem; margin-bottom: 1rem;
}
.agent-section-title .pending-pill {
    background: #fef3c7; color: #92400e;
    font-size: .7rem; font-weight: 700; padding: .15rem .55rem;
    border-radius: 20px; margin-left: .3rem;
}

/* stat mini-cards */
.agent-stats          { display: flex; gap: .8rem; flex-wrap: wrap; margin-bottom: 1.2rem; }
.agent-stat-card {
    flex: 1; min-width: 120px;
    background: #fff; border-radius: 10px; padding: .85rem 1rem;
    box-shadow: 0 1px 4px rgba(0,0,0,.07);
    border-top: 3px solid #e2e8f0;
    display: flex; flex-direction: column; gap: .2rem;
}
.agent-stat-card.st-pending  { border-color: #f59e0b; }
.agent-stat-card.st-active   { border-color: #059669; }
.agent-stat-card.st-inactive { border-color: #dc2626; }
.agent-stat-card.st-leave    { border-color: #7c3aed; }
.agent-stat-card.st-total    { border-color: #2563eb; }
.asc-num  { font-size: 1.5rem; font-weight: 700; color: #0f172a; line-height: 1; }
.asc-lbl  { font-size: .7rem;  color: #94a3b8; font-weight: 600; text-transform: uppercase; letter-spacing: .4px; }

/* flash alert */
.agent-alert {
    padding: .75rem 1rem; border-radius: 8px; margin-bottom: 1rem;
    font-size: .86rem; font-weight: 500; display: flex;
    align-items: flex-start; gap: .5rem; border: 1px solid transparent;
    animation: aSlideIn .3s ease;
}
@keyframes aSlideIn { from{opacity:0;transform:translateY(-6px)} to{opacity:1;transform:translateY(0)} }
.agent-alert.ok  { background:#d1fae5; color:#065f46; border-color:#6ee7b7; }
.agent-alert.wrn { background:#ffedd5; color:#7c2d12; border-color:#fdba74; }
.agent-alert.err { background:#fee2e2; color:#7f1d1d; border-color:#fca5a5; }

/* table card */
.agent-card {
    background: #fff; border-radius: 10px;
    box-shadow: 0 1px 4px rgba(0,0,0,.08); overflow: hidden;
}
.agent-card-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: .85rem 1.2rem; border-bottom: 1px solid #f1f5f9;
    font-size: .9rem; font-weight: 700; color: #0f172a;
    flex-wrap: wrap; gap: .5rem;
}
.agent-tbl-wrap { overflow-x: auto; overflow-y: auto; max-height: 420px; }
.agent-tbl {
    width: 100%; border-collapse: collapse;
    font-size: .84rem; min-width: 860px;
}
.agent-tbl thead th {
    background: #f8fafc; color: #64748b;
    font-size: .7rem; font-weight: 700;
    text-transform: uppercase; letter-spacing: .5px;
    padding: .65rem 1rem; border-bottom: 1px solid #e2e8f0;
    white-space: nowrap; text-align: left;
    position: sticky; top: 0; z-index: 2;
}
.agent-tbl tbody td {
    padding: .75rem 1rem; border-bottom: 1px solid #f1f5f9;
    vertical-align: middle;
}
.agent-tbl tbody tr:last-child td { border-bottom: none; }
.agent-tbl tbody tr:hover td      { background: #f8fafc; }

/* agent name cell */
.a-cell   { display: flex; align-items: center; gap: .6rem; }
.a-avatar {
    width: 32px; height: 32px; border-radius: 50%;
    background: linear-gradient(135deg,#1a2f4a,#243b55);
    display: flex; align-items: center; justify-content: center;
    color: #f59e0b; font-weight: 700; font-size: .8rem; flex-shrink: 0;
}
.a-name { font-weight: 600; color: #0f172a; font-size: .86rem; }
.a-id   { font-size: .7rem; color: #94a3b8; margin-top: .05rem; font-family: monospace; }

/* status badges */
.a-badge {
    display: inline-flex; align-items: center; gap: .3rem;
    padding: .2rem .55rem; border-radius: 20px;
    font-size: .7rem; font-weight: 700; white-space: nowrap;
}
.a-badge::before { content:''; width:6px; height:6px; border-radius:50%; background:currentColor; }
.ab-pending  { background:#fef3c7; color:#92400e; }
.ab-active   { background:#d1fae5; color:#065f46; }
.ab-inactive { background:#fee2e2; color:#7f1d1d; }
.ab-onleave  { background:#ede9fe; color:#4c1d95; }

/* progress bar */
.a-prog-wrap { background:#e2e8f0; border-radius:4px; height:5px; margin-top:.3rem; overflow:hidden; width:80px; }
.a-prog-bar  { height:100%; background:#059669; border-radius:4px; transition:.3s; }

/* action buttons */
.a-act-grp { display:flex; gap:.3rem; flex-wrap:wrap; }
.a-btn {
    display: inline-flex; align-items: center; gap: .25rem;
    padding: .28rem .6rem; border-radius: 6px;
    font-size: .74rem; font-weight: 600; border: none;
    cursor: pointer; transition: .18s; font-family: inherit; white-space: nowrap;
}
.a-btn-approve   { background:#059669; color:#fff; }
.a-btn-approve:hover   { background:#047857; }
.a-btn-reject    { background:#dc2626; color:#fff; }
.a-btn-reject:hover    { background:#b91c1c; }
.a-btn-suspend   { background:#ea580c; color:#fff; }
.a-btn-suspend:hover   { background:#c2410c; }
.a-btn-reactive  { background:#2563eb; color:#fff; }
.a-btn-reactive:hover  { background:#1d4ed8; }
.a-btn-view      { background:#f1f5f9; color:#334155; border:1px solid #e2e8f0; }
.a-btn-view:hover      { background:#e2e8f0; }
.a-btn-full {
    display: inline-flex; align-items: center; gap: .35rem;
    padding: .38rem .85rem; background: #0f1c2e; color: #fff;
    border-radius: 7px; font-size: .8rem; font-weight: 600; border: none;
    cursor: pointer; font-family: inherit; text-decoration: none;
    transition: .18s;
}
.a-btn-full:hover { background: #1a2f4a; }

/* empty state */
.agent-empty { text-align:center; padding:3rem 1rem; color:#94a3b8; }
.agent-empty-icon { font-size:2.5rem; margin-bottom:.5rem; }

/* filter tabs */
.agent-tab-row {
    display: flex; gap: 0; padding: 0 1.2rem;
    border-bottom: 1px solid #e2e8f0; background: #f8fafc;
    overflow-x: auto;
}
.agent-tab {
    background: none; border: none; border-bottom: 2px solid transparent;
    padding: .65rem .95rem; font-size: .82rem; font-weight: 600;
    color: #94a3b8; cursor: pointer; margin-bottom: -1px;
    white-space: nowrap; font-family: inherit; transition: .18s;
    display: flex; align-items: center; gap: .35rem;
}
.agent-tab:hover   { color: #334155; }
.agent-tab.at-on   { color: #0f1c2e; border-bottom-color: #f59e0b; }
.agent-tab .at-cnt {
    background: #e2e8f0; color: #64748b;
    font-size: .66rem; font-weight: 700;
    padding: .1rem .38rem; border-radius: 20px;
}
.agent-tab.at-on .at-cnt { background: #f59e0b; color: #0f1c2e; }
</style>

<%-- ???????????????????????????????????????????????????????????????
     HTML SECTION ? paste wherever you want the block in adhome.jsp
???????????????????????????????????????????????????????????????? --%>

<div class="agent-section">

    <!-- Section title -->
    <div class="agent-section-title">
        ? Delivery Agent Approvals
        <% if (aCntPending > 0) { %>
        <span class="pending-pill">? <%= aCntPending %> pending</span>
        <% } %>
    </div>

    <!-- Flash message -->
    <% if (!agentActionMsg.isEmpty()) { %>
    <div class="agent-alert <%= agentActionType %>" id="agentFlash">
        <span><%=agentActionMsg%></span>
        <button onclick="document.getElementById('agentFlash').remove()"
                style="margin-left:auto;background:none;border:none;cursor:pointer;font-size:.95rem;opacity:.5;">?</button>
    </div>
    <% } %>

    <!-- Mini stat row -->
    <div class="agent-stats">
        <div class="agent-stat-card st-pending">
            <div class="asc-num"><%= aCntPending %></div>
            <div class="asc-lbl">? Pending</div>
        </div>
        <div class="agent-stat-card st-active">
            <div class="asc-num"><%= aCntActive %></div>
            <div class="asc-lbl">? Active</div>
        </div>
        <div class="agent-stat-card st-inactive">
            <div class="asc-num"><%= aCntInactive %></div>
            <div class="asc-lbl">? Inactive</div>
        </div>
        <div class="agent-stat-card st-leave">
            <div class="asc-num"><%= aCntOnLeave %></div>
            <div class="asc-lbl">?? Suspended</div>
        </div>
        <div class="agent-stat-card st-total">
            <div class="asc-num"><%= aCntTotal %></div>
            <div class="asc-lbl">? Total</div>
        </div>
    </div>

    <!-- Table card -->
    <div class="agent-card">

        <!-- Card header -->
        <div class="agent-card-head">
            <span>?? Agent Registry ? <span style="font-weight:400; color:#94a3b8; font-size:.82rem;"><%= agentList.size() %> record<%= agentList.size()!=1?"s":"" %></span></span>
            <a href="adhome.jsp" class="a-btn-full">Open Dashboard ?</a>
        </div>

        <!-- Filter tabs (client-side) -->
        <div class="agent-tab-row">
            <button class="agent-tab at-on" id="atab-all"     onclick="filterAgents('all')">
                All <span class="at-cnt"><%= aCntTotal %></span>
            </button>
            <button class="agent-tab"       id="atab-Pending"   onclick="filterAgents('Pending')">
                ? Pending <span class="at-cnt"><%= aCntPending %></span>
            </button>
            <button class="agent-tab"       id="atab-Active"    onclick="filterAgents('Active')">
                ? Active <span class="at-cnt"><%= aCntActive %></span>
            </button>
            <button class="agent-tab"       id="atab-Inactive"  onclick="filterAgents('Inactive')">
                ? Inactive <span class="at-cnt"><%= aCntInactive %></span>
            </button>
            <button class="agent-tab"       id="atab-On Leave"  onclick="filterAgents('On Leave')">
                ?? Suspended <span class="at-cnt"><%= aCntOnLeave %></span>
            </button>
        </div>

        <!-- Scrollable table -->
        <div class="agent-tbl-wrap">
            <% if (agentList.isEmpty()) { %>
            <div class="agent-empty">
                <div class="agent-empty-icon">?</div>
                <div style="font-weight:700;">No agents found</div>
                <div style="font-size:.82rem; margin-top:.3rem;">No records in delivery_agents table.</div>
            </div>
            <% } else { %>
            <table class="agent-tbl" id="agentTable">
                <thead>
                    <tr>
                        <th>#</th>
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
                    int aRowNum = 0;
                    for (Map<String,String> ag : agentList) {
                        aRowNum++;
                        String agId     = ag.get("agent_id");
                        String agName   = ag.get("agent_name");
                        String agStat   = ag.get("agent_status");
                        String agPhone  = ag.get("phone");
                        String agEmail  = ag.get("email");
                        String agVeh    = ag.get("vehicle_type");
                        String agZone   = ag.get("zone");
                        String agLic    = ag.get("license_no");
                        String agTotal  = ag.get("total_deliveries");
                        String agComp   = ag.get("completed_deliveries");
                        String agCrAt   = ag.get("created_at");

                        String agBadge = "Active".equals(agStat)   ? "ab-active"
                                       : "Pending".equals(agStat)  ? "ab-pending"
                                       : "Inactive".equals(agStat) ? "ab-inactive"
                                       : "ab-onleave";

                        String agVehIcon = "Motorcycle".equals(agVeh)    ? "??"
                                         : "Delivery Van".equals(agVeh)  ? "?"
                                         : "Mini Truck".equals(agVeh)    ? "?" : "?";

                        int agT = 0, agC = 0;
                        try { agT = Integer.parseInt(agTotal); agC = Integer.parseInt(agComp); } catch(Exception e2){}
                        int agPct = agT > 0 ? (agC * 100 / agT) : 0;

                        String agDateFmt = agCrAt;
                        try { agDateFmt = aOutFmt.format(aInFmt.parse(agCrAt)); } catch(Exception e2){}
                %>
                <tr data-status="<%= agStat %>">
                    <td style="color:#94a3b8; font-size:.78rem;"><%= aRowNum %></td>

                    <!-- Agent name + ID -->
                    <td>
                        <div class="a-cell">
                            <div class="a-avatar"><%= agName.substring(0,1).toUpperCase() %></div>
                            <div>
                                <div class="a-name"><%= agName %></div>
                                <div class="a-id">#<%= agId %></div>
                            </div>
                        </div>
                    </td>

                    <!-- Contact -->
                    <td>
                        <div style="font-size:.81rem;">? <%= agPhone %></div>
                        <div style="font-size:.74rem; color:#94a3b8; margin-top:.1rem;">?? <%= agEmail %></div>
                    </td>

                    <!-- Vehicle -->
                    <td><span style="font-size:.82rem;"><%= agVehIcon %> <%= agVeh %></span></td>

                    <!-- Zone -->
                    <td><span style="font-size:.82rem; font-weight:500;">? <%= agZone %></span></td>

                    <!-- License -->
                    <td><span style="font-family:monospace; font-size:.79rem;"><%= agLic %></span></td>

                    <!-- Deliveries + progress -->
                    <td>
                        <div style="font-size:.82rem; font-weight:600; color:#0f172a;">
                            <%= agComp %><span style="color:#94a3b8; font-weight:400;">/<%= agTotal %></span>
                        </div>
                        <div class="a-prog-wrap">
                            <div class="a-prog-bar" style="width:<%= agPct %>%;"></div>
                        </div>
                    </td>

                    <!-- Status badge -->
                    <td><span class="a-badge <%= agBadge %>"><%= agStat %></span></td>

                    <!-- Date -->
                    <td style="font-size:.78rem; color:#94a3b8; white-space:nowrap;"><%= agDateFmt %></td>

                    <!-- Action buttons -->
                    <td>
                        <div class="a-act-grp">
                            <% if ("Pending".equals(agStat)) { %>
                                <!-- APPROVE -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('Approve agent <%= agId %>?')">
                                    <input type="hidden" name="agentAction" value="approve">
                                    <input type="hidden" name="agentId"     value="<%= agId %>">
                                    <button type="submit" class="a-btn a-btn-approve">? Approve</button>
                                </form>
                                <!-- REJECT -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('Reject agent <%= agId %>?')">
                                    <input type="hidden" name="agentAction" value="reject">
                                    <input type="hidden" name="agentId"     value="<%= agId %>">
                                    <button type="submit" class="a-btn a-btn-reject">? Reject</button>
                                </form>

                            <% } else if ("Active".equals(agStat)) { %>
                                <!-- SUSPEND -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('Suspend agent <%= agId %>?')">
                                    <input type="hidden" name="agentAction" value="suspend">
                                    <input type="hidden" name="agentId"     value="<%= agId %>">
                                    <button type="submit" class="a-btn a-btn-suspend">? Suspend</button>
                                </form>

                            <% } else if ("Inactive".equals(agStat) || "On Leave".equals(agStat)) { %>
                                <!-- REACTIVATE -->
                                <form method="post" style="display:inline;"
                                      onsubmit="return confirm('Reactivate agent <%= agId %>?')">
                                    <input type="hidden" name="agentAction" value="reactivate">
                                    <input type="hidden" name="agentId"     value="<%= agId %>">
                                    <button type="submit" class="a-btn a-btn-reactive">?? Reactivate</button>
                                </form>
                            <% } %>

                            <!-- Full details link -->
                            <a href="agentApprovals.jsp?tab=all" class="a-btn a-btn-view">? View</a>
                        </div>
                    </td>
                </tr>
                <% } %>
                </tbody>
            </table>
            <% } %>
        </div><!-- /agent-tbl-wrap -->

        <!-- Footer count -->
        <% if (!agentList.isEmpty()) { %>
        <div style="padding:.6rem 1.2rem; border-top:1px solid #f1f5f9;
                    font-size:.76rem; color:#94a3b8; display:flex; justify-content:space-between; align-items:center;">
            <span>Showing all <strong><%= agentList.size() %></strong> agents ? Use tabs to filter</span>
            <a href="agentApprovals.jsp" style="color:#f59e0b; font-weight:600; font-size:.78rem;">Full Approvals Manager ?</a>
        </div>
        <% } %>

    </div><!-- /agent-card -->
</div><!-- /agent-section -->

<%-- ???????????????????????????????????????????????????????????????
     JS ? paste before </body> in adhome.jsp
???????????????????????????????????????????????????????????????? --%>
<script>
/* ?? Client-side tab filter for agent table ???????????????????? */
function filterAgents(status) {
    /* update active tab style */
    document.querySelectorAll('.agent-tab').forEach(t => t.classList.remove('at-on'));
    const activeTab = document.getElementById('atab-' + status);
    if (activeTab) activeTab.classList.add('at-on');

    /* show/hide rows */
    const rows = document.querySelectorAll('#agentTable tbody tr');
    rows.forEach(function(row) {
        if (status === 'all' || row.dataset.status === status) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

/* auto-dismiss flash message after 5s */
const agentFlash = document.getElementById('agentFlash');
if (agentFlash) setTimeout(function(){ agentFlash.remove(); }, 5000);
</script>