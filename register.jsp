<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Register Agent – LogiX</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap');
    :root {
      --navy:#0d1b2a; --navy-light:#1a2d42; --orange:#f4701b; --orange-light:#ff8c3a;
      --orange-pale:#fff3ec; --green:#06d6a0; --red:#ef476f;
      --text-primary:#0d1b2a; --text-secondary:#4a5568; --text-muted:#8a9ab0;
      --border:#e2e8f0; --surface:#f8fafc; --white:#ffffff;
      --radius-sm:6px; --radius:12px;
      --font-display:'Syne',sans-serif; --font-body:'DM Sans',sans-serif;
      --transition:0.22s ease;
    }
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    body{font-family:var(--font-body);background:var(--surface);color:var(--text-primary);line-height:1.6;-webkit-font-smoothing:antialiased}
    a{text-decoration:none;color:inherit}
    .auth-page{min-height:100vh;display:grid;grid-template-columns:1fr 1fr;background:var(--white)}
    .auth-brand{background:var(--navy);display:flex;flex-direction:column;justify-content:center;align-items:center;padding:60px 50px;position:relative;overflow:hidden}
    .auth-brand::before{content:'';position:absolute;width:400px;height:400px;background:radial-gradient(circle,rgba(244,112,27,.18) 0%,transparent 70%);top:-80px;right:-80px;border-radius:50%}
    .brand-logo{display:flex;align-items:center;gap:14px;margin-bottom:48px;z-index:1}
    .brand-logo .logo-icon{width:52px;height:52px;background:var(--orange);border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:22px}
    .brand-logo h1{font-family:var(--font-display);font-size:1.8rem;font-weight:800;color:var(--white)}
    .brand-logo span{color:var(--orange)}
    .brand-tagline{font-family:var(--font-display);font-size:2.4rem;font-weight:700;color:var(--white);line-height:1.2;text-align:center;z-index:1;margin-bottom:20px}
    .brand-tagline em{color:var(--orange);font-style:normal}
    .brand-sub{color:rgba(255,255,255,.55);text-align:center;z-index:1;max-width:340px}
    .brand-stats{display:flex;gap:32px;margin-top:48px;z-index:1}
    .brand-stat{text-align:center}
    .brand-stat .stat-num{font-family:var(--font-display);font-size:1.8rem;font-weight:800;color:var(--orange)}
    .brand-stat .stat-label{font-size:.78rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.5px}
    .auth-form-side{display:flex;flex-direction:column;justify-content:center;padding:40px 60px;overflow-y:auto}
    .auth-form-title{font-family:var(--font-display);font-size:1.9rem;font-weight:700;color:var(--navy);margin-bottom:8px}
    .auth-form-sub{color:var(--text-secondary);margin-bottom:36px}
    .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}
    .form-grid .full{grid-column:1/-1}
    .form-group{display:flex;flex-direction:column;gap:6px}
    .form-label{font-size:.83rem;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:.4px}
    .form-input,.form-select,.form-textarea{width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:var(--radius-sm);font-family:var(--font-body);font-size:.95rem;color:var(--text-primary);background:var(--white);transition:border-color var(--transition),box-shadow var(--transition);outline:none}
    .form-input:focus,.form-select:focus,.form-textarea:focus{border-color:var(--orange);box-shadow:0 0 0 3px rgba(244,112,27,.12)}
    .form-textarea{resize:vertical;min-height:80px}
    .input-icon-wrap{position:relative}
    .input-icon-wrap .form-input{padding-left:40px}
    .input-icon-wrap .icon{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:var(--text-muted);font-size:1rem}
    .btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:11px 22px;border:none;border-radius:var(--radius-sm);font-family:var(--font-body);font-size:.92rem;font-weight:600;cursor:pointer;transition:all var(--transition);white-space:nowrap}
    .btn-primary{background:var(--orange);color:var(--white)}
    .btn-primary:hover{background:var(--orange-light);transform:translateY(-1px)}
    .btn-lg{padding:14px 28px;font-size:1rem;width:100%}
    .alert{padding:12px 16px;border-radius:var(--radius-sm);margin-bottom:18px;font-size:.9rem;display:flex;align-items:center;gap:8px}
    .alert-error{background:#fef2f2;color:#c0392b;border-left:3px solid var(--red)}
    .file-upload-box{border:2px dashed var(--border);border-radius:var(--radius-sm);padding:18px;text-align:center;cursor:pointer;transition:border-color var(--transition)}
    .file-upload-box:hover{border-color:var(--orange)}
    .file-upload-box input{display:none}
    .file-upload-box .up-icon{font-size:1.6rem;color:var(--text-muted);margin-bottom:6px}
    .file-upload-box p{font-size:.82rem;color:var(--text-muted)}
    .file-name{font-size:.82rem;color:var(--orange);margin-top:6px}
    .vehicle-cards{display:flex;gap:10px}
    .vehicle-card{flex:1;border:2px solid var(--border);border-radius:var(--radius-sm);padding:12px;text-align:center;cursor:pointer;transition:all var(--transition);font-size:.85rem}
    .vehicle-card:hover,.vehicle-card.selected{border-color:var(--orange);background:var(--orange-pale);color:var(--orange)}
    .vehicle-card .vc-icon{font-size:1.5rem;display:block;margin-bottom:4px}
    @media(max-width:1024px){.auth-brand{display:none}.auth-page{grid-template-columns:1fr}.auth-form-side{padding:40px 32px}}
    @media(max-width:768px){.form-grid{grid-template-columns:1fr}.auth-form-side{padding:32px 20px}}
  </style>
</head>
<body>
<div class="auth-page">
  <div class="auth-brand">
    <div class="brand-logo">
      <div class="logo-icon">🚚</div>
      <h1>Logi<span>X</span></h1>
    </div>
    <div class="brand-tagline">Join our <em>delivery</em><br>network today</div>
    <p class="brand-sub">Register as a logistics agent and start earning by delivering orders in your area.</p>
    <div class="brand-stats">
      <div class="brand-stat"><div class="stat-num">₹800+</div><div class="stat-label">Daily Avg</div></div>
      <div class="brand-stat"><div class="stat-num">Flex</div><div class="stat-label">Hours</div></div>
      <div class="brand-stat"><div class="stat-num">Fast</div><div class="stat-label">Payouts</div></div>
    </div>
  </div>

  <div class="auth-form-side">
    <h2 class="auth-form-title">Create Agent Account</h2>
    <p class="auth-form-sub">Fill in your details to get started</p>

    <% if (request.getAttribute("error") != null) { %>
      <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> ${error}</div>
    <% } %>

    <form action="${pageContext.request.contextPath}/register" method="post"
          enctype="multipart/form-data" novalidate id="regForm">
      <div class="form-grid">
        <div class="form-group">
          <label class="form-label">Full Name *</label>
          <input type="text" name="fullName" class="form-input" placeholder="Rajesh Kumar" value="${v_fullName}" required>
        </div>
        <div class="form-group">
          <label class="form-label">Email Address *</label>
          <input type="email" name="email" class="form-input" placeholder="agent@example.com" value="${v_email}" required>
        </div>
        <div class="form-group">
          <label class="form-label">Phone Number *</label>
          <input type="tel" name="phone" class="form-input" placeholder="9XXXXXXXXX" value="${v_phone}" required pattern="[6-9][0-9]{9}">
        </div>
        <div class="form-group">
          <label class="form-label">City *</label>
          <input type="text" name="city" class="form-input" placeholder="Mumbai" value="${v_city}" required>
        </div>
        <div class="form-group full">
          <label class="form-label">Address *</label>
          <textarea name="address" class="form-textarea" placeholder="Street, Area, Landmark" required>${v_address}</textarea>
        </div>
        <div class="form-group full">
          <label class="form-label">Vehicle Type *</label>
          <div class="vehicle-cards" id="vehicleCards">
            <div class="vehicle-card ${v_vehicleType == 'Bike' ? 'selected' : ''}" onclick="selectVehicle('Bike',this)">
              <span class="vc-icon">🏍️</span> Bike
            </div>
            <div class="vehicle-card ${v_vehicleType == 'Van' ? 'selected' : ''}" onclick="selectVehicle('Van',this)">
              <span class="vc-icon">🚐</span> Van
            </div>
            <div class="vehicle-card ${v_vehicleType == 'Truck' ? 'selected' : ''}" onclick="selectVehicle('Truck',this)">
              <span class="vc-icon">🚛</span> Truck
            </div>
          </div>
          <input type="hidden" name="vehicleType" id="vehicleType" value="${v_vehicleType}" required>
        </div>
        <div class="form-group full">
          <label class="form-label">Driving License Number *</label>
          <input type="text" name="licenseNumber" class="form-input" placeholder="MH-1234567" value="${v_licenseNumber}" required>
        </div>
        <div class="form-group">
          <label class="form-label">Password *</label>
          <div class="input-icon-wrap">
            <i class="fas fa-lock icon"></i>
            <input type="password" name="password" id="pwd" class="form-input" placeholder="Min 8 characters" required minlength="8">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Confirm Password *</label>
          <div class="input-icon-wrap">
            <i class="fas fa-lock icon"></i>
            <input type="password" name="confirmPassword" id="cpwd" class="form-input" placeholder="Repeat password" required>
          </div>
        </div>
        <div class="form-group full">
          <label class="form-label">ID Proof (Optional)</label>
          <div class="file-upload-box" onclick="document.getElementById('idProof').click()">
            <div class="up-icon">📎</div>
            <p>Click to upload Aadhar / PAN / License</p>
            <p>JPG, PNG or PDF – max 5MB</p>
            <div class="file-name" id="fileName">No file selected</div>
            <input type="file" name="idProof" id="idProof" accept="image/*,.pdf" onchange="showFileName(this)">
          </div>
        </div>
        <div class="form-group full">
          <button type="submit" class="btn btn-primary btn-lg" id="submitBtn">
            <i class="fas fa-user-plus"></i> Create Account
          </button>
        </div>
      </div>
    </form>

    <p style="text-align:center;margin-top:20px;color:var(--text-secondary);font-size:.9rem;">
      Already registered? <a href="${pageContext.request.contextPath}/login.jsp" style="color:var(--orange);font-weight:600;">Sign in</a>
    </p>
  </div>
</div>
<script>
function selectVehicle(type, el) {
  document.querySelectorAll('.vehicle-card').forEach(c => c.classList.remove('selected'));
  el.classList.add('selected');
  document.getElementById('vehicleType').value = type;
}
function showFileName(input) {
  document.getElementById('fileName').textContent = input.files[0] ? input.files[0].name : 'No file selected';
}
document.getElementById('regForm').addEventListener('submit', function(e) {
  if (document.getElementById('pwd').value !== document.getElementById('cpwd').value) {
    e.preventDefault(); alert('Passwords do not match!'); return;
  }
  if (!document.getElementById('vehicleType').value) {
    e.preventDefault(); alert('Please select a vehicle type.');
  }
});
</script>
</body>
</html>
