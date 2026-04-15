import { FileData, Receipt, BindingType, PrintColor, Sides } from '@/types';

const bindingMap: Record<BindingType, number> = {
  [BindingType.spiral]: 1,
  [BindingType.soft]: 2,
  [BindingType.nobinding]: 0,
};

const colorMap: Record<PrintColor, number> = {
  [PrintColor.color]: 1,
  [PrintColor.bw]: 0,
};

const sidesMap: Record<Sides, number> = {
  [Sides.single]: 0,
  [Sides.both]: 1,
  [Sides.four]: 2,
};

/**
 * Sends a price estimate request to the Spring Boot backend.
 * Mirrors lib/utils/get_price.dart
 */
export async function getPrice(files: FileData[]): Promise<Receipt> {
  const url = process.env.NEXT_PUBLIC_API_BASE_URL!;

  const payload = {
    files: files.map((f) => ({
      name: f.name,
      pages: f.pages,
      copies: f.copies,
      binding: bindingMap[f.binding],
      color: colorMap[f.color],
      sides: sidesMap[f.sides],
    })),
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    throw new Error(`Price API returned ${res.status}`);
  }

  return (await res.json()) as Receipt;
}
