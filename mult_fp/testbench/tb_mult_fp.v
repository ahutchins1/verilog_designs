`timescale 1ns/100ps

module tb_mult_fp ();
    parameter NB_IN  = 13;
    parameter NB_OUT = 13;
    parameter NB_M   =  8; //NB of mantissa
    parameter NB_S   =  1; //NB of sign
    parameter NB_E   =  4; //NB of exponent

    wire [NB_OUT - 1 : 0]   y;

    reg  [NB_IN - 1 : 0]  x_A;
    reg  [NB_IN - 1 : 0]  x_B;

    initial begin: stimulus

        //0 * 0 
        x_A = 13'b0000000000000;
        x_B = 13'b0000000000000;
        #10

        //14 * (-16) = -224 = 13'b1111011000000 without exponent normalization
        x_A = 13'b0101011000000;
        x_B = 13'b1101100000000;
        #10

        // 222 * (1.9921875) = 442.265625 -> 442 = 13'b0111110111010 
        //with exponent normalization and mantissa rounding and truncation
        x_A = 13'b0111010111100;
        x_B = 13'b0011111111110;
        #10

        //overflow -> 13'b0111111111111
        x_A = 13'b0111111111111; //s=0, e=15, m=255 -> 511
        x_B = 13'b0111111111110; //s=0, e=15, m=254 -> 510
        #10

        //14 * 0 
        x_A = 13'b0101011100000;
        x_B = 13'b0000000000000;
        #10

        //0.0625 * (-50.625) = -3.1640625 = 13'b1100010010101
        x_A = 13'b0001100000000;
        x_B = 13'b1110010010101;
        #10

      $finish;
    end

  //always #5 clock = ~clock;

  mult_fp
    #(
      .NB_IN  (NB_IN ),
      .NB_OUT (NB_OUT),
      .NB_M     (NB_M),
      .NB_S     (NB_S),
      .NB_E     (NB_E)
      )
    u_mult_fp
      (
        .y    (y),
        .x_A  (x_A),
        .x_B  (x_B)
      );


    
endmodule