// Floating point multiplier
// This module implements a floating point multiplier with a configurable number of bits for the input and output.
// The input and output formats are defined by the parameters NB_IN, NB_OUT, NB_M, NB_S, and NB_E.

module mult_fp 
#(
    // parameters
    parameter NB_IN  = 13,
    parameter NB_OUT = 13,
    parameter NB_M   =  8, //NB of mantissa
    parameter NB_S   =  1, //NB of sign
    parameter NB_E   =  4  //NB of exponent
)
(
    output [NB_OUT - 1 : 0]   y,
    input  [NB_IN - 1 : 0]  x_A,
    input  [NB_IN - 1 : 0]  x_B
);

localparam BIAS     =         5'b00111;
localparam NB_ADD   = NB_E + $clog2(2); 
localparam NB_PROD  =       2*NB_M + 2;

//data decomposition
wire [NB_S - 1 : 0] s_A; // Sign
wire [NB_S - 1 : 0] s_B;

wire [NB_E - 1 : 0] e_A; // Exponent
wire [NB_E - 1 : 0] e_B;

wire [NB_M - 1 : 0] m_A; // Mantissa
wire [NB_M - 1 : 0] m_B;


wire [NB_ADD -  1 : 0]   exp_add;
wire [NB_ADD -  1 : 0]  exp_norm;
wire [NB_PROD - 1 : 0]      prod;
wire [NB_PROD - 1 : 0]  prod_rnd;
wire [NB_S - 1 : 0]       o_sign;
wire [NB_E - 1 : 0]        o_exp;
wire [NB_M - 1 : 0]       o_mant;
wire                      o_zero;
wire                       o_sat;

assign s_A = x_A [NB_IN - 1 -: NB_S]; 
assign s_B = x_B [NB_IN - 1 -: NB_S];

assign e_A = x_A [NB_IN - 1 - NB_S -: NB_E];
assign e_B = x_B [NB_IN - 1 - NB_S -: NB_E];

assign m_A = x_A [NB_IN - 1 - NB_S - NB_E -: NB_M];
assign m_B = x_B [NB_IN - 1 - NB_S - NB_E -: NB_M];

// Sign comparison
assign o_sign = s_A ^ s_B;

// Add exponents and substract bias
assign exp_add = e_A + e_B - BIAS; 

// Product of mantissas
assign prod = {1'b1,m_A} * {1'b1,m_B};

// Exponent normalization
assign exp_norm = (prod[NB_PROD - 1]) ? exp_add + 1 : exp_add;
assign o_exp    = (exp_norm[NB_ADD - 1]) ? {(NB_E){1'b1}} : exp_norm[NB_ADD - 2 : 0];

// Rounding 
assign prod_rnd = (prod[NB_PROD - 1]) ? 
                  ((prod[NB_PROD - 2 - NB_M ]&(&(prod[NB_PROD - 2 - NB_M : 0])|prod[0])) ? (prod + (1'b1<<(NB_PROD - 2 - NB_M))): prod):
                  ((prod[NB_PROD - 3 - NB_M ]&(&(prod[NB_PROD - 3 - NB_M : 0])|prod[0])) ? (prod + (1'b1<<(NB_PROD - 3 - NB_M))): prod); 

// Saturation and Truncation
assign o_mant = (exp_norm[NB_ADD - 1]) ? {(NB_M){1'b1}} :                                           
                (prod[NB_PROD - 1]) ? prod_rnd[NB_PROD - 2 -: NB_M] : prod_rnd[NB_PROD - 3 -: NB_M];

// Zero management
assign o_zero = (~((|e_A)|(|m_A)))|(~((|e_B)|(|m_B)));

// Output assignment
assign      y = (o_zero) ? {(NB_OUT){1'b0}} : {o_sign,o_exp,o_mant};

// Saturation flag 
assign o_sat = (exp_norm[NB_ADD - 1]) ? {1'b1} : {1'b0};

endmodule