# UVM Intro — 왜 UVM을 배워야 하는가

> 핵심 질문: CRV·CDV(랜덤 자극 + 커버리지)는 그냥 SystemVerilog로도 짤 수 있다. 그런데 **왜 굳이 무겁고 배우기 빡센 UVM이라는 "방법론"** 을 얹나? UVM이 정확히 무슨 고통을 없애주길래 업계 표준이 됐나? 그리고 **SystemVerilog의 장점이 아닌, 오직 UVM만의 장점**은 무엇인가?

## 0. 핵심 한 문장

> **UVM을 배우는 이유는 "검증을 *재사용 가능하고 확장 가능하게* 짓기 위해"다.** CRV·CDV가 *무엇을 할지*(랜덤+커버리지 — 사실 이건 SystemVerilog 기능)라면, UVM은 *어떻게 지을지*(컴포넌트 생명주기·설정·통신·교체를 표준화)를 준다. 그래서 사람·VIP·테스트벤치가 프로젝트와 회사를 넘어 그대로 굴러간다.

---

## 1. 먼저 — 검증이 진짜 병목이다

칩 개발에서 **공수의 절반 이상이 설계가 아니라 검증**이다. "RTL을 짜는 것"보다 "그게 맞는지 증명하는 것"이 더 크고 어렵다.

```text
설계: "이렇게 동작하게 만들었다"
검증: "정말 모든 경우에 그렇게 동작하는가?" ← 경우의 수가 천문학적
```

그래서 검증을 **빠르게·빠짐없이·재사용 가능하게** 짓는 게 칩 일정 전체를 좌우한다. UVM은 바로 그 "검증 생산성"을 위한 도구다.

---

## 2. CRV + CDV는 "엔진" — 근데 그건 SystemVerilog다

directed test(시나리오를 손으로 다 씀)는 세 가지 벽에 부딪힌다: ① 안 떠올린 시나리오는 영원히 안 돈다, ② 조합 수가 폭발한다, ③ 유지보수가 지옥이다. 그 해법이 CRV·CDV다.

```text
CRV(Constrained-Random): 제약 안에서 랜덤 자극 → 상상 못 한 코너까지 두들김
CDV(Coverage-Driven):    뭘 돌았나 측정 → "다 했다"를 판정, 랜덤을 빈 칸으로 유도
```

**그런데 중요한 사실 — CRV도 CDV도 SystemVerilog 기능이다.** 랜덤화는 `rand`/`constraint`/`randomize()`, 커버리지는 `covergroup`/`coverpoint`/`cross`. UVM이 한 줄도 안 보태도 SV 언어만으로 된다. 즉 **CRV/CDV는 "왜 체계적 검증이 필요한가"의 동기일 뿐, UVM의 자랑이 아니다.**

그러면 SV만으로 큰 테스트벤치를 짜기 시작하면 곧바로 같은 질문들에 부딪힌다:

```text
- 컴포넌트를 언제 만들고 언제 연결하지? (실행 순서)
- DUT의 virtual interface, 설정값을 어떻게 driver까지 내려보내지?
- monitor가 본 걸 scoreboard로 어떻게 전달하지?
- test마다 driver를 다른 걸로 바꾸고 싶은데, 코드를 안 고치고 되나?
- 이 AXI agent를 다음 프로젝트에 그대로 재사용하려면?
```

**이 질문들에 매 팀이 제각각 답하면 재사용이 박살난다.** 여기서 UVM이 등장한다 — UVM의 진짜 장점은 CRV/CDV 위에 얹는 **재사용·자동화 인프라**다.

---

## 3. ad-hoc 테스트벤치의 4가지 고통 → UVM의 표준 해답

UVM 없이 맨손으로 짜면 모든 팀이 아래를 **재발명**한다. UVM은 이걸 표준으로 박제한 것:

| 고통 (맨손이면) | UVM의 표준 해답 |
|---|---|
| 컴포넌트 **생명주기** — 언제 build/connect/run? 순서 꼬이면 null 참조 | **phase** (build→connect→run→check…, 순서 보장) |
| **설정 주입** — virtual interface·파라미터를 계층 아래로 어떻게? | **config_db** (set/get로 위에서 아래로 주입) |
| 컴포넌트 간 **통신** — monitor→scoreboard 어떻게 연결? | **TLM** (analysis port, put/get — 느슨한 결합) |
| 컴포넌트/트랜잭션 **교체** — 코드 안 고치고 바꾸려면? | **factory** (type/instance override) |
| **자극 생성** 분리 — 시나리오를 컴포넌트와 떼어내려면? | **sequence/sequencer** |

→ UVM의 무거운 장치들은 멋부린 게 아니라, **"맨손 테스트벤치가 반드시 겪는 구체적 고통"의 표준 해답**이다.

---

## 4. 선 긋기 — 이건 SV, 이건 UVM

오직 UVM만의 장점을 따지려면, 먼저 SystemVerilog 것과 UVM 것을 갈라야 한다.

| 기능 | 누구 것? |
|---|---|
| OOP (class/상속/polymorphism) | **SystemVerilog** ❌UVM아님 |
| 랜덤화 (`rand`, `constraint`, `randomize()`) = CRV | **SystemVerilog** ❌ |
| 기능 커버리지 (`covergroup`/`coverpoint`/`cross`) = CDV | **SystemVerilog** ❌ |
| 어서션 (SVA), `virtual interface`, `clocking block` | **SystemVerilog** ❌ |
| `mailbox`/`semaphore`/`fork-join`/queue | **SystemVerilog** ❌ |
| **factory / override** | **UVM** ✅ |
| **config_db** (계층 설정 주입) | **UVM** ✅ |
| **phase + objection** (동기화된 생명주기) | **UVM** ✅ |
| **sequence/sequencer 프로토콜** | **UVM** ✅ |
| **TLM analysis port** (1:多 방송) | **UVM** ✅ |
| **reporting** (verbosity/severity/pass-fail 집계) | **UVM** ✅ |
| **field automation** (auto copy/compare/print) | **UVM** ✅ |
| **RAL** (`uvm_reg`, 레지스터 추상화) | **UVM** ✅ |

---

## 5. 오직 UVM만의 장점 (SV 혼자선 안 되는 것)

### ① Factory + override — 코드 안 고치고 동작 갈아끼우기 (크라운 주얼)

SV의 polymorphism으로 부모 타입에 자식을 담을 순 있지만, **인스턴스 생성 코드를 안 건드리고** 타입을 바꾸는 건 SV 혼자선 안 된다. UVM factory는 된다:

```text
일반 driver로 동작하다가, 에러 주입 test에서 한 줄로:
  set_type_override(axi_driver::type_id, axi_err_driver::type_id);
→ env 코드 한 줄도 안 고치고 driver가 통째로 교체됨
```

→ "테스트마다 컴포넌트/트랜잭션을 갈아끼운다"는 재사용의 핵심. SV엔 이런 게 없다.

### ② config_db — 계층 아래로 설정·vif 주입

`virtual interface` 자체는 SV지만, 그걸 **top에서 깊이 묻힌 driver까지 문자열 경로로 내려보내는** 표준 통로는 SV에 없다. UVM이 `uvm_config_db#(T)::set/get`으로 준다.

```text
top: set(null,"uvm_test_top.env.agent.driver","vif", axi_if);
driver build_phase: get(this,"","vif", vif);
→ 계층을 관통하는 설정 배선을 손으로 안 잇는다
```

### ③ Phase + Objection — 동기화된 생명주기

SV 클래스엔 "생명주기" 개념이 없다(생성 순서를 손으로 관리). UVM은 **모든 컴포넌트가 같은 phase를 동기화**해서 지나간다:

```text
build(top→down) → connect(bottom→up) → run → check → report
+ objection: "내 자극 아직 안 끝남"을 raise/drop → 모두 drop되면 run 종료
```

→ "언제 만들고, 언제 연결하고, 언제 끝낼지"를 수십 컴포넌트에 걸쳐 자동 조율. SV로 직접 하면 지옥.

### ④ Sequence / Sequencer 프로토콜 — 자극을 컴포넌트와 분리

SV에도 mailbox로 자극을 넘길 순 있지만, UVM은 **재사용 가능한 자극 계층**을 통째로 준다:

```text
- sequence를 driver와 분리(같은 driver에 다른 sequence를 꽂아 재사용)
- sequencer-driver handshake (get_next_item / item_done)
- 중재(priority), grab/lock, virtual sequence(여러 agent 조율)
```

→ "자극 시나리오"가 독립 객체라 테스트마다 갈아끼우고 쌓을 수 있다(layering).

### ⑤ TLM analysis port — 표준 1:多 방송

mailbox는 SV지만, **monitor 하나가 본 트랜잭션을 scoreboard·coverage 여럿에게 동시에, 느슨하게** 뿌리는 표준 연결(`analysis_port`→여러 `analysis_imp`)은 UVM 것:

```text
monitor.ap.write(trans) → scoreboard, coverage가 동시에 받음
→ 받는 쪽이 몇 개든 monitor는 안 바뀜 (느슨한 결합 = 재사용)
```

### ⑥ Reporting — 관리되는 메시지/합불 집계

`$display`는 SV지만, UVM은 **severity(info/warning/error/fatal) + verbosity 필터 + ID별 제어 + 에러 카운트로 자동 pass/fail**을 준다.

```text
`uvm_error("AXI","mismatch") → 에러 카운트 +1 → 시뮬 끝에 자동 FAIL 판정
+ UVM_LOW/HIGH 로 로그 양 런타임 조절
```

### ⑦ Field automation — copy/compare/print 자동

SV면 트랜잭션 비교·출력 함수를 손으로 다 짠다. UVM은 `uvm_object_utils`+field 매크로로 **copy/compare/print/pack을 자동 생성**(쓸지 말지는 별개 — 안티패턴 논쟁은 Unit 6에서).

### ⑧ RAL (uvm_reg) — 레지스터 추상화

DUT 레지스터 맵을 **추상 모델**로 만들어, `reg.write(0xAB)` 같은 고수준 접근 + front/back-door + 미리 짜인 레지스터 테스트(reset 값, R/W 비트)를 제공. SV로 손코딩하면 막대한 일을 UVM이 표준화.

### ⑨ (메타) 표준 base 클래스 — 위 전부가 "같은 모양"

`uvm_driver`/`uvm_monitor`/`uvm_agent`/`uvm_env`/`uvm_scoreboard`/`uvm_test`… 모두가 같은 base·같은 phase·같은 통신 방식을 쓴다. 그래서 남이 만든 컴포넌트를 내 testbench에 그냥 꽂고, UVM 아는 엔지니어는 어느 회사 testbench를 봐도 바로 일한다. **이 "표준 모양"이 위 ①~⑧을 재사용 가능하게 만드는 메타 장점.**

---

## 6. UVM이 진짜 파는 것 — 재사용 3종

UVM의 존재 이유를 한 단어로 줄이면 **재사용**이다. 세 방향:

```text
① 수평 재사용(horizontal): 블록 A 검증용 AXI agent를 블록 B에도 그대로
② 수직 재사용(vertical):   블록 레벨에서 쓴 env를 → 서브시스템 → SoC 레벨로 끌어올림
③ VIP 재사용:              상용/사내 AXI·PCIe VIP를 사서/받아 꽂기만
```

```text
맨손 TB:   블록마다 처음부터 다시 → N개 블록 = N벌 노동
UVM TB:    표준 모양이라 agent·env가 레고처럼 재조립 → 재사용으로 노동 N→1에 수렴
```

---

## 7. 역사 한 줌 (왜 "표준"인가)

```text
VMM (Synopsys, ~2006)       ┐
OVM (Cadence+Mentor, ~2008) ┘ → 벤더마다 따로 → 호환 안 됨 (재사용 안 됨!)
        │
        ▼
UVM (Accellera, 2011~) : 업계가 합의한 단일 표준 (OVM 기반)
        │  UVM 1.1 / 1.2 → IEEE 1800.2-2017 / 2020 으로 표준화
        ▼
SystemVerilog(IEEE 1800) 위에 돌아가는 클래스 라이브러리 + 규약
```

핵심: 예전엔 벤더마다 검증 방법론이 달라 재사용이 안 됐다. UVM은 그걸 하나로 통일한 합의다. **"표준"이라는 게 UVM의 가치 그 자체** — 모두가 같은 걸 쓰니 재사용·이동성이 성립.

---

## 핵심 정리

- **검증이 칩 개발의 최대 병목** — 그걸 빠르고 재사용 가능하게 짓는 게 UVM의 목적.
- **CRV·CDV·OOP·어서션은 전부 SystemVerilog 것** — UVM의 자랑이 아니다. CRV/CDV는 "왜 체계적 검증이 필요한가"의 동기일 뿐.
- **오직 UVM만의 장점**은 그 위에 얹는 *재사용·자동화 인프라*:

```text
① factory/override  — 코드 안 고치고 타입 교체
② config_db         — 계층 설정/vif 주입
③ phase/objection   — 동기화된 생명주기·종료
④ sequence/sequencer— 재사용·계층화 가능한 자극
⑤ TLM analysis port — 표준 1:多 느슨한 결합 통신
⑥ reporting         — verbosity·합불 자동 집계
⑦ field automation  — copy/compare/print 자동
⑧ RAL               — 레지스터 추상화
⑨ (메타) 표준 base 클래스 — 위 전부가 "같은 모양"이라 사람·VIP 재사용
```

- UVM이 파는 핵심 가치는 **재사용**(수평·수직·VIP) + **이동성**(사람·VIP가 표준 위에서 호환).
- VMM/OVM 난립 → **UVM(Accellera, IEEE 1800.2)으로 통일** — "표준"이라는 게 가치의 본질.

> **한 줄:** CRV·CDV·OOP·어서션은 전부 SystemVerilog 것 — UVM의 자랑이 아니다. **오직 UVM만의 장점**은 그 위에 얹는 *재사용·자동화 인프라* — factory(교체)·config_db(주입)·phase/objection(생명주기)·sequencer(자극 계층)·TLM(통신)·reporting(합불)·field automation·RAL, 그리고 이 모두가 **표준 모양**이라 사람과 VIP가 그대로 이동한다는 점. UVM은 "검증을 *어떻게 재사용 가능하게 조립하느냐*"를 푼다.
