`timescale 1ns/10ps
`define IND                                // Test Rx and Tx individually

module tb_uart ();
    parameter BAUD_RATE    = 115200;
    parameter CLOCK_FREQ   = 10000000;
    parameter NB_DATA      = 8;            // Number of expected data bits
    parameter BIT_PERIOD   = 8600;
    parameter CLOCK_PERIOD = 100;          // [ns]

    wire                      tx_rd_valid; // High when transmission is complete
    reg                       tx_wr_valid; // High to initiate transmission
    reg [NB_DATA - 1 : 0]    tx_full_data; // Full size data (to the Transmitter)
    wire                   tx_serial_data; // Serial data (from the Transmitter)
    wire [NB_DATA - 1 : 0]   rx_full_data; // Full size data (from the Receiver)
    reg                    rx_serial_data = 1'b1;; // Serial data (to the Receiver)
    reg                             clock;
    reg token;

    localparam N_CYCLES = 87; // $ceil(CLOCK_FREQ/BAUD_RATE) // Number of cycles per bit received

    task SEND_SERIAL_DATA;
        input [NB_DATA - 1 : 0] i_data;
        integer i;
        begin
            rx_serial_data <= 1'b0; // Start bit
            #(BIT_PERIOD);
            for (i = 0; i < NB_DATA; i = i + 1) begin  // Data bits
                rx_serial_data <= i_data[i];
                #(BIT_PERIOD);
            end
            rx_serial_data <= 1'b1; // Stop bit
            #(BIT_PERIOD);
        end
    endtask

    always 
    #(CLOCK_PERIOD>>1) clock = ~clock; //Generate clock
`ifdef IND
    initial begin
        clock = 1'b0;
        token = 1'b0;
        @(posedge clock);
        @(posedge clock);
        tx_wr_valid  <= 1'b1;
        tx_full_data <= 8'hE4;
        @(posedge clock);
        tx_wr_valid  <= 1'b0;
        @(posedge tx_rd_valid);
        @(posedge clock);
        SEND_SERIAL_DATA(8'h3F);
        token = 1'b1;
        @(posedge clock);
        
        if (rx_full_data == 8'h3F) begin
            $display("------PASS - Correct DATA Received------");
            token = 1'b1;
        end
        else begin
            $display("------FAIL - Incorrect DATA Received------");
            token = 1'b1;
        end
        $finish;
    end

    uart_tx 
    #(
        .BAUD_RATE (BAUD_RATE ),
        .CLOCK_FREQ(CLOCK_FREQ),
        .NB_DATA_IN(NB_DATA   )                    
    )
    u_uart_tx
    (
        .o_valid (tx_rd_valid ),       
        .o_data  (),        
        .i_data  (tx_full_data),
        .i_valid (tx_wr_valid ),       
        .clock   (clock       )
    );

    uart_rx 
    #(
        .BAUD_RATE  (BAUD_RATE ),
        .CLOCK_FREQ (CLOCK_FREQ),
        .NB_DATA_OUT(NB_DATA   ) 
    )
    u_uart_rx
    (
        .o_valid(),  
        .o_data (rx_full_data  ), 
        .i_data (rx_serial_data), 
        .clock  (clock         )
    );

`else
    initial begin
        clock = 1'b0;
        @(posedge clock);
        @(posedge clock);
        tx_wr_valid  <= 1'b1;
        tx_full_data <= 8'h3F;
        SEND_SERIAL_DATA(8'h3F);
        @(posedge clock);
        tx_wr_valid  <= 1'b0;
        
        if (rx_full_data == 8'h3F) begin
            $display("PASS - Correct DATA Received");
        end
        else begin
            $display("FAIL - Incorrect DATA Received");
        end
        $finish;
    end

    uart_tx 
    #(
        .BAUD_RATE (BAUD_RATE ),
        .CLOCK_FREQ(CLOCK_FREQ),
        .NB_DATA_IN(NB_DATA   )                    
    )
    u_uart_tx
    (
        .o_valid (tx_rd_valid ),       
        .o_data  (tx_serial_data),         
        .i_data  (tx_full_data),
        .i_valid (tx_wr_valid ),       
        .clock   (clock       )
    );

    uart_rx 
    #(
        .BAUD_RATE  (BAUD_RATE ),
        .CLOCK_FREQ (CLOCK_FREQ),
        .NB_DATA_OUT(NB_DATA   ) 
    )
    u_uart_rx
    (
        .o_valid(),  
        .o_data (rx_full_data  ), 
        .i_data (tx_serial_data), 
        .clock  (clock         )
    );
`endif


endmodule