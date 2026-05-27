# uvm_queue

## 왜 native queue 대신 uvm_queue?

native SystemVerilog queue는 **값 타입(value type)**이라, 대입하거나 인자로 넘길 때마다 큐 **전체가 통째로 복사**된다(mem copy).
반면 `uvm_queue`는 **클래스(uvm_object 기반)**라 **핸들(포인터)**로 다뤄진다 → 큐를 넘길 때 전체 복사 없이 참조만 전달된다.

!!! note "정리"
    uvm_queue를 쓰지 않으면, 큐를 넘길 때마다 항상 mem copy로 전체를 복사해야 하는 부담이 생긴다.

## 사용법

- **타입 결정** : class parameter `T`로 큐에 담을 원소 타입을 지정
- **사용 전 `new()` 필요** (클래스이므로 인스턴스화 필수)
- `push_back()` / `pop_front()` 등 메서드는 일반 queue와 **동일**
- ⚠️ **인덱스로 직접 접근 불가** (`q[idx]` ✗) → **`get(int idx)`** 메서드 사용

## 예시

```systemverilog
uvm_queue #(int) q;        // T = int 로 타입 결정

q = new("q");              // 사용 전 new() 필수

q.push_back(10);
q.push_back(20);           // method 는 일반 queue 와 동일

int v = q.get(0);          // ✗ q[0]   →   ✓ q.get(0)  (인덱스 직접접근 불가)
int f = q.pop_front();
```
