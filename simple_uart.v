module simple_uart(
    input           clock,
    input           nreset,
    input  [3:0]    avs_address,
    input           avs_read,
    output [31:0]   avs_readdata,
    output          avs_readvalid,
    input           avs_write,
    input  [31:0]   avs_writedata,
    output          avs_waitreq,

    input           rx,
    output          tx
);
// 0x0 : ctrl_reg [0]rx_status(1:latch new data, 0:no new data), [1]tx_status(1:busy(no waitreq), 0:not busy), [31:16]ID
// 0x1 : read_reg
// 0x2 : write_reg ( write data at previous )

localparam [15:0] id = 16'hDEBC;
reg [3:0] addr_reg;
reg [31:0] data_reg;
reg readvalid_reg;
reg [31:0] read_reg;
reg [31:0] write_reg;
reg ctrl_rd;
reg ctrl_wr;


reg set_data;
wire utx_busy;
wire rx_dvalid;
reg [1:0] dff_dvalid;
wire [7:0] rx_data;

uart_tx utx(
    .clk(clock),
    .nreset(nreset),
    .tx_data(write_reg),
    .set_data(set_data),
    .busy(utx_busy),
    .tx(tx),
);
uart_rx urx(
    .clk(clock),
    .nreset(nreset),
    .rx_data(rx_data),
    .dvalid(rx_dvalid),
    .rx(rx),
);
assign avs_waitreq = 0;
assign avs_readdata = data_reg;
assign avs_readvalid = readvalid_reg;

always @(posedge clock or negedge nreset) begin
    if(~nreset) begin
        readvalid_reg <= 0;
    end
    else if( clock ) begin
        if ( avs_read == 1 ) begin
            readvalid_reg <= 1;
        end
        else begin
            readvalid_reg <= 0;
        end
    end
end
always @(posedge clock or negedge nreset) begin
    if(~nreset) begin
        ctrl_wr <= 0;
        set_data <= 0;
        write_reg <= 0;
    end
    else begin
        ctrl_wr <= utx_busy;
        if ( set_data == 1 ) begin
            set_data <= 0;
        end 
        else if( (avs_write == 1) & (utx_busy == 0) ) begin
            set_data <= 1;
            write_reg <= avs_writedata;
        end
    end
end
always @(posedge clock or negedge nreset) begin
    if(~nreset) begin
        data_reg <= 0;
    end
    else begin
        case (avs_address)
            0 : data_reg <= { id, 14'b0, ctrl_rd, ctrl_wr};
            1 : data_reg <= read_reg;
            2 : data_reg <= write_reg;
            3 : data_reg <= {16'h0, id};
            default : data_reg <= 0;
        endcase
    end
end
always @(posedge clock or negedge nreset) begin
    if(~nreset) begin
        dff_dvalid <= 0;
        ctrl_rd <= 0;
        read_reg <= rx_data;
    end
    else begin
        dff_dvalid <= {dff_dvalid[0], rx_dvalid};
        if( dff_dvalid == 1 ) begin
            ctrl_rd <= 1;
            read_reg <= rx_data;
        end
        else if (avs_read == 1) begin
            ctrl_rd <= 0;
        end
    end
end

endmodule
