<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
    pickup-form.jsp
    No DAO / model imports needed – pure HTML form.
    Submitted to OrderServlet POST action=create.
    Error attribute set by servlet on validation failure.
--%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New Pickup Order – LogiX</title>
  <%@ include file="/WEB-INF/_styles.jsp" %>
  <style>
    .form-section{background:var(--white);border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow-card);overflow:hidden;margin-bottom:20px}
    .form-section-header{padding:14px 22px;background:var(--navy);display:flex;align-items:center;gap:10px}
    .form-section-header .sec-icon{font-size:1.2rem}
    .form-section-header h3{font-family:var(--font-display);font-size:1rem;font-weight:700;color:var(--white)}
    .form-section-body{padding:22px}
    .charge-calc{background:var(--orange-pale);border-radius:8px;padding:14px;border:1px solid rgba(244,112,27,.2);display:flex;align-items:center;justify-content:space-between}
    .charge-result{font-family:var(--font-display);font-size:1.4rem;font-weight:800;color:var(--orange)}
  </style>
</head>
<body>
<div class="app-layout">
  <%@ include file="/WEB-INF/sidebar.jsp" %>
  <div class="main-content">
    <header class="topbar">
      <button class="hamburger" onclick="toggleSidebar()"><span></span><span></span><span></span></button>
      <div class="topbar-title">Create Pickup Order</div>
      <a href="${pageContext.request.contextPath}/orders?action=pickup" class="btn btn-outline btn-sm">
        <i class="fas fa-arrow-left"></i> Back
      </a>
    </header>
    <main class="page-content">
      <div class="page-header">
        <h2>New Pickup Order</h2>
        <p>Fill in seller and customer details to create a delivery request.</p>
      </div>

      <% if (request.getAttribute("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> ${error}</div>
      <% } %>

      <form action="${pageContext.request.contextPath}/orders" method="post" id="pickupForm" novalidate>
        <input type="hidden" name="action" value="create">

        <!-- Seller Info -->
        <div class="form-section">
          <div class="form-section-header"><span class="sec-icon">🏪</span><h3>Seller Information</h3></div>
          <div class="form-section-body">
            <div class="form-grid">
              <div class="form-group">
                <label class="form-label">Seller Name *</label>
                <input type="text" name="sellerName" class="form-input" placeholder="Store / Seller name" required>
              </div>
              <div class="form-group">
                <label class="form-label">Seller Contact *</label>
                <input type="tel" name="sellerContact" class="form-input" placeholder="10-digit mobile" required pattern="[6-9][0-9]{9}">
              </div>
              <div class="form-group full">
                <label class="form-label">Seller Address *</label>
                <textarea name="sellerAddress" class="form-textarea" placeholder="Full pickup address with landmark" required></textarea>
              </div>
            </div>
          </div>
        </div>

        <!-- Customer Info -->
        <div class="form-section">
          <div class="form-section-header"><span class="sec-icon">🏠</span><h3>Customer / Delivery Information</h3></div>
          <div class="form-section-body">
            <div class="form-grid">
              <div class="form-group">
                <label class="form-label">Customer Name *</label>
                <input type="text" name="customerName" class="form-input" placeholder="Recipient name" required>
              </div>
              <div class="form-group">
                <label class="form-label">Customer Contact *</label>
                <input type="tel" name="customerContact" class="form-input" placeholder="10-digit mobile" required pattern="[6-9][0-9]{9}">
              </div>
              <div class="form-group full">
                <label class="form-label">Delivery Address *</label>
                <textarea name="customerAddress" class="form-textarea" placeholder="Full delivery address with flat no., building, landmark" required></textarea>
              </div>
            </div>
          </div>
        </div>

        <!-- Product Info -->
        <div class="form-section">
          <div class="form-section-header"><span class="sec-icon">📦</span><h3>Product & Delivery Details</h3></div>
          <div class="form-section-body">
            <div class="form-grid">
              <div class="form-group full">
                <label class="form-label">Product Description *</label>
                <textarea name="productDescription" class="form-textarea" placeholder="e.g. Laptop – Dell Inspiron 15, Qty: 1" required></textarea>
              </div>
              <div class="form-group">
                <label class="form-label">Weight (kg) *</label>
                <input type="number" name="weight" id="weight" class="form-input" placeholder="0.00" step="0.1" min="0.1" max="1000" required oninput="calcCharges()">
              </div>
              <div class="form-group">
                <label class="form-label">Payment Type *</label>
                <select name="paymentType" class="form-select" required>
                  <option value="">Select...</option>
                  <option value="COD">COD (Cash on Delivery)</option>
                  <option value="Prepaid">Prepaid</option>
                </select>
              </div>
              <div class="form-group">
                <label class="form-label">Pickup Date *</label>
                <input type="date" name="pickupDate" id="pickupDate" class="form-input" required>
              </div>
              <div class="form-group">
                <label class="form-label">Expected Delivery Date *</label>
                <input type="date" name="expectedDelivery" id="expectedDelivery" class="form-input" required>
              </div>
              <div class="form-group">
                <label class="form-label">Delivery Charges (₹) *</label>
                <div class="input-icon-wrap">
                  <span class="icon" style="font-size:.9rem;color:var(--text-muted);">₹</span>
                  <input type="number" name="deliveryCharges" id="deliveryCharges" class="form-input" placeholder="0.00" step="0.5" min="0" required>
                </div>
              </div>
              <div class="form-group full">
                <label class="form-label">Special Instructions (Optional)</label>
                <textarea name="specialInstructions" class="form-textarea" placeholder="Handle with care, do not tilt, call before delivery..."></textarea>
              </div>
              <div class="full">
                <div class="charge-calc" id="chargeSuggestion" style="display:none;">
                  <div>
                    <div style="font-size:.8rem;font-weight:600;color:var(--text-secondary);">Suggested charge based on weight</div>
                    <div style="font-size:.75rem;color:var(--text-muted);">Base ₹50 + ₹20/kg</div>
                  </div>
                  <div class="charge-result" id="suggestedCharge">₹0</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div style="display:flex;gap:12px;justify-content:flex-end;">
          <a href="${pageContext.request.contextPath}/orders?action=pickup" class="btn btn-outline">Cancel</a>
          <button type="submit" class="btn btn-primary"><i class="fas fa-paper-plane"></i> Create Order</button>
        </div>
      </form>
    </main>
  </div>
</div>
<script>
function toggleSidebar(){document.getElementById('sidebar').classList.toggle('open');}
// Set today as min for pickup date
(function(){
  const today=new Date().toISOString().split('T')[0];
  document.getElementById('pickupDate').min=today;
  const tomorrow=new Date();tomorrow.setDate(tomorrow.getDate()+1);
  document.getElementById('expectedDelivery').min=tomorrow.toISOString().split('T')[0];
})();
function calcCharges(){
  const wt=parseFloat(document.getElementById('weight').value)||0;
  const sug=document.getElementById('chargeSuggestion');
  if(wt>0){
    const calc=50+(wt*20);
    document.getElementById('suggestedCharge').textContent='₹'+calc.toFixed(2);
    document.getElementById('deliveryCharges').value=calc.toFixed(2);
    sug.style.display='flex';
  }else{sug.style.display='none';}
}
document.getElementById('pickupDate').addEventListener('change',function(){
  const ed=document.getElementById('expectedDelivery');
  if(this.value){
    const next=new Date(this.value);next.setDate(next.getDate()+1);
    ed.min=next.toISOString().split('T')[0];
    if(ed.value&&ed.value<=this.value)ed.value='';
  }
});
document.getElementById('pickupForm').addEventListener('submit',function(e){
  const pd=document.getElementById('pickupDate').value;
  const ed=document.getElementById('expectedDelivery').value;
  if(pd&&ed&&ed<pd){e.preventDefault();alert('Expected delivery date must be after pickup date.');}
});
</script>
</body>
</html>
