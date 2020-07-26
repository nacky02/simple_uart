module uart_rx(
    input clk,
    input nreset,
    output [7:0] rx_data,
    output dvalid,
    input rx
);


reg [7:0] data_reg;
reg [7:0] rx_data_reg;
reg [31:0] time_count;
reg [3:0] bit_count;
reg [3:0] dff_rx;
reg dvalid_reg;
reg rx_reg;
reg [1:0] stat;

assign rx_data = rx_data_reg;
assign dvalid = dvalid_reg;
always @(posedge clk or negedge nreset) begin
    if( ~nreset ) begin
        dff_rx <= 4'hf;
        rx_reg <= 1;
    end else begin
        dff_rx <= {dff_rx[2:0], rx};
        rx_reg <= |dff_rx;
    end
end
always @(posedge clk or negedge nreset) begin
    if( ~nreset ) begin
        stat <= 0;
        dvalid_reg <= 1'b0;
        time_count <= 0;
        bit_count <= 0;
    end 
    else if (stat == 0) begin
        if( rx_reg == 0) begin
            stat <= 1;
            time_count <= 0;
            dvalid_reg <= 1'b0;
        end
    end 
    else if (stat == 1) begin
        if( rx_reg == 1) stat <= 0;
        else if( time_count == 217 ) begin
            time_count <= 0;
            bit_count <= 0;
            stat <= 2;
        end
        else begin
            time_count <= time_count + 1;
        end
    end
    else if ( stat == 2 ) begin
        if( time_count == 434 ) begin
            time_count <= 0;
            data_reg <= {rx_reg, data_reg[7:1]};
            if( bit_count == 7) begin
                stat <= 0;
                dvalid_reg <= 1'b1;
                rx_data_reg <= {rx_reg, data_reg[7:1]};
            end
            else begin
                bit_count <= bit_count + 1;
            end
        end
        else begin
            time_count <= time_count + 1;
        end
    end
end



endmodule
