`timescale 1ns/1ps

`define FILE_PATH "Path to file 'tb_i_noisy_sine.txt'"
`define TOP
// `define PARALLEL
// `define UNFOLDED
module tb_opt_fir ();
parameter NB_DATA_IN    =  8;  
parameter NB_COEFF      =  8;  
parameter N_COEFFS      =  8; 
parameter NB_DATA_OUT   = 19;

wire signed [NB_DATA_OUT - 1 : 0] o_data [3:0];
reg  signed [NB_DATA_IN - 1 : 0]  i_data [3:0];
reg                                   i_enable;
reg                                    i_reset;
reg                                      clock;
reg                                    clock_4; // 4xclock for debugging
reg [NB_SEL - 1 : 0]                       sel;
reg [NB_DATA_IN - 1 : 0]              file_data[0:1023];
reg signed [NB_DATA_IN - 1 : 0]    i_full_data;
reg signed [NB_DATA_OUT - 1 : 0]   o_full_data;
integer i;

localparam N_PARAL = 4;
localparam NB_SEL = $clog2(N_PARAL);

//clock generation
always #40 clock = ~clock;
always #5 clock_4 = ~clock_4; // 4xclock for debugging

always @(posedge clock_4) begin: gen_counter
    if (~i_reset) begin
        sel = {NB_SEL{1'b0}};
    end
    else begin
        if (i_enable) begin
            sel <= sel + {{(NB_SEL - 1){1'b0}},1'b1};
        end
    end
end

always @(*) begin: gen_mux
    case (sel)
        2'b00: o_full_data = o_data[0];
        2'b01: o_full_data = o_data[1];
        2'b10: o_full_data = o_data[2];
        2'b11: o_full_data = o_data[3];
        default: o_full_data = {NB_DATA_OUT{1'b0}};
    endcase
end

always @(*) begin
    case (sel)
        2'b00: i_full_data = i_data[0];
        2'b01: i_full_data = i_data[1];
        2'b10: i_full_data = i_data[2];
        2'b11: i_full_data = i_data[3];
        default: i_full_data = {NB_DATA_IN{1'b0}};
    endcase
end

`ifdef TOP
initial begin: stimulus
    clock   = 1'b0;
    clock_4 = 1'b0;
    @(posedge clock);
    i_enable = 1'b0; //off enable
    i_reset  = 1'b0; //on  reset
    #100
    @(posedge clock);
    i_enable = 1'b1; //on  enable
    i_reset  = 1'b1; //off reset
    #10000
    $finish;
end

`else
initial begin: stimulus
    clock   = 1'b0;
    clock_4 = 1'b0;
    i_data[0] = {NB_DATA_IN{1'b0}}; 
    i_data[1] = {NB_DATA_IN{1'b0}};
    i_data[2] = {NB_DATA_IN{1'b0}};
    i_data[3] = {NB_DATA_IN{1'b0}};

    @(posedge clock);
    i_enable = 1'b0; //off enable
    i_reset  = 1'b0; //on  reset
    #100
    @(posedge clock);
    i_enable = 1'b1; //on  enable
    i_reset  = 1'b1; //off reset

    $readmemb(`FILE_PATH, file_data);

    file_data[0] = {NB_DATA_IN{1'b0}}; 
    file_data[1] = {NB_DATA_IN{1'b0}};
    file_data[2] = {NB_DATA_IN{1'b0}};
    file_data[3] = {NB_DATA_IN{1'b0}};

    file_data[4] = {8'b00000000}; 
    file_data[5] = {8'b00000001};
    file_data[6] = {8'b00000010};
    file_data[7] = {8'b00000011};

    file_data[8]  = {8'b00000100}; 
    file_data[9]  = {8'b00000101};
    file_data[10] = {8'b00000110};
    file_data[11] = {8'b00000111};

    for (i = 0; i < 1024; i = i + 4) begin
        @(posedge clock);
        i_data[0] = file_data[i]    ; 
        i_data[1] = file_data[i + 1];
        i_data[2] = file_data[i + 2];
        i_data[3] = file_data[i + 3];
    end
    $finish;
end
`endif

`ifdef TOP
    top_opt_fir
    #(
        .NB_DATA_IN (NB_DATA_IN ),  
        .NB_COEFF   (NB_COEFF   ),  
        .N_COEFFS   (N_COEFFS   ), 
        .NB_DATA_OUT(NB_DATA_OUT)
    )
    u_top_opt_fir_0
    ( 
        .o_data_0(o_data[0]),
        .o_data_1(o_data[1]),
        .o_data_2(o_data[2]),
        .o_data_3(o_data[3]),  
        .i_enable(i_enable ),
        .i_reset (i_reset  ), 
        .clock   (clock    )   
    );


`elsif PARALLEL
    parallel_fir
    #(
        .NB_DATA_IN (NB_DATA_IN ),  
        .NB_COEFF   (NB_COEFF   ),  
        .N_COEFFS   (N_COEFFS   ), 
        .NB_DATA_OUT(NB_DATA_OUT)
    )
    u_parallel_fir_0
    ( 
        .o_data_0(o_data[0]),
        .o_data_1(o_data[1]),
        .o_data_2(o_data[2]),
        .o_data_3(o_data[3]),
        .i_data_0(i_data[0]),
        .i_data_1(i_data[1]),
        .i_data_2(i_data[2]),
        .i_data_3(i_data[3]),  
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
        .o_data_0(o_data[0]),
        .o_data_1(o_data[1]),
        .o_data_2(o_data[2]),
        .o_data_3(o_data[3]), 
        .i_data_0(i_data[0]),
        .i_data_1(i_data[1]),
        .i_data_2(i_data[2]),
        .i_data_3(i_data[3]),  
        .i_enable(i_enable ),
        .i_reset (i_reset  ), //Low-active reset
        .clock   (clock    )   
    );
`endif
endmodule