import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !anonKey || !serviceKey) {
      throw new Error("Supabase environment variables are missing.");
    }

    const authHeader = req.headers.get("Authorization");

    if (!authHeader?.startsWith("Bearer ")) {
      return json({ success: false, error: "Unauthorized" }, 401);
    }

    const token = authHeader.replace("Bearer ", "");

    const authClient = createClient(supabaseUrl, anonKey);

    const { data: authData, error: authError } =
      await authClient.auth.getUser(token);

    if (authError || !authData.user) {
      return json({ success: false, error: "Invalid session" }, 401);
    }

    const adminClient = createClient(supabaseUrl, serviceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const ownerId = authData.user.id;

    const { data: ownerProfile, error: ownerError } =
      await adminClient
        .from("profiles")
        .select("role")
        .eq("id", ownerId)
        .maybeSingle();

    if (
      ownerError ||
      ownerProfile?.role !== "owner" ||
      authData.user.email?.toLowerCase() !==
        "hamed.soltani714@gmail.com"
    ) {
      return json({
        success: false,
        error: "Only the verified owner can create administrators.",
      }, 403);
    }

    const body = await req.json();

    const email = String(body.email || "").trim().toLowerCase();

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json({ success: false, error: "Invalid email address." }, 400);
    }

    if (email === "hamed.soltani714@gmail.com") {
      return json({
        success: false,
        error: "Owner account cannot be changed.",
      }, 400);
    }

    const requested = body.permissions || {};

    const permissions = {
      manage_content: requested.manage_content === true,
      publish_content: requested.publish_content === true,
      manage_users: requested.manage_users === true,
      manage_bookings: requested.manage_bookings === true,
      manage_memberships: requested.manage_memberships === true,
      manage_notifications: requested.manage_notifications === true,
    };

    let targetUser = null;

    for (let page = 1; page <= 20; page++) {
      const { data, error } = await adminClient.auth.admin.listUsers({
        page,
        perPage: 1000,
      });

      if (error) throw error;

      targetUser = data.users.find(
        (user) => user.email?.toLowerCase() === email
      ) ?? null;

      if (targetUser || data.users.length < 1000) break;
    }

    if (!targetUser) {
      const { data, error } = await adminClient.auth.admin.createUser({
        email,
        password: crypto.randomUUID(),
        email_confirm: false,
      });
      if (error) throw error;
      targetUser = data.user;
    }

    if (!targetUser) {
      throw new Error("Could not create or find the invited user.");
    }

    const { error: profileError } = await adminClient
      .from("profiles")
      .upsert({
        id: targetUser.id,
        email,
        role: "admin",
        permissions,
      }, { onConflict: "id" });

    if (profileError) throw profileError;

    // Send a one-time email code. The admin must verify it and set a personal password.
    const { error: otpError } = await authClient.auth.signInWithOtp({
      email,
      options: { shouldCreateUser: false },
    });
    if (otpError) throw otpError;

    return json({
      success: true,
      message: "Administrator created and one-time activation code sent.",
      email,
      permissions,
    });

  } catch (error) {
    console.error("create-admin error:", error);

    return json({
      success: false,
      error: error instanceof Error
        ? error.message
        : "Unexpected server error.",
    }, 500);
  }
});