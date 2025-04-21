`timescale 1ns/1ps
`define NO_FILE
`define FILE_PATH "Path to file 'tb_i_noisy_sine.txt'"

module tb_serial_fir_filter ();

parameter NB_DATA_IN   = 4;
parameter NB_DATA_OUT  = 4;

localparam NB_COUNTER = $clog2(NB_DATA_IN + NB_DATA_IN);
localparam N_INPUTS = 1024;

wire      o_data;
reg       i_data;
reg    i_coeff_0;
reg    i_coeff_1;
reg    i_coeff_2;
reg        i_rst;
reg         i_en;
reg        clock;  
integer      i,j;
wire       valid;
wire [NB_COUNTER - 1 : 0] counter;

assign counter = tb_serial_fir_filter.u_serial_fir_filter.counter;
assign valid = (counter == 7) ? 1 : 0;

//clock generation
always #5 clock = ~clock;

reg [NB_DATA_IN - 1 : 0]  fi_data    [0 : N_INPUTS - 1];
reg [NB_DATA_IN - 1 : 0]  fi_data_full                 ;
reg [NB_DATA_IN - 1 : 0]  fi_coeff_0                   ;
reg [NB_DATA_IN - 1 : 0]  fi_coeff_1                   ;
reg [NB_DATA_IN - 1 : 0]  fi_coeff_2                   ;

initial begin: stimulus
    `ifdef NO_FILE
    for (i = 0; i < N_INPUTS; i = i + 1) begin
        fi_data[i] = $random;
    end
    `else
    $readmemb(`FILE_PATH, fi_data);
    `endif

    fi_data[1] = 4'b0000;
    fi_data[2] = 4'b0000;
    fi_data[3] = 4'b0000;
    fi_data[4] = 4'b0000;

    fi_data[5] = 4'b1001;
    fi_data[6] = 4'b1001;
    fi_data[7] = 4'b0110;
    fi_data[8] = 4'b1010;

    fi_coeff_0 = 4'b0111;
    fi_coeff_1 = 4'b1000;
    fi_coeff_2 = 4'b0111;

    clock = 1'b0;
    @(posedge clock);
    i_en  = 1'b0;          //off enable
    i_rst = 1'b0;          //on  reset
    #100
    i_data    = 1'b0;
    i_coeff_0 = 1'b0;
    i_coeff_1 = 1'b0;
    i_coeff_2 = 1'b0;
    i_rst = 1'b1;          //off reset
    i_en  = 1'b1;          //on  enable
    i = 0;
    
    while (i < N_INPUTS) begin 
        if (valid) begin
            i = i + 1;
            fi_data_full = fi_data[i];
            for (j = 0; j < NB_DATA_IN; j = j + 1) begin 
                i_data = fi_data[i][j];
                i_coeff_0 = fi_coeff_0[j];
                i_coeff_1 = fi_coeff_1[j];
                i_coeff_2 = fi_coeff_2[j];
                @(posedge clock);
            end
        end
        @(posedge clock);
    end
    #100
    $finish;
end

serial_fir_filter 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT),
    .N_COEFF    (3)
)
u_serial_fir_filter
(
    .o_data   (o_data   ),
    .i_data   (i_data   ),
    .i_coeff({i_coeff_2,i_coeff_1,i_coeff_0}),
    .i_rst    (i_rst    ),
    .i_en     (i_en     ),
    .clk      (clock    )
);



endmodule