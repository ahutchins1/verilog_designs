// `define PARALLEL
`define UNFOLDED
module top_opt_fir
#(
    parameter NB_DATA_IN    =  8, // Number of bits of the input data
    parameter NB_COEFF      =  8, // Number of bits of the coefficients 
    parameter N_COEFFS      =  8, // Number of coefficients
    parameter NB_DATA_OUT   = 19  // Number of bits of the output data
)
( 
    output signed [NB_DATA_OUT - 1 : 0] o_data_0,
    output signed [NB_DATA_OUT - 1 : 0] o_data_1,
    output signed [NB_DATA_OUT - 1 : 0] o_data_2,
    output signed [NB_DATA_OUT - 1 : 0] o_data_3,  
    input                               i_enable,
    input 				                 i_reset, //Low-active reset
    input 				                   clock      
); 

wire [NB_DATA_IN - 1 : 0] data[3:0];

signal_generator
    u_signal_generator
(
   .o_signal_0(data[0]),
   .o_signal_1(data[1]),
   .o_signal_2(data[2]),
   .o_signal_3(data[3]),
   .i_reset   (i_reset),  
   .i_clock   (clock)          
);


`ifdef PARALLEL
    parallel_fir
    #(
        .NB_DATA_IN (NB_DATA_IN ),  
        .NB_COEFF   (NB_COEFF   ),  
        .N_COEFFS   (N_COEFFS   ), 
        .NB_DATA_OUT(NB_DATA_OUT)
    )
    u_parallel_fir_0
    ( 
        .o_data_0(o_data_0),
        .o_data_1(o_data_1),
        .o_data_2(o_data_2),
        .o_data_3(o_data_3),
        .i_data_0(data[0]),
        .i_data_1(data[1]),
        .i_data_2(data[2]),
        .i_data_3(data[3]),  
        .i_en    (i_enable ),
        .i_rst   (i_reset  ), //Low-active reset
        .clk     (clock    )   
    );

`else
    unfolded_fir
    #(
        .NB_DATA_IN (NB_DATA_IN ),  
        .NB_COEFF   (NB_COEFF   ),  
        .N_COEFFS   (N_COEFFS   ), 
        .NB_DATA_OUT(NB_DATA_OUT)
    )
    u_unfolded_fir_0
    ( 
        .o_data_0(o_data_0),
        .o_data_1(o_data_1),
        .o_data_2(o_data_2),
        .o_data_3(o_data_3), 
        .i_data_0(data[0]),
        .i_data_1(data[1]),
        .i_data_2(data[2]),
        .i_data_3(data[3]),  
        .i_enable(i_enable ),
        .i_reset (i_reset  ), //Low-active reset
        .clock   (clock    )   
    );
`endif

endmodule