// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "mat_macros.vh"

// `mat_mul` implements the matrix multiplication.
module mat_mul #(
    `FLOAT_BIAS_PARAMS,
    parameter I = 4,
    parameter J = 4,
    parameter K = 4
) (
    input                                   clk,
    input   [(`MAT_WIDTH(I, J) - 1) : 0]    lhs,
    input   [(`MAT_WIDTH(J, K) - 1) : 0]    rhs,
    output  [(`MAT_WIDTH(I, K) - 1) : 0]    out
);
    genvar i, j, k;
    generate
        for (i = 0; i < I; i = i + 1) begin
            for (k = 0; k < K; k = k + 1) begin
                wire [(`VEC_WIDTH(J) - 1) : 0] lhs_tmp, rhs_tmp;
                for (j = 0; j < J; j = j + 1) begin
                    assign lhs_tmp[`VEC_SELECT(j)] = lhs[`MAT_SELECT(i, j, J)];
                    assign rhs_tmp[`VEC_SELECT(j)] = rhs[`MAT_SELECT(j, k, K)];
                end
                vec_dot #(
                    `FLOAT_PRPG_BIAS_PARAMS,
                    .VEC_SIZE(J)
                ) dot_product (clk, lhs_tmp, rhs_tmp, out[`MAT_SELECT(i, k, K)]);
            end
        end
    endgenerate
endmodule