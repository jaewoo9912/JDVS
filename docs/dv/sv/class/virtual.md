# virtual method/class

## 한 줄 정의

- **`virtual`**     : 핸들이 **실제로 가리키는 객체 타입**(동적 타입)의 메서드 실행
- **non-virtual**   : 핸들이 **선언된 타입**(정적 타입)의 메서드 실행

→ OOP 용어로 **동적 디스패치(dynamic dispatch)** vs **정적 디스패치(static dispatch)**.
**다형성(polymorphism)**의 핵심 메커니즘이다.

## 동작 비교

```systemverilog
class Animal;
  function void speak();        // non-virtual
    $display("Animal sound");
  endfunction
  virtual function void name(); // virtual
    $display("Animal");
  endfunction
endclass

class Dog extends Animal;
  function void speak();        // 이름만 같음 (오버라이드 아님)
    $display("Woof");
  endfunction
  virtual function void name(); // 진짜 오버라이드
    $display("Dog");
  endfunction
endclass

Animal a;
Dog    d = new();
a = d;          // 선언 타입 = Animal, 실제 타입 = Dog

a.speak();      // "Animal sound"  ← 핸들 타입 기준 (정적)
a.name();       // "Dog"           ← 객체 타입 기준 (동적)
```

## 왜 필요한가

- 베이스 클래스 핸들로 받아서 **각자 실제 타입에 맞는 동작**을 시키고 싶을 때
- 컬렉션(queue/array)에 **다양한 서브타입을 담고 일괄 처리**할 때
- 라이브러리/프레임워크가 **사용자 오버라이드를 호출**해야 할 때 (UVM 전체가 이 위에 서있음)

```systemverilog
Animal animals[$] = '{ new Dog(), new Cat() };
foreach (animals[i]) animals[i].name();
// virtual 이어야 Dog, Cat 가 각자 이름 출력. non-virtual 이면 다 "Animal"
```

## 접근 제어자와 조합

| 조합 | 용도 |
| --- | --- |
| `virtual function`            | 공개 + 동적 디스패치 (디폴트 공개 시) |
| `protected virtual function`  | 자식까지 공개 + 동적 디스패치. **가장 흔한 패턴** |
| `local function`              | 이 클래스 전용 헬퍼 (자식이 오버라이드할 일 없음) |

## 자주 하는 실수

- ❌ **non-virtual 메서드를 자식에서 같은 이름으로 선언** → 오버라이드 아닌 별개 메서드. 핸들 타입에 따라 다른 게 호출되는 헷갈리는 버그.
- ❌ **자식에서 `virtual` 키워드 빼고 오버라이드** → 자식 본문은 동작하지만 의도가 안 보임. 모든 오버라이드에 `virtual` 명시하는 게 가독성에 좋음.
- ❌ **함수 시그니처(인자/반환형) 살짝 다른데 오버라이드 의도** → 별개 함수가 됨. 시그니처를 **정확히** 맞춰야 진짜 오버라이드.

## 컨벤션

- 클래스 메서드는 **거의 항상 `virtual` 선언이 안전** (UVM 베스트 프랙티스)
- 자식이 절대 오버라이드 안 한다 **100% 확신할 때만** non-virtual
- 오버라이드 시에도 `virtual` 키워드 **명시 권장** (가독성)
