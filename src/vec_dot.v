// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "vec_macros.vh"

// `vec_dot` returns the result of the dot product of the given two vectors.
module vec_dot #(`VEC_PARAMS) (
    input                                       clk,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    lhs,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    rhs,
    output  [(`FLOAT_WIDTH - 1) : 0]            out
);
    wire [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] result;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] pipeline;
    genvar i;
    generate
        for (i = 0; i < VEC_SIZE; i = i + 1) begin
            float_mul #(`FLOAT_PRPG_BIAS_PARAMS) multiplier (
                lhs[`VEC_SELECT(i)],
                rhs[`VEC_SELECT(i)],
                result[`VEC_SELECT(i)]
            );
        end
    endgenerate
    vec_sum #(`VEC_PRPG_PARAMS) sum (clk, pipeline, out);
    always @(posedge clk) begin
        pipeline <= result;
    end
endmodule