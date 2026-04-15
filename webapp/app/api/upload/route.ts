import { NextRequest, NextResponse } from 'next/server';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const r2 = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.CLOUDFLARE_ACCESS_ID!,
    secretAccessKey: process.env.CLOUDFLARE_SECRET_ACCESS_KEY!,
  },
});

const BUCKET = process.env.CLOUDFLARE_BUCKET!;

/**
 * POST /api/upload
 * Accepts multipart/form-data with fields:
 *   - file: Blob/File
 *   - objectKey: string  (e.g., orderId + sanitized filename)
 *   - contentType: string (defaults to application/pdf)
 */
export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get('file') as Blob | null;
    const objectKey = formData.get('objectKey') as string | null;
    const contentType =
      (formData.get('contentType') as string | null) ?? 'application/pdf';

    if (!file || !objectKey) {
      return NextResponse.json(
        { error: 'Missing file or objectKey' },
        { status: 400 }
      );
    }

    const buffer = Buffer.from(await file.arrayBuffer());

    await r2.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: objectKey,
        Body: buffer,
        ContentType: contentType,
      })
    );

    return NextResponse.json({ success: true, key: objectKey });
  } catch (err) {
    console.error('R2 upload error:', err);
    return NextResponse.json(
      { error: 'Upload failed', detail: String(err) },
      { status: 500 }
    );
  }
}
