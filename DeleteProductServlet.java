

import DataBase.dbconfig;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "DeleteProductServlet", urlPatterns = {"/deleteProduct"})
public class DeleteProductServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        
        // Get session and verify user is logged in
        HttpSession session = request.getSession();
        String sellerEmail = (String) session.getAttribute("email");
        String password = (String) session.getAttribute("password");
        
        // Check if user is logged in
        if (sellerEmail == null || password == null || sellerEmail.trim().isEmpty()) {
            response.sendRedirect("ulogout");
            return;
        }
        
        Connection con = null;
        PreparedStatement pst = null;
        ResultSet rs = null;
        
        try {
            // Get product ID to delete
            String productId = request.getParameter("id");
            
            if (productId == null || productId.trim().isEmpty()) {
                session.setAttribute("errorMessage", "Invalid product ID!");
                response.sendRedirect("viewproduct.jsp");
                return;
            }
            
            // Load MySQL Driver
            Class.forName("com.mysql.jdbc.Driver");
            
            // Get database connection
            con = new dbconfig().getConnection();
            
            // SECURITY: First verify this product belongs to the logged-in seller
            String verifyQuery = "SELECT seller_email FROM adprod WHERE id = ?";
            pst = con.prepareStatement(verifyQuery);
            pst.setString(1, productId);
            rs = pst.executeQuery();
            
            if (rs.next()) {
                String productOwnerEmail = rs.getString("seller_email");
                
                // Check if the logged-in seller owns this product
                if (!sellerEmail.equals(productOwnerEmail)) {
                    session.setAttribute("errorMessage", "You don't have permission to delete this product!");
                    response.sendRedirect("viewproduct.jsp");
                    return;
                }
                
                // Close the verify statement
                rs.close();
                pst.close();
                
                // Now delete the product (seller is verified as owner)
                String deleteQuery = "DELETE FROM adprod WHERE id = ? AND seller_email = ?";
                pst = con.prepareStatement(deleteQuery);
                pst.setString(1, productId);
                pst.setString(2, sellerEmail); // Double-check with email too
                
                int rowsAffected = pst.executeUpdate();
                
                if (rowsAffected > 0) {
                    session.setAttribute("successMessage", "Product deleted successfully!");
                } else {
                    session.setAttribute("errorMessage", "Failed to delete product.");
                }
                
            } else {
                session.setAttribute("errorMessage", "Product not found!");
            }
            
            response.sendRedirect("viewproduct.jsp");
            
        } catch (ClassNotFoundException e) {
            session.setAttribute("errorMessage", "Database driver not found: " + e.getMessage());
            response.sendRedirect("viewproduct.jsp");
            e.printStackTrace();
        } catch (Exception e) {
            session.setAttribute("errorMessage", "Error deleting product: " + e.getMessage());
            response.sendRedirect("viewproduct.jsp");
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
                if (pst != null) pst.close();
                if (con != null) con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public String getServletInfo() {
        return "Servlet for deleting products with ownership verification";
    }
}
