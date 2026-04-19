/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import DataBase.dbconfig;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 *
 * @author moham
 */
@WebServlet(urlPatterns = {"/adminReg"})
public class adminReg extends HttpServlet {

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
        String email=request.getParameter("adminId");
        String password=request.getParameter("password");
        String code=request.getParameter("twofa");
       // out.print(name+" "+pass);
        
        try {
            Class.forName("com.mysql.jdbc.Driver");
              Connection con = new dbconfig().getConnection();
              Statement stat=con.createStatement();
              ResultSet res=stat.executeQuery("SELECT * FROM `admin` WHERE `email`='"+email+"'AND`password`='"+password+"'AND`code`='"+code+"'");
                 // stat.executeUpdate("INSERT INTO `login`(`name`, `pass`) VALUES ('"+name+"','"+pass+"')");
            //out.print("SELECT * FROM `loginpg` WHERE `email`='"+email+"'AND`password`='"+pass+"'");SELECT * FROM `login` WHERE `email`AND`password`
            /* TODO output your page here. You may use following sample code. */
           int flag=0;
              while(res.next())
              {
                  flag=1;
              }
              if(flag==1){
                 
           out.print("<META http-equiv='refresh' content='0;adhome.jsp'>");
              }
              else{
                 out.print("<script>alert('Enter valid password')</script>");
            out.print("<META http-equiv='refresh' content='0;index.html'>");
              }
        }
        catch(Exception e){
        out.print(e);
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
        return "Short description";
    }// </editor-fold>

}
