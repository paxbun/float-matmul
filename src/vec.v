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
module vec_sum #(`VEC_PARAMS) (
    input                                       clk,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    in,
    output  [(`FLOAT_WIDTH - 1) : 0]            out
);
    function integer num_reducers(input integer current);
        begin
            for (num_reducers = 0; current > 1; num_reducers = num_reducers + 1) begin
                current = (current + 1) / 2;
            end
        end
    endfunction

    function integer input_width_at(input integer current, input integer idx);
        integer i;
        begin
            input_width_at = current;
            for (i = 0; i < idx; i = i + 1) begin
                input_width_at = (input_width_at + 1) / 2;
            end
        end
    endfunction

    parameter DEPTH = num_reducers(VEC_SIZE);
    genvar i;
    generate
        if (DEPTH == 0) begin
            assign out = in;
        end else begin
            reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] intm_in [(DEPTH - 1) : 0];
            wire [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] intm_out [(DEPTH - 1) : 0];
            always @(posedge clk) begin
                intm_in[0] <= in;
            end
            assign out = intm_out[DEPTH - 1];
            for (i = 0; i < DEPTH; i = i + 1) begin
                localparam in_size = input_width_at(VEC_SIZE, i);
                localparam out_size = (in_size + 1) / 2;
                vec_sum_reduce #(`FLOAT_PRPG_BIAS_PARAMS, .VEC_SIZE(in_size)) reducer (
                    intm_in[i][(`VEC_WIDTH(in_size) - 1) : 0],
                    intm_out[i][(`VEC_WIDTH(out_size) - 1) : 0]
                );
                if (i > 0) begin
                    always @(posedge clk) begin
                        intm_in[i][(`VEC_WIDTH(in_size) - 1) : 0] <= intm_out[i - 1][(`VEC_WIDTH(in_size) - 1) : 0];
                    end
                end
            end
        end
    endgenerate
endmodule

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