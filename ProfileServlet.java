

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * ProfileServlet  -  /profile
 * GET  -> forward to profile.jsp
 * POST -> updateProfile  |  changePassword
 *
 * Plug-in points marked with  // TODO: DB
 */
@WebServlet("/profile")
public class ProfileServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher("/pages/profile.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action  = req.getParameter("action");
        HttpSession session = req.getSession(false);
        if (session == null) { resp.sendRedirect(req.getContextPath() + "/login.jsp"); return; }

        int agentId = (session.getAttribute("agentId") != null)
                      ? (Integer) session.getAttribute("agentId") : 0;

        if ("updateProfile".equals(action)) {
            String fullName    = req.getParameter("fullName");
            String phone       = req.getParameter("phone");
            String address     = req.getParameter("address");
            String city        = req.getParameter("city");
            String vehicleType = req.getParameter("vehicleType");

            // ── TODO: DB ─────────────────────────────────────────────────
            // AgentDAO dao = new AgentDAO();
            // boolean ok = dao.updateProfile(agentId, fullName, phone, address, city, vehicleType);
            boolean ok = false;  // replace with real DB update
            // ── END TODO ─────────────────────────────────────────────────

            if (ok) {
                // Refresh session attributes
                session.setAttribute("agentName",        fullName);
                session.setAttribute("agentPhone",       phone);
                session.setAttribute("agentAddress",     address);
                session.setAttribute("agentCity",        city);
                session.setAttribute("agentVehicleType", vehicleType);
                req.setAttribute("success", "Profile updated successfully!");
            } else {
                req.setAttribute("error", "Profile update failed. Please try again.");
            }
            req.getRequestDispatcher("/pages/profile.jsp").forward(req, resp);

        } else if ("changePassword".equals(action)) {
            String currentPwd = req.getParameter("currentPassword");
            String newPwd     = req.getParameter("newPassword");
            String confirmPwd = req.getParameter("confirmPassword");

            // ── TODO: DB ─────────────────────────────────────────────────
            // String storedHash = dao.getPasswordHash(agentId);
            // boolean currentOk = PasswordUtil.verify(currentPwd, storedHash);
            boolean currentOk = false;  // replace with real hash check
            // ── END TODO ─────────────────────────────────────────────────

            if (!currentOk) {
                req.setAttribute("pwdError", "Current password is incorrect.");
            } else if (newPwd == null || newPwd.length() < 8) {
                req.setAttribute("pwdError", "New password must be at least 8 characters.");
            } else if (!newPwd.equals(confirmPwd)) {
                req.setAttribute("pwdError", "New passwords do not match.");
            } else {
                // ── TODO: DB ─────────────────────────────────────────────
                // String newHash = PasswordUtil.hash(newPwd);
                // boolean saved  = dao.changePassword(agentId, newHash);
                boolean saved = false;  // replace with real DB update
                // ── END TODO ─────────────────────────────────────────────
                if (saved) {
                    req.setAttribute("pwdSuccess", "Password changed successfully!");
                } else {
                    req.setAttribute("pwdError", "Password change failed. Try again.");
                }
            }
            req.getRequestDispatcher("/pages/profile.jsp").forward(req, resp);
        }
    }
}
