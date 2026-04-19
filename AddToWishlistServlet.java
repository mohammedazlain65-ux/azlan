import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/addtowishlist")
public class AddToWishlistServlet extends HttpServlet {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/multi_vendor";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String userEmail = (String) session.getAttribute("email");
        
        // Check if user is logged in
        if (userEmail == null || userEmail.isEmpty()) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String action = request.getParameter("action");
        String productIdStr = request.getParameter("productId");
        
        if (productIdStr == null || productIdStr.isEmpty()) {
            response.sendRedirect("buyerdashboard.jsp");
            return;
        }
        
        int productId = Integer.parseInt(productIdStr);
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            
            if ("add".equals(action)) {
                // Check if already in wishlist
                String checkSql = "SELECT id FROM wishlist WHERE user_email = ? AND product_id = ?";
                pstmt = conn.prepareStatement(checkSql);
                pstmt.setString(1, userEmail);
                pstmt.setInt(2, productId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    // Already in wishlist
                    session.setAttribute("wishlistMessage", "Product already in your wishlist!");
                    session.setAttribute("wishlistMessageType", "warning");
                } else {
                    // Add to wishlist
                    String insertSql = "INSERT INTO wishlist (user_email, product_id, added_date) VALUES (?, ?, NOW())";
                    pstmt = conn.prepareStatement(insertSql);
                    pstmt.setString(1, userEmail);
                    pstmt.setInt(2, productId);
                    int result = pstmt.executeUpdate();
                    
                    if (result > 0) {
                        session.setAttribute("wishlistMessage", "Product added to wishlist successfully!");
                        session.setAttribute("wishlistMessageType", "success");
                    } else {
                        session.setAttribute("wishlistMessage", "Failed to add product to wishlist.");
                        session.setAttribute("wishlistMessageType", "error");
                    }
                }
                
            } else if ("remove".equals(action)) {
                // Remove from wishlist
                String deleteSql = "DELETE FROM wishlist WHERE user_email = ? AND product_id = ?";
                pstmt = conn.prepareStatement(deleteSql);
                pstmt.setString(1, userEmail);
                pstmt.setInt(2, productId);
                int result = pstmt.executeUpdate();
                
                if (result > 0) {
                    session.setAttribute("wishlistMessage", "Product removed from wishlist.");
                    session.setAttribute("wishlistMessageType", "success");
                } else {
                    session.setAttribute("wishlistMessage", "Failed to remove product from wishlist.");
                    session.setAttribute("wishlistMessageType", "error");
                }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("wishlistMessage", "Error: " + e.getMessage());
            session.setAttribute("wishlistMessageType", "error");
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        
        // Redirect back to referring page or dashboard
        String referer = request.getHeader("Referer");
        if (referer != null && !referer.isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect("buyerdashboard.jsp");
        }
    }
}