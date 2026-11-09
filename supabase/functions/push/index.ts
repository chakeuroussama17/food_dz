// Push notifications for order changes.
//
// Called by the database (orders_push trigger, through pg_net) with
// { order_id, event, by_customer } and the x-push-secret header.
// Decides who to alert and sends through Firebase Cloud Messaging (HTTP v1).
//
// Secrets (supabase secrets set ...):
//   PUSH_SECRET           same value as private.push_config.secret
//   FCM_SERVICE_ACCOUNT   the Firebase service account JSON (one line)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient } from "jsr:@supabase/supabase-js@2";

type Lang = "fr" | "ar" | "en";
type Msg = { title: string; body: string };
type Who = "restaurant" | "customer" | "driver" | "drivers";

const T: Record<string, Record<Lang, (v: Vars) => Msg>> = {
  newOrder: {
    fr: (v) => ({ title: "Nouvelle commande !", body: `#${v.code} · ${v.amount}. Acceptez-la vite.` }),
    ar: (v) => ({ title: "طلب جديد!", body: `#${v.code} · ${v.amount}. اقبله بسرعة.` }),
    en: (v) => ({ title: "New order!", body: `#${v.code} · ${v.amount}. Accept it quickly.` }),
  },
  accepted: {
    fr: (v) => ({ title: "Commande acceptée", body: `${v.restaurant} prépare votre commande #${v.code}.` }),
    ar: (v) => ({ title: "تم قبول الطلب", body: `${v.restaurant} يحضّر طلبك #${v.code}.` }),
    en: (v) => ({ title: "Order accepted", body: `${v.restaurant} is preparing your order #${v.code}.` }),
  },
  newJob: {
    fr: (v) => ({ title: "Nouvelle course disponible", body: `${v.restaurant} → ${v.area}. Gain : ${v.fee}.` }),
    ar: (v) => ({ title: "توصيلة جديدة متاحة", body: `${v.restaurant} ← ${v.area}. الربح: ${v.fee}.` }),
    en: (v) => ({ title: "New delivery available", body: `${v.restaurant} → ${v.area}. Fee: ${v.fee}.` }),
  },
  driverAssignedOwner: {
    fr: (v) => ({ title: "Livreur en route", body: `${v.driver} récupère la commande #${v.code}.` }),
    ar: (v) => ({ title: "السائق في الطريق", body: `${v.driver} سيستلم الطلب #${v.code}.` }),
    en: (v) => ({ title: "Driver on the way", body: `${v.driver} will pick up order #${v.code}.` }),
  },
  ready: {
    fr: (v) => ({ title: "Commande prête", body: `Votre commande #${v.code} attend le livreur.` }),
    ar: (v) => ({ title: "الطلب جاهز", body: `طلبك #${v.code} بانتظار السائق.` }),
    en: (v) => ({ title: "Order ready", body: `Your order #${v.code} is waiting for the driver.` }),
  },
  readyForPickup: {
    fr: (v) => ({ title: "Commande prête à récupérer", body: `#${v.code} chez ${v.restaurant}.` }),
    ar: (v) => ({ title: "الطلب جاهز للاستلام", body: `#${v.code} عند ${v.restaurant}.` }),
    en: (v) => ({ title: "Ready for pickup", body: `#${v.code} at ${v.restaurant}.` }),
  },
  onTheWay: {
    fr: (v) => ({ title: "En route !", body: `${v.driver} arrive avec votre commande. Préparez ${v.amount}.` }),
    ar: (v) => ({ title: "في الطريق!", body: `${v.driver} قادم بطلبك. جهّز ${v.amount}.` }),
    en: (v) => ({ title: "On the way!", body: `${v.driver} is bringing your order. Have ${v.amount} ready.` }),
  },
  delivered: {
    fr: () => ({ title: "Commande livrée", body: "Bon appétit ! Votre reçu est dans l'application." }),
    ar: () => ({ title: "تم التوصيل", body: "بالهناء والشفاء! إيصالك في التطبيق." }),
    en: () => ({ title: "Order delivered", body: "Enjoy your meal! Your receipt is in the app." }),
  },
  deliveredOwner: {
    fr: (v) => ({ title: "Commande livrée", body: `#${v.code} : ${v.driver} vous doit ${v.food}.` }),
    ar: (v) => ({ title: "تم التوصيل", body: `#${v.code}: على ${v.driver} أن يسلّمك ${v.food}.` }),
    en: (v) => ({ title: "Order delivered", body: `#${v.code}: ${v.driver} owes you ${v.food}.` }),
  },
  rejected: {
    fr: (v) => ({ title: "Commande refusée", body: `#${v.code} : ${v.reason}` }),
    ar: (v) => ({ title: "تم رفض الطلب", body: `#${v.code}: ${v.reason}` }),
    en: (v) => ({ title: "Order rejected", body: `#${v.code}: ${v.reason}` }),
  },
  cancelled: {
    fr: (v) => ({ title: "Commande annulée", body: `#${v.code}${v.reason ? " : " + v.reason : ""}` }),
    ar: (v) => ({ title: "تم إلغاء الطلب", body: `#${v.code}${v.reason ? ": " + v.reason : ""}` }),
    en: (v) => ({ title: "Order cancelled", body: `#${v.code}${v.reason ? ": " + v.reason : ""}` }),
  },
};

const NO_ANSWER: Record<Lang, string> = {
  fr: "le restaurant n'a pas répondu à temps",
  ar: "لم يرد المطعم في الوقت المحدد",
  en: "the restaurant didn't answer in time",
};

type Vars = {
  code: string;
  amount: string;
  food: string;
  fee: string;
  restaurant: string;
  area: string;
  driver: string;
  reason: string;
};

function money(v: number): string {
  return `${String(v).replace(/\B(?=(\d{3})+(?!\d))/g, " ")} DA`;
}

/** Who gets which message for an event. */
function plan(event: string, byCustomer: boolean, hasDriver: boolean): Array<[Who, string]> {
  switch (event) {
    case "placed":
      return [["restaurant", "newOrder"]];
    case "accepted":
      return [["customer", "accepted"], ["drivers", "newJob"]];
    case "available":
      return [["drivers", "newJob"]];
    case "driver_assigned":
      return [["restaurant", "driverAssignedOwner"]];
    case "ready":
      return hasDriver
        ? [["customer", "ready"], ["driver", "readyForPickup"]]
        : [["customer", "ready"], ["drivers", "newJob"]];
    case "picked_up":
      return [["customer", "onTheWay"]];
    case "delivered":
      return [["customer", "delivered"], ["restaurant", "deliveredOwner"]];
    case "rejected":
      return [["customer", "rejected"]];
    case "cancelled":
      return byCustomer
        ? [["restaurant", "cancelled"], ...(hasDriver ? [["driver", "cancelled"] as [Who, string]] : [])]
        : [["customer", "cancelled"], ...(hasDriver ? [["driver", "cancelled"] as [Who, string]] : [])];
    default:
      return [];
  }
}

function route(who: Who, orderId: string): string {
  switch (who) {
    case "restaurant":
      return "/restaurant/orders";
    case "customer":
      return `/orders/${orderId}`;
    case "driver":
      return `/driver/orders/${orderId}`;
    case "drivers":
      return "/driver";
  }
}

// ---------- Google OAuth token for FCM (service account, RS256) ----------
let cached: { token: string; exp: number } | null = null;

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const j = await res.json();
  cached = { token: j.access_token, exp: now + (j.expires_in ?? 3600) };
  return cached.token;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_SECRET");
  if (!secret || req.headers.get("x-push-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }
  const saRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!saRaw) return new Response("push not configured", { status: 200 });
  const sa = JSON.parse(saRaw);

  const { order_id, event, by_customer } = await req.json();
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: o, error } = await db
    .from("orders")
    .select("id, code, customer_id, driver_id, total, food_total, delivery_fee, area, reject_reason, restaurants(name, owner_id)")
    .eq("id", order_id)
    .single();
  if (error || !o) return new Response("order not found", { status: 200 });
  const r = o.restaurants as unknown as { name: string; owner_id: string | null };

  let driverName = "";
  if (o.driver_id) {
    const { data: p } = await db.from("profiles").select("full_name").eq("id", o.driver_id).single();
    driverName = p?.full_name ?? "";
  }

  // Free drivers: approved, online, no delivery in progress.
  async function freeDrivers(): Promise<string[]> {
    const { data: online } = await db.from("drivers").select("id").eq("is_approved", true).eq("is_online", true);
    const ids = (online ?? []).map((d) => d.id as string);
    if (ids.length === 0) return [];
    const { data: busy } = await db
      .from("orders").select("driver_id")
      .in("driver_id", ids).in("status", ["accepted", "ready", "picked_up"]);
    const taken = new Set((busy ?? []).map((b) => b.driver_id as string));
    return ids.filter((id) => !taken.has(id));
  }

  const steps = plan(event, !!by_customer, !!o.driver_id);
  const project = sa.project_id as string;
  let sent = 0;

  for (const [who, key] of steps) {
    const users = who === "restaurant" ? [r.owner_id]
      : who === "customer" ? [o.customer_id]
      : who === "driver" ? [o.driver_id]
      : await freeDrivers();
    const ids = users.filter((u): u is string => !!u);
    if (ids.length === 0) continue;
    const { data: tokens } = await db.from("push_tokens").select("token, lang").in("user_id", ids);
    for (const t of tokens ?? []) {
      const lang = (["fr", "ar", "en"].includes(t.lang) ? t.lang : "fr") as Lang;
      const reason = o.reject_reason === "no_answer" ? NO_ANSWER[lang] : (o.reject_reason ?? "");
      const msg = T[key][lang]({
        code: o.code,
        amount: money(o.total),
        food: money(o.food_total),
        fee: money(o.delivery_fee),
        restaurant: r.name,
        area: o.area || "—",
        driver: driverName,
        reason,
      });
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${await accessToken(sa)}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: msg,
            data: { route: route(who, o.id), order_id: o.id, event },
            android: { priority: "HIGH", notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      });
      if (res.ok) {
        sent++;
      } else if (res.status === 404) {
        // Token no longer valid (app uninstalled...): forget it.
        await db.from("push_tokens").delete().eq("token", t.token);
      } else {
        console.error("fcm", res.status, await res.text());
      }
    }
  }
  return new Response(JSON.stringify({ sent }), { headers: { "Content-Type": "application/json" } });
});
