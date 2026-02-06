export function formatAmount(amount: number): string {
  return amount.toLocaleString('en-IN', { style: 'currency', currency: 'INR' });
}