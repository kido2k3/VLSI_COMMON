//===========================================================================
//-- File Version    : 1.00
//-- Date            : 25/11/25
//-- Author          : phong
//-- IP Name         : wptr_handler  (write pointer handle)
//-- History         : ver.1.00 (25/11/24) 1st release
//--
//===========================================================================
module wptr_handler #(
    parameter P_PTR_W = 4
)(
    input                               wclk, 
    input                               wrst_n, 
    input                               i_w_en, 
    input       [P_PTR_W - 1    : 0]    i_g_rptr_sync, 
    output  reg [P_PTR_W - 1    : 0]    o_b_wptr,
    output  reg [P_PTR_W - 1    : 0]    o_g_wptr,
    output  reg                         o_full
);
//---------------------------------------------------------------------------
    // PARAMETER HERE
//---------------------------------------------------------------------------
    // VARIABLE
    reg [P_PTR_W - 1 : 0] b_wptr_nxt;
    reg [P_PTR_W - 1 : 0] g_wptr_nxt;
    wire                  full_nxt;
//---------------------------------------------------------------------------
    assign b_wptr_nxt = o_b_wptr + (i_w_en & !o_full);
    assign g_wptr_nxt = (b_wptr_nxt >>1) ^ b_wptr_nxt;
//---------------------------------------------------------------------------
    always @(posedge wclk) begin
        if(!wrst_n) begin
            o_b_wptr <= 0; // set default value
            o_g_wptr <= 0;
            o_full   <= 0;
        end else begin
            o_b_wptr <= b_wptr_nxt;
            o_g_wptr <= g_wptr_nxt;
            o_full   <= full_nxt;
        end
    end
//---------------------------------------------------------------------------
    assign full_nxt = (g_wptr_nxt == {~i_g_rptr_sync[P_PTR_W - 1 -: 2], i_g_rptr_sync[0 +: P_PTR_W - 2]});
//---------------------------------------------------------------------------
endmodule
//===========================================================================