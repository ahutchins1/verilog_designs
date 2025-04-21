// `define PIPELINE // Use to close timing at f_clock = 100 MHz
module unfolded_fir
#(
    parameter NB_DATA_IN    =  8, // Number of bits of the input data 
    parameter NB_COEFF      =  8, // Number of bits of the coefficents  
    parameter N_COEFFS      =  8, // Number of coefficients of the FIR filter
    parameter NB_DATA_OUT   = 19  // Number of bits of the output data
)
( 
    output signed [NB_DATA_OUT - 1 : 0]  o_data_0,
    output signed [NB_DATA_OUT - 1 : 0]  o_data_1,
    output signed [NB_DATA_OUT - 1 : 0]  o_data_2,
    output signed [NB_DATA_OUT - 1 : 0]  o_data_3, 
    input  signed [NB_DATA_IN - 1 : 0] 	 i_data_0,
    input  signed [NB_DATA_IN - 1 : 0] 	 i_data_1,
    input  signed [NB_DATA_IN - 1 : 0] 	 i_data_2,
    input  signed [NB_DATA_IN - 1 : 0] 	 i_data_3,  
    input                                i_enable,
    input 				                  i_reset, //Low-active reset
    input 				                    clock      
);

localparam NB_PROD_FW  = NB_DATA_IN  + NB_COEFF;                //Number of bits of the products
localparam NB_ADD_FW   = NB_PROD_FW  + $clog2(N_COEFFS);        //Number of bits of the adders

wire [NB_COEFF*N_COEFFS - 1 : 0] i_coeffs; // Input Coeffs
wire signed [NB_COEFF   - 1 : 0] coeff [N_COEFFS - 1 : 0];

`include "Path to file 'fir_coeffs.v'"

`ifdef PIPELINE
reg signed [NB_PROD_FW - 1 : 0] prod_fw_0 [N_COEFFS - 1 : 0];
reg signed [NB_PROD_FW - 1 : 0] prod_fw_1 [N_COEFFS - 1 : 0];
reg signed [NB_PROD_FW - 1 : 0] prod_fw_2 [N_COEFFS - 1 : 0];
reg signed [NB_PROD_FW - 1 : 0] prod_fw_3 [N_COEFFS - 1 : 0];
`else
wire signed [NB_PROD_FW - 1 : 0] prod_fw_0 [N_COEFFS - 1 : 0];
wire signed [NB_PROD_FW - 1 : 0] prod_fw_1 [N_COEFFS - 1 : 0];
wire signed [NB_PROD_FW - 1 : 0] prod_fw_2 [N_COEFFS - 1 : 0];
wire signed [NB_PROD_FW - 1 : 0] prod_fw_3 [N_COEFFS - 1 : 0];
`endif
wire signed [NB_ADD_FW - 1 : 0]  add_fw_0  [N_COEFFS - 2 : 0];
wire signed [NB_ADD_FW - 1 : 0]  add_fw_1  [N_COEFFS - 2 : 0];
wire signed [NB_ADD_FW - 1 : 0]  add_fw_2  [N_COEFFS - 2 : 0];
wire signed [NB_ADD_FW - 1 : 0]  add_fw_3  [N_COEFFS - 2 : 0];

reg signed  [NB_ADD_FW - 1 : 0]  reg_data  [N_COEFFS - 2 : 0];

assign o_data_0 = add_fw_0[N_COEFFS - 2];
assign o_data_1 = add_fw_1[N_COEFFS - 2];
assign o_data_2 = add_fw_2[N_COEFFS - 2];
assign o_data_3 = add_fw_3[N_COEFFS - 2];

generate
    genvar ptr_coeff;
    for(ptr_coeff = 0; ptr_coeff < N_COEFFS; ptr_coeff = ptr_coeff + 1) begin:b2v_coeff
        assign coeff[ptr_coeff] = i_coeffs[(ptr_coeff + 1) * NB_COEFF - 1 -: NB_COEFF];
    end
endgenerate

integer idx;
always @(posedge clock) begin
    if (!i_reset) begin
        for(idx = 0 ; idx < N_COEFFS ; idx = idx + 1) begin
        reg_data[idx] <= {NB_DATA_IN{1'b0}};
        end
    end 
    else begin
        if (i_enable) begin
            for(idx = 0 ; idx < N_COEFFS ; idx = idx + 1) begin
                if(idx == 0) begin
                reg_data[idx] <= prod_fw_3[idx];
                end
                else begin
                reg_data[idx] <= add_fw_3[idx - 1];
                end   
            end
        end
    end
end

generate
    genvar i;
    for(i = 0; i < N_COEFFS; i = i + 1) begin:prodfw
        `ifdef PIPELINE
        always @(posedge clock) begin
            prod_fw_0[i] <= coeff[i] * i_data_0;
            prod_fw_1[i] <= coeff[i] * i_data_1;
            prod_fw_2[i] <= coeff[i] * i_data_2;
            prod_fw_3[i] <= coeff[i] * i_data_3;
        end
        `else
        assign prod_fw_0[i] = coeff[i] * i_data_0;
        assign prod_fw_1[i] = coeff[i] * i_data_1;
        assign prod_fw_2[i] = coeff[i] * i_data_2;
        assign prod_fw_3[i] = coeff[i] * i_data_3;
        `endif
    end
endgenerate

generate
    genvar j;
    for(j = 0; j < (N_COEFFS - 1); j = j + 1) begin:addersfw
        if (j == 0) begin
            assign add_fw_0[j] = reg_data[j] + prod_fw_0[j + 1]; 
            assign add_fw_1[j] = prod_fw_0[j] + prod_fw_1[j + 1];
            assign add_fw_2[j] = prod_fw_1[j] + prod_fw_2[j + 1];
            assign add_fw_3[j] = prod_fw_2[j] + prod_fw_3[j + 1];
        end
        else begin
            assign add_fw_0[j] = reg_data[j]     + prod_fw_0[j + 1];
            assign add_fw_1[j] = add_fw_0[j - 1] + prod_fw_1[j + 1];
            assign add_fw_2[j] = add_fw_1[j - 1] + prod_fw_2[j + 1];
            assign add_fw_3[j] = add_fw_2[j - 1] + prod_fw_3[j + 1];
        end
    end
endgenerate

endmodule
