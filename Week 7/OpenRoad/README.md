# Table of contents

- [Week 7 Task – BabySoC Physical Design & Post-Route SPEF Generation](#week-7-task--babysoc-physical-design--post-route-spef-generation)
- [Floorplan and Placement of VSDBabySoC in OpenROAD](#floorplan-and-placement-of-vsdbabysoc-in-openroad)
- [Macro Configuration File Documentation](#macro-configuration-file-documentation)
- [This proc is here to allow us to use 'return' to return early from this](#this-proc-is-here-to-allow-us-to-use-return-to-return-early-from-this)
- [file which is sourced](#file-which-is-sourced)
- [Repair design using global route parasitics](#repair-design-using-global-route-parasitics)
- [Running DPL to fix overlapped instances](#running-dpl-to-fix-overlapped-instances)
- [Run to get modified net by DPL](#run-to-get-modified-net-by-dpl)
- [Route only the modified net by DPL](#route-only-the-modified-net-by-dpl)
- [Repair timing using global route parasitics](#repair-timing-using-global-route-parasitics)
- [Running DPL to fix overlapped instances](#running-dpl-to-fix-overlapped-instances)
- [Run to get modified net by DPL](#run-to-get-modified-net-by-dpl)
- [Route only the modified net by DPL](#route-only-the-modified-net-by-dpl)
- [log_cmd global_route -start_incremental](#log_cmd-global_route--start_incremental)
- [recover_power_helper](#recover_power_helper)
- [Route the modified nets by rsz journal restore](#route-the-modified-nets-by-rsz-journal-restore)
- [global_routing fix](#log_cmd-global_route--end_incremental-res_aware-)
- [Write SDC to results with updated clock periods that are just failing.](#write-sdc-to-results-with-updated-clock-periods-that-are-just-failing)
- [Use make target update_sdc_clock to install the updated sdc.](#use-make-target-update_sdc_clock-to-install-the-updated-sdc)

# Week 7 Task – BabySoC Physical Design & Post-Route SPEF Generation

This document presents the complete physical design implementation of the BabySoC using OpenROAD, covering all stages from floorplanning to post-route parasitic extraction (SPEF generation). The objective of this task is to integrate the theoretical and practical aspects of digital design by executing a full RTL-to-GDSII flow on a real System-on-Chip (SoC).

Through this exercise, the BabySoC design undergoes floorplan definition, standard cell placement, routing, and parasitic extraction to reflect a realistic ASIC design process. Each stage is explored to understand how physical parameters—such as floorplan constraints, placement density, and routing topology—affect timing performance and design closure.

The outcome of this work is a fully placed and routed BabySoC layout, accompanied by a generated SPEF file that enables post-route Static Timing Analysis (STA). This provides insight into how parasitic effects influence signal delay and how accurate timing verification is performed in professional VLSI design environments.

Comprehensive screenshots, step-by-step procedures, and observations are documented to demonstrate the design flow, tools used, challenges encountered, and verification results.

### Setup and Prepare Project Directory
Clone or set up the directory structure as follows:
```txt
VSDBabySoC/
├── src/
│   ├── include/
│   │   ├── sandpiper.vh
│   │   └── other header files...
│   ├── module/
│   │   ├── vsdbabysoc.v      # Top-level module integrating all components
│   │   ├── rvmyth.v          # RISC-V core module
│   │   ├── avsdpll.v         # PLL module
│   │   ├── avsddac.v         # DAC module
│   │   └── testbench.v       # Testbench for simulation
└── output/
└── compiled_tlv/         # Holds compiled intermediate files if needed
```

### 🛠️ Cloning the Project

To begin, clone the VSDBabySoC repository using the following command:

```bash
cd ~/VLSI
git clone https://github.com/manili/VSDBabySoC.git
cd ~/VLSI/VSDBabySoC/
```
<img width="731" height="267" alt="image" src="1.png" />

### TLV to Verilog Conversion for RVMYTH

Initially, you will see only the `rvmyth.tlv` file inside `src/module/`, since the RVMYTH core is written in TL-Verilog.

<img width="731" height="267" alt="image" src="2.png" />
To convert it into a `.v` file for simulation, follow the steps below:

<strong>🔧<img width="731" height="267" alt="image" src="3.png" /></strong>

```bash
# Step 1: Install python3-venv (if not already installed)
sudo apt update
sudo apt install python3-venv python3-pip
```

<img width="731" height="267" alt="image" src="4.png" />
```
# Step 2: Create and activate a virtual environment
cd ~/VLSI/VSDBabySoC/
python3 -m venv sp_env
source sp_env/bin/activate
```

<img width="731" height="267" alt="image" src="5.png" />

```
# Step 3: Install SandPiper-SaaS inside the virtual environment
pip install pyyaml click sandpiper-saas
```

<img width="731" height="267" alt="image" src="6.png" />
```
# Step 4: Convert rvmyth.tlv to Verilog
sandpiper-saas -i ./src/module/*.tlv -o rvmyth.v --bestsv --noline -p verilog --outdir ./src/module/
```

<img width="731" height="267" alt="image" src="7.png" />
✅ After running the above command, rvmyth.v will be generated in the src/module/ directory.

You can confirm this by listing the files:

<img width="731" height="267" alt="image" src="8.png" />

#### Note 
To use this environment in future sessions, always activate it first:
```bash
source sp_env/bin/activate
```
To exit:
```bash
deactivate
```
### Simulation Steps

#### <ins>Pre-Synthesis Simulation</ins>

Run the following command to perform a pre-synthesis simulation:

```bash
cd ~/VLSI/VSDBabySoC/
mkdir -p output/pre_synth_sim
iverilog -o ~/Desktop/VLSI/VSDBabySoC/output/pre_synth_sim/pre_synth_sim.out -DPRE_SYNTH_SIM -I ~/Desktop/VLSI/VSDBabySoC/src/include -I ~/Desktop/VLSI/VSDBabySoC/src/module ~/Desktop/VLSI/VSDBabySoC/src/module/testbench.v
```
<img width="731" height="267" alt="image" src="9.png" />
Then run:
```bash
cd output/pre_synth_sim
./pre_synth_sim.out
```
<img width="731" height="267" alt="image" src="10.png" />

Explanation:

- DPRE_SYNTH_SIM: Defines the PRE_SYNTH_SIM macro for conditional compilation in the testbench.
- The resulting pre_synth_sim.vcd file can be viewed in GTKWave.

#### Viewing Waveform in GTKWave

After running the simulation, open the VCD file in GTKWave: 

```bash

cd ~/VLSI/VSDBabySoC/
gtkwave output/pre_synth_sim/pre_synth_sim.vcd

```
Drag and drop the CLK, reset, OUT (DAC), and RV TO DAC [9:0] signals to their respective locations in the simulation tool

<img width="731" height="267" alt="image" src="11.png" />
In this picture we can see the following signals:

**CLK**: This is the input CLK signal of the RVMYTH core. This signal comes from the PLL, originally.

**reset**: This is the input reset signal of the RVMYTH core. This signal comes from an external source, originally.

**OUT**: This is the output OUT signal of the VSDBabySoC module. This signal comes from the DAC (due to simulation restrictions it behaves like a digital signal which is incorrect), originally.

**RV_TO_DAC[9:0]**: This is the 10-bit output [9:0] OUT port of the RVMYTH core. This port comes from the RVMYTH register #17, originally.

**OUT**: This is a real datatype wire which can simulate analog values. It is the output wire real OUT signal of the DAC module. This signal comes from the DAC, originally. 

This can be viewed by changing the Data Format of the signal to Analog → Step

#### Viewing DAC output in analog mode

Drag and drop the CLK, reset, OUT (DAC) (as analog step), and RV TO DAC [9:0] signals to their respective locations in the simulation tool 

<img width="731" height="267" alt="image" src="12.png" />
<img width="731" height="267" alt="image" src="13.png" />

### Trouble shooting tips

   - Module Redefinition: If you encounter redefinition errors, ensure modules are included only once, either in the testbench or in the command line.
   - Path Issues: Verify paths specified with -I are correct. Use full paths if relative paths cause errors.

## Why Pre-Synthesis and Post-Synthesis?

1. **Pre-Synthesis Simulation**: 
   - Focuses only on verifying functionality based on the RTL code.
   - Zero-delay environment, with events occurring on the active clock edge.

2. **Post-Synthesis Simulation (GLS)**:
   - Uses the synthesized netlist (gate-level) to simulate both functionality and timing.
   - Identifies timing violations and potential mismatches (e.g., unintended latches).
   - Helps verify dynamic circuit behavior that static methods may miss.

## VSDBabySoC Post-Synthesis Simulation

Post-synthesis simulation is a critical step in the digital design flow, providing insights into both the functionality and timing of the synthesized design. 

Unlike pre-synthesis simulation, which focuses solely on verifying the functionality based on the RTL code, post-synthesis simulation uses the synthesized netlist to ensure that the design behaves correctly in terms of both logic and timing.

Key aspects of post-synthesis simulation include:

**Functionality and Timing Verification**: It checks the design's functionality and timing using the gate-level netlist, helping identify timing violations and potential mismatches such as unintended latches.

**Dynamic Circuit Behavior**: Post-synthesis simulation can reveal dynamic circuit behaviors that static methods might miss, ensuring the design operates correctly under real-world conditions.

**Identifying Issues**: It helps in identifying issues that may not be apparent in pre-synthesis simulations, such as glitches or race conditions due to the actual gate delays.

The first step in the design flow is to synthesize the generated RTL code, followed by simulating the result. This process helps uncover more about the code and its potential bugs. In this section, we will synthesize our code and then perform a post-synthesis simulation to look for any issues. Ideally, the post-synthesis and pre-synthesis (modeling section) results should be identical, confirming that the synthesis process has not altered the original design behavior.

#### Why do pre-synthesis simulation? Why not just do post-synthesis simulation?
Pre-synthesis simulation is crucial for verifying the logical functionality of a digital design before it undergoes synthesis. It allows designers to detect and correct logical errors, such as incorrect operator usage or unintended latch inference, early in the development process. This type of simulation focuses solely on the high-level behavior of the design, enabling faster iterations and design exploration without the constraints of gate-level details. On the other hand, post-synthesis simulation, or gate-level simulation, is essential for timing verification and ensuring that the synthesized design meets real-world performance requirements. It accounts for gate delays and helps identify any synthesis-induced issues, providing a final validation of both functionality and timing before the design is implemented in hardware. Together, these simulations ensure a robust and reliable digital design.

Here is the step-by-step execution plan for running the  commands manually:
---
### **Step 1: Load the Top-Level Design and Supporting Modules**
- Launch the yosys synthesis tool from your working directory.
```bash
yosys
```
<img width="731" height="267" alt="image" src="14.png" />
- Read the main vsdbabysoc.v RTL file into the yosys environment.
```bash
yosys> read_verilog src/module/vsdbabysoc.v 
```
<img width="731" height="267" alt="image" src="15.png" />
- The following cp commands copy essential header files from the src/include directory into the working directory. These include:

  **sp_verilog.vh** – contains Verilog definitions and macros

  **sandpiper.vh** – holds integration-related definitions for SandPiper

  **sandpiper_gen.vh** – may include auto-generated or tool-generated parameters

```bash
cd ~/Desktop/VLSI/VSDBabySoC
cp -r src/include/sp_verilog.vh .
cp -r src/include/sandpiper.vh .
cp -r src/include/sandpiper_gen.vh .
ls
```

<img width="731" height="267" alt="image" src="16.png" />
- Read the rvmyth.v file with the include path using -I option.
```bash
yosys> read_verilog -I ~/Desktop/VLSI/VSDBabySoC/src/include/ ~/Desktop/VLSI/VSDBabySoC/src/module/rvmyth.v
```
<img width="731" height="267" alt="image" src="17.png" />

#### ❗Note:

_If you try to read the rvmyth.v file using yosys without copying the necessary header files first, you may encounter errors.

_To avoid these errors, make sure to copy the required include files into your working directory! This ensures Yosys can resolve them correctly during parsing, even if the -I option is used._

- Read the clk_gate.v file with the include path using -I option.

```bash
yosys> read_verilog -I ~/Desktop/VLSI/VSDBabySoC/src/include/ ~/Desktop/VLSI/VSDBabySoC/src/module/clk_gate.v
```

<img width="731" height="267" alt="image" src="18.png" />
### **Step 2: Load the Liberty Files for Synthesis**
Inside the same yosys shell, run:
```bash
read_liberty -lib ~/Desktop/VLSI/VSDBabySoC/src/lib/avsdpll.lib 
read_liberty -lib ~/Desktop/VLSI/VSDBabySoC/src/lib/avsddac.lib 
read_liberty -lib ~/Desktop/VLSI/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```
<img width="731" height="267" alt="image" src="19.png" />
### **Step 3: Run Synthesis Targeting `vsdbabysoc`**
```bash
yosys> synth -top vsdbabysoc
```
<img width="731" height="267" alt="image" src="20.png" />
### **Step 4: Map D Flip-Flops to Standard Cells**

```bash
yosys> dfflibmap -liberty ~/Desktop/VLSI/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```
<img width="731" height="267" alt="image" src="21.png" />
### **Step 5: Perform Optimization and Technology Mapping**
```bash
yosys> opt
yosys> abc -liberty ~/Desktop/VLSI/VSDBabySoC/src/lib/sky130_fd_sc_hd__tt_025C_1v80.lib -script +strash;scorr;ifraig;retime;{D};strash;dch,-f;map,-M,1,{D}
```

| Step           | Purpose                                                              |
| -------------- | -------------------------------------------------------------------- |
| `strash`       | Structural hashing (reduces logic redundancy)                        |
| `scorr`        | Sequential sweeping for redundancy removal                           |
| `ifraig`       | Incremental FRAIGing (logic equivalence checking and optimization)   |
| `retime;{D}`   | Move registers across combinational logic to optimize timing         |
| `strash`       | Re-run structural hashing after retiming                             |
| `dch,-f`       | Delay-aware combinational optimization with fast mode                |
| `map,-M,1,{D}` | Map logic to gates minimizing area (`-M,1`) and retime-aware (`{D}`) |


<img width="731" height="267" alt="image" src="22.png" />


<img width="731" height="267" alt="image" src="23.png" />

### **Step 6: Perform Final Clean-Up and Renaming**

```bash
yosys> flatten
yosys> setundef -zero
yosys> clean -purge
yosys> rename -enumerate
```
| **Command**         | **Purpose / Usage**                                                                    |
| ------------------- | -------------------------------------------------------------------------------------- |
| `flatten`           | Flattens the entire design hierarchy into a single-level netlist.                      |
| `setundef -zero`    | Replaces all undefined (`x`) logic values with logical `0` to avoid simulation issues. |
| `clean -purge`      | Removes all unused wires, cells, and modules; `-purge` makes it more aggressive.       |
| `rename -enumerate` | Renames internal wires and cells to unique, numbered names for consistency.            |

<img width="731" height="267" alt="image" src="24.png" />

### **Step 7: Check Statistics**
```bash
yosys> stat
```
13. Printing statistics.
```shell
=== vsdbabysoc ===

   Number of wires:               4709
   Number of wire bits:           6183
   Number of public wires:        4709
   Number of public wire bits:    6183
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:               5885
     avsddac                         1
     avsdpll                         1
     sky130_fd_sc_hd__a2111oi_0      8
     sky130_fd_sc_hd__a211oi_1      12
     sky130_fd_sc_hd__a21boi_0       3
     sky130_fd_sc_hd__a21o_2         4
     sky130_fd_sc_hd__a21oi_1      682
     sky130_fd_sc_hd__a221oi_1     165
     sky130_fd_sc_hd__a22oi_1      133
     sky130_fd_sc_hd__a311oi_1       8
     sky130_fd_sc_hd__a31oi_1      333
     sky130_fd_sc_hd__a32o_1         1
     sky130_fd_sc_hd__a32oi_1        2
     sky130_fd_sc_hd__a41oi_1       13
     sky130_fd_sc_hd__and2_2         3
     sky130_fd_sc_hd__and3_2         1
     sky130_fd_sc_hd__clkinv_1     579
     sky130_fd_sc_hd__dfxtp_1     1144
     sky130_fd_sc_hd__lpflow_inputiso0p_1      1
     sky130_fd_sc_hd__mux2i_1       11
     sky130_fd_sc_hd__nand2_1      823
     sky130_fd_sc_hd__nand3_1      278
     sky130_fd_sc_hd__nand3b_1       1
     sky130_fd_sc_hd__nand4_1       48
     sky130_fd_sc_hd__nor2_1       388
     sky130_fd_sc_hd__nor3_1        33
     sky130_fd_sc_hd__nor3b_1        1
     sky130_fd_sc_hd__nor4_1         6
     sky130_fd_sc_hd__o2111a_1       2
     sky130_fd_sc_hd__o2111ai_1     24
     sky130_fd_sc_hd__o211ai_1      48
     sky130_fd_sc_hd__o21a_1         8
     sky130_fd_sc_hd__o21ai_0      867
     sky130_fd_sc_hd__o21bai_1      13
     sky130_fd_sc_hd__o221ai_1       6
     sky130_fd_sc_hd__o22ai_1      154
     sky130_fd_sc_hd__o311ai_0       4
     sky130_fd_sc_hd__o31ai_1        1
     sky130_fd_sc_hd__o41ai_1        2
     sky130_fd_sc_hd__or2_2         14
     sky130_fd_sc_hd__or4_2          1
     sky130_fd_sc_hd__xnor2_1       16
     sky130_fd_sc_hd__xor2_1        42
```

### **Step 8: Write the Synthesized Netlist**
```bash

yosys> write_verilog -noattr ~/Desktop/VLSI/VSDBabySoC/output/post_synth_sim/vsdbabysoc.synth.v
```
<img width="731" height="267" alt="image" src="1.png" />
