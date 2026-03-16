const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendApprovalNotification = functions.https.onCall(async (data) => {
  const targetToken = data.token;
  const orderLetterNo = data.sp_number;
  const senderName = data.sender_name;
  const type = data.type || "next_approver";

  if (!targetToken) {
    return {success: false, message: "Token kosong"};
  }

  const isFullyApproved = type === "fully_approved";

  const payload = {
    token: targetToken,
    notification: {
      title: isFullyApproved
        ? "SP Disetujui Sepenuhnya! 🎉"
        : "Persetujuan Diperlukan 📝",
      body: isFullyApproved
        ? `Hore! Surat Pesanan [${orderLetterNo}] Anda telah disetujui sepenuhnya.`
        : `SP [${orderLetterNo}] menunggu persetujuan Anda (dari ${senderName}).`,
    },
    data: {
      type: type,
      order_letter_no: orderLetterNo || "",
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

  try {
    await admin.messaging().send(payload);
    console.log(`FCM sent [${type}] to token ...${targetToken.slice(-8)}`);
    return {success: true, type: type};
  } catch (error) {
    console.error("Gagal mengirim FCM:", error);
    throw new functions.https.HttpsError("internal", "Gagal kirim FCM");
  }
});
