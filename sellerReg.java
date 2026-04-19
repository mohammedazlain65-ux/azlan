/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import DataBase.dbconfig;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 *
 * @author moham
 */
@WebServlet(urlPatterns = {"/sellerReg"})
public class sellerReg extends HttpServlet {

    /**
     * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
     * methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        // Get all form parameters
        String fname = request.getParameter("firstName");
        String lname = request.getParameter("lastName");
        String email = request.getParameter("email");
        String phno = request.getParameter("phno");
        String bname = request.getParameter("businessName");
        String btype = request.getParameter("businessType");
        String category = request.getParameter("category");
        String gst = request.getParameter("gst");
        String pan = request.getParameter("pan");
        String desc = request.getParameter("desc");
        String add1 = request.getParameter("address1");
        String add2 = request.getParameter("address2");
        String city = request.getParameter("city");
        String state = request.getParameter("state");
        String pin = request.getParameter("pincode");
        String accountno = request.getParameter("accountNumber");
        String ifsc = request.getParameter("ifsc");
        String bankname = request.getParameter("bankName");
        String pass = request.getParameter("password");
        String cpass = request.getParameter("confirmpassword");
        
        // Validate password match
         if(pass.equals(cpass)){
        try {
            Class.forName("com.mysql.jdbc.Driver");
                  Connection con = new dbconfig().getConnection();
                  Statement stat=con.createStatement();
                  stat.executeUpdate("INSERT INTO `sellerreg`(`Fname`, `Lname`, `email`, `phono`, `Bname`, `Btype`, `category`, `gst`, `pan`, `disc`, `address1`, `address2`, `city`, `state`, `pin`, `accountno`, `ifsc`, `bankname`, `pass`, `cpass`) VALUES ('"+fname+"','"+lname+"','"+email+"','"+phno+"','"+bname+"','"+btype+"','"+category+"','"+gst+"','"+pan+"','"+desc+"','"+add1+"','"+add2+"','"+city+"','"+state+"','"+pin+"','"+accountno+"','"+ifsc+"','"+bankname+"','"+pass+"','"+cpass+"')");
                  //"+fname+"','"+lname+"','"+email+"','"+phno+"','"+pass+"','"+cpass+"','"+add1+"','"+add2+"','"+city+"','"+pin+"
            /* TODO output your page here. You may use following sample code. */
           out.printf("<script>alert('Sign-up succesfull')</script>");
           out.print("<META http-equiv='refresh' content='0;sellerdashboard.jsp'>");
        }
        catch(Exception e){
        out.print(e);
        }
         }
        else{
            out.print("<script>alert('Confirm password does not match'</script>");
            out.print("<META http-equiv='refresh' content='0;sellerReg'>");
                
            }
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Seller Registration Servlet";
    }// </editor-fold>

}