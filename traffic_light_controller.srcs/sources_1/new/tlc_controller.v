`timescale 1ns / 1ps
`default_nettype none

/* This module describes the top level traffic light controller (version 1) */
module tlc_controller_ver1(
    output wire [1:0] highwaySignal, farmSignal, // Connected to LEDs
    output wire [3:0] JB,                        // Output state for debugging
    input wire Clk,
    input wire Rst,                              // Button input
    input wire farmSensorBtn
);

    /* Intermediate nets */
    wire RstSync;    // Reset after synchronization
    wire RstCount;   // Reset signal from FSM
    reg [30:0] Count;
    wire farmSensorSync;
    synchronizer SYNC_SENSOR (farmSensorSync, farmSensorBtn, Clk);


    assign JB[3] = RstCount; // Highest debugging bit for Reset Count

    /* Synchronize button inputs */
    // Note: The 'synchronizer' module is provided by the course directory
    synchronizer SYNC (RstSync, Rst, Clk);

    /* Instantiate FSM */
    tlc_fsm FSM(
        .state(JB[2:0]),       // Wire states up to JB for debugging
        .RstCount(RstCount),
        .highwaySignal(highwaySignal),
        .farmSignal(farmSignal),
        .Count(Count),
        .Clk(Clk),
        .Rst(RstSync),         // Use synchronized reset
        .farmSensor(farmSensorSync)
    );

    /* Counter with reset logic */
    always @(posedge Clk or posedge RstSync) begin
        if (RstSync || RstCount) begin
            Count <= 31'b0;
        end
        else begin
            Count <= Count + 1;
        end
    end

endmodule