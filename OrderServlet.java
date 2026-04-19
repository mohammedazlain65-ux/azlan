

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.*;

/**
 * OrderServlet  -  Unified endpoint for all order operations.
 *
 * GET  /orders               -> list agent's orders (action=list, default)
 * GET  /orders?action=pickup -> unassigned pending orders
 * GET  /orders?action=view&id=N  -> order detail
 * GET  /orders?action=track&t=TRACKING -> tracking page
 * GET  /orders?action=history -> completed deliveries
 * GET  /dashboard            -> dashboard stats
 * POST /orders action=create|accept|reject|updateStatus
 *
 * Plug-in points marked with  // TODO: DB
 * All JSP pages read data from request attributes (List<String[]> rows).
 */
@WebServlet({"/orders", "/dashboard"})
public class OrderServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (req.getServletPath().equals("/dashboard")) {
            handleDashboard(req, resp);
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "pickup"  : handlePickupList(req, resp);
            case "view"    : handleView(req, resp);
            case "track"   : handleTrack(req, resp);
            case "history" : handleHistory(req, resp);
            default        : handleList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create"      : handleCreate(req, resp);
            case "accept"       : handleAccept(req, resp);
            case "reject"       : handleReject(req, resp);
            case "updateStatus" : handleUpdateStatus(req, resp);
            default : resp.sendRedirect(req.getContextPath() + "/dashboard");
        }
    }

    // ── GET Handlers ────────────────────────────────────────────────────────

    private void handleDashboard(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int agentId = getSessionAgentId(req);

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // int total     = dao.countByAgent(agentId);
        // int pending   = dao.countByAgentAndStatus(agentId,"Pending") + ...;
        // int inTransit = ...;
        // int delivered = dao.countByAgentAndStatus(agentId,"Delivered");
        // List<Order> recent = dao.findByAgent(agentId, null);  // last 5
        //
        // Build List<String[]> recentOrders where each row:
        //   [tracking, custName, custContact, pickupDate, expectedDelivery,
        //    paymentType, status, badgeClass, orderId]
        int totalOrders    = 0;
        int pendingCount   = 0;
        int inTransitCount = 0;
        int deliveredCount = 0;
        List<String[]> recentOrders = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("totalOrders",    totalOrders);
        req.setAttribute("pendingCount",   pendingCount);
        req.setAttribute("inTransitCount", inTransitCount);
        req.setAttribute("deliveredCount", deliveredCount);
        req.setAttribute("recentOrders",   recentOrders);
        req.getRequestDispatcher("/pages/dashboard.jsp").forward(req, resp);
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int    agentId = getSessionAgentId(req);
        String status  = req.getParameter("status");
        String keyword = req.getParameter("keyword");
        String role    = getSessionRole(req);

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // List<Order> raw = "ADMIN".equals(role)
        //     ? dao.search(keyword, status)
        //     : dao.findByAgent(agentId, status);
        //
        // Build List<String[]> orders where each row:
        //   [tracking,custName,custContact,productDesc,weightKg,pickupDate,
        //    expectedDelivery,daysRemaining,paymentType,deliveryCharges,
        //    status,badgeClass,orderId]
        List<String[]> orders = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("orders",  orders);
        req.setAttribute("filter",  status);
        req.setAttribute("keyword", keyword);
        req.getRequestDispatcher("/pages/orders.jsp").forward(req, resp);
    }

    private void handlePickupList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // List<Order> raw = dao.findUnassignedPending();
        //
        // Build List<String[]> pickupOrders where each row:
        //   [tracking,paymentType,sellerName,sellerAddr,sellerContact,
        //    custName,custAddr,custContact,productDesc,weightKg,
        //    pickupDate,expectedDelivery,deliveryCharges,specialInstructions,orderId]
        List<String[]> pickupOrders = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("pickupOrders", pickupOrders);
        req.getRequestDispatcher("/pages/pickup-orders.jsp").forward(req, resp);
    }

    private void handleView(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int orderId  = parseInt(req.getParameter("id"), 0);
        int agentId  = getSessionAgentId(req);

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // Order order  = dao.findById(orderId);
        // if (order == null) { resp.sendRedirect(...); return; }
        //
        // Build String[] orderData (22 elements):
        //   [0]=tracking,[1]=createdAt,[2]=agentName,[3]=status,[4]=badgeClass,
        //   [5]=paymentType,[6]=sellerName,[7]=sellerAddr,[8]=sellerContact,
        //   [9]=custName,[10]=custAddr,[11]=custContact,[12]=productDesc,
        //   [13]=weightKg,[14]=pickupDate,[15]=expectedDelivery,
        //   [16]=specialNotes,[17]=deliveryCharges,[18]=isPaid(0/1),
        //   [19]=orderId,[20]=assignedAgentId,[21]=currentStepIndex
        //
        // Build List<String[]> statusHistory each: [status,changedAt,agentName,remarks,dotClass]
        //
        // canUpdate = (order.getAgentId() == agentId) && !isFinalStatus
        // nextStatuses = derive from current status
        String[] orderData = null;
        List<String[]> statusHistory = new ArrayList<>();
        boolean canUpdate = false;
        String[] nextStatuses = new String[]{};
        // ── END TODO ──────────────────────────────────────────────────────

        if (orderData == null) {
            resp.sendRedirect(req.getContextPath() + "/orders");
            return;
        }

        req.setAttribute("orderData",      orderData);
        req.setAttribute("statusHistory",  statusHistory);
        req.setAttribute("canUpdate",      canUpdate);
        req.setAttribute("nextStatuses",   nextStatuses);
        req.getRequestDispatcher("/pages/order-detail.jsp").forward(req, resp);
    }

    private void handleTrack(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String tracking = req.getParameter("t");

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // Order order  = (tracking != null) ? dao.findByTracking(tracking.trim().toUpperCase()) : null;
        //
        // Build String[] trackData (8 elements):
        //   [0]=tracking,[1]=custName,[2]=agentName,[3]=expectedDelivery,
        //   [4]=charges,[5]=status,[6]=badgeClass,[7]=currentStepIndex
        //
        // Build List<String[]> statusHistory: [status, changedAt, remarks]
        boolean orderFound = false;
        String[] trackData = null;
        List<String[]> statusHistory = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("tracking",      tracking);
        req.setAttribute("orderFound",    orderFound);
        req.setAttribute("trackData",     trackData);
        req.setAttribute("statusHistory", statusHistory);
        req.getRequestDispatcher("/pages/track-order.jsp").forward(req, resp);
    }

    private void handleHistory(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int agentId = getSessionAgentId(req);

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // List<Order> raw = dao.findByAgent(agentId, "Delivered");
        //
        // Build List<String[]> orders each:
        //   [tracking,custName,custContact,productDesc,expectedDelivery,
        //    paymentType,deliveryCharges,orderId]
        List<String[]> orders = new ArrayList<>();
        // ── END TODO ──────────────────────────────────────────────────────

        req.setAttribute("orders", orders);
        req.getRequestDispatcher("/pages/order-history.jsp").forward(req, resp);
    }

    // ── POST Handlers ───────────────────────────────────────────────────────

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String sellerName         = req.getParameter("sellerName");
        String sellerAddress      = req.getParameter("sellerAddress");
        String sellerContact      = req.getParameter("sellerContact");
        String customerName       = req.getParameter("customerName");
        String customerAddress    = req.getParameter("customerAddress");
        String customerContact    = req.getParameter("customerContact");
        String productDescription = req.getParameter("productDescription");
        String paymentType        = req.getParameter("paymentType");
        String specialInstructions= req.getParameter("specialInstructions");
        String weight             = req.getParameter("weight");
        String deliveryCharges    = req.getParameter("deliveryCharges");
        String pickupDate         = req.getParameter("pickupDate");
        String expectedDelivery   = req.getParameter("expectedDelivery");

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // Order order  = new Order();
        // order.setSellerName(sellerName); ... set all fields ...
        // order.setWeightKg(new BigDecimal(weight));
        // order.setPickupDate(LocalDate.parse(pickupDate));
        // boolean created = dao.createOrder(order);
        boolean created = false;  // replace with real DB insert
        // ── END TODO ──────────────────────────────────────────────────────

        if (created) {
            req.getSession().setAttribute("flashSuccess", "Order created successfully!");
            resp.sendRedirect(req.getContextPath() + "/orders?action=pickup");
        } else {
            req.setAttribute("error", "Failed to create order. Please try again.");
            req.getRequestDispatcher("/pages/pickup-form.jsp").forward(req, resp);
        }
    }

    private void handleAccept(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int agentId = getSessionAgentId(req);
        int orderId = parseInt(req.getParameter("orderId"), 0);

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // dao.acceptOrder(orderId, agentId);
        // ── END TODO ──────────────────────────────────────────────────────

        resp.sendRedirect(req.getContextPath() + "/orders?action=pickup");
    }

    private void handleReject(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int    agentId = getSessionAgentId(req);
        int    orderId = parseInt(req.getParameter("orderId"), 0);
        String reason  = req.getParameter("reason");

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // dao.rejectOrder(orderId, agentId, reason);
        // ── END TODO ──────────────────────────────────────────────────────

        resp.sendRedirect(req.getContextPath() + "/orders");
    }

    private void handleUpdateStatus(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        int    agentId   = getSessionAgentId(req);
        int    orderId   = parseInt(req.getParameter("orderId"), 0);
        String newStatus = req.getParameter("newStatus");
        String remarks   = req.getParameter("remarks");

        // ── TODO: DB ─────────────────────────────────────────────────────
        // OrderDAO dao = new OrderDAO();
        // dao.updateStatus(orderId, agentId, newStatus, remarks);
        // ── END TODO ──────────────────────────────────────────────────────

        resp.sendRedirect(req.getContextPath() + "/orders?action=view&id=" + orderId);
    }

    // ── Utilities ────────────────────────────────────────────────────────────

    private int getSessionAgentId(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) return 0;
        Object id = s.getAttribute("agentId");
        return (id instanceof Integer) ? (Integer) id : 0;
    }

    private String getSessionRole(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) return "AGENT";
        Object r = s.getAttribute("agentRole");
        return r != null ? r.toString() : "AGENT";
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}
