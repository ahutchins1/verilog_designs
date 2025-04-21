`timescale 1ns/1ps
//`define SYMM
`define FILE_PATH "Path to file 'tb_i_noisy_sine.txt'"

module tb_da_fir();

    parameter NB_DATA_IN  = 8;
    parameter NB_COEFF    = 16;
    parameter NB_DATA_OUT = 28;

    wire signed [NB_DATA_OUT - 1 : 0] o_data  ;
    reg                               i_data  ;
    reg                               i_reset ;
    reg                               i_enable;
    reg                               clock   ;

    reg [NB_DATA_IN - 1 : 0] file_data [0 : 1023];
    reg [NB_DATA_IN - 1 : 0] sin;
    integer i,j;

    //clock generation
    always #5 clock =~ clock;

    initial begin
        clock = 1'b0;
        @(posedge clock);
        i_reset = 1'b0;
        i_enable = 1'b0;
        #100
        @(posedge clock);
        i_reset = 1'b1;
        $readmemb(`FILE_PATH, file_data);
        for (i = 2; i < 1024; i = i + 1) begin
            for (j = 0; j < NB_DATA_IN; j = j + 1) begin
                @(posedge clock)
                i_data = file_data[i][j];
                i_enable = 1'b1;
                sin = file_data[i];
            end
        end
        $finish;
    end

`ifdef SYMM
symm_da_rom_fir
    #(
        //Parameters
        .NB_DATA_IN   (NB_DATA_IN  ),
        .NB_COEFF     (NB_COEFF    ),
        .NB_DATA_OUT  (NB_DATA_OUT )
    )
    u_symm_da_rom_fir_filter
    (
        //Ports
        .o_data  (o_data  ),
        .i_data  (i_data  ),
        .i_reset (i_reset ),
        .i_enable(i_enable),
        .clock   (clock   )
    );
`else
da_rom_fir_filter
    #(
        //Parameters
        .NB_DATA_IN   (NB_DATA_IN  ),
        .NB_COEFF     (NB_COEFF    ),
        .NB_DATA_OUT  (NB_DATA_OUT )
    )
    u_da_rom_fir_filter
    (
        //Ports
        .o_data  (o_data  ),
        .i_data  (i_data  ),
        .i_reset (i_reset ),
        .i_enable(i_enable),
        .clock   (clock   )
    );
`endif

endmodule