const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const PDFDocument = require("pdfkit");

admin.initializeApp();

// Config via Firebase environment params
const smtpEmail = defineString("SMTP_EMAIL");
const smtpPassword = defineString("SMTP_PASSWORD");

/**
 * Triggers when a new inspection is created in Firestore.
 * Generates a PDF report and emails it to the fleet owner.
 */
exports.onInspectionCreated = onDocumentCreated(
  "inspections/{inspectionId}",
  async (event) => {
    const inspection = event.data.data();
    if (!inspection) return;

    try {
      // Look up the owner to get their email and notification preferences
      const ownerDoc = await admin
        .firestore()
        .collection("users")
        .doc(inspection.ownerId)
        .get();

      if (!ownerDoc.exists) {
        console.log(`Owner ${inspection.ownerId} not found`);
        return;
      }

      const owner = ownerDoc.data();

      // Check if owner has email notifications enabled
      if (!owner.notifyEmail) {
        console.log(`Owner ${owner.name} has email notifications disabled`);
        return;
      }

      if (!owner.email) {
        console.log(`Owner ${owner.name} has no email address`);
        return;
      }

      // Generate PDF
      const pdfBuffer = await generateInspectionPDF(inspection);

      // Send email
      await sendEmail(owner.email, owner.name, inspection, pdfBuffer);

      console.log(
        `Inspection email sent to ${owner.email} for ${inspection.vanRegistration}`
      );
    } catch (error) {
      console.error("Error sending inspection email:", error);
    }
  }
);

/**
 * Generate a professional inspection PDF report.
 */
function generateInspectionPDF(inspection) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 40, size: "A4" });
    const chunks = [];

    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    const isPassed = inspection.status === "passed";
    const date = inspection.date?.toDate
      ? inspection.date.toDate()
      : new Date(inspection.date);
    const dateStr = date.toLocaleDateString("en-GB", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    // ========== HEADER ==========
    doc.fontSize(22).fillColor("#1565C0").text("Fleet Checker", { continued: true });
    doc.fontSize(16).fillColor("#000000").text(`    ${inspection.vanRegistration}`, { align: "right" });
    doc.fontSize(10).fillColor("#757575").text("Vehicle Inspection Report", 40);
    doc.fontSize(9).fillColor("#757575").text(dateStr, { align: "right" });
    doc.moveTo(40, doc.y + 5).lineTo(555, doc.y + 5).strokeColor("#1565C0").lineWidth(2).stroke();
    doc.moveDown(1);

    // ========== STATUS BANNER ==========
    const bannerY = doc.y;
    const bannerColor = isPassed ? "#E8F5E9" : "#FFEBEE";
    const bannerBorder = isPassed ? "#4CAF50" : "#EF5350";
    const bannerText = isPassed ? "INSPECTION PASSED" : "INSPECTION FAILED";
    const textColor = isPassed ? "#2E7D32" : "#C62828";

    doc.rect(40, bannerY, 515, 36).fillAndStroke(bannerColor, bannerBorder);
    doc.fontSize(16).fillColor(textColor).text(bannerText, 40, bannerY + 10, {
      width: 515,
      align: "center",
    });
    doc.y = bannerY + 48;

    // ========== DETAILS ==========
    const details = [
      ["Vehicle Registration", inspection.vanRegistration],
      ["Driver", inspection.driverName],
      ["Date & Time", dateStr],
      ["Mileage", `${inspection.mileage} miles`],
    ];

    doc.rect(40, doc.y, 515, details.length * 22 + 10).fill("#F5F5F5");
    let detailY = doc.y + 8;
    for (const [label, value] of details) {
      doc.fontSize(10).fillColor("#757575").text(label, 52, detailY);
      doc.fontSize(10).fillColor("#000000").text(value, 300, detailY, {
        width: 243,
        align: "right",
      });
      detailY += 22;
    }
    doc.y = detailY + 10;

    // ========== CHECKLIST ==========
    doc.fontSize(13).fillColor("#000000").text("Checklist Results", 40);
    doc.moveDown(0.5);

    const checklist = inspection.checklist || [];

    // Table header
    const tableX = 40;
    const colWidths = [40, 340, 135];
    let rowY = doc.y;

    doc.rect(tableX, rowY, 515, 22).fill("#E3F2FD");
    doc.fontSize(10).fillColor("#000000");
    doc.text("#", tableX + 6, rowY + 6);
    doc.text("Item", tableX + 46, rowY + 6);
    doc.text("Result", tableX + 386, rowY + 6);
    rowY += 22;

    // Table rows
    for (let i = 0; i < checklist.length; i++) {
      const item = checklist[i];
      const isFail = item.status === "fail";

      // Check if we need a new page
      if (rowY > 720) {
        doc.addPage();
        rowY = 40;
      }

      if (isFail) {
        doc.rect(tableX, rowY, 515, 20).fill("#FFEBEE");
      }

      // Grid lines
      doc.rect(tableX, rowY, 515, 20).strokeColor("#BDBDBD").lineWidth(0.5).stroke();

      doc.fontSize(9).fillColor("#000000").text(`${i + 1}`, tableX + 6, rowY + 5);
      doc.text(item.name, tableX + 46, rowY + 5);

      const statusColor =
        item.status === "pass" ? "#2E7D32" : item.status === "fail" ? "#C62828" : "#757575";
      doc.fillColor(statusColor).text(item.status.toUpperCase(), tableX + 386, rowY + 5);
      rowY += 20;
    }
    doc.y = rowY + 10;

    // ========== GENERAL NOTES ==========
    if (inspection.generalNotes) {
      if (doc.y > 680) doc.addPage();
      doc.fontSize(13).fillColor("#000000").text("General Notes", 40);
      doc.moveDown(0.3);
      const notesY = doc.y;
      doc.rect(40, notesY, 515, 40).fillAndStroke("#FFF8E1", "#FFE082");
      doc.fontSize(9).fillColor("#000000").text(inspection.generalNotes, 50, notesY + 8, {
        width: 495,
      });
      doc.y = notesY + 50;
    }

    // ========== FAILED ITEMS DETAIL ==========
    const failedItems = checklist.filter((c) => c.status === "fail");
    if (failedItems.length > 0) {
      if (doc.y > 650) doc.addPage();
      doc.fontSize(13).fillColor("#000000").text("Failed Items Detail", 40);
      doc.moveDown(0.5);

      for (const item of failedItems) {
        if (doc.y > 700) doc.addPage();
        const fY = doc.y;
        doc.rect(40, fY, 515, 35).fillAndStroke("#FFEBEE", "#EF9A9A");
        doc.fontSize(11).fillColor("#C62828").text(item.name, 50, fY + 6);
        if (item.notes) {
          doc.fontSize(9).fillColor("#000000").text(`Notes: ${item.notes}`, 50, fY + 20, {
            width: 495,
          });
        }
        doc.y = fY + 42;
      }
    }

    // ========== SUMMARY ==========
    if (doc.y > 660) doc.addPage();
    doc.moveDown(1);
    doc.fontSize(13).fillColor("#000000").text("Inspection Summary", 40, doc.y, {
      width: 515,
      align: "center",
    });
    doc.moveDown(0.5);

    const passCount = checklist.filter((c) => c.status === "pass").length;
    const failCount = checklist.filter((c) => c.status === "fail").length;
    const naCount = checklist.filter((c) => c.status === "na").length;
    const applicable = checklist.length - naCount;
    const passRate = applicable > 0 ? Math.round((passCount / applicable) * 100) : 0;

    const summaryY = doc.y;
    doc.rect(40, summaryY, 515, 50).strokeColor("#BDBDBD").lineWidth(1).stroke();

    const cols = [
      { label: "Passed", value: `${passCount}`, color: "#2E7D32", x: 105 },
      { label: "Failed", value: `${failCount}`, color: "#C62828", x: 235 },
      { label: "N/A", value: `${naCount}`, color: "#757575", x: 365 },
      { label: "Pass Rate", value: `${passRate}%`, color: "#1976D2", x: 495 },
    ];

    for (const col of cols) {
      doc.fontSize(18).fillColor(col.color).text(col.value, col.x - 40, summaryY + 8, {
        width: 80,
        align: "center",
      });
      doc.fontSize(8).fillColor("#757575").text(col.label, col.x - 40, summaryY + 32, {
        width: 80,
        align: "center",
      });
    }

    // ========== FOOTER ==========
    doc.fontSize(7).fillColor("#9E9E9E").text(
      "Fleet Checker - Vehicle Inspection Report",
      40,
      760,
      { width: 515, align: "center" }
    );

    doc.end();
  });
}

/**
 * Send inspection email with PDF attachment.
 */
async function sendEmail(ownerEmail, ownerName, inspection, pdfBuffer) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: smtpEmail.value(),
      pass: smtpPassword.value(),
    },
  });

  const isPassed = inspection.status === "passed";
  const statusText = isPassed ? "PASSED" : "FAILED";
  const statusEmoji = isPassed ? "✅" : "❌";
  const date = inspection.date?.toDate
    ? inspection.date.toDate()
    : new Date(inspection.date);
  const dateStr = date.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

  const passCount = (inspection.checklist || []).filter(
    (c) => c.status === "pass"
  ).length;
  const failCount = (inspection.checklist || []).filter(
    (c) => c.status === "fail"
  ).length;

  const subject = `${statusEmoji} Inspection ${statusText} — ${inspection.vanRegistration} (${dateStr})`;

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: #1565C0; color: white; padding: 20px; border-radius: 8px 8px 0 0;">
        <h2 style="margin: 0;">Fleet Checker</h2>
        <p style="margin: 5px 0 0; opacity: 0.9;">Vehicle Inspection Report</p>
      </div>

      <div style="padding: 20px; background: ${isPassed ? "#E8F5E9" : "#FFEBEE"}; text-align: center;">
        <h1 style="color: ${isPassed ? "#2E7D32" : "#C62828"}; margin: 0;">
          INSPECTION ${statusText}
        </h1>
      </div>

      <div style="padding: 20px; background: #f5f5f5;">
        <table style="width: 100%; border-collapse: collapse;">
          <tr><td style="padding: 8px; color: #757575;">Vehicle</td><td style="padding: 8px; font-weight: bold; text-align: right;">${inspection.vanRegistration}</td></tr>
          <tr><td style="padding: 8px; color: #757575;">Driver</td><td style="padding: 8px; font-weight: bold; text-align: right;">${inspection.driverName}</td></tr>
          <tr><td style="padding: 8px; color: #757575;">Date</td><td style="padding: 8px; font-weight: bold; text-align: right;">${dateStr}</td></tr>
          <tr><td style="padding: 8px; color: #757575;">Mileage</td><td style="padding: 8px; font-weight: bold; text-align: right;">${inspection.mileage} miles</td></tr>
          <tr><td style="padding: 8px; color: #757575;">Passed</td><td style="padding: 8px; font-weight: bold; text-align: right; color: #2E7D32;">${passCount}</td></tr>
          <tr><td style="padding: 8px; color: #757575;">Failed</td><td style="padding: 8px; font-weight: bold; text-align: right; color: #C62828;">${failCount}</td></tr>
        </table>
      </div>

      <div style="padding: 20px; text-align: center; color: #757575; font-size: 12px;">
        <p>The full inspection PDF is attached to this email.</p>
        <p>Open the Fleet Checker app for full details including photos.</p>
      </div>
    </div>
  `;

  const regSafe = inspection.vanRegistration.replace(/[^a-zA-Z0-9]/g, "_");
  const dateSafe = date.toISOString().split("T")[0];

  await transporter.sendMail({
    from: `"Fleet Checker" <${smtpEmail.value()}>`,
    to: ownerEmail,
    subject,
    html,
    attachments: [
      {
        filename: `Inspection_${regSafe}_${dateSafe}.pdf`,
        content: pdfBuffer,
        contentType: "application/pdf",
      },
    ],
  });
}
