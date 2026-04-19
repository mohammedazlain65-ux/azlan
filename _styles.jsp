<%-- ============================================================
     _styles.jsp  –  Shared embedded CSS for all dashboard pages.
     Include with:  <%@ include file="/WEB-INF/_styles.jsp" %>
     ============================================================ --%>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
<style>
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap');
:root {
  --navy:#0d1b2a; --navy-light:#1a2d42; --navy-mid:#162336;
  --orange:#f4701b; --orange-light:#ff8c3a; --orange-pale:#fff3ec;
  --teal:#00b4d8; --green:#06d6a0; --red:#ef476f; --yellow:#ffd166;
  --text-primary:#0d1b2a; --text-secondary:#4a5568; --text-muted:#8a9ab0;
  --border:#e2e8f0; --surface:#f8fafc; --white:#ffffff;
  --shadow-sm:0 1px 3px rgba(0,0,0,.08); --shadow-md:0 4px 16px rgba(0,0,0,.10);
  --shadow-lg:0 8px 32px rgba(0,0,0,.14); --shadow-card:0 2px 12px rgba(13,27,42,.08);
  --radius-sm:6px; --radius:12px; --radius-lg:18px;
  --font-display:'Syne',sans-serif; --font-body:'DM Sans',sans-serif;
  --sidebar-w:260px; --topbar-h:64px; --transition:0.22s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;font-size:15px}
body{font-family:var(--font-body);background:var(--surface);color:var(--text-primary);line-height:1.6;-webkit-font-smoothing:antialiased}
a{text-decoration:none;color:inherit}
img{max-width:100%;display:block}

/* ── Form Elements ─────────── */
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

/* ── Buttons ─────────────── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:11px 22px;border:none;border-radius:var(--radius-sm);font-family:var(--font-body);font-size:.92rem;font-weight:600;cursor:pointer;transition:all var(--transition);white-space:nowrap}
.btn-primary{background:var(--orange);color:var(--white)}
.btn-primary:hover{background:var(--orange-light);transform:translateY(-1px);box-shadow:0 4px 14px rgba(244,112,27,.35)}
.btn-secondary{background:var(--navy);color:var(--white)}
.btn-secondary:hover{background:var(--navy-light);transform:translateY(-1px)}
.btn-outline{background:transparent;border:1.5px solid var(--border);color:var(--text-secondary)}
.btn-outline:hover{border-color:var(--orange);color:var(--orange)}
.btn-success{background:var(--green);color:var(--navy)}
.btn-danger{background:var(--red);color:var(--white)}
.btn-sm{padding:7px 14px;font-size:.82rem}
.btn-lg{padding:14px 28px;font-size:1rem;width:100%}
.btn-icon{padding:8px;border-radius:8px}

/* ── Alerts ─────────────── */
.alert{padding:12px 16px;border-radius:var(--radius-sm);margin-bottom:18px;font-size:.9rem;display:flex;align-items:center;gap:8px}
.alert-error{background:#fef2f2;color:#c0392b;border-left:3px solid var(--red)}
.alert-success{background:#f0fdf9;color:#0a7c5a;border-left:3px solid var(--green)}
.alert-info{background:#eff8ff;color:#1e67b5;border-left:3px solid var(--teal)}

/* ── Dashboard Layout ─────── */
.app-layout{display:flex;min-height:100vh}
.sidebar{width:var(--sidebar-w);background:var(--navy);display:flex;flex-direction:column;position:fixed;top:0;left:0;height:100vh;z-index:100;transition:transform var(--transition)}
.sidebar-header{padding:20px 22px;border-bottom:1px solid rgba(255,255,255,.07);display:flex;align-items:center;gap:12px}
.sidebar-logo-icon{width:40px;height:40px;background:var(--orange);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.sidebar-brand{font-family:var(--font-display);font-size:1.1rem;font-weight:800;color:var(--white)}
.sidebar-brand span{color:var(--orange)}
.sidebar-agent-card{margin:16px 14px;padding:14px;background:rgba(255,255,255,.06);border-radius:var(--radius-sm);display:flex;align-items:center;gap:10px}
.agent-avatar{width:38px;height:38px;border-radius:50%;background:var(--orange);display:flex;align-items:center;justify-content:center;font-family:var(--font-display);font-weight:700;color:var(--white);font-size:.9rem;flex-shrink:0}
.agent-info .agent-name{font-size:.88rem;font-weight:600;color:var(--white);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.agent-info .agent-role{font-size:.74rem;color:var(--orange);text-transform:uppercase;letter-spacing:.5px}
.sidebar-nav{flex:1;padding:10px 0;overflow-y:auto}
.nav-section-label{font-size:.7rem;font-weight:700;color:rgba(255,255,255,.3);text-transform:uppercase;letter-spacing:1px;padding:12px 22px 6px}
.nav-link{display:flex;align-items:center;gap:11px;padding:10px 22px;color:rgba(255,255,255,.65);font-size:.9rem;font-weight:500;border-left:3px solid transparent;transition:all var(--transition)}
.nav-link:hover{color:var(--white);background:rgba(255,255,255,.06)}
.nav-link.active{color:var(--white);background:rgba(244,112,27,.15);border-left-color:var(--orange)}
.nav-link .nav-icon{font-size:1rem;width:18px;text-align:center}
.sidebar-footer{padding:16px 14px;border-top:1px solid rgba(255,255,255,.07)}
.logout-btn{display:flex;align-items:center;gap:10px;padding:10px 14px;color:rgba(255,255,255,.55);font-size:.88rem;border-radius:var(--radius-sm);transition:all var(--transition);cursor:pointer;width:100%;border:none;background:none}
.logout-btn:hover{color:var(--red);background:rgba(239,71,111,.1)}
.main-content{margin-left:var(--sidebar-w);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:var(--topbar-h);background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;position:sticky;top:0;z-index:50;gap:16px}
.topbar-title{font-family:var(--font-display);font-size:1.1rem;font-weight:700;color:var(--navy);flex:1}
.search-bar{display:flex;align-items:center;gap:8px;background:var(--surface);border:1.5px solid var(--border);border-radius:8px;padding:7px 14px;min-width:260px}
.search-bar input{border:none;background:none;outline:none;font-family:var(--font-body);font-size:.88rem;color:var(--text-primary);width:100%}
.notif-btn{position:relative;width:38px;height:38px;border-radius:8px;background:var(--surface);border:1.5px solid var(--border);display:flex;align-items:center;justify-content:center;cursor:pointer;color:var(--text-secondary);transition:all var(--transition)}
.notif-btn:hover{border-color:var(--orange);color:var(--orange)}
.notif-dot{position:absolute;top:6px;right:6px;width:8px;height:8px;background:var(--orange);border-radius:50%;border:2px solid var(--white)}
.page-content{padding:28px 32px;flex:1}
.page-header{margin-bottom:28px}
.page-header h2{font-family:var(--font-display);font-size:1.5rem;font-weight:700;color:var(--navy)}
.page-header p{color:var(--text-secondary);margin-top:4px}

/* ── Stats Grid ─────────────── */
.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:20px;margin-bottom:32px}
.stat-card{background:var(--white);border-radius:var(--radius);padding:22px 24px;display:flex;align-items:flex-start;gap:16px;box-shadow:var(--shadow-card);border:1px solid var(--border);position:relative;overflow:hidden;transition:transform var(--transition),box-shadow var(--transition)}
.stat-card:hover{transform:translateY(-2px);box-shadow:var(--shadow-md)}
.stat-icon{width:48px;height:48px;border-radius:var(--radius-sm);display:flex;align-items:center;justify-content:center;font-size:1.3rem;flex-shrink:0}
.stat-icon.orange{background:var(--orange-pale);color:var(--orange)}
.stat-icon.navy{background:rgba(13,27,42,.07);color:var(--navy)}
.stat-icon.green{background:rgba(6,214,160,.1);color:var(--green)}
.stat-icon.teal{background:rgba(0,180,216,.1);color:var(--teal)}
.stat-icon.red{background:rgba(239,71,111,.1);color:var(--red)}
.stat-info{flex:1;min-width:0}
.stat-label{font-size:.78rem;font-weight:600;color:var(--text-muted);text-transform:uppercase;letter-spacing:.4px}
.stat-value{font-family:var(--font-display);font-size:2rem;font-weight:800;color:var(--navy);line-height:1.1}
.stat-sub{font-size:.78rem;color:var(--green);margin-top:2px}

/* ── Cards & Tables ─────────── */
.card{background:var(--white);border-radius:var(--radius);box-shadow:var(--shadow-card);border:1px solid var(--border);overflow:hidden}
.card-header{padding:18px 22px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;gap:12px}
.card-title{font-family:var(--font-display);font-size:1rem;font-weight:700;color:var(--navy)}
.card-body{padding:22px}
.data-table-wrap{overflow-x:auto}
.data-table{width:100%;border-collapse:collapse;font-size:.88rem}
.data-table thead tr{background:var(--surface);border-bottom:2px solid var(--border)}
.data-table th{padding:11px 16px;text-align:left;font-size:.74rem;font-weight:700;color:var(--text-muted);text-transform:uppercase;letter-spacing:.5px;white-space:nowrap}
.data-table td{padding:13px 16px;border-bottom:1px solid var(--border);vertical-align:middle}
.data-table tbody tr:hover{background:var(--surface)}
.data-table tbody tr:last-child td{border-bottom:none}

/* ── Badges ─────────────────── */
.badge{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border-radius:20px;font-size:.74rem;font-weight:700;text-transform:uppercase;letter-spacing:.3px}
.badge-pending{background:#fff8e6;color:#b7791f}
.badge-accepted{background:#eff8ff;color:#1e67b5}
.badge-picked{background:#f0f4ff;color:#5b6af5}
.badge-transit{background:rgba(0,180,216,.1);color:#007ea0}
.badge-out{background:rgba(244,112,27,.1);color:var(--orange)}
.badge-delivered{background:rgba(6,214,160,.12);color:#059669}
.badge-cancelled{background:rgba(239,71,111,.1);color:#c0392b}
.pay-badge{display:inline-block;padding:3px 9px;border-radius:4px;font-size:.74rem;font-weight:700;text-transform:uppercase}
.pay-badge.cod{background:var(--orange-pale);color:var(--orange)}
.pay-badge.prepaid{background:rgba(6,214,160,.1);color:#059669}

/* ── Timeline ─────────────── */
.timeline{padding:10px 0}
.timeline-item{display:flex;gap:16px;position:relative;padding-bottom:24px}
.timeline-item:last-child{padding-bottom:0}
.timeline-item:not(:last-child)::before{content:'';position:absolute;left:15px;top:30px;width:2px;bottom:0;background:var(--border)}
.timeline-dot{width:32px;height:32px;border-radius:50%;background:var(--green);display:flex;align-items:center;justify-content:center;color:var(--white);font-size:.8rem;flex-shrink:0;z-index:1}
.timeline-dot.pending{background:var(--yellow);color:var(--navy)}
.timeline-dot.active{background:var(--orange)}
.timeline-dot.rejected{background:var(--red)}
.timeline-content{flex:1}
.timeline-status{font-weight:600;color:var(--navy)}
.timeline-meta{font-size:.8rem;color:var(--text-muted);margin-top:2px}
.timeline-remarks{font-size:.82rem;color:var(--text-secondary);margin-top:4px;padding:6px 10px;background:var(--surface);border-radius:6px;border-left:3px solid var(--border)}

/* ── Filter Bar ─────────────── */
.filter-bar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:20px}
.filter-chip{padding:6px 14px;border-radius:20px;font-size:.82rem;font-weight:600;border:1.5px solid var(--border);color:var(--text-secondary);cursor:pointer;background:var(--white);transition:all var(--transition)}
.filter-chip:hover,.filter-chip.active{border-color:var(--orange);color:var(--orange);background:var(--orange-pale)}

/* ── Modal ─────────────────── */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(13,27,42,.55);z-index:1000;align-items:center;justify-content:center}
.modal-overlay.open{display:flex}
.modal{background:var(--white);border-radius:var(--radius-lg);padding:28px;max-width:420px;width:90%;box-shadow:var(--shadow-lg)}
.modal h3{font-family:var(--font-display);color:var(--navy);margin-bottom:12px}

/* ── Misc ────────────────────── */
.hamburger{display:none;background:none;border:none;cursor:pointer;padding:8px;flex-direction:column;gap:5px}
.hamburger span{display:block;width:22px;height:2px;background:var(--navy);border-radius:2px;transition:all var(--transition)}
.divider{border:none;border-top:1px solid var(--border);margin:24px 0}
.empty-state{text-align:center;padding:60px 20px}
.empty-state .empty-icon{font-size:3rem;opacity:.25;margin-bottom:16px}
.empty-state h4{font-family:var(--font-display);color:var(--navy);margin-bottom:8px}
.empty-state p{color:var(--text-muted)}

/* ── Animations ─────────────── */
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
@keyframes slideIn{from{opacity:0;transform:translateX(-10px)}to{opacity:1;transform:translateX(0)}}
.fade-up{animation:fadeUp 0.4s ease forwards}
.stat-card{animation:fadeUp 0.4s ease forwards}
.stat-card:nth-child(1){animation-delay:.05s;opacity:0}
.stat-card:nth-child(2){animation-delay:.1s;opacity:0}
.stat-card:nth-child(3){animation-delay:.15s;opacity:0}
.stat-card:nth-child(4){animation-delay:.2s;opacity:0}

/* ── Responsive ─────────────── */
@media(max-width:768px){
  .sidebar{transform:translateX(-100%)}
  .sidebar.open{transform:translateX(0)}
  .main-content{margin-left:0}
  .hamburger{display:flex}
  .page-content{padding:20px 16px}
  .form-grid{grid-template-columns:1fr}
  .stats-grid{grid-template-columns:1fr 1fr}
}
@media(max-width:480px){
  .stats-grid{grid-template-columns:1fr}
  .topbar{padding:0 16px}
}
</style>
