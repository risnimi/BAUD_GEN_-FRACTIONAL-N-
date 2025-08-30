# BIT RATE – BAUD – SYMBOL & BAUD‑GENERATOR (UART)

## 0) Ký hiệu nhanh

- Rb: bit rate (bits per second, bps) – số bit/giây trên đường truyền.

- Rs: symbol rate / baud rate (symbols per second, baud) – số symbol/giây.

## 1) Định nghĩa & quan hệ

Bit rate (Rb):

- Gross: tính cả overhead (start/stop/parity, 8b/10b, FEC…).

- Net/throughput: chỉ payload = gross × hiệu suất khung.
Baud rate (Rs): số symbol/giây.
Symbol: một trạng thái tín hiệu giữ trong thời gian cố định; với điều chế M-ary, mỗi symbol mang log2(M) bit.
Quan hệ tổng quát:
Rb = Rs × log2(M)
UART (NRZ, M = 2) ⇒ 1 symbol = 1 bit ⇒ Rb = Rs (trên dây).
Ví dụ hiệu suất UART:

- 8N1: 1 start + 8 data + 1 stop = 10 bit/khung ⇒ hiệu suất = 8/10 = 80%.

- 8E1: thêm parity = 11 bit/khung ⇒ hiệu suất = 8/11 ≈ 72.7%.

## 2) Baud‑Generator (clock‑enable divider)

Mục tiêu: tạo xung cho phép (clock‑enable) từ clock hệ thống “clk” để chạy đúng baud, không tạo thêm clock domain.
Hai xung đầu ra thường dùng:

- tick_bit @ BAUD: xung 1 chu kỳ clk, xuất hiện mỗi bit‑time; TX dùng để bước/shift sang bit mới.

- tick_osr @ BAUD × OSR (OSR thường 16): xung 1 chu kỳ clk chạy nhanh hơn; RX dùng cho oversampling.
“Xung 1 chu kỳ” là gì? Đồng bộ với clk và chỉ lên “1” đúng một chu kỳ clk (lên ở cạnh lên này, về “0” ở cạnh lên kế tiếp). Đây là enable, không phải clock mới.
Quan hệ chốt: 1 bit‑time = OSR × tick_osr = 1 × tick_bit.

## 3) Tạo tick_osr và tick_bit từ F_CLK

Mục tiêu tần số:

- F_TICK_OSR = BAUD × OSR

- F_TICK_BIT = BAUD
Integer‑N divider: tạo tick mỗi N chu kỳ clk (khi N = F_CLK / F_TICK là số nguyên).
Fractional‑N divider: xen kẽ khoảng cách N / (N+1) chu kỳ clk để đạt tần số trung bình đúng; có jitter ±1 chu kỳ clk nhưng vẫn đồng bộ. Thường hiện thực bằng phase‑accumulator/NCO.
Ví dụ:

- F_CLK = 50 MHz, BAUD = 115200, OSR = 16 ⇒ F_TICK_OSR = 1,843,200 Hz.

- N_ideal = 50,000,000 / 1,843,200 ≈ 27.126.

- Fractional‑N: đa số khoảng cách 27 chu kỳ, thỉnh thoảng 28 chu kỳ để đạt trung bình ~27.126.

## 4) Vai trò trong TX/RX

TX (truyền): dùng tick_bit để shift/gửi theo trình tự: start → d0 → … → d7 → parity (nếu có) → stop.
RX (nhận): dùng tick_osr để oversample:

- Phát hiện cạnh rơi của start → đợi OSR/2 tick để trúng giữa bit.

- Sau đó mỗi OSR tick lấy mẫu 1 lần (thường vote 3 mẫu quanh giữa bit để tăng miễn nhiễu).

## 5) Jitter là gì? (và vì sao chấp nhận được)

Jitter = độ lệch thời điểm xuất hiện của tick/edge so với lịch lý tưởng.
Các cách đo phổ biến:

- Period jitter: ΔTn = Tn − T_ideal (chênh lệch chu kỳ so với lý tưởng).

- Cycle‑to‑cycle jitter: |Tn − Tn‑1| (biến thiên giữa hai chu kỳ liên tiếp).

- TIE (Time Interval Error): TIE(n) = tn − n·T_ideal (sai lệch thời điểm tích lũy).
Deterministic vs Random:

- Deterministic (giới hạn, lặp lại): ví dụ quantization jitter do chia fractional‑N (xen kẽ N/(N+1)).

- Random: đến từ phase noise của nguồn clock, nhiễu nguồn/môi trường…
Trong chia fractional‑N (ví dụ trên):

- Khoảng cách giữa 2 tick_osr: 27×T_clk = 540 ns hoặc 28×T_clk = 560 ns (với T_clk = 20 ns @ 50 MHz).

- Bit‑time ở 115.2 kbps: T_bit ≈ 8.6806 µs.

- Cycle‑to‑cycle jitter tối đa khi chuyển 27↔28 là 20 ns ≈ 0.23% của T_bit → rất nhỏ; RX với OSR=16 + vote 3 mẫu vẫn lấy mẫu an toàn.
