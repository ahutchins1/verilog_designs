// Distributed Arithmetic based FIR Filter
// Uses a table with pre-calculated results to avoid using multipliers
// Reduced complexity but also throughput
// Serial processing
// Coeffs: h = [-0.0456 -0.1703 0.0696 0.3094 0.4521 0.3094 0.0696 -0.1703 -0.0456]
// Coeffs format S(16.15)
// Input  format S (8.7)
// Output format S(28.22)


module da_rom_fir_filter
#(
    //Parameters
    parameter NB_DATA_IN  = 8,
    parameter NB_COEFF    = 16,
    parameter NB_DATA_OUT = 28
)
(
    //Ports
    output reg signed [NB_DATA_OUT - 1 : 0] o_data  ,
    input                                   i_data  ,
    input                                   i_reset ,
    input                                   i_enable,
    input                                   clock
);

localparam N_COEFFS   = 9;
localparam NB_ROM     = NB_COEFF + $clog2(N_COEFFS);
localparam N_ADDR_ROM = 2**N_COEFFS;
localparam NB_COUNTER = $clog2(NB_DATA_IN);

reg  signed [NB_DATA_IN - 1 : 0]  x_reg    [N_COEFFS - 1 : 0]  ;
reg  signed [NB_ROM - 1 : 0 ]     rom_data [0 : N_ADDR_ROM - 1];
reg         [N_COEFFS - 1 : 0]    rom_addr                     ;
reg  signed [NB_ROM - 1 : 0 ]     rom_read                     ;
wire signed [NB_DATA_OUT - 1 : 0] sum                          ;    
reg  signed [NB_DATA_OUT - 1 : 0] acc                          ;
reg         [NB_COUNTER - 1 : 0]  counter                      ;  //counter for processed bits

//Load ROM (based on coefficients) from a file
initial begin
    $readmemh("C:/Curso_DDA/GP04/E4_4/da_fir_rtl/mem_files/rom_hex.mem", rom_data);
end
//------------------------------------------------------------------------------------

//Shift Register
integer ptr_rst, ptr_set;
always @(posedge clock or negedge i_reset) begin: shift_register
    if(!i_reset) begin
        for (ptr_rst = 0; ptr_rst < N_COEFFS; ptr_rst = ptr_rst + 1) begin
            x_reg[ptr_rst] <= {NB_DATA_IN{1'b0}};
        end
        counter <= {(NB_COUNTER){1'b0}};
        acc     <= {(NB_ROM){1'b0}};
    end
    else begin
        if (i_enable) begin
            counter  <= counter + 1; 
            x_reg[0] <= {i_data, x_reg[0][NB_DATA_IN - 1 : 1]};
            for (ptr_set = 1; ptr_set < N_COEFFS; ptr_set = ptr_set + 1) begin
                x_reg[ptr_set] <= {x_reg[ptr_set - 1][0], x_reg[ptr_set][NB_DATA_IN - 1 : 1]};  //Register initialization
            end
                if (counter == (NB_DATA_IN - 1)) begin
                    acc    <= {(NB_DATA_OUT){1'b0}};
                    o_data <= sum;
                end    
                else begin
                    acc   <= sum ; 
                end
        end
    end
end

//ROM reading
integer ptr_addr;
always @(*) begin
    rom_addr = 0;
    for (ptr_addr = 0; ptr_addr < N_COEFFS; ptr_addr = ptr_addr + 1) begin
        rom_addr = rom_addr | (x_reg[ptr_addr][0] << ptr_addr);
    end
    rom_read = (counter == (NB_DATA_IN - 1)) ? (-(rom_data[rom_addr])) : (rom_data[rom_addr]);           
end

//Sum of the aligned partial products
assign sum = ($signed(acc) + $signed({rom_read,{(NB_DATA_OUT-NB_ROM){1'b0}}})) >>> 1;                               

endmodule