module parallel_fir
#(
    parameter NB_DATA_IN    =  8, // Number of bits of the input data
    parameter NB_COEFF      =  8, // Number of bits of the coefficients 
    parameter N_COEFFS      =  8, // Number of coefficients of the FIR filter
    parameter NB_DATA_OUT   = 19  // Number of bits of the output data
)
( 
    output signed [NB_DATA_OUT - 1 : 0] o_data_0,
    output signed [NB_DATA_OUT - 1 : 0] o_data_1,
    output signed [NB_DATA_OUT - 1 : 0] o_data_2,
    output signed [NB_DATA_OUT - 1 : 0] o_data_3,
    input signed  [NB_DATA_IN - 1 : 0]  i_data_0,
    input signed  [NB_DATA_IN - 1 : 0]  i_data_1,
    input signed  [NB_DATA_IN - 1 : 0]  i_data_2,
    input signed  [NB_DATA_IN - 1 : 0]  i_data_3,  
    input                                   i_en,
    input 				                   i_rst, //Low-active reset
    input 				                     clk      
);      

localparam N_PARAL = 4;                               // Number of parallel FIR filters
localparam NS_REG = NB_DATA_IN + N_PARAL - 1;         // Number of samples in the regressor

// Regressor

reg  signed [NB_DATA_IN - 1 : 0]  reg_data [NS_REG - 1 : 0]; // Regressor data
wire signed [NB_DATA_IN - 1 : 0]  i_data [N_PARAL - 1 : 0] ;
wire signed [NB_DATA_OUT - 1 : 0] o_data [N_PARAL - 1 : 0] ;

assign i_data[0] = i_data_0;
assign i_data[1] = i_data_1;
assign i_data[2] = i_data_2;
assign i_data[3] = i_data_3;

integer i;
always @(posedge clk) begin
    if (~i_rst) begin
        for (i = 0; i < NS_REG; i = i + 1) begin
            reg_data[i] <= {NB_DATA_IN{1'b0}};
        end
    end
    else begin
        if (i_en) begin
            for (i = 0; i < NS_REG; i = i + 1) begin
                if (i >= (NS_REG - N_PARAL)) begin: zero_delay_samples
                    reg_data[i] <= i_data[i - (NS_REG - N_PARAL)];
                end
                else begin: one_and_two_delay_samples
                    reg_data[i] <= reg_data[i + N_PARAL];
                end
            end
        end
    end
end

// Generate fir filters
fir_filter
#(
    .NB_DATA_IN (NB_DATA_IN ),  
    .NB_COEFF   (NB_COEFF   ),  
    .N_COEFFS   (N_COEFFS   ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_fir_0
( 
    .o_data(o_data_0), 
    .i_data_0(reg_data[7]),
    .i_data_1(reg_data[6]),
    .i_data_2(reg_data[5]),
    .i_data_3(reg_data[4]),
    .i_data_4(reg_data[3]),
    .i_data_5(reg_data[2]),
    .i_data_6(reg_data[1]),
    .i_data_7(reg_data[0]),  
    .i_en  (i_en ),
    .i_rst (i_rst),
    .clk   (clk  )      
);

fir_filter
#(
    .NB_DATA_IN (NB_DATA_IN ),  
    .NB_COEFF   (NB_COEFF   ),  
    .N_COEFFS   (N_COEFFS   ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_fir_1
( 
    .o_data(o_data_1), 
    .i_data_0(reg_data[8]),
    .i_data_1(reg_data[7]),
    .i_data_2(reg_data[6]),
    .i_data_3(reg_data[5]),
    .i_data_4(reg_data[4]),
    .i_data_5(reg_data[3]),
    .i_data_6(reg_data[2]),
    .i_data_7(reg_data[1]),  
    .i_en  (i_en ),
    .i_rst (i_rst),
    .clk   (clk  )      
);

fir_filter
#(
    .NB_DATA_IN (NB_DATA_IN ),  
    .NB_COEFF   (NB_COEFF   ),  
    .N_COEFFS   (N_COEFFS   ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_fir_2
( 
    .o_data(o_data_2), 
    .i_data_0(reg_data[9]),
    .i_data_1(reg_data[8]),
    .i_data_2(reg_data[7]),
    .i_data_3(reg_data[6]),
    .i_data_4(reg_data[5]),
    .i_data_5(reg_data[4]),
    .i_data_6(reg_data[3]),
    .i_data_7(reg_data[2]),  
    .i_en  (i_en ),
    .i_rst (i_rst),
    .clk   (clk  )      
);

fir_filter
#(
    .NB_DATA_IN (NB_DATA_IN ),  
    .NB_COEFF   (NB_COEFF   ),  
    .N_COEFFS   (N_COEFFS   ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_fir_3
( 
    .o_data(o_data_3), 
    .i_data_0(reg_data[10]),
    .i_data_1(reg_data[9]),
    .i_data_2(reg_data[8]),
    .i_data_3(reg_data[7]),
    .i_data_4(reg_data[6]),
    .i_data_5(reg_data[5]),
    .i_data_6(reg_data[4]),
    .i_data_7(reg_data[3]),  
    .i_en  (i_en ),
    .i_rst (i_rst),
    .clk   (clk  )      
);

endmodule
