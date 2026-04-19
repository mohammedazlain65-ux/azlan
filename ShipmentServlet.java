

import DataBase.dbconfig;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

/**
 * ShipmentServlet.java
 *
 * URL mapping : /ShipmentServlet
 *
 * Supported actions (sent as request parameter  ?action=...):
 *  - getAllShipments        : returns all shipments as JSON
 *  - getShipmentById        : returns one shipment by order_id
 *  - addShipment            : INSERT a new shipment
 *  - updateShipmentStatus   : UPDATE only the status column
 *  - deleteShipment         : DELETE a shipment record
 */
@WebServlet("/ShipmentServlet")
public class ShipmentServlet extends HttpServlet {

    /** GET  — read-only queries */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        // Allow AJAX calls from the JSP
        response.setHeader("Access-Control-Allow-Origin", "*");

        String action = request.getParameter("action");
        PrintWriter out = response.getWriter();

       try (Connection conn = new dbconfig().getConnection()) {

            if ("getAllShipments".equals(action)) {
                getAllShipments(conn, out);

            } else if ("getShipmentById".equals(action)) {
                String orderId = request.getParameter("order_id");
                getShipmentById(conn, out, orderId);

            } else if ("filterByStatus".equals(action)) {
                String status = request.getParameter("status");
                filterByStatus(conn, out, status);

            } else {
                out.print("{\"error\":\"Unknown GET action\"}");
            }

        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    /** POST — write operations */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Access-Control-Allow-Origin", "*");

        String action = request.getParameter("action");
        PrintWriter out = response.getWriter();

        try (Connection conn = new dbconfig().getConnection()) {

            if ("addShipment".equals(action)) {
                addShipment(conn, request, out);

            } else if ("updateShipmentStatus".equals(action)) {
                updateShipmentStatus(conn, request, out);

            } else if ("deleteShipment".equals(action)) {
                deleteShipment(conn, request, out);

            } else {
                out.print("{\"error\":\"Unknown POST action\"}");
            }

        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"" + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    // ------------------------------------------------------------------
    // PRIVATE HELPERS
    // ------------------------------------------------------------------

    /** Return all shipments joined with agent name. */
    private void getAllShipments(Connection conn, PrintWriter out) throws SQLException {
        String sql = "SELECT s.*, a.agent_name " +
                     "FROM shipments s " +
                     "LEFT JOIN delivery_agents a ON s.agent_id = a.agent_id " +
                     "ORDER BY s.dispatch_date DESC, s.dispatch_time DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                first = false;
                json.append(shipmentToJson(rs));
            }
            json.append("]");
            out.print(json);
        }
    }

    /** Return a single shipment by order_id. */
    private void getShipmentById(Connection conn, PrintWriter out, String orderId)
            throws SQLException {
        if (orderId == null || orderId.isEmpty()) {
            out.print("{\"error\":\"order_id is required\"}");
            return;
        }
        String sql = "SELECT s.*, a.agent_name " +
                     "FROM shipments s " +
                     "LEFT JOIN delivery_agents a ON s.agent_id = a.agent_id " +
                     "WHERE s.order_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    out.print(shipmentToJson(rs));
                } else {
                    out.print("{\"error\":\"Shipment not found\"}");
                }
            }
        }
    }

    /** Return shipments filtered by status. */
    private void filterByStatus(Connection conn, PrintWriter out, String status)
            throws SQLException {
        String sql = "SELECT s.*, a.agent_name " +
                     "FROM shipments s " +
                     "LEFT JOIN delivery_agents a ON s.agent_id = a.agent_id " +
                     "WHERE s.shipment_status = ? " +
                     "ORDER BY s.dispatch_date DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                StringBuilder json = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    first = false;
                    json.append(shipmentToJson(rs));
                }
                json.append("]");
                out.print(json);
            }
        }
    }

    /**
     * INSERT a new shipment.
     * Required POST params: order_id, tracking_number, product_name, customer_name,
     *   customer_phone, delivery_address, dispatch_date (yyyy-MM-dd), dispatch_time (HH:mm),
     *   expected_delivery (yyyy-MM-dd), agent_id, transport_mode
     */
    private void addShipment(Connection conn, HttpServletRequest req, PrintWriter out)
            throws SQLException {

        String orderId       = req.getParameter("order_id");
        String trackingNum   = req.getParameter("tracking_number");
        String productName   = req.getParameter("product_name");
        String customerName  = req.getParameter("customer_name");
        String customerPhone = req.getParameter("customer_phone");
        String address       = req.getParameter("delivery_address");
        String dispatchDate  = req.getParameter("dispatch_date");
        String dispatchTime  = req.getParameter("dispatch_time");
        String expectedDel   = req.getParameter("expected_delivery");
        String agentId       = req.getParameter("agent_id");
        String transport     = req.getParameter("transport_mode");
        String notes         = req.getParameter("notes");

        // Basic validation
        if (orderId == null || productName == null || customerName == null ||
            dispatchDate == null || dispatchTime == null || expectedDel == null || address == null) {
            out.print("{\"success\":false,\"message\":\"Missing required fields\"}");
            return;
        }

        // Auto-generate tracking number if blank
        if (trackingNum == null || trackingNum.isEmpty()) {
            trackingNum = "MH-TRK-" + dispatchDate.replace("-","") + "-" + System.currentTimeMillis() % 10000;
        }

        String sql = "INSERT INTO shipments " +
                     "(order_id, tracking_number, product_name, customer_name, customer_phone, " +
                     " delivery_address, dispatch_date, dispatch_time, expected_delivery, " +
                     " agent_id, transport_mode, shipment_status, notes) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?,?,'dispatched',?)";

        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1,  orderId);
            ps.setString(2,  trackingNum);
            ps.setString(3,  productName);
            ps.setString(4,  customerName);
            ps.setString(5,  customerPhone != null ? customerPhone : "");
            ps.setString(6,  address);
            ps.setDate(7,    Date.valueOf(dispatchDate));
            ps.setTime(8,    Time.valueOf(dispatchTime.length() == 5 ? dispatchTime + ":00" : dispatchTime));
            ps.setDate(9,    Date.valueOf(expectedDel));
            ps.setString(10, (agentId != null && !agentId.isEmpty()) ? agentId : null);
            ps.setString(11, transport != null ? transport : "Road -- Delivery Van");
            ps.setString(12, notes != null ? notes : "");

            int rows = ps.executeUpdate();
            if (rows > 0) {
                // Also insert the first tracking event
                insertTrackingEvent(conn, orderId, trackingNum, "Dispatched",
                        "Assigned to agent", new Timestamp(System.currentTimeMillis()),
                        "Shipment dispatched");

                out.print("{\"success\":true,\"message\":\"Shipment added successfully\"," +
                          "\"tracking_number\":\"" + trackingNum + "\"}");
            } else {
                out.print("{\"success\":false,\"message\":\"Insert failed\"}");
            }
        }
    }

    /**
     * UPDATE shipment status.
     * Required POST params: order_id, status
     * Optional: actual_delivery (yyyy-MM-dd) when marking as delivered
     */
    private void updateShipmentStatus(Connection conn, HttpServletRequest req, PrintWriter out)
            throws SQLException {

        String orderId       = req.getParameter("order_id");
        String newStatus     = req.getParameter("status");
        String actualDelivery = req.getParameter("actual_delivery");

        if (orderId == null || newStatus == null) {
            out.print("{\"success\":false,\"message\":\"order_id and status are required\"}");
            return;
        }

        String sql;
        if ("delivered".equals(newStatus) && actualDelivery != null && !actualDelivery.isEmpty()) {
            sql = "UPDATE shipments SET shipment_status = ?, actual_delivery = ? WHERE order_id = ?";
        } else {
            sql = "UPDATE shipments SET shipment_status = ? WHERE order_id = ?";
        }

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            if ("delivered".equals(newStatus) && actualDelivery != null && !actualDelivery.isEmpty()) {
                ps.setDate(2, Date.valueOf(actualDelivery));
                ps.setString(3, orderId);
            } else {
                ps.setString(2, orderId);
            }

            int rows = ps.executeUpdate();

            // Update agent's completed count if delivered
            if (rows > 0 && "delivered".equals(newStatus)) {
                updateAgentCompletedCount(conn, orderId);
            }

            out.print(rows > 0
                    ? "{\"success\":true,\"message\":\"Status updated to " + newStatus + "\"}"
                    : "{\"success\":false,\"message\":\"No record found for order_id: " + orderId + "\"}");
        }
    }

    /** DELETE a shipment record. */
    private void deleteShipment(Connection conn, HttpServletRequest req, PrintWriter out)
            throws SQLException {

        String orderId = req.getParameter("order_id");
        if (orderId == null || orderId.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"order_id is required\"}");
            return;
        }

        String sql = "DELETE FROM shipments WHERE order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            int rows = ps.executeUpdate();
            out.print(rows > 0
                    ? "{\"success\":true,\"message\":\"Shipment deleted\"}"
                    : "{\"success\":false,\"message\":\"No record found\"}");
        }
    }

    // ------------------------------------------------------------------
    // UTILITY
    // ------------------------------------------------------------------

    /** Build a JSON object string from the current ResultSet row. */
    private String shipmentToJson(ResultSet rs) throws SQLException {
        return "{" +
            "\"shipment_id\":"     + rs.getInt("shipment_id")                    + "," +
            "\"order_id\":\""      + esc(rs.getString("order_id"))               + "\"," +
            "\"tracking_number\":\"" + esc(rs.getString("tracking_number"))      + "\"," +
            "\"product_name\":\""  + esc(rs.getString("product_name"))           + "\"," +
            "\"customer_name\":\"" + esc(rs.getString("customer_name"))          + "\"," +
            "\"customer_phone\":\"" + esc(rs.getString("customer_phone"))        + "\"," +
            "\"delivery_address\":\"" + esc(rs.getString("delivery_address"))    + "\"," +
            "\"dispatch_date\":\""  + rs.getDate("dispatch_date")                + "\"," +
            "\"dispatch_time\":\""  + rs.getTime("dispatch_time")                + "\"," +
            "\"expected_delivery\":\"" + rs.getDate("expected_delivery")         + "\"," +
            "\"actual_delivery\":\"" + nullSafe(rs.getDate("actual_delivery"))   + "\"," +
            "\"agent_id\":\""       + esc(rs.getString("agent_id"))              + "\"," +
            "\"agent_name\":\""     + esc(rs.getString("agent_name"))            + "\"," +
            "\"transport_mode\":\"" + esc(rs.getString("transport_mode"))        + "\"," +
            "\"shipment_status\":\"" + esc(rs.getString("shipment_status"))      + "\"," +
            "\"notes\":\""          + esc(rs.getString("notes"))                 + "\"" +
            "}";
    }

    /** Insert a single tracking event for a shipment. */
    private void insertTrackingEvent(Connection conn, String orderId, String trackingNum,
            String status, String location, Timestamp eventTime, String description)
            throws SQLException {

        // Get shipment_id first
        int shipmentId = -1;
        String getSql = "SELECT shipment_id FROM shipments WHERE order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(getSql)) {
            ps.setString(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) shipmentId = rs.getInt("shipment_id");
            }
        }
        if (shipmentId == -1) return;

        String insertSql = "INSERT INTO order_tracking " +
                           "(shipment_id, tracking_number, event_status, event_location, event_datetime, event_description) " +
                           "VALUES (?,?,?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setInt(1, shipmentId);
            ps.setString(2, trackingNum);
            ps.setString(3, status);
            ps.setString(4, location);
            ps.setTimestamp(5, eventTime);
            ps.setString(6, description);
            ps.executeUpdate();
        }
    }

    /** Increment agent's completed_deliveries when a shipment is marked delivered. */
    private void updateAgentCompletedCount(Connection conn, String orderId) throws SQLException {
        String sql = "UPDATE delivery_agents a " +
                     "JOIN shipments s ON a.agent_id = s.agent_id " +
                     "SET a.completed_deliveries = a.completed_deliveries + 1 " +
                     "WHERE s.order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            ps.executeUpdate();
        }
    }

    private String esc(String s)          { return s == null ? "" : s.replace("\"", "\\\""); }
    private String nullSafe(Object o)     { return o == null ? "" : o.toString(); }
}