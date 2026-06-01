# (Advanced) 두 개의 API 층과 latency 측정

## 핵심: begin_tr는 두 곳에 정의돼 있다

| 정의 위치 | 호출 형태 | 첫 인자 |
|---|---|---|
| `uvm_transaction` | `trans.begin_tr(2000)` | (자기 자신) |
| `uvm_component` | `this.begin_tr(trans, ...)` | **트랜잭션을 인자로 받음** |

그리고 **컴포넌트 버전은 내부에서 트랜잭션 버전을 호출하는 래퍼**다.

```text
component.begin_tr(trans)  ──내부──▶  trans.begin_tr()   (실제 시각 도장)
component.end_tr(trans)    ──내부──▶  trans.end_tr()
component.accept_tr(trans) ──내부──▶  trans.accept_tr()
```

UVM 1.2 소스(`uvm_component::m_begin_tr`)의 실제 코드:

```systemverilog
if (parent_recorder != null)
   link_handle = tr.begin_child_tr(begin_time, parent_recorder.get_handle());
else
   link_handle = tr.begin_tr(begin_time);   // ★ 트랜잭션 버전 호출
```

## 컴포넌트 버전 시그니처 (UVM 1.2)

```systemverilog
function integer begin_tr (uvm_transaction tr,
                           string  stream_name   = "main",   // ← 2번째는 string!
                           string  label         = "",
                           string  desc          = "",
                           time    begin_time     = 0,
                           integer parent_handle = 0);
function void end_tr    (uvm_transaction tr, time end_time = 0, bit free_handle = 1);
function void accept_tr (uvm_transaction tr, time accept_time = 0);
```

> ⚠️  함정: `this.begin_tr(trans, 2000)`은 2000을 **stream_name(string) 자리**에 넣는 꼴이라 begin_time이 안 된다. begin_time을 주려면:
> ```systemverilog
> void'(this.begin_tr(trans, .begin_time(2000)));     // named (권장)
> void'(this.begin_tr(trans, "main", "", "", 2000));  // positional
> ```

## 컴포넌트 버전을 쓰는 이유 (래퍼가 추가로 하는 일)

| 컴포넌트 버전이 얹어주는 것 | 트랜잭션 단독 |
|---|---|
| 자기 hierarchy 밑 **stream**에 막대 배치 (파형에서 driver/monitor 아래 정렬) | ✗ |
| `stream_name`/`label`/`desc` 지정 | ✗ |
| `component.do_begin_tr()` / `do_end_tr()` **콜백** 발동 | ✗ |
| `recording_detail` 등 컴포넌트 설정 반영 | ✗ |
| parent recorder 자동 연결 | 수동 handle 전달 |

**선택 기준:** driver/monitor에서 파형 계층·콜백 훅이 필요 → `this.begin_tr(trans, ...)`. 시각만 박으면 됨 → `trans.begin_tr()`.

```systemverilog
forever begin
  this.seq_item_port.get_next_item(req);
  void'(this.begin_tr(req, "rdma_cmd"));   // driver 밑 "rdma_cmd" stream에 기록
  this.EntryPoint(req);
  this.end_tr(req);
  this.seq_item_port.item_done();
end
```

## `uvm_transaction` 메서드 일람

| 분류 | 메서드 |
|---|---|
| 생명주기 | `accept_tr(time)` · `begin_tr(time)`→integer · `begin_child_tr(time, parent_handle)`→integer · `end_tr(time, free_handle=1)` |
| 시각 회수 | `get_accept_time()` · `get_begin_time()` · `get_end_time()` |
| handle | `get_tr_handle()` |
| 이벤트 | `begin_event` · `end_event` · `events`/`get_event_pool()` (`uvm_event`) |
| 콜백(override) | `do_accept_tr()` · `do_begin_tr()` · `do_end_tr()` · `do_record(recorder)` |
| 식별 | `get/set_transaction_id()` · `get/set_initiator()` |

## latency 측정

**방법 1 — 한 트랜잭션 내부 (3단계 시각 빼기)**

```systemverilog
time wait_lat    = item.get_begin_time() - item.get_accept_time();  // 큐 대기
time service_lat = item.get_end_time()   - item.get_begin_time();   // 처리
time total_lat   = item.get_end_time()   - item.get_accept_time();  // 전체
```

**방법 2 — end-to-end (RDMA post→completion)**

```systemverilog
void'(cmd.begin_tr());                              // (A) driver: SQ doorbell
// ...
cmd.end_tr();                                       // (B) CQ handler: completion
time completion_lat = cmd.get_end_time() - cmd.get_begin_time();
```

**방법 3 — 이벤트 기반 분리형 측정**

```systemverilog
item.begin_event.wait_trigger();  time t0 = item.begin_event.get_trigger_time();
item.end_event.wait_trigger();    time t1 = item.end_event.get_trigger_time();
record_latency(t1 - t0);
```

> recording이 latency 측정의 *필수*는 아니다(`$realtime` 변수로도 됨). 다만 recording으로 재면 ① 같은 값이 파형 막대로도 보여 디버깅이 따라오고 ② 이벤트로 측정 로직 분리가 가능하고 ③ self-documenting 이라는 이점이 있다.

## ⚠️  가장 흔한 함정: 시각은 "객체"에 박힌다 (API 종류 무관)

`get_begin_time()`은 **그 트랜잭션 객체 안의** 값을 돌려준다. 다른 컴포넌트가 읽으려면 **같은 객체 핸들**을 들고 있어야 한다.

```systemverilog
// ❌ clone/copy → 다른 객체 → 시각 0 (begin/end time은 보통 field 매크로로 복사 안 됨)
this.begin_tr(trans);  trans_copy = trans.clone();  ap.write(trans_copy);
sb: trans_copy.get_begin_time();   // → 0

// ✅ 같은 핸들 공유
this.begin_tr(trans);  ap.write(trans);
sb: trans.get_begin_time();        // → 정상
```

**한 줄 요약:** 시각 도장은 언제나 `uvm_transaction`이 찍는다. 컴포넌트 버전은 그걸 hierarchy·stream·콜백에 엮어주는 래퍼일 뿐이며, 값을 나중에 읽을 수 있느냐는 *같은 객체를 들고 있느냐*에만 달려 있다.
