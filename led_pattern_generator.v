`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:10:28 07/16/2026 
// Design Name: 
// Module Name:    led_pattern_generator 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////// ====================================================================
// ====================================================================
// Digital LED Pattern Generator (Corrected Version)
// ====================================================================

module led_pattern_generator (
    input  wire       clk,             // System Clock
    input  wire       reset,           // Reset Button
    input  wire       start_stop,      // Start/Stop Switch (1 = Run, 0 = Pause)
    input  wire [1:0] pattern_select,  // User Inputs: Pattern Selection
    input  wire       speed_inc,       // User Inputs: Speed Increase (Pulse)
    input  wire       speed_dec,       // User Inputs: Speed Decrease (Pulse)
    input  wire       directio_ctrl,   // User Inputs: Direction Control (1=Left, 0=Right)
    output wire [7:0] led_out          // LED Driver Outputs
);

    // ----------------------------------------------------------------
    // 1. Clock Divider Signals
    // ----------------------------------------------------------------
    reg [27:0] clk_divider;            // Core clock divider register
    wire       slow_clock;             // Pulsed output to drive pattern shifting

    // ----------------------------------------------------------------
    // 2. Speed Controller & Edge Detection Module
    // ----------------------------------------------------------------
    reg [2:0] speed_level;             // 8 Speed levels (0 to 7)

    // Debounce/edge detectors for speed increment and decrement buttons
    reg speed_inc_d, speed_inc_edge;
    reg speed_dec_d, speed_dec_edge;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            speed_inc_d     <= 1'b0;
            speed_inc_edge  <= 1'b0;
            speed_dec_d     <= 1'b0;
            speed_dec_edge  <= 1'b0;
        end else begin
            speed_inc_d     <= speed_inc;
            speed_inc_edge  <= speed_inc && !speed_inc_d; // rising edge detect
            speed_dec_d     <= speed_dec;
            speed_dec_edge  <= speed_dec && !speed_dec_d; // rising edge detect
        end
    end

    // Speed parameter configuration adjustment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            speed_level <= 3'd3; // Default intermediate speed
        end else begin
            if (speed_inc_edge && (speed_level < 3'd7))
                speed_level <= speed_level + 1'b1;
            else if (speed_dec_edge && (speed_level > 3'd0))
                speed_level <= speed_level - 1'b1;
        end
    end

    // Clock division maximum count logic based on selected speed level
    reg [27:0] max_count;
    always @(*) begin
        case (speed_level)
            3'd0: max_count = 28'd50_000_000; // Slowest
            3'd1: max_count = 28'd25_000_000;
            3'd2: max_count = 28'd12_500_000;
            3'd3: max_count = 28'd6_250_000;  // Default
            3'd4: max_count = 28'd3_125_000;
            3'd5: max_count = 28'd1_562_500;
            3'd6: max_count = 28'd781_250;
            3'd7: max_count = 28'd390_625;    // Fastest
            default: max_count = 28'd6_250_000;
        endcase // <-- FIXED: Changed from 'case' to 'endcase' here
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_divider <= 28'b0;
        end else if (clk_divider >= max_count - 1) begin
            clk_divider <= 28'b0;
        end else begin
            clk_divider <= clk_divider + 1'b1;
        end
    end

    assign slow_clock = (clk_divider == (max_count - 1));

    // ----------------------------------------------------------------
    // 3. Pattern Selector & Shift Logic
    // ----------------------------------------------------------------
    reg [7:0] pattern_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pattern_reg <= 8'b0000_0001;
        end else if (start_stop && slow_clock) begin
            case (pattern_select)
                // Pattern 0: Single Chasing LED
                2'b00: begin
                    if (directio_ctrl) // Left shift
                        pattern_reg <= {pattern_reg[6:0], pattern_reg[7]};
                    else               // Right shift
                        pattern_reg <= {pattern_reg[0], pattern_reg[7:1]};
                end

                // Pattern 1: Double Block Chasing
                2'b01: begin
                    if (directio_ctrl)
                        pattern_reg <= {pattern_reg[5:0], pattern_reg[7:6]};
                    else
                        pattern_reg <= {pattern_reg[1:0], pattern_reg[7:2]};
                end

                // Pattern 2: Alternating Flashing Blocks
                2'b10: begin
                    pattern_reg <= ~pattern_reg;
                end

                // Pattern 3: Multi-directional Binary Counter Simulation
                2'b11: begin
                    if (directio_ctrl)
                        pattern_reg <= pattern_reg + 1'b1;
                    else
                        pattern_reg <= pattern_reg - 1'b1;
                end
            endcase
        end
    end

    // ----------------------------------------------------------------
    // 4. LED Driver Module (Continuous Assignment)
    // ----------------------------------------------------------------
    // <-- FIXED: Replaced faulty always block with a clean assign statement
    assign led_out = pattern_reg;

endmodule