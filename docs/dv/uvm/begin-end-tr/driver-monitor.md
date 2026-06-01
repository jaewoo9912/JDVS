# 어디서 호출하는가 — driver vs monitor

## 핵심 한 문장

> **driver는 "지금 시작!"을 실시간으로 알지만, monitor는 끝난 뒤에야 알아서 시작 시각을 거꾸로 적어야 할 수도 있다.**

## 비유: 요리사 vs 맛보는 사람

| | 누구 | 시작 시각 |
|---|---|---|
| **driver** | 직접 요리하는 사람 (직접 구동) | "지금"으로 찍으면 됨 → `begin_tr()` |
| **monitor** | 옆에서 맛만 보는 사람 (관찰) | 정체를 끝나고 알면 "아까 그때"로 소급 → `begin_tr(t_start)` |

## driver 예제 (요리사 — "지금" 찍기)

이 프로젝트 `lib/base/component/env/agent/driver/vrdma_driver.svh`의 실제 루프에 2줄 추가:

```systemverilog
forever begin
  this.seq_item_port.get_next_item(req);

  void'(req.begin_tr());   // ★ req 받자마자 "지금" 시작 도장 (handle 안 받으면 void')
  this.EntryPoint(req);    //   이 task 도는 동안 막대가 그려짐
  req.end_tr();            // ★ 구동 끝나면 "지금" 끝 도장

  this.seq_item_port.item_done();
end
```

## monitor 예제 (맛보기 — 정체를 나중에 알면 "과거로 소급")

```systemverilog
time t_start;
forever begin
  wait (vif.valid === 1'b1);
  t_start = $realtime;        // ★ 시작 시각을 박제 (예: 2000ns)
  collect_packet(tr);         // 다 관찰 (예: 2300ns까지)
  tr.begin_tr(t_start);       // ★ 시작은 "아까 2000ns"로 소급
  tr.end_tr($realtime);       // ★ 끝은 "지금 2300ns"
  ap.write(tr);
end
```

> ⚠️  monitor에서 인자 없이 `begin_tr()`를 쓰면 시작이 "지금"으로 찍혀 막대가 트랜잭션 뒤에 찌그러지거나 길이 0이 된다.

## 예외: AXI read처럼 "시작 때 정체를 아는" 프로토콜은 소급 불필요

AR이 오는 순간 이미 "read다, 주소는 이거다"를 알기 때문에 monitor라도 실시간 `begin_tr()`로 충분하다.

```systemverilog
forever begin
  @(posedge clk iff (arvalid && arready));   // AR 핸드셰이크 = 시작
  axi_rd = axi_read_item::type_id::create("axi_rd");
  axi_rd.addr = araddr; axi_rd.len = arlen;
  void'(axi_rd.begin_tr());                  // ★ AR 수락 → 시작 (소급 불필요)

  do @(posedge clk iff (rvalid && rready));
  while (!rlast);                            // 마지막 데이터 beat까지
  axi_rd.end_tr();                           // ★ rlast → 끝
  ap.write(axi_rd);
end
```

| 상황 | 시작 때 정체를 아는가 | begin_tr |
|---|---|---|
| AXI read | ✅ AR 보면 바로 앎 | `begin_tr()` 실시간 OK |
| 헤더 파싱 후에야 타입 판명 | ❌ 다 받아야 앎 | `begin_tr(t_start)` 소급 |

## 정밀 포인트

- "AR이 왔을 때"의 정확한 시점은 **AR 핸드셰이크 완료**(`arvalid && arready` 둘 다 1)인 클럭이다. arvalid만으로는 시작이 아니다.
- "요청 접수(AR)" vs "데이터 구동 시작"을 구분하고 싶으면 `begin_tr` 외에 **`accept_tr`** 를 쓴다 (→ [다음 단원](accept-tr.md)).
