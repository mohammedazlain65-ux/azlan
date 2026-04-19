<%-- 
    Document   : updateCart
    Created on : 6 Feb, 2026, 7:15:00 PM
    Author     : moham
--%>

<%@page import="java.util.HashMap"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    String password = null;
    try {
        username = hs.getAttribute("email").toString();
        password = hs.getAttribute("password").toString();
        if(username == null || password == null || username == "" || password == "") {
            out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>");
        }
    } catch(Exception e) {
        out.print("<meta http-equiv=\"refresh\" content=\"0;url=ulogout\"/>"); 
    }
%>

<%
    // Get parameters
    String action = request.getParameter("action");
    String productIdStr = request.getParameter("productId");
    String quantityStr = request.getParameter("quantity");
    
    // Initialize response variables
    String message = "";
    String messageType = "success"; // success, error, info
    boolean redirectToCart = false;
    
    try {
        // Get or create cart from session
        HashMap<Integer, Integer> cart = (HashMap<Integer, Integer>) session.getAttribute("cart");
        
        if(cart == null) {
            cart = new HashMap<Integer, Integer>();
            session.setAttribute("cart", cart);
        }
        
        // Validate productId
        if(productIdStr == null || productIdStr.isEmpty()) {
            throw new Exception("Product ID is required");
        }
        
        int productId = Integer.parseInt(productIdStr);
        
        // Database connection parameters (same as buyerdashboard.jsp)
        String dbURL = "jdbc:mysql://localhost:3306/multi_vendor";
        String dbUser = "root";
        String dbPassword = "";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            // Load MySQL JDBC Driver
            Class.forName("com.mysql.jdbc.Driver");
            
            // Establish connection
            conn = DriverManager.getConnection(dbURL, dbUser, dbPassword);
            
            // Verify product exists
            String query = "SELECT * FROM adprod WHERE id = ?";
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, productId);
            rs = pstmt.executeQuery();
            
            if(!rs.next()) {
                throw new Exception("Product not found");
            }
            
            // Get product details
            String productName = rs.getString("pname");
            String availableQuantity = rs.getString("quantity");
            int availableQty = 0;
            
            try {
                availableQty = Integer.parseInt(availableQuantity);
            } catch(NumberFormatException e) {
                availableQty = 100; // Default availability
            }
            
            // Handle different actions
            if("add".equals(action)) {
                // Add to cart or increase quantity
                int currentQty = cart.getOrDefault(productId, 0);
                int newQty = currentQty + 1;
                
                // Check if quantity exceeds available stock
                if(newQty > availableQty) {
                    message = "Cannot add more items. Only " + availableQty + " units available in stock.";
                    messageType = "warning";
                } else {
                    cart.put(productId, newQty);
                    session.setAttribute("cart", cart);
                    message = "\"" + productName + "\" added to cart successfully!";
                    messageType = "success";
                }
                
            } else if("remove".equals(action)) {
                // Remove from cart completely
                if(cart.containsKey(productId)) {
                    cart.remove(productId);
                    session.setAttribute("cart", cart);
                    message = "\"" + productName + "\" removed from cart successfully!";
                    messageType = "success";
                    redirectToCart = true;
                } else {
                    message = "Product not found in cart.";
                    messageType = "error";
                }
                
            } else if("update".equals(action)) {
                // Update quantity
                if(quantityStr == null || quantityStr.isEmpty()) {
                    throw new Exception("Quantity is required for update action");
                }
                
                int quantity = Integer.parseInt(quantityStr);
                
                if(quantity <= 0) {
                    // Remove if quantity is 0 or negative
                    cart.remove(productId);
                    session.setAttribute("cart", cart);
                    message = "\"" + productName + "\" removed from cart.";
                    messageType = "info";
                    redirectToCart = true;
                } else if(quantity > availableQty) {
                    message = "Cannot update quantity. Only " + availableQty + " units available in stock.";
                    messageType = "warning";
                    redirectToCart = true;
                } else {
                    cart.put(productId, quantity);
                    session.setAttribute("cart", cart);
                    message = "Cart updated successfully!";
                    messageType = "success";
                    redirectToCart = true;
                }
                
            } else if("increase".equals(action)) {
                // Increase quantity by 1
                int currentQty = cart.getOrDefault(productId, 0);
                int newQty = currentQty + 1;
                
                if(newQty > availableQty) {
                    message = "Cannot add more items. Only " + availableQty + " units available in stock.";
                    messageType = "warning";
                    redirectToCart = true;
                } else {
                    cart.put(productId, newQty);
                    session.setAttribute("cart", cart);
                    message = "Quantity increased successfully!";
                    messageType = "success";
                    redirectToCart = true;
                }
                
            } else if("decrease".equals(action)) {
                // Decrease quantity by 1
                int currentQty = cart.getOrDefault(productId, 0);
                int newQty = currentQty - 1;
                
                if(newQty <= 0) {
                    cart.remove(productId);
                    session.setAttribute("cart", cart);
                    message = "\"" + productName + "\" removed from cart.";
                    messageType = "info";
                    redirectToCart = true;
                } else {
                    cart.put(productId, newQty);
                    session.setAttribute("cart", cart);
                    message = "Quantity decreased successfully!";
                    messageType = "success";
                    redirectToCart = true;
                }
                
            } else if("clear".equals(action)) {
                // Clear entire cart
                cart.clear();
                session.setAttribute("cart", cart);
                message = "Cart cleared successfully!";
                messageType = "success";
                redirectToCart = true;
                
            } else {
                throw new Exception("Invalid action specified");
            }
            
        } catch(ClassNotFoundException e) {
            message = "Database driver not found: " + e.getMessage();
            messageType = "error";
        } catch(SQLException e) {
            message = "Database error: " + e.getMessage();
            messageType = "error";
        } finally {
            // Close database resources
            try {
                if(rs != null) rs.close();
                if(pstmt != null) pstmt.close();
                if(conn != null) conn.close();
            } catch(SQLException e) {
                e.printStackTrace();
            }
        }
        
    } catch(NumberFormatException e) {
        message = "Invalid product ID or quantity format";
        messageType = "error";
    } catch(Exception e) {
        message = "Error: " + e.getMessage();
        messageType = "error";
    }
    
    // Store message in session
    session.setAttribute("cartMessage", message);
    session.setAttribute("cartMessageType", messageType);
    
    // Redirect
    String redirectUrl = redirectToCart ? "cart.jsp" : "buyerdashboard.jsp";
    response.sendRedirect(redirectUrl);
%>
