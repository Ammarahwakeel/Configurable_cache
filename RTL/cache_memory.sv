`define BLOCKS 64
`define WORDS 4
`define WORD_SIZE 32
`define BLOCK_SIZE (`WORDS * `WORD_SIZE) // 128 bits
module cache_memory (
    input logic clk,                                          
    input logic [23:0] tag,              // From decoder           
    input logic [5:0] index,             // From decoder
    input logic [1:0] offset,            // From decoder
    input logic req_type,                // 0=Read , 1=Write
    input logic read_en,                   
    input logic write_en,            
    input logic refill,
    input [`BLOCK_SIZE-1:0] data_in,     // 128-bit block from memory
    output logic [`BLOCK_SIZE-1:0] dirty_block_out
    output logic hit,
    output logic [31:0] dataOut
);
    // Each block: valid(1) + dirty(1) + tag(24) + data(128) = 154 bits
    assign dirty_block_out = cache[index][153:26];
    logic [`BLOCK_SIZE+25:0] cache [`BLOCKS-1:0];
    assign valid       = cache[index][0];
    assign dirty       = cache[index][1];
    assign [23:0] stored_tag = cache[index][25:2];               // tag_bits of cache_line
    logic [`BLOCK_SIZE-1:0] block = cache[index][153:26];

    task automatic compare_tags;
        input [23:0] tag;
        input [23:0] stored_tag;
        input logic valid;
        output logic hit_result;
        begin
            if (valid && tag == stored_tag)
                hit_ = 1;
            else
                hit = 0;
        end
    endtask

    logic compare_result;
    always @(posedge clk) begin
        if (!req_type) begin
            // CPU READ operation
            compare_tags(tag, stored_tag, valid, compare_result);
            hit <= compare_result;

            if (compare_result && read_en) begin
                dataOut <= block[32 * offset +: 32];
            end
        end else if (req_type && hit && write_en) begin
            // WRITE HIT operation
            cache[index][153:26][32*offset +: 32] <= data_in;  // write word into correct offset
            cache[index][1] <= 1'b1;  // set dirty bit
        end else if (refill) begin
    // This happens in WRITE_ALLOCATE
           cache[index][0] <= 1'b1;          // valid = 1
           cache[index][1] <= (req_type) ? 1'b1 : 1'b0;  // set dirty only if it's a write
           cache[index][25:2] <= tag;
           cache[index][153:26] <= data_in;

           if (req_type && write_en) begin
           // CPU write request after block has been refilled
           cache[index][153:26][32*offset +: 32] <= data_in;
           end
           // Optional: recompute hit
           compare_tags(tag, tag, 1'b1, compare_result);
           hit <= compare_result;
        end
    end
    
endmodule
