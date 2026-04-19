

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import java.io.IOException;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * AuthFilter  -  protects all /pages/*, /orders, /dashboard, /profile, /admin/* URLs.
 * If no valid session exists, redirects to /login.jsp.
 * If a non-admin tries to access /admin/*, redirects to /dashboard.
 */
@WebFilter(urlPatterns = {"/pages/*", "/orders", "/dashboard", "/profile", "/admin/*"})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        HttpSession session = req.getSession(false);
        boolean loggedIn    = (session != null && session.getAttribute("agentId") != null);

        if (!loggedIn) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        // Admin-only guard
        String uri  = req.getRequestURI();
        String role = (String) session.getAttribute("agentRole");
        if (uri.contains("/admin/") && !"ADMIN".equals(role)) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        chain.doFilter(request, response);
    }

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void destroy() {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
}
