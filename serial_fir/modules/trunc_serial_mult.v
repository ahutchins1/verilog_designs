// Based on Gnanasekaran's 1983 "On a Bit-Serial Input and Bit-Serial Output Multiplier"
// Input  format is: S(4,3) x S(4,3)
// Output format is:          S(8,6)

// For the first n-1 steps:
// (1a) [p_2k ... p_1] = [a_k ... a_1][b_k ... b_1]
// (1b) a_k 2^(k-1)[b_k ... b_1]
// (1c) b_k 2^(k-1)[a_(k-1) ... a_1]

// For the n-th step (if bit sign is 1):
// (2a) [p_2n ... p_1] = [a_n ... a_1][b_n ... b_1]
// (2b) - a_n 2^(n-1)[b_n ... b_1]
// (2c) - b_n 2^(n-1)[a_(n-1) ... a_1]

// The result of the multiplication is 1a + 1b + 1c , or 2a + 2b + 2c in the last step if necessary

// Terms Q1 and Q2 help perform the two's compliment
`define SAT_VAL 4'b0111

module trunc_serial_mult #(
    // Parameters
    parameter NB_DATA_IN  = 4,
    parameter NB_DATA_OUT = 8,
    parameter NB_COUNTER  = 3
)
(
    // Ports
    output                       o_data,
    input                      i_data_a,
    input                      i_data_b,
    input [NB_COUNTER - 1 : 0]  counter, 
    input                         i_rst,
    input                          i_en,
    input                           clk
);

localparam NB_PROD    = NB_DATA_IN + NB_DATA_IN;

reg  [NB_DATA_IN - 1 : 0]       a                     ;  // Register a (queue)
reg                       a_delay                     ;  // Introduces 1 cicle delay into reg. "a" queue
reg  [NB_DATA_IN - 1 : 0]       b                     ;  // Register b (queue)
reg  [NB_DATA_IN - 1 : 0]       s                     ;  // Sum bits
reg  [NB_DATA_IN - 1 : 0]       c [1 : 0]             ;  // Carry bits
wire [2 : 0]                  sum [NB_DATA_IN - 1 : 0];  // Full result of the sum 1a + 1b + 1c
reg  [NB_DATA_IN - 1 : 0]      sr                     ;  // Shift register for a and b queue fashioned regs.
wire                     overflow                     ;  // Overflow flag (should be output)
wire [NB_DATA_IN - 1 : 0]    oneb                     ;  // Result of 1b eq.
wire [NB_DATA_IN - 1 : 0]    onec                     ;  // Result of 1c eq.

wire q1;                                                 // Q1 takes a_n-th value
wire q2;                                                 // Q2 takes b_n-th value

reg sat;

wire [3:0] shifted_sat_val;

assign q1 = (counter == (NB_DATA_IN - 1)) ? i_data_a : 0 ;
assign q2 = (counter == (NB_DATA_IN - 1)) ? i_data_b : 0 ;

assign oneb = (b ^ {NB_DATA_IN{q1}}) & ({NB_DATA_IN{i_data_a}});
assign onec = (a ^ {NB_DATA_IN{q2}}) & ({NB_DATA_IN{i_data_b}});

assign sum [3] = oneb[3] + onec[3]        + c[0][3] + c[1][2]          ;
assign sum [2] = oneb[2] + onec[2] + s[3] + c[0][2] + c[1][1]          ;
assign sum [1] = oneb[1] + onec[1] + s[2] + c[0][1] + c[1][0]          ;
assign sum [0] = oneb[0] + onec[0] + s[1] + c[0][0]           + q1 + q2;

assign shifted_sat_val = (counter > NB_DATA_IN) ? (`SAT_VAL >> (counter - NB_DATA_IN)) : `SAT_VAL;

assign o_data = (counter > (NB_DATA_IN - 1)) ? ((sat) ? shifted_sat_val[0] : s[0]) : 0;

assign overflow = c[0][NB_DATA_IN - 1];

always @(posedge clk or negedge i_rst) begin
    if (!i_rst) begin
        a       <= {NB_DATA_IN{1'b0}};
        a_delay <= 1'b0;
        b       <= {NB_DATA_IN{1'b0}};
        s       <= {NB_DATA_IN{1'b0}};
        c[0]    <= {NB_DATA_IN{1'b0}};
        c[1]    <= {NB_DATA_IN{1'b0}};
        sr      <= {{(NB_DATA_IN - 1){1'b0}} ,1'b1};
        sat     <= 1'b0;

    end
    else begin
        if (i_en) begin
            if ((counter >= (NB_DATA_IN - 1)) && (counter < (NB_PROD - 2))) begin
                a       <= {NB_DATA_IN{1'b0}};
                a_delay <= 1'b0;
                b       <= {NB_DATA_IN{1'b0}};
            end

            else if (counter == (NB_PROD - 2)) begin
                a       <= {NB_DATA_IN{1'b0}};
                a_delay <= 1'b0;
                b       <= {NB_DATA_IN{1'b0}};
                s       <= {NB_DATA_IN{1'b0}};
                c[0]    <= {NB_DATA_IN{1'b0}};
                c[1]    <= {NB_DATA_IN{1'b0}};
                sr      <= {{(NB_DATA_IN - 1){1'b0}} ,1'b1};
            end

            else begin
                b <= b | (sr & {NB_DATA_IN{i_data_b}}); // register queue
                a <= a | ((sr >> 1) & {NB_DATA_IN{a_delay}}); // register queue (delayed)
                a_delay <= i_data_a;
                sr <= sr << 1;
            end

            {c[0][3]        ,s[3]}   <= sum [3];
            {c[1][2],c[0][2],s[2]}   <= sum [2];
            {c[1][1],c[0][1],s[1]}   <= sum [1];
            {c[1][0],c[0][0],s[0]}   <= sum [0];

            sat     <= (counter == NB_DATA_IN - 2) ? ((i_data_b) & (~|b[2:0])) & ((i_data_a) & (~|a[2:0])) : sat; // Saturation flag
        end
    end
end

endmodule