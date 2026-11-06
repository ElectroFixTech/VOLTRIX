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
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);

  try {
    const authorization = req.headers.get("Authorization") || "";
    const token = authorization.replace(/^Bearer\\s+/i, "").trim();
    if (!token) return reply({ error: "Authentication required." }, 401);

    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !serviceKey || !anonKey) {
      return reply({ error: "Customer service is not configured." }, 500);
    }

    // Validate the caller and read their own profile using their session.
    // This follows the same RLS path used by the Admin page login check.
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser(token);
    if (userError || !userData.user) return reply({ error: "Invalid session." }, 401);

    const { data: profile, error: profileError } = await userClient
      .from("profiles").select("role").eq("id", userData.user.id).maybeSingle();
    if (profileError) {
      console.error("list-customers profile check:", profileError);
      return reply({ error: "Could not verify admin role: " + profileError.message }, 500);
    }
    if (profile?.role !== "admin") return reply({ error: "Admin access denied." }, 403);

    // The service-role key is used only for the Auth Admin API.
    const adminClient = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const customers: Array<{
      id: string;
      email: string | null;
      created_at: string;
      email_confirmed_at: string | null;
      last_sign_in_at: string | null;
    }> = [];

    for (let page = 1; page <= 100; page++) {
      const { data, error } = await adminClient.auth.admin.listUsers({ page, perPage: 1000 });
      if (error) {
        console.error("list-customers auth admin listUsers:", error);
        return reply({ error: "Could not load registered accounts: " + error.message }, 500);
      }
      const users = data.users || [];
      customers.push(...users.map((user) => ({
        id: user.id,
        email: user.email || null,
        created_at: user.created_at,
        email_confirmed_at: user.email_confirmed_at || null,
        last_sign_in_at: user.last_sign_in_at || null,
      })));
      if (users.length < 1000) break;
    }

    customers.sort((a, b) => Date.parse(b.created_at) - Date.parse(a.created_at));
    return reply({ success: true, customers });
  } catch (error) {
    console.error("list-customers error:", error);
    const detail = error instanceof Error ? error.message : String(error);
    return reply({ error: "Could not load registered accounts: " + detail }, 500);
  }
});
