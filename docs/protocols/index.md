# 프로토콜 (Protocols)

칩 안팎의 블록들이 서로 대화하는 **약속(규약)** 을 다룹니다. SoC 내부 버스부터 시작합니다.

!!! abstract "학습 개요"
    - 📊 **레벨:** Intermediate ~ Advanced
    - 🎯 **학습 목표:** "두 블록이 어떤 신호를, 어떤 순서로, 어떤 타이밍에 주고받기로 약속했나"를 설명하고, 그 약속이 깨지는 지점(= DV 검증 핫스팟)을 짚을 수 있다.
    - 🧭 **방식:** 코드보다 개념·비유·타이밍 다이어그램 중심. DV 관점을 항상 곁들임.

## 주제

- **AMBA** (ARM의 SoC 온칩 버스 표준 — APB / AHB / AXI / ACE / CHI)
    - [Unit 1 — APB & AHB (AMBA의 두 클래식 버스)](amba/amba-unit1-apb-ahb.md) ✅
    - [Unit 1 — APB & AHB : Q&A 모음](amba/amba-unit1-qa.md) ✅
    - [Unit 2 — AXI (그 벽을 깨는 버스)](amba/amba-unit2-axi.md) ✅
    - [Unit 2 — AXI : Q&A 모음](amba/amba-unit2-qa.md) ✅
    - [Unit 3 — AXI-Stream (주소를 버린 버스)](amba/amba-unit3-axi-stream.md) ✅
    - [Unit 3 — AXI-Stream : Q&A 모음](amba/amba-unit3-qa.md) ✅
