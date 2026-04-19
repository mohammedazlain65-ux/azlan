import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * ProductImagesServlet
 * URL: /productImages?productId=123
 *
 * Returns a JSON array of image paths for a given product.
 * First checks product_images table (multi-image support).
 * Falls back to adprod.pimage if no rows found.
 *
 * Response example:
 *   ["uploads/product_123_0.jpg","uploads/product_123_1.jpg"]
 */
@WebServlet(name = "ProductImagesServlet", urlPatterns = {"/productImages"})
public class ProductImagesServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        // Allow browser to cache for 5 minutes to reduce DB hits
        response.setHeader("Cache-Control", "public, max-age=300");

        String pidParam = request.getParameter("productId");

        // Validate input
        if (pidParam == null || pidParam.trim().isEmpty()) {
            response.getWriter().write("[]");
            return;
        }

        int productId;
        try {
            productId = Integer.parseInt(pidParam.trim());
        } catch (NumberFormatException e) {
            response.getWriter().write("[]");
            return;
        }

        List<String> images = new ArrayList<>();

        Connection        con     = null;
        PreparedStatement pst     = null;
        ResultSet         rs      = null;

        try {
            Class.forName("com.mysql.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            // ── Step 1: Try product_images table (multi-image) ────────────────
            String sql =
                "SELECT image_path FROM product_images " +
                "WHERE product_id = ? " +
                "ORDER BY is_primary DESC, id ASC";   // primary image first

            pst = con.prepareStatement(sql);
            pst.setInt(1, productId);
            rs  = pst.executeQuery();

            while (rs.next()) {
                String path = rs.getString("image_path");
                if (path != null && !path.trim().isEmpty()) {
                    images.add(path.trim());
                }
            }

            // ── Step 2: Fallback to adprod.pimage if no rows in product_images ─
            if (images.isEmpty()) {
                rs.close();  pst.close();

                pst = con.prepareStatement(
                    "SELECT pimage FROM adprod WHERE id = ?");
                pst.setInt(1, productId);
                rs = pst.executeQuery();

                if (rs.next()) {
                    String pimage = rs.getString("pimage");
                    if (pimage != null && !pimage.trim().isEmpty()
                            && !pimage.equalsIgnoreCase("null")
                            && !pimage.equals("0")) {
                        images.add(pimage.trim());
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            // Return empty array on error — JS will show placeholder
        } finally {
            try { if (rs  != null) rs.close();  } catch (Exception ignored) {}
            try { if (pst != null) pst.close(); } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }

        // ── Build JSON array manually (no external library needed) ────────────
        PrintWriter out = response.getWriter();
        out.print("[");
        for (int i = 0; i < images.size(); i++) {
            if (i > 0) out.print(",");
            out.print("\"");
            out.print(escapeJson(images.get(i)));
            out.print("\"");
        }
        out.print("]");
    }

    /** Minimal JSON string escaping */
    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    @Override
    public String getServletInfo() {
        return "Returns JSON array of image paths for a product (multi-image + fallback)";
    }
}