// =============================================
// NINJA MEMORY SYSTEM (From Previous Victory)
// =============================================

// --- NINJA CACHE MODULE ---
module ninja_cache (
    input wire clk,
    input wire reset,
    input wire [3:0] lookup_addr,
    input wire [3:0] lookup_data,
    input wire lookup_write,
    output reg cache_hit,
    output reg [3:0] cache_data_out
);
    reg [3:0] stored_addr;
    reg [3:0] stored_data;
    reg valid;
    
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
            cache_hit <= 1'b0;
        end else begin
            cache_hit <= valid && (lookup_addr == stored_addr);
            cache_data_out <= stored_data;
            
            if (lookup_write) begin
                stored_addr <= lookup_addr;
                stored_data <= lookup_data;
                valid <= 1'b1;
            end
        end
    end
endmodule

// --- PREDICTION ENGINE MODULE ---
module prediction_engine (
    input wire clk,
    input wire reset,
    input wire [3:0] current_addr,
    input wire is_read,
    output reg [3:0] predicted_addr
);
    always @(posedge clk) begin
        if (reset) begin
            predicted_addr <= 4'b0001;
        end else if (is_read) begin
            predicted_addr <= current_addr + 1;
        end
    end
endmodule

// --- SPECULATIVE RESOLVER MODULE ---
module speculative_resolver (
    input wire clk,
    input wire reset,
    input wire find_req,
    input wire [3:0] find_addr,
    input wire union_req,
    input wire [3:0] union_addr, 
    input wire [3:0] union_data,
    output reg speculative_hit,
    output reg [3:0] speculative_data
);
    reg [3:0] recent_union_addr;
    reg [3:0] recent_union_data;
    reg recent_valid;
    
    always @(posedge clk) begin
        if (reset) begin
            recent_valid <= 1'b0;
            speculative_hit <= 1'b0;
            speculative_data <= 4'b0;
        end else begin
            speculative_hit <= 1'b0;
            
            if (find_req && recent_valid && (find_addr == recent_union_addr)) begin
                speculative_hit <= 1'b1;
                speculative_data <= recent_union_data;
                recent_valid <= 1'b0;
            end
            
            if (union_req) begin
                recent_union_addr <= union_addr;
                recent_union_data <= union_data; 
                recent_valid <= 1'b1;
            end
        end
    end
endmodule

// --- NINJA MEMORY SYSTEM ---
module ninja_memory_system (
    input wire clk,
    input wire reset,
    
    input wire find_req,
    input wire [5:0] find_addr, 
    output reg [5:0] find_data,
    output reg find_ready,
    
    input wire union_req,
    input wire [5:0] union_addr,
    input wire [5:0] union_data,
    output reg union_ready
);

    // Simple memory simulation for parent array
    reg [5:0] parent_array [0:63];
    integer i;
    
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            parent_array[i] = i;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                parent_array[i] <= i;
            end
            find_ready <= 1'b0;
            union_ready <= 1'b0;
        end else begin
            find_ready <= 1'b0;
            union_ready <= 1'b0;
            
            if (find_req) begin
                find_data <= parent_array[find_addr];
                find_ready <= 1'b1;
                $display("💾 MEMORY: Read addr %d -> data %d", find_addr, parent_array[find_addr]);
            end else if (union_req) begin
                parent_array[union_addr] <= union_data;
                union_ready <= 1'b1;
                $display("💾 MEMORY: Write addr %d <- data %d", union_addr, union_data);
            end
        end
    end

endmodule
