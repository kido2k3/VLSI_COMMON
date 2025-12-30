//===========================================================================
//-- File Version    : 1.00
//-- Date            : 25/11/25
//-- Author          : phong
//-- IP Name         : fifo_mem  (fifo memory)
//-- History         : ver.1.00 (25/11/24) 1st release
//--
//===========================================================================
module fifo_mem #(
    parameter P_DEPTH       = 8, 
    parameter P_DATA_W      = 8, 
    parameter P_PTR_W       = 4     // log2(P_DEPTH) + 1
) (
    // WRITE INTERFACE
    input                               wclk, 
    input                               w_en, 
    input           [P_PTR_W - 1    :0] b_wptr,
    input           [P_DATA_W - 1   :0] i_data,
    input                               i_full,
    // READ INTERFACE
    input                               rclk, 
    input                               r_en,
    input           [P_PTR_W - 1    :0] b_rptr,
    input                               i_empty,
    output  reg     [P_DATA_W - 1   :0] o_data
);
//---------------------------------------------------------------------------
    // PARAMETER HERE
//---------------------------------------------------------------------------
    // VARIABLE
    reg [P_DATA_W - 1 : 0] fifo[P_DEPTH];
//---------------------------------------------------------------------------
    always@(posedge wclk) begin
        if(w_en & !i_full) begin
            fifo[b_wptr[P_PTR_W - 2 : 0]] <= i_data;
        end
    end
//---------------------------------------------------------------------------
    assign o_data = fifo[b_rptr[P_PTR_W - 2 : 0]];
endmodule
//===========================================================================