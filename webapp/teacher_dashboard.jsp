<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User, models.MarketplaceItem" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background-color: #f0f2f5; display: flex; }
        
        /* SIDEBAR STYLING */
        .sidebar { width: 260px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; }
        .sidebar h2 { color: #63b3ed; margin-bottom: 30px; }
        .sidebar-link { display: block; color: #cbd5e0; text-decoration: none; padding: 12px; border-radius: 8px; margin-bottom: 10px; transition: 0.3s; cursor: pointer; }
        .sidebar-link:hover { background: #2d3748; color: white; }
        .sidebar-link.active { background: #3182ce; color: white; }
        
        /* CONTENT STYLING */
        .main-content { margin-left: 310px; padding: 40px; width: calc(100% - 310px); }
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }
        
        .card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .balance-box { background: #ebf8ff; color: #2b6cb0; padding: 20px; border-radius: 10px; border-left: 5px solid #3182ce; margin-bottom: 25px; }
        
        .btn-submit { background-color: #38a169; color: white; padding: 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; transition: 0.2s; }
        .btn-submit:hover { opacity: 0.9; }
        
        input, select { padding: 12px; width: 100%; margin-bottom: 15px; border-radius: 8px; border: 1px solid #cbd5e0; box-sizing: border-box; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 10px; text-align: left;}
        th, td { padding: 12px; border-bottom: 1px solid #edf2f7; }
        
        /* BADGES */
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .bg-active { background: #c6f6d5; color: #22543d; }
        .bg-low { background: #feebc8; color: #744210; }
        .bg-out { background: #fed7d7; color: #822727; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
    
    <nav>
        <div onclick="showTab('overview', this)" class="sidebar-link active">🏠 Dashboard Overview</div>
        <div onclick="showTab('attendance', this)" class="sidebar-link">📝 Mark Attendance</div>
        <div onclick="showTab('marketplace', this)" class="sidebar-link">🏪 Marketplace Manager</div>
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link">💰 Financial Ledger</a>
        <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
        <a href="login.html" style="color: #fc8181;" class="sidebar-link">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">

    <div id="overview" class="tab-panel active">
        <h1>Teacher Dashboard</h1>
        <div class="balance-box">
            <small>CLASS REWARD BUDGET</small>
            <h2 style="margin: 5px 0;">$${allowance != null ? allowance : "0.00"}</h2>
        </div>
        <div class="card">
            <h3>Quick Summary</h3>
            <p>Welcome back! You have <strong>${marketplaceOrders.size()}</strong> pending purchase requests to review in the Marketplace tab.</p>
        </div>
    </div>

    <div id="attendance" class="tab-panel">
        <h1>Attendance Console</h1>
        <div class="card">
            <h3>📝 Process Session Salaries</h3>
            <p style="color: #718096;">Select a class to begin marking attendance and disbursing student rewards.</p>
            <form action="markAttendance" method="GET">
                <select name="classId" required>
                    <option value="">-- Choose Class --</option>
                    <% List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
                       if (classes != null) for (Map<String, Object> c : classes) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                    <% } %>
                </select>
                <button type="submit" class="btn-submit" style="width: 100%;">Launch Attendance Console</button>
            </form>
        </div>
    </div>

    <div id="marketplace" class="tab-panel">
        <h1>Marketplace Manager</h1>
        
        <div class="card">
            <h3>🚀 Create New Store Item</h3>
            <form action="teacherAction" method="POST" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <input type="hidden" name="action" value="createItem">
                <input type="text" name="itemName" placeholder="Item Name (e.g. Hall Pass)" required>
                <input type="number" name="price" placeholder="Price ($)" step="0.01" required>
                <input type="number" name="stock" placeholder="Initial Stock (-1 for unlimited)" required>
                <input type="text" name="description" placeholder="Short Description">
                <button type="submit" class="btn-submit" style="grid-column: span 2; background: #3182ce;">Add to Student Store</button>
            </form>
        </div>

        <div class="card" style="border-top: 4px solid #3182ce;">
            <h3>📊 My Live Inventory</h3>
            <table>
                <thead>
                    <tr>
                        <th>Item</th>
                        <th>Price</th>
                        <th>Stock</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <% List<MarketplaceItem> myItems = (List<MarketplaceItem>)request.getAttribute("myItems");
                       if(myItems != null && !myItems.isEmpty()) { 
                           for(MarketplaceItem item : myItems) { %>
                        <tr>
                            <td><strong><%= item.getName() %></strong></td>
                            <td style="color: #38a169; font-weight: bold;">$<%= item.getPrice() %></td>
                            <td><%= (item.getStock() == -1) ? "♾️" : item.getStock() %></td>
                            <td>
                                <% if(item.getStock() == 0) { %>
                                    <span class="badge bg-out">SOLD OUT</span>
                                <% } else if(item.getStock() > 0 && item.getStock() < 5) { %>
                                    <span class="badge bg-low">LOW STOCK</span>
                                <% } else { %>
                                    <span class="badge bg-active">ACTIVE</span>
                                <% } %>
                            </td>
                        </tr>
                    <% } } else { %>
                        <tr><td colspan="4" align="center">No items found in your store.</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <div class="card" style="border-top: 4px solid #38a169;">
            <h3>🛒 Pending Purchase Requests</h3>
            <form action="teacherAction" method="POST">
                <input type="hidden" name="action" value="bulkProcess">
                <table>
                    <thead>
                        <tr style="background: #f7fafc;">
                            <th><input type="checkbox" onclick="toggleChecks(this)"></th>
                            <th>Student</th>
                            <th>Item Requested</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% List<Map<String, Object>> mOrders = (List<Map<String, Object>>)request.getAttribute("marketplaceOrders");
                           if(mOrders != null && !mOrders.isEmpty()) { for(Map<String, Object> o : mOrders) { %>
                            <tr>
                                <td><input type="checkbox" name="selectedOrders" value="<%= o.get("id") %>"></td>
                                <td><%= o.get("student") %></td>
                                <td><span style="background:#eef2ff; color:#4338ca; padding:4px 8px; border-radius:4px;"><%= o.get("item") %></span></td>
                                <td><small><%= o.get("date") %></small></td>
                            </tr>
                        <% } } else { %>
                            <tr><td colspan="4" align="center">No pending requests at this time.</td></tr>
                        <% } %>
                    </tbody>
                </table>
                <div style="margin-top:20px; display:flex; gap:15px;">
                    <button type="submit" name="decision" value="APPROVED" class="btn-submit" style="background:#38a169; flex:1;">Approve Selected</button>
                    <button type="submit" name="decision" value="REJECTED" class="btn-submit" style="background:#e53e3e; flex:1;">Reject & Refund Selected</button>
                </div>
            </form>
        </div>
    </div>

</div>

<script>
    // Tab Panel Switching Logic
    function showTab(tabId, element) {
        document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.remove('active'));
        document.querySelectorAll('.sidebar-link').forEach(link => link.classList.remove('active'));
        
        document.getElementById(tabId).classList.add('active');
        element.classList.add('active');
    }

    // Bulk Select Checkboxes
    function toggleChecks(source) {
        var checkboxes = document.getElementsByName('selectedOrders');
        for(var i=0; i<checkboxes.length; i++) checkboxes[i].checked = source.checked;
    }
</script>
</body>
</html>