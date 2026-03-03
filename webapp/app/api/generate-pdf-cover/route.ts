import { NextRequest, NextResponse } from 'next/server';
import { PDFDocument, StandardFonts, rgb, PageSizes } from 'pdf-lib';
import QRCode from 'qrcode';

/**
 * POST /api/generate-pdf-cover
 * Body: { code: string }
 * Returns: PDF bytes as application/pdf
 *
 * Generates an A4 cover page with a QR code encoding the order code.
 */
export async function POST(req: NextRequest) {
  try {
    const { code } = await req.json();
    if (!code) {
      return NextResponse.json({ error: 'Missing code' }, { status: 400 });
    }

    // Generate QR code as PNG buffer
    const qrPngBuffer = await QRCode.toBuffer(code, {
      type: 'png',
      width: 400,
      margin: 2,
      color: { dark: '#021526', light: '#ffffff' },
    });

    const pdfDoc = await PDFDocument.create();
    const page = pdfDoc.addPage(PageSizes.A4);
    const { width, height } = page.getSize();

    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // Title text
    const titleText = 'RIT Arcade – Order Code';
    const titleSize = 24;
    const titleWidth = font.widthOfTextAtSize(titleText, titleSize);
    page.drawText(titleText, {
      x: (width - titleWidth) / 2,
      y: height / 2 + 160,
      size: titleSize,
      font,
      color: rgb(0.04, 0.2, 0.3),
    });

    // Embed QR code image
    const qrImage = await pdfDoc.embedPng(qrPngBuffer);
    const qrDisplaySize = 200;
    page.drawImage(qrImage, {
      x: (width - qrDisplaySize) / 2,
      y: height / 2 - 60,
      width: qrDisplaySize,
      height: qrDisplaySize,
    });

    // Order code as text below QR for human readability
    const codeSize = 28;
    const codeWidth = font.widthOfTextAtSize(code, codeSize);
    page.drawText(code, {
      x: (width - codeWidth) / 2,
      y: height / 2 - 100,
      size: codeSize,
      font,
      color: rgb(0.43, 0.67, 0.85),
    });

    const pdfBytes = await pdfDoc.save();
    return new NextResponse(Buffer.from(pdfBytes), {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="order_${code}.pdf"`,
      },
    });
  } catch (err) {
    console.error('PDF cover generation error:', err);
    return NextResponse.json(
      { error: 'PDF generation failed', detail: String(err) },
      { status: 500 }
    );
  }
}
