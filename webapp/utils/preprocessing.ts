import { FileData } from '@/types';

/**
 * Sanitizes a single file name: replaces spaces and unsafe characters
 * with underscores, collapses consecutive underscores, and trims.
 */
function sanitizeSingle(name: string): string {
  // Replace any non-alphanumeric (except . - _) characters with underscore
  let sanitized = name.replace(/[^a-zA-Z0-9.\-_]/g, '_');
  // Collapse multiple underscores
  sanitized = sanitized.replace(/_+/g, '_');
  // Trim leading/trailing underscores from the base name (keep extension)
  const dotIndex = sanitized.lastIndexOf('.');
  const base = dotIndex >= 0 ? sanitized.slice(0, dotIndex) : sanitized;
  const ext = dotIndex >= 0 ? sanitized.slice(dotIndex) : '';
  return base.replace(/^_+|_+$/g, '') + ext;
}

/**
 * SHA-1 hash a string using the Web Crypto API (browser-compatible).
 */
async function sha1(text: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(text);
  const hashBuffer = await crypto.subtle.digest('SHA-1', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Sanitize file names in a list of FileData.
 * If the sanitized name bytes exceed 1000, the base is replaced by its SHA-1 hash.
 * Mirrors lib/components/preprocessing.dart
 */
export async function sanitizeFileNames(files: FileData[]): Promise<FileData[]> {
  return Promise.all(
    files.map(async (file) => {
      let name = sanitizeSingle(file.name);
      const dotIndex = name.lastIndexOf('.');
      const base = dotIndex >= 0 ? name.slice(0, dotIndex) : name;
      const ext = dotIndex >= 0 ? name.slice(dotIndex) : '';

      if (new TextEncoder().encode(name).length > 1000) {
        const hash = await sha1(base);
        name = hash + ext;
      }

      return { ...file, name };
    })
  );
}
