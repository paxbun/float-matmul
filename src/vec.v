// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "vec_macros.vh"

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

// `vec_sum` returns the sum of all elements of the given vector.
module vec_sum #(`VEC_DEPTH_PARAMS) (
    input                                           clk,
    input   [(`VEC_WIDTH(`VEC_DEPTH_SIZE) - 1) : 0] in,
    output  [(`FLOAT_WIDTH - 1) : 0]                out
);
    parameter INPUT_SIZE = `VEC_DEPTH_SIZE;
    parameter INTM_SIZE = (1 << (DEPTH + 1)) - 1;
    genvar i;
    generate
        if (DEPTH == 0) begin
            assign out = in;
        end else begin
            reg [(`VEC_WIDTH(INTM_SIZE) - 1) : `FLOAT_WIDTH] intm_in;
            wire [(`VEC_WIDTH(INTM_SIZE - INPUT_SIZE) - 1) : 0] intm_out;
            always @(posedge clk) begin
                intm_in[(`VEC_WIDTH(INTM_SIZE - INPUT_SIZE) - 1) : `FLOAT_WIDTH]
                    <= intm_out[(`VEC_WIDTH(INTM_SIZE - INPUT_SIZE) - 1) : `FLOAT_WIDTH];
                intm_in[(`VEC_WIDTH(INTM_SIZE) - 1) : (`VEC_WIDTH(INTM_SIZE - INPUT_SIZE))] <= in;
            end
            assign out = intm_out[`VEC_SELECT(0)];
            for (i = 0; i < DEPTH; i = i + 1) begin
                localparam out_begin = (1 << i) - 1;
                localparam out_length = (1 << i);
                localparam in_begin = out_begin + out_length;
                localparam in_length = (1 << (i + 1));
                vec_sum_reduce #(`FLOAT_PRPG_BIAS_PARAMS, .VEC_SIZE(in_length)) reducer (
                    intm_in[`VEC_WIDTH(in_begin) +: `VEC_WIDTH(in_length)],
                    intm_out[`VEC_WIDTH(out_begin) +: `VEC_WIDTH(out_length)]
                );
            end
        end
    endgenerate
endmodule

// `vec_dot` returns the result of the dot product of the given two vectors.
module vec_dot #(`VEC_DEPTH_PARAMS) (
    input                                           clk,
    input   [(`VEC_WIDTH(`VEC_DEPTH_SIZE) - 1) : 0] lhs,
    input   [(`VEC_WIDTH(`VEC_DEPTH_SIZE) - 1) : 0] rhs,
    output  [(`FLOAT_WIDTH - 1) : 0]                out
);
    parameter INPUT_SIZE = `VEC_DEPTH_SIZE;
    wire [(`VEC_WIDTH(INPUT_SIZE) - 1) : 0] result;
    reg [(`VEC_WIDTH(INPUT_SIZE) - 1) : 0] pipeline;
    genvar i;
    generate
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            float_mul #(`FLOAT_PRPG_BIAS_PARAMS) multiplier (
                lhs[`VEC_SELECT(i)],
                rhs[`VEC_SELECT(i)],
                result[`VEC_SELECT(i)]
            );
        end
    endgenerate
    vec_sum #(`VEC_PRPG_DEPTH_PARAMS) sum (clk, pipeline, out);
    always @(posedge clk) begin
        pipeline <= result;
    end
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