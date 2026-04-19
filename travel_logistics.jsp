<%@ page import="java.sql.Statement" %>
<%@ page import="java.sql.Types" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ page import="java.sql.*,java.util.*" %>
<%!
/* ================================================================
   DB CONFIG
================================================================ */
private static final String DB_URL  = "jdbc:mysql://localhost:3306/multi_vendor?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
private static final String DB_USER = "root";
private static final String DB_PASS = "";
private Connection getConn() throws Exception { Class.forName("com.mysql.jdbc.Driver"); return DriverManager.getConnection(DB_URL,DB_USER,DB_PASS); }
private void close(Connection c,PreparedStatement p,ResultSet r){try{if(r!=null)r.close();}catch(Exception e){}try{if(p!=null)p.close();}catch(Exception e){}try{if(c!=null)c.close();}catch(Exception e){}}

/* ================================================================
   DATA MODELS
================================================================ */
public static class OrderRow{ public int id,total_items; public String order_id,source,customer_email,full_name,phone,shipping_address,city,state,pincode,payment_method,order_status,order_notes,order_date,updated_at; public double subtotal,tax_amount,grand_total; }
public static class Shipment{ public int shipment_id; public String order_id,tracking_number,product_name,customer_name,customer_phone,delivery_address,dispatch_date,dispatch_time,expected_delivery,actual_delivery,agent_id,agent_name,transport_mode,shipment_status,notes,seller_source; }
public static class ReturnReq{ public int return_id,product_id; public String order_id,customer_email,seller_email,return_reason,return_description,return_status,created_at,updated_at; }
public static class TrackEvt{ public int track_id; public String tracking_number,event_status,event_location,event_datetime,event_description; }
public static class Agent{ public String agent_id,agent_name,vehicle_type,agent_status,phone,zone,email; public int total_deliveries,completed_deliveries; }
public static class OItem{ public int item_id,product_id,quantity; public String product_name,seller_email; public double price,total; }

/* ================================================================
   HELPERS
================================================================ */
public String safe(String s){return s==null?"":s.replace("<","&lt;").replace(">","&gt;");}
public String raw(String s){return s==null?"":s;}
public String genTrk(String date){String d=(date!=null)?date.replace("-",""):"20260309";return "MH-TRK-"+d+"-"+(int)(Math.random()*900+100)+"-"+(System.currentTimeMillis()%1000);}
public int countStatus(List<OrderRow> list,String st){int n=0;for(OrderRow o:list)if(st.equals(o.order_status))n++;return n;}
public void ensureAgentCols(Connection c){String[]s={"ALTER TABLE delivery_agents ADD COLUMN email VARCHAR(150) DEFAULT NULL","ALTER TABLE delivery_agents ADD COLUMN password VARCHAR(255) DEFAULT NULL","ALTER TABLE delivery_agents ADD COLUMN license_no VARCHAR(60) DEFAULT NULL","ALTER TABLE delivery_agents MODIFY COLUMN agent_status ENUM('Active','Inactive','On Leave','Pending') DEFAULT 'Pending'"};for(String q:s){try{c.createStatement().executeUpdate(q);}catch(Exception ig){}}}

/* Fetch helpers */
public List<OrderRow> fetchOrders(String whereClause,String[] params) throws Exception{
    List<OrderRow>list=new ArrayList<OrderRow>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();p=c.prepareStatement("SELECT * FROM orders "+whereClause+" ORDER BY order_date DESC");
    for(int i=0;i<params.length;i++)p.setString(i+1,params[i]);r=p.executeQuery();
    while(r.next()){OrderRow o=new OrderRow();o.id=r.getInt("id");o.order_id=r.getString("order_id");o.source=r.getString("source");o.customer_email=r.getString("customer_email");o.full_name=r.getString("full_name");o.phone=r.getString("phone");o.shipping_address=r.getString("shipping_address");o.city=r.getString("city");o.state=r.getString("state");o.pincode=r.getString("pincode");o.payment_method=r.getString("payment_method");o.order_status=r.getString("order_status");o.order_notes=r.getString("order_notes");o.subtotal=r.getDouble("subtotal");o.tax_amount=r.getDouble("tax_amount");o.grand_total=r.getDouble("grand_total");o.total_items=r.getInt("total_items");o.order_date=r.getString("order_date");o.updated_at=r.getString("updated_at");list.add(o);}
    }finally{close(c,p,r);}return list;}

public List<Shipment> fetchShipments(String whereClause,String[]params)throws Exception{
    List<Shipment>list=new ArrayList<Shipment>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();p=c.prepareStatement("SELECT s.*,da.agent_name FROM shipments s LEFT JOIN delivery_agents da ON s.agent_id=da.agent_id "+whereClause+" ORDER BY s.dispatch_date DESC");
    for(int i=0;i<params.length;i++)p.setString(i+1,params[i]);r=p.executeQuery();
    while(r.next()){Shipment s=new Shipment();s.shipment_id=r.getInt("shipment_id");s.order_id=r.getString("order_id");s.tracking_number=r.getString("tracking_number");s.product_name=r.getString("product_name");s.customer_name=r.getString("customer_name");s.customer_phone=r.getString("customer_phone");s.delivery_address=r.getString("delivery_address");s.dispatch_date=r.getString("dispatch_date");s.dispatch_time=r.getString("dispatch_time");s.expected_delivery=r.getString("expected_delivery");s.actual_delivery=r.getString("actual_delivery");s.agent_id=r.getString("agent_id");s.agent_name=r.getString("agent_name");s.transport_mode=r.getString("transport_mode");s.shipment_status=r.getString("shipment_status");s.notes=r.getString("notes");try{s.seller_source=r.getString("seller_source");}catch(Exception ig){s.seller_source="manual";}if(s.seller_source==null||s.seller_source.isEmpty())s.seller_source="manual";list.add(s);}
    }finally{close(c,p,r);}return list;}

public Shipment getShipmentByOrder(String oid)throws Exception{
    List<Shipment>list=fetchShipments("WHERE s.order_id=?",new String[]{oid});return list.isEmpty()?null:list.get(0);}

public List<ReturnReq>fetchReturns(String where,String[]params)throws Exception{
    List<ReturnReq>list=new ArrayList<ReturnReq>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();p=c.prepareStatement("SELECT * FROM return_requests "+where+" ORDER BY created_at DESC");
    for(int i=0;i<params.length;i++)p.setString(i+1,params[i]);r=p.executeQuery();
    while(r.next()){ReturnReq rq=new ReturnReq();rq.return_id=r.getInt("return_id");rq.order_id=r.getString("order_id");rq.product_id=r.getInt("product_id");rq.customer_email=r.getString("customer_email");rq.seller_email=r.getString("seller_email");rq.return_reason=r.getString("return_reason");rq.return_description=r.getString("return_description");rq.return_status=r.getString("return_status");rq.created_at=r.getString("created_at");rq.updated_at=r.getString("updated_at");list.add(rq);}
    }finally{close(c,p,r);}return list;}

public List<TrackEvt>getTrackEvents(String trk)throws Exception{
    List<TrackEvt>list=new ArrayList<TrackEvt>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();p=c.prepareStatement("SELECT * FROM order_tracking WHERE tracking_number=? ORDER BY event_datetime ASC");p.setString(1,trk);r=p.executeQuery();
    while(r.next()){TrackEvt t=new TrackEvt();t.track_id=r.getInt("track_id");t.tracking_number=r.getString("tracking_number");t.event_status=r.getString("event_status");t.event_location=r.getString("event_location");t.event_datetime=r.getString("event_datetime");t.event_description=r.getString("event_description");list.add(t);}
    }finally{close(c,p,r);}return list;}

public List<Agent>getAgents(boolean onlyActive)throws Exception{
    List<Agent>list=new ArrayList<Agent>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();String sql=onlyActive?"SELECT * FROM delivery_agents WHERE agent_status IN ('Active','On Leave') ORDER BY agent_id":"SELECT * FROM delivery_agents ORDER BY agent_id";p=c.prepareStatement(sql);r=p.executeQuery();
    while(r.next()){Agent a=new Agent();a.agent_id=r.getString("agent_id");a.agent_name=r.getString("agent_name");a.vehicle_type=r.getString("vehicle_type");a.agent_status=r.getString("agent_status");a.phone=r.getString("phone");a.zone=r.getString("zone");a.total_deliveries=r.getInt("total_deliveries");a.completed_deliveries=r.getInt("completed_deliveries");try{a.email=r.getString("email");}catch(Exception ig){a.email="";}list.add(a);}
    }finally{close(c,p,r);}return list;}

public List<OItem>getItems(String oid)throws Exception{
    List<OItem>list=new ArrayList<OItem>();Connection c=null;PreparedStatement p=null;ResultSet r=null;
    try{c=getConn();p=c.prepareStatement("SELECT oi.*,COALESCE(pr.name,oi.product_name,'Product') pname,COALESCE(pr.seller_email,'') smail FROM order_items oi LEFT JOIN products pr ON oi.product_id=pr.id WHERE oi.order_id=?");p.setString(1,oid);r=p.executeQuery();
    while(r.next()){OItem i=new OItem();i.item_id=r.getInt("id");i.product_id=r.getInt("product_id");i.quantity=r.getInt("quantity");try{i.price=r.getDouble("unit_price");}catch(Exception ig){try{i.price=r.getDouble("price");}catch(Exception ig2){}}try{i.total=r.getDouble("item_total");}catch(Exception ig){try{i.total=r.getDouble("total");}catch(Exception ig2){}}try{i.product_name=r.getString("pname");}catch(Exception ig){i.product_name="Product";}try{i.seller_email=r.getString("smail");}catch(Exception ig){i.seller_email="";}list.add(i);}
    }catch(Exception e){}finally{close(c,p,r);}return list;}
%>
<%
/* ================================================================
   SESSION / ROLE DETECTION
================================================================ */
String sessionEmail  = null;
String sessionRole   = "guest";
String agentId       = null;
String agentName     = null;

try { Object o=session.getAttribute("email"); if(o!=null) sessionEmail=o.toString().trim(); } catch(Exception ig){}
try { Object o=session.getAttribute("role");  if(o!=null) sessionRole=o.toString().trim().toLowerCase(); } catch(Exception ig){}
try { Object o=session.getAttribute("agent_id"); if(o!=null) agentId=o.toString().trim(); } catch(Exception ig){}
try { Object o=session.getAttribute("agent_name"); if(o!=null) agentName=o.toString().trim(); } catch(Exception ig){}

// Query-param fallback for testing
String vA=request.getParameter("viewAs"); if(vA!=null&&!vA.isEmpty()) sessionRole=vA.toLowerCase();
String eP=request.getParameter("email");  if(eP!=null&&!eP.isEmpty()) sessionEmail=eP.trim();

boolean isAdmin    = "admin".equals(sessionRole);
boolean isSeller   = "seller".equals(sessionRole);
boolean isAgent    = "agent".equals(sessionRole);
boolean isCustomer = "customer".equals(sessionRole)||"user".equals(sessionRole);
boolean isLoggedIn = sessionEmail!=null&&!sessionEmail.isEmpty();

/* ================================================================
   ACTION HANDLER
================================================================ */
String action="", actionMsg=""; boolean actionOk=false;
action = request.getParameter("action"); if(action==null) action="";

/* ---- ADMIN: Approve / Reject Agent ---- */
if ("agentApprove".equals(action) && isAdmin) {
    String aid=request.getParameter("a_agent_id"); String nst=request.getParameter("a_new_status");
    String[]allowed={"Active","Inactive","Pending","On Leave"};boolean valid=false;
    for(String s:allowed)if(s.equals(nst)){valid=true;break;}
    if(aid!=null&&!aid.trim().isEmpty()&&valid){
        Connection c=null;PreparedStatement p=null;
        try{c=getConn();ensureAgentCols(c);p=c.prepareStatement("UPDATE delivery_agents SET agent_status=? WHERE agent_id=?");p.setString(1,nst);p.setString(2,aid.trim());int rows=p.executeUpdate();actionMsg=rows>0?"✅ Agent "+aid+" status updated to "+nst:"⚠ Update failed.";actionOk=rows>0;}
        catch(Exception e){actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
    }
}

/* ---- SELLER: Confirm Order ---- */
else if ("confirmOrder".equals(action) && isSeller) {
    String oid=request.getParameter("o_order_id");
    if(oid!=null&&!oid.trim().isEmpty()){
        Connection c=null;PreparedStatement p=null;
        try{c=getConn();p=c.prepareStatement("UPDATE orders SET order_status='Confirmed',updated_at=NOW() WHERE order_id=? AND order_status='Pending'");p.setString(1,oid.trim());int rows=p.executeUpdate();
        if(rows>0){PreparedStatement p2=c.prepareStatement("INSERT INTO order_status_log (order_id,old_status,new_status,changed_by,remarks,changed_at) VALUES (?,'Pending','Confirmed',?,?,NOW())");p2.setString(1,oid.trim());p2.setString(2,sessionEmail);p2.setString(3,"Seller confirmed order");p2.executeUpdate();p2.close();actionMsg="✅ Order "+oid+" confirmed successfully!";actionOk=true;}
        else{actionMsg="⚠ Order not found or already processed.";}}
        catch(Exception e){actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
    }
}

/* ---- SELLER/ADMIN: Confirm/Reject Return Request ---- */
else if ("updateReturnStatus".equals(action) && (isSeller||isAdmin)) {
    String rid=request.getParameter("r_return_id"); String nst=request.getParameter("r_new_status");
    String[]ok2={"Pending","Approved","Rejected","Completed"};boolean v2=false;for(String s:ok2)if(s.equals(nst)){v2=true;break;}
    int rid_int=-1;try{rid_int=Integer.parseInt(rid);}catch(Exception e){}
    if(rid_int>0&&v2){
        Connection c=null;PreparedStatement p=null;
        try{c=getConn();String sql=isAdmin?"UPDATE return_requests SET return_status=?,updated_at=NOW() WHERE return_id=?":"UPDATE return_requests SET return_status=?,updated_at=NOW() WHERE return_id=? AND seller_email=?";p=c.prepareStatement(sql);p.setString(1,nst);p.setInt(2,rid_int);if(!isAdmin)p.setString(3,sessionEmail);int rows=p.executeUpdate();actionMsg=rows>0?"✅ Return #"+rid_int+" updated to "+nst:"⚠ Update failed.";actionOk=rows>0;}
        catch(Exception e){actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
    }
}

/* ---- CUSTOMER: Submit Return Request ---- */
else if ("submitReturn".equals(action) && isLoggedIn && isCustomer) {
    String r_oid=request.getParameter("r_order_id");String r_pid=request.getParameter("r_product_id");String r_sem=request.getParameter("r_seller_email");String r_rea=request.getParameter("r_reason");String r_des=request.getParameter("r_description");
    if(r_oid==null||r_oid.trim().isEmpty()||r_pid==null||r_pid.trim().isEmpty()||r_rea==null||r_rea.trim().isEmpty()){actionMsg="⚠ Please fill in all required fields.";}
    else{int pid=-1;try{pid=Integer.parseInt(r_pid.trim());}catch(Exception e){}
    if(pid<=0){actionMsg="⚠ Invalid product ID.";}
    else{Connection c=null;PreparedStatement p=null;ResultSet rs=null;
    try{c=getConn();p=c.prepareStatement("SELECT order_status FROM orders WHERE order_id=? AND customer_email=?");p.setString(1,r_oid.trim());p.setString(2,sessionEmail);rs=p.executeQuery();
    if(!rs.next()){actionMsg="⚠ Order not found or access denied.";}
    else if(!"Delivered".equalsIgnoreCase(rs.getString("order_status"))){actionMsg="⚠ Returns only allowed for Delivered orders.";}
    else{rs.close();p.close();p=c.prepareStatement("SELECT return_id FROM return_requests WHERE order_id=? AND product_id=? AND customer_email=?");p.setString(1,r_oid.trim());p.setInt(2,pid);p.setString(3,sessionEmail);rs=p.executeQuery();
    if(rs.next()){actionMsg="⚠ Return request already exists for this item.";}
    else{rs.close();p.close();p=c.prepareStatement("INSERT INTO return_requests (order_id,product_id,customer_email,seller_email,return_reason,return_description,return_status) VALUES (?,?,?,?,?,?,'Pending')");p.setString(1,r_oid.trim());p.setInt(2,pid);p.setString(3,sessionEmail);p.setString(4,(r_sem!=null&&!r_sem.trim().isEmpty())?r_sem.trim():null);p.setString(5,r_rea.trim());p.setString(6,(r_des!=null&&!r_des.trim().isEmpty())?r_des.trim():null);int rows=p.executeUpdate();actionMsg=rows>0?"✅ Return submitted! Seller will review within 2-3 days.":"❌ Failed.";actionOk=rows>0;}}
    }catch(Exception e){actionMsg="❌ "+e.getMessage();}finally{close(c,p,rs);}}}}

/* ---- CUSTOMER: Cancel Return ---- */
else if ("cancelReturn".equals(action) && isLoggedIn && isCustomer) {
    String rid=request.getParameter("r_return_id");int rid_int=-1;try{rid_int=Integer.parseInt(rid);}catch(Exception e){}
    if(rid_int>0){Connection c=null;PreparedStatement p=null;try{c=getConn();p=c.prepareStatement("DELETE FROM return_requests WHERE return_id=? AND customer_email=? AND return_status='Pending'");p.setInt(1,rid_int);p.setString(2,sessionEmail);int rows=p.executeUpdate();actionMsg=rows>0?"✅ Return request cancelled.":"⚠ Cannot cancel. May already be processed.";actionOk=rows>0;}catch(Exception e){actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}}
}

/* ---- AGENT: Mark Delivered ---- */
else if ("agentDelivered".equals(action) && isAgent && agentId!=null) {
    String oid=request.getParameter("o_order_id");
    if(oid!=null&&!oid.trim().isEmpty()){
        Connection c=null;PreparedStatement p=null;
        try{c=getConn();c.setAutoCommit(false);
        // Only update if assigned to this agent
        p=c.prepareStatement("UPDATE shipments SET shipment_status='delivered',actual_delivery=CURDATE(),updated_at=NOW() WHERE order_id=? AND agent_id=?");p.setString(1,oid.trim());p.setString(2,agentId);int rows=p.executeUpdate();p.close();
        if(rows>0){
            p=c.prepareStatement("UPDATE orders SET order_status='Delivered',updated_at=NOW() WHERE order_id=?");p.setString(1,oid.trim());p.executeUpdate();p.close();
            p=c.prepareStatement("INSERT INTO order_tracking (shipment_id,tracking_number,event_status,event_location,event_datetime,event_description) SELECT shipment_id,tracking_number,'Delivered',delivery_address,NOW(),'Package delivered to customer by agent' FROM shipments WHERE order_id=?");p.setString(1,oid.trim());p.executeUpdate();p.close();
            p=c.prepareStatement("UPDATE delivery_agents SET completed_deliveries=completed_deliveries+1 WHERE agent_id=?");p.setString(1,agentId);p.executeUpdate();p.close();
            c.commit();actionMsg="✅ Order "+oid+" marked as Delivered!";actionOk=true;
        }else{c.rollback();actionMsg="⚠ Cannot update — order may not be assigned to you.";}}
        catch(Exception e){try{c.rollback();}catch(Exception ig){}actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
    }
}

/* ---- AGENT: Cancel Shipment ---- */
else if ("agentCancel".equals(action) && isAgent && agentId!=null) {
    String oid=request.getParameter("o_order_id");
    if(oid!=null&&!oid.trim().isEmpty()){
        Connection c=null;PreparedStatement p=null;
        try{c=getConn();c.setAutoCommit(false);
        p=c.prepareStatement("UPDATE shipments SET shipment_status='returned',updated_at=NOW() WHERE order_id=? AND agent_id=?");p.setString(1,oid.trim());p.setString(2,agentId);int rows=p.executeUpdate();p.close();
        if(rows>0){
            p=c.prepareStatement("UPDATE orders SET order_status='Cancelled',updated_at=NOW() WHERE order_id=?");p.setString(1,oid.trim());p.executeUpdate();p.close();
            p=c.prepareStatement("INSERT INTO order_tracking (shipment_id,tracking_number,event_status,event_location,event_datetime,event_description) SELECT shipment_id,tracking_number,'Delivery Failed','Agent location',NOW(),'Delivery could not be completed — order cancelled' FROM shipments WHERE order_id=?");p.setString(1,oid.trim());p.executeUpdate();p.close();
            c.commit();actionMsg="Order "+oid+" has been cancelled.";actionOk=true;
        }else{c.rollback();actionMsg="⚠ Cannot cancel — order may not be assigned to you.";}  }
        catch(Exception e){try{c.rollback();}catch(Exception ig){}actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
    }
}

/* ---- ADMIN/SELLER: Dispatch ---- */
else if ("dispatch".equals(action) && (isAdmin||isSeller)) {
    String oid=request.getParameter("d_orderid"),pname=request.getParameter("d_product"),cname=request.getParameter("d_customer"),cph=request.getParameter("d_phone"),addr=request.getParameter("d_address"),ddate=request.getParameter("d_date"),dtime=request.getParameter("d_time"),edate=request.getParameter("d_delivery_date"),aid2=request.getParameter("d_agent"),tmode=request.getParameter("d_transport");
    String src=isSeller?"seller":"manual";
    if(oid!=null&&!oid.trim().isEmpty()&&pname!=null&&!pname.trim().isEmpty()){
        Connection c=null;PreparedStatement p=null;ResultSet rs=null;
        try{
            c=getConn();c.setAutoCommit(false);
            // Check order is Confirmed before dispatching
            p=c.prepareStatement("SELECT order_status FROM orders WHERE order_id=?");p.setString(1,oid.trim());rs=p.executeQuery();
            if(!rs.next()){actionMsg="⚠ Order not found.";}
            else{
                String ost=rs.getString("order_status");rs.close();p.close();
                if(!"Confirmed".equals(ost)&&!"Processing".equals(ost)&&isAdmin==false){
                    actionMsg="⚠ Order must be Confirmed before dispatch. Current status: "+ost;
                } else {
                    p=c.prepareStatement("SELECT shipment_id FROM shipments WHERE order_id=?");p.setString(1,oid.trim());rs=p.executeQuery();
                    if(rs.next()){
                        rs.close();p.close();actionMsg="⚠ Shipment for order "+oid+" already exists.";
                    } else {
                        rs.close();p.close();
                        String trk=genTrk(ddate);
                        p=c.prepareStatement("INSERT INTO shipments (order_id,tracking_number,product_name,customer_name,customer_phone,delivery_address,dispatch_date,dispatch_time,expected_delivery,agent_id,transport_mode,shipment_status,seller_source) VALUES (?,?,?,?,?,?,?,?,?,?,?,'dispatched',?)",Statement.RETURN_GENERATED_KEYS);
                        p.setString(1,oid.trim());p.setString(2,trk);p.setString(3,pname.trim());p.setString(4,cname!=null?cname.trim():"");p.setString(5,cph!=null?cph.trim():null);p.setString(6,addr!=null?addr.trim():"");p.setString(7,ddate!=null?ddate:"");p.setString(8,dtime!=null?dtime:"09:00");p.setString(9,edate!=null?edate:"");
                        if(aid2!=null&&!aid2.trim().isEmpty())p.setString(10,aid2.trim());else p.setNull(10,Types.VARCHAR);
                        p.setString(11,tmode!=null?tmode:"Road -- Delivery Van");p.setString(12,src);p.executeUpdate();
                        rs=p.getGeneratedKeys();int nid=rs.next()?rs.getInt(1):-1;rs.close();p.close();
                        if(aid2!=null&&!aid2.trim().isEmpty()){p=c.prepareStatement("UPDATE delivery_agents SET total_deliveries=total_deliveries+1 WHERE agent_id=?");p.setString(1,aid2.trim());p.executeUpdate();p.close();}
                        if(nid>0){
                            p=c.prepareStatement("INSERT INTO order_tracking (shipment_id,tracking_number,event_status,event_location,event_datetime,event_description) VALUES (?,?,'Order Dispatched','MarketHub Warehouse',NOW(),'Order dispatched by "+src+"')");p.setInt(1,nid);p.setString(2,trk);p.executeUpdate();p.close();
                            p=c.prepareStatement("INSERT INTO dispatch_log (shipment_id,order_id,dispatched_by,dispatch_datetime,agent_id,transport_mode) VALUES (?,?,?,NOW(),?,?)");p.setInt(1,nid);p.setString(2,oid.trim());p.setString(3,isAdmin?"Admin":sessionEmail);if(aid2!=null&&!aid2.trim().isEmpty())p.setString(4,aid2.trim());else p.setNull(4,Types.VARCHAR);p.setString(5,tmode!=null?tmode:"Road -- Delivery Van");p.executeUpdate();p.close();
                        }
                        // Update order status to Processing
                        p=c.prepareStatement("UPDATE orders SET order_status='Processing',updated_at=NOW() WHERE order_id=?");p.setString(1,oid.trim());p.executeUpdate();p.close();
                        c.commit();actionMsg="🚛 Dispatched! Tracking: "+trk;actionOk=true;
                    }
                }
            }
        }
        catch(Exception e){try{c.rollback();}catch(Exception ig){}actionMsg="❌ "+e.getMessage();}finally{close(c,p,rs);}
    }else{actionMsg="⚠ Order ID and Product Name required.";}
}

/* ---- ADMIN: Mark Delivered ---- */
else if ("markDelivered".equals(action) && isAdmin) {
    String oid=request.getParameter("order_id");
    Connection c=null;PreparedStatement p=null;
    try{c=getConn();c.setAutoCommit(false);p=c.prepareStatement("UPDATE shipments SET shipment_status='delivered',actual_delivery=CURDATE(),updated_at=NOW() WHERE order_id=?");p.setString(1,oid);p.executeUpdate();p.close();p=c.prepareStatement("UPDATE orders SET order_status='Delivered',updated_at=NOW() WHERE order_id=?");p.setString(1,oid);p.executeUpdate();p.close();p=c.prepareStatement("INSERT INTO order_tracking (shipment_id,tracking_number,event_status,event_location,event_datetime,event_description) SELECT shipment_id,tracking_number,'Delivered',delivery_address,NOW(),'Package delivered' FROM shipments WHERE order_id=?");p.setString(1,oid);p.executeUpdate();c.commit();actionMsg="✅ Order "+oid+" marked Delivered!";actionOk=true;}
    catch(Exception e){try{c.rollback();}catch(Exception ig){}actionMsg="❌ "+e.getMessage();}finally{close(c,p,null);}
}

/* ================================================================
   SECTION ROUTING
================================================================ */
String sec=request.getParameter("section");if(sec==null||sec.isEmpty())sec=isAgent?"myorders":"orders";

/* ================================================================
   LOAD DATA
================================================================ */
List<OrderRow> allOrders=new ArrayList<OrderRow>(); List<Shipment> allShips=new ArrayList<Shipment>();
List<ReturnReq>allReturns=new ArrayList<ReturnReq>(); List<Agent> allAgents=new ArrayList<Agent>();
String dbErr="";
try{
    if(isAdmin){ allOrders=fetchOrders("",new String[]{}); allShips=fetchShipments("",new String[]{}); allReturns=fetchReturns("",new String[]{}); allAgents=getAgents(false); }
    else if(isSeller){
        allOrders=fetchOrders("WHERE order_id IN (SELECT DISTINCT o.order_id FROM orders o JOIN order_items oi ON o.order_id=oi.order_id JOIN products p ON oi.product_id=p.id WHERE p.seller_email=?)",new String[]{sessionEmail});
        allShips=fetchShipments("",new String[]{}); allReturns=fetchReturns("WHERE seller_email=?",new String[]{sessionEmail}); allAgents=getAgents(true);
    } else if(isAgent&&agentId!=null){
        allShips=fetchShipments("WHERE s.agent_id=?",new String[]{agentId});
        // get orders for agent's shipments
        for(Shipment s:allShips){try{List<OrderRow>tmp=fetchOrders("WHERE order_id=?",new String[]{raw(s.order_id)});if(!tmp.isEmpty())allOrders.add(tmp.get(0));}catch(Exception ig){}}
        allReturns=fetchReturns("",new String[]{});
    } else if(isLoggedIn&&isCustomer){
        allOrders=fetchOrders("WHERE customer_email=?",new String[]{sessionEmail});
        allShips=fetchShipments("",new String[]{}); allReturns=fetchReturns("WHERE customer_email=?",new String[]{sessionEmail}); allAgents=getAgents(true);
    } else {
        allOrders=fetchOrders("",new String[]{}); allShips=fetchShipments("",new String[]{}); allReturns=fetchReturns("",new String[]{}); allAgents=getAgents(false);
    }
}catch(Exception e){dbErr=e.getMessage();}

/* ================================================================
   TRACK ORDER SEARCH
================================================================ */
String trackIn=request.getParameter("trackInput"); Shipment trackedShip=null; List<TrackEvt>trackEvts=new ArrayList<TrackEvt>(); OrderRow trackedOrder=null;
if(trackIn!=null&&!trackIn.trim().isEmpty()){
    String q=trackIn.trim();
    for(Shipment s:allShips){if(raw(s.order_id).equalsIgnoreCase(q)||raw(s.tracking_number).equalsIgnoreCase(q)){trackedShip=s;break;}}
    if(trackedShip==null){try{trackedShip=getShipmentByOrder(q);}catch(Exception ig){}}
    if(trackedShip!=null){try{trackEvts=getTrackEvents(raw(trackedShip.tracking_number));}catch(Exception ig){}for(OrderRow o:allOrders){if(raw(o.order_id).equalsIgnoreCase(raw(trackedShip.order_id))){trackedOrder=o;break;}}}
    sec="track";
}

int sTotal=allOrders.size(),sShipped=countStatus(allOrders,"Shipped"),sDelivered=countStatus(allOrders,"Delivered"),sPending=countStatus(allOrders,"Pending"),sConfirmed=countStatus(allOrders,"Confirmed");
int sRetPending=0;for(ReturnReq r:allReturns)if("Pending".equals(r.return_status)||"Approved".equals(r.return_status))sRetPending++;
String qBase="?section="+sec+(isLoggedIn?"&email="+sessionEmail+"&viewAs="+sessionRole:"");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MarketHub — Logistics &amp; Order Tracking</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{--ink:#0b0f1a;--ink2:#1e2535;--ink3:#2e3a52;--slate:#64748b;--mist:#94a3b8;--border:#e2e8f0;--surface:#f8fafc;--white:#fff;--accent:#3b82f6;--accent2:#6366f1;--success:#10b981;--warning:#f59e0b;--danger:#ef4444;--radius:14px;--shadow:0 4px 24px rgba(11,15,26,.08);--shadow-lg:0 12px 40px rgba(11,15,26,.14);}
*{margin:0;padding:0;box-sizing:border-box}html{scroll-behavior:smooth}
body{font-family:'DM Sans',sans-serif;background:#f0f4f8;color:var(--ink);min-height:100vh;}

/* TOPBAR */
.topbar{background:var(--ink);color:rgba(255,255,255,.5);font-size:12.5px;padding:9px 0;}
.topbar a{color:rgba(255,255,255,.5);text-decoration:none;}
.topbar a:hover{color:#60a5fa;}
.tb{max-width:1340px;margin:0 auto;padding:0 24px;display:flex;justify-content:space-between;align-items:center;}

/* HEADER */
.header{background:#fff;border-bottom:1px solid var(--border);position:sticky;top:0;z-index:200;box-shadow:0 2px 16px rgba(0,0,0,.06);}
.hi{max-width:1340px;margin:0 auto;padding:0 24px;display:flex;align-items:center;gap:28px;height:64px;}
.logo{font-family:'Syne',sans-serif;font-size:22px;font-weight:800;color:var(--ink);text-decoration:none;display:flex;align-items:center;gap:9px;}
.logo-dot{width:10px;height:10px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));}
.htag{font-size:12.5px;font-weight:600;color:var(--slate);background:var(--surface);border:1px solid var(--border);padding:5px 14px;border-radius:50px;}
.hr{margin-left:auto;display:flex;align-items:center;gap:12px;}
.rtag{font-size:11.5px;font-weight:700;padding:4px 13px;border-radius:50px;letter-spacing:.5px;text-transform:uppercase;}
.r-admin{background:#fef3c7;color:#92400e;} .r-seller{background:#ede9fe;color:#5b21b6;} .r-customer{background:#d1fae5;color:#065f46;} .r-agent{background:#e0f2fe;color:#075985;} .r-guest{background:#f1f5f9;color:#475569;}

/* NAV */
.nav{background:var(--ink2);}
.nav-inner{max-width:1340px;margin:0 auto;padding:0 24px;display:flex;overflow-x:auto;scrollbar-width:none;}
.nav-inner::-webkit-scrollbar{display:none;}
.nl{color:rgba(255,255,255,.55);font-weight:600;font-size:13px;padding:16px 20px;display:flex;align-items:center;gap:8px;cursor:pointer;text-decoration:none;white-space:nowrap;border-bottom:3px solid transparent;transition:all .25s;}
.nl:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.05);}
.nl.active{color:#fff;border-bottom-color:var(--accent);}
.nbadge{background:var(--danger);color:#fff;font-size:10px;font-weight:800;padding:2px 6px;border-radius:50px;min-width:18px;text-align:center;}

/* LAYOUT */
.container{max-width:1340px;margin:0 auto;padding:0 24px;}
.py{padding-top:36px;padding-bottom:36px;}
.section{display:none;}.section.active{display:block;}

/* HERO */
.hero{background:linear-gradient(135deg,var(--ink) 0%,var(--ink3) 100%);padding:40px 0 36px;color:#fff;position:relative;overflow:hidden;}
.hero::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at 80% 50%,rgba(99,102,241,.18) 0%,transparent 60%),radial-gradient(ellipse at 20% 80%,rgba(59,130,246,.12) 0%,transparent 50%);}
.hero-inner{position:relative;z-index:1;max-width:1340px;margin:0 auto;padding:0 24px;}
.h-eyebrow{display:inline-flex;align-items:center;gap:7px;background:rgba(255,255,255,.1);border:1px solid rgba(255,255,255,.15);padding:5px 14px;border-radius:50px;font-size:11.5px;font-weight:700;color:rgba(255,255,255,.8);text-transform:uppercase;letter-spacing:.5px;margin-bottom:12px;}
.hero h1{font-family:'Syne',sans-serif;font-size:30px;font-weight:800;line-height:1.1;margin-bottom:8px;}
.hero p{font-size:14px;color:rgba(255,255,255,.6);max-width:540px;}
.hero-wave{position:absolute;bottom:-1px;left:0;right:0;height:36px;background:#f0f4f8;clip-path:ellipse(55% 100% at 50% 100%);}

/* STATS */
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:24px;}
@media(max-width:880px){.stats-grid{grid-template-columns:repeat(2,1fr);}}
.sc{background:#fff;border-radius:var(--radius);padding:20px 18px;border:1px solid var(--border);position:relative;overflow:hidden;transition:transform .25s,box-shadow .25s;}
.sc:hover{transform:translateY(-3px);box-shadow:var(--shadow-lg);}
.sc::after{content:'';position:absolute;top:0;left:0;right:0;height:3px;}
.sc.bl::after{background:linear-gradient(90deg,#3b82f6,#6366f1);} .sc.am::after{background:linear-gradient(90deg,#f59e0b,#f97316);} .sc.gr::after{background:linear-gradient(90deg,#10b981,#06b6d4);} .sc.rd::after{background:linear-gradient(90deg,#ef4444,#f97316);}
.si{width:42px;height:42px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:17px;color:#fff;margin-bottom:12px;}
.si.bl{background:linear-gradient(135deg,#3b82f6,#6366f1);} .si.am{background:linear-gradient(135deg,#f59e0b,#f97316);} .si.gr{background:linear-gradient(135deg,#10b981,#06b6d4);} .si.rd{background:linear-gradient(135deg,#ef4444,#f97316);}
.sn{font-family:'Syne',sans-serif;font-size:28px;font-weight:800;color:var(--ink);}
.sl{font-size:12.5px;font-weight:600;color:var(--slate);margin-top:2px;}

/* CARD */
.card{background:#fff;border-radius:var(--radius);border:1px solid var(--border);box-shadow:var(--shadow);overflow:hidden;margin-bottom:22px;}
.card-header{padding:18px 22px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;}
.card-title{font-family:'Syne',sans-serif;font-size:16px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:9px;}
.card-title i{color:var(--accent);}
.card-body{padding:22px;}

/* TABLE */
.tw{overflow-x:auto;max-height:480px;overflow-y:auto;}
.tw::-webkit-scrollbar{width:5px;height:5px;} .tw::-webkit-scrollbar-thumb{background:var(--accent);border-radius:10px;}
table{width:100%;border-collapse:collapse;}
thead{position:sticky;top:0;z-index:5;}
th{background:var(--surface);color:var(--slate);font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;padding:11px 15px;text-align:left;border-bottom:2px solid var(--border);white-space:nowrap;}
td{padding:13px 15px;border-bottom:1px solid var(--border);font-size:13px;font-weight:500;color:var(--ink);vertical-align:middle;}
tr:last-child td{border-bottom:none;}
tr:hover td{background:rgba(59,130,246,.02);}

/* BADGES */
.badge{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:50px;font-size:11.5px;font-weight:700;white-space:nowrap;}
.badge::before{content:'';width:5px;height:5px;border-radius:50%;display:inline-block;}
.b-Pending{background:#f1f5f9;color:#475569;} .b-Pending::before{background:#94a3b8;}
.b-Confirmed{background:#e0f2fe;color:#075985;} .b-Confirmed::before{background:#0ea5e9;}
.b-Processing{background:#ede9fe;color:#5b21b6;} .b-Processing::before{background:#7c3aed;animation:pulse 1.5s infinite;}
.b-Shipped{background:#fef3c7;color:#92400e;} .b-Shipped::before{background:#f59e0b;animation:pulse 1.5s infinite;}
.b-Delivered{background:#d1fae5;color:#065f46;} .b-Delivered::before{background:#10b981;}
.b-Cancelled{background:#fee2e2;color:#991b1b;} .b-Cancelled::before{background:#ef4444;}
.b-Refunded{background:#fef9c3;color:#713f12;} .b-Refunded::before{background:#eab308;}
.b-dispatched{background:#e0f2fe;color:#075985;} .b-dispatched::before{background:#0ea5e9;}
.b-intransit{background:#fef3c7;color:#92400e;} .b-intransit::before{background:#f59e0b;animation:pulse 1.5s infinite;}
.b-delivered{background:#d1fae5;color:#065f46;} .b-delivered::before{background:#10b981;}
.b-returned{background:#fee2e2;color:#991b1b;} .b-returned::before{background:#ef4444;}
.b-Approved{background:#d1fae5;color:#065f46;} .b-Approved::before{background:#10b981;}
.b-Rejected{background:#fee2e2;color:#991b1b;} .b-Rejected::before{background:#ef4444;}
.b-Completed{background:#e0e7ff;color:#3730a3;} .b-Completed::before{background:#6366f1;}
.b-Active{background:#d1fae5;color:#065f46;} .b-Active::before{background:#10b981;}
.b-Inactive{background:#fee2e2;color:#991b1b;} .b-Inactive::before{background:#ef4444;}
.b-agent-Pending{background:#fef3c7;color:#92400e;} .b-agent-Pending::before{background:#f59e0b;}
.b-cod{background:#fef3c7;color:#92400e;} .b-upi{background:#ede9fe;color:#5b21b6;} .b-card{background:#e0f2fe;color:#075985;}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}

/* BUTTONS */
.btn{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;border-radius:9px;font-family:'DM Sans',sans-serif;font-weight:700;font-size:13px;border:none;cursor:pointer;transition:all .2s;text-decoration:none;white-space:nowrap;}
.btn:active{transform:scale(.97);}
.bp{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;} .bp:hover{box-shadow:0 6px 18px rgba(99,102,241,.4);transform:translateY(-1px);color:#fff;}
.bs{background:linear-gradient(135deg,var(--success),#059669);color:#fff;} .bs:hover{box-shadow:0 6px 18px rgba(16,185,129,.4);transform:translateY(-1px);color:#fff;}
.bd{background:linear-gradient(135deg,var(--danger),#dc2626);color:#fff;} .bd:hover{box-shadow:0 6px 18px rgba(239,68,68,.4);transform:translateY(-1px);color:#fff;}
.bw{background:linear-gradient(135deg,var(--warning),#d97706);color:#fff;} .bw:hover{box-shadow:0 6px 18px rgba(245,158,11,.4);transform:translateY(-1px);color:#fff;}
.bo{background:transparent;color:var(--accent);border:2px solid var(--accent);} .bo:hover{background:var(--accent);color:#fff;}
.bg{background:var(--surface);color:var(--slate);border:1px solid var(--border);} .bg:hover{background:var(--border);}
.btn-sm{padding:6px 12px;font-size:12px;border-radius:8px;} .btn-xs{padding:4px 10px;font-size:11px;border-radius:7px;}

/* FORMS */
.fg2{margin-bottom:16px;}
.flbl{display:block;font-size:11px;font-weight:700;color:var(--slate);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;}
.fc{width:100%;padding:10px 13px;border:2px solid var(--border);border-radius:9px;font-family:'DM Sans',sans-serif;font-size:14px;font-weight:500;color:var(--ink);background:#fff;transition:border-color .2s,box-shadow .2s;}
.fc:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 4px rgba(59,130,246,.1);}
.ig{position:relative;} .ig i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--mist);font-size:12px;pointer-events:none;} .ig .fc{padding-left:36px;}
.frow{display:grid;grid-template-columns:1fr 1fr;gap:14px;} @media(max-width:580px){.frow{grid-template-columns:1fr;}}
.frow3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;} @media(max-width:680px){.frow3{grid-template-columns:1fr;}}

/* FILTER PILLS */
.fp-bar{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:18px;}
.fp{padding:6px 15px;border-radius:50px;font-size:12px;font-weight:700;border:2px solid var(--border);background:#fff;color:var(--slate);cursor:pointer;transition:all .2s;text-decoration:none;}
.fp:hover,.fp.active{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}

/* ORDER CARD (customer) */
.oc{background:#fff;border:1px solid var(--border);border-radius:var(--radius);padding:18px 20px;margin-bottom:14px;transition:all .25s;}
.oc:hover{border-color:var(--accent);box-shadow:var(--shadow-lg);}
.om{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:9px;margin-bottom:12px;}
.oid{font-family:'Syne',sans-serif;font-size:15px;font-weight:800;}
.odt{font-size:12px;color:var(--slate);}
.oitem{display:flex;align-items:center;gap:10px;padding:9px 13px;background:var(--surface);border-radius:9px;margin-bottom:7px;}
.oi-thumb{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,#e0e7ff,#ede9fe);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.oi-name{font-weight:700;font-size:13px;}
.oi-sub{font-size:11.5px;color:var(--slate);}
.ofooter{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:9px;padding-top:12px;border-top:1px solid var(--border);}

/* SHIPMENT PROGRESS */
.sp{display:flex;align-items:center;gap:0;margin:10px 0;}
.sp-step{display:flex;flex-direction:column;align-items:center;flex:1;}
.sp-dot{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;color:#fff;}
.sp-done{background:var(--success);} .sp-active{background:var(--accent);box-shadow:0 0 0 4px rgba(59,130,246,.2);} .sp-idle{background:var(--border);color:var(--mist);}
.sp-line{flex:1;height:2px;}
.sp-done-line{background:var(--success);} .sp-idle-line{background:var(--border);}
.sp-lbl{font-size:10px;font-weight:700;color:var(--slate);margin-top:4px;text-align:center;max-width:60px;line-height:1.2;}

/* TIMELINE */
.timeline{padding-left:24px;border-left:2px solid var(--border);}
.ti{position:relative;padding-bottom:20px;}
.ti:last-child{padding-bottom:0;}
.ti-dot{position:absolute;left:-30px;top:3px;width:11px;height:11px;border-radius:50%;background:var(--success);border:2px solid #fff;box-shadow:0 0 0 2px var(--success);}
.ti-dot.idle{background:var(--border);box-shadow:0 0 0 2px var(--border);}
.ti-time{font-size:11px;color:var(--slate);font-weight:600;margin-bottom:2px;}
.ti-evt{font-size:13.5px;font-weight:700;color:var(--ink);}
.ti-loc{font-size:12px;color:var(--slate);margin-top:1px;}
.ti-desc{font-size:11.5px;color:var(--mist);margin-top:1px;font-style:italic;}

/* TRACK INFO */
.ti-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:13px;margin-top:16px;}
@media(max-width:680px){.ti-grid{grid-template-columns:1fr;}}
.ti-item{background:var(--surface);border-radius:9px;padding:12px 14px;}
.ti-lbl{font-size:10.5px;font-weight:700;color:var(--slate);text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px;}
.ti-val{font-size:13.5px;font-weight:700;color:var(--ink);}

/* RETURN CARD */
.rcard{background:#fff;border:1.5px solid var(--border);border-radius:var(--radius);padding:16px 18px;transition:all .25s;}
.rcard:hover{border-color:var(--danger);box-shadow:0 8px 24px rgba(239,68,68,.09);}

/* MODAL */
.modal-ov{display:none;position:fixed;inset:0;background:rgba(11,15,26,.6);z-index:1000;align-items:center;justify-content:center;backdrop-filter:blur(4px);padding:20px;}
.modal-ov.open{display:flex;}
.modal-box{background:#fff;border-radius:18px;padding:28px;width:100%;max-width:520px;max-height:90vh;overflow-y:auto;box-shadow:var(--shadow-lg);animation:mIn .3s cubic-bezier(.34,1.56,.64,1);}
@keyframes mIn{from{opacity:0;transform:scale(.93) translateY(18px)}to{opacity:1;transform:scale(1) translateY(0)}}
.mhead{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;padding-bottom:14px;border-bottom:1px solid var(--border);}
.mtitle{font-family:'Syne',sans-serif;font-size:18px;font-weight:800;color:var(--ink);}
.mclose{width:32px;height:32px;border-radius:8px;background:var(--surface);border:1px solid var(--border);display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:14px;color:var(--slate);transition:all .2s;}
.mclose:hover{background:#fee2e2;color:var(--danger);border-color:var(--danger);}

/* ALERT */
.alert{padding:12px 16px;border-radius:9px;font-size:13px;font-weight:600;margin-bottom:16px;border-left:4px solid;display:flex;align-items:flex-start;gap:9px;line-height:1.5;}
.al-ok{background:#d1fae5;color:#065f46;border-color:var(--success);}
.al-err{background:#fee2e2;color:#991b1b;border-color:var(--danger);}
.al-info{background:#e0f2fe;color:#075985;border-color:#0ea5e9;}
.al-warn{background:#fef3c7;color:#92400e;border-color:var(--warning);}

/* EMPTY */
.empty{text-align:center;padding:56px 20px;color:var(--slate);}
.empty i{font-size:44px;opacity:.2;margin-bottom:14px;display:block;color:var(--ink);}
.empty p{font-size:14.5px;font-weight:600;} .empty span{font-size:12.5px;opacity:.7;}

/* TOAST */
.toast-stack{position:fixed;bottom:22px;right:22px;z-index:9999;display:flex;flex-direction:column;gap:9px;}
.toast{background:#fff;border-radius:11px;padding:12px 16px;box-shadow:var(--shadow-lg);display:flex;align-items:center;gap:10px;min-width:250px;font-size:13px;font-weight:600;color:var(--ink);border-left:4px solid var(--success);animation:tIn .3s ease;}
.toast.err{border-left-color:var(--danger);}
@keyframes tIn{from{opacity:0;transform:translateX(28px)}to{opacity:1;transform:translateX(0)}}

/* PROD CELL */
.pcell{display:flex;align-items:center;gap:10px;}
.pthumb{width:38px;height:38px;border-radius:9px;background:linear-gradient(135deg,#e0e7ff,#ede9fe);display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;}
.pname{font-weight:700;font-size:13px;}
.pid{font-size:11.5px;color:var(--slate);}

.divider{height:1px;background:var(--border);margin:18px 0;}
@media(max-width:768px){.hero h1{font-size:22px;}.card-body{padding:16px;}.tw{max-height:340px;}}
</style>
</head>
<body>

<!-- TOPBAR -->
<div class="topbar"><div class="tb">
  <div><i class="fas fa-phone" style="margin-right:5px"></i>+91 1800-123-4567 &nbsp;&nbsp;<i class="fas fa-envelope" style="margin-right:5px"></i>logistics@markethub.com</div>
  <div style="display:flex;gap:14px;align-items:center">
    <% if(isAdmin){%><a href="adlogin.jsp"><i class="fas fa-shield-alt" style="margin-right:4px"></i>Admin</a><%}%>
    <% if(isSeller){%><a href="sellerorders.jsp"><i class="fas fa-store" style="margin-right:4px"></i>Seller</a><%}%>
    <% if(isCustomer){%><a href="myorders.jsp"><i class="fas fa-box" style="margin-right:4px"></i>My Orders</a><%}%>
    <% if(isAgent){%><a href="agent_login.jsp"><i class="fas fa-user-tie" style="margin-right:4px"></i>Agent Portal</a><%}%>
    <% if(!isLoggedIn){%><a href="agent_login.jsp">Agent Login</a><%}%>
    <% if(isLoggedIn){%><a href="ulogin.jsp">Logout</a><%}%>
  </div>
</div></div>

<!-- HEADER -->
<header class="header"><div class="hi">
  <a href="index.jsp" class="logo"><div class="logo-dot"></div>MarketHub</a>
  <span class="htag"><i class="fas fa-truck" style="margin-right:5px;color:var(--accent)"></i>Logistics &amp; Tracking</span>
  <div class="hr">
    <% if(isLoggedIn){%><span style="font-size:12.5px;font-weight:600;color:var(--slate)"><i class="fas fa-user-circle" style="margin-right:5px"></i><%=safe(isAgent?agentName:sessionEmail)%></span><%}%>
    <span class="rtag r-<%=sessionRole%>">
      <%if(isAdmin){%><i class="fas fa-shield-alt"></i> Admin<%}else if(isSeller){%><i class="fas fa-store"></i> Seller<%}else if(isAgent){%><i class="fas fa-user-tie"></i> Agent<%}else if(isCustomer){%><i class="fas fa-user"></i> Customer<%}else{%><i class="fas fa-eye"></i> Guest<%}%>
    </span>
  </div>
</div></header>

<!-- NAV -->
<nav class="nav"><div class="nav-inner">
  <%String nBase="?";if(isLoggedIn)nBase+="email="+sessionEmail+"&viewAs="+sessionRole+"&";%>
  <%if(isAgent){%>
  <a href="<%=nBase%>section=myorders" class="nl <%="myorders".equals(sec)?"active":""%>"><i class="fas fa-box"></i> My Assigned Orders</a>
  <a href="<%=nBase%>section=track"    class="nl <%="track".equals(sec)?"active":""%>"><i class="fas fa-map-marker-alt"></i> Track</a>
  <%}else{%>
  <a href="<%=nBase%>section=orders"    class="nl <%="orders".equals(sec)?"active":""%>"><i class="fas fa-list-check"></i> Orders</a>
  <a href="<%=nBase%>section=track"     class="nl <%="track".equals(sec)?"active":""%>"><i class="fas fa-map-marker-alt"></i> Track Order</a>
  <%if(isAdmin||isSeller){%>
  <a href="<%=nBase%>section=shipments" class="nl <%="shipments".equals(sec)?"active":""%>"><i class="fas fa-truck-fast"></i> Shipments</a>
  <%if(isAdmin){%>
  <a href="<%=nBase%>section=dispatch"  class="nl <%="dispatch".equals(sec)?"active":""%>"><i class="fas fa-box"></i> Dispatch</a>
  <a href="<%=nBase%>section=agents"    class="nl <%="agents".equals(sec)?"active":""%>"><i class="fas fa-user-tie"></i> Agents <%if(sRetPending>0){%><span class="nbadge">!</span><%}%></a>
  <%}%>
  <%}%>
  <a href="<%=nBase%>section=returns"   class="nl <%="returns".equals(sec)?"active":""%>"><i class="fas fa-rotate-left"></i> Returns<%if(sRetPending>0){%><span class="nbadge"><%=sRetPending%></span><%}%></a>
  <%}%>
</div></nav>

<%if(dbErr!=null&&!dbErr.isEmpty()){%>
<div class="container" style="padding-top:14px"><div class="alert al-err"><i class="fas fa-exclamation-triangle"></i>DB Error: <%=safe(dbErr)%></div></div>
<%}%>

<%-- ================================================================ AGENT: MY ORDERS --%>
<div id="sec-myorders" class="section <%="myorders".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-box"></i> My Assigned Orders</div>
  <h1><%=safe(agentName!=null?agentName:"Agent")%>'s Deliveries</h1>
  <p>Orders assigned to you. Mark them as <strong>Delivered</strong> on completion, or <strong>Cancel</strong> if delivery fails.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <%if(!actionMsg.isEmpty()){%><div class="alert <%=actionOk?"al-ok":"al-err"%>"><%=safe(actionMsg)%></div><%}%>
  <%if(allShips.isEmpty()){%>
  <div class="empty"><i class="fas fa-truck"></i><p>No shipments assigned yet</p><span>Deliveries assigned to you will appear here.</span></div>
  <%}else{%>
  <% String[]ems={"📦","🖥️","📱","👟","🎧","⌚","💻","📷","🎮","🛍️"};int ei=0;
     for(Shipment s:allShips){ String ss=raw(s.shipment_status);
       OrderRow oMatch=null;for(OrderRow o:allOrders){if(raw(o.order_id).equalsIgnoreCase(raw(s.order_id))){oMatch=o;break;}}
  %>
  <div class="oc">
    <div class="om">
      <div>
        <div class="oid"><i class="fas fa-truck" style="margin-right:7px;color:var(--accent)"></i><%=safe(s.order_id)%></div>
        <div class="odt" style="margin-top:2px"><i class="fas fa-barcode" style="margin-right:4px"></i><%=safe(s.tracking_number)%></div>
      </div>
      <span class="badge b-<%=ss%>"><%=ss.length()>0?ss.substring(0,1).toUpperCase()+ss.substring(1):""%></span>
    </div>

    <div style="background:var(--surface);border-radius:10px;padding:14px 16px;margin-bottom:14px">
      <div class="frow">
       <div><div style="font-size:11px;font-weight:700;color:var(--slate);text-transform:uppercase">Customer</div>
<div style="font-weight:700;font-size:13.5px;margin-top:3px"><%=safe(s.customer_name)%></div>
<%if(s.customer_phone!=null&&!s.customer_phone.isEmpty()){%>
<div style="font-size:12px;color:var(--slate)"><i class="fas fa-phone" style="margin-right:4px;color:var(--accent)"></i><%=safe(s.customer_phone)%></div>
<%}%>
</div>
        <div><div style="font-size:11px;font-weight:700;color:var(--slate);text-transform:uppercase">Delivery Date</div><div style="font-weight:700;font-size:13.5px;color:var(--success);margin-top:3px"><i class="fas fa-calendar-check" style="margin-right:5px"></i><%=safe(s.expected_delivery)%></div><div style="font-size:12px;color:var(--slate)">Dispatched: <%=safe(s.dispatch_date)%></div></div>
      </div>
      <div style="margin-top:10px;font-size:12.5px;color:var(--slate)"><i class="fas fa-map-marker-alt" style="margin-right:5px;color:var(--danger)"></i><%=safe(s.delivery_address)%></div>
      <%if(oMatch!=null){%><div style="margin-top:8px;display:flex;gap:14px;flex-wrap:wrap;font-size:12.5px"><span><strong>Order:</strong> <%=safe(oMatch.order_id)%></span><span><strong>Status:</strong> <span class="badge b-<%=safe(oMatch.order_status)%>" style="font-size:11px"><%=safe(oMatch.order_status)%></span></span><span><strong>Total:</strong> ₹<%=String.format("%.2f",oMatch.grand_total)%></span></div><%}%>
    </div>

    <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center">
      <a href="<%=nBase%>section=track&trackInput=<%=safe(s.tracking_number)%>" class="btn bo btn-sm"><i class="fas fa-map-marker-alt"></i> Track</a>
      <%if(!"delivered".equals(ss)&&!"returned".equals(ss)){%>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="agentDelivered">
        <input type="hidden" name="o_order_id" value="<%=safe(s.order_id)%>">
        <input type="hidden" name="section" value="myorders">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bs btn-sm" onclick="return confirm('Mark this order as Delivered?')"><i class="fas fa-check-circle"></i> Mark Delivered</button>
      </form>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="agentCancel">
        <input type="hidden" name="o_order_id" value="<%=safe(s.order_id)%>">
        <input type="hidden" name="section" value="myorders">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bd btn-sm" onclick="return confirm('Cancel this delivery?')"><i class="fas fa-times-circle"></i> Cancel Delivery</button>
      </form>
      <%}else if("delivered".equals(ss)){%>
      <span class="badge b-Delivered" style="padding:8px 14px"><i class="fas fa-check-circle" style="margin-right:5px"></i>Delivered ✓</span>
      <%}%>
    </div>
  </div>
  <%ei++;} %>
  <%}%>
</div></div>

<%-- ================================================================ ORDERS SECTION --%>
<div id="sec-orders" class="section <%="orders".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-list-check"></i> <%=isAdmin?"All Orders":isSeller?"Seller Orders":"My Orders"%></div>
  <h1>Order Management</h1>
  <p>View, confirm, and dispatch orders. Track delivery status and manage returns in real-time.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <div class="stats-grid">
    <div class="sc bl"><div class="si bl"><i class="fas fa-box-open"></i></div><div class="sn"><%=sTotal%></div><div class="sl">Total Orders</div></div>
    <div class="sc am"><div class="si am"><i class="fas fa-clock"></i></div><div class="sn"><%=sPending%></div><div class="sl">Pending</div></div>
    <div class="sc gr"><div class="si gr"><i class="fas fa-check-circle"></i></div><div class="sn"><%=sDelivered%></div><div class="sl">Delivered</div></div>
    <div class="sc rd"><div class="si rd"><i class="fas fa-rotate-left"></i></div><div class="sn"><%=sRetPending%></div><div class="sl">Return Requests</div></div>
  </div>

  <%if(!actionMsg.isEmpty()){%><div class="alert <%=actionOk?"al-ok":"al-err"%>"><%=safe(actionMsg)%></div><%}%>

  <%String of2=request.getParameter("of");if(of2==null)of2="all";
    List<OrderRow>fOrders=new ArrayList<OrderRow>();for(OrderRow o:allOrders){if("all".equals(of2)||of2.equals(o.order_status))fOrders.add(o);}
    String opfx="?"+(isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":"")+"section=orders";
  %>
  <div class="fp-bar">
    <a href="<%=opfx%>&of=all"       class="fp <%="all".equals(of2)?"active":""%>">All (<%=allOrders.size()%>)</a>
    <a href="<%=opfx%>&of=Pending"   class="fp <%="Pending".equals(of2)?"active":""%>">Pending (<%=countStatus(allOrders,"Pending")%>)</a>
    <a href="<%=opfx%>&of=Confirmed" class="fp <%="Confirmed".equals(of2)?"active":""%>">Confirmed</a>
    <a href="<%=opfx%>&of=Processing"class="fp <%="Processing".equals(of2)?"active":""%>">Processing</a>
    <a href="<%=opfx%>&of=Shipped"   class="fp <%="Shipped".equals(of2)?"active":""%>">Shipped</a>
    <a href="<%=opfx%>&of=Delivered" class="fp <%="Delivered".equals(of2)?"active":""%>">Delivered</a>
    <a href="<%=opfx%>&of=Cancelled" class="fp <%="Cancelled".equals(of2)?"active":""%>">Cancelled</a>
  </div>

  <%if(isCustomer){%>
  <!-- Customer: Card view -->
  <%String[]emC={"📦","🖥️","📱","👟","🎧","⌚","💻","📷","🎮","🛍️"};int ci=0;
    for(OrderRow o:fOrders){
      Shipment sh=null;try{sh=getShipmentByOrder(raw(o.order_id));}catch(Exception ig){}
      List<OItem>items=new ArrayList<OItem>();try{items=getItems(raw(o.order_id));}catch(Exception ig){}
  %>
  <div class="oc">
    <div class="om">
      <div><div class="oid">#<%=safe(o.order_id)%></div><div class="odt"><%=safe(o.order_date)%></div></div>
      <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
        <span class="badge b-<%=safe(o.order_status)%>"><%=safe(o.order_status)%></span>
        <span class="badge b-<%=safe(o.payment_method)%>"><%=safe(o.payment_method).toUpperCase()%></span>
        <strong style="font-size:13.5px">₹<%=String.format("%.2f",o.grand_total)%></strong>
      </div>
    </div>
    <%if(sh!=null){String sst=raw(sh.shipment_status);boolean s2="intransit".equals(sst)||"delivered".equals(sst);boolean s3="delivered".equals(sst);%>
    <div style="background:var(--surface);border-radius:9px;padding:12px 14px;margin-bottom:12px">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:9px">
        <span style="font-size:12px;font-weight:700;color:var(--slate)"><i class="fas fa-truck" style="margin-right:5px;color:var(--accent)"></i><%=safe(sh.tracking_number)%></span>
        <span class="badge b-<%=sst%>"><%=sst.length()>0?sst.substring(0,1).toUpperCase()+sst.substring(1):""%></span>
      </div>
      <div class="sp">
        <div class="sp-step"><div class="sp-dot sp-done"><i class="fas fa-check"></i></div><div class="sp-lbl">Dispatched</div></div>
        <div class="sp-line <%=s2?"sp-done-line":"sp-idle-line"%>"></div>
        <div class="sp-step"><div class="sp-dot <%=s2?"sp-done":"sp-idle"%>"><i class="fas fa-truck"></i></div><div class="sp-lbl">In Transit</div></div>
        <div class="sp-line <%=s3?"sp-done-line":"sp-idle-line"%>"></div>
        <div class="sp-step"><div class="sp-dot <%=s3?"sp-done":"sp-idle"%>"><i class="fas fa-check-circle"></i></div><div class="sp-lbl">Delivered</div></div>
      </div>
    </div>
    <%}%>
    <%for(OItem oi:items){
        boolean alreadyRet=false;for(ReturnReq rr:allReturns){if(raw(rr.order_id).equals(raw(o.order_id))&&rr.product_id==oi.product_id){alreadyRet=true;break;}}
    %>
    <div class="oitem">
      <div class="oi-thumb">📦</div>
      <div style="flex:1"><div class="oi-name"><%=safe(oi.product_name)%></div><div class="oi-sub">Qty:<%=oi.quantity%> &nbsp;·&nbsp; ₹<%=String.format("%.2f",oi.price)%></div></div>
      <%if("Delivered".equals(o.order_status)){if(!alreadyRet){%>
      <button class="btn bd btn-xs" onclick="openRet('<%=safe(o.order_id)%>','<%=oi.product_id%>','<%=safe(oi.product_name)%>','<%=safe(oi.seller_email)%>')"><i class="fas fa-rotate-left"></i> Return</button>
      <%}else{%><span class="badge b-Pending" style="font-size:11px"><i class="fas fa-clock" style="margin-right:4px"></i>Return Pending</span><%}}%>
    </div>
    <%}%>
    <div class="ofooter">
      <span style="font-size:12.5px;color:var(--slate)"><i class="fas fa-map-marker-alt" style="margin-right:4px;color:var(--accent)"></i><%=safe(o.shipping_address)%>, <%=safe(o.city)%></span>
      <%if(sh!=null){%><a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=track&trackInput=<%=safe(sh.tracking_number)%>" class="btn bo btn-sm"><i class="fas fa-map-marker-alt"></i> Track</a><%}%>
    </div>
  </div>
  <%ci++;}if(fOrders.isEmpty()){%><div class="empty"><i class="fas fa-box-open"></i><p>No orders found</p></div><%}%>

  <%}else{%>
  <!-- Admin/Seller: Table view -->
  <div class="card">
    <div class="card-header">
      <div class="card-title"><i class="fas fa-table"></i> Orders Table</div>
      <%if(isAdmin){%><a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=dispatch" class="btn bp btn-sm"><i class="fas fa-plus"></i> New Dispatch</a><%}%>
    </div>
    <div class="tw">
      <table>
        <thead><tr><th>Order ID</th><th>Customer</th><th>Total</th><th>Payment</th><th>Status</th><th>Date</th><th>Shipment</th><th>Actions</th></tr></thead>
        <tbody>
        <%String[]emT={"📦","🖥️","📱","👟","🎧","⌚","💻","📷"};int ti=0;
          for(OrderRow o:fOrders){
            Shipment sh=null;try{sh=getShipmentByOrder(raw(o.order_id));}catch(Exception ig){}
        %>
        <tr>
          <td><div class="pcell"><div class="pthumb"><%=emT[ti%emT.length]%></div><div><div class="pname"><%=safe(o.order_id)%></div><div class="pid"><%=o.total_items%> item(s)</div></div></div></td>
          <td><div style="font-weight:700"><%=safe(o.full_name)%></div><div style="font-size:11.5px;color:var(--slate)"><%=safe(o.customer_email)%></div></td>
          <td style="font-weight:800">₹<%=String.format("%.2f",o.grand_total)%></td>
          <td><span class="badge b-<%=safe(o.payment_method)%>"><%=safe(o.payment_method).toUpperCase()%></span></td>
          <td><span class="badge b-<%=safe(o.order_status)%>"><%=safe(o.order_status)%></span></td>
          <td style="font-size:12px;color:var(--slate)"><%=safe(o.order_date).substring(0,Math.min(16,safe(o.order_date).length()))%></td>
          <td>
            <%if(sh!=null){%><div style="font-size:11.5px;font-family:monospace;color:var(--accent)"><%=safe(sh.tracking_number)%></div><span class="badge b-<%=raw(sh.shipment_status)%>" style="font-size:11px"><%=raw(sh.shipment_status).length()>0?raw(sh.shipment_status).substring(0,1).toUpperCase()+raw(sh.shipment_status).substring(1):""%></span>
            <%}else{%><span style="font-size:12px;color:var(--mist)">Not dispatched</span><%}%>
          </td>
          <td><div style="display:flex;gap:5px;flex-wrap:wrap">
            <%-- Seller: Confirm Pending order --%>
            <%if(isSeller&&"Pending".equals(o.order_status)){%>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="confirmOrder">
              <input type="hidden" name="o_order_id" value="<%=safe(o.order_id)%>">
              <input type="hidden" name="section" value="orders"><input type="hidden" name="of" value="<%=of2%>">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bs btn-xs" onclick="return confirm('Confirm this order?')"><i class="fas fa-check"></i> Confirm</button>
            </form>
            <%}%>
            <%-- Track --%>
            <%if(sh!=null){%><a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=track&trackInput=<%=safe(sh.tracking_number)%>" class="btn bo btn-xs"><i class="fas fa-map-marker-alt"></i> Track</a><%}%>
            <%-- Admin: Mark Delivered --%>
            <%if(isAdmin&&sh!=null&&!"delivered".equals(raw(sh.shipment_status))){%>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="markDelivered"><input type="hidden" name="order_id" value="<%=safe(o.order_id)%>">
              <input type="hidden" name="section" value="orders"><input type="hidden" name="of" value="<%=of2%>">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bs btn-xs"><i class="fas fa-check"></i> Delivered</button>
            </form>
            <%}%>
            <%-- Admin: Dispatch unshipped Confirmed order --%>
            <%if(isAdmin&&sh==null&&("Confirmed".equals(o.order_status)||"Processing".equals(o.order_status))){%>
            <a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=dispatch&prefill=<%=safe(o.order_id)%>" class="btn bp btn-xs"><i class="fas fa-truck"></i> Dispatch</a>
            <%}%>
          </div></td>
        </tr>
        <%ti++;}if(fOrders.isEmpty()){%><tr><td colspan="8"><div class="empty"><i class="fas fa-box-open"></i><p>No orders found</p></div></td></tr><%}%>
        </tbody>
      </table>
    </div>
  </div>
  <%}%>
</div></div>

<%-- ================================================================ TRACK SECTION --%>
<div id="sec-track" class="section <%="track".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-satellite-dish"></i> Live Tracking</div>
  <h1>Track Your Shipment</h1>
  <p>Enter an Order ID or Tracking Number for real-time delivery status and full timeline.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <div class="card">
    <div class="card-header"><div class="card-title"><i class="fas fa-search"></i> Search Shipment</div></div>
    <div class="card-body">
      <form method="get" action="travel_logistics.jsp">
        <input type="hidden" name="section" value="track">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <div style="display:flex;gap:9px;max-width:540px">
          <div class="ig" style="flex:1"><i class="fas fa-search"></i><input type="text" name="trackInput" class="fc" placeholder="Enter Order ID or Tracking Number…" value="<%=trackIn!=null?safe(trackIn):""%>"></div>
          <button type="submit" class="btn bp"><i class="fas fa-search"></i> Track</button>
        </div>
      </form>
    </div>
  </div>

  <%if(trackedShip!=null){String ss2=raw(trackedShip.shipment_status);boolean t2="intransit".equals(ss2)||"delivered".equals(ss2);boolean t3="delivered".equals(ss2);%>
  <div class="card">
    <div class="card-header">
      <div class="card-title"><i class="fas fa-truck-fast"></i> Shipment Details</div>
      <span class="badge b-<%=ss2%>"><%=ss2.length()>0?ss2.substring(0,1).toUpperCase()+ss2.substring(1):""%></span>
    </div>
    <div class="card-body">
      <div style="display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:18px">
        <div>
          <div style="font-size:11px;font-weight:700;color:var(--slate);text-transform:uppercase;letter-spacing:.5px">Tracking Number</div>
          <div style="font-family:'Syne',sans-serif;font-size:20px;font-weight:800;color:var(--ink)"><%=safe(trackedShip.tracking_number)%></div>
          <div style="font-size:13px;color:var(--slate);margin-top:3px"><strong><%=safe(trackedShip.product_name)%></strong> — <%=safe(trackedShip.customer_name)%></div>
        </div>
        <div style="text-align:right">
          <div style="font-size:11px;font-weight:700;color:var(--slate);text-transform:uppercase">Order ID</div>
          <div style="font-family:'Syne',sans-serif;font-size:16px;font-weight:800;color:var(--accent)"><%=safe(trackedShip.order_id)%></div>
        </div>
      </div>
      <!-- Stepper -->
      <div style="background:var(--surface);border-radius:11px;padding:18px 22px;margin-bottom:20px">
        <div class="sp">
          <div class="sp-step"><div class="sp-dot sp-done"><i class="fas fa-box"></i></div><div class="sp-lbl">Order Placed</div></div>
          <div class="sp-line sp-done-line" style="flex:1"></div>
          <div class="sp-step"><div class="sp-dot sp-done"><i class="fas fa-truck-loading"></i></div><div class="sp-lbl">Dispatched</div></div>
          <div class="sp-line <%=t2?"sp-done-line":"sp-idle-line"%>" style="flex:1"></div>
          <div class="sp-step"><div class="sp-dot <%=t2?"sp-done":"sp-idle"%>"><i class="fas fa-truck"></i></div><div class="sp-lbl">In Transit</div></div>
          <div class="sp-line <%=t3?"sp-done-line":"sp-idle-line"%>" style="flex:1"></div>
          <div class="sp-step"><div class="sp-dot <%=t3?"sp-done":"sp-idle"%>"><i class="fas fa-check-circle"></i></div><div class="sp-lbl">Delivered</div></div>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px">
        <!-- Timeline -->
        <div>
          <div style="font-family:'Syne',sans-serif;font-size:13.5px;font-weight:800;color:var(--ink);margin-bottom:13px"><i class="fas fa-clock" style="margin-right:7px;color:var(--accent)"></i>Tracking Timeline</div>
          <%if(!trackEvts.isEmpty()){%>
          <div class="timeline">
            <%for(int ti2=trackEvts.size()-1;ti2>=0;ti2--){TrackEvt te=trackEvts.get(ti2);%>
            <div class="ti"><div class="ti-dot"></div>
              <div class="ti-time"><%=safe(te.event_datetime)%></div>
              <div class="ti-evt"><%=safe(te.event_status)%></div>
              <div class="ti-loc"><i class="fas fa-map-pin" style="margin-right:4px"></i><%=safe(te.event_location)%></div>
              <%if(te.event_description!=null&&!te.event_description.isEmpty()){%><div class="ti-desc"><%=safe(te.event_description)%></div><%}%>
            </div>
            <%}%>
          </div>
          <%}else{%><div style="color:var(--mist);font-size:13px;font-style:italic">No detailed tracking events yet.</div><%}%>
        </div>
        <!-- Info -->
        <div>
          <div style="font-family:'Syne',sans-serif;font-size:13.5px;font-weight:800;color:var(--ink);margin-bottom:13px"><i class="fas fa-info-circle" style="margin-right:7px;color:var(--accent)"></i>Shipment Info</div>
          <div style="display:flex;flex-direction:column;gap:9px">
            <div class="ti-item"><div class="ti-lbl">Dispatch Date &amp; Time</div><div class="ti-val"><%=safe(trackedShip.dispatch_date)%> <%=safe(trackedShip.dispatch_time)%></div></div>
            <div class="ti-item"><div class="ti-lbl">Expected Delivery</div><div class="ti-val" style="color:var(--success)"><%=safe(trackedShip.expected_delivery)%></div></div>
            <%if(trackedShip.actual_delivery!=null&&!trackedShip.actual_delivery.isEmpty()){%><div class="ti-item"><div class="ti-lbl">Actual Delivery</div><div class="ti-val" style="color:var(--success)">✅ <%=safe(trackedShip.actual_delivery)%></div></div><%}%>
            <div class="ti-item"><div class="ti-lbl">Agent</div><div class="ti-val"><i class="fas fa-user-tie" style="margin-right:5px;color:var(--accent)"></i><%=trackedShip.agent_name!=null?safe(trackedShip.agent_name):"Unassigned"%></div></div>
            <div class="ti-item"><div class="ti-lbl">Transport</div><div class="ti-val"><%=safe(trackedShip.transport_mode)%></div></div>
            <div class="ti-item"><div class="ti-lbl">Address</div><div class="ti-val"><i class="fas fa-map-marker-alt" style="margin-right:5px;color:var(--danger)"></i><%=safe(trackedShip.delivery_address)%></div></div>
          </div>
          <%if(isCustomer&&"delivered".equals(ss2)){%>
          <div class="divider"></div>
          <div style="background:#fef2f2;border:1px solid #fca5a5;border-radius:9px;padding:12px 14px">
            <div style="font-weight:700;font-size:13px;color:#991b1b;margin-bottom:7px"><i class="fas fa-rotate-left" style="margin-right:5px"></i>Request a Return</div>
            <button class="btn bd btn-sm" onclick="openRet('<%=safe(trackedShip.order_id)%>','','<%=safe(trackedShip.product_name)%>','')"><i class="fas fa-rotate-left"></i> Return This Item</button>
          </div>
          <%}%>
        </div>
      </div>
      <%if(trackedOrder!=null){%>
      <div class="divider"></div>
      <div style="background:var(--surface);border-radius:9px;padding:14px">
        <div style="font-family:'Syne',sans-serif;font-size:13px;font-weight:800;color:var(--ink);margin-bottom:9px"><i class="fas fa-receipt" style="margin-right:6px;color:var(--accent)"></i>Order Summary</div>
        <div style="display:flex;gap:20px;flex-wrap:wrap;font-size:13px">
          <div><span style="color:var(--slate);font-weight:600">Customer:</span> <strong><%=safe(trackedOrder.full_name)%></strong></div>
          <div><span style="color:var(--slate);font-weight:600">Grand Total:</span> <strong style="color:var(--accent)">₹<%=String.format("%.2f",trackedOrder.grand_total)%></strong></div>
          <div><span style="color:var(--slate);font-weight:600">Payment:</span> <span class="badge b-<%=safe(trackedOrder.payment_method)%>"><%=safe(trackedOrder.payment_method).toUpperCase()%></span></div>
          <div><span style="color:var(--slate);font-weight:600">Status:</span> <span class="badge b-<%=safe(trackedOrder.order_status)%>"><%=safe(trackedOrder.order_status)%></span></div>
        </div>
      </div>
      <%}%>
    </div>
  </div>
  <%}else if(trackIn!=null&&!trackIn.trim().isEmpty()){%>
  <div class="empty"><i class="fas fa-search-minus"></i><p>No results for "<%=safe(trackIn)%>"</p><span>Check the Order ID or Tracking Number.</span></div>
  <%}else if(!allShips.isEmpty()){%>
  <div class="card">
    <div class="card-header"><div class="card-title"><i class="fas fa-history"></i> Recent Shipments — Quick Track</div></div>
    <div class="tw" style="max-height:300px"><table>
      <thead><tr><th>Order ID</th><th>Tracking No.</th><th>Customer</th><th>Status</th><th>Expected</th><th>Action</th></tr></thead>
      <tbody><%int qt=0;for(Shipment s:allShips){if(qt>=8)break;String sst2=raw(s.shipment_status);%>
      <tr>
        <td><strong><%=safe(s.order_id)%></strong></td>
        <td style="font-family:monospace;font-size:12px;color:var(--accent)"><%=safe(s.tracking_number)%></td>
        <td><%=safe(s.customer_name)%></td>
        <td><span class="badge b-<%=sst2%>"><%=sst2.length()>0?sst2.substring(0,1).toUpperCase()+sst2.substring(1):""%></span></td>
        <td style="color:var(--success);font-weight:700"><%=safe(s.expected_delivery)%></td>
        <td><a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=track&trackInput=<%=safe(s.tracking_number)%>" class="btn bo btn-xs"><i class="fas fa-map-marker-alt"></i> Track</a></td>
      </tr>
      <%qt++;}%></tbody>
    </table></div>
  </div>
  <%}%>
</div></div>

<%-- ================================================================ SHIPMENTS SECTION (Admin/Seller) --%>
<%if(isAdmin||isSeller){%>
<div id="sec-shipments" class="section <%="shipments".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-truck-fast"></i> Shipment Management</div>
  <h1>Active Shipments</h1><p>Track and manage all dispatched orders.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <%String sf=request.getParameter("sf");if(sf==null)sf="all";
    List<Shipment>fShips=new ArrayList<Shipment>();for(Shipment s:allShips){if("all".equals(sf)||sf.equals(s.shipment_status))fShips.add(s);}
    String spfx="?"+(isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":"")+"section=shipments";
  %>
  <div class="fp-bar">
    <a href="<%=spfx%>&sf=all"        class="fp <%="all".equals(sf)?"active":""%>">All (<%=allShips.size()%>)</a>
    <a href="<%=spfx%>&sf=dispatched" class="fp <%="dispatched".equals(sf)?"active":""%>">Dispatched</a>
    <a href="<%=spfx%>&sf=intransit"  class="fp <%="intransit".equals(sf)?"active":""%>">In Transit</a>
    <a href="<%=spfx%>&sf=delivered"  class="fp <%="delivered".equals(sf)?"active":""%>">Delivered</a>
    <a href="<%=spfx%>&sf=returned"   class="fp <%="returned".equals(sf)?"active":""%>">Returned</a>
  </div>
  <div class="card">
    <div class="card-header">
      <div class="card-title"><i class="fas fa-truck"></i> Shipments</div>
      <%if(isAdmin){%><a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=dispatch" class="btn bp btn-sm"><i class="fas fa-plus"></i> New Dispatch</a><%}%>
    </div>
    <div class="tw"><table>
      <thead><tr><th>Product</th><th>Order ID</th><th>Customer</th><th>Dispatch</th><th>Expected</th><th>Agent</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>
      <%String[]emSh={"📦","🖥️","📱","👟","🎧","⌚"};int shi=0;
        for(Shipment s:fShips){String sst3=raw(s.shipment_status);%>
      <tr>
        <td><div class="pcell"><div class="pthumb"><%=emSh[shi%emSh.length]%></div><div><div class="pname"><%=safe(s.product_name)%></div><div class="pid" style="font-family:monospace;color:var(--accent)"><%=safe(s.tracking_number)%></div></div></div></td>
        <td><strong><%=safe(s.order_id)%></strong></td>
        <td><div style="font-weight:700"><%=safe(s.customer_name)%></div><%if(s.customer_phone!=null&&!s.customer_phone.isEmpty()){%><div style="font-size:11.5px;color:var(--slate)"><%=safe(s.customer_phone)%></div><%}%></td>
        <td><div style="font-weight:700"><%=safe(s.dispatch_date)%></div><div style="font-size:11.5px;color:var(--slate)"><%=safe(s.dispatch_time)%></div></td>
        <td style="color:var(--success);font-weight:700"><%=safe(s.expected_delivery)%></td>
        <td><%=s.agent_name!=null?safe(s.agent_name):"<span style='color:var(--mist)'>Unassigned</span>"%></td>
        <td><span class="badge b-<%=sst3%>"><%=sst3.length()>0?sst3.substring(0,1).toUpperCase()+sst3.substring(1):""%></span></td>
        <td><div style="display:flex;gap:5px;flex-wrap:wrap">
          <a href="?<%=isLoggedIn?"email="+sessionEmail+"&viewAs="+sessionRole+"&":""%>section=track&trackInput=<%=safe(s.tracking_number)%>" class="btn bo btn-xs"><i class="fas fa-map-marker-alt"></i> Track</a>
          <%if(!"delivered".equals(sst3)&&!"returned".equals(sst3)&&isAdmin){%>
          <form method="post" action="travel_logistics.jsp" style="display:inline">
            <input type="hidden" name="action" value="markDelivered"><input type="hidden" name="order_id" value="<%=safe(s.order_id)%>">
            <input type="hidden" name="section" value="shipments"><input type="hidden" name="sf" value="<%=sf%>">
            <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
            <button type="submit" class="btn bs btn-xs"><i class="fas fa-check"></i> Delivered</button>
          </form>
          <%}%>
        </div></td>
      </tr>
      <%shi++;}if(fShips.isEmpty()){%><tr><td colspan="8"><div class="empty"><i class="fas fa-truck"></i><p>No shipments found</p></div></td></tr><%}%>
      </tbody>
    </table></div>
  </div>
</div></div>
<%}%>

<%-- ================================================================ DISPATCH SECTION (Admin Only) --%>
<%if(isAdmin){%>
<div id="sec-dispatch" class="section <%="dispatch".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-box"></i> Dispatch Center</div>
  <h1>Dispatch New Shipment</h1><p>Assign a delivery agent and create a shipment. Only <strong>Confirmed</strong> orders can be dispatched.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <%if(!actionMsg.isEmpty()&&"dispatch".equals(action)){%><div class="alert <%=actionOk?"al-ok":"al-err"%>"><%=safe(actionMsg)%></div><%}%>
  <div class="alert al-info"><i class="fas fa-info-circle"></i>Only orders with status <strong>Confirmed</strong> or <strong>Processing</strong> can be dispatched. Sellers must confirm orders first.</div>
  <div class="card">
    <div class="card-header"><div class="card-title"><i class="fas fa-paper-plane"></i> Dispatch Form</div></div>
    <div class="card-body">
      <form method="post" action="travel_logistics.jsp">
        <input type="hidden" name="action" value="dispatch"><input type="hidden" name="section" value="shipments">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <div class="frow">
          <div class="fg2"><label class="flbl">Order ID *</label><div class="ig"><i class="fas fa-hashtag"></i><input type="text" name="d_orderid" class="fc" placeholder="e.g. ORD-1770894348471" required value="<%=safe(request.getParameter("prefill")!=null?request.getParameter("prefill"):"")%>"></div></div>
          <div class="fg2"><label class="flbl">Product Name *</label><div class="ig"><i class="fas fa-box-open"></i><input type="text" name="d_product" class="fc" placeholder="e.g. Wireless Earbuds" required></div></div>
          <div class="fg2"><label class="flbl">Customer Name *</label><div class="ig"><i class="fas fa-user"></i><input type="text" name="d_customer" class="fc" placeholder="e.g. Ravi Shankar" required></div></div>
          <div class="fg2"><label class="flbl">Customer Phone</label><div class="ig"><i class="fas fa-phone"></i><input type="text" name="d_phone" class="fc" placeholder="9900000099"></div></div>
        </div>
        <div class="fg2"><label class="flbl">Delivery Address *</label><div class="ig"><i class="fas fa-map-marker-alt"></i><input type="text" name="d_address" class="fc" placeholder="Full delivery address" required></div></div>
        <div class="frow3">
          <div class="fg2"><label class="flbl">Dispatch Date *</label><input type="date" name="d_date" class="fc" required></div>
          <div class="fg2"><label class="flbl">Dispatch Time</label><input type="time" name="d_time" class="fc"></div>
          <div class="fg2"><label class="flbl">Expected Delivery *</label><input type="date" name="d_delivery_date" class="fc" required></div>
        </div>
        <div class="frow">
          <div class="fg2"><label class="flbl">Delivery Agent</label>
            <select name="d_agent" class="fc">
              <option value="">-- Select Agent --</option>
              <%try{List<Agent>activeAg=getAgents(true);for(Agent a:activeAg){%>
              <option value="<%=safe(a.agent_id)%>"><%=safe(a.agent_name)%> (<%=safe(a.agent_id)%>) — <%=a.zone!=null?safe(a.zone):safe(a.vehicle_type)%></option>
              <%}}catch(Exception ig){}%>
            </select>
          </div>
          <div class="fg2"><label class="flbl">Transport Mode</label>
            <select name="d_transport" class="fc"><option>Road -- Delivery Van</option><option>Road -- Motorcycle</option><option>Air Cargo</option><option>Train Cargo</option></select>
          </div>
        </div>
        <button type="submit" class="btn bp"><i class="fas fa-paper-plane"></i> Dispatch Shipment</button>
      </form>
    </div>
  </div>
</div></div>
<%}%>

<%-- ================================================================ RETURNS SECTION --%>
<div id="sec-returns" class="section <%="returns".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-rotate-left"></i> Returns</div>
  <h1>Return Requests</h1><p><%=isCustomer?"Manage your return requests for delivered orders.":"Review and process return requests from customers."%></p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <%if(!actionMsg.isEmpty()&&("submitReturn".equals(action)||"cancelReturn".equals(action)||"updateReturnStatus".equals(action))){%><div class="alert <%=actionOk?"al-ok":"al-err"%>"><%=safe(actionMsg)%></div><%}%>
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:18px;flex-wrap:wrap;gap:9px">
    <div style="font-family:'Syne',sans-serif;font-size:17px;font-weight:800;color:var(--ink)"><i class="fas fa-rotate-left" style="margin-right:7px;color:var(--danger)"></i>Returns (<%=allReturns.size()%>)</div>
    <%if(isCustomer){%><button class="btn bd" onclick="document.getElementById('retModal').classList.add('open')"><i class="fas fa-plus"></i> New Return Request</button><%}%>
  </div>
  <%if(allReturns.isEmpty()){%>
  <div class="empty"><i class="fas fa-rotate-left"></i><p>No return requests</p><span><%=isCustomer?"No returns submitted yet.":"No customer returns."%></span></div>
  <%}else{%>
  <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(380px,1fr));gap:14px">
  <%for(ReturnReq r:allReturns){String rst=raw(r.return_status);String rstCap=rst.length()>0?rst.substring(0,1).toUpperCase()+rst.substring(1):"";%>
  <div class="rcard">
    <div style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:11px">
      <div><div style="font-family:'Syne',sans-serif;font-size:15px;font-weight:800">Return #<%=r.return_id%></div><div style="font-size:12px;color:var(--slate);margin-top:2px">Order: <strong><%=safe(r.order_id)%></strong> · Product ID: <%=r.product_id%></div></div>
      <span class="badge b-<%=rst%>"><%=rstCap%></span>
    </div>
    <div style="background:var(--surface);border-radius:8px;padding:11px 13px;margin-bottom:11px">
      <div style="font-size:12.5px;color:var(--slate);margin-bottom:4px"><i class="fas fa-user" style="margin-right:4px;color:var(--accent)"></i><strong>Customer:</strong> <%=safe(r.customer_email)%></div>
      <%if(r.seller_email!=null&&!r.seller_email.isEmpty()){%><div style="font-size:12.5px;color:var(--slate);margin-bottom:4px"><i class="fas fa-store" style="margin-right:4px;color:var(--accent2)"></i><strong>Seller:</strong> <%=safe(r.seller_email)%></div><%}%>
      <div style="font-size:12.5px;font-weight:700;color:var(--danger);background:#fee2e2;padding:6px 9px;border-radius:7px;margin-top:5px"><i class="fas fa-exclamation-triangle" style="margin-right:5px"></i><%=safe(r.return_reason)%></div>
      <%if(r.return_description!=null&&!r.return_description.isEmpty()){%><div style="font-size:12px;color:var(--slate);margin-top:5px;font-style:italic">"<%=safe(r.return_description)%>"</div><%}%>
    </div>
    <div style="font-size:11.5px;color:var(--slate);margin-bottom:9px">Submitted: <%=safe(r.created_at)%></div>
    <div style="display:flex;gap:7px;flex-wrap:wrap">
      <%if(isCustomer&&"Pending".equals(rst)){%>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="cancelReturn"><input type="hidden" name="r_return_id" value="<%=r.return_id%>">
        <input type="hidden" name="section" value="returns"><%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bg btn-sm" onclick="return confirm('Cancel this return?')"><i class="fas fa-times"></i> Cancel</button>
      </form>
      <%}%>
      <%if((isSeller||isAdmin)&&!"Completed".equals(rst)&&!"Rejected".equals(rst)){%>
      <%if("Pending".equals(rst)){%>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="updateReturnStatus"><input type="hidden" name="r_return_id" value="<%=r.return_id%>">
        <input type="hidden" name="r_new_status" value="Approved"><input type="hidden" name="section" value="returns">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bs btn-sm"><i class="fas fa-check"></i> Approve</button>
      </form>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="updateReturnStatus"><input type="hidden" name="r_return_id" value="<%=r.return_id%>">
        <input type="hidden" name="r_new_status" value="Rejected"><input type="hidden" name="section" value="returns">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bd btn-sm"><i class="fas fa-times"></i> Reject</button>
      </form>
      <%}else if("Approved".equals(rst)){%>
      <form method="post" action="travel_logistics.jsp" style="display:inline">
        <input type="hidden" name="action" value="updateReturnStatus"><input type="hidden" name="r_return_id" value="<%=r.return_id%>">
        <input type="hidden" name="r_new_status" value="Completed"><input type="hidden" name="section" value="returns">
        <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
        <button type="submit" class="btn bp btn-sm"><i class="fas fa-box-open"></i> Mark Completed</button>
      </form>
      <%}%>
      <%}%>
    </div>
  </div>
  <%}%>
  </div>
  <%}%>
</div></div>

<%-- ================================================================ AGENTS SECTION (Admin) --%>
<%if(isAdmin){%>
<div id="sec-agents" class="section <%="agents".equals(sec)?"active":""%>">
<div class="hero"><div class="hero-inner">
  <div class="h-eyebrow"><i class="fas fa-user-tie"></i> Agent Management</div>
  <h1>Delivery Agents</h1><p>Approve pending registrations, monitor performance, and manage agent status.</p>
</div><div class="hero-wave"></div></div>
<div class="container py">
  <%if(!actionMsg.isEmpty()&&"agentApprove".equals(action)){%><div class="alert <%=actionOk?"al-ok":"al-err"%>"><%=safe(actionMsg)%></div><%}%>

  <%-- Pending agents alert --%>
  <%try{List<Agent>allAg=getAgents(false);int pendingCount=0;for(Agent a:allAg){if("Pending".equals(a.agent_status))pendingCount++;}
    if(pendingCount>0){%>
  <div class="alert al-warn"><i class="fas fa-clock"></i><strong><%=pendingCount%> agent(s) pending approval.</strong> Review and activate them below.</div>
  <%}}catch(Exception ig){}%>

  <div class="card">
    <div class="card-header"><div class="card-title"><i class="fas fa-user-tie"></i> All Delivery Agents</div>
      <a href="agent_register.jsp" target="_blank" class="btn bp btn-sm"><i class="fas fa-user-plus"></i> Agent Register Page</a>
    </div>
    <div class="tw">
      <table>
        <thead><tr><th>Agent</th><th>ID</th><th>Email</th><th>Zone</th><th>Vehicle</th><th>Total</th><th>Completed</th><th>Performance</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
        <%try{List<Agent>allAg2=getAgents(false);if(allAg2.isEmpty()){%>
        <tr><td colspan="10"><div class="empty"><i class="fas fa-user-tie"></i><p>No agents found</p></div></td></tr>
        <%}for(Agent a:allAg2){int pct=a.total_deliveries>0?(int)((double)a.completed_deliveries/a.total_deliveries*100):0;%>
        <tr>
          <td><div style="display:flex;align-items:center;gap:10px">
            <div style="width:38px;height:38px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent2));display:flex;align-items:center;justify-content:center;color:#fff;font-weight:800;font-size:15px;flex-shrink:0"><%=a.agent_name!=null?String.valueOf(a.agent_name.charAt(0)):"?"%></div>
            <div><div style="font-weight:700"><%=safe(a.agent_name)%></div><%if(a.phone!=null&&!a.phone.isEmpty()){%><div style="font-size:11.5px;color:var(--slate)"><%=safe(a.phone)%></div><%}%></div>
          </div></td>
          <td><strong style="font-family:monospace"><%=safe(a.agent_id)%></strong></td>
          <td style="font-size:12px;color:var(--slate)"><%=a.email!=null?safe(a.email):"—"%></td>
          <td><%=a.zone!=null?safe(a.zone):"—"%></td>
          <td><i class="fas fa-<%="Motorcycle".equals(a.vehicle_type)?"motorcycle":"truck"%>" style="margin-right:5px;color:var(--accent)"></i><%=safe(a.vehicle_type)%></td>
          <td style="font-weight:800"><%=a.total_deliveries%></td>
          <td style="font-weight:800;color:var(--success)"><%=a.completed_deliveries%></td>
          <td style="min-width:120px"><div style="display:flex;align-items:center;gap:7px"><div style="flex:1;background:var(--border);border-radius:50px;height:6px;overflow:hidden"><div style="width:<%=pct%>%;height:100%;background:linear-gradient(90deg,var(--accent),var(--accent2));border-radius:50px"></div></div><span style="font-size:12.5px;font-weight:800;color:var(--accent)"><%=pct%>%</span></div></td>
          <td>
           <% String asc = raw(a.agent_status); boolean isActiveOrEmpty = "Active".equals(asc) || asc.isEmpty(); %>
            <span class="badge <%="Active".equals(a.agent_status)?"b-Active":"Pending".equals(a.agent_status)?"b-agent-Pending":"b-Inactive"%>"><%=safe(a.agent_status)%></span>
          </td>
          <td><div style="display:flex;gap:5px;flex-wrap:wrap">
            <%if("Pending".equals(a.agent_status)){%>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="agentApprove"><input type="hidden" name="a_agent_id" value="<%=safe(a.agent_id)%>">
              <input type="hidden" name="a_new_status" value="Active"><input type="hidden" name="section" value="agents">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bs btn-xs"><i class="fas fa-check"></i> Approve</button>
            </form>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="agentApprove"><input type="hidden" name="a_agent_id" value="<%=safe(a.agent_id)%>">
              <input type="hidden" name="a_new_status" value="Inactive"><input type="hidden" name="section" value="agents">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bd btn-xs"><i class="fas fa-times"></i> Reject</button>
            </form>
            <%}else if("Active".equals(a.agent_status)){%>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="agentApprove"><input type="hidden" name="a_agent_id" value="<%=safe(a.agent_id)%>">
              <input type="hidden" name="a_new_status" value="Inactive"><input type="hidden" name="section" value="agents">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bd btn-xs"><i class="fas fa-ban"></i> Deactivate</button>
            </form>
            <%}else if("Inactive".equals(a.agent_status)){%>
            <form method="post" action="travel_logistics.jsp" style="display:inline">
              <input type="hidden" name="action" value="agentApprove"><input type="hidden" name="a_agent_id" value="<%=safe(a.agent_id)%>">
              <input type="hidden" name="a_new_status" value="Active"><input type="hidden" name="section" value="agents">
              <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
              <button type="submit" class="btn bs btn-xs"><i class="fas fa-check"></i> Re-Activate</button>
            </form>
            <%}%>
          </div></td>
        </tr>
        <%}}catch(Exception ig2){}%>
        </tbody>
      </table>
    </div>
  </div>
</div></div>
<%}%>

<%-- ================================================================ RETURN MODAL (Customer) --%>
<%if(isCustomer||!isLoggedIn){%>
<div class="modal-ov" id="retModal">
  <div class="modal-box">
    <div class="mhead">
      <div class="mtitle"><i class="fas fa-rotate-left" style="margin-right:8px;color:var(--danger)"></i>Submit Return Request</div>
      <button class="mclose" onclick="document.getElementById('retModal').classList.remove('open')"><i class="fas fa-times"></i></button>
    </div>
    <form method="post" action="travel_logistics.jsp">
      <input type="hidden" name="action" value="submitReturn"><input type="hidden" name="section" value="returns">
      <%if(isLoggedIn){%><input type="hidden" name="email" value="<%=sessionEmail%>"><input type="hidden" name="viewAs" value="<%=sessionRole%>"><%}%>
      <div class="fg2"><label class="flbl">Order ID *</label><div class="ig"><i class="fas fa-hashtag"></i><input type="text" name="r_order_id" id="r_oid" class="fc" placeholder="ORD-XXXX" required></div></div>
      <div class="fg2"><label class="flbl">Product ID * <span style="font-size:10.5px;color:var(--mist)">(numeric)</span></label><div class="ig"><i class="fas fa-box"></i><input type="number" name="r_product_id" id="r_pid" class="fc" placeholder="e.g. 13" required min="1"></div></div>
      <div class="fg2"><label class="flbl">Seller Email <span style="font-size:10.5px;color:var(--mist)">(optional)</span></label><div class="ig"><i class="fas fa-envelope"></i><input type="email" name="r_seller_email" id="r_sem" class="fc" placeholder="seller@example.com"></div></div>
      <div class="fg2"><label class="flbl">Reason for Return *</label>
        <select name="r_reason" class="fc" required>
          <option value="">-- Select Reason --</option>
          <option>Damaged or defective product</option>
          <option>Wrong item delivered</option>
          <option>Product not as described</option>
          <option>Changed mind / Not needed</option>
          <option>Late delivery</option>
          <option>Size / Fit issue</option>
          <option>Missing parts or accessories</option>
        </select>
      </div>
      <div class="fg2"><label class="flbl">Additional Description</label><textarea name="r_description" class="fc" rows="3" placeholder="Describe the issue…" style="resize:vertical"></textarea></div>
      <div class="alert al-info" style="font-size:12px;margin-bottom:14px"><i class="fas fa-info-circle"></i>Returns are only allowed for <strong>Delivered</strong> orders. Seller reviews within 2-3 business days.</div>
      <button type="submit" class="btn bd" style="width:100%;justify-content:center"><i class="fas fa-rotate-left"></i> Submit Return Request</button>
    </form>
  </div>
</div>
<%}%>

<!-- DB MIGRATION SQL NOTE modal trigger for admin -->

<!-- TOAST -->
<div class="toast-stack" id="ts"></div>

<script>
function showToast(msg,type){
  const s=document.getElementById('ts'),t=document.createElement('div');
  t.className='toast'+(type==='err'?' err':'');
  t.innerHTML='<i class="fas '+(type==='err'?'fa-exclamation-circle':'fa-check-circle')+'" style="color:'+(type==='err'?'var(--danger)':'var(--success)')+'"></i>'+msg;
  s.appendChild(t);setTimeout(()=>{t.style.transition='all .4s';t.style.opacity='0';t.style.transform='translateX(28px)';setTimeout(()=>t.remove(),400)},4500);
}
<%if(!actionMsg.isEmpty()){%>
window.addEventListener('DOMContentLoaded',()=>showToast('<%=actionMsg.replace("'","\\'").replace("\"","&quot;").replace("\n"," ")%>','<%=actionOk?"ok":"err"%>'));
<%}%>
function openRet(oid,pid,pname,sem){
  const o=document.getElementById('r_oid'),p=document.getElementById('r_pid'),s=document.getElementById('r_sem');
  if(o)o.value=oid||''; if(p&&pid)p.value=pid; if(s&&sem)s.value=sem;
  document.getElementById('retModal').classList.add('open');
}
document.querySelectorAll('.modal-ov').forEach(m=>m.addEventListener('click',e=>{if(e.target===m)m.classList.remove('open');}));
document.addEventListener('keydown',e=>{if(e.key==='Escape')document.querySelectorAll('.modal-ov.open').forEach(m=>m.classList.remove('open'));});
window.addEventListener('DOMContentLoaded',()=>{
  const now=new Date(),fut=new Date(now);fut.setDate(fut.getDate()+3);
  const fmt=d=>d.toISOString().split('T')[0];
  const tstr=now.toTimeString().slice(0,5);
  [['d_time',tstr],['d_date',fmt(now)],['d_delivery_date',fmt(fut)]].forEach(([n,v])=>{const el=document.querySelector('[name="'+n+'"]');if(el&&!el.value)el.value=v;});
});
</script>
</body>
</html>
