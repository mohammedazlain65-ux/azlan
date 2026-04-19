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
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@WebServlet(name = "AddProductServlet", urlPatterns = {"/addprod"})
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,   // 2MB  — buffer threshold before writing to disk
    maxFileSize       = 1024 * 1024 * 10,  // 10MB — max size per individual image
    maxRequestSize    = 1024 * 1024 * 100  // 100MB — raised to support up to 5 x 10MB images
)
public class AddProductServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        // ── Session / auth check ──────────────────────────────────────────────
        HttpSession session = request.getSession();
        String sellerEmail  = (String) session.getAttribute("email");
        String password     = (String) session.getAttribute("password");

        if (sellerEmail == null || password == null || sellerEmail.trim().isEmpty()) {
            response.sendRedirect("ulogout");
            return;
        }

        Connection        con = null;
        PreparedStatement pst = null;

        try {
            // ── Core product fields ───────────────────────────────────────────
            String productName        = request.getParameter("productname");
            String quantity           = request.getParameter("quantity");
            String rate               = request.getParameter("rate");
            String category           = request.getParameter("category");
            String productDescription = request.getParameter("proddis");

            // Validate required core fields
            if (productName        == null || productName.trim().isEmpty()        ||
                quantity           == null || quantity.trim().isEmpty()           ||
                rate               == null || rate.trim().isEmpty()               ||
                category           == null || category.trim().isEmpty()           ||
                productDescription == null || productDescription.trim().isEmpty()) {

                session.setAttribute("errorMessage", "All required fields must be filled!");
                response.sendRedirect("addprod.jsp");
                return;
            }

            // ── Return policy fields ──────────────────────────────────────────
            String   returnAvailable = request.getParameter("returnAvailable"); // "yes" | "no"
            String   returnWindow    = request.getParameter("returnWindow");    // "7","10","15","30"
            String   returnType      = request.getParameter("returnType");      // enum value
            String[] returnCondArr   = request.getParameterValues("returnConditions");
            String   returnNotes     = request.getParameter("returnNotes");

            // Build comma-separated conditions string for DB SET column
            String returnConditions = "";
            if (returnCondArr != null && "yes".equals(returnAvailable)) {
                returnConditions = String.join(",", returnCondArr);
            }

            // If return is not available, nullify all sub-fields
            if (!"yes".equals(returnAvailable)) {
                returnWindow     = null;
                returnType       = null;
                returnConditions = null;
                returnNotes      = null;
            }

            // ── Multi-image upload ────────────────────────────────────────────
            String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads";
            File   uploadDir  = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();

            List<String> imagePaths = new ArrayList<>();

            // Collect only parts belonging to "productimages" that have actual content
            Collection<Part> imageParts = request.getParts().stream()
                .filter(p -> "productimages".equals(p.getName()) && p.getSize() > 0)
                .collect(java.util.stream.Collectors.toList());

            for (Part part : imageParts) {
                String originalName = Paths.get(part.getSubmittedFileName()).getFileName().toString();
                String ext          = originalName.substring(originalName.lastIndexOf("."));
                // Unique name: timestamp + index prevents collisions on rapid submission
                String uniqueName   = "product_" + System.currentTimeMillis() + "_" + imagePaths.size() + ext;
                String filePath     = uploadPath + File.separator + uniqueName;

                try (InputStream in = part.getInputStream()) {
                    Files.copy(in, Paths.get(filePath), StandardCopyOption.REPLACE_EXISTING);
                }
                imagePaths.add("uploads/" + uniqueName);
            }

            // ── Database connection ───────────────────────────────────────────
            Class.forName("com.mysql.jdbc.Driver");
            con = new dbconfig().getConnection();

            // ── Insert product record (with RETURN_GENERATED_KEYS for FK use) ─
            String insertQuery =
                "INSERT INTO adprod " +
                "  (seller_email, pname, quantity, rate, category, proddis, pimage, description, " +
                "   return_available, return_window, return_type, return_conditions, return_notes) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            pst = con.prepareStatement(insertQuery, PreparedStatement.RETURN_GENERATED_KEYS);

            // Core fields — params 1–8
            pst.setString(1, sellerEmail);
            pst.setString(2, productName);
            pst.setString(3, quantity);
            pst.setString(4, rate);
            pst.setString(5, category);
            pst.setString(6, productDescription);
            pst.setString(7, imagePaths.isEmpty() ? "" : imagePaths.get(0)); // primary image fallback
            pst.setString(8, ""); // reserved 'description' column

            // Return policy fields — params 9–13
            pst.setString(9, returnAvailable);

            if (returnWindow != null) {
                pst.setInt(10, Integer.parseInt(returnWindow));
            } else {
                pst.setNull(10, java.sql.Types.TINYINT);
            }

            pst.setString(11, returnType);
            pst.setString(12, (returnConditions == null || returnConditions.isEmpty()) ? null : returnConditions);
            pst.setString(13, returnNotes);

            int rows = pst.executeUpdate();

            // ── Insert image paths into product_images table ──────────────────
            if (rows > 0 && !imagePaths.isEmpty()) {
                ResultSet generatedKeys = pst.getGeneratedKeys();
                if (generatedKeys.next()) {
                    int productId = generatedKeys.getInt(1);

                    String imgInsert =
                        "INSERT INTO product_images (product_id, image_path, is_primary) " +
                        "VALUES (?, ?, ?)";
                    PreparedStatement imgPst = con.prepareStatement(imgInsert);

                    for (int i = 0; i < imagePaths.size(); i++) {
                        imgPst.setInt(1, productId);
                        imgPst.setString(2, imagePaths.get(i));
                        imgPst.setBoolean(3, i == 0); // index 0 = primary image
                        imgPst.addBatch();
                    }
                    imgPst.executeBatch();
                    imgPst.close();
                    generatedKeys.close();
                }
            }

            // ── Redirect based on result ──────────────────────────────────────
            if (rows > 0) {
                session.setAttribute("successMessage", "Product added successfully!");
                response.sendRedirect("viewproduct.jsp");
            } else {
                session.setAttribute("errorMessage", "Failed to add product. Please try again.");
                response.sendRedirect("addprod.jsp");
            }

        } catch (ClassNotFoundException e) {
            session.setAttribute("errorMessage", "Database driver not found: " + e.getMessage());
            response.sendRedirect("addprod.jsp");
            e.printStackTrace();
        } catch (Exception e) {
            session.setAttribute("errorMessage", "Error adding product: " + e.getMessage());
            response.sendRedirect("addprod.jsp");
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
        return "Servlet for adding products with multi-image upload and return policy support";
    }
}
