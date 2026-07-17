import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("Authorization");

  if (!supabaseUrl || !serviceRoleKey) {
    console.error("Missing required Supabase environment variables.");
    return jsonResponse({ error: "Server configuration error." }, 500);
  }

  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Authentication required." }, 401);
  }

  const accessToken = authorization.replace(/^Bearer\s+/i, "");
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const {
    data: { user },
    error: userError,
  } = await adminClient.auth.getUser(accessToken);

  if (userError || !user) {
    return jsonResponse({ error: "Your session is invalid or expired." }, 401);
  }

  const { error: deleteError } =
    await adminClient.auth.admin.deleteUser(user.id);

  if (deleteError) {
    console.error(`Failed to delete user ${user.id}:`, deleteError);
    return jsonResponse(
      {
        error:
          "Your account could not be deleted. Please contact support if the problem continues.",
      },
      500,
    );
  }

  // Avatar uploads use profile_<user-id>_<timestamp> filenames. Storage is not
  // affected by deleting an auth user, so remove matching objects separately.
  try {
    const { data: avatarFiles, error: listError } = await adminClient.storage
      .from("blog_images")
      .list("avatars", {
        limit: 100,
        search: `profile_${user.id}_`,
      });

    if (listError) {
      throw listError;
    }

    const avatarPaths =
      avatarFiles?.map((file) => `avatars/${file.name}`) ?? [];
    if (avatarPaths.length > 0) {
      const { error: removeError } = await adminClient.storage
        .from("blog_images")
        .remove(avatarPaths);
      if (removeError) {
        throw removeError;
      }
    }
  } catch (storageError) {
    // The account is already deleted; an orphaned avatar must not turn a
    // successful account deletion into an error for the client.
    console.error(`Failed to clean avatars for ${user.id}:`, storageError);
  }

  return jsonResponse({ success: true }, 200);
});
