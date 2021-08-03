// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/float_macros.vh"

// `float_relu` applies the ReLU operation to the given vector.
module float_relu #(`FLOAT_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    in,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    res
);
    always @(*) begin
        if (!in[`FLOAT_WIDTH - 1]) begin
            res <= in;
        end else begin
            res <= { `FLOAT_WIDTH { 1'b0 } };
        end
    end
endmodule