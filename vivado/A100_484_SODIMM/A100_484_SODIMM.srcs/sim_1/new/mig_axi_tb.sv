`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/30/2023 11:54:41 PM
// Design Name: 
// Module Name: mig_axi_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mig_axi_tb();

    localparam ADDR_WIDTH = 16;
    localparam CK_WIDTH = 2;
    localparam CKE_WIDTH = 2;
    localparam CS_WIDTH = 2;
    localparam BYTES_COUNT = 8;
    localparam ODT_COUNT = 2;

    localparam AXI_ID_WIDTH = 4;
    localparam AXI_DATA_WIDTH = 512;
    localparam AXI_ADDR_WIDTH = 33;

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

    logic app_sr_req = 'b0;
    logic app_ref_req = 'b0;
    logic app_zq_req = 'b0;
    wire app_sr_active;
    wire app_ref_ack;
    wire app_zq_ack;

    wire ui_clk;
    wire ui_clk_sync_rst;
    wire mmcm_locked;
    logic aresetn = 1'b1;

    // AXI Interface Write Address Ports
    logic [AXI_ID_WIDTH-1:0] s_axi_awid = 'h0;
    logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr = 'h0;
    logic  [7:0] s_axi_awlen = 'h0;     //burst size 1 - single transfer
    logic [2:0] s_axi_awsize = 3'b110;  //64 bytes transfers
    logic [1:0] s_axi_awburst = 2'b01;  //INCR burst type
    logic [0:0] s_axi_awlock = 1'b0;    //normal access
    logic [3:0] s_axi_awcache = 3'b000; //DEVICE_NON_BUFFERABLE
    logic [2:0] s_axi_awprot = 3'b000;  //Unprivileged, secure, data access
    logic [3:0] s_axi_awqos = 'h0;
    logic s_axi_awvalid = 1'b0;
    wire s_axi_awready;

    // AXI Interface Write Data Ports
    logic [AXI_DATA_WIDTH-1:0] s_axi_wdata;
    logic [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb = {(AXI_DATA_WIDTH/8){1'b1}};
    logic s_axi_wlast = 1'b1;   //1 indicates last trasfer of a burst
    logic s_axi_wvalid = 1'b0;
    wire s_axi_wready;

    // AXI Interface Write Response Ports
    wire [AXI_ID_WIDTH-1:0] s_axi_bid;
    wire [1:0] s_axi_bresp; //2'b00 - Normal access success, 2'b01 - Exclusive access okay, 2'b10 - Slave error, 2'b11 - Decode error.
    wire s_axi_bvalid;
    logic s_axi_bready = 1'b1;

    // AXI Interface Read Address Ports
    logic [AXI_ID_WIDTH-1:0] s_axi_arid = 'h0;
    logic [AXI_ADDR_WIDTH-1:0] s_axi_araddr = 'h0;
    logic [7:0] s_axi_arlen = 'h0;      //burst size 1 - single transfer
    logic [2:0] s_axi_arsize = 3'b110;  //64 bytes transfers
    logic [1:0] s_axi_arburst = 2'b01;  //INCR burst type
    logic [0:0] s_axi_arlock = 1'b0;    //normal access
    logic [3:0] s_axi_arcache = 3'b000; //DEVICE_NON_BUFFERABLE
    logic [2:0] s_axi_arprot = 3'b000;  //Unprivileged, secure, data access
    logic [3:0] s_axi_arqos = 'h0;
    logic s_axi_arvalid = 1'b0;
    wire s_axi_arready;

    // AXI Interface Read Data Ports
    wire [AXI_ID_WIDTH-1:0] s_axi_rid;
    wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0] s_axi_rresp; //2'b00 - Normal access success, 2'b01 - Exclusive access okay, 2'b10 - Slave error, 2'b11 - Decode error.
    wire s_axi_rlast;       //1 indicates last trasfer of a burst
    wire s_axi_rvalid;
    logic s_axi_rready = 1'b1;

    logic sys_clk_p = 'b0;
    logic sys_clk_n;
    assign sys_clk_n = ~sys_clk_p;
    logic sys_rst = 'b0;

    localparam RESET_PERIOD = 200000; //in pSec 
    localparam CMD_DELAY = 200;

    always #2500 sys_clk_p = ~sys_clk_p;

    int write_cnt = 0;

    task send_write_cmd();
    begin
        s_axi_awaddr = write_cnt * 7'h40;
        s_axi_awvalid = 1'b1;

        $display("%m:[%0t] Sending write command to address %h.", $stime, s_axi_awaddr);

        s_axi_wdata = {(AXI_DATA_WIDTH/8){write_cnt * 7'h40}};
        s_axi_wvalid = 1'b1;

        fork
            begin
                do begin
                    @(posedge ui_clk);
                end
                while (s_axi_awready != 1'b1);
                    
                #(CMD_DELAY);
                s_axi_awvalid = 1'b0;
                #(CMD_DELAY);
            end
            begin
                do begin
                    @(posedge ui_clk);
                end
                while (s_axi_wready != 1'b1);
                #(CMD_DELAY);
                s_axi_wvalid = 1'b0;
                #(CMD_DELAY);
            end
        join
        write_cnt = write_cnt + 1;
            
    end
    endtask: send_write_cmd

    task recv_write_resp();
        forever begin
            do begin
                @(posedge ui_clk);
            end
            while (s_axi_bvalid != 1'b1);
            $display("%m:[%0t] Received write response.", $stime);
        end
    endtask: recv_write_resp
    
    int read_cnt = 0;

    task send_read_cmd();
    begin
        s_axi_araddr = read_cnt * 7'h40;
        s_axi_arvalid = 1'b1;

        $display("%m:[%0t] Sending read command to address %h.", $stime, s_axi_araddr);
        do begin
            @(posedge ui_clk);
        end
        while (s_axi_arready != 1'b1);
            
        #(CMD_DELAY);
        s_axi_arvalid = 1'b0;
        #(CMD_DELAY);
        read_cnt = read_cnt + 1;
    end        
    endtask: send_read_cmd
    
    task recv_read();
        forever begin
            do begin
                @(posedge ui_clk);
            end
            while (s_axi_rvalid != 1'b1);
            $display("%m:[%0t] Received read data: %h.", $stime, s_axi_rdata);
        end
    endtask: recv_read
    
    

    initial begin
        #RESET_PERIOD sys_rst = 'b1;

        wait(init_calib_complete);
        $display("Calibration Done");
        
        @(posedge ui_clk);
        #(CMD_DELAY);

        fork
            begin
                for (int i = 0; i < 10; i++) begin
                    send_write_cmd();
                end
                for (int i = 0; i < 10; i++) begin
                    send_read_cmd();
                end
            end
            recv_write_resp();
            recv_read();
        join_any
    end

    mig_7series_SODIMM u_mig_7series_SODIMM (



    // Memory interface ports

    .ddr3_addr                      (ddr3_addr),  // output [15:0]		ddr3_addr

    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba

    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n

    .ddr3_ck_n                      (ddr3_ck_n),  // output [1:0]		ddr3_ck_n

    .ddr3_ck_p                      (ddr3_ck_p),  // output [1:0]		ddr3_ck_p

    .ddr3_cke                       (ddr3_cke),  // output [1:0]		ddr3_cke

    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n

    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n

    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n

    .ddr3_dq                        (ddr3_dq),  // inout [63:0]		ddr3_dq

    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [7:0]		ddr3_dqs_n

    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [7:0]		ddr3_dqs_p

    .init_calib_complete            (init_calib_complete),  // output			init_calib_complete

      

	.ddr3_cs_n                      (ddr3_cs_n),  // output [1:0]		ddr3_cs_n

    .ddr3_dm                        (ddr3_dm),  // output [7:0]		ddr3_dm

    .ddr3_odt                       (ddr3_odt),  // output [1:0]		ddr3_odt

    // Application interface ports

    .ui_clk                         (ui_clk),  // output			ui_clk

    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst

    .mmcm_locked                    (mmcm_locked),  // output			mmcm_locked

    .aresetn                        (aresetn),  // input			aresetn

    .app_sr_req                     (app_sr_req),  // input			app_sr_req

    .app_ref_req                    (app_ref_req),  // input			app_ref_req

    .app_zq_req                     (app_zq_req),  // input			app_zq_req

    .app_sr_active                  (app_sr_active),  // output			app_sr_active

    .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack

    .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack

    // Slave Interface Write Address Ports

    .s_axi_awid                     (s_axi_awid),  // input [3:0]			s_axi_awid

    .s_axi_awaddr                   (s_axi_awaddr),  // input [32:0]			s_axi_awaddr

    .s_axi_awlen                    (s_axi_awlen),  // input [7:0]			s_axi_awlen

    .s_axi_awsize                   (s_axi_awsize),  // input [2:0]			s_axi_awsize

    .s_axi_awburst                  (s_axi_awburst),  // input [1:0]			s_axi_awburst

    .s_axi_awlock                   (s_axi_awlock),  // input [0:0]			s_axi_awlock

    .s_axi_awcache                  (s_axi_awcache),  // input [3:0]			s_axi_awcache

    .s_axi_awprot                   (s_axi_awprot),  // input [2:0]			s_axi_awprot

    .s_axi_awqos                    (s_axi_awqos),  // input [3:0]			s_axi_awqos

    .s_axi_awvalid                  (s_axi_awvalid),  // input			s_axi_awvalid

    .s_axi_awready                  (s_axi_awready),  // output			s_axi_awready

    // Slave Interface Write Data Ports

    .s_axi_wdata                    (s_axi_wdata),  // input [511:0]			s_axi_wdata

    .s_axi_wstrb                    (s_axi_wstrb),  // input [63:0]			s_axi_wstrb

    .s_axi_wlast                    (s_axi_wlast),  // input			s_axi_wlast

    .s_axi_wvalid                   (s_axi_wvalid),  // input			s_axi_wvalid

    .s_axi_wready                   (s_axi_wready),  // output			s_axi_wready

    // Slave Interface Write Response Ports

    .s_axi_bid                      (s_axi_bid),  // output [3:0]			s_axi_bid

    .s_axi_bresp                    (s_axi_bresp),  // output [1:0]			s_axi_bresp

    .s_axi_bvalid                   (s_axi_bvalid),  // output			s_axi_bvalid

    .s_axi_bready                   (s_axi_bready),  // input			s_axi_bready

    // Slave Interface Read Address Ports

    .s_axi_arid                     (s_axi_arid),  // input [3:0]			s_axi_arid

    .s_axi_araddr                   (s_axi_araddr),  // input [32:0]			s_axi_araddr

    .s_axi_arlen                    (s_axi_arlen),  // input [7:0]			s_axi_arlen

    .s_axi_arsize                   (s_axi_arsize),  // input [2:0]			s_axi_arsize

    .s_axi_arburst                  (s_axi_arburst),  // input [1:0]			s_axi_arburst

    .s_axi_arlock                   (s_axi_arlock),  // input [0:0]			s_axi_arlock

    .s_axi_arcache                  (s_axi_arcache),  // input [3:0]			s_axi_arcache

    .s_axi_arprot                   (s_axi_arprot),  // input [2:0]			s_axi_arprot

    .s_axi_arqos                    (s_axi_arqos),  // input [3:0]			s_axi_arqos

    .s_axi_arvalid                  (s_axi_arvalid),  // input			s_axi_arvalid

    .s_axi_arready                  (s_axi_arready),  // output			s_axi_arready

    // Slave Interface Read Data Ports

    .s_axi_rid                      (s_axi_rid),  // output [3:0]			s_axi_rid

    .s_axi_rdata                    (s_axi_rdata),  // output [511:0]			s_axi_rdata

    .s_axi_rresp                    (s_axi_rresp),  // output [1:0]			s_axi_rresp

    .s_axi_rlast                    (s_axi_rlast),  // output			s_axi_rlast

    .s_axi_rvalid                   (s_axi_rvalid),  // output			s_axi_rvalid

    .s_axi_rready                   (s_axi_rready),  // input			s_axi_rready

    // System Clock Ports

    .sys_clk_p                       (sys_clk_p),  // input				sys_clk_p

    .sys_clk_n                       (sys_clk_n),  // input				sys_clk_n

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
endmodule
