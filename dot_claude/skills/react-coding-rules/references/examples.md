# React コーディング具体例

## Props定義

### Good: 型名は `Props` で統一

```typescript
type Props = {
  title: string;
  onSubmit: () => void;
};

export const SubmitButton = ({ title, onSubmit }: Props) => {
  return <button onClick={onSubmit}>{title}</button>;
};
```

### Bad: コンポーネント名を含めた型名

```typescript
// NG: xxProps は不要
type SubmitButtonProps = {
  title: string;
  onSubmit: () => void;
};

export const SubmitButton = ({ title, onSubmit }: SubmitButtonProps) => {
  return <button onClick={onSubmit}>{title}</button>;
};
```

## ロジックの分離

### Good: ロジックをコンポーネント外に切り出し

```typescript
const formatPrice = (price: number) => {
  return `¥${price.toLocaleString()}`;
};

const calculateTotal = (items: Item[]) => {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
};

export const CartTotal = ({ items }: Props) => {
  const total = calculateTotal(items);
  return <p>合計: {formatPrice(total)}</p>;
};
```

### Bad: JSX内に複雑なロジック

```typescript
// NG: JSX内でロジックが複雑
export const CartTotal = ({ items }: Props) => {
  return (
    <p>
      合計: ¥
      {items
        .reduce((sum, item) => sum + item.price * item.quantity, 0)
        .toLocaleString()}
    </p>
  );
};
```

## カスタムフック

### Good: 再利用可能なロジックをフックに切り出し

```typescript
// hooks/useToggle.ts
export const useToggle = (initial = false) => {
  const [value, setValue] = useState(initial);
  const toggle = () => setValue((v) => !v);
  return [value, toggle] as const;
};

// components/Modal.tsx
export const Modal = ({ children }: Props) => {
  const [isOpen, toggle] = useToggle();
  return (
    <>
      <button onClick={toggle}>開く</button>
      {isOpen && <div className="modal">{children}</div>}
    </>
  );
};
```

### Bad: 同じロジックを複数コンポーネントで重複

```typescript
// NG: 同じuseStateパターンが複数箇所に
export const Modal = ({ children }: Props) => {
  const [isOpen, setIsOpen] = useState(false);
  const toggle = () => setIsOpen((v) => !v);
  // ...
};

export const Dropdown = ({ children }: Props) => {
  const [isOpen, setIsOpen] = useState(false);
  const toggle = () => setIsOpen((v) => !v);
  // ...
};
```
