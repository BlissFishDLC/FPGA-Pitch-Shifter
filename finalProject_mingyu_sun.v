//made by Mingyu Sun
//no error and signal are correct from ModelSim
//not function on FPGA board, only giving the same sound with lower quality
//in order to not conflict with other working modules then comment all the codes here

/*
module fsm(clock, reset, record, setSpeed, play,pause, finishPlay, audioInEn, setSpeedEn, audioOutEn, paused);
input clock, reset, record, setSpeed, play,pause, finishPlay;
output reg audioInEn;
output reg setSpeedEn;
output reg audioOutEn;
output reg paused;

reg [3:0] current_state, next_state;
    localparam  Idle              = 4'd0,
                waitRecord        = 4'd1,
                RecordStage       = 4'd2,
                WaitSetSpeed      = 4'd3,
                settingSpeed      = 4'd4,
                waitForOutput     = 4'd5,
                outputStage       = 4'd6,
                WaitToBePalsed    = 4'd7,
                pauseStage        = 4'd8,
					 WaitToResume	    = 4'd9;
always@(*)
    begin 
            case (current_state)
                Idle: begin
                if(~(record | setSpeed | play))
                    next_state <= Idle;
                else if(record)
					next_state <= waitRecord;
				else if(setSpeed)
				   	next_state <= WaitSetSpeed;
				else if(play)
					next_state <= outputStage;
				end
				waitRecord: begin
                if(record)
					next_state <= waitRecord;
				else
					next_state <= RecordStage;
				end
				RecordStage: begin
				if(record)
					next_state <= WaitSetSpeed;
				else 
					next_state <= RecordStage;

				end
				WaitSetSpeed: begin
				if(setSpeed)
					next_state <= settingSpeed;
				else
					next_state <= WaitSetSpeed;
				end
				settingSpeed: begin
				if(setSpeed) 
					next_state <= settingSpeed;
				else
					next_state <= waitForOutput;
				
				end
				waitForOutput: begin
				if(~play)
					next_state <= waitForOutput;
				else
					next_state <= outputStage;
				end
				outputStage: begin
				if(pause)
					next_state <= WaitToBePalsed;
				else if(finishPlay)
					next_state <= Idle;
				else	
					next_state <= outputStage;
				end
				WaitToBePalsed: begin
				if(pause)
					next_state <= WaitToBePalsed;
				else
					next_state <= pauseStage;
				end
				pauseStage: begin
				if(pause)
					next_state <= WaitToResume;
				else 
					next_state <= pauseStage;
				end
				WaitToResume: begin
				if(pause)
					next_state <= WaitToResume;
				else
					next_state <= outputStage;
				end


             
            default:     next_state = Idle;
      	    endcase
		end 
		always @(*) begin
        // By default make all our signals 0
      audioInEn = 0;
		setSpeedEn = 0;
		audioOutEn = 0;
		paused = 0;


        case (current_state)
        RecordStage: begin
			audioInEn = 1;
		end
		settingSpeed: begin
			setSpeedEn = 1;
		end
		outputStage: begin
			audioOutEn = 1;
		end
		pauseStage: begin
			paused = 1;
		end

            
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase

    end // enable_signals
always@(posedge clock) begin
        if(reset)
            begin
            current_state <= Idle;
            end
        else
            current_state <= next_state;
    end // state_FFS


        
endmodule

module pitchShifter(clock, reset, audioIn, read_audio_in, 
							speed, setSpeed, audioOut, write_audio_out, 
							record, play, pause, audio_in_available,audio_out_allowed);
	parameter fast = 2500;
	parameter nornal = 5000;
	parameter slow = 10000;
	input clock, reset, setSpeed,record, play, pause;
	input wire [31:0]audioIn;
	input audio_in_available, audio_out_allowed;
	input [1:0]speed;
	output [31:0]audioOut;
	output reg read_audio_in;
	output reg write_audio_out;
	reg [1:0] storedSpeed;
	reg [15:0]  addressm1;
	reg [15:0]  m1LastAddress;
	wire finishPlay;
	reg [25:0]counter;
	reg  wrenm1, start, resetSola;
	wire audioInEn, setSpeedEn, audioOutEn, paused, wrenm2, finishSola;
	wire [31:0] data;
	wire [31:0] m1Out;
	wire [31:0] solaOut;
	wire [15:0] addressm2;
	wire [15:0] addressm1Sola;
	reg setFinishSola;
	fsm f1(clock, reset, record, setSpeed, play,pause, finishPlay, audioInEn, setSpeedEn, audioOutEn, paused);


	audioMemory m1(addressm1, clock, audioIn, wrenm1, m1Out);
	audioMemory m2(addressm2, clock, solaOut, wrenm2, audioOut);
	sola s1(clock, reset, start, m1Out, solaOut, finishSola, speed, m1LastAddress,addressm1Sola,addressm2, wrenm2, finishPlay, resetSola,audioOutEn);
	always @(posedge clock)begin
	if(reset)begin
		addressm1 <= -1;
		counter <=nornal;
		wrenm1 <= 0;
		 setFinishSola <= 0;
		write_audio_out <= 0;
		read_audio_in <= 0;
	end
	if(audioInEn)begin
		 if(counter == nornal)begin
			 wrenm1 <= 1;
			counter <= 0;	
			m1LastAddress <= addressm1 +1;
			 addressm1 <= addressm1 + 1;
			 read_audio_in <= 1;
		end
		else begin
			wrenm1 <=0;
			counter <= counter +1;
		end
		

	end
	if(~audioInEn & (~audioOutEn)) begin
		counter <= 0;
	end
	if(~audioInEn) begin
		wrenm1 <= 0;
		read_audio_in <= 0;
	end
	if(~audioOutEn)
		write_audio_out <= 0;
		resetSola <= 1;
	if(setSpeedEn)begin
		storedSpeed <= speed; 
	end
	if(audioOutEn)begin
		resetSola <= 0;
		 addressm1 <= addressm1Sola;
		if(~finishSola)begin
			start <=1;
		end
		else begin
			write_audio_out <= 1;
			start <= 0;
			
		end
		
	end


	end
endmodule

module sola(clock, reset, start, audioIn, audioOut, finishSola, speed, m1LastAddress,addressm1,addressm2, outEn,finishPlay, resetSola,audioOutEn);
	input clock, reset, start, resetSola, audioOutEn;
	input [31:0]audioIn;
	input [1:0]speed;
	input [15:0]m1LastAddress;
	output reg [31:0]audioOut;
	output reg[15:0]addressm2;
	reg[15:0]m2LastAddress;
	output reg[1:0]addressm1;
	output reg finishSola;
	output reg outEn;
	output reg finishPlay;
	reg [25:0] counter;
	reg [34:0] r0;
	reg [34:0] r1;
	reg [34:0] r2;
	reg [34:0] r3;
	reg [34:0] r4;
	reg [34:0] r5;
	reg [34:0] r6;
	reg [34:0] r7;
	reg [34:0] r8;
	reg [34:0] r9;
	reg [34:0] r10;
	reg [34:0] r11;
	reg [34:0] r12;
	reg [34:0] r13;
	reg [34:0] r14;
	reg [34:0] r15;


always @(posedge clock)begin
	if(reset)begin
		addressm1 <= -1;
		counter <= 0;
		outEn <= 0;
		addressm2 <= -1;
		finishSola <= 0;
		finishPlay <= 0;
	end
	if(resetSola) begin
		finishPlay <= 0;
		finishSola <= 0;
	end
	if(audioOutEn) begin
	if(start)begin
		if(speed == 0)begin
			if(counter == 0)begin
				r0 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
				outEn <= 0;
			end
			else if(counter == 1)begin
				r1 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 2)begin
				r2 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 3)begin
				r3 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 4)begin
				r4 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 5)begin
				r5 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 6)begin
				r6 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 7)begin
				r7 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 8)begin
				r8 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 9)begin
				r9 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 10)begin
				r10 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 11)begin
				r11 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 12)begin
				r12 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 13)begin
				r13 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 14)begin
				r14 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 15)begin
				r15 <= audioIn;
				counter <= counter +1;
				addressm1 <= addressm1 +1;
			end
			else if(counter == 16)begin
				audioOut <= r0;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
				outEn <= 1;
			end
			
			else if(counter == 17)begin
				if(r1[31] == 1)begin
					r1 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r1)* 7) >> 3;
				end
				else begin
					r1 = (r1 * 7) >> 3;
				end
				if(r9[31] == 1)begin
					r9 = 33'b100000000000000000000000000000000 - (33'b100000000000000000000000000000000 - r9) >> 3;
				end
				else begin
					r9 = r9 >> 3;
				end

				audioOut = r1 + r9;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 18)begin
				if(r2[31] == 1)begin
					r2 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r2)* 6) >> 3;
				end
				else begin
					r2 = (r2 * 6) >> 3;
				end
				if(r10[31] == 1)begin
					r10 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r10)* 2) >> 3;
				end
				else begin
					r10 = (r10 * 2) >> 3;
				end

				audioOut = r2 + r10;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 19)begin
				if(r3[31] == 1)begin
					r3 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r3)* 5) >> 3;
				end
				else begin
					r3 = (r3 * 5) >> 3;
				end
				if(r11[31] == 1)begin
					r11 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r11)* 3) >> 3;
				end
				else begin
					r11 = (r11 * 3) >> 3;
				end

				audioOut = r3 + r11;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 20)begin
				if(r4[31] == 1)begin
					r4 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r4)* 4) >> 3;
				end
				else begin
					r4 = (r4 * 4) >> 3;
				end
				if(r12[31] == 1)begin
					r12 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r12)* 4) >> 3;
				end
				else begin
					r12 = (r12 * 4) >> 3;
				end

				audioOut = r4 + r12;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 21)begin
				if(r5[31] == 1)begin
					r5 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r5)* 3) >> 3;
				end
				else begin
					r5 = (r5 * 3) >> 3;
				end
				if(r13[31] == 1)begin
					r13 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r13)*5 ) >> 3;
				end
				else begin
					r13 = (r13 * 5) >> 3;
				end

				audioOut = r5 + r13;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 22)begin
				if(r6[31] == 1)begin
					r6 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r6)* 2) >> 3;
				end
				else begin
					r6 = (r6 * 2) >> 3;
				end
				if(r14[31] == 1)begin
					r14 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r14)* 6) >> 3;
				end
				else begin
					r14 = (r14 * 6) >> 3;
				end

				audioOut = r6 + r14;
				counter <= counter +1;
				addressm2 <= addressm2 +1;
			end
			else if(counter == 23)begin
				if(r7[31] == 1)begin
					r7 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r7)* 1) >> 3;
				end
				else begin
					r7 = (r7 * 1) >> 3;
				end
				if(r15[31] == 1)begin
					r15 = 33'b100000000000000000000000000000000 - ((33'b100000000000000000000000000000000 - r15)* 7) >> 3;
				end
				else begin
					r15 = (r15 * 7) >> 3;
				end

				audioOut = r7 + r15;
				counter <= 0;
				addressm2 <= addressm2 +1;
				if(addressm1 >= m1LastAddress)begin
					addressm1 <= -1;
					outEn <= 0;
					m2LastAddress <= addressm2 + 1;
					finishSola <= 1;
					counter <= 2;
				end
			end
		end

		
                
	end
	else begin	
		if(addressm2 == m2LastAddress) begin
			addressm2 <= 0;
		end
		else begin
			if(counter == 10000) begin
				addressm2 <= addressm2 +1;
				counter <= 0;
			end
			else if(counter < 10000) begin
			 	counter <= counter +1;
			end
			if(addressm2 == (m2LastAddress - 1))begin
				finishPlay <= 1;
				counter <= 0;
				addressm2 <= 0;
				addressm1 <= 0;

			end

		end

	end
end
end

endmodule


module audioMemory (
	address,
	clock,
	data,
	wren,
	q);

	input	[12:0]  address;
	input	  clock;
	input	[31:0]  data;
	input	  wren;
	output	[31:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [31:0] sub_wire0;
	wire [31:0] q = sub_wire0[31:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 8192,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 13,
		altsyncram_component.width_a = 32,
		altsyncram_component.width_byteena_a = 1;


endmodule
*/