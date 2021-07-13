// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "vec_macros.vh"

// `vec_sum` returns the sum of all elements of the given vector.
module vec_sum #(`VEC_PARAMS) (
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    in,
    output  [(`FLOAT_WIDTH - 1) : 0]            out
);
    parameter INTERMEDIATE_SIZE = (VEC_SIZE + 1) / 2;
    parameter NUM_ADDERS = VEC_SIZE / 2;
    genvar i;
    generate
        if (VEC_SIZE == 0) begin
            // do nothing
        end else if (VEC_SIZE == 1) begin
            assign out = in;
        end else begin
            wire [(`VEC_WIDTH(INTERMEDIATE_SIZE) - 1) : 0] result;
            for (i = 0; i < NUM_ADDERS; i = i + 1) begin
                float_add #(`FLOAT_PRPG_BIAS_PARAMS) adder (
                    in[`VEC_SELECT(i * 2 + 0)],
                    in[`VEC_SELECT(i * 2 + 1)],
                    result[`VEC_SELECT(i)]
                );
            end
            if (VEC_SIZE % 2 == 1) begin
                assign result[`VEC_SELECT(INTERMEDIATE_SIZE - 1)]
                    = in[`VEC_SELECT(VEC_SIZE - 1)];
            end
            vec_sum #(
                `FLOAT_PRPG_BIAS_PARAMS,
                .VEC_SIZE(INTERMEDIATE_SIZE)
            ) recursive (result, out);
        end
    endgenerate
endmodule

// `vec_dot` returns the result of the dot product of the given two vectors.
module vec_dot #(`VEC_PARAMS) (
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    lhs,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    rhs,
    output  [(`FLOAT_WIDTH - 1) : 0]            out
);
    wire [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] result;
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
    vec_sum #(`VEC_PRPG_PARAMS) sum (result, out);
endmodule

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

// `vec_relu` applies the ReLU operation to each element of the given vector.
module vec_relu #(`VEC_PARAMS) (
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    in,
    output  [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    out
);
    genvar i;
    generate
        for (i = 0; i < VEC_SIZE; i = i + 1) begin
            float_relu #(`FLOAT_PRPG_PARAMS) relu (in[`VEC_SELECT(i)], out[`VEC_SELECT(i)]);
        end
    endgenerate
endmodule