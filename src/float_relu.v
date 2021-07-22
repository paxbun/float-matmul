// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "float_macros.vh"

// `float_relu` applies the ReLU operation to the given vector.
module float_relu #(`FLOAT_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    in,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    out
);
    always @(*) begin
        if (!in[`FLOAT_WIDTH - 1]) begin
            out <= in;
        end else begin
            out <= { `FLOAT_WIDTH { 1'b0 } };
        end
    end
endmodule