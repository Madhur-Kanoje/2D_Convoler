module conv_kxk_stream_flat #(

    parameter DATA_W  = 8,

    parameter COEFF_W = 8,

    parameter IMG_W   = 5,

    parameter K       = 3

)(

    input  wire                              clk,

    input  wire                              rst,

    input  wire                              valid_in,

    input  wire [DATA_W-1:0]                 pixel_in,

    input  wire signed [(K*K*COEFF_W)-1:0]   kernel_flat,

    output reg                               valid_out,

    output reg signed [DATA_W+COEFF_W+8:0]   conv_out

);

    integer i, j;

    // line buffers

    reg [DATA_W-1:0] linebuf [0:K-2][0:IMG_W-1];

    reg [$clog2(IMG_W)-1:0] wr_ptr;

    // delayed row pixels

    reg [DATA_W-1:0] row_pix [0:K-1];

    // window

    reg [DATA_W-1:0] window [0:K-1][0:K-1];

    // row/col counters

    reg [$clog2(IMG_W):0] col_cnt;

    reg [31:0] row_cnt;

    // -----------------------------

    // Row/Col counter

    // -----------------------------

    always @(posedge clk) begin

        if (rst) begin

            col_cnt <= 0;

            row_cnt <= 0;

        end

        else if (valid_in) begin

            if (col_cnt == IMG_W-1) begin

                col_cnt <= 0;

                row_cnt <= row_cnt + 1;

            end

            else begin

                col_cnt <= col_cnt + 1;

            end

        end

    end

    // -----------------------------

    // Line buffer update// -----------------------------

    always @(posedge clk) begin

        if (rst) begin

            wr_ptr <= 0;

            for (i = 0; i < K; i = i + 1)

                row_pix[i] <= 0;

            for (i = 0; i < K-1; i = i + 1)

                for (j = 0; j < IMG_W; j = j + 1)

                    linebuf[i][j] <= 0;

        end

        else if (valid_in) begin

            // read

            for (i = 0; i < K-1; i = i + 1)

                row_pix[i] <= linebuf[i][wr_ptr];

            row_pix[K-1] <= pixel_in;

            // shift line buffers down

            for (i = 0; i < K-2; i = i + 1)

                linebuf[i][wr_ptr] <= linebuf[i+1][wr_ptr];

            linebuf[K-2][wr_ptr] <= pixel_in;

            // advance pointer

            if (wr_ptr == IMG_W-1)

                wr_ptr <= 0;

            else

                wr_ptr <= wr_ptr + 1;

        end

    end

    // -----------------------------

    // Window shift register update

    // -----------------------------

    always @(posedge clk) begin

        if (rst) begin

            for (i = 0; i < K; i = i + 1)

                for (j = 0; j < K; j = j + 1)

                    window[i][j] <= 0;

        end

        else if (valid_in) begin

            // shift left

            for (i = 0; i < K; i = i + 1)

                for (j = 0; j < K-1; j = j + 1)

                    window[i][j] <= window[i][j+1];

            // insert right column

            for (i = 0; i < K; i = i + 1)

                window[i][K-1] <= row_pix[i];

        end

    end

    // -----------------------------

    // Convolution combinational MAC

    // -----------------------------

    reg signed [DATA_W+COEFF_W+8:0] acc;

    reg signed [COEFF_W-1:0] coeff;

    always @(*) begin

        acc = 0;

        for (i = 0; i < K; i = i + 1) begin

            for (j = 0; j < K; j = j + 1) begin

                coeff = kernel_flat[((i*K + j)*COEFF_W) +: COEFF_W];

                acc = acc + $signed({1'b0, window[i][j]}) * coeff;

            end

        end

    end

    // -----------------------------

    // valid_out generation (CORRECT)

    // valid when inside valid output region

    // -----------------------------

    always @(posedge clk) begin

        if (rst) begin

            valid_out <= 0;

        end

        else if (valid_in) begin

            if ((row_cnt >= (K-1)) && (col_cnt >= (K-1)))

                valid_out <= 1;

            else

                valid_out <= 0;

        end

        else begin

            valid_out <= 0;

        end

    end

    // -----------------------------

    // Register output only when valid_out

    // -----------------------------

    always @(posedge clk) begin

        if (rst)

            conv_out <= 0;

        else if (valid_in && valid_out)

            conv_out <= acc;

    end

endmodule
