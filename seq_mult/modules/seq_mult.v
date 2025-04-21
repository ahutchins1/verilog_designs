// Sequential serial multiplier
// Format is S(4,3) x S(4,3)
// Truncated output:  S(4,3)
// Both input and output are serial
// The multiplicand is assumed to be a constant coefficient 

// The output is generated every 4 clock cycles and stored in sum_srt
// While the input is being received, the output is calculated (first 4 clock cycles)
// The next 4 clock cycles correspond to the serial deliver of the output (aux logic and o_data assignment)

module seq_mult 
#(
    //Parameters
    parameter NB_DATA_IN   = 4,
    parameter NBF_DATA_IN  = 3,
    parameter NB_DATA_OUT  = 4,
    parameter NBF_DATA_OUT = 3
)
(
    //Ports
    output                     o_data,
    input                      i_data,
    input [NB_DATA_IN - 1 : 0]  coeff,
    input                       i_rst,
    input                        i_en,
    input                       clock  
);

localparam NB_REG     = NB_DATA_IN * 2    ; // Number of bits of accumulator register
localparam NB_COUNTER = $clog2(NB_DATA_IN); // Number of bits of cycle counter

wire        [NB_DATA_IN - 1 : 0]  partial_prod;
reg  signed [NB_REG - 1 : 0]               acc;
wire signed [NB_REG - 1 : 0]               sum;
reg         [NB_COUNTER - 1 : 0]       counter;
wire signed [NB_DATA_OUT - 1 : 0]      sum_srt;
reg signed  [NB_DATA_OUT - 1 : 0]          aux;

always @(posedge clock or negedge i_rst) begin
    if (!i_rst) begin
        counter <= {(NB_COUNTER){1'b0}};
        acc     <= {(NB_DATA_IN){1'b0}};
    end
    else begin
        if (i_en) begin
            counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};          // From 0-3, then overflow

            if (&counter) begin  
                acc <= {(NB_DATA_IN){1'b0}}; // Resets the accumulator for the cycle after counter = 3 (counter = 0)
                aux <= sum_srt;              // Updates the auxiliary output
            end
            else begin
                acc <= sum;                  // Updates the accumulator
                aux <= aux >> 1;             // Shift every clock cycle for serial output logic
            end
        end
    end
end

assign partial_prod = (counter == (NB_DATA_IN - 1)) ? 
                      (-(coeff&{NB_DATA_IN{i_data}})) : (coeff&{NB_DATA_IN{i_data}}); // Partial product generation

assign sum = (acc + $signed({partial_prod, {NB_DATA_OUT{1'b0}}})) >>> 1;              // Accumulation and shift for posterior alignment

assign o_data = aux[0]; //Serial output

Sat_Round_Trunc // Module for saturation or rounding and truncation
#(
.NB_DATA_IN   (NB_REG       ),
.NBF_DATA_IN  (NBF_DATA_IN*2),
.NB_DATA_OUT  (NB_DATA_OUT  ),
.NBF_DATA_OUT (NBF_DATA_OUT )
)
u_Sat_Round_Trunc
(
.o_data     (sum_srt),
.i_data     (sum) 
);

endmodule