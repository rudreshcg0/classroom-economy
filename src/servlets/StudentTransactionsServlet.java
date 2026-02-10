package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/studentTransactions")
public class StudentTransactionsServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        if (teacher == null) { response.sendRedirect("login.html"); return; }

        String classId = request.getParameter("classId");
        String studentId = request.getParameter("studentId");

        try (Connection conn = DBConnection.getConnection()) {
            // ALWAYS fetch classes for the dropdown
            List<Map<String, Object>> classes = new ArrayList<>();
            String sqlC = "SELECT class_id, class_name FROM classes WHERE teacher_id = ?";
            PreparedStatement pstC = conn.prepareStatement(sqlC);
            pstC.setInt(1, teacher.getId());
            ResultSet rsC = pstC.executeQuery();
            while(rsC.next()){
                Map<String, Object> map = new HashMap<>();
                map.put("id", rsC.getInt("class_id"));
                map.put("name", rsC.getString("class_name"));
                classes.add(map);
            }
            request.setAttribute("classes", classes);

            // STATE 1: Class Selected -> Fetch Students
            if (classId != null && studentId == null) {
                List<User> students = new ArrayList<>();
                String sqlS = "SELECT u.user_id, u.username, u.roll_no, w.balance FROM users u " +
                              "JOIN student_classes sc ON u.user_id = sc.student_id " +
                              "JOIN wallets w ON u.user_id = w.student_id " +
                              "WHERE sc.class_id = ?";
                PreparedStatement pstS = conn.prepareStatement(sqlS);
                pstS.setInt(1, Integer.parseInt(classId));
                ResultSet rsS = pstS.executeQuery();
                while(rsS.next()){
                    students.add(new User(rsS.getInt("user_id"), rsS.getString("username"), "student", 
                                teacher.getSchoolId(), rsS.getDouble("balance"), rsS.getString("roll_no")));
                }
                request.setAttribute("students", students);
                request.setAttribute("selectedClassId", classId);
            }

            // STATE 2: Student Selected -> Fetch Transactions
            if (studentId != null) {
                List<Map<String, Object>> txs = new ArrayList<>();
                String sqlT = "SELECT t.*, u1.username as sender_name, u2.username as receiver_name " +
                              "FROM transactions t " +
                              "LEFT JOIN users u1 ON t.sender_id = u1.user_id " +
                              "LEFT JOIN users u2 ON t.receiver_id = u2.user_id " +
                              "WHERE t.sender_id = ? OR t.receiver_id = ? " +
                              "ORDER BY t.created_at DESC";
                PreparedStatement pstT = conn.prepareStatement(sqlT);
                int sId = Integer.parseInt(studentId);
                pstT.setInt(1, sId);
                pstT.setInt(2, sId);
                ResultSet rsT = pstT.executeQuery();
                while(rsT.next()){
                    Map<String, Object> t = new HashMap<>();
                    t.put("amount", rsT.getDouble("amount"));
                    t.put("type", rsT.getString("type"));
                    t.put("desc", rsT.getString("description"));
                    t.put("date", rsT.getTimestamp("created_at"));
                    t.put("sender", rsT.getString("sender_name") == null ? "SYSTEM" : rsT.getString("sender_name"));
                    t.put("receiver", rsT.getString("receiver_name"));
                    txs.add(t);
                }
                request.setAttribute("transactions", txs);
                
                // Fetch student name for the header
                PreparedStatement pstN = conn.prepareStatement("SELECT username FROM users WHERE user_id = ?");
                pstN.setInt(1, sId);
                ResultSet rsN = pstN.executeQuery();
                if(rsN.next()) request.setAttribute("targetStudentName", rsN.getString("username"));
            }

            request.getRequestDispatcher("student_transactions.jsp").forward(request, response);
        } catch (SQLException e) { e.printStackTrace(); }
    }
}