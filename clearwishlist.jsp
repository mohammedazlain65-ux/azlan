<%@page import="java.sql.*"%>
<%
    HttpSession hs = request.getSession();
    String username = null;
    
    try {
        username = hs.getAttribute("email").toString();
        if(username == null || username.isEmpty()) {
            response.sendRedirect("ulogout");
            return;
        }
    } catch(Exception e) {
        response.sendRedirect("ulogout");
        return;
    }
    
    String dbURL  = "jdbc:mysql://localhost:3306/multi_vendor";
    String dbUser = "root";
    String dbPass = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    
    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbURL, dbUser, dbPass);
        
        String deleteSql = "DELETE FROM wishlist WHERE user_email = ?";
        pstmt = conn.prepareStatement(deleteSql);
        pstmt.setString(1, username);
        int result = pstmt.executeUpdate();
        
        if(result > 0) {
            session.setAttribute("wishlistMessage", "All items removed from wishlist successfully!");
            session.setAttribute("wishlistMessageType", "success");
        } else {
            session.setAttribute("wishlistMessage", "Your wishlist is already empty.");
            session.setAttribute("wishlistMessageType", "warning");
        }
        
    } catch(Exception e) {
        e.printStackTrace();
        session.setAttribute("wishlistMessage", "Error clearing wishlist: " + e.getMessage());
        session.setAttribute("wishlistMessageType", "error");
    } finally {
        try {
            if(pstmt != null) pstmt.close();
            if(conn != null) conn.close();
        } catch(SQLException e) {
            e.printStackTrace();
        }
    }
    
    response.sendRedirect("wishlist.jsp");
%>
