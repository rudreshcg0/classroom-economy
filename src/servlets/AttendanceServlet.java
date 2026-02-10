package servlets;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import utils.DBConnection;
import models.User;

@WebServlet("/markAttendance")
public class AttendanceServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User teacher = (User) session.getAttribute("user");
        String classIdStr = request.getParameter("classId");

        if (teacher == null || classIdStr == null) {
            response.sendRedirect("teacherDashboard");
            return;
        }

        List<User> linkedStudents = new ArrayList<>();
        Map<String, Object> classDetails = new HashMap<>();

        try (Connection conn = DBConnection.getConnection()) {
            String sqlClass = "SELECT class_id, class_name, pay_per_session FROM classes WHERE class_id = ? AND teacher_id = ?";
            try (PreparedStatement pst1 = conn.prepareStatement(sqlClass)) {
                pst1.setInt(1, Integer.parseInt(classIdStr));
                pst1.setInt(2, teacher.getId());
                ResultSet rs1 = pst1.executeQuery();
                if (rs1.next()) {
                    classDetails.put("id", rs1.getInt("class_id"));
                    classDetails.put("name", rs1.getString("class_name"));
                    classDetails.put("pay", rs1.getDouble("pay_per_session"));
                }
            }

            String sqlStudents = "SELECT u.user_id, u.username, u.roll_no, w.balance " +
                                 "FROM users u " +
                                 "JOIN student_classes sc ON u.user_id = sc.student_id " +
                                 "JOIN wallets w ON u.user_id = w.student_id " +
                                 "WHERE sc.class_id = ? ORDER BY u.roll_no ASC";
            try (PreparedStatement pst2 = conn.prepareStatement(sqlStudents)) {
                pst2.setInt(1, Integer.parseInt(classIdStr));
                ResultSet rs2 = pst2.executeQuery();
                while (rs2.next()) {
                    linkedStudents.add(new User(
                        rs2.getInt("user_id"),
                        rs2.getString("username"),
                        "student",
                        teacher.getSchoolId(),
                        rs2.getDouble("balance"),
                        rs2.getString("roll_no")
                    ));
                }
            }

            request.setAttribute("classDetails", classDetails);
            request.setAttribute("students", linkedStudents);
            request.getRequestDispatcher("mark_attendance.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String[] studentIds = request.getParameterValues("presentStudents");
        String classIdStr = request.getParameter("classId");
        String schoolIdStr = request.getParameter("schoolId");

        if (classIdStr == null || studentIds == null) {
            response.sendRedirect("teacherDashboard?error=no_selection");
            return;
        }

        int classId = Integer.parseInt(classIdStr);
        int schoolId = Integer.parseInt(schoolIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            conn.setAutoCommit(false);

            // 1. Mints money into the student wallet
            String updateWallet = "UPDATE wallets SET balance = balance + (SELECT pay_per_session FROM classes WHERE class_id = ?) WHERE student_id = ?";
            
            // 2. Marks attendance on the specific date
            String markAttend = "INSERT INTO attendance (student_id, class_id, is_present, processed_payment, attendance_date) VALUES (?, ?, TRUE, TRUE, CURRENT_DATE)";
            
            // 3. Logs the system transaction (sender_id is NULL or a specific System Account ID)
            String logTrans = "INSERT INTO transactions (sender_id, receiver_id, amount, type, description, school_id) " +
                              "VALUES (NULL, ?, (SELECT pay_per_session FROM classes WHERE class_id = ?), 'ATTENDANCE_PAY', 'System Attendance Reward', ?)";

            try (PreparedStatement pstWallet = conn.prepareStatement(updateWallet);
                 PreparedStatement pstAttend = conn.prepareStatement(markAttend);
                 PreparedStatement pstLog = conn.prepareStatement(logTrans)) {

                for (String sId : studentIds) {
                    int studentId = Integer.parseInt(sId);

                    // Student Wallet Update
                    pstWallet.setInt(1, classId);
                    pstWallet.setInt(2, studentId);
                    pstWallet.executeUpdate();

                    // Attendance Mark
                    pstAttend.setInt(1, studentId);
                    pstAttend.setInt(2, classId);
                    pstAttend.executeUpdate();

                    // Transaction Log
                    pstLog.setInt(1, studentId);
                    pstLog.setInt(2, classId);
                    pstLog.setInt(3, schoolId);
                    pstLog.executeUpdate();
                }

                conn.commit();
                response.sendRedirect("teacherDashboard?success=1");

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            response.sendRedirect("teacherDashboard?error=already_paid_today");
        }
    }
}