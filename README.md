# BIT RATE – BAUD – SYMBOL & BAUD‑GENERATOR (UART)

## 0) Ký hiệu nhanh
-	Rb: bit rate (bits per second, bps) – số bit/giây trên đường truyền.
-	Rs: symbol rate / baud rate (symbols per second, baud) – số symbol/giây.

## 1) Định nghĩa & quan hệ
Bit rate (Rb):
-	Gross: tính cả overhead (start/stop/parity, 8b/10b, FEC…).
-	Net/throughput: chỉ payload = gross × hiệu suất khung.
Baud rate (Rs): số symbol/giây.
Symbol: một trạng thái tín hiệu giữ trong thời gian cố định; với điều chế M-ary, mỗi symbol mang log2(M) bit.
Quan hệ tổng quát:
Rb = Rs × log2(M)
UART (NRZ, M = 2) ⇒ 1 symbol = 1 bit ⇒ Rb = Rs (trên dây).
Ví dụ hiệu suất UART:
-	8N1: 1 start + 8 data + 1 stop = 10 bit/khung ⇒ hiệu suất = 8/10 = 80%.
-	8E1: thêm parity = 11 bit/khung ⇒ hiệu suất = 8/11 ≈ 72.7%.

## 2) Baud‑Generator (clock‑enable divider)
Mục tiêu: tạo xung cho phép (clock‑enable) từ clock hệ thống “clk” để chạy đúng baud, không tạo thêm clock domain.
Hai xung đầu ra thường dùng:
-	tick_bit @ BAUD: xung 1 chu kỳ clk, xuất hiện mỗi bit‑time; TX dùng để bước/shift sang bit mới.
-	tick_osr @ BAUD × OSR (OSR thường 16): xung 1 chu kỳ clk chạy nhanh hơn; RX dùng cho oversampling.
“Xung 1 chu kỳ” là gì? Đồng bộ với clk và chỉ lên “1” đúng một chu kỳ clk (lên ở cạnh lên này, về “0” ở cạnh lên kế tiếp). Đây là enable, không phải clock mới.
Quan hệ chốt: 1 bit‑time = OSR × tick_osr = 1 × tick_bit.
## 3) Tạo tick từ F_CLK: cơ chế hai kiểu chia
Đặt tần số đích: F_TICK_BIT = BAUD (cho tick_bit) và F_TICK_OSR = BAUD × OSR (cho tick_osr). Gọi N* = F_CLK / F_TICK. Xung tick luôn rộng 1 chu kỳ clk.
### 3.1) Chia integer‑N (mod‑N counter, có thể làm tròn N)
Nguyên lý: nếu N* là số nguyên thì cứ N chu kỳ clk phát 1 tick. Khi N* không nguyên, có thể làm tròn N = round(N*) để dùng mod‑N.
Cơ chế: bộ đếm đồng bộ đếm 0→N−1; khi chạm N−1 thì phát tick 1‑chu kỳ và quay về 0.
Tính chất:
-	Khoảng cách tick cố định = N × Tclk ⇒ không có jitter do chia.
-	Nếu dùng làm tròn: tần số tick thực tế F'_TICK = F_CLK / N có offset cố định so với F_TICK.
-	Đơn giản, rẻ tài nguyên; phù hợp khi sai số sau làm tròn đủ nhỏ.
### 3.2) Chia fractional‑N (Bresenham / error‑accumulator hoặc NCO)
Mục tiêu: đạt đúng tần số trung bình F_TICK khi N* không nguyên bằng cách xen kẽ khoảng cách tick là floor(N*) và ceil(N*).
Cơ chế Bresenham/error‑accumulator:
-	Viết F_TICK/F_CLK = p/q (rút gọn). Mỗi chu kỳ cộng p vào bộ tích lũy lỗi; khi ≥ q thì phát tick và trừ q (giữ phần dư).
-	Kết quả: số lần chọn (N+1) tỷ lệ với phần dư, đảm bảo khoảng cách trung bình = N*, nên F_TICK trung bình đúng.
Cơ chế NCO/phase‑accumulator (tương đương về lý thuyết): mỗi clk tăng pha theo Δ ≈ F_TICK/F_CLK; khi pha tràn 1.0 thì phát tick và giữ lại phần dư pha.
Tính chất:
-	Đúng tần số trung bình; không có offset lâu dài.
-	Cycle‑to‑cycle jitter định lượng ±1 Tclk do xen kẽ khoảng cách N/N+1 (deterministic).
-	Tài nguyên thấp; rất phù hợp khi F_CLK không chia hết F_TICK.

## 4) Vai trò trong TX/RX
TX (truyền): dùng tick_bit để shift/gửi theo trình tự: start → d0 → … → d7 → parity (nếu có) → stop.
RX (nhận): dùng tick_osr để oversample:
-	Phát hiện cạnh rơi của start → đợi OSR/2 tick để trúng giữa bit.
-	Sau đó mỗi OSR tick lấy mẫu 1 lần (thường vote 3 mẫu quanh giữa bit để tăng miễn nhiễu).

## 5) Jitter là gì? (và vì sao chấp nhận được)
Jitter = độ lệch thời điểm xuất hiện của tick/edge so với lịch lý tưởng.
Các cách đo phổ biến:
-	Period jitter: ΔTn = Tn − T_ideal (chênh lệch chu kỳ so với lý tưởng).
-	Cycle‑to‑cycle jitter: |Tn − Tn‑1| (biến thiên giữa hai chu kỳ liên tiếp).
-	TIE (Time Interval Error): TIE(n) = tn − n·T_ideal (sai lệch thời điểm tích lũy).
Deterministic vs Random:
-	Deterministic (giới hạn, lặp lại): ví dụ quantization jitter do chia fractional‑N (xen kẽ N/(N+1)).
-	Random: đến từ phase noise của nguồn clock, nhiễu nguồn/môi trường…
Trong chia fractional‑N (ví dụ trên):
-	Khoảng cách giữa 2 tick_osr: 27×T_clk = 540 ns hoặc 28×T_clk = 560 ns (với T_clk = 20 ns @ 50 MHz).
-	Bit‑time ở 115.2 kbps: T_bit ≈ 8.6806 µs.
-	Cycle‑to‑cycle jitter tối đa khi chuyển 27↔28 là 20 ns ≈ 0.23% của T_bit → rất nhỏ; RX với OSR=16 + vote 3 mẫu vẫn lấy mẫu an toàn.
