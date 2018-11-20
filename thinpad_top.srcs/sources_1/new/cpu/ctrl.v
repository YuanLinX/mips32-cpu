`include "../defines.v"

module ctrl(
    input wire clk,
    input wire rst,
    input wire[31:0] ebase_i,
    input wire[31:0] excepttype_i,
    input wire[`RegBus] cp0_epc_i,
    input wire mem_we_i,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    input wire stallreq_from_mem,

    output reg[`RegBus] new_pc,
    output reg mem_we_o,
    output reg flush,
    output reg[5:0] stall
);

    reg pause_for_store;

    always @(posedge clk) begin
        if (rst == `RstEnable)
            pause_for_store <= 1'b0;
        else if (mem_we_i == 1'b1)
            pause_for_store <= ~pause_for_store;
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            stall <= 6'b000000;
            flush <= 1'b0;
            new_pc <= `ZeroWord;
            mem_we_o <= 1'b0;
        end else if (excepttype_i != `ZeroWord) begin
            flush <= 1'b1;
            mem_we_o <= 1'b0;
            stall <= 6'b000000;
            case (excepttype_i)
                32'h00000001: new_pc <= ebase_i; //interrupt
                32'h00000008: new_pc <= ebase_i; //syscall
                32'h0000000a: new_pc <= ebase_i; //inst_invalid
                32'h0000000d: new_pc <= ebase_i; //trap
                32'h0000000c: new_pc <= ebase_i; //ov
                32'h0000000e: new_pc <= cp0_epc_i; //eret
                32'h0000000f: new_pc <= ebase_i; // tlbmiss, need to be change to uCore
                32'h0000000b: new_pc <= ebase_i;
                default: new_pc <= ebase_i;
            endcase
        end else if (stallreq_from_ex == `Stop) begin
            stall <= 6'b001111;
            flush <= 1'b0; 
            mem_we_o <= 1'b0;
        end else if (stallreq_from_id == `Stop) begin
            stall <= 6'b000111;
            flush <= 1'b0; 
            mem_we_o <= 1'b0;
        end else if (mem_we_i == 1'b1 && pause_for_store == 1'b0) begin
            stall <= 6'b011111;
            flush <= 1'b0;
            mem_we_o <= 1'b0;
        end else if (mem_we_i == 1'b1 && pause_for_store == 1'b1) begin
            stall <= 6'b001111;
            flush <= 1'b0;
            mem_we_o <= 1'b1;
        end else if (stallreq_from_mem == `Stop) begin
            stall <= 6'b000111;
            flush <= 1'b0;
            mem_we_o <= 1'b0;
        end else begin
            stall <= 6'b000000; 
            flush <= 1'b0; 
            new_pc <= `ZeroWord;
            mem_we_o <= 1'b0;
        end
    end
endmodule