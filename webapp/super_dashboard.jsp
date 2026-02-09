<%@ page import="java.sql.*, utils.DBConnection, models.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getRole().equals("platform_root") && !user.getRole().equals("super_admin"))) {
        response.sendRedirect("login.html");
        return;
    }
%>
<html>
<head>
    <title>Platform Root Control</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f4f7f6; padding: 40px; margin: 0; }
        .container { max-width: 1200px; margin: auto; }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); margin-bottom: 25px; }
        h2, h3 { color: #2c3e50; margin-top: 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; background: white; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        th { background: #34495e; color: white; border-radius: 4px 4px 0 0; }
        .btn-del { background: #e74c3c; color: white; border: none; padding: 8px 15px; border-radius: 6px; cursor: pointer; transition: 0.3s; }
        .btn-del:hover { background: #c0392b; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 25px; }
        input, select { padding: 12px; width: 100%; margin: 8px 0; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
        .btn-save { background: #27ae60; color: white; border: none; padding: 12px; border-radius: 6px; cursor: pointer; width: 100%; font-weight: bold; }
        .btn-save:hover { background: #219150; }
    </style>
</head>
<body>
    <div class="container">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h2>🌍 Platform Management Hub</h2>
            <p>Master: <strong><%= user.getUsername() %></strong> | <a href="login.html" style="color: #e74c3c;">Logout</a></p>
        </div>

        <div class="grid">
            <div class="card">
                <h3>+ Add New School</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchool">
                    <input type="text" name="schoolName" placeholder="School Name" required>
                    <button type="submit" class="btn-save">Create School</button>
                </form>
            </div>

            <div class="card">
                <h3>+ Appoint School Admin</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchoolAdmin">
                    <input type="text" name="adminUser" placeholder="Admin Username" required>
                    <input type="password" name="adminPass" placeholder="Password" required>
                    <select name="schoolId" required>
                        <option value="">-- Assign to School --</option>
                        <% 
                        try (Connection conn = DBConnection.getConnection();
                             Statement st = conn.createStatement();
                             ResultSet rs = st.executeQuery("SELECT * FROM schools ORDER BY school_name")) {
                            while(rs.next()) { %>
                            <option value="<%= rs.getInt("school_id") %>"><%= rs.getString("school_name") %></option>
                        <% } } catch(Exception e) {} %>
                    </select>
                    <button type="submit" class="btn-save" style="background: #2980b9;">Assign Admin</button>
                </form>
            </div>
        </div>

        <div class="card">
            <h3>Registered Schools</h3>
            <table>
                <thead>
                    <tr><th>ID</th><th>School Name</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <% try (Connection conn = DBConnection.getConnection();
                            Statement st = conn.createStatement();
                            ResultSet rs = st.executeQuery("SELECT * FROM schools")) {
                        while(rs.next()) { %>
                        <tr>
                            <td><%= rs.getInt("school_id") %></td>
                            <td><%= rs.getString("school_name") %></td>
                            <td>
                                <form action="superAdminAction" method="POST" style="display:inline;" onsubmit="return confirm('WARNING: Deleting a school deletes ALL Teachers, Students, and Data. Continue?')">
                                    <input type="hidden" name="action" value="deleteSchool">
                                    <input type="hidden" name="schoolId" value="<%= rs.getInt("school_id") %>">
                                    <button type="submit" class="btn-del">Delete School</button>
                                </form>
                            </td>
                        </tr>
                    <% } } catch(Exception e) {} %>
                </tbody>
            </table>
        </div>

        <div class="card">
            <h3>Active School Admins</h3>
            <table>
                <thead>
                    <tr><th>Admin Username</th><th>School Name</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <% try (Connection conn = DBConnection.getConnection();
                            Statement st = conn.createStatement();
                            ResultSet rs = st.executeQuery(
                                "SELECT u.user_id, u.username, s.school_name " +
                                "FROM users u JOIN schools s ON u.school_id = s.school_id " +
                                "WHERE u.role = 'school_admin'")) {
                        while(rs.next()) { %>
                        <tr>
                            <td><%= rs.getString("username") %></td>
                            <td><%= rs.getString("school_name") %></td>
                            <td>
                                <form action="superAdminAction" method="POST" style="display:inline;" onsubmit="return confirm('Remove admin access for this user?')">
                                    <input type="hidden" name="action" value="deleteAdmin">
                                    <input type="hidden" name="adminId" value="<%= rs.getInt("user_id") %>">
                                    <button type="submit" class="btn-del" style="background: #f39c12;">Remove Admin</button>
                                </form>
                            </td>
                        </tr>
                    <% } } catch(Exception e) {} %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>