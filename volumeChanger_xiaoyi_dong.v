//  Created by Xiaoyi Dong on 2023/12/04.
//  SW[1:0] 00 silence 01 up 11 original 10 down
//  input output audio signal 32 bits
//  Two structures are given according to different situations: 
//  1. Unified module 2. Separate modules: FSM, FIFO, DATAPATH
//  12/05 bugs found on Separate modules and signal width is 16 bits -> using Unified module only


// 1. unified module
module audioControl(
    input clk,
    input reset,
    input [31:0] audio_in,
    output reg [31:0] audio_out,
    input [1:0] SW // function select
);

// FIFO
reg [31:0] fifo[0:1];
reg [1:0] fifo_count = 0;
reg [31:0] last_sample = 0;
reg slow_down_phase = 0;
reg [1:0] sample_counter = 0;

always @(posedge clk) begin
    if (reset) begin
        fifo_count <= 0;
        last_sample <= 0;
        slow_down_phase <= 0;
        audio_out <= 0;
    end else begin
        // FIFO buffer handle
        if (fifo_count < 2) begin
            fifo[fifo_count] <= audio_in;
            fifo_count <= fifo_count + 1;
        end

        case (SW)
            2'b00: begin // silence checked
                audio_out <= 0;
            end
            2'b01: begin // turn up
                if (fifo_count == 2) begin
                    audio_out <= fifo[0] <<< 2;
                    fifo[0] <= fifo[1];
                    fifo_count <= 1;
                end
            end

            2'b10: begin // turn down
                if (fifo_count == 2) begin
                    audio_out <= fifo[0];
                    fifo[0] <= fifo[1];
                    fifo_count <= 1;
                end
            end
            2'b11: begin // original checked
                if (fifo_count == 2) begin
                    audio_out <= fifo[0] <<< 1;
                    fifo[0] <= fifo[1];
                    fifo_count <= 1;
                end
            end
        endcase
    end
end

endmodule

/*
// 2.Separate modules
// 2.1 FSM

module fsm (
    input clk,
    input reset,
    input [1:0] SW,
    output reg [1:0] mode
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        mode <= 2'b10;
    end else begin
        mode <= SW;
    end
end

endmodule

// 2.2 FIFO

module fifo_buffer (
    input clk,
    input reset,
    input [15:0] audio_in,
    output reg [15:0] audio_out,
    input read_enable,
    input write_enable,
    output reg full,
    output reg empty
);

reg [15:0] buffer[1:0];
reg [1:0] count = 0;

always @(posedge clk) begin
    if (reset) begin
        count <= 0;
        empty <= 1;
        full <= 0;
    end else begin
        if (write_enable && !full) begin
            buffer[count] <= audio_in;
            count <= count + 1;
            empty <= 0;
            if (count == 1) full <= 1;
        end
        if (read_enable && !empty) begin
            audio_out <= buffer[0];
            buffer[0] <= buffer[1];
            count <= count - 1;
            full <= 0;
            if (count == 1) empty <= 1;
        end
    end
end

endmodule

// 2.3 DATAPATH

module datapath (
    input clk,
    input reset,
    input [15:0] audio_in,
    output reg [15:0] audio_out,
    input [1:0] mode
);

reg [15:0] last_sample = 0;
reg slow_down_phase = 0;

always @(posedge clk) begin
    if (reset) begin
        last_sample <= 0;
        slow_down_phase <= 0;
        audio_out <= 0;
    end else begin
        case (mode)
            2'b00: audio_out <= 0;
            2'b01: audio_out <= (audio_in + last_sample) >> 1;
            2'b10: audio_out <= audio_in;
            2'b11: begin
                if (slow_down_phase == 0) begin
                    audio_out <= audio_in;
                    slow_down_phase <= 1;
                end else begin
                    audio_out <= (audio_in + last_sample) >> 1;
                    slow_down_phase <= 0;
                end
            end
        endcase
        last_sample <= audio_in;
    end
end

endmodule

// 2.4 audioControl topper

module audioControl(
    input clk,
    input reset,
    input [15:0] audio_in,
    input [1:0] SW,
    output [15:0] audio_out
);

wire [1:0] mode;
wire [15:0] fifo_out;
wire fifo_read_enable, fifo_write_enable, fifo_full, fifo_empty;

fsm fsm_inst (
    .clk(clk),
    .reset(reset),
    .SW(SW),
    .mode(mode)
);

fifo_buffer fifo_inst (
    .clk(clk),
    .reset(reset),
    .audio_in(audio_in),
    .audio_out(fifo_out),
    .read_enable(fifo_read_enable),
    .write_enable(fifo_write_enable),
    .full(fifo_full),
    .empty(fifo_empty)
);

datapath datapath_inst (
    .clk(clk),
    .reset(reset),
    .audio_in(fifo_out),
    .audio_out(audio_out),
    .mode(mode)
);

assign fifo_write_enable = !fifo_full;
assign fifo_read_enable = !fifo_empty && (mode != 2'b10);

endmodule
*/