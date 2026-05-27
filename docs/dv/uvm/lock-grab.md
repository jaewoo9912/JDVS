# lock + grab

## 개념

한 시퀀스가 sequencer를 **독점(exclusive access)**해서, 그 사이 다른 시퀀스가 끼어들지 못하게 하는 메커니즘이다.

하나의 sequencer에 여러 시퀀스가 item을 보내면 sequencer가 **arbitration(중재)**으로 번갈아 처리한다. 그런데 **중간에 끼어들면 안 되는 일련의 동작**(예: register Read-Modify-Write, 끊기면 안 되는 multi-beat 전송)이 있다. 이때 lock/grab으로 잠근다.

- `lock()` / `grab()`로 독점을 얻고, `unlock()` / `ungrab()`로 푼다.
- 풀기 전까지는 다른 시퀀스가 그 sequencer에 접근 불가.

## lock vs grab

차이는 **arbitration 큐의 어디로 끼어드느냐**다. (위 = 먼저 처리)

```
arbitration 큐  (위 = 먼저 처리)
┌──────────────┐
│  grab   ◄──── 맨 위(앞)로 새치기   → "위에서 막음"
├──────────────┤
│  req A       │   ← 이미 대기 중인 요청들
│  req B       │
├──────────────┤
│  lock   ◄──── 맨 아래(뒤)에 줄섬   → "아래에서 막음"
└──────────────┘
```

| | 큐에서 위치 | 동작 |
| --- | --- | --- |
| **lock()** | 맨 **아래**(뒤) | 자기 차례를 **기다린 뒤** 독점 (점잖게 줄섬) |
| **grab()** | 맨 **위**(앞) | 대기 요청 **제치고 즉시** 독점 (새치기, 고우선) |

## 사용법

`lock`/`grab`은 **`uvm_sequence_base`의 메서드**라 시퀀스 안(`body()`)에서 호출한다.

```systemverilog
task body();
  grab();           // == this.grab() → 내 m_sequencer 를 잠금
  // ...
  ungrab();
endtask
```

인자로 **잠글 sequencer**를 지정할 수 있다. 안 넘기면 자기가 붙어있는 sequencer(`m_sequencer`)가 기본.

```systemverilog
grab();           // 내 sequencer
grab(ex_sqr);     // 다른 sequencer (핸들이 있을 때)
```

!!! note "전제: 같은 sequencer"
    lock/grab 경쟁(줄서기/새치기)은 **같은 sequencer**를 두고 다투는 시퀀스들 사이에서만 일어난다.
    다른 sequencer에 붙은 시퀀스는 서로 영향이 없다.

## 예시 — 새치기 하느냐 마느냐

같은 sequencer에 A, B가 줄 서 있고, C가 살짝 늦게 들어오는 상황.

```systemverilog
fork
  seqA.start(sqr);        // ① A 가 먼저
  seqB.start(sqr);        // ② B 가 다음
  #1 seqC.start(sqr);     // ③ C 는 살짝 늦게 (큐상 A,B 뒤)
join
```

**C가 `lock()`** — 안 제침 (줄 뒤에서 기다림)

```systemverilog
task seqC::body();
  lock();
  `uvm_do(item_c)
  unlock();
endtask
// 실행 순서:  A → B → C
```

**C가 `grab()`** — 제침 (새치기)

```systemverilog
task seqC::body();
  grab();
  `uvm_do(item_c)
  ungrab();
endtask
// 실행 순서:  C → A → B
```

## 실무에서 언제?

| 상황 | 사용 | 이유 |
| --- | --- | --- |
| 레지스터 Read-Modify-Write | `lock` | 읽고→고치고→쓰는 사이 다른 시퀀스가 끼면 값이 깨짐 |
| 끊기면 안 되는 multi-beat 전송 | `lock` | 트랜잭션 중간 인터리빙 방지 |
| **ISR(인터럽트 서비스 루틴) 처리** | `grab` | 인터럽트는 급하니 진행 중인 자극을 제치고 먼저 서비스 |

!!! tip "ISR 처리에 grab"
    보통 **ISR(interrupt service routine)**을 처리할 때 `grab`을 쓴다.
    인터럽트가 뜨면 돌던 자극을 잠시 제치고(새치기) 인터럽트부터 서비스한 뒤, `ungrab`으로 풀어 원래 흐름으로 돌아온다.

!!! warning "deadlock 주의"
    `unlock()` / `ungrab()`를 빠뜨리면 sequencer가 영원히 잠겨 **deadlock**이 난다. 반드시 풀어줄 것.
    관련 메서드: `is_blocked()`(다른 잠금에 막혔나), `has_lock()`(내가 잠금 보유 중인가).
