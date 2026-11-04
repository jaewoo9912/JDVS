# modport — interface 신호의 방향 지정

> **modport**는 interface 안의 신호를 **누가 어떤 방향으로 쓰는지** 역할별로 정해주는 것이다. interface가 **전선 묶음**이라면, modport는 그 묶음을 master / slave / monitor 시점으로 보는 **창문**이다.

---

## 1. 기본 형태

```systemverilog
interface axi_if;
  logic awvalid;
  logic awready;

  modport master (output awvalid, input  awready);
  modport slave  (input  awvalid, output awready);
endinterface
```

| 신호 | master | slave |
| --- | --- | --- |
| `awvalid` | output | input |
| `awready` | input | output |

---

## 2. 왜 쓰나? — 방향 실수를 컴파일에서 잡기

```systemverilog
module dut (axi_if.slave bus);
  assign bus.awvalid = 1'b1;   // input으로 선언된 신호에 쓰기 → 컴파일 에러
endmodule
```

- DUT 포트에 `axi_if.slave bus`처럼 연결하면, **input으로 선언된 신호에 쓰려고 할 때 컴파일 에러**가 난다.
- 방향 실수를 **컴파일 단계에서 잡아주는 안전장치**다.

!!! tip "선택 사항"
    modport는 없어도 동작한다. 하지만 **VIP처럼 여러 사람이 쓰는 코드**에서는 넣는 게 좋다.
