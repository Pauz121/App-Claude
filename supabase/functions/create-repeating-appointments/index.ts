import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type Payload = {
  trainer_id: string;
  client_id: string;
  start_date: string;
  end_date: string;
  weekdays: number[];
  time: string;
  duration_minutes: number;
  type: string;
  notes?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Missing Supabase environment" }, 500);
  }

  const payload = (await req.json()) as Payload;
  const validationError = validate(payload);
  if (validationError) {
    return json({ error: validationError }, 400);
  }

  const rows = appointmentRows(payload);
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });

  const token = req.headers.get("Authorization")?.replace("Bearer ", "");
  const { data: userData, error: userError } = token
    ? await supabase.auth.getUser(token)
    : { data: { user: null }, error: new Error("Missing token") };
  if (userError || !userData.user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const { data: trainer, error: trainerError } = await supabase
    .from("trainers")
    .select("id")
    .eq("id", payload.trainer_id)
    .eq("user_id", userData.user.id)
    .maybeSingle();

  if (trainerError || !trainer) {
    return json({ error: "Trainer not allowed" }, 403);
  }

  const { data, error } = await supabase
    .from("appointments")
    .insert(rows)
    .select("*");

  if (error) {
    return json({ error: error.message }, 400);
  }

  return json({ appointments: data ?? [] }, 200);
});

function appointmentRows(payload: Payload) {
  const start = parseDate(payload.start_date);
  const end = parseDate(payload.end_date);
  const rows = [];

  for (let day = new Date(start); day <= end; day.setUTCDate(day.getUTCDate() + 1)) {
    const weekday = day.getUTCDay();
    if (!payload.weekdays.includes(weekday)) continue;

    const startsAt = withTime(day, payload.time);
    const endsAt = new Date(startsAt.getTime() + payload.duration_minutes * 60_000);
    rows.push({
      trainer_id: payload.trainer_id,
      client_id: payload.client_id,
      title: payload.type === "checkin" ? "Check-in Studio" : "Allenamento",
      session_type: payload.type,
      starts_at: startsAt.toISOString(),
      ends_at: endsAt.toISOString(),
      status: "scheduled",
      notes: payload.notes ?? null,
    });
  }

  return rows;
}

function validate(payload: Payload) {
  if (!payload.trainer_id || !payload.client_id) return "trainer_id and client_id are required";
  if (!payload.start_date || !payload.end_date) return "start_date and end_date are required";
  if (!payload.weekdays?.length) return "weekdays must contain at least one day";
  if (!payload.time) return "time is required";
  if (!payload.duration_minutes || payload.duration_minutes <= 0) return "duration_minutes must be positive";
  return null;
}

function parseDate(value: string) {
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime())) throw new Error(`Invalid date: ${value}`);
  return date;
}

function withTime(date: Date, time: string) {
  const [hours, minutes] = time.split(":").map(Number);
  const result = new Date(date);
  result.setUTCHours(hours, minutes, 0, 0);
  return result;
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
