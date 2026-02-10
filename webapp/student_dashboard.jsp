<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Student Wallet - VCES Pay</title>
    <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
    <script src="https://unpkg.com/@lottiefiles/lottie-player@latest/dist/lottie-player.js"></script>
    
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; display: flex; background: #f8fafc; overflow-x: hidden; }
        .sidebar { width: 260px; background: #1e293b; color: white; height: 100vh; padding: 25px; position: fixed; z-index: 10; }
        .sidebar h2 { color: #10b981; margin-bottom: 30px; }
        .nav-item { padding: 12px; cursor: pointer; border-radius: 8px; margin-bottom: 5px; color: #94a3b8; display: block; text-decoration: none; transition: 0.3s; }
        .nav-item.active { background: #334155; color: white; }
        .main { margin-left: 285px; padding: 40px; width: calc(100% - 285px); }
        
        .balance-card { background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 30px; border-radius: 16px; margin-bottom: 25px; box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.2); }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 20px; }
        
        .tab { display: none; } .tab.active { display: block; }
        .btn { padding: 12px; border: none; border-radius: 8px; color: white; cursor: pointer; font-weight: bold; width: 100%; transition: 0.3s; }
        input { width: 100%; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 10px; box-sizing: border-box; }
        
        .text-green { color: #10b981 !important; }
        .text-red { color: #ef4444 !important; }
        .item-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        
        /* Animation Overlays */
        .full-overlay {
            display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(255, 255, 255, 0.98); z-index: 9999;
            flex-direction: column; align-items: center; justify-content: center;
            backdrop-filter: blur(8px);
        }

        table { width: 100%; border-collapse: collapse; }
        td { padding: 12px; border-bottom: 1px solid #f1f5f9; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Pay</h2>
    <div class="nav-item active" onclick="openTab(event, 'home')">🏠 Dashboard</div>
    <div class="nav-item" onclick="openTab(event, 'pay')">💸 Pay & Request</div>
    <div class="nav-item" onclick="openTab(event, 'shop')">🛒 Marketplace</div>
    <a href="login.html" class="nav-item" style="color: #f87171; margin-top: 30px;">Logout</a>
</div>

<div class="main">
    <div id="home" class="tab active">
        <div class="balance-card">
            <small>WALLET BALANCE</small>
            <h1 style="margin: 5px 0; font-size: 42px;">$${balance != null ? balance : '0.00'}</h1>
            <p style="margin: 0; opacity: 0.8;">Roll No: ${rollNo}</p>
        </div>

        <div class="card">
            <h3>🔔 Pending Payment Requests</h3>
            <% List<Map<String, Object>> pr = (List<Map<String, Object>>)request.getAttribute("pendingRequests");
               if(pr != null && !pr.isEmpty()) { for(Map<String, Object> r : pr) { %>
                <div style="background:#fffbeb; padding:15px; border-radius:12px; border:1px solid #fcd34d; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center;">
                    <div><strong><%= r.get("from") %></strong>: $<%= r.get("amt") %><br><small>"<%= r.get("note") %>"</small></div>
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
            <h3>Recent History</h3>
            <table>
                <% List<Map<String, Object>> hist = (List<Map<String, Object>>)request.getAttribute("history");
                   if(hist != null) { for(Map<String, Object> h : hist) { 
                       boolean isCredit = (boolean)h.get("isCredit"); %>
                    <tr>
                        <td><%= h.get("desc") %></td>
                        <td align="right" class="<%= isCredit ? "text-green" : "text-red" %>" style="font-weight:bold;">
                            <%= isCredit ? "+" : "-" %>$<%= h.get("amount") %>
                        </td>
                    </tr>
                <% } } %>
            </table>
        </div>
    </div>

    <div id="pay" class="tab">
        <div class="card">
            <h3>Send Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="sendMoney">
                <input type="text" name="receiverUsername" placeholder="Recipient Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <input type="text" name="note" placeholder="Note (Optional)">
                <button type="submit" class="btn" style="background:#3b82f6;">Send Now</button>
            </form>
        </div>
        <div class="card">
            <h3>Request Money</h3>
            <form action="studentAction" method="POST">
                <input type="hidden" name="action" value="requestMoney">
                <input type="text" name="payerUsername" placeholder="Friend's Username" required>
                <input type="number" name="amount" placeholder="Amount ($)" step="0.01" required>
                <input type="text" name="note" placeholder="Reason for request">
                <button type="submit" class="btn" style="background:#8b5cf6;">Send Request</button>
            </form>
        </div>
    </div>

    <div id="shop" class="tab">
        <div class="card">
            <h2>College Store</h2>
            <div class="item-grid">
                <% List<Map<String, Object>> items = (List<Map<String, Object>>)request.getAttribute("availableItems");
                   if(items != null) { for(Map<String, Object> i : items) { 
                       int stock = (int)i.get("stock"); %>
                    <div style="border:1px solid #e2e8f0; padding:15px; border-radius:10px; display:flex; flex-direction:column; justify-content:space-between;">
                        <div>
                            <h4><%= i.get("name") %></h4>
                            <p style="font-size:12px; color:#64748b;"><%= i.get("desc") %></p>
                        </div>
                        <div style="margin-top:10px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                                <span class="text-green" style="font-weight:bold; font-size:18px;">$<%= i.get("price") %></span>
                                <span id="stock-count-<%= i.get("id") %>" style="font-size:11px; color:#94a3b8; font-weight:bold;">
                                    <%= stock == -1 ? "♾️ Unlimited" : stock + " left" %>
                                </span>
                            </div>
                            <form action="studentAction" method="POST">
                                <input type="hidden" name="action" value="buyItem">
                                <input type="hidden" name="itemId" value="<%= i.get("id") %>">
                                <input type="hidden" name="itemPrice" value="<%= i.get("price") %>">
                                <input type="hidden" name="itemName" value="<%= i.get("name") %>">
                                <button type="submit" id="buy-btn-<%= i.get("id") %>" class="btn" style="background:#f59e0b;" <%= stock == 0 ? "disabled" : "" %>>
                                    <%= stock == 0 ? "Sold Out" : "Buy Now" %>
                                </button>
                            </form>
                        </div>
                    </div>
                <% } } %>
            </div>
        </div>
    </div>
</div>

<div id="successOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_afwjhpyv.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#10b981; font-size:28px; margin-top:-20px; font-weight:800;">Payment Successful</h2>
    <button onclick="closePopups()" class="btn" style="background:#1e293b; width:180px; margin-top:30px;">Done</button>
</div>

<div id="errorOverlay" class="full-overlay">
    <lottie-player src="https://assets10.lottiefiles.com/packages/lf20_ghfp8v9f.json" background="transparent" speed="1" style="width: 300px; height: 300px;" autoplay></lottie-player>
    <h2 style="color:#ef4444; font-size:28px; margin-top:-20px; font-weight:800;">Transaction Failed</h2>
    <p id="errorTxt" style="color:#64748b;">Insufficient balance or system error.</p>
    <button onclick="closePopups()" class="btn" style="background:#ef4444; width:180px; margin-top:30px;">Try Again</button>
</div>

<audio id="successSound" src="https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3"></audio>
<audio id="errorSound" src="https://assets.mixkit.co/active_storage/sfx/951/951-preview.mp3"></audio>

<script>
    function openTab(evt, tabName) {
        var i, tab, nav;
        tab = document.getElementsByClassName("tab");
        for (i = 0; i < tab.length; i++) tab[i].style.display = "none";
        nav = document.getElementsByClassName("nav-item");
        for (i = 0; i < nav.length; i++) nav[i].className = nav[i].className.replace(" active", "");
        document.getElementById(tabName).style.display = "block";
        evt.currentTarget.className += " active";
    }

    window.onload = function() {
        const params = new URLSearchParams(window.location.search);
        if (params.has('success')) triggerSuccess();
        if (params.has('error')) triggerError(params.get('error'));
    };

    function triggerSuccess() {
        document.getElementById('successOverlay').style.display = 'flex';
        document.getElementById('successSound').play();
        if (navigator.vibrate) navigator.vibrate([100, 30, 100]);
        
        var end = Date.now() + (2 * 1000);
        (function frame() {
            confetti({ particleCount: 3, angle: 60, spread: 55, origin: { x: 0 }, colors: ['#10b981', '#3b82f6'] });
            confetti({ particleCount: 3, angle: 120, spread: 55, origin: { x: 1 }, colors: ['#10b981', '#3b82f6'] });
            if (Date.now() < end) requestAnimationFrame(frame);
        }());
    }

    function triggerError(code) {
        const overlay = document.getElementById('errorOverlay');
        if(code === 'balance') document.getElementById('errorTxt').innerText = "Insufficient wallet balance!";
        overlay.style.display = 'flex';
        document.getElementById('errorSound').play();
        if (navigator.vibrate) navigator.vibrate(400);
        overlay.animate([{ transform: 'translateX(-10px)' }, { transform: 'translateX(10px)' }, { transform: 'translateX(0)' }], { duration: 150, iterations: 3 });
    }

    function closePopups() {
        const url = new URL(window.location);
        url.searchParams.delete('success');
        url.searchParams.delete('error');
        window.history.pushState({}, '', url);
        location.reload();
    }

    // Live Stock Logic
    function updateStock() {
        fetch('getMarketStock')
            .then(response => response.text())
            .then(data => {
                const items = data.split(',');
                items.forEach(item => {
                    if (!item) return;
                    const [id, stock] = item.split(':');
                    const stockEl = document.getElementById('stock-count-' + id);
                    const btnEl = document.getElementById('buy-btn-' + id);
                    if (stockEl && btnEl) {
                        const stockNum = parseInt(stock);
                        stockEl.innerText = (stockNum === -1) ? "♾️ Unlimited" : stockNum + " left";
                        if (stockNum === 0) {
                            btnEl.disabled = true;
                            btnEl.innerText = "Sold Out";
                            btnEl.style.background = "#cbd5e0";
                        }
                    }
                });
            });
    }
    setInterval(updateStock, 5000);
</script>
</body>
</html>