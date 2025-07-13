module top (
    input  logic clk,
    input  logic rst,

    // From CPU
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write
    input  logic [31:0] data_in,
    input logic [31:0] address,
    // To CPU
    output logic [31:0] dataOut,
    output logic        done_cache
);
    // Decoder outputs
    logic [23:0] tag;
    logic [5:0] index;
    logic [1:0] blk_offset;
    //Cache_mem signals I/O
    logic acknowledge, refill, read_en, write_en,logic [`BLOCK_SIZE-1:0] dirty_block_out dirty_bit,hit;
    //Mem signals
    logic read_en_mem, write_en_mem, [`BLOCK_SIZE-1:0] data_out_mem, ready_mem, logic [`BLOCK_SIZE-1:0] dirty_block_in;

    //Instantiation
    cache_decoder decoder (
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset)
    );
    cache_controller controller (
    .clk(clk),
    .rst(rst),
    .req_valid(req_valid),
    .req_type(req_type),
    .hit(hit),
    .dirty_bit(dirty_bit),
    .ready_mem(ready_mem),
    .read_en_mem(read_en_mem),
    .write_en_mem(write_en_mem),
    .write_en(write_en),
    .read_en_cache(read_en_cache),
    .refill(refill),
    );
    cache_memory cache (
    .clk(clk),
    .tag(tag),
    .index(index),
    .offset(offset),
    .req_type(req_type),
    .read_en(read_en_cache),
    .write_en(write_en),
    .refill(refill),
    .data_in(mem_block_out),         // From main memory
    .cpu_data_in(cpu_data_in),       // Word from CPU
    .dirty_block_out(dirty_block_out), // To memory
    .hit(hit),
    .dataOut(dataOut),
    .dirty(dirty_bit),                // You'll need to expose this from cache
    .done_cache(done_cache),               
    .acknowledge(acknowledge)             
   );
   main_memory memory (
    .clk(clk),
    .read_en_mem(read_en_mem),
    .write_en_mem(write_en_mem),
    .address({tag, index, offset, 2'b00}), // Form address from tag+index+offset
    .dirty_block_in(dirty_block_out),
    .acknowledge(acknowledge),
    .block_out(mem_block_out),
    .ready_mem(ready_mem)
);
endmodule