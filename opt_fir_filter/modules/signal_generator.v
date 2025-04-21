module signal_generator
(
   output [NB_DATA - 1 : 0] o_signal_0,
   output [NB_DATA - 1 : 0] o_signal_1,
   output [NB_DATA - 1 : 0] o_signal_2,
   output [NB_DATA - 1 : 0] o_signal_3,
   input                       i_reset,  
   input                       i_clock          
);

   // Parameters
   parameter NB_DATA    = 8;
   parameter NB_COUNT   = 10;
   parameter MEM_INIT_FILE = "C:/Curso_DDA/GP05/lab5_2_rtl/testbench/tb_i_noisy_sine.txt";


   integer i;
   reg [NB_COUNT  - 1 : 0] counter;
   reg [NB_DATA  - 1 : 0]  data[0:1023];

  initial begin
    if (MEM_INIT_FILE != "") begin
      $readmemb(MEM_INIT_FILE, data);
    end
  end

   always@(posedge i_clock or negedge i_reset) begin
      if(!i_reset) begin
         counter  <= {NB_COUNT{1'b0}};
   end
      else begin
         counter  <= counter + {{(NB_COUNT - 1){1'b0}},{1'b1}};
      end
   end

   assign o_signal_0 = data[counter];
   assign o_signal_1 = data[counter + {{(NB_COUNT - 2){1'b0}},{2'b01}}];
   assign o_signal_2 = data[counter + {{(NB_COUNT - 2){1'b0}},{2'b10}}];
   assign o_signal_3 = data[counter + {{(NB_COUNT - 2){1'b0}},{2'b11}}];


endmodule