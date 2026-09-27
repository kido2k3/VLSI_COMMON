//===========================================================================
//-- File Version    : 1.00
//-- Date            : 25/11/25
//-- Author          : phong
//-- IP Name         : asc_fifo (Asynchronous FIFO)
//-- History         : ver.1.00 (25/11/24) 1st release
//--
//===========================================================================
module asc_fifo #(
    parameter P_DEPTH       = 8, 
    parameter P_DATA_W      = 8
)(
    // WRITE INTERFACE
    input                               wclk, 
    input                               wrst_n, 
    input                               w_en, 
    input           [P_DATA_W - 1   :0] i_data,
    output                              o_full,
    // READ INTERFACE
    input                               rclk, 
    input                               rrst_n, 
    input                               r_en,
    output                              o_empty,
    output  reg     [P_DATA_W - 1   :0] o_data
);
//---------------------------------------------------------------------------
    // PARAMETER HERE
    // localparam  P_PTR_W = $clog2(P_DEPTH) + 1; // log2(P_DEPTH) + 1
    localparam  P_PTR_W = 4; // log2(P_DEPTH) + 1
//---------------------------------------------------------------------------
    // VARIABLE
    reg [P_PTR_W - 1 : 0] g_wptr_sync;
    reg [P_PTR_W - 1 : 0] g_rptr_sync;
    reg [P_PTR_W - 1 : 0] b_wptr; 
    reg [P_PTR_W - 1 : 0] b_rptr;
    reg [P_PTR_W - 1 : 0] g_wptr; 
    reg [P_PTR_W - 1 : 0] g_rptr;
//---------------------------------------------------------------------------
    //write pointer to read clock domain
    synchronizer #(
        .P_DATA_W    (P_PTR_W)
    ) u_synchronizer0 (
        .clk         (rclk),
        .rst_n       (rrst_n),
        .i_data      (g_wptr),
        .o_data      (g_wptr_sync)
    );
    //read pointer to write clock domain
    synchronizer #(
        .P_DATA_W    (P_PTR_W)
    ) u_synchronizer1 (
        .clk         (wclk),
        .rst_n       (wrst_n),
        .i_data      (g_rptr),
        .o_data      (g_rptr_sync)
    );
//---------------------------------------------------------------------------
    wptr_handler #(
        .P_PTR_W          (P_PTR_W)
    ) u_wptr_handler (
        .wclk             (wclk),
        .wrst_n           (wrst_n),
        .i_w_en           (w_en),
        .i_g_rptr_sync    (g_rptr_sync),
        .o_b_wptr         (b_wptr),
        .o_g_wptr         (g_wptr),
        .o_full           (o_full)
    );
    rptr_handler #(
        .P_PTR_W          (P_PTR_W)
    ) u_rptr_handler (
        .rclk             (rclk),
        .rrst_n           (rrst_n),
        .i_r_en           (r_en),
        .i_g_wptr_sync    (g_wptr_sync),
        .o_b_rptr         (b_rptr),
        .o_g_rptr         (g_rptr),
        .o_empty          (o_empty)
    );
//---------------------------------------------------------------------------
    fifo_mem #(
        .P_DEPTH     (P_DEPTH),
        .P_DATA_W    (P_DATA_W),
        .P_PTR_W     (P_PTR_W)        // log2(P_DEPTH) + 1
    ) u_fifo_mem (
        // WRITE INTERFACE
        .wclk        (wclk),
        .w_en        (w_en),
        .b_wptr      (b_wptr),
        .i_data      (i_data),
        .i_full      (o_full),
        // READ INTERFACE
        .rclk        (rclk),
        .r_en        (r_en),
        .b_rptr      (b_rptr),
        .i_empty     (o_empty),
        .o_data      (o_data)
    );
//---------------------------------------------------------------------------
endmodule
//===========================================================================