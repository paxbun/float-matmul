// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "vec_macros.vh"

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