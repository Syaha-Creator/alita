const admin = require("firebase-admin");
const {onCall} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

// ── Secrets (scheduled reminder) — set via:
//   firebase functions:secrets:set API_BASE_URL
//   firebase functions:secrets:set CLIENT_ID
//   firebase functions:secrets:set CLIENT_SECRET
//   firebase functions:secrets:set SCHEDULER_EMAIL
//   firebase functions:secrets:set SCHEDULER_PASSWORD
//   firebase functions:secrets:set APPROVER_USER_IDS
// Value APPROVER_USER_IDS: comma-separated numeric user IDs to check hourly.
const secretApiBaseUrl = defineSecret("API_BASE_URL");
const secretClientId = defineSecret("CLIENT_ID");
const secretClientSecret = defineSecret("CLIENT_SECRET");
const secretSchedulerEmail = defineSecret("SCHEDULER_EMAIL");
const secretSchedulerPassword = defineSecret("SCHEDULER_PASSWORD");
const secretApproverUserIds = defineSecret("APPROVER_USER_IDS");

/**
 * Builds FCM payload for approval-related pushes.
 * @param {object} data — token, sp_number, sender_name, type, pending_count (optional)
 */
function buildMessagingPayload(data) {
  const targetToken = data.token;
  const orderLetterNo = data.sp_number || "";
  const orderLetterId =
    data.order_letter_id !== undefined && data.order_letter_id !== null
      ? String(data.order_letter_id)
      : "";
  const senderName = data.sender_name || "";
  const type = data.type || "next_approver";
  const pendingCountRaw = data.pending_count;
  const pendingCount =
    pendingCountRaw !== undefined && pendingCountRaw !== null && pendingCountRaw !== ""
      ? parseInt(String(pendingCountRaw), 10) || 1
      : 1;

  let title;
  let body;
  if (type === "fully_approved") {
    title = "SP Disetujui Sepenuhnya!";
    body =
      `Hore! Surat Pesanan [${orderLetterNo}] Anda telah disetujui sepenuhnya.`;
  } else if (type === "rejected") {
    title = "SP Ditolak";
    body = `Surat Pesanan [${orderLetterNo}] ditolak oleh ${senderName}.`;
  } else if (type === "reminder") {
    title = "Pengingat Persetujuan";
    body =
      pendingCount === 1
        ? "Anda memiliki 1 SP menunggu persetujuan."
        : `Anda memiliki ${pendingCount} SP menunggu persetujuan.`;
  } else {
    title = "Persetujuan Diperlukan";
    body =
      `SP [${orderLetterNo}] menunggu persetujuan Anda (dari ${senderName}).`;
  }

  return {
    token: targetToken,
    notification: {title, body},
    data: {
      type,
      order_letter_no: orderLetterNo,
      order_letter_id: orderLetterId,
      pending_count: String(pendingCountRaw ?? ""),
    },
    android: {
      priority: "high",
      notification: {
        sound: "default",
        channelId: "approval_channel",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };
}

exports.sendApprovalNotification = onCall(
    {region: "asia-southeast2"},
    async (request) => {
      const data = request.data;
      const targetToken = data.token;
      if (!targetToken) {
        return {success: false, message: "Token kosong"};
      }

      const payload = buildMessagingPayload(data);

      try {
        await admin.messaging().send(payload);
        console.log(
            `FCM sent [${data.type || "next_approver"}] to token ...` +
            `${String(targetToken).slice(-8)}`,
        );
        return {success: true, type: data.type || "next_approver"};
      } catch (error) {
        console.error("Gagal mengirim FCM:", error);
        const {HttpsError} = require("firebase-functions/v2/https");
        throw new HttpsError("internal", "Gagal kirim FCM");
      }
    },
);

// ── Scheduled: hourly reminder for listed approvers ─────────────────

function joinUrl(base, path) {
  const b = String(base).replace(/\/+$/, "");
  const p = path.startsWith("/") ? path : `/${path}`;
  return b + p;
}

async function signInScheduler(baseUrl, clientId, clientSecret, email, password) {
  const url = new URL(joinUrl(baseUrl, "/sign_in"));
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("client_secret", clientSecret);
  const res = await fetch(url.toString(), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({email, password}),
  });
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error(`sign_in invalid JSON status=${res.status}`);
  }
  if (!res.ok) {
    throw new Error(`sign_in ${res.status}: ${text.slice(0, 300)}`);
  }
  const token = data.token;
  if (!token) {
    throw new Error("sign_in: missing token in response");
  }
  return String(token);
}

async function apiGet(baseUrl, path, accessToken, clientId, clientSecret, query) {
  const url = new URL(joinUrl(baseUrl, path));
  url.searchParams.set("access_token", accessToken);
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("client_secret", clientSecret);
  for (const [k, v] of Object.entries(query || {})) {
    if (v != null && String(v) !== "") {
      url.searchParams.set(k, String(v));
    }
  }
  const res = await fetch(url.toString(), {
    headers: {Accept: "application/json"},
  });
  const text = await res.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error(`GET ${path} invalid JSON status=${res.status}`);
  }
  if (!res.ok) {
    throw new Error(`GET ${path} ${res.status}: ${text.slice(0, 300)}`);
  }
  return data;
}

function normalizeApproved(value) {
  if (value === null || value === undefined) return "pending";
  if (typeof value === "boolean") return value ? "approved" : "rejected";
  const s = String(value).trim().toLowerCase();
  if (["approved", "true", "1"].includes(s)) return "approved";
  if (["rejected", "ditolak", "false", "0"].includes(s)) return "rejected";
  if (s === "pending" || s === "") return "pending";
  return "unknown";
}

function arePriorApprovedByIndex(discounts, myIndex) {
  for (let i = 0; i < myIndex; i++) {
    if (normalizeApproved(discounts[i].approved) !== "approved") {
      return false;
    }
  }
  return true;
}

function headerIsRejected(letter) {
  return normalizeApproved(letter.status) === "rejected";
}

/**
 * Mirrors Flutter ApprovalInboxNotifier inbox split: actionable pending SP count.
 */
function countActionablePendingForUser(rawOrders, currentUserIdStr) {
  const grouped = new Map();
  for (const wrap of rawOrders) {
    if (!wrap || typeof wrap !== "object") continue;
    const letter = wrap.order_letter || {};
    const key = letter.id ?? letter.no_sp ?? JSON.stringify(wrap);
    if (!grouped.has(key)) grouped.set(key, wrap);
  }
  const allOrders = Array.from(grouped.values());
  let pendingSpCount = 0;

  for (const orderWrap of allOrders) {
    let isMyApproval = false;
    let isMyApprovalDone = false;
    let hasActionablePending = false;
    const letter = orderWrap.order_letter || {};
    const details = orderWrap.order_letter_details || [];
    const headerRejected = headerIsRejected(letter);
    let hasRejectedDiscount = false;

    for (const detail of details) {
      const discounts = detail.order_letter_discount || [];
      for (let i = 0; i < discounts.length; i++) {
        const disc = discounts[i];
        const discEnum = normalizeApproved(disc.approved);
        if (discEnum === "rejected") hasRejectedDiscount = true;
        const approverId = String(disc.approver_id ?? "");
        if (!approverId || approverId !== currentUserIdStr) continue;
        isMyApproval = true;
        if (discEnum === "approved" || discEnum === "rejected") {
          isMyApprovalDone = true;
        } else if (discEnum === "pending") {
          if (arePriorApprovedByIndex(discounts, i)) {
            hasActionablePending = true;
          }
        }
      }
    }

    if (!isMyApproval) continue;
    if (headerRejected || hasRejectedDiscount) {
      continue;
    }
    if (hasActionablePending) {
      pendingSpCount++;
    }
  }
  return pendingSpCount;
}

function firstDeviceTokenFromBody(json) {
  const result = json.result;
  if (Array.isArray(result) && result.length > 0) {
    const t = result[0].token;
    return t ? String(t) : null;
  }
  if (result && typeof result === "object" && result.token) {
    return String(result.token);
  }
  return null;
}

exports.checkPendingApprovals = onSchedule(
    {
      schedule: "every 6 hours",
      timeZone: "Asia/Jakarta",
      region: "asia-southeast2",
      secrets: [
        secretApiBaseUrl,
        secretClientId,
        secretClientSecret,
        secretSchedulerEmail,
        secretSchedulerPassword,
        secretApproverUserIds,
      ],
    },
    async () => {
      const baseUrl = secretApiBaseUrl.value();
      const clientId = secretClientId.value();
      const clientSecret = secretClientSecret.value();
      const email = secretSchedulerEmail.value();
      const password = secretSchedulerPassword.value();
      const idsRaw = secretApproverUserIds.value() || "";

      const userIds = idsRaw
          .split(",")
          .map((s) => s.trim())
          .filter((s) => s.length > 0);

      if (userIds.length === 0) {
        console.log(
            "checkPendingApprovals: APPROVER_USER_IDS empty — skip " +
            "(set secret to comma-separated user IDs)",
        );
        return;
      }

      let accessToken;
      try {
        accessToken = await signInScheduler(
            baseUrl,
            clientId,
            clientSecret,
            email,
            password,
        );
      } catch (e) {
        console.error("checkPendingApprovals: sign_in failed", e);
        return;
      }

      for (const uid of userIds) {
        try {
          const inboxJson = await apiGet(
              baseUrl,
              "/order_letter_approvals",
              accessToken,
              clientId,
              clientSecret,
              {user_id: uid},
          );
          const rawOrders = inboxJson.result || [];
          const count = countActionablePendingForUser(rawOrders, uid);
          if (count <= 0) {
            console.log(`checkPendingApprovals: user ${uid} — no pending`);
            continue;
          }

          const tokenJson = await apiGet(
              baseUrl,
              "/device_tokens",
              accessToken,
              clientId,
              clientSecret,
              {user_id: uid},
          );
          const fcmToken = firstDeviceTokenFromBody(tokenJson);
          if (!fcmToken) {
            console.log(`checkPendingApprovals: user ${uid} — no FCM token`);
            continue;
          }

          const payload = buildMessagingPayload({
            token: fcmToken,
            sp_number: "",
            sender_name: "Sistem",
            type: "reminder",
            pending_count: count,
          });

          await admin.messaging().send(payload);
          console.log(
              `checkPendingApprovals: reminder sent user=${uid} count=${count}`,
          );
        } catch (e) {
          console.error(`checkPendingApprovals: user ${uid} failed`, e);
        }
      }
    },
);
