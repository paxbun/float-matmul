// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "float_macros.vh"

// `float_swap` ensures that the exponent of `lhs` is the same or greater than that of `rhs`.
module float_swap #(`FLOAT_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    lhs_out,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    rhs_out
);
    wire [(EXP_WIDTH - 1) : 0] lhs_exp, rhs_exp;
    assign lhs_exp = lhs[(`FLOAT_WIDTH - 2) : MAN_WIDTH];
    assign rhs_exp = rhs[(`FLOAT_WIDTH - 2) : MAN_WIDTH];

    always @(*) begin
        if (lhs_exp < rhs_exp) begin
            lhs_out <= rhs;
            rhs_out <= lhs;
        end else begin
            lhs_out <= lhs;
            rhs_out <= rhs;
        end
    end
endmodule