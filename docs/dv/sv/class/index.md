# Class

> 검증 환경(TB)의 뼈대가 되는 **SystemVerilog `class`** 관련 메모 — `virtual` 메서드/클래스의 동적 디스패치, 핸들·Shallow·Deep 복사 차이, 그리고 추상 클래스 `virtual class`와 `virtual interface` 핸들.

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [virtual method / class](virtual.md) | 핸들이 실제로 가리키는 객체 타입의 메서드를 실행하는 `virtual` |
| [객체 복사 (Shallow vs Deep)](object-copy.md) | `b = a;` 핸들 공유 vs `new a` Shallow Copy vs `copy()` Deep Copy |
| [virtual class / interface](virtual-interface.md) | 추상 클래스 `virtual class`와 class(TB)에서 신호에 접근하는 `virtual interface` 핸들 |

!!! tip "OOP 설계 관점은 따로"
    상속 vs 구성(composition) 같은 설계 판단은 [OOP](../../oop/index.md) 섹션에 정리한다.
