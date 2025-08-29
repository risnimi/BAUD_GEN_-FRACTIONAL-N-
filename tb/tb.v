`timescale 1ns / 1ps


module tb;

	// ======= Config =======
  parameter integer F_CLK = 50_000_000;   // 50 MHz
  parameter integer BAUD  = 115200;
  parameter integer OSR   = 16;

  // ======= Derived =======
  parameter integer FTICK = BAUD*OSR;
  parameter integer N0    = F_CLK / FTICK;             // floor
  parameter integer R     = F_CLK - N0*FTICK;          // remainder (0..FTICK-1)
  

  // ======= DUT =======
  reg  clk, rst_n;
  top uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.tick_osr(tick_osr), 
		.tick_bit(tick_bit)
	);

  initial begin
        $dumpfile("sim/dump.vcd");   // dễ nhất: ghi ngay ở thư mục hiện tại
        $dumpvars(0, tb);        // tb = tên module testbench
        #1000 $finish;           // đảm bảo flush VCD và kết thúc mô phỏng
   end

   // clock 50 MHz
  initial clk = 1'b0;
  always #10 clk = ~clk;

  /// reset
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

   // ======= Đếm chu kỳ & error =======
  integer cycle;
  integer errors;
  initial begin
    cycle  = 0;
    errors = 0;
  end
  always @(posedge clk) begin
    if (rst_n) cycle <= cycle + 1; else cycle <= 0;
  end
  // ======= Log cấu hình =======
  initial begin
    $timeformat(-9,0," ns",10);
    $display("CFG(FRAC): F_CLK=%0d, BAUD=%0d, OSR=%0d => FTICK=%0d, N0=%0d, R=%0d",
              F_CLK, BAUD, OSR, FTICK, N0, R);
  end
 // ======= Check A: spacing ∈ {N0, N0+1}, đếm tần suất (N0+1) =======
  integer last_tick_cycle;
  integer delta;
  integer cnt_N;
  integer cnt_Np1;
  integer intervals;
  initial begin
    last_tick_cycle = -1;
    delta = 0;
    cnt_N = 0;
    cnt_Np1 = 0;
    intervals = 0;
  end
  always @(posedge clk) begin
    if (rst_n && tick_osr) begin
      if (last_tick_cycle >= 0) begin
        delta = cycle - last_tick_cycle;
        intervals = intervals + 1;
  if (delta == N0)        cnt_N   = cnt_N   + 1;
        else if (delta == N0+1) cnt_Np1 = cnt_Np1 + 1;
        else begin
          $display("%t  ERROR: spacing %0d not in {%0d,%0d}", $time, delta, N0, N0+1);
          errors = errors + 1;
        end
      end
      last_tick_cycle = cycle;
    end
  end
  // ======= Check B: width 1-clk =======
  reg tick_osr_d;
  reg tick_bit_d;
  initial begin
    tick_osr_d = 1'b0;
    tick_bit_d = 1'b0;
  end
  
  always @(posedge clk) begin
    tick_osr_d <= tick_osr;
    tick_bit_d <= tick_bit;
    if (rst_n) begin
      if (tick_osr_d && tick_osr) begin
        $display("%t  ERROR: tick_osr width > 1 clk", $time);
        errors = errors + 1;
      end
      if (tick_bit_d && tick_bit) begin
        $display("%t  ERROR: tick_bit width > 1 clk", $time);
        errors = errors + 1;
      end
    end
  end
  // ======= Check C: mỗi OSR tick_osr -> 1 tick_bit =======
  integer osr_count;
  initial osr_count = 0;
  always @(posedge clk) begin
    if (!rst_n) osr_count <= 0;
    else if (tick_osr) begin
      if (osr_count == OSR-1) begin
        if (!tick_bit) begin
          $display("%t  ERROR: expected tick_bit on OSR-th tick_osr", $time);
          errors = errors + 1;
        end
		  osr_count <= 0;
      end else begin
        if (tick_bit) begin
          $display("%t  ERROR: unexpected tick_bit before OSR ticks", $time);
          errors = errors + 1;
        end
        osr_count <= osr_count + 1;
      end
    end
  end
   // ======= Kết thúc theo sự kiện: sau đủ số intervals =======
  // Mục tiêu: thu thập ~2000 intervals để ước lượng tần suất N0+1
  integer target_intervals;
  integer expected_Np1;
  integer tol;
  integer diff;

  initial begin
    target_intervals = 2000;  // có thể tăng/giảm
    // chờ reset xong
    wait (rst_n==1'b1);
    // chờ đủ số khoảng cách để thống kê
    wait (intervals >= target_intervals);
	 if (R == 0) begin
      if (cnt_Np1 != 0) begin
        $display("ERROR: R==0 nhưng vẫn có khoảng cách N0+1");
        errors = errors + 1;
      end
		 end else begin
      // p ≈ R/FTICK; expected_Np1 ≈ p * intervals; dung sai nhỏ
      expected_Np1 = (R * intervals) / FTICK;
      tol = (intervals/100); if (tol < 5) tol = 5;  // ±1% hoặc tối thiểu 5
      diff = (cnt_Np1 > expected_Np1) ? (cnt_Np1 - expected_Np1)
                                      : (expected_Np1 - cnt_Np1);
		if (diff > tol) begin
        $display("WARN: cnt_Np1=%0d, expected~%0d +/- %0d (intervals=%0d)",
                  cnt_Np1, expected_Np1, tol, intervals);
        // nếu muốn nghiêm hơn: errors = errors + 1;
      end
    end

  
   
    if (errors==0) $display("TB PASS (no errors).");
    else           $display("TB FAIL: %0d error(s).", errors);

    #1 $finish;
  end



endmodule