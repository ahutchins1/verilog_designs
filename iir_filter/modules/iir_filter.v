// IIR Filter
// Coeffs format S(16.15)
// Input  format S(16.15)
// Output format S(16.15)

`include "Path to file 'iir_coeffs.v'"

module iir_filter
#(
    parameter NB_DATA_IN    = 16, 
    parameter NBF_DATA_IN   = 15, 
    parameter NB_COEFF      = 16, 
    parameter NBF_COEFF     = 15, 
    parameter N_COEFFS      =  3, 
    parameter NB_DATA_OUT   = 16,
    parameter NBF_DATA_OUT  = 15
)
( 
    output signed [NB_DATA_IN - 1 : 0]  o_data  , 
    output signed [NB_DATA_IN - 1 : 0]  o_data_2,
    input signed [NB_DATA_IN - 1 : 0] 	i_data  ,  
    input                               i_enable,
    input 				                i_reset , //Low-active reset
    input 				                clock      
);

localparam NB_PROD_FW  = NB_DATA_IN  + NB_COEFF;                // Number of bits of the products
localparam NBF_PROD_FW = NBF_DATA_IN + NBF_COEFF;               // Number of fractional bits of the products
localparam NB_ADD_FW   = NB_PROD_FW  + $clog2(N_COEFFS);        // Number of bits of the adders
localparam NBF_ADD_FW  = NBF_PROD_FW;                           // Number of fractional bits of the adders

localparam NB_TRUNC  = NB_DATA_OUT;          // Number of bits after the truncation
localparam NBF_TRUNC = NBF_DATA_OUT;         // Number of fractional bits after the truncation
localparam NBI_TRUNC = NB_TRUNC - NBF_TRUNC; // Number of integer bits after the truncation

//Option 1 (fb res > output res)
localparam NB_DATA_FB  =  NB_ADD_FW;  // Number of bits of feedback registers
localparam NBF_DATA_FB = NBF_ADD_FW;  // Number of fractional bits of feedback registers

//Option 2 (fb res == output res)
// localparam NB_DATA_FB  = NB_DATA_OUT;  // Number of bits of feedback registers
// localparam NBF_DATA_FB = NBF_DATA_OUT; // Number of fractional bits of feedback registers

localparam NB_PROD_FB  = NB_DATA_FB  +  NB_COEFF;               // Number of bits of the products
localparam NBF_PROD_FB = NBF_DATA_FB + NBF_COEFF;               // Number of fractional bits of the products
localparam NB_ADD_FB   = NB_PROD_FB  + $clog2(N_COEFFS);        // Number bits of the adders
localparam NBF_ADD_FB  = NBF_PROD_FB;                           // Number of fractional bits of the adders
localparam NBI_ADD_FB  = NB_ADD_FB -  NBF_ADD_FB;               // Number of integer bits of the adders

wire [NB_COEFF*N_COEFFS - 1 : 0]     i_coeff_b; // Input Coeffs B
wire [NB_COEFF*(N_COEFFS-1) - 1 : 0] i_coeff_a; // Input Coeffs A

wire signed [NB_COEFF   - 1 : 0] coeff_a [N_COEFFS - 2 : 0];  
wire signed [NB_COEFF   - 1 : 0] coeff_b [N_COEFFS - 1 : 0];

reg signed [NB_DATA_IN  - 1 : 0]    x_reg       [N_COEFFS - 1 : 0]; 
wire signed [NB_PROD_FW    - 1 : 0] prod_fw     [N_COEFFS - 1 : 0];
wire signed [NB_ADD_FW    - 1 : 0]  add_fw      [N_COEFFS - 2 : 0];
wire signed [NB_TRUNC - 1 : 0]      add_fw_srt ;
wire signed [NB_PROD_FB    - 1 : 0] add_fw_expd; 

reg signed [NB_DATA_FB - 1 : 0]     y_reg       [N_COEFFS - 2 : 0];  
wire signed [NB_PROD_FB    - 1 : 0] prod_fb     [N_COEFFS - 2 : 0]; 
wire signed [NB_ADD_FB    - 1 : 0]  add_fb      [N_COEFFS - 2 : 0];
wire signed [NB_DATA_FB - 1 : 0]    add_fb_srt;                   

wire sat_flag_fw;
wire sat_flag_fb;

generate
    genvar ptr_coeff_a;
    genvar ptr_coeff_b;

    for(ptr_coeff_b = 0; ptr_coeff_b < N_COEFFS; ptr_coeff_b = ptr_coeff_b + 1) begin:b2v_coeff_b
        assign coeff_b[ptr_coeff_b] = i_coeff_b[(ptr_coeff_b + 1) * NB_COEFF - 1 -: NB_COEFF];
    end
    for(ptr_coeff_a = 0; ptr_coeff_a < N_COEFFS - 1; ptr_coeff_a = ptr_coeff_a + 1) begin:b2v_coeff_a
        assign coeff_a[ptr_coeff_a] = i_coeff_a[(ptr_coeff_a + 1) * NB_COEFF - 1 -: NB_COEFF];
    end
endgenerate

//Forward

integer ptr_rst_fw;
integer ptr_set_fw;
always @(posedge clock) begin
    if (!i_reset) begin
        for(ptr_rst_fw = 0 ; ptr_rst_fw < N_COEFFS ; ptr_rst_fw = ptr_rst_fw + 1) begin
        x_reg[ptr_rst_fw] <= {NB_DATA_IN{1'b0}};
        end
    end 
    else begin
        if (i_enable) begin
            for(ptr_set_fw = 0 ; ptr_set_fw < N_COEFFS ; ptr_set_fw = ptr_set_fw + 1) begin
                if(ptr_set_fw == 0) begin
                x_reg[ptr_set_fw] <= i_data;
                end
                else begin
                x_reg[ptr_set_fw] <= x_reg[ptr_set_fw - 1];
                end   
            end
        end
    end
end

generate
    genvar ptr_p_fw;
    for(ptr_p_fw = 0; ptr_p_fw < N_COEFFS; ptr_p_fw = ptr_p_fw + 1) begin:prodfw
        assign prod_fw[ptr_p_fw] = coeff_b[ptr_p_fw] * x_reg[ptr_p_fw];
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

// Saturation / Rounding and Truncation module
Sat_Round_Trunc 
#(
    .NB_DATA_IN     (NB_ADD_FW),
    .NBF_DATA_IN    (NBF_ADD_FW),
    .NB_DATA_OUT    (16),
    .NBF_DATA_OUT   (15)
)
u_Sat_Round_Trunc_fw
(
.o_data            (add_fw_srt),
.sat_flag          (sat_flag_fw),
.i_data            (add_fw[N_COEFFS - 2])
);

assign add_fw_expd = $signed({{NBI_ADD_FB - NBI_TRUNC{add_fw_srt[NB_TRUNC - 1]}},add_fw_srt,
                            {NBF_ADD_FB - NBF_TRUNC{1'b0}}});

//Feedback
  
integer ptr_rst_fb;
integer ptr_set_fb;
always @(posedge clock) begin
if (!i_reset) begin
    for(ptr_rst_fb = 0 ; ptr_rst_fb < N_COEFFS - 1 ; ptr_rst_fb = ptr_rst_fb + 1) begin
        y_reg[ptr_rst_fb] <= {NB_DATA_FB{1'b0}};
    end
    end 
else begin
    if (i_enable) begin
        for(ptr_set_fb = 0 ; ptr_set_fb < N_COEFFS - 1 ; ptr_set_fb = ptr_set_fb + 1) begin
            if(ptr_set_fb == 0) begin
                y_reg[ptr_set_fb] <= add_fb_srt;
            end
            else begin
                y_reg[ptr_set_fb] <= y_reg[ptr_set_fb - 1];
            end   
        end
    end
end
end

generate
genvar ptr_p_fb;
for(ptr_p_fb = 0; ptr_p_fb < (N_COEFFS - 1); ptr_p_fb = ptr_p_fb + 1) begin:prodfb
    assign prod_fb[ptr_p_fb] = coeff_a[ptr_p_fb] * y_reg[ptr_p_fb];
end
endgenerate

generate
genvar ptr_a_fb;
for(ptr_a_fb = 0; ptr_a_fb < (N_COEFFS - 1); ptr_a_fb = ptr_a_fb + 1) begin:addersfb
    if (ptr_a_fb == 0)
    assign add_fb[ptr_a_fb] = - prod_fb[ptr_a_fb] - prod_fb[ptr_a_fb + 1];
    else if (ptr_a_fb == N_COEFFS - 2)
    assign add_fb[ptr_a_fb] = add_fb[ptr_a_fb - 1] + add_fw_expd;
    else
    assign add_fb[ptr_a_fb] = add_fb[ptr_a_fb - 1] - prod_fb[ptr_a_fb + 1];
end
endgenerate

Sat_Round_Trunc 
#(
.NB_DATA_IN   (NB_ADD_FB),
.NBF_DATA_IN  (NBF_ADD_FB),
.NB_DATA_OUT  (NB_DATA_FB),
.NBF_DATA_OUT (NBF_DATA_FB)
)
u_Sat_Round_Trunc_fb
(
.o_data               (add_fb_srt),
.sat_flag            (sat_flag_fb),
.i_data     (add_fb[N_COEFFS - 2])
);

//Option 1 (fb res > output res)
Sat_Round_Trunc 
#(
.NB_DATA_IN   (NB_ADD_FB),
.NBF_DATA_IN  (NBF_ADD_FB),
.NB_DATA_OUT  (NB_DATA_OUT),
.NBF_DATA_OUT (NBF_DATA_OUT)
)
u_Sat_Round_Trunc_out
(   
.o_data              (o_data     ),
.sat_flag            (sat_flag_fb),
.i_data     (add_fb[N_COEFFS - 2])
);

//Option 2 (fb res == output res)
// assign o_data = add_fb_srt;
//----------------------------------------------------------
Sat_Round_Trunc 
#(
 .NB_DATA_IN   (NB_DATA_FB),
 .NBF_DATA_IN  (NBF_DATA_FB),
 .NB_DATA_OUT  (NB_DATA_OUT),
 .NBF_DATA_OUT (NBF_DATA_OUT)
)
u_Sat_Round_Trunc_out_d2
(
 .o_data     (o_data_2   ),
 .sat_flag   (sat_flag_fb),
 .i_data     (y_reg[1]   )
);

endmodule
