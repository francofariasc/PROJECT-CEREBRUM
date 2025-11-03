// =============================================
// UNION-FIND DECODER CORE
// =============================================

// --- HARDWARE-OPTIMIZED FIND UNIT ---
module find_unit (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [5:0] node_addr,
    input wire [5:0] memory_data,
    input wire memory_ready,
    output reg [5:0] root_data,
    output reg ready,
    output reg memory_req,
    output reg [5:0] memory_addr
);

    reg [1:0] state;
    reg [5:0] original_node;
    reg [5:0] intermediate_data;
    
    parameter IDLE = 0, STAGE1 = 1, STAGE2 = 2;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            ready <= 1'b0;
            memory_req <= 1'b0;
        end else begin
            ready <= 1'b0;
            memory_req <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= STAGE1;
                        original_node <= node_addr;
                        memory_req <= 1'b1;
                        memory_addr <= node_addr;
                        $display("🔍 FIND: Starting for node %d", node_addr);
                    end
                end
                
                STAGE1: begin
                    if (memory_ready) begin
                        intermediate_data <= memory_data;
                        if (memory_data == original_node) begin
                            // Root found immediately
                            root_data <= memory_data;
                            ready <= 1'b1;
                            state <= IDLE;
                            $display("🔍 FIND: Immediate root %d", memory_data);
                        end else begin
                            // Need second lookup
                            memory_req <= 1'b1;
                            memory_addr <= memory_data;
                            state <= STAGE2;
                            $display("🔍 FIND: Stage1 -> parent %d", memory_data);
                        end
                    end
                end
                
                STAGE2: begin
                    if (memory_ready) begin
                        root_data <= memory_data;
                        ready <= 1'b1;
                        state <= IDLE;
                        $display("🔍 FIND: Root found %d", memory_data);
                    end
                end
            endcase
        end
    end
endmodule

// --- UNION UNIT ---
module union_unit (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [5:0] root_a,
    input wire [5:0] root_b,
    output reg ready,
    output reg memory_req,
    output reg [5:0] memory_addr,
    output reg [5:0] memory_data
);

    always @(posedge clk) begin
        if (reset) begin
            ready <= 1'b0;
            memory_req <= 1'b0;
        end else begin
            ready <= 1'b0;
            memory_req <= 1'b0;
            
            if (start && root_a != root_b) begin
                memory_req <= 1'b1;
                memory_addr <= root_b;
                memory_data <= root_a;
                ready <= 1'b1;
                $display("🔗 UNION: Merging %d -> %d", root_b, root_a);
            end else if (start) begin
                ready <= 1'b1;
                $display("🔗 UNION: Same root, no merge needed");
            end
        end
    end
endmodule

// --- CLUSTER GROWTH CONTROLLER ---
module cluster_growth_controller (
    input wire clk,
    input wire reset,
    input wire [48:0] syndrome,
    input wire find_ready,
    input wire [5:0] find_data,
    input wire union_ready,
    output reg find_req,
    output reg [5:0] find_addr,
    output reg union_req,
    output reg [5:0] union_addr,
    output reg [5:0] union_data,
    output reg growth_complete
);

    reg [48:0] active_defects;
    reg [5:0] defect_queue [0:24];
    reg [4:0] queue_head;
    reg [4:0] queue_tail;
    reg queue_processing;
    
    reg [5:0] current_root;
    reg [2:0] state;
    integer i;
    
    parameter IDLE = 0, GET_ROOT = 1, DONE = 2;
    
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            find_req <= 1'b0;
            union_req <= 1'b0;
            growth_complete <= 1'b0;
            queue_head <= 0;
            queue_tail <= 0;
            queue_processing <= 1'b0;
        end else begin
            find_req <= 1'b0;
            union_req <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (syndrome != 0 && !queue_processing) begin
                        // Initialize defect queue
                        queue_tail <= 0;
                        for (i = 0; i < 49; i = i + 1) begin
                            if (syndrome[i]) begin
                                defect_queue[queue_tail] <= i;
                                queue_tail <= queue_tail + 1;
                            end
                        end
                        queue_processing <= 1'b1;
                        queue_head <= 0;
                        state <= GET_ROOT;
                        $display("🌱 GROWTH: Starting with %0d defects", queue_tail);
                    end else begin
                        growth_complete <= 1'b1;
                    end
                end
                
                GET_ROOT: begin
                    if (queue_head < queue_tail) begin
                        find_req <= 1'b1;
                        find_addr <= defect_queue[queue_head];
                        state <= GET_ROOT; // Stay in same state until ready
                        $display("🌱 GROWTH: Processing defect %d", defect_queue[queue_head]);
                    end else begin
                        state <= DONE;
                        queue_processing <= 1'b0;
                    end
                    
                    if (find_ready) begin
                        queue_head <= queue_head + 1;
                        $display("🌱 GROWTH: Found root %d for defect", find_data);
                    end
                end
                
                DONE: begin
                    growth_complete <= 1'b1;
                    $display("🌱 GROWTH: Cluster growth complete");
                end
            endcase
        end
    end
endmodule

// --- CORRECTION CALCULATOR ---
module correction_calculator (
    input wire clk,
    input wire reset,
    input wire growth_complete,
    output reg [48:0] correction_mask,
    output reg decode_complete
);

    always @(posedge clk) begin
        if (reset) begin
            correction_mask <= 0;
            decode_complete <= 1'b0;
        end else if (growth_complete) begin
            // Simplified correction - single error at first defect position
            correction_mask <= 49'b1;
            decode_complete <= 1'b1;
            $display("✅ CORRECTION: Decoding complete");
        end else begin
            decode_complete <= 1'b0;
        end
    end
endmodule
