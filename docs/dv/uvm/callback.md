# uvm_callback

## 왜 callback을 쓰나

부모(parent) class의 동작 중간에 **user가 추가 동작을 끼워넣고 싶을 때** 사용한다.

상속 후 **override**로도 가능하지만, 그렇게 하면 케이스마다 매번 상속해야 해서 **class tree가 넓어진다**.
→ 대신 **callback**을 쓰면 상속 없이 동작을 주입할 수 있다.

## 사용 방법

### 1. callback 클래스 정의 — `uvm_callback` 상속

```systemverilog
class print_cb extends uvm_callback;
  virtual function void pre_print(printer p);
    // user 가 끼워넣을 추가 동작
  endfunction
endclass
```

### 2. callback을 쓸 class에서 cb 타입 등록

```systemverilog
// `uvm_register_cb(<현재 class>, <callback class>)
`uvm_register_cb(printer, print_cb)
```

### 3. 실행 코드에서 callback 생성 후 add

```systemverilog
// uvm_callback#(<class>, <cb class>)::add(<class inst>, <cb inst>)
print_cb cb = new("cb");
uvm_callback#(printer, print_cb)::add(p, cb);
```

### 4. class 내부에서 callback 실행

```systemverilog
// `uvm_do_callbacks(<현재 class>, <cb class>, <method>)
`uvm_do_callbacks(printer, print_cb, pre_print(this))
```

!!! tip
    callback도 **다형성(Polymorphism)** 적용이 가능하다 — 같은 cb 타입을 상속해 다양한 동작을 주입할 수 있다.
