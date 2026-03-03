<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.functions" prefix="fn" %>
<%
    User userObj = (User) session.getAttribute("user");
    if (userObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String fullName = (userObj.getFullName() != null && !userObj.getFullName().isEmpty()) ? userObj.getFullName() : "Student";
    char avatarLetter = fullName.charAt(0);
    request.setAttribute("fullName", fullName);
    request.setAttribute("avatarLetter", avatarLetter);
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
        <div class="avatar-circle" style="margin: 0 auto 10px;"><c:out value="${avatarLetter}" /></div>
        <div style="font-weight: bold; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"><c:out value="${fullName}" /></div>
        <small style="color: #64748b;">Roll No: <c:out value="${sessionScope.user.rollNo}" /></small>
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
            <h1 style="margin: 5px 0; font-size: 42px;">₹<c:out value="${balance != null ? balance : '0.00'}" /></h1>
            <p style="margin: 0; opacity: 0.8;">Welcome back, <c:out value="${fullName}" />!</p>
        </div>

        <div class="card">
            <h3>🔔 Pending Payment Requests</h3>
            <c:choose>
                <c:when test="${not empty pendingRequests}">
                    <c:forEach var="r" items="${pendingRequests}">
                        <div style="background:#fffbeb; padding:15px; border-radius:12px; border:1px solid #fcd34d; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center;">
                            <div>
                                <strong><c:out value="${r.from}" /></strong>: ₹<c:out value="${r.amt}" /><br>
                                <small>"<c:out value="${r.note}" />"</small>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="sendMoney">
                                <input type="hidden" name="requestId" value="<c:out value='${r.id}' />">
                                <input type="hidden" name="receiverUsername" value="<c:out value='${r.from}' />">
                                <input type="hidden" name="amount" value="<c:out value='${r.amt}' />">
                                <button type="submit" class="btn" style="background:#059669; width:auto; padding: 8px 15px;">Pay Now</button>
                            </form>
                        </div>
                    </c:forEach>
                </c:when>
                <c:otherwise>
                    <p style="color: #94a3b8;">No new requests.</p>
                </c:otherwise>
            </c:choose>
        </div>

        <div class="card">
            <h3>Recent Wallet Activity</h3>
            <table>
                <c:choose>
                    <c:when test="${not empty history}">
                        <c:forEach var="h" items="${history}">
                            <tr>
                                <td style="padding: 12px 0;">
                                    <div style="font-weight: 500;"><c:out value="${h.desc}" /></div>
                                    <small style="color: #94a3b8;"><c:out value="${h.date}" /></small>
                                </td>
                                <td align="right" class="${h.isCredit ? 'text-green' : 'text-red'}" style="font-weight:bold; font-size: 16px;">
                                    <c:out value="${h.isCredit ? '+' : '-'}" />₹<c:out value="${h.amount}" />
                                </td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr><td colspan="2" style="text-align: center; color: #94a3b8; padding: 20px;">No recent transactions.</td></tr>
                    </c:otherwise>
                </c:choose>
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
            <button class="btn toggle-btn" id="studentMarketBtn" onclick="toggleStudentMarket()">📜 Order History</button>
        </div>
        <div id="marketStoreGrid">
            <div class="item-grid">
                <c:forEach var="i" items="${availableItems}">
                    <div class="card" style="border:1px solid #e2e8f0; display:flex; flex-direction:column; justify-content:space-between;">
                        <div>
                            <h4><c:out value="${i.name}" /></h4>
                            <p style="font-size:12px; color:#64748b;"><c:out value="${i.desc}" /></p>
                        </div>
                        <div style="margin-top:10px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                <span class="text-green" style="font-weight:bold; font-size:18px;">₹<c:out value="${i.price}" /></span>
                                <span style="font-size:11px; color:#94a3b8;">
                                    <c:out value="${i.stock == -1 ? '♾️ Unlimited' : i.stock.concat(' left')}" />
                                </span>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="buyItem">
                                <input type="hidden" name="itemId" value="<c:out value='${i.id}' />">
                                <input type="hidden" name="itemName" value="<c:out value='${i.name}' />">
                                <button type="submit" class="btn" style="background:#f59e0b;" ${i.stock == 0 ? 'disabled' : ''}>
                                    <c:out value="${i.stock == 0 ? 'Sold Out' : 'Buy Now'}" />
                                </button>
                            </form>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>
        <div id="marketHistoryAudit" style="display: none;">
            <div class="card">
                <input type="text" id="auditSearch" onkeyup="filterStudentAudit()" placeholder="🔍 Search orders..." class="search-bar">
                <table>
                    <thead>
                        <tr style="background: #f8fafc;">
                            <th>Item</th><th>Price</th><th>Date</th><th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="auditTableBody">
                        <c:forEach var="o" items="${myOrders}">
                            <tr class="audit-row">
                                <td class="order-item"><strong><c:out value="${o.item_name}" /></strong></td>
                                <td>₹<c:out value="${o.price}" /></td>
                                <td><small><c:out value="${o.date}" /></small></td>
                                <td class="order-status">
                                    <c:choose>
                                        <c:when test="${o.status == 'PENDING_TEACHER'}"><span style="color: #f59e0b;">⏳ Pending</span></c:when>
                                        <c:when test="${o.status == 'COMPLETED'}"><span class="text-green">✅ Approved</span></c:when>
                                        <c:otherwise><span class="text-red">❌ Rejected</span></c:otherwise>
                                    </c:choose>
                                </td>
                            </tr>
                        </c:forEach>
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
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">FULL NAME</label><input type="text" value="<c:out value='${sessionScope.user.fullName}' />" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">ROLL NUMBER</label><input type="text" value="<c:out value='${sessionScope.user.rollNo}' />" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">EMAIL ADDRESS</label><input type="text" value="<c:out value='${sessionScope.user.email}' />" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #64748b; font-size: 13px;">SYSTEM USERNAME</label><input type="text" value="<c:out value='${sessionScope.user.username}' />" disabled style="background: #f1f5f9;"></div>
                    <div><label style="font-weight: bold; color: #10b981; font-size: 13px;">BIRTHDATE</label><input type="date" name="birthdate" value="<c:out value='${sessionScope.user.birthdate}' />" required></div>
                </div>
                <div style="margin-top: 20px; border-top: 1px solid #f1f5f9; padding-top: 20px;">
                    <button type="submit" class="btn" style="background: #10b981; width: auto; padding: 12px 40px;">Save</button>
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