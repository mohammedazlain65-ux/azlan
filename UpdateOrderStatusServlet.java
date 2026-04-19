

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * UpdateOrderStatusServlet
 *
 * Handles status updates from sellerorders.jsp.
 * Responds with JSON so the page can update without full reload.
 *
 * URL:  POST /updateorderstatus
 *
 * Parameters:
 *   orderId    — the order to update
 *   newStatus  — Pending | Processing | Shipped | Delivered | Cancelled
 *
 * Security: only updates if this seller (session email) owns a product in the order.
 */
@WebServlet("/updateorderstatus")
public class UpdateOrderStatusServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // ── Session guard ────────────────────────────────────────────────
        HttpSession session     = request.getSession(false);
        String      sellerEmail = (session != null && session.getAttribute("email") != null)
                                  ? session.getAttribute("email").toString() : null;

        if (sellerEmail == null || sellerEmail.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Not authenticated\"}");
            return;
        }

        String orderId   = request.getParameter("orderId");
        String newStatus = request.getParameter("newStatus");

        if (orderId == null || orderId.trim().isEmpty() ||
            newStatus == null || newStatus.trim().isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Missing parameters\"}");
            return;
        }

        // Whitelist allowed statuses
        String[] allowed = {"Pending","Processing","Shipped","Delivered","Cancelled"};
        boolean valid = false;
        for (String s : allowed) { if (s.equalsIgnoreCase(newStatus)) { newStatus = s; valid = true; break; } }
        if (!valid) {
            out.print("{\"success\":false,\"message\":\"Invalid status value\"}");
            return;
        }

        Connection conn = null;
        PreparedStatement ps = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            // Verify seller owns a product in this order
            ps = conn.prepareStatement(
               // In UpdateOrderStatusServlet.java — find this query and fix it too
               "SELECT COUNT(*) FROM order_items oi " +
               "JOIN adprod ap ON oi.product_id = ap.id " +
               "WHERE oi.order_id = ? AND ap.seller_email = ?");
            ps.setString(1, orderId);
            ps.setString(2, sellerEmail);
            ResultSet rs      = ps.executeQuery();
            boolean   canEdit = rs.next() && rs.getInt(1) > 0;
            rs.close(); ps.close();

            if (!canEdit) {
                out.print("{\"success\":false,\"message\":\"Unauthorized: order does not contain your products\"}");
                return;
            }

            // Perform the update
            ps = conn.prepareStatement(
                "UPDATE orders SET order_status = ? WHERE order_id = ?");
            ps.setString(1, newStatus);
            ps.setString(2, orderId);
            int rows = ps.executeUpdate();

            if (rows > 0) {
                out.print("{\"success\":true,\"message\":\"Status updated to " +
                          escapeJson(newStatus) + "\",\"newStatus\":\"" +
                          escapeJson(newStatus) + "\"}");
            } else {
                out.print("{\"success\":false,\"message\":\"Order not found\"}");
            }

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"DB Error: " +
                      escapeJson(e.getMessage()) + "\"}");
        } finally {
            try { if (ps   != null) ps.close();   } catch (Exception ignored) {}
            try { if (conn != null) conn.close();  } catch (Exception ignored) {}
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}
