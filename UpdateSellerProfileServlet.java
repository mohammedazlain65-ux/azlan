import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * UpdateSellerProfileServlet
 *
 * Handles AJAX POST from sellerprofile.jsp to update the logged-in
 * seller's name, phone and business_name in the `sellers` table.
 *
 * URL:    /updatesellerprofile
 * Input:  POST params — name, phone, businessName
 * Output: JSON  — { "success": true }
 *               — { "success": false, "message": "..." }
 */
@WebServlet("/updatesellerprofile")
public class UpdateSellerProfileServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor"
            + "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        PrintWriter out = response.getWriter();

        /* ── 1. Session check ── */
        HttpSession session = request.getSession(false);
        if (session == null) {
            out.print("{\"success\":false,\"message\":\"Session expired. Please login again.\"}");
            return;
        }

        Object emailObj = session.getAttribute("email");
        if (emailObj == null || emailObj.toString().trim().isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Not logged in.\"}");
            return;
        }
        String sellerEmail = emailObj.toString().trim();

        /* ── 2. Read + validate parameters ── */
        String name         = getParam(request, "name");
        String phone        = getParam(request, "phone");
        String businessName = getParam(request, "businessName");

        if (name.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Full name is required.\"}");
            return;
        }
        if (phone.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Phone number is required.\"}");
            return;
        }
        if (!phone.matches("\\d{7,15}")) {
            out.print("{\"success\":false,\"message\":\"Phone must be 7-15 digits.\"}");
            return;
        }
        if (businessName.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Business name is required.\"}");
            return;
        }
        if (name.length() > 40) {
            out.print("{\"success\":false,\"message\":\"Name must be 40 characters or fewer.\"}");
            return;
        }
        if (businessName.length() > 400) {
            out.print("{\"success\":false,\"message\":\"Business name must be 400 characters or fewer.\"}");
            return;
        }

        /* ── 3. DB update ── */
        Connection conn = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            String sql = "UPDATE sellers SET name = ?, phone = ?, business_name = ? WHERE email = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, name);
            ps.setString(2, phone);
            ps.setString(3, businessName);
            ps.setString(4, sellerEmail);

            int rows = ps.executeUpdate();
            ps.close();

            if (rows > 0) {
                // Also update session username so topbar shows new name
                session.setAttribute("username", name);
                out.print("{\"success\":true}");
            } else {
                out.print("{\"success\":false,\"message\":\"No seller found with this email.\"}");
            }

        } catch (ClassNotFoundException cnfe) {
            out.print("{\"success\":false,\"message\":\"DB driver not found: " + escapeJson(cnfe.getMessage()) + "\"}");
        } catch (SQLException sqle) {
            out.print("{\"success\":false,\"message\":\"DB error: " + escapeJson(sqle.getMessage()) + "\"}");
        } finally {
            if (conn != null) { try { conn.close(); } catch (SQLException ignored) {} }
        }
    }

    /* ── Helpers ── */
    private String getParam(HttpServletRequest request, String param) {
        String v = request.getParameter(param);
        return (v != null) ? v.trim() : "";
    }

    /** Escapes double quotes and backslashes for safe JSON embedding. */
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("sellerprofile.jsp");
    }
}
