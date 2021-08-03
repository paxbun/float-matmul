// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/vec_macros.vh"

// `vec_sum_reduce` calculates the pairwise sum of the elements in the vector.
module vec_sum_reduce #(`VEC_PARAMS) (
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]            in,
    output  [(`VEC_WIDTH((VEC_SIZE + 1) / 2) - 1) : 0]  out
);
    parameter NUM_ADDERS = VEC_SIZE / 2;
    parameter INTERMEDIATE_SIZE = (VEC_SIZE + 1) / 2;
    genvar i;
    generate
        if (VEC_SIZE == 0) begin
            // do nothing
        end else if (VEC_SIZE == 1) begin
            assign out = in;
        end else begin
            for (i = 0; i < NUM_ADDERS; i = i + 1) begin
                float_add #(`FLOAT_PRPG_BIAS_PARAMS) adder (
                    in[`VEC_SELECT(i * 2 + 0)],
                    in[`VEC_SELECT(i * 2 + 1)],
                    out[`VEC_SELECT(i)]
                );
            end
            if (VEC_SIZE % 2 == 1) begin
                assign out[`VEC_SELECT(INTERMEDIATE_SIZE - 1)]
                    = in[`VEC_SELECT(VEC_SIZE - 1)];
            end
        end
    endgenerate
endmodule