package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/manageStudents")
public class ManageStudentsServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        
        List<User> students = new ArrayList<>();
        List<Map<String, Object>> classes = new ArrayList<>();
        List<Map<String, Object>> enrollments = new ArrayList<>();

        try (Connection conn = DBConnection.getConnection()) {
            // 1. Get Teacher's Classes
            String sqlC = "SELECT class_id, class_name FROM classes WHERE teacher_id = ?";
            PreparedStatement pst1 = conn.prepareStatement(sqlC);
            pst1.setInt(1, teacher.getId());
            ResultSet rs1 = pst1.executeQuery();
            while(rs1.next()){
                Map<String, Object> map = new HashMap<>();
                map.put("id", rs1.getInt("class_id"));
                map.put("name", rs1.getString("class_name"));
                classes.add(map);
            }

            // 2. Get All Students in School
            String sqlS = "SELECT u.user_id, u.username, u.roll_no FROM users u WHERE u.school_id = ? AND u.role = 'student' ORDER BY u.roll_no ASC";
            PreparedStatement pst2 = conn.prepareStatement(sqlS);
            pst2.setInt(1, teacher.getSchoolId());
            ResultSet rs2 = pst2.executeQuery();
            while(rs2.next()){
                students.add(new User(rs2.getInt("user_id"), rs2.getString("username"), "student", teacher.getSchoolId(), 0.0, rs2.getString("roll_no")));
            }

            // 3. Get Specific Class Enrollments (to show who is in what class)
            String sqlE = "SELECT u.username, c.class_name, sc.student_id, sc.class_id " +
                          "FROM student_classes sc " +
                          "JOIN users u ON sc.student_id = u.user_id " +
                          "JOIN classes c ON sc.class_id = c.class_id " +
                          "WHERE c.teacher_id = ?";
            PreparedStatement pst3 = conn.prepareStatement(sqlE);
            pst3.setInt(1, teacher.getId());
            ResultSet rs3 = pst3.executeQuery();
            while(rs3.next()){
                Map<String, Object> eMap = new HashMap<>();
                eMap.put("sName", rs3.getString("username"));
                eMap.put("cName", rs3.getString("class_name"));
                eMap.put("sId", rs3.getInt("student_id"));
                eMap.put("cId", rs3.getInt("class_id"));
                enrollments.add(eMap);
            }

            request.setAttribute("classes", classes);
            request.setAttribute("students", students);
            request.setAttribute("enrollments", enrollments);
            request.getRequestDispatcher("manage_students.jsp").forward(request, response);
        } catch (SQLException e) { e.printStackTrace(); }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        try (Connection conn = DBConnection.getConnection()) {
            if ("addBulk".equals(action)) {
                String[] names = request.getParameterValues("names");
                String[] rolls = request.getParameterValues("rolls");
                String sql = "INSERT INTO users (username, password, role, school_id, roll_no) VALUES (?, 'pass123', 'student', ?, ?)";
                PreparedStatement pst = conn.prepareStatement(sql);
                for(int i=0; i<names.length; i++) {
                    if(names[i] != null && !names[i].isEmpty()){
                        pst.setString(1, names[i]);
                        pst.setInt(2, teacher.getSchoolId());
                        pst.setString(3, rolls[i]);
                        pst.addBatch();
                    }
                }
                pst.executeBatch();
            } else if ("linkClass".equals(action)) {
                int sId = Integer.parseInt(request.getParameter("studentId"));
                int cId = Integer.parseInt(request.getParameter("classId"));
                String sql = "INSERT INTO student_classes (student_id, class_id) VALUES (?, ?) ON CONFLICT DO NOTHING";
                PreparedStatement pst = conn.prepareStatement(sql);
                pst.setInt(1, sId);
                pst.setInt(2, cId);
                pst.executeUpdate();
            } else if ("deleteStudent".equals(action)) {
                int sId = Integer.parseInt(request.getParameter("studentId"));
                String sql = "DELETE FROM users WHERE user_id = ? AND school_id = ?";
                PreparedStatement pst = conn.prepareStatement(sql);
                pst.setInt(1, sId);
                pst.setInt(2, teacher.getSchoolId());
                pst.executeUpdate();
            } else if ("removeFromClass".equals(action)) {
                int sId = Integer.parseInt(request.getParameter("studentId"));
                int cId = Integer.parseInt(request.getParameter("classId"));
                String sql = "DELETE FROM student_classes WHERE student_id = ? AND class_id = ?";
                PreparedStatement pst = conn.prepareStatement(sql);
                pst.setInt(1, sId);
                pst.setInt(2, cId);
                pst.executeUpdate();
            }
            response.sendRedirect("manageStudents?success=1");
        } catch (SQLException e) { e.printStackTrace(); }
    }
}