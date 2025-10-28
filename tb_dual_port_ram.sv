`timescale 1ns/1ps
// ====================================================
// FOR 32-BIT TRUE DUAL-PORT RAM
// ====================================================
module tb_dual_port_ram;

  // ----------------------------------------------
  // Parameters
  // ----------------------------------------------
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 8;
  parameter DEPTH      = 1 << ADDR_WIDTH;
  parameter NUM_TESTS  = 2000;

  // ----------------------------------------------
  // DUT Signals
  // ----------------------------------------------
  logic                    clk_a, clk_b;
  logic                    we_a, we_b;
  logic [ADDR_WIDTH-1:0]   addr_a, addr_b;
  logic [DATA_WIDTH-1:0]   data_in_a, data_in_b;
  logic [DATA_WIDTH-1:0]   data_out_a, data_out_b;

  // ----------------------------------------------
  // Reference Memory Model
  // ----------------------------------------------
  logic [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

  // ----------------------------------------------
  // DUT Instantiation
  // ----------------------------------------------
  dual_port_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) dut (
    .clk_a(clk_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .data_in_a(data_in_a),
    .data_out_a(data_out_a),
    .clk_b(clk_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .data_in_b(data_in_b),
    .data_out_b(data_out_b)
  );

  // ----------------------------------------------
  // Clock Generation
  // ----------------------------------------------
  initial begin
    clk_a = 0;
    forever #5 clk_a = ~clk_a; // 10 ns period
  end

  assign clk_b = clk_a; // synchronous operation for simplicity

  // ----------------------------------------------
  // Randomization Task
  // ----------------------------------------------
  task automatic random_operation(output bit same_addr);
    same_addr = ($urandom_range(0, 9) == 0); // 10% same address

    we_a = $urandom_range(0, 1);
    we_b = $urandom_range(0, 1);

    addr_a = $urandom_range(0, DEPTH - 1);
    addr_b = same_addr ? addr_a : $urandom_range(0, DEPTH - 1);

    data_in_a = $urandom();
    data_in_b = $urandom();

    // Display generated operation
$display("[RANDOM] Time=%0t | WE_A=%0b Addr_A=%0d Data_A=%0d | WE_B=%0b Addr_B=%0d Data_B=%0d%s",
         $time, we_a, addr_a, data_in_a, we_b, addr_b, data_in_b,
         same_addr ? " (Same Addr Conflict)" : "");

  endtask

  // ----------------------------------------------
  // Random Test Stimulus
  // ----------------------------------------------
  initial begin
    bit same_addr; 
    we_a = 0; we_b = 0;
    addr_a = 0; addr_b = 0;
    data_in_a = 0; data_in_b = 0;

    // Initialize reference memory
    for (int i = 0; i < DEPTH; i++)
      ref_mem[i] = '0;

    $display("=================================================");
    $display("   STARTING RANDOMIZED Dual-Port RAM TEST         ");
    $display("=================================================");

   // bit same_addr;

    repeat (NUM_TESTS) begin
      @(posedge clk_a);
      random_operation(same_addr);

      // Apply writes to reference model
      if (we_a && we_b && same_addr) begin
        // Conflict case — Port A wins
        ref_mem[addr_a] = data_in_a;
      end
      else begin
        if (we_a) ref_mem[addr_a] = data_in_a;
        if (we_b) ref_mem[addr_b] = data_in_b;
      end

      // Random delay before next transaction
      repeat ($urandom_range(0,2)) @(posedge clk_a);
    end

    // Stop all writes before verification
    we_a = 0;
    we_b = 0;
    @(posedge clk_a);

    verify_memory();
  end

  // ----------------------------------------------
  // Verification Task
  // ----------------------------------------------
  task verify_memory();
    int errors = 0;
    $display("-------------------------------------------------");
    $display(" Verifying Final RAM Contents...");
    $display("-------------------------------------------------");

    for (int i = 0; i < DEPTH; i++) begin
      addr_a = i;
      @(posedge clk_a);
      if (data_out_a !== ref_mem[i]) begin
        $display("[ERROR] Addr %0h: Expected %h, Got %h", i, ref_mem[i], data_out_a);
        errors++;
      end
    end

    $display("-------------------------------------------------");
    if (errors == 0)
      $display(" TEST PASSED — %0d Random Operations Verified Successfully", NUM_TESTS);
    else
      $display(" TEST FAILED — %0d Mismatches Found", errors);
    $display("-------------------------------------------------");

    $finish;
  endtask

  // ----------------------------------------------
  // Functional Coverage
  // ----------------------------------------------
  covergroup cg @(posedge clk_a);
    // Cover whether each port performs read or write
    coverpoint we_a { bins read_write[] = {0,1}; }
    coverpoint we_b { bins read_write[] = {0,1}; }

    // Address coverage (sample limited range for efficiency)
    coverpoint addr_a {
      bins low_addr[]  = {[0:15]};
      bins mid_addr[]  = {[16:127]};
      bins high_addr[] = {[128:255]};
    }
    coverpoint addr_b {
      bins low_addr[]  = {[0:15]};
      bins mid_addr[]  = {[16:127]};
      bins high_addr[] = {[128:255]};
    }

    // Cross coverage: both ports activity
    cross we_a, we_b;
  endgroup

  cg c1 = new();

  // ----------------------------------------------
  // Waveform + Code Coverage
  // ----------------------------------------------
  initial begin
    $dumpfile("dual_port_ram_wv.vcd");
    $dumpvars(0, tb_dual_port_ram);

    
  end

endmodule

