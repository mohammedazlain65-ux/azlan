import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * ImageServlet — Securely serves uploaded product images from the
 * application's  /uploads/  folder.
 *
 * URL pattern:  /image?file=product_1738234567890.jpg
 *
 * AddProductServlet stores: "uploads/product_XXXXX.ext" in the pimage column.
 * The buyer dashboard calls:
 *      contextPath + "/" + pimage
 *   → /MultiVendor/uploads/product_XXXXX.ext
 *
 * That path is served DIRECTLY by the servlet container because the file
 * sits inside the deployed webapp directory (under /uploads/).
 *
 * ──────────────────────────────────────────────────────────────────────
 * THIS SERVLET IS AN ALTERNATIVE / FALLBACK that you can use if you
 * ever move uploads OUTSIDE the webapp root (e.g. to D:/uploads/).
 * In that case change the buyer dashboard src to:
 *      contextPath + "/image?file=" + productFileName
 * ──────────────────────────────────────────────────────────────────────
 *
 * HOW TO USE THIS SERVLET (optional):
 *   1. Place this file in src/main/java/
 *   2. In buyerdashboard.jsp change imgSrc to:
 *         ctxPath + "/image?file=" + pimage.replace("uploads/","")
 *   3. Set UPLOAD_DIR below to wherever you store your images.
 * ──────────────────────────────────────────────────────────────────────
 */
@WebServlet(name = "ImageServlet", urlPatterns = {"/image"})
public class ImageServlet extends HttpServlet {

    /*  ─── OPTION A (default) ───────────────────────────────────────────
        Images are inside the deployed webapp (standard setup).
        Leave this null — the servlet will resolve the path automatically
        using getServletContext().getRealPath("").
        ─── OPTION B ────────────────────────────────────────────────────
        If you store images OUTSIDE the webapp (e.g. D:/uploads/),
        set the absolute path here:
            private static final String UPLOAD_DIR = "D:/my_project/uploads";
    ─────────────────────────────────────────────────────────────────── */
    private static final String UPLOAD_DIR = null; // null = auto-resolve inside webapp

    // Maximum filename length guard (security)
    private static final int MAX_FILENAME_LEN = 200;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        /* ── 1. Read and validate the 'file' parameter ── */
        String fileName = request.getParameter("file");

        if (fileName == null || fileName.trim().isEmpty()) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST, "Missing 'file' parameter.");
            return;
        }

        // Strip path traversal attempts  (e.g. ../../etc/passwd)
        fileName = new File(fileName).getName();   // keeps only the filename portion

        if (fileName.isEmpty() || fileName.length() > MAX_FILENAME_LEN) {
            sendError(response, HttpServletResponse.SC_BAD_REQUEST, "Invalid filename.");
            return;
        }

        // Allow only safe characters in filename
        if (!fileName.matches("[a-zA-Z0-9_\\-\\.]+")) {
            sendError(response, HttpServletResponse.SC_FORBIDDEN, "Illegal characters in filename.");
            return;
        }

        /* ── 2. Resolve the absolute path to the uploads folder ── */
        String uploadsFolder;
        if (UPLOAD_DIR != null && !UPLOAD_DIR.isEmpty()) {
            // Option B: explicit external directory
            uploadsFolder = UPLOAD_DIR;
        } else {
            // Option A: inside deployed webapp  →  .../webapps/MultiVendor/uploads
            uploadsFolder = getServletContext().getRealPath("") + File.separator + "uploads";
        }

        File imageFile = new File(uploadsFolder + File.separator + fileName);

        /* ── 3. Safety: make sure resolved path is inside the uploads folder ── */
        String canonicalUploads = new File(uploadsFolder).getCanonicalPath();
        String canonicalImage   = imageFile.getCanonicalPath();

        if (!canonicalImage.startsWith(canonicalUploads + File.separator)
                && !canonicalImage.equals(canonicalUploads)) {
            sendError(response, HttpServletResponse.SC_FORBIDDEN, "Access denied.");
            return;
        }

        /* ── 4. Check file exists and is readable ── */
        if (!imageFile.exists() || !imageFile.isFile() || !imageFile.canRead()) {
            // Return the placeholder SVG so the browser shows something nice
            sendPlaceholderSvg(response, "No Image");
            return;
        }

        /* ── 5. Detect MIME type ── */
        String mimeType = Files.probeContentType(imageFile.toPath());
        if (mimeType == null) {
            // Fallback MIME based on extension
            String ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
            switch (ext) {
                case "jpg": case "jpeg": mimeType = "image/jpeg"; break;
                case "png":              mimeType = "image/png";  break;
                case "gif":              mimeType = "image/gif";  break;
                case "webp":             mimeType = "image/webp"; break;
                case "svg":              mimeType = "image/svg+xml"; break;
                default:                 mimeType = "application/octet-stream";
            }
        }

        // Only serve image types (security: block accidental non-image files)
        if (!mimeType.startsWith("image/")) {
            sendError(response, HttpServletResponse.SC_FORBIDDEN, "Not an image file.");
            return;
        }

        /* ── 6. Set caching headers (images don't change often) ── */
        response.setContentType(mimeType);
        response.setContentLengthLong(imageFile.length());
        response.setHeader("Cache-Control", "public, max-age=86400"); // 1 day
        response.setDateHeader("Last-Modified", imageFile.lastModified());

        /* ── 7. Stream the image bytes to the browser ── */
        try (FileInputStream fis = new FileInputStream(imageFile);
             OutputStream out    = response.getOutputStream()) {

            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }

    /* ── Helper: send an HTTP error with plain text ── */
    private void sendError(HttpServletResponse response, int code, String message) throws IOException {
        response.sendError(code, message);
    }

    /* ── Helper: return a simple SVG placeholder when image is missing ── */
    private void sendPlaceholderSvg(HttpServletResponse response, String label) throws IOException {
        response.setContentType("image/svg+xml");
        response.setHeader("Cache-Control", "no-cache");
        String svg =
            "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300' viewBox='0 0 300 300'>" +
            "<rect width='300' height='300' fill='#f0f4ff'/>" +
            "<rect x='1' y='1' width='298' height='298' fill='none' stroke='#c7d2fe' stroke-width='2' rx='8'/>" +
            "<text x='150' y='130' font-family='sans-serif' font-size='48' text-anchor='middle' fill='#a5b4fc'>&#128247;</text>" +
            "<text x='150' y='175' font-family='sans-serif' font-size='14' text-anchor='middle' fill='#6366f1' font-weight='600'>No Image Available</text>" +
            "</svg>";
        response.getWriter().write(svg);
    }

    @Override
    public String getServletInfo() {
        return "Serves uploaded product images from the /uploads/ folder securely.";
    }
}
