//Milestone 1 TEAM 13

module uart_tb;
  reg clk, reset, wr_en, rd_en;
  reg [7:0] d_in;
  wire tx, rx;
  wire [7:0] d_out;
  wire tx_full, rx_empty;

  // Instantiate the UART top module
  uart_top uart_inst (.*);

  // Clock generation
  always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
  end

  // Stimulus generation
  initial begin
    reset = 1;
    wr_en = 0;
    rd_en = 0;
    d_in = 8'b0;

    #10;
    reset = 0;

    // Test writing data
    #10;
    wr_en = 1;
    d_in = 8'b10101010; 
    #10;
    wr_en = 0;

    // Test reading data
    #10;
    rd_en = 1;
    #10;
    rd_en = 0;

    // Test another write and read
    #10;
    wr_en = 1;
    d_in = 8'b11001100; // Write another data
    #10;
    wr_en = 0;
    #10;
    rd_en = 1; // Read the new data
    #10;
    rd_en = 0;

   
    #20;
    $finish;
  end

  initial begin
    $monitor("Time: %t, d_in: %b, d_out: %b, wr_en: %b, rd_en: %b, tx_full: %b, rx_empty: %b", $time, d_in, d_out, wr_en, rd_en, tx_full, rx_empty);
  end

endmodule