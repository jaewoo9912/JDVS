# 깊은 상속(상속 폭발) 문제

> 상속을 여러 층 쌓으면, 클래스 하나가 실제로 어떻게 동작하는지 알려고 **조상 클래스를 전부 거슬러 올라가 봐야** 한다. 해결책은 **1층 상속 + knob**, 또는 **composition(부품 조립)**이다.

---

## 1. 예시 구조

```
base_seq
 └ axi_base_seq
    └ axi_wr_seq
       └ axi_wr_narrow_seq
          └ axi_wr_narrow_unaligned_seq
             └ axi_wr_narrow_unaligned_wrap_seq
```

---

## 2. 예시 코드 (층마다 body를 덮어씀)

```systemverilog
class axi_wr_seq extends uvm_sequence #(axi_item);
  virtual task body();
    `uvm_do_with(req, { dir == WRITE; })
  endtask
endclass

class axi_wr_narrow_seq extends axi_wr_seq;
  virtual task body();
    `uvm_do_with(req, { dir == WRITE; size < 3; })   // 덮어씀
  endtask
endclass

class axi_wr_narrow_unalign_seq extends axi_wr_narrow_seq;
  virtual task body();
    `uvm_do_with(req, { dir == WRITE; size < 3; addr % 4 != 0; })  // 또 덮어씀
  endtask
endclass
```

---

## 3. 깊은 상속의 단점 5가지

| # | 단점 | 설명 |
|---|------|------|
| 1 | 읽기 어려움 | `wr_narrow_unalign_wrap_err_seq`가 실제로 뭘 보내는지 알려면 파일 6개를 위로 따라가야 한다. |
| 2 | 조합 폭발 | narrow/full × align/unalign × INCR/WRAP = 8개, read까지 더하면 16개. 조합마다 새 클래스가 필요하다. |
| 3 | 로직 복사 | `addr+1`(unaligned) 로직이 `wr_narrow_unalign_seq`와 `wr_unalign_seq` 두 곳에 생긴다. 규칙이 바뀌면 다 찾아 고쳐야 한다. |
| 4 | 부모 수정이 반영 안 됨 (super 미사용) | `wr_seq`에 `wait_ready()`를 추가해도 body를 복사해 덮어쓴 자식은 그대로라, 일부 테스트만 fail이 난다. |
| 5 | 부모 수정이 몰래 퍼짐 (super 사용) | `wr_seq`에 `size = 2`를 넣으면 자식이 앞에서 넣은 `size = 1`이 덮어써져, narrow seq가 에러 없이 full로 바뀐다. |

### 조합이 곱셈으로 늘어나는 이유

| 옵션 | 필요한 클래스 |
|------|--------------|
| narrow/full | 2 |
| + aligned/unaligned | 2×2 = 4 |
| + INCR/WRAP | 4×2 = 8 |
| + read/write | 8×2 = 16 |

!!! warning "SV 클래스는 부모가 하나뿐이다"
    그래서 `narrow_unalign`을 `narrow`와 `unalign` 둘 다에게서 상속할 수 없고, 조합마다 따로 클래스를 만들어 코드를 복사해야 한다.

!!! tip "상속(곱셈) vs knob(덧셈)"
    상속 방식은 조합 수만큼 클래스가 필요한 **곱셈**이고, knob 방식은 옵션 수만큼만 늘어나는 **덧셈**이다.

---

## 4. super 예제

```systemverilog
class wr_seq extends base_seq;
  task body(); wait_ready(); send(); endtask
endclass
class wr_narrow_seq extends wr_seq;
  task body(); size = 1; super.body(); endtask
endclass
class wr_narrow_unalign_seq extends wr_narrow_seq;
  task body(); addr = addr + 1; super.body(); endtask
endclass
```

- 실행 순서는 `addr+1` → `size=1` → `wait_ready` → `send`다. 파일 하나만 봐서는 알 수 없다.
- `wr_seq`를 `wait_ready(); size = 2; send();`로 바꾸면 narrow가 조용히 깨진다.

!!! warning "super를 써도, 안 써도 문제"
    super를 안 쓰면 부모 수정이 **반영되지 않고**, 쓰면 **예상 못한 방식으로 퍼진다**. 어느 쪽이든 층이 깊을수록 감당이 안 된다.

---

## 5. 진짜 나쁜 예시

```
axi_base_seq
 └ axi_wr_seq                      body: wait_ready, send
    └ axi_wr_narrow_seq            body 복사, size=1
       └ axi_wr_narrow_unalign_seq super.body() + addr+1
          └ axi_wr_narrow_unalign_wrap_seq   body 복사, burst=WRAP
             └ axi_wr_narrow_unalign_wrap_err_seq  super + 에러 주입
 └ axi_wr_unalign_seq              body 복사, addr+1
    └ axi_wr_unalign_wrap_seq      super + burst=WRAP
```

- 5~6층 깊이다.
- 복사와 super가 섞여 있다.
- 같은 로직이 여러 곳에 있다.
- 조합 폭발이 진행 중이다.

!!! warning "pass와 fail이 섞인다"
    `wait_ready()` 버그를 고치면 super로 이어진 seq만 고쳐지고, 복사본과 그 아래는 안 고쳐진다. 그래서 pass와 fail이 섞여 원인을 찾는 데 오래 걸린다.

---

## 6. 상속 자체가 나쁜 건 아니다: 1층 + knob

문제는 `extends` 자체가 아니라, **자식끼리 다시 상속하면서 로직이 여러 층으로 흩어지는 것**이다.

```
wr_seq (body, knob 전부 여기)
 ├ wr_narrow_seq          : narrow = 1
 ├ wr_unalign_seq         : unalign = 1
 └ wr_narrow_unalign_seq  : narrow = 1, unalign = 1
```

- 조합마다 클래스를 만들면 여전히 2의 거듭제곱으로 늘어난다. 하지만 각 클래스가 설정 한두 줄짜리여서 관리할 수 있다.
- 대표 조합만 이름을 붙여 주고, 나머지는 test에서 knob을 켜게 한다.

!!! tip "주의점"
    - 자식에서 자식으로 다시 상속하지 않는다.
    - knob을 켜는 위치를 정해 둔다. `new()`에서 켜면 test가 덮어쓸 수 있고, `pre_randomize`나 `body`에서 켜면 test가 바꿀 수 없다.

---

## 7. composition으로 해결하기

seq를 상속으로 쌓지 않고, **역할별 부품 객체**를 갖고 끼워 쓴다.

```systemverilog
class axi_cfg extends uvm_object;      // 설정 부품
  rand bit narrow, unalign;
  rand burst_e burst;
endclass

class err_injector extends uvm_object; // 동작 부품
  virtual function void apply(axi_item t); t.resp = SLVERR; endfunction
endclass

class axi_wr_seq extends axi_base_seq;
  axi_cfg      cfg;
  err_injector inj;   // 없으면 null
  task body();
    wait_ready();
    // start_item → randomize(cfg 제약) → inj.apply → finish_item
    //   cfg.narrow  -> size < 3;
    //   cfg.unalign -> addr % 4 != 0;
    //   burst == cfg.burst;
  endtask
endclass
```

test에서는 이렇게 조립한다.

```systemverilog
seq.cfg.narrow = 1; seq.cfg.unalign = 1; seq.cfg.burst = WRAP;
seq.inj = err_injector::type_id::create("inj");
```

6층짜리 `wr_narrow_unalign_wrap_err_seq`가 **클래스 하나와 설정 네 줄**로 끝난다.

| # | 단점 | composition에서는 |
|---|------|------------------|
| 1 | 읽기 어려움 | body가 한 곳에 있어 파일 하나만 보면 된다. |
| 2 | 조합 폭발 | 옵션이 cfg 변수 하나라 클래스가 늘지 않는다. |
| 3 | 로직 복사 | unaligned 규칙은 제약 한 줄에만 있다. |
| 4 | 부모 수정 미반영 | 복사본이 없어서 `wait_ready()`를 한 번 고치면 끝난다. |
| 5 | 부모 수정이 몰래 퍼짐 | super 체인이 없어서, 누가 값을 덮어쓰는지 cfg만 보면 알 수 있다. |

- 에러 주입 방식을 바꾸려면 `err_injector`를 extends한 새 부품만 끼우면 되고, seq는 손댈 필요가 없다.

!!! warning "factory override는 해결책이 아니다"
    factory override는 클래스 하나를 통째로 바꿔 끼우는 용도라, 조합 폭발을 해결하는 도구는 아니다.

---

## 8. 비유

> 집을 고칠 때마다 층을 하나씩 더 올리는 것과 같다. 몇 층 올라가면 맨 위층 배관이 어디서 시작되는지 아무도 모르게 된다.
