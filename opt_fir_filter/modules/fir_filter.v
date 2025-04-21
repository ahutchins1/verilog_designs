//FIR filter module
//It does not include the delay line
//It is assumed that the input data is already delayed
//Input format is:  S(8,7)
//Output format is: S(19,14)

module fir_filter #(
    parameter NB_DATA_IN    =  8, // Number of bits of the input data
    parameter NB_COEFF      =  8, // Number of bits of the coefficients
    parameter N_COEFFS      =  8, // Number of coefficients 
    parameter NB_DATA_OUT   = 19  // Number of bits of the output data
)
( 
    output signed [NB_DATA_OUT - 1 : 0]   o_data, 
    input signed [NB_DATA_IN - 1 : 0]   i_data_0,  
    input signed [NB_DATA_IN - 1 : 0]   i_data_1,
    input signed [NB_DATA_IN - 1 : 0]   i_data_2,
    input signed [NB_DATA_IN - 1 : 0]   i_data_3,
    input signed [NB_DATA_IN - 1 : 0]   i_data_4,
    input signed [NB_DATA_IN - 1 : 0]   i_data_5,
    input signed [NB_DATA_IN - 1 : 0]   i_data_6,
    input signed [NB_DATA_IN - 1 : 0]   i_data_7,
    input                                   i_en,
    input 				                   i_rst, //Low-active reset
    input 				                     clk      
);

localparam NB_PROD_FW  = NB_DATA_IN  + NB_COEFF;                 //Number of bits of the products
localparam NB_ADD_FW   = NB_PROD_FW  + $clog2(N_COEFFS);         //Number of bits of the adders

wire        [NB_COEFF*N_COEFFS - 1 : 0] i_coeffs;                // Input Coefficients
wire signed [NB_COEFF   - 1 : 0]        coeff [N_COEFFS - 1 : 0];

`include "Path to file 'fir_coeffs.v'"

wire signed [NB_PROD_FW    - 1 : 0] prod_fw     [N_COEFFS - 1 : 0];
wire signed [NB_ADD_FW    - 1 : 0]  add_fw      [N_COEFFS - 2 : 0]; 

wire signed [NB_DATA_IN - 1 : 0] i_data [N_COEFFS - 1 :0];

assign i_data[0] = i_data_0;
assign i_data[1] = i_data_1;
assign i_data[2] = i_data_2;
assign i_data[3] = i_data_3;
assign i_data[4] = i_data_4;
assign i_data[5] = i_data_5;
assign i_data[6] = i_data_6;
assign i_data[7] = i_data_7;

generate
    genvar ptr_coeff;
    for(ptr_coeff = 0; ptr_coeff < N_COEFFS; ptr_coeff = ptr_coeff + 1) begin:b2v_coeff
        assign coeff[ptr_coeff] = i_coeffs[(ptr_coeff + 1) * NB_COEFF - 1 -: NB_COEFF];
    end
endgenerate

generate
    genvar ptr_p_fw;
    for(ptr_p_fw = 0; ptr_p_fw < N_COEFFS; ptr_p_fw = ptr_p_fw + 1) begin:prodfw
        assign prod_fw[ptr_p_fw] = coeff[ptr_p_fw] * i_data[ptr_p_fw];
    end
endgenerate

generate
    genvar ptr_a_fw;
    for(ptr_a_fw = 0; ptr_a_fw < (N_COEFFS - 1); ptr_a_fw = ptr_a_fw + 1) begin:addersfw
        if (ptr_a_fw == 0) 
        assign add_fw[ptr_a_fw] = prod_fw[ptr_a_fw] + prod_fw[ptr_a_fw + 1];
        else
        assign add_fw[ptr_a_fw] = add_fw[ptr_a_fw - 1] + prod_fw[ptr_a_fw + 1];
    end
endgenerate

assign o_data = add_fw[N_COEFFS - 2];

endmodule
