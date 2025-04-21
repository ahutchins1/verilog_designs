// UART Transmitter
// 8 data bits 
// 1 start bit
// 1 stop bit
// NO parity

module uart_tx #(
    // Parameters
    parameter BAUD_RATE  = 115200,
    parameter CLOCK_FREQ = 10000000,
    parameter NB_DATA_IN = 8                    // Number of expected data bits
)
(
    // Ports
    output                       o_valid,       // High when the data has been transmitted completely
    output reg                    o_data,       // Serial output    
    input  [NB_DATA_IN - 1 : 0]   i_data,
    input                        i_valid,       // High when UART transmitter needs to be used
    input                          clock
);

localparam N_CYCLES = 87; // $ceil(CLOCK_FREQ/BAUD_RATE) // Number of cycles per bit received
localparam NB_COUNTER = 8;
localparam NB_IDX     = $clog2(NB_DATA_IN); 

localparam IDLE      = 3'b000;
localparam START_BIT = 3'b001;
localparam DATA      = 3'b010;
localparam STOP_BIT  = 3'b011;
localparam RESET     = 3'b100;

reg delayline;
reg reg_bit  ;

reg [NB_COUNTER - 1 : 0] counter ;
reg [NB_IDX - 1 : 0]     bit_idx ;
reg [NB_DATA_IN - 1 : 0] reg_data = {NB_DATA_IN{1'b0}};;
reg                      valid;
reg [2:0]                state;

always @(posedge clock) begin: state_machine_tx
    case (state)
        IDLE: begin
            o_data  <= 1'b1;               // Remains high when transmitter is not active
            counter <= {NB_COUNTER{1'b0}};
            bit_idx <= {NB_IDX{1'b0}};
            valid   <= 1'b0;
            if (i_valid) begin
                reg_data <= i_data;
                state    <= START_BIT;
            end 
            else begin
                state    <= IDLE;
            end 
        end 
        START_BIT: begin
            o_data <= 1'b0;                // Send Start bit
            if (counter < (N_CYCLES - 1)) begin 
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= START_BIT;
            end
            else begin                      // After N_CYCLES cycles start sending data
                counter <= {NB_COUNTER{1'b0}}; 
                state   <= DATA;
            end
        end
        DATA: begin
            o_data <= reg_data[bit_idx];
            if (counter < (N_CYCLES - 1)) begin
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= DATA;
            end
            else begin
                counter <= {NB_COUNTER{1'b0}};
                if (bit_idx < (NB_DATA_IN - 1)) begin
                    bit_idx <= bit_idx + {{(NB_IDX - 1){1'b0}},1'b1};
                    state   <= DATA;
                end
                else begin
                    bit_idx <= {NB_IDX{1'b0}};
                    state   <= STOP_BIT;
                end
            end
        end
        STOP_BIT: begin
            o_data <= 1'b1;
            if (counter < (N_CYCLES - 1)) begin
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= STOP_BIT;
            end
            else begin
                counter <= {NB_COUNTER{1'b0}};
                valid   <= 1'b1;
                state   <= RESET;
            end
        end
        RESET: begin
            valid <= 1'b1;
            state <= IDLE;
        end
        default: begin
            state <= IDLE;
        end
    endcase
end

assign o_valid  = valid;

endmodule