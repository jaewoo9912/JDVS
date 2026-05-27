# 인덱스 부분 선택 (Indexed part-select)

비트 벡터에서 **시작 비트와 폭(width)**만 지정해 연속된 비트를 잘라내는 문법이다.
시작 인덱스가 **변수**여도 폭이 고정이라 합성·문법상 안전하다는 게 핵심 장점이다.

- `[start +: width]` → `start`부터 **비트 번호가 커지는 방향**으로 `width`개 == `[start+width-1 : start]`
- `[start -: width]` → `start`부터 **작아지는 방향**으로 `width`개 == `[start : start-width+1]`

## 예시

```systemverilog
x[5 +: 3]   // → x[7:5]   (비트 5, 6, 7)
x[5 -: 3]   // → x[5:3]   (비트 5, 4, 3)

data[i*8 +: 8]   // i번째 바이트를 슬라이스 (i가 변수여도 OK)
```

for문과 함께 쓰면 워드를 바이트 단위로 순회할 수 있다.

```systemverilog
for (int i = 0; i < 4; i++) begin
    byte_arr[i] = data[i*8 +: 8];
    // i = 0 -> data[7:0]
    // i = 1 -> data[15:8]
    // i = 2 -> data[23:16]
    // i = 3 -> data[31:24]
end
```
