export interface Transaction {
  id: string;
  userId: string;
  amount: number;
  type: 'credit' | 'debit';
  category: string;
  createdAt: string;
}