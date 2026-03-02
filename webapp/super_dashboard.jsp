<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, utils.DBConnection, models.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getRole().equals("platform_root"))) {
        response.sendRedirect("login.html");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Platform Management - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/super_dashboard.css">
</head>
<body>

    <div class="container">
        <div class="header-main">
            <h2>🌍 Platform Management Hub</h2>
            <div class="user-meta">
                <span>Master: <strong><%= user.getUsername() %></strong></span>
                <a href="login.jsp" class="logout-link">Logout</a>
            </div>
        </div>

        <div class="tab-navigation">
            <button class="tab-btn active" data-target="section-roster">🏫 Managed Schools</button>
            <button class="tab-btn" data-target="section-add-school">➕ Add New School</button>
            <button class="tab-btn" data-target="section-assign-admin">👤 Appoint Admin</button>
        </div>

        <div id="section-roster" class="tab-content active">
            <div class="card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h3>Managed Schools & Admins</h3>
                    <input type="text" id="schoolSearch" onkeyup="filterTable()" class="search-box" placeholder="🔍 Search school or admin...">
                </div>
                <table id="schoolTable">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>School Name</th>
                            <th>Appointed Admin</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        String sql = "SELECT s.school_id, s.school_name, u.username AS admin_name, u.user_id AS admin_id " +
                                     "FROM schools s LEFT JOIN users u ON s.school_id = u.school_id AND u.role = 'school_admin' " +
                                     "ORDER BY s.school_id";
                        try (Connection conn = DBConnection.getConnection();
                             Statement st = conn.createStatement();
                             ResultSet rs = st.executeQuery(sql)) {
                            while(rs.next()) {
                                String adminName = rs.getString("admin_name");
                        %>
                        <tr>
                            <td><%= rs.getInt("school_id") %></td>
                            <td><strong><%= rs.getString("school_name") %></strong></td>
                            <td><%= (adminName != null) ? "👤 " + adminName : "<em>Unassigned</em>" %></td>
                            <td>
                                <div style="display: flex; gap: 8px;">
                                    <button onclick="editSchool(<%= rs.getInt("school_id") %>, '<%= rs.getString("school_name") %>')" class="btn btn-edit">✏️ Rename</button>
                                    <form action="superAdminAction" method="POST" onsubmit="return confirm('DELETE SCHOOL? This wipes all data.')">
                                        <input type="hidden" name="action" value="deleteSchool">
                                        <input type="hidden" name="schoolId" value="<%= rs.getInt("school_id") %>">
                                        <button type="submit" class="btn btn-del">🗑️ School</button>
                                    </form>
                                    <% if (adminName != null) { %>
                                    <form action="superAdminAction" method="POST" onsubmit="return confirm('Remove this Admin?')">
                                        <input type="hidden" name="action" value="deleteAdmin">
                                        <input type="hidden" name="adminId" value="<%= rs.getInt("admin_id") %>">
                                        <button type="submit" class="btn btn-orange">👤 Reset</button>
                                    </form>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <% } } catch(Exception e) {} %>
                    </tbody>
                </table>
            </div>
        </div>

        <div id="section-add-school" class="tab-content">
            <div class="card card-center">
                <h3>+ Add New School</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchool">
                    <input type="text" name="schoolName" placeholder="Enter Full School Name" required>
                    <button type="submit" class="btn btn-save">Create School Instance</button>
                </form>
            </div>
        </div>

        <div id="section-assign-admin" class="tab-content">
            <div class="card card-center">
                <h3>+ Appoint School Admin</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchoolAdmin">
                    <input type="text" name="adminUser" placeholder="Admin Username" required>
                    <input type="password" name="adminPass" placeholder="Admin Password" required>
                    <select name="schoolId" required>
                        <option value="">-- Assign to School --</option>
                        <% try (Connection conn = DBConnection.getConnection();
                               Statement st = conn.createStatement();
                               ResultSet rs = st.executeQuery("SELECT * FROM schools ORDER BY school_name")) {
                            while(rs.next()) { %>
                                <option value="<%= rs.getInt("school_id") %>"><%= rs.getString("school_name") %></option>
                        <% } } catch(Exception e) {} %>
                    </select>
                    <button type="submit" class="btn btn-save" style="background: #2980b9;">Appoint & Assign</button>
                </form>
            </div>
        </div>

    </div>

    <form id="editForm" action="superAdminAction" method="POST" style="display:none;">
        <input type="hidden" name="action" value="editSchool">
        <input type="hidden" name="schoolId" id="editSchoolId">
        <input type="hidden" name="newName" id="editNewName">
    </form>

    <script src="${pageContext.request.contextPath}/js/super_dashboard.js"></script>
</body>
</html>