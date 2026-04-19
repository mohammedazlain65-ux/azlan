import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * UpdateReturnServlet
 * URL: /UpdateReturnServlet  (POST — called from admin/seller pages)
 *
 * params:
 *   action   = approve | reject | complete
 *   returnId = int
 *   role     = admin | seller
 *   redirect = page to redirect after (default: adminReturns.jsp or sellerReturns.jsp)
 *
 * Rules:
 *   - Admin can set any status.
 *   - Seller can only set Approved / Rejected on Pending requests for their products.
 *   - Only admin can set Completed.
 */
@WebServlet(name = "UpdateReturnServlet", urlPatterns = {"/UpdateReturnServlet"})
public class UpdateReturnServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action    = request.getParameter("action");
        String returnIdS = request.getParameter("returnId");
        String role      = request.getParameter("role");      // "admin" | "seller"
        String redirect  = request.getParameter("redirect");

        if (redirect == null || redirect.trim().isEmpty()) {
            redirect = "admin".equals(role) ? "adminReturns.jsp" : "sellerReturns.jsp";
        }

        // Get caller email from session
        String callerEmail = null;
        try { callerEmail = request.getSession().getAttribute("email").toString(); } catch (Exception e) {}

        if (callerEmail == null || action == null || returnIdS == null) {
            response.sendRedirect(redirect);
            return;
        }

        int returnId;
        try { returnId = Integer.parseInt(returnIdS.trim()); }
        catch (NumberFormatException e) { response.sendRedirect(redirect); return; }

        // Map action → new status
        String newStatus;
        switch (action) {
            case "approve":  newStatus = "Approved";  break;
            case "reject":   newStatus = "Rejected";  break;
            case "complete": newStatus = "Completed"; break;
            default: response.sendRedirect(redirect); return;
        }

        // Sellers cannot mark Complete
        if ("seller".equals(role) && "Completed".equals(newStatus)) {
            response.sendRedirect(redirect);
            return;
        }

        Connection con = null; PreparedStatement pst = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            String sql;
            if ("admin".equals(role)) {
                // Admin: update any return
                sql = "UPDATE return_requests SET return_status=? WHERE return_id=?";
                pst = con.prepareStatement(sql);
                pst.setString(1, newStatus);
                pst.setInt(2, returnId);
            } else {
                // Seller: only update Pending requests for their own products
                sql = "UPDATE return_requests SET return_status=? " +
                      "WHERE return_id=? AND seller_email=? AND return_status='Pending'";
                pst = con.prepareStatement(sql);
                pst.setString(1, newStatus);
                pst.setInt(2, returnId);
                pst.setString(3, callerEmail);
            }
            pst.executeUpdate();

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (pst != null) pst.close(); } catch (Exception ig) {}
            try { if (con != null) con.close(); } catch (Exception ig) {}
        }

        response.sendRedirect(redirect);
    }

    @Override
    public String getServletInfo() {
        return "Handles return request status updates by admin or seller";
    }
}