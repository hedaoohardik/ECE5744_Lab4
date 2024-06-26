// 3 new test cases added

// 1.Maximal Case: Both A and B are set to their maximal values (0xFFFF) with a carry-in (Cin) to check the overflow handling.
// 2.Alternate Bits Set: Alternate bits set in A and the inverse pattern in B with and without carry-in to test the adder's bit-wise operations.
// 3.Incremental Case: A continuously increases, while B is set to a small constant value, testing the adder's ability to handle small incremental changes over a range.

// Includes required files for Cadence Virtuoso
`include "constants.vams"
`include "disciplines.vams"

// Use macro to define adder's bit width
`define NBITS 16

/*
    -------------------------------------------------
                SIGNAL GENERATOR MODULE
    -------------------------------------------------
*/
// Declare test signal generator module
module lab4_signal_gen_wff(A, B, Cin, CLK);

// Declare outputs
output Cin;
output CLK;
// Declare 16-bit outputs from MSB-LSB ordering
output [`NBITS-1:0] A;
output [`NBITS-1:0] B;

// Specify desired output type to be a continuous voltage signal
voltage Cin;
voltage CLK;
voltage [`NBITS-1:0] A;
voltage [`NBITS-1:0] B;

// Declare locally-scoped constants using localparam keyword
// Clock period for test cases
localparam cp = 4000p;
// Clock half-period for FF clock latch signal
localparam cp2 = 2000p;

// Number of testcases per testsuite
localparam tb1 = 2;
localparam tb2 = `NBITS;
localparam tb3 = `NBITS;
localparam tb4 = 2;
localparam tb5 = 2;
localparam tb6 = 2;
localparam tb7 = 2; // New test suite for maximal case
localparam tb8 = 2; // New test suite for alternate bits set
localparam tb9 = 16; // New test suite for incremental case

// Tracks clock signal high/low value
real            clk_sig;

// Constants for clock periods
parameter real  clk_period = cp from (0:inf);
parameter real  clk_period2 = cp2 from (0:inf);
parameter real  trise = 20p from [0:inf];
parameter real  tfall = 20p from [0:inf];

// Constants for voltage signal bounds
parameter real  v_high = 1.2;
parameter real  v_low = 0.0;

// Initialize integer variables for signal generator outputs
// A, B, Cin are inputs to the N-bit adder
integer         A_curr;
integer         B_curr;
integer         Cin_curr;

// Keeps track of how many testcases have completed
integer         curTestCount = 0;

// Testsuite specific helper variables
integer         tb2Count = 0;
integer         tb3Count = 0;
integer         tb4Count = 1;
integer         tb5Count = 1;
integer         tb6Count = 1;
integer         tb9Count = 0;

// Initialize counters to be used in for-loop
// Cannot use integers as the for-loop used is a "generator construct"
genvar          j;

// Start analog description of module
analog begin

    // Initialize signal generator output values
    @(initial_step) begin
        A_curr = 0;
        B_curr = 0;
        Cin_curr = 0;
    }

/*
    -------------------------------------------------
                FF BUFFER STAGE CLOCK SIGNAL
    -------------------------------------------------
*/

    // Timer block to oscillate flip-flop latch clock signal
    @(timer(1n,clk_period2)) begin
        if (clk_sig == v_low) begin 
            clk_sig = v_high;
        end
        else begin
            clk_sig = v_low;
        end
    }

    // Write to CLK output pin
    V(CLK)  <+ transition(clk_sig, 0, trise, tfall);

/*
    -------------------------------------------------
                TESTCASE DEFINITIONS
    -------------------------------------------------
*/

    // Timer block to run testcases
    @(timer(0.5n,clk_period)) begin

    // Testsuite 1
        curTestCount = curTestCount + 1;
        if (curTestCount <= tb1) begin
            A_curr = 0;
            B_curr = 0;
            Cin_curr = 0;
            if(curTestCount == 2) begin
                Cin_curr = 1;
            end
        end

    // Testsuite 2
        if (tb1 < curTestCount && curTestCount <= tb1 + tb2) begin
            A_curr = 16'hFFFF;
            B_curr = (1 << tb2Count);
            Cin_curr = 0;
            tb2Count  = tb2Count + 1;
        end

    // Testsuite 3
        if (tb1 + tb2 < curTestCount && curTestCount <= tb1 + tb2 + tb3) begin
            A_curr = (1 << tb3Count);
            B_curr = 16'hFFFF;
            Cin_curr = 0;
            tb3Count  = tb3Count + 1;
        end

    // Testsuite 4
        if (tb1 + tb2 + tb3 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4) begin
            A_curr = 16'hFFFF;
            B_curr = 0;
            Cin_curr = 1;
            if(tb4Count == 2) begin
                A_curr = 0;
                B_curr = 16'hFFFF;
                Cin_curr = 1;
            end
            tb4Count  = tb4Count + 1;
        end

    // Testsuite 5
        if (tb1 + tb2 + tb3 + tb4 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4 + tb5) begin
            A_curr = 16'h000F;
            B_curr = 0;
            Cin_curr = 1;
            if(tb5Count == 2) begin
                A_curr = 0;
                B_curr = 16'h000F;
                Cin_curr = 1;
            end
            tb5Count  = tb5Count + 1;
        end

    // Testsuite 6
        if (tb1 + tb2 + tb3 + tb4 + tb5 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4 + tb5 + tb6) begin
            A_curr = 16'h5555;
            B_curr = 16'hAAAA;
            Cin_curr = 0;
            if(tb6Count == 2) begin
                A_curr = 16'h5555;
                B_curr = 16'hAAAA;
                Cin_curr = 1;
            end
            tb6Count  = tb6Count + 1;
        end

    // Test Suite 7: Maximal Case
        if (tb1 + tb2 + tb3 + tb4 + tb5 + tb6 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4 + tb5 + tb6 + tb7) begin
            A_curr = 16'hFFFF;
            B_curr = 16'hFFFF;
            Cin_curr = curTestCount % 2;  // Alternate Cin
        end

    // Test Suite 8: Alternate Bits Set
        if (tb1 + tb2 + tb3 + tb4 + tb5 + tb6 + tb7 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4 + tb5 + tb6 + tb7 + tb8) begin
            A_curr = 16'hAAAA;
            B_curr = 16'h5555;
            Cin_curr = curTestCount % 2;  // Alternate Cin
        end

    // Test Suite 9: Incremental Case
        if (tb1 + tb2 + tb3 + tb4 + tb5 + tb6 + tb7 + tb8 < curTestCount && curTestCount <= tb1 + tb2 + tb3 + tb4 + tb5 + tb6 + tb7 + tb8 + tb9) begin
            A_curr = tb9Count;
            B_curr = 16'h0003;
            Cin_curr = 0;
            tb9Count  = tb9Count + 1;
        end
    end



    // Parse integer testcase inputs into binary,
    // write resultant binary to N-bit output pins
    for (j = 0; j < `NBITS; j = j + 1) begin
        V(A[j])  <+ transition(A_curr & (1 << j) ? v_high : v_low, 0, trise, tfall);
        V(B[j])  <+ transition(B_curr & (1 << j) ? v_high : v_low, 0, trise, tfall);
    end
    V(Cin)   <+ transition(Cin_curr ? v_high : v_low, 0, trise, tfall);

end

endmodule
