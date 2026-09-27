//===========================================================================
//-- File Version    : 1.00
//-- Date            : 25/11/25
//-- Author          : phong
//-- IP Name         : tb_asc_fifo
//-- History         : ver.1.00 (25/11/25) 1st release
//--
//===========================================================================
`timescale 10ns/1ns
module tb_asc_fifo;
//---------------------------------------------------------------------------
    reg end_block_flag [4];
    reg wait_for_rst;
//---------------------------------------------------------------------------
    // INSERT VARIABLE HERE
    parameter P_DEPTH       = 8; 
    parameter P_DATA_W      = 8;
    parameter P_WR_CYCLE    = 10;
    parameter P_RD_CYCLE    = 12;
    // WRITE INTERFACE
    reg                               wclk; 
    reg                               wrst_n; 
    reg                               w_en = 0; 
    reg           [P_DATA_W - 1   :0] i_data = 0;
    wire                              o_full;
    // READ INTERFACE
    reg                               rclk; 
    reg                               rrst_n; 
    reg                               r_en = 0;
    wire                              o_empty;
    wire          [P_DATA_W - 1   :0] o_data;
//---------------------------------------------------------------------------;
    // CLK_GEN
    initial begin
        wclk = 0;
        forever #(P_WR_CYCLE / 2) wclk = ~wclk;
    end
    initial begin
        rclk = 0;
        forever #(P_RD_CYCLE / 2) rclk = ~rclk;
    end
//---------------------------------------------------------------------------
    // RST_GEN
    initial begin
        wrst_n = 0;
        @(posedge wclk); 
        #0.1;
        wrst_n = 1;
    end
    initial begin
        rrst_n = 0;
        @(posedge rclk); 
        #0.1;
        rrst_n = 1;
        wait_for_rst = 1;
    end
//---------------------------------------------------------------------------
    // instantiate module here
    asc_fifo #(
        .P_DEPTH     (P_DEPTH),
        .P_DATA_W    (P_DATA_W)
    ) u_asc_fifo (
        // WRITE INTERFACE
        .wclk        (wclk),
        .wrst_n      (wrst_n),
        .w_en        (w_en),
        .i_data      (i_data),
        .o_full      (o_full),
        // READ INTERFACE
        .rclk        (rclk),
        .rrst_n      (rrst_n),
        .r_en        (r_en),
        .o_empty     (o_empty),
        .o_data      (o_data)
    );
//---------------------------------------------------------------------------
    initial begin
        foreach (end_block_flag[i]) begin
            end_block_flag[i] = 0;
        end
    end
//---------------------------------------------------------------------------
    initial begin : driver
        $display ("//=====================================//");
        $display ("//-- [%8d] Simulation Start !!! --//", $time);
        $display ("//=====================================//");
//---------------------------------------------------------------------------
        // INITIAL DATA HERE
        wait_for_rst = 0;
        wait(wait_for_rst);
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
        // CODE HERE
//---------------------------------------------------------------------------
        // case 1: write data 8 times
        for (int i=0; i < 8; ++i) begin
            #0.1 i_data  = i;
            r_en = 0;
            w_en = 1;
            $display("%t: write data: %d", $time, i_data);
            @(posedge wclk);
        end
//---------------------------------------------------------------------------
        // case 2: read data 8 times
        for (int i=0; i < 8; ++i) begin
            #0.1 r_en = 1;
            w_en = 0;
            #0.1;
            $display("%t: read data: %d", $time, o_data);
            @(posedge rclk);
        end
//---------------------------------------------------------------------------
        @(posedge wclk);
        #5;
        end_block_flag[0] = 1;
    end
//---------------------------------------------------------------------------
    // OTHER CODE
    initial begin : monitor
        // forever begin
        //     $write("%4d: rst_n = %b , i_data = %d, w_en = %d, r_en = %d --> ", $time, rst_n, i_data, w_en, r_en);
        //     #0.2;
        //     $display("o_full = %d, o_empty = %d, o_data = %d", o_full, o_empty, o_data);
        //     @(posedge clk);
        //     if(end_block_flag[0]) begin
        //         break;
        //     end
        // end
        end_block_flag[1] = 1;
    end
//---------------------------------------------------------------------------
    initial begin
        wait(end_block_flag[0] & end_block_flag[1]);
        $display ("//===================================//");
        $display ("//-- [%8d] Simulation End !!! --//", $time);
        $display ("//===================================//");
        $finish;
    end
//---------------------------------------------------------------------------;
    initial begin
        // $dumpfile();     // $dumpfile(<filename>);
        // $dumpvars (0);        // Dumps all variables from all module instances
        // $dumpvars (0, tb_switch_modeling);    // Dumps all variables within module 'tb' and in all sub-modules
        // $dumpvars (1, tb);    // Dumps all variables within module 'tb', not in any sub-modules
        // $dumpvars (0, tb.ram_ctrl, tb.alu2.a);  // Dumps all variables in 'tb.ram_ctrl' and in all its sub-modules, and the variable 'tb.alu2.a' in module 'alu2'
    end
//---------------------------------------------------------------------------;
endmodule
//===========================================================================
