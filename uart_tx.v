module uart_tx(
    input clk,
    input nreset,
    input [7:0] tx_data,
    input set_data,
    output busy,
    output tx
);


reg [8:0] data_reg;
reg [31:0] time_count;
reg [3:0] bit_count;
reg tx_reg;
reg stat;

assign tx = tx_reg;
assign busy = stat;
always @(posedge clk or negedge nreset) begin
    if( ~nreset ) begin
        tx_reg <= 1;
        stat <= 0;
    end 
    else if ((stat == 0) & (set_data==1)) begin
        stat <= 1;
        tx_reg <= 0;
        data_reg <= {1'b1, tx_data};
        bit_count<=0;
        time_count <= 0;
    end 
    else if (stat == 1) begin
        if( time_count == 434 ) begin
            time_count <= 0;
            bit_count <= bit_count+1;
            if( bit_count == 11) begin
                tx_reg <= 1;
                stat <= 0;
            end
            else begin
                tx_reg <= data_reg[0];
                data_reg <= {1'b1, data_reg[8:1]};
            end;
        end
        else begin
            time_count <= time_count+1;
        end
    end

end



endmodule
