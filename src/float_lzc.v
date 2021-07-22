// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "lzc_macros.vh"

// `float_lzc` performs the same operation with that of `float_naive_lzc`, but also uses logical and
// for shorter critical path. Always prefer `float_lzc` to `float_naive_lzc` without any special
// reason.
module float_lzc #(`LZC_PARAMS, parameter GROUP_SIZE = 8) (
    input       [(INPUT_WIDTH - 1) : 0]     in,
    output  reg [(OUTPUT_WIDTH - 1) : 0]    out
);
    parameter NUM_GROUPS = (INPUT_WIDTH + (GROUP_SIZE - 1)) / GROUP_SIZE;
    parameter LAST_GROUP_SIZE = INPUT_WIDTH - (NUM_GROUPS - 1) * GROUP_SIZE;

    wire [(OUTPUT_WIDTH - 1) : 0] group_out[(NUM_GROUPS - 1) : 0];
    reg [(OUTPUT_WIDTH - 1) : 0] out_list[(NUM_GROUPS - 1) : 0];

    always @(*) begin
        out_list[0] <= group_out[0];
        out <= out_list[NUM_GROUPS - 1];
    end

    float_naive_lzc #(
        .INPUT_WIDTH(LAST_GROUP_SIZE),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .OUTPUT_STEP(OUTPUT_STEP),
        .OUTPUT_BIAS(OUTPUT_BIAS + OUTPUT_STEP * (INPUT_WIDTH - LAST_GROUP_SIZE))
    ) lzc_0 (in[(LAST_GROUP_SIZE - 1) : 0], group_out[0]);

    genvar i;
    generate
        for (i = 1; i < NUM_GROUPS; i = i + 1) begin
            wire [(GROUP_SIZE - 1) : 0] current;
            assign current = in[(GROUP_SIZE * i + LAST_GROUP_SIZE - 1) : (GROUP_SIZE * (i - 1) + LAST_GROUP_SIZE)];

            float_naive_lzc #(
                .INPUT_WIDTH(GROUP_SIZE),
                .OUTPUT_WIDTH(OUTPUT_WIDTH),
                .OUTPUT_STEP(OUTPUT_STEP),
                .OUTPUT_BIAS(OUTPUT_BIAS + OUTPUT_STEP * (INPUT_WIDTH - LAST_GROUP_SIZE - i * GROUP_SIZE))
            ) lzc (current, group_out[i]);

            always @(*) begin
                if (current) begin
                    out_list[i] <= group_out[i];
                end else begin
                    out_list[i] <= out_list[i - 1];
                end
            end
        end
    endgenerate
endmodule