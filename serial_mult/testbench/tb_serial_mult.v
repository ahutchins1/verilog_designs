`define TRUNC
// `define SIGNED
module tb_serial_mult ();

parameter NB_DATA_IN   = 4;
parameter NB_DATA_OUT  = 8;

localparam NB_COUNTER = $clog2(NB_DATA_IN);
localparam N_INPUTS = 100;

wire      o_data;
reg     i_data_a;
reg     i_data_b;
reg        i_rst;
reg         i_en;
reg        clock;  
integer      i,j;
wire       valid;

//clock generation
always #5 clock = ~clock;


reg [NB_DATA_IN - 1: 0]  full_input_a[N_INPUTS - 1 : 0];
reg [NB_DATA_IN - 1: 0]  full_input_b[N_INPUTS - 1 : 0];
reg [NB_DATA_IN - 1: 0]  i_a                           ;
reg [NB_DATA_IN - 1: 0]  i_b                           ;

initial begin: stimulus
    for (i = 0; i < N_INPUTS; i = i + 1) begin
        full_input_a[i] = $random;
        full_input_b[i] = $random;
    end
    full_input_a[10] = 4'b1000;
    full_input_b[10] = 4'b1000;
    clock = 1'b0;
    @(posedge clock);
    i_en  = 1'b0;        //off enable
    i_rst = 1'b0;      //on  reset
    #100
    @(posedge clock);
    for (i = 0; i < N_INPUTS; i = i + 1) begin
        for (j = 0; j < NB_DATA_IN; j = j + 1) begin
            @(posedge clock)  
                i_data_a = full_input_a[i][j];
                i_data_b = full_input_b[i][j];
            if (valid) begin
                i_a = full_input_a[i];
                i_b = full_input_b[i];
            end
            if (j == 0) begin
                i_rst = 1'b1;    //off reset
                i_en  = 1'b1;      //on  enable
            end
        end
    end
    #100
    $finish;
end

`ifdef TRUNC
assign valid = (tb_serial_mult.u_trunc_serial_mult.counter == 7) ? 1 : 0;
trunc_serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_trunc_serial_mult
(
    .o_data  (o_data  ),
    .i_data_a(i_data_a),
    .i_data_b(i_data_b), 
    .i_rst   (i_rst   ),
    .i_en    (i_en    ),
    .clk     (clock   )
);
`elsif SIGNED
assign valid = (tb_serial_mult.u_sig_serial_mult.counter == 0) ? 1 : 0;
sig_serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_sig_serial_mult
(
    .o_data  (o_data  ),
    .i_data_a(i_data_a),
    .i_data_b(i_data_b), 
    .i_rst   (i_rst   ),
    .i_en    (i_en    ),
    .clk     (clock   )
);
`else
assign valid = (tb_serial_mult.u_serial_mult.counter == 0) ? 1 : 0;
serial_mult 
#(
    .NB_DATA_IN (NB_DATA_IN ), 
    .NB_DATA_OUT(NB_DATA_OUT)
)
u_serial_mult
(
    .o_data  (o_data  ),
    .i_data_a(i_data_a),
    .i_data_b(i_data_b), 
    .i_rst   (i_rst   ),
    .i_en    (i_en    ),
    .clk     (clock   )
);
`endif
endmodule