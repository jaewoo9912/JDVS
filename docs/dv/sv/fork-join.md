# thread (fork-join)

`fork ... join_xxx` = 블록들을 **동시 실행 프로세스**로 띄움.

## fork-join 세 변형 (join / join_any / join_none)

세 변형의 차이 = **부모가 자식을 언제까지 기다리느냐** 하나뿐.

### 비교표 (`#10`/`#20`/`#30` 자식 기준)

| 변형 | 부모 통과 시점 | 나머지 자식 |
| --- | --- | --- |
| `join`      | @30 (전원 완료) | 없음 |
| `join_any`  | @10 (첫 완료)   | 계속 실행 ⚠️ |
| `join_none` | @0 (즉시)       | 계속 실행 ⚠️ |

### 핵심 규칙

- **R1**: fork 안 각 `begin/end` = 독립 프로세스 1개
- **R2**: `join_any` / `join_none`은 **나머지 자식을 죽이지 않음** (정리는 `disable fork`)
- **R3**: `join_none`은 스케줄만 → 부모가 blocking 문(`#`/`@`/`wait`)을 만나야 자식이 실제 시작
- **R4**: 자식이 `forever`면 `join`(또는 전부 forever 시 `join_any`)은 **데드락**

### 흔한 오해

- ❌ `join_any` 쓰면 나머지 취소된다 → 아님, 계속 산다 (R2)
- ❌ `join_none` 다음 줄에서 자식 이미 실행 중 → 아님, 출발선 대기 (R3)

### 선택 가이드

- 결과 꼭 대기 → `join`
- 누구든 먼저 끝나면 됨 (timeout 경쟁) → `join_any` + `disable fork`
- 발사 후 잊기 (fire-and-forget) → `join_none`

## wait fork / disable fork

### 한 줄 정의

- `wait fork;`    = 이 프로세스의 **직속 자식**이 본문을 끝낼 때까지 대기
- `disable fork;` = 이 프로세스의 **자손 트리 전체**를 재귀적으로 강제 종료

### 비대칭 핵심

| 연산 | 시야 | 동작 |
| --- | --- | --- |
| `wait fork`    | 직속 자식까지만 | 끝나길 기다림 |
| `disable fork` | 전 자손 (재귀) | 강제 종료 |

→ 외우는 법: **`wait` = 퇴근 확인(자식만)**, **`disable` = 사형 집행(일가족 전체)**

### 직속 자식 식별 규칙

- 부모 = 그 `fork` 키워드를 **실행하는** 프로세스
- 직속 자식 = `fork ~ join_xxx` 사이에 **직접 들어있는** 각 `begin/end` (또는 단문)
- 자식 안에서 또 `fork` → 그건 자식의 자식 = 손자 (부모 시점에선 자손)

### 자주 헷갈리는 포인트

- `wait fork`가 "손자까지 기다리는 것처럼" 보이면, 자식이 안에서 `join`으로 손자를 기다리느라 늦게 끝났을 뿐. **`wait fork` 시야는 항상 자식 1대까지**.
- 자식이 손자를 `join_none`으로 던지고 끝내면 → `wait fork` 통과, **손자는 외톨이로 살아남음**.
- `disable fork`는 자식의 fork 종류 무관, **자손 트리 전체 사형**.

### 범위 좁히기 (`disable fork` wrapper 패턴)

```systemverilog
fork begin                    // 격리 wrapper (이게 calling process가 됨)
  fork
    work();
    timeout();
  join_any
  disable fork;               // wrapper 의 자손만 죽음 → 바깥 fork 는 안전
end join
```

### 선택 가이드

- `join_none`으로 던진 자식 전부 끝까지 보장 → **`wait fork`**
- `join_any`로 경쟁시킨 뒤 진 쪽 정리 → **`join_any` + `disable fork`** (+ 필요시 wrapper)
- 트리 전체 확실히 정리 → **`disable fork` 한 방**
- 트리 전체 확실히 대기 → `wait fork`만으론 부족. **자식들 안에서도 `wait fork` 명시 필요**

## foreach + fork — 변수 캡처 함정

### 함정의 증상

- `foreach`로 N개 자식을 `join_none`으로 띄움
- 각 자식이 루프 변수 `i`를 참조하면 → **모든 자식이 마지막 `i` 값(N-1)**만 본다
- 컴파일·시뮬 다 통과. **결과만 조용히 망가지는 타입.**

### 왜 이렇게 되나 — 두 가지 사실의 결합

#### ① 변수 수명 (lifetime)

- SystemVerilog 변수 기본은 **static**: 메모리 1개를 모든 진입이 공유
- `foreach` 루프 변수 `i`도 마찬가지. 자식이 `i`를 참조하면 **부모의 `i` 메모리를 그대로 가리킴**
- `automatic`으로 선언하면 → 진입할 때마다 **새 메모리 할당**

#### ② 스케줄러 동작 — "마이크 1개" 모델

- 한 시점에 한 프로세스만 실행 (선점 없음)
- 마이크 잡은 프로세스는 **blocking 문 만날 때까지** 계속 실행
- 마이크 놓는 시점 = `#delay` / `@event` / `wait` / `wait fork` / `join`(자식 대기)
- `fork...join_none` 자체는 마이크 안 놓음. **자식을 등록만 함**

#### ③ 결합 → 함정

- `foreach` 안에서 부모가 마이크를 **안 놓는다** (`join_none`만 반복)
- 자식들은 등록만 된 채 출발 못 함
- 부모가 `foreach` 끝까지 `i`를 휘리릭 돌림 (`i = 0 → ... → N-1`)
- 부모가 마침내 `wait fork`를 만나 마이크 놓음
- 그제서야 자식들이 출발 → **모두 `i = N-1` 봄** 💀

### 해법

#### 공간으로 풀기 — `automatic` 캡처 (표준)

```systemverilog
foreach (port[i]) begin
  fork
    begin
      automatic int j = i;       // 자식 첫 줄. 현재 i 를 j 에 복사 (새 메모리)
      forever port[j].get(...);  // i 대신 j 사용
    end
  join_none
end
wait fork;
```

- 핵심: **선언만으론 부족**. `= i` 할당까지 같이 해야 캡처
- 자식 본문에서 `i` 참조도 **전부 `j`로 바꿔야** 함
- 관행: `fork`의 `begin` 첫 줄에 둠 ("자식 로컬"이라는 의도가 드러남)

#### 시간으로 풀기 — `join` 사용

```systemverilog
foreach (port[i]) begin
  fork
    work_with(i);
  join     // ← join 이 blocking → 자식 즉시 시작, 끝까지 실행 후 다음 iteration
end
```

- 각 iteration마다 부모가 멈춰서 자식이 `i`를 **바뀌기 전에 읽음**
- 단점: **병렬성 잃음** (자식이 직렬화). 병렬이 필요하면 `automatic` 패턴이 정답

### 흔한 오해

- ❌ "자식 안에 blocking(`#10`) 있으니까 자식이 즉시 시작해서 `i` 잡아둘 것"
    → 아님. `join_none`은 **자식 시작 자체를 안 시킴**. 자식 안 blocking은 자식이 출발한 다음에야 의미가 생김
- ❌ "`automatic` 선언만 하면 자동 캡처"
    → 아님. **`automatic int j = i;` 처럼 할당까지** 해야 함
- ❌ "`join_none`만의 문제"
    → **부모가 자식 시작 전 변수를 바꾸는 모든 패턴**에서 발생 가능

### 스케줄러 추가 사실 — 부모↔자식 핑퐁

- 자식 안 blocking → 자식이 마이크 놓음 → 부모가 깨어 있으면 부모가 잡음
- 부모↔자식이 시뮬 시간에 따라 **번갈아 실행**
- **비결정적이 아님** — blocking 문 위치를 보면 실행 순서 예측 가능

## process 클래스 & 라벨로 개별 제어

### 왜 필요한가

- `wait fork` / `disable fork` = **단체** 제어. 특정 자식 하나만 다룰 수 없음
- 개별 제어 도구가 필요 → **`process` 클래스**(전체 컨트롤) / **라벨**(죽이기 전용)

### process 클래스 — 프로세스의 이름표

- SystemVerilog **빌트인 클래스**. 인스턴스 1개 = 살아있는 프로세스 1개를 가리키는 **핸들**
- 자식이 **자기 핸들을 외부에 노출**시켜야 외부에서 제어 가능

#### 주요 메서드

| 메서드 | 동작 |
| --- | --- |
| `process::self()` | 지금 이 줄을 실행하는 프로세스의 핸들 반환 |
| `p.await()`       | 그 프로세스가 끝날 때까지 대기 |
| `p.kill()`        | 그 프로세스와 자손 전부 종료 (재귀) |
| `p.status()`      | 상태 enum: `FINISHED` / `RUNNING` / `WAITING` / `SUSPENDED` / `KILLED` |
| `p.suspend()`     | 일시정지 |
| `p.resume()`      | 재개 |

#### 캡처 패턴 (정석)

```systemverilog
class my_thing;
  process worker;                       // 멤버 변수 — 외부에서 접근 가능

  task spawn();
    fork
      begin
        worker = process::self();       // 자식이 자기 핸들 등록
        do_work();
      end
    join_none
  endtask

  task wait_done();
    if (worker != null) worker.await(); // 그 자식만 핀포인트 대기
  endtask
endclass
```

- `worker`는 **클래스 멤버 또는 공유 변수**여야 함 (로컬 변수에 잡으면 외부가 못 봄)
- `await()` / `kill()` 직전에 **`null` 체크 필수**

### 라벨 — 죽이기 전용 이름표

`begin/end` 또는 `fork`에 `: 이름`을 붙인다.

```systemverilog
fork
  begin : WORKER_A
    do_a();
  end
  begin : WORKER_B
    do_b();
  end
join_none

disable WORKER_A;     // WORKER_A 와 그 자손만 종료. WORKER_B 는 무사.
```

- 라벨은 **컴파일 타임 정적 이름** (런타임 핸들인 `process`와 다른 점)
- `wait LABEL` / `LABEL.await()` 같은 건 **없음** → 라벨로는 **직접 못 기다림**
    - 기다리려면: **플래그 변수 + `wait`**로 우회, 또는 그냥 **`process` 클래스 사용**

### 라벨 vs process 비교

| 능력 | 라벨 | process 클래스 |
| --- | --- | --- |
| 개별 죽이기 | ✅ `disable LABEL` | ✅ `p.kill()` |
| 개별 기다리기 | ❌ (우회 필요) | ✅ `p.await()` |
| 상태 확인 | ❌ | ✅ `p.status()` |
| 일시정지 / 재개 | ❌ | ✅ `suspend` / `resume` |
| 선언 시점 | 컴파일 타임 | 런타임 |
| 무게 | 가벼움 | 객체 1개 |

→ **기다리기 필요 = `process` 클래스**, **죽이기만 = 라벨**.
