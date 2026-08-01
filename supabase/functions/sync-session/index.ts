import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

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

type KanpurClaims = {
  email?: string;
  sub?: string;
  role?: string;
  exp?: number;
  iss?: string;
  user_metadata?: Record<string, unknown>;
  app_metadata?: Record<string, unknown>;
};

type ProfilePayload = {
  name?: string;
  username?: string;
  avatar_url?: string;
  bio?: string;
  headline?: string;
};

function isExistingUserError(
  error: { message?: string; status?: number } | null,
) {
  if (!error) return false;
  const message = (error.message ?? "").toLowerCase();
  return (
    error.status === 422 ||
    message.includes("already") ||
    message.includes("registered") ||
    message.includes("exists")
  );
}

function nonEmpty(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

async function verifyKanpurAccessToken(
  token: string,
): Promise<KanpurClaims> {
  const kanpurJwtSecret = Deno.env.get("KANPUR_JWT_SECRET");
  const kanpurSupabaseUrl = Deno.env.get("KANPUR_SUPABASE_URL");

  // Prefer JWKS (ES256 / new Supabase signing keys).
  const unverified = jose.decodeJwt(token) as KanpurClaims;
  const issuer = unverified.iss?.replace(/\/$/, "");
  const jwksBase =
    (kanpurSupabaseUrl?.replace(/\/$/, "")
      ? `${kanpurSupabaseUrl.replace(/\/$/, "")}/auth/v1`
      : null) ??
    issuer ??
    null;

  if (jwksBase) {
    try {
      const JWKS = jose.createRemoteJWKSet(
        new URL(`${jwksBase}/.well-known/jwks.json`),
      );
      const { payload } = await jose.jwtVerify(token, JWKS);
      return payload as KanpurClaims;
    } catch (jwksError) {
      console.error("JWKS verification failed, trying HS256 fallback:", jwksError);
    }
  }

  // Legacy HS256 JWT secret fallback.
  if (kanpurJwtSecret) {
    const secret = new TextEncoder().encode(kanpurJwtSecret);
    const { payload } = await jose.jwtVerify(token, secret, {
      algorithms: ["HS256"],
    });
    return payload as KanpurClaims;
  }

  throw new Error("Unable to verify Kanpur JWT (no JWKS/HS256 secret).");
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
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.");
    return jsonResponse({ error: "Server configuration error." }, 500);
  }

  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Authentication required." }, 401);
  }

  const kanpurAccessToken = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!kanpurAccessToken) {
    return jsonResponse({ error: "Authentication required." }, 401);
  }

  let claims: KanpurClaims;
  try {
    claims = await verifyKanpurAccessToken(kanpurAccessToken);
  } catch (error) {
    console.error("Failed to verify Kanpur JWT:", error);
    return jsonResponse({ error: "Invalid or expired Kanpur session." }, 401);
  }

  const email = claims.email?.trim().toLowerCase();
  if (!email) {
    return jsonResponse(
      { error: "Kanpur session is missing an email claim." },
      400,
    );
  }

  let profilePayload: ProfilePayload = {};
  try {
    const body = await request.json();
    if (body && typeof body === "object") {
      profilePayload = body as ProfilePayload;
    }
  } catch {
    // Body is optional.
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  // Create ReadMe user when missing; ignore "already registered".
  const displayFromMeta =
    nonEmpty(claims.user_metadata?.full_name) ??
    nonEmpty(claims.user_metadata?.name) ??
    nonEmpty(claims.user_metadata?.username);

  const { data: created, error: createError } = await adminClient.auth.admin
    .createUser({
      email,
      email_confirm: true,
      user_metadata: {
        source: "kanpur_sso",
        kanpur_user_id: claims.sub ?? null,
        full_name:
          nonEmpty(profilePayload.name) ?? displayFromMeta ?? email.split("@")[0],
        name:
          nonEmpty(profilePayload.name) ?? displayFromMeta ?? email.split("@")[0],
        avatar_url: nonEmpty(profilePayload.avatar_url),
      },
    });

  if (createError && !isExistingUserError(createError)) {
    console.error("Failed to create ReadMe user:", createError);
    return jsonResponse({ error: "Unable to create ReadMe user." }, 500);
  }

  // Mint a session without sending email: magic-link token hash → verifyOtp.
  const { data: linkData, error: linkError } = await adminClient.auth.admin
    .generateLink({
      type: "magiclink",
      email,
    });

  if (linkError || !linkData?.properties?.hashed_token) {
    console.error("Failed to generate magic link:", linkError);
    return jsonResponse({ error: "Unable to create ReadMe session." }, 500);
  }

  const { data: sessionData, error: otpError } = await adminClient.auth
    .verifyOtp({
      type: "magiclink",
      token_hash: linkData.properties.hashed_token,
    });

  if (otpError || !sessionData.session) {
    console.error("Failed to verify magic link OTP:", otpError);
    return jsonResponse({ error: "Unable to create ReadMe session." }, 500);
  }

  const session = sessionData.session;
  const userId = created?.user?.id ?? session.user.id;
  const fallbackName = email.split("@")[0] || email;
  const displayName =
    nonEmpty(profilePayload.name) ??
    displayFromMeta ??
    fallbackName;
  const username =
    nonEmpty(profilePayload.username) ??
    email.replace(/[^a-z0-9]/gi, "_").slice(0, 40);
  const avatarUrl = nonEmpty(profilePayload.avatar_url);
  const bio = nonEmpty(profilePayload.bio);
  const headline = nonEmpty(profilePayload.headline);

  // Fill empty profile fields; never wipe values the user already set in ReadMe.
  const { data: existingProfile } = await adminClient
    .from("profiles")
    .select("id, name, username, avatar_url, bio, headline")
    .eq("id", userId)
    .maybeSingle();

  const profileRow = {
    id: userId,
    name: nonEmpty(existingProfile?.name) ?? displayName,
    username: nonEmpty(existingProfile?.username) ?? username,
    avatar_url: nonEmpty(existingProfile?.avatar_url) ?? avatarUrl,
    bio: nonEmpty(existingProfile?.bio) ?? bio,
    headline: nonEmpty(existingProfile?.headline) ?? headline,
  };

  const { error: profileError } = await adminClient
    .from("profiles")
    .upsert(profileRow, { onConflict: "id" });

  if (profileError) {
    console.error("Failed to upsert ReadMe profile:", profileError);
  }

  return jsonResponse(
    {
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      token_type: session.token_type,
      user_id: userId,
      email,
      profile: profileRow,
    },
    200,
  );
});
