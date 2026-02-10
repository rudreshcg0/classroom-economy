package servlets;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/getMarketStock")
public class MarketplaceStockServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;

        if (user == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement pst = conn.prepareStatement(
                 "SELECT item_id, stock FROM marketplace_items WHERE school_id = ?")) {
            
            pst.setInt(1, user.getSchoolId());
            
            try (ResultSet rs = pst.executeQuery();
                 PrintWriter out = response.getWriter()) {
                
                StringBuilder sb = new StringBuilder();
                while (rs.next()) {
                    sb.append(rs.getInt("item_id"))
                      .append(":")
                      .append(rs.getInt("stock"))
                      .append(",");
                }
                out.print(sb.toString());
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}