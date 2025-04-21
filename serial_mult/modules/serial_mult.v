// Based on Gnanasekaran's 1983 "On a Bit-Serial Input and Bit-Serial Output Multiplier"
// Input  format is: U(4,3) x U(4,3)
// Output format is:          U(8,6)

// (1a) [p_2k ... p_1] = [a_k ... a_1][b_k ... b_1]
// (1b) a_k 2^(k-1)[b_k ... b_1]
// (1c) b_k 2^(k-1)[a_(k-1) ... a_1]

// The result of the multiplication is 1a + 1b + 1c

module serial_mult #(
    // Parameters
    parameter NB_DATA_IN  = 4,
    parameter NB_DATA_OUT = 8
)
(
    // Ports
    output   o_data,
    input  i_data_a,
    input  i_data_b, 
    input     i_rst,
    input      i_en,
    input       clk
);

localparam NB_PROD    = NB_DATA_IN + NB_DATA_IN;
localparam NB_COUNTER = $clog2(NB_PROD);

reg  [NB_DATA_IN - 1 : 0]       a                     ;  // Register a (queue)
reg                       a_delay                     ;  // Introduces 1 cicle delay into reg. "a" queue
reg  [NB_DATA_IN - 1 : 0]       b                     ;  // Register b (queue)
reg  [NB_DATA_IN - 1 : 1]       s                     ;  // Sum bits
reg  [NB_DATA_IN - 1 : 0]       c [1 : 0]             ;  // Carry bits
wire [2 : 0]                  sum [NB_DATA_IN - 1 : 0];  // Full result of the sum 1a + 1b + 1c
reg  [NB_COUNTER - 1 : 0] counter                     ;  // Counter (0 - 7)
reg  [NB_DATA_IN - 1 : 0]      sr                     ;  // Shift register for a and b queue fashioned regs.
wire                     overflow                     ;  // Overflow flag (should be output)
wire [NB_DATA_IN - 1 : 0]    oneb                     ;  // Result of 1b eq.
wire [NB_DATA_IN - 1 : 0]    onec                     ;  // Result of 1c eq.

assign oneb = b & {NB_DATA_IN{i_data_a}};
assign onec = a & {NB_DATA_IN{i_data_b}};

assign sum [3] = oneb[3] + onec[3]        + c[0][3] + c[1][2];
assign sum [2] = oneb[2] + onec[2] + s[3] + c[0][2] + c[1][1];
assign sum [1] = oneb[1] + onec[1] + s[2] + c[0][1] + c[1][0];
assign sum [0] = oneb[0] + onec[0] + s[1] + c[0][0]          ;

assign o_data = sum[0][0];
assign overflow = c[0][NB_DATA_IN - 1];

always @(posedge clk or negedge i_rst) begin
    if (!i_rst) begin
        a       <= {NB_DATA_IN{1'b0}};
        a_delay <= 1'b0;
        b       <= {NB_DATA_IN{1'b0}};
        s       <= {NB_DATA_IN{1'b0}};
        c[0]    <= {NB_DATA_IN{1'b0}};
        c[1]    <= {NB_DATA_IN{1'b0}};
        counter <= {NB_COUNTER{1'b0}};
        sr      <= {{(NB_DATA_IN - 1){1'b0}} ,1'b1};
    end
    else begin
        if (i_en) begin
            if ((counter >= (NB_DATA_IN)) && (counter < (NB_PROD - 1))) begin
                a       <= {NB_DATA_IN{1'b0}};
                a_delay <= 1'b0;
                b       <= {NB_DATA_IN{1'b0}};
            end

            else if (&counter) begin
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
            {c[1][0],c[0][0]     }   <= sum [0][2:1];

            counter <= counter + {{(NB_COUNTER - 1){1'b0}},1'b1};
        end
    end
end

endmodule