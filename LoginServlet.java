

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * LoginServlet  -  POST /login
 *
 * Plug-in points marked with  // TODO: DB
 * Replace those blocks with your AgentDAO / JDBC calls.
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String email    = req.getParameter("email");
        String password = req.getParameter("password");

        if (isBlank(email) || isBlank(password)) {
            req.setAttribute("error", "Email and password are required.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }
        email = email.trim().toLowerCase();

        // ── TODO: DB ─────────────────────────────────────────────────────────
        // AgentDAO dao = new AgentDAO();
        // Agent agent  = dao.findByEmail(email);
        // boolean valid = agent != null && PasswordUtil.verify(password, agent.getPasswordHash());
        //
        // Placeholder variables (replace with real DB values):
        boolean agentFound    = false;
        boolean passwordValid = false;
        String  agentName     = null;
        String  agentRole     = null;
        String  agentCity     = null;
        String  agentVehicle  = null;
        String  agentEmail    = null;
        String  agentPhone    = null;
        String  agentLicense  = null;
        String  agentAddress  = null;
        String  agentSince    = null;
        int     agentId       = 0;
        // ── END TODO ──────────────────────────────────────────────────────────

        if (!agentFound || !passwordValid) {
            req.setAttribute("error", "Invalid email or password.");
            req.setAttribute("email", email);
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        HttpSession session = req.getSession(true);
        session.setAttribute("agentId",           agentId);
        session.setAttribute("agentName",          agentName);
        session.setAttribute("agentRole",          agentRole);
        session.setAttribute("agentEmail",         agentEmail);
        session.setAttribute("agentPhone",         agentPhone);
        session.setAttribute("agentCity",          agentCity);
        session.setAttribute("agentVehicleType",   agentVehicle);
        session.setAttribute("agentLicenseNumber", agentLicense);
        session.setAttribute("agentAddress",       agentAddress);
        session.setAttribute("agentMemberSince",   agentSince);
        session.setMaxInactiveInterval(60 * 60);

        if ("ADMIN".equals(agentRole)) {
            resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
        } else {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect(req.getContextPath() + "/login.jsp");
    }

    private boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }
}
