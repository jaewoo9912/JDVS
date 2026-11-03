# `+incdir+` — include 경로 지정

> `+incdir+`는 **`` `include``할 파일이 존재하는 디렉토리**를 컴파일러에 알려주는 옵션이다. 파일을 컴파일하는 옵션이 아니므로 interface 같은 **src 파일은 해당하지 않는다.** 따라서 **pkg 안에 선언된 `` `include`` 파일들의 경로**를 적어준다.

---

## 1. `+incdir+`란?

- `` `include "파일명"``이 나오면 컴파일러는 **현재 디렉토리**를 먼저 보고, 없으면 **`+incdir+`로 준 경로를 순서대로** 찾는다.
- 찾은 파일은 `` `include``가 적힌 자리에 **텍스트로 그대로 복사**된다.
- **경로만 알려줄 뿐, 파일을 컴파일하지 않는다.** 실제 컴파일 대상은 명령줄이나 filelist(`-f`)에 직접 적은 파일이다.

---

## 2. 무엇을 위한 경로인가?

| 파일 | filelist에 직접 적나? | `+incdir+` 필요? |
| --- | --- | --- |
| `axi_pkg.sv` (package) | O | X |
| pkg 안에서 `` `include``하는 클래스 파일 (`axi_driver.sv` 등) | X | **O** (이 파일들이 있는 dir) |
| `axi_if.sv` (interface) | O | X |

- interface는 module처럼 컴파일 단위 최상위에 있어야 해서 **package 안에 `` `include``할 수 없다** → filelist에 직접 적고, `+incdir+`와는 관계없다.
- 그래서 `+incdir+`에는 **pkg에 선언된 `` `include`` 파일들이 있는 디렉토리**를 적는다.

```systemverilog
// axi_pkg.sv
package axi_pkg;
  import uvm_pkg::*;
  `include "axi_item.sv"     // ./vip/axi/src 에서 찾음
  `include "axi_driver.sv"
  `include "axi_monitor.sv"
endpackage
```

```text
// filelist.f
+incdir+./vip/axi/src
./vip/axi/src/axi_pkg.sv
./vip/axi/src/axi_if.sv
./tb/tb_top.sv
```

!!! warning "예외"
    interface **안에서** `` `include``를 쓰면 (예: `` `include "axi_defines.svh"``) 그 파일의 경로는 `+incdir+`로 잡아줘야 한다.

!!! tip "`` `include`` vs `import`"
    `+incdir+`는 `` `include``(텍스트 복사)에만 쓰인다. `import`는 이미 컴파일된 package를 가져다 쓰는 것이라 `+incdir+`와 관계없다.
