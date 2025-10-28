`timescale 1ns/1ps

module dual_port_ram #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter DEPTH = 1 << ADDR_WIDTH
)(
  input  logic                    clk_a,
  input  logic                    we_a,
  input  logic [ADDR_WIDTH-1:0]   addr_a,
  input  logic [DATA_WIDTH-1:0]   data_in_a,
  output logic [DATA_WIDTH-1:0]   data_out_a,

  input  logic                    clk_b,
  input  logic                    we_b,
  input  logic [ADDR_WIDTH-1:0]   addr_b,
  input  logic [DATA_WIDTH-1:0]   data_in_b,
  output logic [DATA_WIDTH-1:0]   data_out_b
);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Initialize
  initial for (int i = 0; i < DEPTH; i++) mem[i] = '0;

  // Port A (synchronous read)
  always @(posedge clk_a) begin
    if (we_a)
      mem[addr_a] <= data_in_a;
    data_out_a <= mem[addr_a];
  end

  // Port B (synchronous read)
  always @(posedge clk_b) begin
    if (we_b)
      mem[addr_b] <= data_in_b;
    data_out_b <= mem[addr_b];
  end

endmodule

