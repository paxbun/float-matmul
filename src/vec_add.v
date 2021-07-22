// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "vec_macros.vh"

// `vec_add` returns the sum of the given two vectors.
module vec_add #(`VEC_PARAMS) (
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    lhs,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    rhs,
    output  [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    out
);
    genvar i;
    generate
        for (i = 0; i < VEC_SIZE; i = i + 1) begin
            float_add #(`FLOAT_PRPG_BIAS_PARAMS) adder (
                lhs[`VEC_SELECT(i)],
                rhs[`VEC_SELECT(i)],
                out[`VEC_SELECT(i)]
            );
        end
    endgenerate
endmodule