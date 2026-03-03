<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%
    User userObj = (User) session.getAttribute("user");
    if (userObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String fullName = (userObj.getFullName() != null && !userObj.getFullName().isEmpty()) ? userObj.getFullName() : "Student";
    char avatarLetter = fullName.charAt(0);
%>
<!DOCTYPE html>
<html>
<head>
    <title>Student Wallet - VCES Pay</title>
    <link rel="stylesheet" href="css/dashboard.css">
    <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
    <script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
</head>
<body>

<button class="mobile-nav-toggle" style="z-index: 1101;" onclick="toggleSidebar()">☰</button>

<div class="sidebar" id="sidebar">
    <span class="sidebar-close" onclick="toggleSidebar()">✕</span>
    <h2>VCES Pay</h2>
    
    <div style="padding: 10px; background: #0f172a; border-radius: 12px; margin-bottom: 20px; text-align: center;">
        <div class="avatar-circle" style="margin: 0 auto 10px;"><%= avatarLetter %></div>
        <div style="font-weight: bold; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><%= fullName %></div>
        <small style="color: #64748b;">Roll No: ${sessionScope.user.rollNo}</small>
    </div>

    <div class="nav-item active" onclick="openTab(event, 'home')">🏠 Dashboard</div>
    <div class="nav-item" onclick="openTab(event, 'pay')">💸 Pay & Request</div>
    <div class="nav-item" onclick="openTab(event, 'shop')">🛒 Marketplace</div>
    <div class="nav-item" onclick="openTab(event, 'profile')">👤 My Profile</div>
    <a href="login.jsp" class="nav-item" style="color: #f87171; margin-top: 30px;">Logout</a>
</div>

<div class="main">
    <div id="home" class="tab active">
        <div class="balance-card">
            <small>WALLET BALANCE</small>
            <h1 style="margin: 5px 0; font-size: 42px;">₹${balance != null ? balance : '0.00'}</h1>
            <p style="margin: 0; opacity: 0.8;">Welcome back, <%= fullName %>!</p>
        </div>

        <div class="card">
            <h3>🔔 Pending Payment Requests</h3>
            <% List<Map<String, Object>> pr = (List<Map<String, Object>>)request.getAttribute("pendingRequests");
               if(pr != null && !pr.isEmpty()) { for(Map<String, Object> r : pr) { %>
                <div style="background:#fffbeb; padding:15px; border-radius:12px; border:1px solid #fcd34d; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center;">
                    <div><strong><%= r.get("from") %></strong>: ₹<%= r.get("amt") %><br><small>"<%= r.get("note") %>"</small></div>
                    <form action="studentAction" method="POST">
                        <input type="hidden" name="action" value="sendMoney">
                        <input type="hidden" name="requestId" value="<%= r.get("id") %>">
                        <input type="hidden" name="receiverUsername" value="<%= r.get("from") %>">
                        <input type="hidden" name="amount" value="<%= r.get("amt") %>">
                        <button type="submit" class="btn" style="background:#059669; width:auto; padding: 8px 15px;">Pay Now</button>
                    </form>
                </div>
            <% } } else { %> <p style="color: #94a3b8;">No new requests.</p> <% } %>
        </div>

        <div class="card">
            <h3>Recent Wallet Activity</h3>
            <table>
                <% List<Map<String, Object>> hist = (List<Map<String, Object>>)request.getAttribute("history");
                   if(hist != null && !hist.isEmpty()) { 
                       for(Map<String, Object> h : hist) { 
                           boolean isCredit = (boolean)h.get("isCredit"); 
                %>
                    <tr>
                        <td style="padding: 12px 0;">
                            <div style="font-weight: 500;"><%= h.get("desc") %></div>
                            <small style="color: #94a3b8;"><%= h.get("date") %></small>
                        </td>
                        <td align="right" class="<%= isCredit ? "text-green" : "text-red" %>" style="font-weight:bold; font-size: 16px;">
                            <%= isCredit ? "+" : "-" %>₹<%= h.get("amount") %>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr><td colspan="2" style="text-align: center; color: #94a3b8; padding: 20px;">No recent transactions.</td></tr>
                <% } %>
            </table>
        </div>
    </div>

    <div id="pay" class="tab">
        <div class="card">
            <h3>💸 Send Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="sendMoney">
                <input type="text" name="receiverUsername" placeholder="Recipient Username" required>
                <input type="number" name="amount" placeholder="Amount (₹)" step="0.01" required>
                <input type="text" name="note" placeholder="Note (Optional)">
                <button type="submit" class="btn" style="background:#3b82f6;">Send Now</button>
            </form>
        </div>
        <div class="card" style="border-top: 4px solid #8b5cf6;">
            <h3>📥 Request Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="requestMoney">
                <input type="text" name="payerUsername" placeholder="Friend's Username" required>
                <input type="number" name="amount" placeholder="Amount (₹)" step="0.01" required>
                <input type="text" name="note" placeholder="Reason for request">
                <button type="submit" class="btn" style="background:#8b5cf6;">Send Request</button>
            </form>
        </div>
    </div>

    <div id="shop" class="tab">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h2 style="margin: 0;">Marketplace</h2>
            <button class="btn toggle-btn" id="studentMarketBtn" onclick="toggleStudentMarket()">📜 View Order History</button>
        </div>
        <div id="marketStoreGrid">
            <div class="item-grid">
                <% List<Map<String, Object>> items = (List<Map<String, Object>>)request.getAttribute("availableItems");
                   if(items != null) { for(Map<String, Object> i : items) { int stock = (int)i.get("stock"); %>
                    <div class="card" style="border:1px solid #e2e8f0; display:flex; flex-direction:column; justify-content:space-between;">
                        <div>
                            <h4><%= i.get("name") %></h4>
                            <p style="font-size:12px; color:#64748b;"><%= i.get("desc") %></p>
                        </div>
                        <div style="margin-top:10px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                <span class="text-green" style="font-weight:bold; font-size:18px;">₹<%= i.get("price") %></span>
                                <span id="stock-count-<%= i.get("id") %>" style="font-size:11px; color:#94a3b8;"><%= stock == -1 ? "♾️ Unlimited" : stock + " left" %></span>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="buyItem">
                                <input type="hidden" name="itemId" value="<%= i.get("id") %>">
                                <input type="hidden" name="itemPrice" value="<%= i.get("price") %>">
                                <input type="hidden" name="itemName" value="<%= i.get("name") %>">
                                <button type="submit" id="buy-btn-<%= i.get("id") %>" class="btn" style="background:#f59e0b;" <%= stock == 0 ? "disabled" : "" %>><%= stock == 0 ? "Sold Out" : "Buy Now" %></button>
                            </form>
                        </div>
                    </div>
                <% } } %>
            </div>
        </div>
        <div id="marketHistoryAudit" style="display: none;">
            <div class="card">
                <input type="text" id="auditSearch" onkeyup="filterStudentAudit()" placeholder="🔍 Search orders by item name or status..." class="search-bar">
                <table>
                    <thead>
                        <tr style="background: #f8fafc;">
                            <th>Item</th><th>Price</th><th>Date</th><th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="auditTableBody">
                        <% List<Map<String, Object>> myOrders = (List<Map<String, Object>>)request.getAttribute("myOrders");
                           if(myOrders != null) { for(Map<String, Object> o : myOrders) { String status = (String)o.get("status"); %>
                            <tr class="audit-row">
                                <td class="order-item"><strong><%= o.get("item_name") %></strong></td>
                                <td>₹<%= o.get("price") %></td>
                                <td><small><%= o.get("date") %></small></td>
                                <td class="order-status">
                                    <% if("PENDING_TEACHER".equals(status)) { %><span style="color: #f59e0b;">⏳ Pending</span>
                                    <% } else if("COMPLETED".equals(status)) { %><span class="text-green">✅ Approved</span>
                                    <% } else { %><span class="text-red">❌ Rejected</span><% } %>
                                </td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div id="profile" class="tab">
        <h1>My Profile</h1>
        <div class="card">
            <form action="updateProfile" method="POST">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">FULL NAME</label><input type="text" value="${sessionScope.user.fullName}" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">ROLL NUMBER</label><input type="text" value="${sessionScope.user.rollNo}" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">EMAIL ADDRESS</label><input type="text" value="${sessionScope.user.email}" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">SYSTEM USERNAME</label><input type="text" value="${sessionScope.user.username}" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #10b981; font-size: 13px;">BIRTHDATE</label><input type="date" name="birthdate" value="${sessionScope.user.birthdate}" required></div>
                </div>
                <div style="margin-top: 20px; border-top: 1px solid #f1f5f9; padding-top: 20px;">
                    <button type="submit" class="btn" style="background: #10b981; width: auto; padding: 12px 40px;">Save</button>
                    <p style="font-size: 12px; color: #94a3b8; margin-top: 10px;">Note: Name and Email can only be changed by your teacher.</p>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="successOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_afwjhpyv.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#10b981; font-size:28px; margin-top:-20px;">Success!</h2>
    <button onclick="closePopups()" class="btn" style="background:#1e293b; width:180px; margin-top:30px;">Done</button>
</div>

<div id="errorOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_ghfp8v9f.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#ef4444; font-size:28px; margin-top:-20px;">Failed</h2>
    <p id="errorTxt" style="color:#64748b;">Insufficient balance or system error.</p>
    <button onclick="closePopups()" class="btn" style="background:#ef4444; width:180px; margin-top:30px;">Try Again</button>
</div>

<audio id="successSound" src="https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3"></audio>
<audio id="errorSound" src="https://assets.mixkit.co/active_storage/sfx/951/951-preview.mp3"></audio>

<script src="js/dashboard.js"></script>
</body>
</html>