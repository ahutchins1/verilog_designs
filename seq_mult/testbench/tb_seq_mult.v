module tb_seq_mult ();

parameter NB_DATA_IN   = 4;
parameter NBF_DATA_IN  = 3;
parameter NB_DATA_OUT  = 4;
parameter NBF_DATA_OUT = 3;

localparam NB_COUNTER = $clog2(NB_DATA_IN);
localparam N_INPUTS = 50;

wire                     o_data                      ;
reg                      i_data                      ;
reg [NB_DATA_IN - 1 : 0] coeff                       ;
reg                      i_rst                       ;
reg                      i_en                        ;
reg                      clock                       ;  
reg [NB_DATA_IN - 1: 0]  full_input[N_INPUTS - 1 : 0];
reg [NB_DATA_IN - 1: 0]  i_word                      ;
integer i,j;

//clock generation
always #5 clock = ~clock;

initial begin: stimulus
    for (i = 0; i < N_INPUTS; i = i + 1) begin
        full_input[i] = $random;
    end
    coeff = 4'b1101;
    clock = 1'b0;
    @(posedge clock);
    i_en = 1'b0;        //off enable
    i_rst  = 1'b0;      //on  reset
    #100
    i_data = 1'b0;
    @(posedge clock);        
    for (i = 0; i < N_INPUTS; i = i + 1) begin
        for (j = 0; j < NB_DATA_IN; j = j + 1) begin
            @(posedge clock)
            i_data = full_input[i][j];
            i_word = full_input[i];
            if (j == 1) begin
                i_rst  = 1'b1;    //off reset
                i_en = 1'b1;      //on  enable
            end
        end
    end
    #100
    $finish;
end

seq_mult 
#(
    .NB_DATA_IN  (NB_DATA_IN  ),
    .NBF_DATA_IN (NBF_DATA_IN ),
    .NB_DATA_OUT (NB_DATA_OUT ),
    .NBF_DATA_OUT(NBF_DATA_OUT)
)
u_seq_mult
(
    .o_data(o_data),
    .i_data(i_data),
    .coeff (coeff ),
    .i_rst (i_rst ),
    .i_en  (i_en  ),
    .clock (clock ) 
);
endmodule