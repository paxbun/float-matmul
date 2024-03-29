// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/vec_macros.vh"

// `vec_sum` returns the sum of all elements of the given vector.
module vec_sum #(`VEC_PARAMS) (
    input                                       clk,
    input   [(`VEC_WIDTH(VEC_SIZE) - 1) : 0]    in,
    output  [(`FLOAT_WIDTH - 1) : 0]            res
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

    genvar i;
    generate
        if (VEC_SIZE == 1) begin
            assign res = in;
        end else begin
            localparam depth = num_reducers(VEC_SIZE);
            // TODO: change the type so `intm_in` has the optimal size 
            reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] intm_in [(depth - 1) : 1];
            wire [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] intm_out [(depth - 1) : 0];
            assign res = intm_out[depth - 1];
            for (i = 0; i < depth; i = i + 1) begin
                localparam in_size = input_width_at(VEC_SIZE, i);
                localparam res_size = (in_size + 1) / 2;
                if (i == 0) begin
                    vec_sum_reduce #(`FLOAT_PRPG_BIAS_PARAMS, .VEC_SIZE(in_size)) reducer (
                        in,
                        intm_out[i][(`VEC_WIDTH(res_size) - 1) : 0]
                    );
                end else begin
                    vec_sum_reduce #(`FLOAT_PRPG_BIAS_PARAMS, .VEC_SIZE(in_size)) reducer (
                        intm_in[i][(`VEC_WIDTH(in_size) - 1) : 0],
                        intm_out[i][(`VEC_WIDTH(res_size) - 1) : 0]
                    );
                    always @(posedge clk) begin
                        intm_in[i][(`VEC_WIDTH(in_size) - 1) : 0]
                            <= intm_out[i - 1][(`VEC_WIDTH(in_size) - 1) : 0];
                    end
                end
            end
        end
    endgenerate
endmodule