import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * ReturnServlet
 * URL: /ReturnServlet (POST)
 *
 * Handles return requests submitted by customers for delivered order items.
 * One return request per product per order per customer.
 *
 * Required DB table:
 *   CREATE TABLE return_requests (
 *       return_id          INT AUTO_INCREMENT PRIMARY KEY,
 *       order_id           VARCHAR(100) NOT NULL,
 *       product_id         INT NOT NULL,
 *       customer_email     VARCHAR(255) NOT NULL,
 *       seller_email       VARCHAR(255),
 *       return_reason      VARCHAR(255) NOT NULL,
 *       return_description TEXT,
 *       return_status      ENUM('Pending','Approved','Rejected','Completed') DEFAULT 'Pending',
 *       created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *       updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *       UNIQUE KEY uq_return (order_id, product_id, customer_email)
 *   );
 */
@WebServlet(name = "ReturnServlet", urlPatterns = {"/ReturnServlet"})
public class ReturnServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        HttpSession session = request.getSession();
        String customerEmail = null;
        try { customerEmail = session.getAttribute("email").toString(); } catch (Exception e) {}

        // Auth check
        if (customerEmail == null || customerEmail.trim().isEmpty()) {
            response.sendRedirect("ulogout");
            return;
        }

        String action   = request.getParameter("action");
        String redirect = request.getParameter("redirect");
        if (redirect == null || redirect.trim().isEmpty()) redirect = "myorders.jsp";

        // ── SUBMIT return request ──────────────────────────────────────────
        if ("submit".equals(action)) {
            String orderId     = request.getParameter("r_order_id");
            String productIdSt = request.getParameter("r_product_id");
            String sellerEmail = request.getParameter("r_seller_email");
            String reason      = request.getParameter("r_reason");
            String description = request.getParameter("r_description");

            // Validate required fields
            if (orderId == null || orderId.trim().isEmpty() ||
                productIdSt == null || productIdSt.trim().isEmpty() ||
                reason == null || reason.trim().isEmpty()) {
                session.setAttribute("returnMsg", "Please fill in all required fields.");
                session.setAttribute("returnOk", false);
                response.sendRedirect(redirect);
                return;
            }

            int productId;
            try { productId = Integer.parseInt(productIdSt); }
            catch (NumberFormatException e) {
                session.setAttribute("returnMsg", "Invalid product. Please try again.");
                session.setAttribute("returnOk", false);
                response.sendRedirect(redirect);
                return;
            }

            Connection con = null; PreparedStatement pst = null; ResultSet rs = null;

            try {
                Class.forName("com.mysql.jdbc.Driver");
                con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

                // ── Verify order belongs to customer and is Delivered ──
                String verifySql =
                    "SELECT order_status FROM orders WHERE order_id=? AND customer_email=?";
                pst = con.prepareStatement(verifySql);
                pst.setString(1, orderId);
                pst.setString(2, customerEmail);
                rs = pst.executeQuery();

                if (!rs.next()) {
                    session.setAttribute("returnMsg", "Order not found or access denied.");
                    session.setAttribute("returnOk", false);
                    response.sendRedirect(redirect);
                    return;
                }
                String orderStatus = rs.getString("order_status");
                if (!"Delivered".equalsIgnoreCase(orderStatus)) {
                    session.setAttribute("returnMsg", "Returns are only allowed for delivered orders.");
                    session.setAttribute("returnOk", false);
                    response.sendRedirect(redirect);
                    return;
                }
                rs.close(); pst.close();

                // ── Check duplicate return request ──
                String dupSql =
                    "SELECT return_id FROM return_requests " +
                    "WHERE order_id=? AND product_id=? AND customer_email=?";
                pst = con.prepareStatement(dupSql);
                pst.setString(1, orderId);
                pst.setInt(2, productId);
                pst.setString(3, customerEmail);
                rs = pst.executeQuery();
                if (rs.next()) {
                    session.setAttribute("returnMsg", "A return request for this item already exists.");
                    session.setAttribute("returnOk", false);
                    response.sendRedirect(redirect);
                    return;
                }
                rs.close(); pst.close();

                // ── Verify product belongs to this order ──
                String itemSql =
                    "SELECT product_id FROM order_items WHERE order_id=? AND product_id=?";
                pst = con.prepareStatement(itemSql);
                pst.setString(1, orderId);
                pst.setInt(2, productId);
                rs = pst.executeQuery();
                if (!rs.next()) {
                    session.setAttribute("returnMsg", "Product not found in this order.");
                    session.setAttribute("returnOk", false);
                    response.sendRedirect(redirect);
                    return;
                }
                rs.close(); pst.close();

                // ── Insert return request ──
                String insertSql =
                    "INSERT INTO return_requests " +
                    "(order_id, product_id, customer_email, seller_email, return_reason, return_description, return_status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, 'Pending')";
                pst = con.prepareStatement(insertSql);
                pst.setString(1, orderId);
                pst.setInt(2, productId);
                pst.setString(3, customerEmail);
                pst.setString(4, (sellerEmail != null && !sellerEmail.trim().isEmpty()) ? sellerEmail.trim() : null);
                pst.setString(5, reason.trim());
                pst.setString(6, (description != null && !description.trim().isEmpty()) ? description.trim() : null);
                int rows = pst.executeUpdate();

                if (rows > 0) {
                    session.setAttribute("returnMsg",
                        "Return request submitted! The seller will review it within 2\u20133 business days.");
                    session.setAttribute("returnOk", true);
                } else {
                    session.setAttribute("returnMsg", "Failed to submit return. Please try again.");
                    session.setAttribute("returnOk", false);
                }

            } catch (Exception e) {
                e.printStackTrace();
                session.setAttribute("returnMsg", "Error processing return: " + e.getMessage());
                session.setAttribute("returnOk", false);
            } finally {
                try { if (rs  != null) rs.close();  } catch (Exception ig) {}
                try { if (pst != null) pst.close(); } catch (Exception ig) {}
                try { if (con != null) con.close(); } catch (Exception ig) {}
            }

        // ── CANCEL return request (customer cancels a Pending request) ────
        } else if ("cancel".equals(action)) {
            String returnIdSt = request.getParameter("r_return_id");
            int returnId;
            try { returnId = Integer.parseInt(returnIdSt); }
            catch (Exception e) {
                session.setAttribute("returnMsg", "Invalid request.");
                session.setAttribute("returnOk", false);
                response.sendRedirect(redirect);
                return;
            }

            Connection con = null; PreparedStatement pst = null;
            try {
                Class.forName("com.mysql.jdbc.Driver");
                con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                // Only allow cancelling own Pending requests
                String cancelSql =
                    "DELETE FROM return_requests " +
                    "WHERE return_id=? AND customer_email=? AND return_status='Pending'";
                pst = con.prepareStatement(cancelSql);
                pst.setInt(1, returnId);
                pst.setString(2, customerEmail);
                int rows = pst.executeUpdate();
                if (rows > 0) {
                    session.setAttribute("returnMsg", "Return request cancelled successfully.");
                    session.setAttribute("returnOk", true);
                } else {
                    session.setAttribute("returnMsg", "Could not cancel. Request may already be processed.");
                    session.setAttribute("returnOk", false);
                }
            } catch (Exception e) {
                session.setAttribute("returnMsg", "Error: " + e.getMessage());
                session.setAttribute("returnOk", false);
            } finally {
                try { if (pst != null) pst.close(); } catch (Exception ig) {}
                try { if (con != null) con.close(); } catch (Exception ig) {}
            }
        }

        response.sendRedirect(redirect);
    }

    @Override
    public String getServletInfo() {
        return "Handles product return requests from customers for delivered orders";
    }
}
