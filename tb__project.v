`timescale 1ns/1ps

module tb_conv_kxk_stream_flat;

    parameter DATA_W  = 8;

    parameter COEFF_W = 8;

    parameter IMG_W   = 5;

    parameter K       = 3;

    localparam OUT_W     = IMG_W - (K-1);

    localparam TOTAL_OUT = OUT_W * OUT_W;

    reg clk;

    reg rst;

    reg valid_in;

    reg [DATA_W-1:0] pixel_in;

    reg signed [(K*K*COEFF_W)-1:0] kernel_flat;

    wire valid_out;

    wire signed [DATA_W+COEFF_W+8:0] conv_out;

    // DUT

    conv_kxk_stream_flat #(

        .DATA_W(DATA_W),

        .COEFF_W(COEFF_W),

        .IMG_W(IMG_W),

        .K(K)

    ) dut (

        .clk(clk),

        .rst(rst),

        .valid_in(valid_in),

        .pixel_in(pixel_in),

        .kernel_flat(kernel_flat),

        .valid_out(valid_out),

        .conv_out(conv_out)

    );

    // Clock

    always #5 clk = ~clk;

    // Image storage

    integer img [0:IMG_W*IMG_W-1];

    integer idx;

    initial begin

        img[0]  = 1;   img[1]  = 2;   img[2]  = 3;   img[3]  = 4;   img[4]  = 5;

        img[5]  = 6;   img[6]  = 7;   img[7]  = 8;   img[8]  = 9;   img[9]  = 10;

        img[10] = 11;  img[11] = 12;  img[12] = 13;  img[13] = 14;  img[14] = 15;

        img[15] = 16;  img[16] = 17;  img[17] = 18;  img[18] = 19;  img[19] = 20;

        img[20] = 21;  img[21] = 22;  img[22] = 23;  img[23] = 24;  img[24] = 25;

    end

    // Kernel initialization: 3x3 all ones

    initial begin

        kernel_flat = 0;

        kernel_flat[0*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[1*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[2*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[3*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[4*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[5*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[6*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[7*COEFF_W +: COEFF_W] =  8'sd1;

        kernel_flat[8*COEFF_W +: COEFF_W] =  8'sd1;

    end

    // Stimulus

    initial begin

        clk = 0;

        rst = 1;

        valid_in = 0;

        pixel_in = 0;

        #20;

        rst = 0;

        // Start streaming pixels

        valid_in = 1;

        for (idx = 0; idx < IMG_W*IMG_W; idx = idx + 1) begin

            pixel_in = img[idx];

            #10;

        end

        valid_in = 0;

        pixel_in = 0;

    end

    // Output printing as matrix

    integer out_count = 0;

    integer out_col   = 0;

    always @(posedge clk) begin

        if (valid_out) begin

            $write("%0d\t", conv_out);

            out_col = out_col + 1;

            out_count = out_count + 1;

            if (out_col == OUT_W) begin

                $write("\n");

                out_col = 0;

            end

            // Stop simulation after all outputs printed

            if (out_count == TOTAL_OUT) begin

                $write("\nSimulation finished. Printed %0d outputs.\n", TOTAL_OUT);

                $finish;

            end

        end

    end

endmodule
 