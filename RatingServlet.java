package com.markethub.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * RatingServlet — handles all product_ratings table operations.
 *
 * Mapped URLs:
 *   POST  /RatingServlet?action=submit   — insert or update a rating
 *   POST  /RatingServlet?action=delete   — delete a rating
 *   GET   /RatingServlet?action=get      — fetch a single rating (JSON)
 *   GET   /RatingServlet?action=list     — fetch all ratings for an order (JSON)
 *
 * Database table: product_ratings
 *   id, order_id, product_id, product_name, customer_email,
 *   seller_email, rating (1-5), review_comment, rated_at
 *
 * Registration in web.xml (if not using annotations):
 *   <servlet>
 *     <servlet-name>RatingServlet</servlet-name>
 *     <servlet-class>com.markethub.servlet.RatingServlet</servlet-class>
 *   </servlet>
 *   <servlet-mapping>
 *     <servlet-name>RatingServlet</servlet-name>
 *     <url-pattern>/RatingServlet</url-pattern>
 *   </servlet-mapping>
 */
@WebServlet("/RatingServlet")
public class RatingServlet extends HttpServlet {

    // ── DB config — change these to match your setup ──────────────────────
    private static final String DB_URL  =
        "jdbc:mysql://localhost:3306/multi_vendor" +
        "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";
    // ──────────────────────────────────────────────────────────────────────

    // ── Helper: open a new connection ─────────────────────────────────────
    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.jdbc.Driver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    // ── Helper: get logged-in customer email from session ─────────────────
    private String getCustomerEmail(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        Object email = session.getAttribute("email");
        return (email != null && !email.toString().trim().isEmpty())
               ? email.toString().trim() : null;
    }

    // ── Helper: safe HTML escape to prevent XSS in JSON output ────────────
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    // ── Helper: write JSON response ───────────────────────────────────────
    private void jsonResponse(HttpServletResponse resp,
                              boolean ok, String message,
                              String extraJson) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();
        String body = "{\"success\":" + ok +
                      ",\"message\":\"" + esc(message) + "\"" +
                      (extraJson != null ? "," + extraJson : "") +
                      "}";
        out.print(body);
        out.flush();
    }

    // ══════════════════════════════════════════════════════════════════════
    // GET — fetch rating(s)
    // ══════════════════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String customerEmail = getCustomerEmail(req);
        if (customerEmail == null) {
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED,
                           "Please log in to view ratings.");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "get";

        switch (action) {

            // ── GET single rating for one product in one order ───────────
            case "get": {
                String orderId   = req.getParameter("order_id");
                String productId = req.getParameter("product_id");

                if (orderId == null || productId == null) {
                    jsonResponse(resp, false,
                                 "Missing order_id or product_id.", null);
                    return;
                }

                Connection conn = null;
                try {
                    conn = getConnection();
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT id, rating, review_comment, rated_at " +
                        "FROM product_ratings " +
                        "WHERE order_id = ? AND product_id = ? " +
                        "  AND customer_email = ?");
                    ps.setString(1, orderId);
                    ps.setInt(2, Integer.parseInt(productId));
                    ps.setString(3, customerEmail);
                    ResultSet rs = ps.executeQuery();

                    if (rs.next()) {
                        String extra =
                            "\"id\":"              + rs.getInt("id")              + "," +
                            "\"rating\":"          + rs.getInt("rating")          + "," +
                            "\"review_comment\":\"" + esc(rs.getString("review_comment")) + "\"," +
                            "\"rated_at\":\""      + esc(rs.getString("rated_at"))       + "\"";
                        jsonResponse(resp, true, "Rating found.", extra);
                    } else {
                        jsonResponse(resp, false, "No rating found.", null);
                    }
                    rs.close(); ps.close();
                } catch (Exception ex) {
                    jsonResponse(resp, false, "DB error: " + ex.getMessage(), null);
                } finally {
                    try { if (conn != null) conn.close(); } catch (Exception ig) {}
                }
                break;
            }

            // ── GET all ratings the customer left for one order ──────────
            case "list": {
                String orderId = req.getParameter("order_id");

                if (orderId == null) {
                    jsonResponse(resp, false, "Missing order_id.", null);
                    return;
                }

                Connection conn = null;
                try {
                    conn = getConnection();
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT id, product_id, product_name, rating, " +
                        "       review_comment, rated_at " +
                        "FROM product_ratings " +
                        "WHERE order_id = ? AND customer_email = ? " +
                        "ORDER BY rated_at DESC");
                    ps.setString(1, orderId);
                    ps.setString(2, customerEmail);
                    ResultSet rs = ps.executeQuery();

                    StringBuilder items = new StringBuilder("[");
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) items.append(",");
                        items.append("{")
                             .append("\"id\":")             .append(rs.getInt("id"))             .append(",")
                             .append("\"product_id\":")     .append(rs.getInt("product_id"))     .append(",")
                             .append("\"product_name\":\"") .append(esc(rs.getString("product_name")))  .append("\",")
                             .append("\"rating\":")         .append(rs.getInt("rating"))         .append(",")
                             .append("\"review_comment\":\"").append(esc(rs.getString("review_comment"))).append("\",")
                             .append("\"rated_at\":\"")     .append(esc(rs.getString("rated_at")))      .append("\"")
                             .append("}");
                        first = false;
                    }
                    items.append("]");
                    rs.close(); ps.close();

                    jsonResponse(resp, true, "OK", "\"ratings\":" + items);
                } catch (Exception ex) {
                    jsonResponse(resp, false, "DB error: " + ex.getMessage(), null);
                } finally {
                    try { if (conn != null) conn.close(); } catch (Exception ig) {}
                }
                break;
            }

            default:
                jsonResponse(resp, false,
                             "Unknown action. Use: get, list", null);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // POST — submit or delete a rating
    // ══════════════════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String customerEmail = getCustomerEmail(req);
        if (customerEmail == null) {
            /* Not logged in — redirect back if it's a form POST */
            if (isAjax(req)) {
                jsonResponse(resp, false, "Session expired. Please log in.", null);
            } else {
                resp.sendRedirect("ulogout");
            }
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "submit";

        switch (action) {

            // ── INSERT or UPDATE a rating (upsert) ───────────────────────
            case "submit": {
                String orderId     = req.getParameter("r_order_id");
                String productId   = req.getParameter("r_product_id");
                String productName = req.getParameter("r_product_name");
                String sellerEmail = req.getParameter("r_seller_email");
                String starStr     = req.getParameter("r_star");
                String comment     = req.getParameter("r_comment");
                String redirectTo  = req.getParameter("redirect");

                /* ── Validate ── */
                String validationErr = validateSubmit(
                        orderId, productId, productName,
                        sellerEmail, starStr);
                if (validationErr != null) {
                    handleError(req, resp, validationErr,
                                redirectTo, customerEmail);
                    return;
                }

                int star = Integer.parseInt(starStr.trim());
                comment  = (comment != null) ? comment.trim() : "";

                Connection conn = null;
                try {
                    conn = getConnection();

                    /* Security: verify this order actually belongs
                       to the logged-in customer before writing */
                    if (!orderBelongsToCustomer(conn, orderId, customerEmail)) {
                        handleError(req, resp,
                                    "Order not found for your account.",
                                    redirectTo, customerEmail);
                        return;
                    }

                    /* Upsert — one rating per (order_id, product_id) */
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO product_ratings " +
                        "  (order_id, product_id, product_name, " +
                        "   customer_email, seller_email, rating, review_comment) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?) " +
                        "ON DUPLICATE KEY UPDATE " +
                        "  rating = VALUES(rating), " +
                        "  review_comment = VALUES(review_comment), " +
                        "  rated_at = NOW()");
                    ps.setString(1, orderId);
                    ps.setInt   (2, Integer.parseInt(productId));
                    ps.setString(3, productName);
                    ps.setString(4, customerEmail);
                    ps.setString(5, sellerEmail != null ? sellerEmail : "");
                    ps.setInt   (6, star);
                    ps.setString(7, comment);
                    int affected = ps.executeUpdate();
                    ps.close();

                    String msg = (affected == 1)
                                 ? "Your review has been submitted!"
                                 : "Your review has been updated!";

                    if (isAjax(req)) {
                        jsonResponse(resp, true, msg, null);
                    } else {
                        /* Standard form POST — redirect with flash message */
                        String dest = (redirectTo != null && !redirectTo.isEmpty())
                                      ? redirectTo : "myorders.jsp";
                        req.getSession().setAttribute("ratingMsg", msg);
                        req.getSession().setAttribute("ratingOk",  true);
                        resp.sendRedirect(dest);
                    }

                } catch (Exception ex) {
                    handleError(req, resp,
                                "Could not save your review: " + ex.getMessage(),
                                redirectTo, customerEmail);
                } finally {
                    try { if (conn != null) conn.close(); } catch (Exception ig) {}
                }
                break;
            }

            // ── DELETE a rating ──────────────────────────────────────────
            case "delete": {
                String orderId   = req.getParameter("r_order_id");
                String productId = req.getParameter("r_product_id");
                String redirectTo = req.getParameter("redirect");

                if (orderId == null || productId == null) {
                    handleError(req, resp,
                                "Missing order_id or product_id for delete.",
                                redirectTo, customerEmail);
                    return;
                }

                Connection conn = null;
                try {
                    conn = getConnection();
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM product_ratings " +
                        "WHERE order_id = ? AND product_id = ? " +
                        "  AND customer_email = ?");
                    ps.setString(1, orderId);
                    ps.setInt   (2, Integer.parseInt(productId));
                    ps.setString(3, customerEmail);
                    int deleted = ps.executeUpdate();
                    ps.close();

                    String msg = deleted > 0
                                 ? "Your review has been removed."
                                 : "No review found to delete.";

                    if (isAjax(req)) {
                        jsonResponse(resp, deleted > 0, msg, null);
                    } else {
                        String dest = (redirectTo != null && !redirectTo.isEmpty())
                                      ? redirectTo : "myorders.jsp";
                        req.getSession().setAttribute("ratingMsg", msg);
                        req.getSession().setAttribute("ratingOk",  deleted > 0);
                        resp.sendRedirect(dest);
                    }

                } catch (Exception ex) {
                    handleError(req, resp,
                                "Could not delete review: " + ex.getMessage(),
                                redirectTo, customerEmail);
                } finally {
                    try { if (conn != null) conn.close(); } catch (Exception ig) {}
                }
                break;
            }

            default:
                if (isAjax(req)) {
                    jsonResponse(resp, false,
                                 "Unknown action. Use: submit, delete", null);
                } else {
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST,
                                   "Unknown action.");
                }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Private helpers
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Validates the fields required for a rating submission.
     * Returns null if valid, or an error message if not.
     */
    private String validateSubmit(String orderId, String productId,
                                  String productName, String sellerEmail,
                                  String starStr) {
        if (orderId == null || orderId.trim().isEmpty())
            return "Missing order ID.";
        if (productId == null || productId.trim().isEmpty())
            return "Missing product ID.";
        if (productName == null || productName.trim().isEmpty())
            return "Missing product name.";
        if (starStr == null || starStr.trim().isEmpty())
            return "Please select a star rating (1–5).";
        try {
            int star = Integer.parseInt(starStr.trim());
            if (star < 1 || star > 5)
                return "Rating must be between 1 and 5 stars.";
        } catch (NumberFormatException e) {
            return "Invalid star value.";
        }
        return null; // all good
    }

    /**
     * Confirms the given order_id exists in the `orders` table for
     * the logged-in customer. Prevents cross-user rating injection.
     */
    private boolean orderBelongsToCustomer(Connection conn,
                                            String orderId,
                                            String customerEmail)
            throws Exception {
        PreparedStatement ps = conn.prepareStatement(
            "SELECT 1 FROM orders " +
            "WHERE order_id = ? AND customer_email = ? LIMIT 1");
        ps.setString(1, orderId);
        ps.setString(2, customerEmail);
        ResultSet rs = ps.executeQuery();
        boolean found = rs.next();
        rs.close(); ps.close();
        return found;
    }

    /**
     * Detects whether the request was made via AJAX (fetch / XMLHttpRequest).
     * Checks the X-Requested-With header set by jQuery/fetch wrappers,
     * or falls back to the Accept header.
     */
    private boolean isAjax(HttpServletRequest req) {
        String xrw = req.getHeader("X-Requested-With");
        if ("XMLHttpRequest".equalsIgnoreCase(xrw)) return true;
        String accept = req.getHeader("Accept");
        return (accept != null && accept.contains("application/json"));
    }

    /**
     * Handles errors for both AJAX and standard form POSTs.
     * For form POSTs: stores flash attributes in session and redirects.
     */
    private void handleError(HttpServletRequest req,
                              HttpServletResponse resp,
                              String message,
                              String redirectTo,
                              String customerEmail)
            throws IOException {
        if (isAjax(req)) {
            jsonResponse(resp, false, message, null);
        } else {
            String dest = (redirectTo != null && !redirectTo.isEmpty())
                          ? redirectTo : "myorders.jsp";
            req.getSession().setAttribute("ratingMsg", message);
            req.getSession().setAttribute("ratingOk",  false);
            try { resp.sendRedirect(dest); } catch (IOException ignored) {}
        }
    }
}
