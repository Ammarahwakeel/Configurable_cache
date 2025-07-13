module main_memory (
    input clk,
    input read_en,                    // From controller
    input [31:0] address,
    output reg [127:0] block_out,     // 4 words = 128 bits
    output reg ready                  // Signal: memory has data ready
);

    reg [31:0] base_address;
    integer i;

    always @(posedge clk) begin
        if (read_en) begin
            base_address = {address[31:4], 4'b0000};  // Align to block (16-byte boundary)
            ready = 1;
            for (i = 0; i < 4; i = i + 1) begin
                block_out[i*32 +: 32] = base_address + i;  // For simulation: word = addr
            end
        end else begin
            ready = 0;
        end
    end
endmodule