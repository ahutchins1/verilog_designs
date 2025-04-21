// UART Receiver
// 8 data bits
// 1 start bit
// 1 stop bit
// NO parity 

module uart_rx #(
    // Parameters
    parameter BAUD_RATE   = 115200,
    parameter CLOCK_FREQ  = 10000000,
    parameter NB_DATA_OUT = 8                   // Number of expected data bits
)
(
    // Ports
    output                       o_valid,       // High when the data has been received completely
    output [NB_DATA_OUT - 1 : 0]  o_data, 
    input                         i_data,       // Serial input
    input                          clock
);

localparam N_CYCLES = 87; // $ceil(CLOCK_FREQ/BAUD_RATE) // Number of cycles per bit received
localparam NB_COUNTER = 8;
localparam NB_IDX     = $clog2(NB_DATA_OUT); 

localparam IDLE      = 3'b000;
localparam START_BIT = 3'b001;
localparam DATA      = 3'b010;
localparam STOP_BIT  = 3'b011;
localparam RESET     = 3'b100;

reg delayline;
reg reg_bit  ;

reg [NB_COUNTER - 1 : 0]  counter ;
reg [NB_IDX - 1 : 0]      bit_idx ;
reg [NB_DATA_OUT - 1 : 0] reg_data = {NB_DATA_OUT{1'b0}};
reg                       valid;
reg [2:0]                 state;


always @(posedge clock) begin
    delayline <=    i_data;
    reg_bit   <= delayline;
end

always @(posedge clock) begin: state_machine_rx
    case (state)
        IDLE: begin
            counter <= {NB_COUNTER{1'b0}} ;
            bit_idx <= {NB_IDX{1'b0}}     ;
            valid   <= 1'b0;
            if (~reg_bit)                              // Start bit detection
                state <= START_BIT;      
            else
                state <= IDLE;
        end
        START_BIT: begin
            if (counter == (N_CYCLES - 1) >> 1) begin  // Only half a period for stable readings
                if (~reg_bit) begin
                    counter <= {NB_COUNTER{1'b0}}; 
                    state   <= DATA;
                end
                else 
                    state  <= IDLE;
            end
            else begin
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= START_BIT;
            end
        end
        DATA: begin
            if (counter < (N_CYCLES - 1)) begin
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= DATA;
            end
            else begin                                                  // After N_CYCLES cycles start saving data
                counter           <= {NB_COUNTER{1'b0}};
                reg_data[bit_idx] <= reg_bit;
                if (bit_idx < (NB_DATA_OUT - 1)) begin           
                    bit_idx <= bit_idx + {{(NB_IDX - 1){1'b0}},1'b1};
                    state   <= DATA; 
                end
                else begin                                              // After receiving all the bits prepare for the Stop bit 
                    bit_idx <= {NB_IDX{1'b0}};
                    state   <= STOP_BIT; 
                end
            end
        end
        STOP_BIT: begin
            if (counter < (N_CYCLES - 1)) begin
                counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
                state   <= STOP_BIT;
            end
            else begin
                valid   <= 1'b1;
                counter <= {NB_COUNTER{1'b0}};
                state   <= RESET;
            end
        end
        RESET: begin
            state <= IDLE;
            valid <= 1'b0;
        end
        default: begin
            state <= IDLE;
        end
    endcase
end

assign o_valid = valid;
assign o_data  = reg_data;

endmodule