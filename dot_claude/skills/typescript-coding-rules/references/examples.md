# TypeScript コーディング具体例

## Export方針

### Good: named export

```typescript
export const fetchUser = async (id: string) => {
  // ...
};

export type User = {
  id: string;
  name: string;
};
```

### Bad: default export

```typescript
// NG: default export は避ける
const fetchUser = async (id: string) => {
  // ...
};

export default fetchUser;
```

## 関数の書き方

### Good: アロー関数

```typescript
export const calculateTax = (price: number, rate: number) => {
  return Math.floor(price * rate);
};

export const formatCurrency = (amount: number) => `¥${amount.toLocaleString()}`;
```

### Bad: function宣言

```typescript
// NG: function宣言は使わない
export function calculateTax(price: number, rate: number) {
  return Math.floor(price * rate);
}
```

## 型定義

### Good: 推論に任せる

```typescript
// 戻り値の型は推論に任せる
const getUser = (id: string) => {
  return { id, name: 'User', createdAt: new Date() };
};

// ローカル変数も推論に任せる
const count = 0;
const users = [];
```

### Bad: 推論できる型を明示

```typescript
// NG: 戻り値の型を明示
const getUser = (id: string): { id: string; name: string; createdAt: Date } => {
  return { id, name: 'User', createdAt: new Date() };
};

// NG: 推論できるローカル変数に型を付ける
const count: number = 0;
const users: User[] = [];
```

### Good: 自明な戻り値型を省略

```typescript
// void を返す関数 → 型注釈不要
const deleteUser = async (id: string) => {
  await db.delete(users).where(eq(users.id, id));
};

// ジェネリック引数で推論される → 外側の型注釈不要
const fetchUser = (id: string) =>
  apiClient<User>(`/users/${id}`);

// プリミティブ型を返す → 型注釈不要
const getCondition = (code: number) => {
  const conditions: Record<number, string> = { 0: "Clear" };
  return conditions[code] || "Unknown";
};
```

### Good: 複雑な戻り値型は明示してよい

```typescript
// 複雑なオブジェクトリテラルを返す場合は明示してよい
const listForAdmin = async (d1: D1Database): Promise<{
  items: User[];
  total: number;
  nextCursor: string | null;
  hasMore: boolean;
}> => {
  // ...
};
```

## パスエイリアス

### Good: path alias優先、同階層は相対パス

```typescript
// path aliasを使用
import { Button } from '@/components/Button';
import { useAuth } from '@/hooks/useAuth';

// 同階層のみ相対パス
import { formatDate } from './utils';
import type { Props } from './types';
```

### Bad: 深い相対パス

```typescript
// NG: 深いネストの相対パス
import { Button } from '../../../components/Button';
import { useAuth } from '../../../hooks/useAuth';
```

## データ取得

### Good: fetch関数を定義して呼び出す

```typescript
// api/users.ts
export const fetchUser = async (id: string) => {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error('Failed to fetch user');
  }
  return response.json();
};

// 呼び出し側
const user = await fetchUser(userId);
```

### Bad: 呼び出し側で直接fetch

```typescript
// NG: コンポーネント内で直接fetch
const UserProfile = ({ id }: Props) => {
  useEffect(() => {
    fetch(`/api/users/${id}`)
      .then((res) => res.json())
      .then(setUser);
  }, [id]);
};
```

### Bad: axiosを使用

```typescript
// NG: axiosより標準fetch APIを使う
import axios from 'axios';

const user = await axios.get(`/api/users/${id}`);
```
