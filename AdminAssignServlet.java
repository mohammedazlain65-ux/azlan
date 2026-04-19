

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * AdminAssignServlet  -  POST /admin/assign
 * Lets ADMIN assign an unassigned order to a chosen agent.
 *
 * Plug-in points marked with  // TODO: DB
 */
@WebServlet("/admin/assign")
public class AdminAssignServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Admin role guard
        HttpSession session = req.getSession(false);
        String role = (session != null && session.getAttribute("agentRole") != null)
                      ? session.getAttribute("agentRole").toString() : "";
        if (!"ADMIN".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        int orderId = 0;
        int agentId = 0;
        try {
            orderId = Integer.parseInt(req.getParameter("orderId"));
            agentId = Integer.parseInt(req.getParameter("agentId"));
        } catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
            return;
        }

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // dao.assignToAgent(orderId, agentId);
        // ── END TODO ──────────────────────────────────────────────────────

        req.getSession().setAttribute("flashSuccess", "Order assigned successfully!");
        resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
    }
}
