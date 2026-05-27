# uvm_object

`copy()` / `clone()` 등 uvm_object의 핵심 메서드를 다룬다.

## copy() vs clone()

- **`copy()`** : **이미 존재하는** 객체에 내용을 덮어씌운다. → 대상 obj가 미리 있어야 한다.
- **`clone()`** : `new()` + `copy()` 를 한 번에. 새 객체를 만들어 복사하므로 → **기존 obj가 없어도 된다.**

## 예시

```systemverilog
// copy(): 대상이 이미 있어야 함
dst = my_obj::type_id::create("dst");
dst.copy(src);                 // src 내용을 dst에 덮어씌움

// clone(): 새로 만들어서 복사 (대상 불필요)
my_obj cloned;
$cast(cloned, src.clone());    // 내부적으로 new() + copy()
```
