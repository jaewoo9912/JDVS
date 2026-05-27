# SystemVerilog

SystemVerilog(SV)는 하드웨어 설계와 검증에 모두 쓰이는 HDL/HVL 통합 언어다.

## Tips (실무 메모)

일하면서 얻은 문법 팁/노하우를 모아둔다.

### 인덱스 부분 선택 (Indexed part-select)

비트 벡터에서 **시작 비트와 폭(width)**만 지정해 연속된 비트를 잘라내는 문법이다.
시작 인덱스가 **변수**여도 폭이 고정이라 합성·문법상 안전하다는 게 핵심 장점이다.

- `[start +: width]` → `start`부터 **비트 번호가 커지는 방향**으로 `width`개 == `[start+width-1 : start]`
- `[start -: width]` → `start`부터 **작아지는 방향**으로 `width`개 == `[start : start-width+1]`

**예시**

```systemverilog
x[5 +: 3]   // → x[7:5]   (비트 5, 6, 7)
x[5 -: 3]   // → x[5:3]   (비트 5, 4, 3)

data[i*8 +: 8]   // i번째 바이트를 슬라이스 (i가 변수여도 OK)
```
