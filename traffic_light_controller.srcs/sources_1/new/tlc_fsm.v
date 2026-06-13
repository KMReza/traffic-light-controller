`timescale 1ns / 1ps
`default_nettype none

module tlc_fsm(
    output reg [2:0] state,
    output reg RstCount,
    output reg [1:0] highwaySignal, farmSignal,
    input wire [30:0] Count,
    input wire Clk, Rst,
    input wire farmSensor // New sensor input
);

    // State Encoding
    parameter S0 = 3'b000, // Red/Red
              S1 = 3'b001, // Highway Green (Min 30s)
              S2 = 3'b010, // Highway Yellow
              S3 = 3'b011, // Red/Red
              S4 = 3'b100, // Farm Green (Min 3s)
              S5 = 3'b101, // Farm Yellow
              S6 = 3'b110, // Highway Green (Wait for Sensor)
              S7 = 3'b111; // Farm Green (Extension up to 15s)

    parameter GREEN = 2'b11, YELLOW = 2'b10, RED = 2'b01;

    reg [2:0] nextState;

    always @(posedge Clk) begin
        if (Rst) state <= S0;
        else state <= nextState;
    end

    // Next State Logic with Sensor Integration
    always @(*) begin
        case (state)
            S0: nextState = (Count >= 50_000_000) ? S1 : S0;  
            // Highway must be green for at least 30s 
            S1: nextState = (Count >= 1_500_000_000) ? S6 : S1; 
            // Stay in S6 as long as no car is on farm road 
            S6: nextState = (farmSensor) ? S2 : S6;           
            S2: nextState = (Count >= 150_000_000) ? S3 : S2; 
            S3: nextState = (Count >= 50_000_000) ? S4 : S3;  
            // Farm road green for at least 3s
            S4: nextState = (Count >= 150_000_000) ? S7 : S4;  
            // Remain green if sensor is high, but max 15 addtl seconds
            S7: nextState = (!farmSensor || Count >= 750_000_000) ? S5 : S7; 
            S5: nextState = (Count >= 150_000_000) ? S0 : S5;  
            default: nextState = S0;
        endcase
    end

    // Output Logic
    always @(*) begin
        highwaySignal = RED; farmSignal = RED; RstCount = 0;
        case (state)
            S0: begin highwaySignal = RED;    if (Count >= 50_000_000) RstCount = 1; end
            S1: begin highwaySignal = GREEN;  if (Count >= 1_500_000_000) RstCount = 1; end
            S6: begin highwaySignal = GREEN;  if (farmSensor) RstCount = 1; end
            S2: begin highwaySignal = YELLOW; if (Count >= 150_000_000) RstCount = 1; end
            S3: begin highwaySignal = RED;    if (Count >= 50_000_000) RstCount = 1; end
            S4: begin farmSignal = GREEN;     if (Count >= 150_000_000) RstCount = 1; end
            S7: begin farmSignal = GREEN;     if (!farmSensor || Count >= 750_000_000) RstCount = 1; end
            S5: begin farmSignal = YELLOW;   if (Count >= 150_000_000) RstCount = 1; end
        endcase
    end
endmodule