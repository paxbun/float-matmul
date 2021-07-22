// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "float_macros.vh"

// `float_break` splits the given floating-point number into the sign part, the exponent part, and
// the mantissa part. `float_break` extends the mantissa part so it follows the fixed-point number
// format with 1 sign bit, 2 integer bits, and MAN_WIDTH decimal bits. Note that even if the given
// number is negative, `float_break` returns positive mantissa. If the exponent of `in` is 0,
// `float_break` assigns 1 to `exp`.
module float_break #(`FLOAT_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    in,
    output                                  sign,
    output      [(EXP_WIDTH + 1) : 0]       exp,
    output  reg [(MAN_WIDTH + 2) : 0]       man
);
    assign sign = in[`FLOAT_WIDTH - 1];
    assign exp[(EXP_WIDTH + 1) : EXP_WIDTH] = 2'b0;
    assign exp[(EXP_WIDTH - 1) : 1] = in[(`FLOAT_WIDTH - 2) : (MAN_WIDTH + 1)];

    always @(*) begin
        man[(MAN_WIDTH + 2) : (MAN_WIDTH + 1)] <= 2'b0;
        if (!in[(`FLOAT_WIDTH - 2) : MAN_WIDTH]) begin
            man[MAN_WIDTH] <= 0;
        end else begin
            man[MAN_WIDTH] <= 1;
        end
        man[(MAN_WIDTH - 1) : 0] = in[(MAN_WIDTH - 1) : 0];
    end

    assign exp[0] = in[MAN_WIDTH] | !man[MAN_WIDTH];
endmodule
