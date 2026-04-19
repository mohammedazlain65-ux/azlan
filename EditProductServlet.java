

import DataBase.dbconfig;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet(name = "EditProductServlet", urlPatterns = {"/edit"})
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2MB
    maxFileSize = 1024 * 1024 * 10,       // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class EditProductServlet extends HttpServlet {

    /**
     * Handles the HTTP GET request to display the edit form
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        String email = (String) session.getAttribute("email");
        String password = (String) session.getAttribute("password");
        
        // Check if user is logged in
        if (email == null || password == null) {
            response.sendRedirect("ulogout");
            return;
        }
        
        // Forward to the edit.jsp page
        request.getRequestDispatcher("edit.jsp").forward(request, response);
    }

    /**
     * Handles the HTTP POST request to update product details
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html;charset=UTF-8");
        
        HttpSession session = request.getSession();
        String email = (String) session.getAttribute("email");
        String password = (String) session.getAttribute("password");
        
        // Check if user is logged in
        if (email == null || password == null) {
            response.sendRedirect("ulogout");
            return;
        }
        
        Connection con = null;
        PreparedStatement pst = null;
        
        try {
            // Get form parameters
            String id = request.getParameter("id");
            String oname = request.getParameter("oname"); // Original product name
            String pname = request.getParameter("pname");
            String quantity = request.getParameter("quantity");
            String rate = request.getParameter("rate");
            String category = request.getParameter("category");
            String proddis = request.getParameter("proddis");
            String description = request.getParameter("description");
            Part productImagePart = request.getPart("productimage");
            
            // Validate required fields
            if (pname == null || pname.trim().isEmpty() ||
                quantity == null || quantity.trim().isEmpty() ||
                rate == null || rate.trim().isEmpty() ||
                category == null || category.trim().isEmpty() ||
                proddis == null || proddis.trim().isEmpty()) {
                
                session.setAttribute("errorMessage", "All required fields must be filled!");
                response.sendRedirect("edit.jsp?id=" + id);
                return;
            }
            
            // Load MySQL Driver
            Class.forName("com.mysql.jdbc.Driver");
            
            // Get database connection
            con = new dbconfig().getConnection();
            
            String imagePath = null;
            
            // Check if a new image was uploaded
            if (productImagePart != null && productImagePart.getSize() > 0) {
                String fileName = Paths.get(productImagePart.getSubmittedFileName()).getFileName().toString();
                
                // Generate unique filename
                String timestamp = String.valueOf(System.currentTimeMillis());
                String extension = fileName.substring(fileName.lastIndexOf("."));
                String uniqueFileName = "product_" + timestamp + extension;
                
                // Define upload path (adjust according to your project structure)
                String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }
                
                // Save file
                String filePath = uploadPath + File.separator + uniqueFileName;
                try (InputStream input = productImagePart.getInputStream()) {
                    Files.copy(input, Paths.get(filePath), StandardCopyOption.REPLACE_EXISTING);
                }
                
                // Set relative path for database
                imagePath = "uploads/" + uniqueFileName;
            } else {
                // No new image uploaded, keep the existing one
                PreparedStatement selectPst = con.prepareStatement(
                    "SELECT pimage FROM adprod WHERE id = ?"
                );
                selectPst.setString(1, id);
                ResultSet rs = selectPst.executeQuery();
                if (rs.next()) {
                    imagePath = rs.getString("pimage");
                }
                rs.close();
                selectPst.close();
            }
            
            // Update product in database
            String updateQuery = "UPDATE adprod SET pname=?, quantity=?, rate=?, category=?, proddis=?, description=?, pimage=? WHERE id=?";
            pst = con.prepareStatement(updateQuery);
            
            pst.setString(1, pname);
            pst.setString(2, quantity);
            pst.setString(3, rate);
            pst.setString(4, category);
            pst.setString(5, proddis);
            pst.setString(6, description != null ? description : "");
            pst.setString(7, imagePath);
            pst.setString(8, id);
            
            int rowsAffected = pst.executeUpdate();
            
            if (rowsAffected > 0) {
                session.setAttribute("successMessage", "Product updated successfully!");
                response.sendRedirect("viewproduct.jsp");
            } else {
                session.setAttribute("errorMessage", "Failed to update product. Please try again.");
                response.sendRedirect("edit.jsp?id=" + id);
            }
            
        } catch (ClassNotFoundException e) {
            session.setAttribute("errorMessage", "Database driver not found: " + e.getMessage());
            response.sendRedirect("edit.jsp?id=" + request.getParameter("id"));
            e.printStackTrace();
        } catch (Exception e) {
            session.setAttribute("errorMessage", "Error updating product: " + e.getMessage());
            response.sendRedirect("edit.jsp?id=" + request.getParameter("id"));
            e.printStackTrace();
        } finally {
            try {
                if (pst != null) pst.close();
                if (con != null) con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public String getServletInfo() {
        return "Servlet for editing product details";
    }
}
