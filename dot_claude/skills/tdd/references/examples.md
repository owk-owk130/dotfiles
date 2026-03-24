# TDD 具体例

## 良い例：ユーザー検証関数のTDD

### Step 1: テストを先に書く

```typescript
describe('validateEmail', () => {
  it('正常系: 有効なメールアドレスを受け入れる', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('異常系: @がないメールアドレスを拒否する', () => {
    expect(validateEmail('userexample.com')).toBe(false);
  });

  it('異常系: 空文字を拒否する', () => {
    expect(validateEmail('')).toBe(false);
  });
});
```

### Step 2: テスト実行 → 失敗確認

```bash
npm test
# FAIL: validateEmail is not defined
```

### Step 3: 最小限の実装

```typescript
export const validateEmail = (email: string) => {
  if (!email) return false;
  return email.includes('@');
};
```

### Step 4: テスト通過を確認

```bash
npm test
# PASS
```

## アンチパターン

### NG: 実装しながらテストを書く

```typescript
// 実装を先に書いてしまっている
export const validateEmail = (email: string) => {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
};

// 後からテストを追加（TDDではない）
describe('validateEmail', () => {
  it('works', () => {
    expect(validateEmail('test@example.com')).toBe(true);
  });
});
```

### NG: テストが失敗する前に実装を進める

テストを書いた直後に実行せず、すぐ実装に入るのはNG。
必ず「赤」を確認してから「緑」にする。
