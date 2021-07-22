// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "lzc_macros.vh"

// `float_naive_lzc` counts the number of the leading zeros of the given unsigned integer.
// `float_naive_lzc` assigns `s * n + b` to `out` where `s` is OUTPUT_STEP, `b` is OUTPUT_BIAS, and
// `n` is the number of the leading zeros.
module float_naive_lzc #(`LZC_PARAMS) (
    input       [(INPUT_WIDTH - 1) : 0]     in,
    output  reg [(OUTPUT_WIDTH - 1) : 0]    out
);
    reg [(OUTPUT_WIDTH - 1) : 0] out_list[INPUT_WIDTH  : 0];

    always @(*) begin
        out_list[0] <= OUTPUT_STEP * INPUT_WIDTH + OUTPUT_BIAS;
        out <= out_list[INPUT_WIDTH];
    end
    
    genvar i;
    generate
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            always @(*) begin
                if (in[i]) begin
                    out_list[i + 1] <= OUTPUT_STEP * (INPUT_WIDTH - 1 - i) + OUTPUT_BIAS;
                end else begin
                    out_list[i + 1] <= out_list[i];
                end
            end
        end
    endgenerate
endmodule