<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Agent Login – LogiX</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap');
    :root {
      --navy:#0d1b2a; --navy-light:#1a2d42; --orange:#f4701b; --orange-light:#ff8c3a;
      --orange-pale:#fff3ec; --teal:#00b4d8; --green:#06d6a0; --red:#ef476f;
      --text-primary:#0d1b2a; --text-secondary:#4a5568; --text-muted:#8a9ab0;
      --border:#e2e8f0; --surface:#f8fafc; --white:#ffffff;
      --shadow-md:0 4px 16px rgba(0,0,0,.10);
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
    .auth-brand::after{content:'';position:absolute;width:300px;height:300px;background:radial-gradient(circle,rgba(0,180,216,.12) 0%,transparent 70%);bottom:-60px;left:-60px;border-radius:50%}
    .brand-logo{display:flex;align-items:center;gap:14px;margin-bottom:48px;z-index:1}
    .brand-logo .logo-icon{width:52px;height:52px;background:var(--orange);border-radius:14px;display:flex;align-items:center;justify-content:center;font-size:22px}
    .brand-logo h1{font-family:var(--font-display);font-size:1.8rem;font-weight:800;color:var(--white);letter-spacing:-.5px}
    .brand-logo span{color:var(--orange)}
    .brand-tagline{font-family:var(--font-display);font-size:2.4rem;font-weight:700;color:var(--white);line-height:1.2;text-align:center;z-index:1;margin-bottom:20px}
    .brand-tagline em{color:var(--orange);font-style:normal}
    .brand-sub{color:rgba(255,255,255,.55);text-align:center;z-index:1;max-width:340px}
    .brand-stats{display:flex;gap:32px;margin-top:48px;z-index:1}
    .brand-stat{text-align:center}
    .brand-stat .stat-num{font-family:var(--font-display);font-size:1.8rem;font-weight:800;color:var(--orange)}
    .brand-stat .stat-label{font-size:.78rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.5px}
    .auth-form-side{display:flex;flex-direction:column;justify-content:center;padding:60px 64px;overflow-y:auto}
    .auth-form-title{font-family:var(--font-display);font-size:1.9rem;font-weight:700;color:var(--navy);margin-bottom:8px}
    .auth-form-sub{color:var(--text-secondary);margin-bottom:36px}
    .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}
    .form-grid .full{grid-column:1/-1}
    .form-group{display:flex;flex-direction:column;gap:6px}
    .form-label{font-size:.83rem;font-weight:600;color:var(--text-secondary);text-transform:uppercase;letter-spacing:.4px}
    .form-input,.form-select,.form-textarea{width:100%;padding:11px 14px;border:1.5px solid var(--border);border-radius:var(--radius-sm);font-family:var(--font-body);font-size:.95rem;color:var(--text-primary);background:var(--white);transition:border-color var(--transition),box-shadow var(--transition);outline:none}
    .form-input:focus,.form-select:focus{border-color:var(--orange);box-shadow:0 0 0 3px rgba(244,112,27,.12)}
    .input-icon-wrap{position:relative}
    .input-icon-wrap .form-input{padding-left:40px}
    .input-icon-wrap .icon{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:var(--text-muted);font-size:1rem}
    .btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:11px 22px;border:none;border-radius:var(--radius-sm);font-family:var(--font-body);font-size:.92rem;font-weight:600;cursor:pointer;transition:all var(--transition);white-space:nowrap}
    .btn-primary{background:var(--orange);color:var(--white)}
    .btn-primary:hover{background:var(--orange-light);transform:translateY(-1px);box-shadow:0 4px 14px rgba(244,112,27,.35)}
    .btn-lg{padding:14px 28px;font-size:1rem;width:100%}
    .alert{padding:12px 16px;border-radius:var(--radius-sm);margin-bottom:18px;font-size:.9rem;display:flex;align-items:center;gap:8px}
    .alert-error{background:#fef2f2;color:#c0392b;border-left:3px solid var(--red)}
    .alert-success{background:#f0fdf9;color:#0a7c5a;border-left:3px solid var(--green)}
    .alert-info{background:#eff8ff;color:#1e67b5;border-left:3px solid var(--teal)}
    .divider{border:none;border-top:1px solid var(--border);margin:24px 0}
    @media(max-width:1024px){.auth-brand{display:none}.auth-page{grid-template-columns:1fr}.auth-form-side{padding:40px 32px}}
    @media(max-width:480px){.auth-form-side{padding:32px 20px}}
  </style>
</head>
<body>
<div class="auth-page">
  <div class="auth-brand">
    <div class="brand-logo">
      <div class="logo-icon">🚚</div>
      <h1>Logi<span>X</span></h1>
    </div>
    <div class="brand-tagline">Deliver <em>faster</em>,<br>track <em>smarter</em></div>
    <p class="brand-sub">A unified platform for logistics agents to manage pickups, deliveries and routes.</p>
    <div class="brand-stats">
      <div class="brand-stat"><div class="stat-num">10k+</div><div class="stat-label">Deliveries</div></div>
      <div class="brand-stat"><div class="stat-num">500+</div><div class="stat-label">Agents</div></div>
      <div class="brand-stat"><div class="stat-num">98%</div><div class="stat-label">On-Time</div></div>
    </div>
  </div>

  <div class="auth-form-side">
    <h2 class="auth-form-title">Welcome back 👋</h2>
    <p class="auth-form-sub">Sign in to your agent account to continue</p>

    <% if ("true".equals(request.getParameter("registered"))) { %>
      <div class="alert alert-success"><i class="fas fa-check-circle"></i> Registration successful! You can now log in.</div>
    <% } %>
    <% if ("true".equals(request.getParameter("logout"))) { %>
      <div class="alert alert-info"><i class="fas fa-info-circle"></i> You have been logged out successfully.</div>
    <% } %>
    <% if (request.getAttribute("error") != null) { %>
      <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> ${error}</div>
    <% } %>

    <form action="${pageContext.request.contextPath}/login" method="post" novalidate id="loginForm">
      <div class="form-grid" style="grid-template-columns:1fr;">
        <div class="form-group">
          <label class="form-label">Email Address</label>
          <div class="input-icon-wrap">
            <i class="fas fa-envelope icon"></i>
            <input type="email" name="email" class="form-input"
                   placeholder="agent@example.com" value="${email}" required autocomplete="email">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Password</label>
          <div class="input-icon-wrap">
            <i class="fas fa-lock icon"></i>
            <input type="password" name="password" id="loginPwd" class="form-input"
                   placeholder="Enter your password" required>
            <span class="icon" style="left:auto;right:13px;cursor:pointer;" onclick="togglePwd('loginPwd',this)">
              <i class="fas fa-eye"></i>
            </span>
          </div>
        </div>
        <button type="submit" class="btn btn-primary btn-lg">
          <i class="fas fa-sign-in-alt"></i> Sign In
        </button>
      </div>
    </form>

    <hr class="divider">
    <p style="text-align:center;color:var(--text-secondary);font-size:.9rem;">
      New agent? <a href="${pageContext.request.contextPath}/register.jsp" style="color:var(--orange);font-weight:600;">Create an account</a>
    </p>
  </div>
</div>
<script>
function togglePwd(id, el) {
  const inp = document.getElementById(id);
  const icon = el.querySelector('i');
  if (inp.type === 'password') { inp.type = 'text'; icon.classList.replace('fa-eye','fa-eye-slash'); }
  else { inp.type = 'password'; icon.classList.replace('fa-eye-slash','fa-eye'); }
}
</script>
</body>
</html>
