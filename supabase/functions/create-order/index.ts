import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  let stage = "request";
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  try {
    const authorization = req.headers.get("Authorization") || "";
    const token = authorization.replace(/^Bearer\s+/i, "");
    if (!token) return reply({ error: "Please sign in before placing an order." }, 401);

    const { name, phone, governorate, address, notes, payment_method, payment_reference, items } = await req.json();

    if (typeof name !== "string" || name.trim().length < 2 ||
        typeof phone !== "string" || phone.trim().length < 7 ||
        typeof governorate !== "string" || !governorate.trim() ||
        typeof address !== "string" || address.trim().length < 5 ||
        !Array.isArray(items) || items.length < 1 || items.length > 50) {
      return reply({ error: "Please provide valid customer details and cart items." }, 400);
    }
    if (payment_method !== "cod") {
      return reply({ error: "Only Cash on Delivery is currently available." }, 400);
    }

    const url = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !key || !anonKey) return reply({ error: "Order service is not configured." }, 500);

    const authClient = createClient(url, anonKey, { auth: { persistSession: false } });
    const { data: authData, error: authError } = await authClient.auth.getUser(token);
    if (authError || !authData.user) return reply({ error: "Your session expired. Please sign in again." }, 401);

    stage = "database connection";
    const db = createClient(url, key, { auth: { persistSession: false } });
    const cleanItems = items.map((x: any) => ({
      id: String(x.id ?? ""),
      quantity: Number(x.quantity),
    }));
    if (cleanItems.some((x: any) => !x.id || !Number.isInteger(x.quantity) || x.quantity < 1 || x.quantity > 99)) {
      return reply({ error: "One or more cart quantities are invalid." }, 400);
    }

    const ids = [...new Set(cleanItems.map((x: any) => x.id))];
    stage = "checking products";
    const { data: products, error: productError } = await db
      .from("products").select("id,name,price,active").in("id", ids);
    if (productError) throw productError;
    if (!products || products.length !== ids.length || products.some((p: any) => !p.active)) {
      return reply({ error: "A product in your cart is no longer available. Please refresh the store." }, 409);
    }

    const productMap = new Map(products.map((p: any) => [String(p.id), p]));
    const lines = cleanItems.map((item: any) => {
      const p: any = productMap.get(item.id);
      return { product_id: p.id, product_name: p.name, quantity: item.quantity, unit_price: Number(p.price) };
    });
    const total = lines.reduce((sum: number, item: any) => sum + item.quantity * item.unit_price, 0);
    if (!Number.isFinite(total) || total <= 0) return reply({ error: "Invalid order total." }, 400);

    const orderNumber = "VX-" + Date.now().toString(36).toUpperCase() + "-" + crypto.randomUUID().slice(0, 6).toUpperCase();
    stage = "saving order";
    const { data: order, error: orderError } = await db.from("orders").insert({
      order_number: orderNumber,
      customer_name: name.trim().slice(0, 120),
      phone: phone.trim().slice(0, 30),
      governorate: governorate.trim().slice(0, 80),
      address: address.trim().slice(0, 500),
      payment_method: "cod",
      status: "new",
      total,
    }).select("id,order_number,total").single();
    if (orderError) throw orderError;

    stage = "saving order items";
    const orderLines = lines.map((line: any) => ({ ...line, order_id: order.id }));
    const { error: itemsError } = await db.from("order_items").insert(orderLines);
    if (itemsError) {
      await db.from("orders").delete().eq("id", order.id);
      throw itemsError;
    }

    return reply({ success: true, order_number: order.order_number, total: order.total });
  } catch (error) {
    console.error("create-order error at " + stage + ":", error);
    const detail = error && typeof error === "object"
      ? {
          message: (error as any).message ?? null,
          code: (error as any).code ?? null,
          details: (error as any).details ?? null,
          hint: (error as any).hint ?? null,
        }
      : { message: String(error) };
    return reply({ error: "Order failed at " + stage, details: detail }, 500);
  }
});
