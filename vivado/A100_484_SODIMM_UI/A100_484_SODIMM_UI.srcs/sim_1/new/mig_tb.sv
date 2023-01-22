`timescale 1ps/1ps

module mig_tb();

    localparam ADDR_WIDTH = 16;
    localparam CK_WIDTH = 2;
    localparam CKE_WIDTH = 2;
    localparam CS_WIDTH = 2;
    localparam BYTES_COUNT = 8;
    localparam ODT_COUNT = 2;

    localparam UI_ADDR_WIDTH = 30;
    localparam UI_DATA_WIDTH = 512;
    localparam UI_DATA_WIDTH_PER_BYTE = 8;

    wire [ADDR_WIDTH-1:0] ddr3_addr;
    wire [2:0] ddr3_ba;
    wire ddr3_cas_n;
    wire [CK_WIDTH-1:0] ddr3_ck_p;
    wire [CK_WIDTH-1:0] ddr3_ck_n;
    wire [CKE_WIDTH-1:0] ddr3_cke;
    wire ddr3_ras_n;
    wire ddr3_reset_n;
    wire ddr3_we_n;
    wire [BYTES_COUNT*8-1:0] ddr3_dq;
    wire [BYTES_COUNT-1:0] ddr3_dqs_p;
    wire [BYTES_COUNT-1:0] ddr3_dqs_n;
    wire [CS_WIDTH-1:0] ddr3_cs_n;
    wire [BYTES_COUNT-1:0] ddr3_dm;
    wire [ODT_COUNT-1:0] ddr3_odt;

    wire init_calib_complete;

    logic [UI_ADDR_WIDTH-1:0] app_addr = 'h0;
    logic [2:0] app_cmd = 'b0;
    logic app_en = 'b0;
    logic [UI_DATA_WIDTH-1:0] app_wdf_data = 'b0;
    logic [UI_DATA_WIDTH/8-1:0] app_wdf_mask = 'b0;
    logic app_wdf_end = 'b0;
    logic app_wdf_wren = 'b0;

    wire [UI_DATA_WIDTH-1:0] app_rd_data;
    wire app_rd_data_end;
    wire app_rd_data_valid;

    wire app_rdy;
    wire app_wdf_rdy;

    logic app_sr_req = 'b0;
    logic app_ref_req = 'b0;
    logic app_zq_req = 'b0;
    wire app_sr_active;
    wire app_ref_ack;
    wire app_zq_ack;

    wire ui_clk;
    wire ui_clk_sync_rst;

    logic sys_clk_p = 'b0;
    logic sys_clk_n;
    assign sys_clk_n = ~sys_clk_p;
    logic sys_rst = 'b0;

    localparam CMD_READ = 3'b001, CMD_WRITE = 3'b000;

    localparam RESET_PERIOD = 200000; //in pSec 
    localparam CMD_DELAY = 200;

    always #2500 sys_clk_p = ~sys_clk_p;

    initial begin
        #RESET_PERIOD sys_rst = 'b1;

        wait(init_calib_complete);
        $display("Calibration Done");

        @(posedge ui_clk);
        #(CMD_DELAY)
        //$display("[%0t] Writing data into FIFO.", $stime);
        app_wdf_data = {(UI_DATA_WIDTH_PER_BYTE * BYTES_COUNT){32'h11223344}};
        app_wdf_end = 'b1;
        app_wdf_wren = 'b1;

        wait(app_wdf_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        //$display("[%0t] Writing data into FIFO.", $stime);
        app_wdf_data = {(UI_DATA_WIDTH_PER_BYTE * BYTES_COUNT){32'h55667788}};
        app_wdf_end = 'b1;
        app_wdf_wren = 'b1;

        wait(app_wdf_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        //$display("[%0t] Writing data into FIFO.", $stime);
        app_wdf_data = {(UI_DATA_WIDTH_PER_BYTE * BYTES_COUNT){32'h99aabbcc}};
        app_wdf_end = 'b1;
        app_wdf_wren = 'b1;

        wait(app_wdf_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        //$display("[%0t] Writing data into FIFO.", $stime);
        app_wdf_data = {(UI_DATA_WIDTH_PER_BYTE * BYTES_COUNT){32'hddeeff00}};
        app_wdf_end = 'b1;
        app_wdf_wren = 'b1;

        wait(app_wdf_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        app_wdf_end = 'b0;
        app_wdf_wren = 'b0;
        
        @(posedge ui_clk);
        #(CMD_DELAY)
        app_cmd = CMD_WRITE;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);
        
        #(CMD_DELAY)
        app_addr = 'h8;
        app_cmd = CMD_WRITE;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);
        
        #(CMD_DELAY)
        app_addr = 'h10;
        app_cmd = CMD_WRITE;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);
        
        #(CMD_DELAY)
        app_addr = {1'b1, {(UI_ADDR_WIDTH-1){1'b0}}};
        app_cmd = CMD_WRITE;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);
        
        #(CMD_DELAY)
        app_en = 1'b0;
        @(posedge ui_clk);

        #(CMD_DELAY)
        app_addr = 'h0;
        app_cmd = CMD_READ;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        app_addr = 'h8;
        app_cmd = CMD_READ;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        app_addr = 'h10;
        app_cmd = CMD_READ;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);

        #(CMD_DELAY)
        app_addr = {1'b1, {(UI_ADDR_WIDTH-1){1'b0}}};
        app_cmd = CMD_READ;
        app_en = 1'b1;
        wait(app_rdy);
        @(posedge ui_clk);
    
        #(CMD_DELAY)
        app_en = 1'b0;
        @(posedge ui_clk);
    end

    mig_7series_SODIMM u_mig_7series_SODIMM (



        // Memory interface ports
    
        .ddr3_addr                      (ddr3_addr),  // output [14:0]		ddr3_addr
    
        .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba
    
        .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n
    
        .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
    
        .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
    
        .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
    
        .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
    
        .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
    
        .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
    
        .ddr3_dq                        (ddr3_dq),  // inout [31:0]		ddr3_dq
    
        .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [3:0]		ddr3_dqs_n
    
        .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [3:0]		ddr3_dqs_p
    
        .init_calib_complete            (init_calib_complete),  // output			init_calib_complete
    
          
    
        .ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n
    
        .ddr3_dm                        (ddr3_dm),  // output [3:0]		ddr3_dm
    
        .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt
    
        // Application interface ports
    
        .app_addr                       (app_addr),  // input [28:0]		app_addr
    
        .app_cmd                        (app_cmd),  // input [2:0]		app_cmd
    
        .app_en                         (app_en),  // input				app_en
    
        .app_wdf_data                   (app_wdf_data),  // input [255:0]		app_wdf_data
    
        .app_wdf_end                    (app_wdf_end),  // input				app_wdf_end
    
        .app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren
    
        .app_rd_data                    (app_rd_data),  // output [255:0]		app_rd_data
    
        .app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end
    
        .app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid
    
        .app_rdy                        (app_rdy),  // output			app_rdy
    
        .app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy
    
        .app_sr_req                     (app_sr_req),  // input			app_sr_req
    
        .app_ref_req                    (app_ref_req),  // input			app_ref_req
    
        .app_zq_req                     (app_zq_req),  // input			app_zq_req
    
        .app_sr_active                  (app_sr_active),  // output			app_sr_active
    
        .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
    
        .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack
    
        .ui_clk                         (ui_clk),  // output			ui_clk
    
        .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst
    
        .app_wdf_mask                   (app_wdf_mask),  // input [31:0]		app_wdf_mask
    
        // System Clock Ports
    
        .sys_clk_p                       (sys_clk_p),
        .sys_clk_n                       (sys_clk_n),
    
        .sys_rst                        (sys_rst) // input sys_rst
    
        );

    ddr3_module mem(
            .reset_n(ddr3_reset_n),
            .ck(ddr3_ck_p)     ,
            .ck_n(ddr3_ck_n)   ,
            .cke(ddr3_cke)    ,
            .s_n(ddr3_cs_n)    , 
            .ras_n(ddr3_ras_n)  ,
            .cas_n(ddr3_cas_n)  ,
            .we_n(ddr3_we_n)   ,
            .ba(ddr3_ba)     ,
            .addr(ddr3_addr)   ,
            .odt(ddr3_odt)    ,
            .dqs(ddr3_dqs_p)    ,
            .dqs_n(ddr3_dqs_n)  ,
            .dm(ddr3_dm),
            .dq(ddr3_dq)     ,
            .scl()    ,
            .sa()     ,
            .sda()
        );

    /*ddr3_model mem1

        (

         .rst_n   (ddr3_reset_n),

         .ck      (ddr3_ck_p[0]),

         .ck_n    (ddr3_ck_n[0]),

         .cke     (ddr3_cke[0]),

         .cs_n    (ddr3_cs_n[0]),

         .ras_n   (ddr3_ras_n),

         .cas_n   (ddr3_cas_n),

         .we_n    (ddr3_we_n),

         .dm_tdqs (ddr3_dm[1:0]),

         .ba      (ddr3_ba),

         .addr    (ddr3_addr),

         .dq      (ddr3_dq[15:0]),

         .dqs     (ddr3_dqs_p[1:0]),

         .dqs_n   (ddr3_dqs_n[1:0]),

         .tdqs_n  (),

         .odt     (ddr3_odt[0])

         );

    ddr3_model mem2

        (

        .rst_n   (ddr3_reset_n),

        .ck      (ddr3_ck_p[0]),

        .ck_n    (ddr3_ck_n[0]),

        .cke     (ddr3_cke[0]),

        .cs_n    (ddr3_cs_n[0]),

        .ras_n   (ddr3_ras_n),

        .cas_n   (ddr3_cas_n),

        .we_n    (ddr3_we_n),

        .dm_tdqs (ddr3_dm[3:2]),

        .ba      (ddr3_ba),

        .addr    (ddr3_addr),

        .dq      (ddr3_dq[31:16]),

        .dqs     (ddr3_dqs_p[3:2]),

        .dqs_n   (ddr3_dqs_n[3:2]),

        .tdqs_n  (),

        .odt     (ddr3_odt[0])

        );*/
endmodule
