`timescale 1ns/1ps

`define FILE_PATH "Path to file 'tb_i_noisy_sine.txt'"

module tb_iir ();
parameter NB_IN      = 16;
parameter NBF_IN     = 15;
parameter NB_COEFF   = 16;
parameter NBF_COEFF  = 15;
parameter N_COEFF    =  3;
parameter NB_OUT     = 16;
parameter NBF_OUT    = 15;

wire  signed [NB_OUT - 1 : 0]                 o_data;
wire  signed [NB_OUT - 1 : 0]               o_data_2;
reg signed [NB_IN - 1 : 0]                    i_data;
reg                                         i_enable;
reg                                          i_reset;
reg                                            clock;

reg [NB_IN - 1 : 0] file_data[0:1023];
integer i;
integer u = 1;

//clock generation
always #5 clock = ~clock;

initial begin: stimulus
clock = 1'b0;
@(posedge clock);
i_enable = 1'b0; //off enable
i_reset  = 1'b0; //on  reset
#100
@(posedge clock);
// i_reset  = 1'b1; //off reset
i_enable = 1'b1; //on  enable

$readmemb(`FILE_PATH, file_data);

for (i = 0; i < 1024; i = i + 1) begin
    @(posedge clock);
    i_data = file_data[i]; 
  if (i > 10 && u == 1) begin
    @(posedge clock);
    i_reset  = 1'b1;
    u = 0;
  end
end

$finish;
end

iir_filter
#(
  .NB_DATA_IN   (NB_IN    ),
  .NBF_DATA_IN  (NBF_IN   ),
  .NB_COEFF     (NB_COEFF ),
  .NBF_COEFF    (NBF_COEFF),
  .N_COEFFS     (N_COEFF  ),
  .NB_DATA_OUT  (NB_OUT   ),
  .NBF_DATA_OUT (NBF_OUT  )
)
u_iir_filter
( 
  .o_data   (o_data  ),
  .o_data_2 (o_data_2),
  .i_data   (i_data  ), 
  .i_enable (i_enable),
  .i_reset  (i_reset ),
  .clock    (clock   )   
);

endmodule