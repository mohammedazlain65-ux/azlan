import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.nio.file.*;

/**
 * RegisterServlet  -  POST /register
 * Handles multipart/form-data (ID proof file upload is optional).
 *
 * Plug-in points marked with  // TODO: DB
 */
@WebServlet("/register")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 5  * 1024 * 1024,
    maxRequestSize    = 10 * 1024 * 1024
)
public class RegisterServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String fullName      = req.getParameter("fullName");
        String email         = req.getParameter("email");
        String phone         = req.getParameter("phone");
        String address       = req.getParameter("address");
        String city          = req.getParameter("city");
        String password      = req.getParameter("password");
        String confirmPwd    = req.getParameter("confirmPassword");
        String vehicleType   = req.getParameter("vehicleType");
        String licenseNumber = req.getParameter("licenseNumber");

        // ── Validation ────────────────────────────────────────────────────
        String error = validate(fullName, email, phone, address, city,
                                password, confirmPwd, vehicleType, licenseNumber);
        if (error != null) {
            req.setAttribute("error", error);
            preserveFormValues(req, fullName, email, phone, address, city, vehicleType, licenseNumber);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // ── TODO: DB  -  duplicate email check ────────────────────────────
        // AgentDAO dao = new AgentDAO();
        // if (dao.emailExists(email.trim().toLowerCase())) { ... }
        boolean emailAlreadyExists = false;  // replace with real DB check
        // ── END TODO ──────────────────────────────────────────────────────

        if (emailAlreadyExists) {
            req.setAttribute("error", "An account with this email already exists.");
            preserveFormValues(req, fullName, email, phone, address, city, vehicleType, licenseNumber);
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
            return;
        }

        // ── File upload (optional) ─────────────────────────────────────────
        String idProofPath = null;
        Part filePart = req.getPart("idProof");
        if (filePart != null && filePart.getSize() > 0) {
            // FIX: use super.getServletContext() — no override needed, inherited from GenericServlet
            String uploadDir = super.getServletContext().getRealPath("/uploads/id_proofs/");
            Files.createDirectories(Paths.get(uploadDir));
            String fileName = System.currentTimeMillis() + "_" + sanitize(filePart.getSubmittedFileName());
            filePart.write(uploadDir + File.separator + fileName);
            idProofPath = "uploads/id_proofs/" + fileName;
        }

        // ── TODO: DB  -  save agent ───────────────────────────────────────
        // String hashedPassword = PasswordUtil.hash(password);
        // Agent agent = new Agent();
        // agent.setFullName(fullName.trim()); agent.setEmail(email.trim().toLowerCase());
        // ... set all fields ...
        // boolean saved = dao.register(agent);
        boolean saved = false;  // replace with real DB save
        // ── END TODO ──────────────────────────────────────────────────────

        if (saved) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp?registered=true");
        } else {
            req.setAttribute("error", "Registration failed. License number may already be registered.");
            req.getRequestDispatcher("/register.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect(req.getContextPath() + "/register.jsp");
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private String validate(String fullName, String email, String phone, String address,
                             String city, String password, String confirmPwd,
                             String vehicleType, String license) {
        if (isBlank(fullName))     return "Full name is required.";
        if (isBlank(email))        return "Email is required.";
        if (!email.matches("^[\\w._%+\\-]+@[\\w.\\-]+\\.[a-zA-Z]{2,}$"))
                                    return "Enter a valid email address.";
        if (isBlank(phone))        return "Phone number is required.";
        if (!phone.matches("^[6-9]\\d{9}$"))
                                    return "Enter a valid 10-digit Indian mobile number.";
        if (isBlank(address))      return "Address is required.";
        if (isBlank(city))         return "City is required.";
        if (isBlank(password))     return "Password is required.";
        if (password.length() < 8) return "Password must be at least 8 characters.";
        if (!password.equals(confirmPwd)) return "Passwords do not match.";
        if (isBlank(vehicleType))  return "Vehicle type is required.";
        if (isBlank(license))      return "License number is required.";
        return null;
    }

    // FIX: use trim().isEmpty() instead of isBlank() for Java 8 compatibility
    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private String sanitize(String name) {
        return name == null ? "file" : name.replaceAll("[^a-zA-Z0-9.\\-_]", "_");
    }

    private void preserveFormValues(HttpServletRequest req, String fullName, String email,
                                    String phone, String address, String city,
                                    String vehicleType, String license) {
        req.setAttribute("v_fullName",      fullName);
        req.setAttribute("v_email",         email);
        req.setAttribute("v_phone",         phone);
        req.setAttribute("v_address",       address);
        req.setAttribute("v_city",          city);
        req.setAttribute("v_vehicleType",   vehicleType);
        req.setAttribute("v_licenseNumber", license);
    }

    // FIX: DELETED the bogus getServletContext() override that was here.
    // HttpServlet inherits a correct ServletContext-returning version from GenericServlet.
}