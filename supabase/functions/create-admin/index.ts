import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const OWNER_EMAIL = "hamed.soltani714@gmail.com";

const allowedPermissions = [
  "manage_content",
  "publish_content",
  "manage_users",
  "manage_bookings",
];

function response(
  status: number,
  data: Record<string, unknown>,
) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return response(405, {
      success: false,
      error: "Method not allowed",
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return response(500, {
        success: false,
        error: "Server configuration is incomplete",
      });
    }

    const authorization = req.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return response(401, {
        success: false,
        error: "Authentication required",
      });
    }

    const token = authorization.substring(7).trim();

    if (!token) {
      return response(401, {
        success: false,
        error: "Invalid access token",
      });
    }

    // Verify the caller using their access token.
    const authClient = createClient(supabaseUrl, anonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const {
      data: { user: caller },
      error: authError,
    } = await authClient.auth.getUser(token);

    if (authError || !caller) {
      return response(401, {
        success: false,
        error: "Invalid or expired session",
      });
    }

    // Service-role client is used only inside this server function.
    const adminClient = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      },
    );

    // Only the owner account can create administrators.
    const { data: ownerProfile, error: ownerError } =
      await adminClient
        .from("profiles")
        .select("role")
        .eq("id", caller.id)
        .maybeSingle();

    if (
      ownerError ||
      ownerProfile?.role !== "owner" ||
      caller.email?.toLowerCase() !== OWNER_EMAIL
    ) {
      return response(403, {
        success: false,
        error: "Only the project owner can create administrators",
      });
    }

    const body = await req.json();

    const email =
      typeof body.email === "string"
        ? body.email.trim().toLowerCase()
        : "";

    if (
      !email ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    ) {
      return response(400, {
        success: false,
        error: "A valid email address is required",
      });
    }

    if (email === OWNER_EMAIL) {
      return response(400, {
        success: false,
        error: "The owner account cannot be changed into an administrator",
      });
    }

    // Accept only known permission names and boolean values.
    const requestedPermissions =
      body.permissions &&
      typeof body.permissions === "object" &&
      !Array.isArray(body.permissions)
        ? body.permissions
        : {};

    const permissions: Record<string, boolean> = {};

    for (const key of allowedPermissions) {
      permissions[key] = requestedPermissions[key] === true;
    }

    // Send the Supabase invitation.
    const { data: invitation, error: inviteError } =
      await adminClient.auth.admin.inviteUserByEmail(email);

    if (inviteError || !invitation.user) {
      return response(400, {
        success: false,
        error: inviteError?.message ?? "Could not send invitation",
      });
    }

    // The database trigger creates the initial profile.
    // Upsert ensures the invited user receives the admin role.
    const { error: profileError } = await adminClient
      .from("profiles")
      .upsert(
        {
          id: invitation.user.id,
          email,
          role: "admin",
          permissions,
        },
        {
          onConflict: "id",
        },
      );

    if (profileError) {
      return response(500, {
        success: false,
        error: "Invitation sent, but administrator profile setup failed",
        details: profileError.message,
      });
    }

    return response(200, {
      success: true,
      message: "Administrator invitation sent successfully",
      email,
      permissions,
    });
  } catch (error) {
    return response(500, {
      success: false,
      error: error instanceof Error
        ? error.message
        : "Unexpected server error",
    });
  }
});
