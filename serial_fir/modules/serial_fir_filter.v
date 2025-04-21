// Serial FIR Filter
// Input  format is: S(4,3)
// Output format is: S(4,3)

// Includes saturation and truncation

// In the first 4 counter cycles, the inputs must be fed into the filter 
// The multipliers take 8 cycles to produce their output                 
// (cycle 0 they receive the LSB of the input, cycle 7 they produce the MSB of the output)

// Multpliers' outputs are fed into the adder tree, introducing a 1 cycle delay
// Adder tree takes 6 cycles to produce its output, introducing a 1 cycle delay
// The accumulator introduces a 1 cycle delay
// The register post-accumulator introduces a 1 cycle delay
// The full output is available in the 13th cycle (counter == 4)
// From there on, the output is shifted to the right, producing the serial output. That introduces a 1 cycle delay
// The first bit of the output in serial format is available in the 14th cycle (counter == 5)
// Total delay is 13 cycles from the first input to the first output in serial format

// NOTE: To accumulate the serial inputs the filter is accessing the queue register from the first multiplier
// to optimize the design. This can be modified making register be from multiplier module an output register port,
// or using a queue register in the filter module.


module serial_fir_filter #(
    parameter NB_DATA_IN  = 4,
    parameter NB_DATA_OUT = 4,
    parameter N_COEFF     = 3
) 
(
    output                     o_data,
    input                      i_data,
    input [N_COEFF - 1 : 0]   i_coeff,
    input                       i_rst,
    input                        i_en,
    input                         clk
);

localparam NB_PROD    = NB_DATA_IN + NB_DATA_IN;
localparam NB_COUNTER = $clog2(NB_PROD);
localparam NB_SUM     = NB_DATA_IN + $clog2(N_COEFF);

reg  [NB_DATA_IN - 1 : 0]         delayline [N_COEFF - 2 : 0];
reg  [NB_COUNTER - 1 : 0]           counter;
reg  [NB_DATA_IN - 1 : 0]                sr; 
wire [NB_DATA_IN - 1 : 0] delayline_shifted [N_COEFF - 2 : 0];
wire [N_COEFF - 1 : 0]                 prod;
reg  [N_COEFF - 1 : 0]             prod_reg;
reg  [NB_SUM - 1 : 0]              s, s_reg;
reg                                   o_reg;
wire [NB_DATA_OUT - 1 : 0]             s_st;
wire [NB_DATA_OUT - 1 : 0]        s_shifted;
wire [1:0]                               fa [N_COEFF-2:0];
reg  [1:0]                              c_o;

// Serial input generation for each coefficient
genvar i;
generate
    for (i = 0; i < (N_COEFF - 1); i = i + 1) begin : gen_delayline_shift
        assign delayline_shifted[i] = delayline[i] >> counter;
    end
endgenerate

// Full adder logic for summing multiplier outputs
assign fa[0] = prod_reg[0] + prod_reg[1] + c_o[0];
assign fa[1] = prod_reg[2] + fa[0][0] + c_o[1];

// Saturation or truncation logic
assign s_st = (~((&(s_reg[(NB_SUM - 1) -: 3])) || (~(|(s_reg[(NB_SUM - 1) -: 3]))))) ?    
              ((s_reg[NB_SUM - 1]) ? {1'b1, {(NB_DATA_OUT - 1){1'b0}}} : 
              {1'b0, {(NB_DATA_OUT - 1){1'b1}}}) : s_reg[(NB_DATA_OUT - 1) -: NB_DATA_OUT];

// Shift output for serial format
assign s_shifted = (counter >= (NB_DATA_IN - 1)) ? s_st >> (counter - NB_DATA_IN) : {NB_DATA_OUT{1'b0}};
assign o_data = o_reg;

always @(posedge clk or negedge i_rst) begin
    if (!i_rst) begin
        prod_reg <= {N_COEFF{1'b0}};
        s        <= {NB_SUM{1'b0}};
        s_reg    <= {NB_SUM{1'b0}};
        c_o      <= 2'b00;
        o_reg    <= 1'b0;
    end 
    else begin
        if (i_en) begin
            if ((counter >= NB_DATA_IN) && (counter < NB_PROD)) begin
                prod_reg <= prod;                                        // Store multiplier outputs
                o_reg    <= s_shifted[0];                                // Store serial output
            end
            c_o   <= ((counter == (NB_DATA_IN - 1)) || (counter == NB_DATA_IN)) ? // Update carry-out
                    2'b00 : {fa[1][1], fa[0][1]};
            s     <= {fa[1][0], s[NB_SUM - 1 : 1]};                      // Accumulate results using full adders
            s_reg <= (counter == (NB_DATA_IN - 1)) ? s : s_reg;          // Store final result (full output)                      
        end
    end
end

always @(posedge clk or negedge i_rst) begin 
    if (!i_rst) begin
        delayline[0] <= {NB_DATA_IN{1'b0}}; 
        delayline[1] <= {NB_DATA_IN{1'b0}};
        sr        <= {NB_DATA_IN{1'b0}};
        counter   <= {NB_COUNTER{1'b1}};
    end 
    else if (i_en) begin
        counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
        if (counter == (NB_DATA_IN - 1)) begin
            sr <= u_trunc_serial_mult_0.b;
        end
        else if (counter == 7) begin                                 // Shift register for multiplier inputs
            delayline[0] <= sr;
            delayline[1] <= delayline[0];
        end
    end
end

// Instantiate the first multiplier separately
trunc_serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT),
    .NB_COUNTER (NB_COUNTER )
)
u_trunc_serial_mult_0
(
    .o_data  (prod[0]   ),
    .i_data_a(i_coeff[0]),
    .i_data_b(i_data    ),
    .counter (counter   ),    
    .i_rst   (i_rst     ),
    .i_en    (i_en      ),
    .clk     (clk       )
);

trunc_serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT),
    .NB_COUNTER (NB_COUNTER )
)
u_trunc_serial_mult_1
(
    .o_data  (prod[1]   ),
    .i_data_a(i_coeff[1]),
    .i_data_b(delayline_shifted[0][0]),
    .counter (counter   ),    
    .i_rst   (i_rst     ),
    .i_en    (i_en      ),
    .clk     (clk       )
);

trunc_serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT),
    .NB_COUNTER (NB_COUNTER )
)
u_trunc_serial_mult_2
(
    .o_data  (prod[2]   ),
    .i_data_a(i_coeff[2]),
    .i_data_b(delayline_shifted[1][0]),
    .counter (counter   ),    
    .i_rst   (i_rst     ),
    .i_en    (i_en      ),
    .clk     (clk       )
);

endmodule