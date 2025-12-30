//===========================================================================
//-- File Version    : 1.00
//-- Date            : 25/11/25
//-- Author          : kido
//-- IP Name         : syn_fifo (Synchronous FIFO)
//-- History         : ver.1.00 (25/11/24) 1st release
//--
//===========================================================================
module syn_fifo #(
    parameter                           P_DATA_W    = 8,
    parameter                           P_DEPTH     = 8
)(
    input                               clk, 
    input                               rst_n, 
    input       [P_DATA_W - 1   : 0]    i_data,
    input                               i_wr_en,
    input                               i_rd_en,
    output                              o_full,
    output                              o_empty,
    output reg  [P_DATA_W - 1   : 0]    o_data
);
//---------------------------------------------------------------------------
    // PARAMETER HERE
    localparam  P_PTR_W = $clog2(P_DEPTH) + 1;
//---------------------------------------------------------------------------
    // VARIABLE
    reg     [P_PTR_W - 1        : 0] wr_ptr;    // write pointer
    reg     [P_PTR_W - 1        : 0] rd_ptr;    // read pointer
    reg     [P_DATA_W - 1       : 0] fifo [P_DEPTH];
 
//---------------------------------------------------------------------------
    always @(posedge clk) begin
        if(!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            o_data <= 0;
        end else begin
            // wirte data
            if(i_wr_en && !o_full) begin
                wr_ptr <= wr_ptr + 1;
                fifo[wr_ptr[0 +: (P_PTR_W - 1)]] <= i_data;
            end
//---------------------------------------------------------------------------
            // read data
            if(i_rd_en && !o_empty) begin
                rd_ptr <= rd_ptr + 1;
                o_data <= fifo[rd_ptr[0 +: (P_PTR_W - 1)]];
            end
        end
    end
//---------------------------------------------------------------------------
    // check empty or full
    assign {o_full, o_empty} =      (wr_ptr == rd_ptr) ? 2'b01 :
                                    (wr_ptr[0 +: (P_PTR_W - 1)] == rd_ptr[0 +: (P_PTR_W - 1)]) ? 2'b10 : 2'b00;
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
endmodule
//===========================================================================