import { FileData, BindingType } from '@/types';

/**
 * Calculates estimated processing time in seconds for an order.
 * 1 second per page + 300 seconds per binding job copy.
 * Mirrors lib/components/time_calculation.dart
 */
export function calculateTime(files: FileData[]): number {
  let totalSeconds = 0;
  for (const file of files) {
    totalSeconds += file.pages; // 1s per page
    if (file.binding !== BindingType.nobinding) {
      totalSeconds += 300 * file.copies; // 5 min per binding copy
    }
  }
  return totalSeconds;
}

/**
 * Formats seconds into a human-readable duration string.
 */
export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`;
}
