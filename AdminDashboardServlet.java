

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.*;

/**
 * AdminDashboardServlet  -  GET /admin/dashboard
 * Loads admin stats and forwards to admin-dashboard.jsp.
 *
 * Plug-in points marked with  // TODO: DB
 */
@WebServlet("/admin/dashboard")
public class AdminDashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Admin role guard
        HttpSession session = req.getSession(false);
        String role = (session != null && session.getAttribute("agentRole") != null)
                      ? session.getAttribute("agentRole").toString() : "";
        if (!"ADMIN".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/pages/dashboard.jsp");
            return;
        }

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO odao = new OrderDAO();
        // AgentDAO adao = new AgentDAO();
        //
        // int total     = odao.countAll();
        // int pending   = odao.countByStatus("Pending");
        // int inTransit = odao.countByStatus("In Transit") + ...;
        // int delivered = odao.countByStatus("Delivered");
        //
        // Build List<String[]> pendingOrders each:
        //   [tracking,custName,productDesc,pickupDate,charges,orderId]
        //
        // Build List<String[]> allAgents each:
        //   [agentId,fullName,email,phone,city,vehicleType,licenseNumber,role,createdAt]
        int total = 0, pending = 0, inTransit = 0, delivered = 0;
        List<String[]> pendingOrders = new ArrayList<>();
        List<String[]> allAgents     = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("totalOrders",    total);
        req.setAttribute("pendingCount",   pending);
        req.setAttribute("inTransitCount", inTransit);
        req.setAttribute("deliveredCount", delivered);
        req.setAttribute("pendingOrders",  pendingOrders);
        req.setAttribute("allAgents",      allAgents);
        req.getRequestDispatcher("/pages/admin-dashboard.jsp").forward(req, resp);
    }
}
