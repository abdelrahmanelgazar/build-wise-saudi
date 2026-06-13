// Saudi locale number/currency helpers (Arabic UI but Western digits for tables — clearer for cost work)
const nf2 = new Intl.NumberFormat("en-SA", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const nf0 = new Intl.NumberFormat("en-SA", { maximumFractionDigits: 0 });
const nf3 = new Intl.NumberFormat("en-SA", { minimumFractionDigits: 0, maximumFractionDigits: 3 });

export function fmtSAR(value: number | string | null | undefined): string {
  const n = Number(value ?? 0);
  if (!Number.isFinite(n)) return "0.00 ر.س";
  return `${nf2.format(n)} ر.س`;
}

export function fmtNumber(value: number | string | null | undefined, decimals = 2): string {
  const n = Number(value ?? 0);
  if (!Number.isFinite(n)) return "0";
  if (decimals === 0) return nf0.format(n);
  if (decimals === 3) return nf3.format(n);
  return nf2.format(n);
}

export function fmtPct(value: number | string | null | undefined): string {
  return `${fmtNumber(value, 2)}%`;
}
