`define RND_1BIT
// `define RND_TNE
module Sat_Round_Trunc 
#(
    //Parameters
    parameter NB_DATA_IN   = 50,
    parameter NBF_DATA_IN  = 45,
    parameter NB_DATA_OUT  = 16,
    parameter NBF_DATA_OUT = 15
)
(
    //Ports
    output signed [NB_DATA_OUT - 1 : 0]   o_data,
    output                              sat_flag,
    input  signed [NB_DATA_IN - 1 : 0]    i_data
);

localparam NBI_DATA_IN  = NB_DATA_IN  -  NBF_DATA_IN;
localparam NBI_DATA_OUT = NB_DATA_OUT - NBF_DATA_OUT;

wire [NB_DATA_IN - 1 : 0] data_rnd;

//rounding 
`ifdef RND_1BIT //1 bit-check rounding
assign data_rnd = (i_data[NB_DATA_IN - 1 - NB_DATA_OUT]) ? 
                  (i_data + (1'b1<<(NB_DATA_IN - 1 - NB_DATA_OUT))) : i_data;
`else // Rounding to nearest even
assign data_rnd = (i_data[NBF_DATA_IN - NBF_DATA_OUT - 2]&
                  ((&(i_data[(NBF_DATA_IN - NBF_DATA_OUT - 3) : 0]))|i_data[0])) ? 
                  (i_data + (1'b1<<(NBF_DATA_IN - NBF_DATA_OUT - 2))): i_data;     
`endif

//saturation and truncation
assign sat_flag = ~((&(data_rnd[NB_DATA_IN - 1 -: NBI_DATA_IN]))||
                    (~(|(data_rnd[NB_DATA_IN - 1 -: NBI_DATA_IN]))));

assign o_data = (sat_flag) ? ((i_data[NB_DATA_IN - 1]) ? {1'b1,{(NB_DATA_OUT-1){1'b0}}} : 
                {1'b0,{(NB_DATA_OUT-1){1'b1}}}) : data_rnd[(NBF_DATA_IN + NBI_DATA_OUT - 1) -: NB_DATA_OUT];

endmodule
