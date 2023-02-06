`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2023 11:52:25 AM
// Design Name: 
// Module Name: axi_vip_mem_tb
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

import axi_vip_pkg::*;
import axi_vip_mem_pkg::*;

module axi_vip_mem_tb();

    localparam AXI_ID_WIDTH = 4;
    localparam AXI_DATA_WIDTH = 512;
    localparam AXI_ADDR_WIDTH = 33;

    // AXI Interface Write Address Ports
    logic [AXI_ID_WIDTH-1:0] s_axi_awid = 'h0;
    logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr = 'h0;
    logic  [7:0] s_axi_awlen = 'h0;     //burst size 1 - single transfer
    logic [2:0] s_axi_awsize = 3'b110;  //64 bytes transfers
    logic [1:0] s_axi_awburst = 2'b01;  //INCR burst type
    logic [0:0] s_axi_awlock = 1'b0;    //normal access
    logic [3:0] s_axi_awcache = 3'b000; //DEVICE_NON_BUFFERABLE
    logic [2:0] s_axi_awprot = 3'b000;  //Unprivileged, secure, data access
    logic [3:0] s_axi_awregion = 4'h0;  //not used
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

    logic ui_clk = 'b0;
    logic sys_rst = 'b0;

    localparam RESET_PERIOD = 200000; //in pSec 
    localparam CMD_DELAY = 200;

    always #5000 ui_clk = ~ui_clk;

    axi_vip_mem_slv_mem_t mem_agent;

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

        mem_agent = new ("Slave VIP Memory", axi_vip_mem_tb.axi_vip_mem_inst.inst.IF);
        mem_agent.mem_model.set_bresp_delay_range(0, 5);
        mem_agent.mem_model.set_inter_beat_gap_range(0, 5);
        mem_agent.start_slave();
        //#RESET_PERIOD sys_rst = 'b1;

        //wait(init_calib_complete);
        //$display("Calibration Done");
        
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

    axi_vip_mem axi_vip_mem_inst (
  .aclk(ui_clk),                      // input wire aclk

  .s_axi_awid(s_axi_awid),        // input wire [3 : 0] s_axi_awid
  .s_axi_awaddr(s_axi_awaddr),    // input wire [32 : 0] s_axi_awaddr
  .s_axi_awlen(s_axi_awlen),      // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(s_axi_awsize),    // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(s_axi_awburst),  // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(s_axi_awlock),    // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(s_axi_awcache),  // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(s_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awqos(s_axi_awqos),      // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(s_axi_awvalid),  // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),  // output wire s_axi_awready

  .s_axi_wdata(s_axi_wdata),      // input wire [511 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),      // input wire [63 : 0] s_axi_wstrb
  .s_axi_wlast(s_axi_wlast),      // input wire s_axi_wlast
  .s_axi_wvalid(s_axi_wvalid),    // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),    // output wire s_axi_wready

  .s_axi_bid(s_axi_bid),          // output wire [3 : 0] s_axi_bid
  .s_axi_bresp(s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),    // input wire s_axi_bready

  .s_axi_arid(s_axi_arid),        // input wire [3 : 0] s_axi_arid
  .s_axi_araddr(s_axi_araddr),    // input wire [32 : 0] s_axi_araddr
  .s_axi_arlen(s_axi_arlen),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(s_axi_arsize),    // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(s_axi_arburst),  // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(s_axi_arlock),    // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(s_axi_arcache),  // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(s_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arqos(s_axi_arqos),      // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(s_axi_arvalid),  // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),  // output wire s_axi_arready
  
  .s_axi_rid(s_axi_rid),          // output wire [3 : 0] s_axi_rid
  .s_axi_rdata(s_axi_rdata),      // output wire [511 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(s_axi_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(s_axi_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready)    // input wire s_axi_rready
);
endmodule
