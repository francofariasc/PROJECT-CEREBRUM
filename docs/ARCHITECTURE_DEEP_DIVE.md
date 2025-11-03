# Architecture Deep Dive: Project Cerebrum

## System Overview
Syndrome Input → Growth Controller → Find/Union Units → Memory System → Correction Output

### Core Components

#### 1. Ninja Memory System
- **Parent Array**: 64×6-bit memory storing union-find tree structure
- **Cache Layer**: 4-way associative cache for frequent access patterns
- **Prediction Engine**: Sequential address prediction for prefetching
- **Speculative Resolver**: Handle memory dependencies without stalling

#### 2. Union-Find Processing Engine
- **Find Unit**: Two-stage pipeline:
  - Stage 1: Lookup node's parent
  - Stage 2: Lookup parent's parent (path compression)
- **Union Unit**: Single-cycle root merging with conflict detection
- **Growth Controller**: Defect queue management and cluster processing

#### 3. Surface Code Integration
- **49-bit Syndrome**: Surface code stabilizer measurements
- **Defect Processing**: Convert syndrome defects to union-find operations
- **Correction Calculator**: Generate error correction masks from clusters

### Memory Hierarchy
Registers → Cache → Parent Array → External Memory
1 cycle 1 cycle 2 cycles 10+ cycles

### Performance Optimizations
- **Pipelined Operations**: Overlap memory accesses with computation
- **Ready Handshaking**: Non-blocking inter-module communication
- **Queue-based Processing**: Efficient defect batch processing
- **Hardware Parallelism**: Concurrent find/union operations
