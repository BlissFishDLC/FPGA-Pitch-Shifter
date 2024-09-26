
module Topper (
	// Inputs
	CLOCK_50,
	KEY,

	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK,
	SW,
	LEDR
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[3:0]	SW;


input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output		  	 AUD_XCK;
output		    AUD_DACDAT;

output		    FPGA_I2C_SCLK;

wire				   audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				   read_audio_in;
wire				   audio_out_allowed;
wire				   write_audio_out;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
//codes above this line are given
//made by Xiaoyi Dong starts from here

output    [1:0]   LEDR;

assign    read_audio_in   = audio_in_available & audio_out_allowed;
assign    write_audio_out = audio_in_available & audio_out_allowed;
assign    LEDR[0] = read_audio_in;
assign    LEDR[1] = audio_out_allowed;

// audioControl left channel
audioControl audio_control_left (
    .clk(CLOCK_50),
    .reset(~KEY[0]),
    .audio_in(left_channel_audio_in),
    .SW(SW[1:0]),
    .audio_out(left_channel_audio_out)
);

// audioControl right channel
audioControl audio_control_right (
    .clk(CLOCK_50),
    .reset(~KEY[0]),
    .audio_in(right_channel_audio_in),
    .SW(SW[1:0]),
    .audio_out(right_channel_audio_out)
);

//made by Xiaoyi Dong ends here
//codes after this line are given
/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						   (~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				   (read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			   (write_audio_out),

	.AUD_ADCDAT					   (AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					   (AUD_BCLK),
	.AUD_ADCLRCK				   (AUD_ADCLRCK),
	.AUD_DACLRCK				   (AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					      (AUD_XCK),
	.AUD_DACDAT					   (AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50						(CLOCK_50),
	.reset						   (~KEY[0])
);

endmodule

