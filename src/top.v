`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    06:26:56 08/29/2025 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top #(
  parameter integer F_CLK = 50_000_000,
  parameter integer BAUD  = 115200,
  parameter integer OSR   = 16
)(
  input  wire clk,
  input  wire rst_n,
  output reg  tick_osr,
  output reg  tick_bit
);

// ---- ceil(log2(value)) portable (không dùng $clog2) ----
  function integer clog2;
    input integer value;
    integer v, i;
  begin
    if (value <= 1) clog2 = 1;
    else begin
      v = value - 1;
      for (i = 0; v > 0; i = i + 1) v = v >> 1;
      clog2 = i;
    end
  end
  endfunction
  // ---- Tham số dẫn xuất ----
  localparam integer FTICK = BAUD * OSR;           // f_tick_osr
  localparam integer N0    = F_CLK / FTICK;        // floor(F_CLK/FTICK)
  localparam integer R     = F_CLK - N0*FTICK;     // phần dư (0..FTICK-1)
  localparam integer N_MIN = (N0 < 1) ? 1 : N0;    // chốt N>=1

  // width đủ chứa N hoặc N+1
  localparam integer CNT_W = clog2(N_MIN+1);       // (vì nạp N  -> đếm N..0)
  localparam integer OSR_W = clog2(OSR);
// ---- Trạng thái ----
  reg [CNT_W-1:0] cnt = {CNT_W{1'b0}};   // down-counter spacing
  reg [31:0]      acc = 32'd0;           // accumulator để quyết định N/N+1
  reg [OSR_W-1:0] osr = {OSR_W{1'b0}};   // đếm OSR để phát tick_bit
 // ---- Core ----
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= {CNT_W{1'b0}};
      acc <= 32'd0;
      osr <= {OSR_W{1'b0}};
      tick_osr <= 1'b0;
      tick_bit <= 1'b0;
		end else begin
      tick_osr <= 1'b0;
      tick_bit <= 1'b0;

      if (cnt == 0) begin
        // phát tick_osr (1-clk)
        tick_osr <= 1'b1;
		 // gom OSR tick_osr -> 1 tick_bit
        if (osr == OSR-1) begin
          osr <= {OSR_W{1'b0}};
          tick_bit <= 1'b1;
        end else begin
          osr <= osr + 1'b1;
        end
		  // quyết định khoảng cách lần tới: N hoặc N+1
        if (R == 0) begin
          // chia đúng: khoảng cách cố định N_MIN
          // load N_MIN-1 để đếm xuống về 0 sau N_MIN chu kỳ
          cnt <= N_MIN - 1;
        end else if (acc + R >= FTICK) begin
          // lần này dùng (N_MIN + 1) chu kỳ
          acc <= acc + R - FTICK;
			  cnt <= N_MIN;          // N+1 -> load N
        end else begin
          // lần này dùng N_MIN chu kỳ
          acc <= acc + R;
          cnt <= N_MIN - 1;      // N   -> load N-1
        end

      end else begin
        // chưa đến tick -> đếm xuống
        cnt <= cnt - 1'b1;
      end
    end
  end
endmodule