// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/float_macros.vh"

// `float_combine` combines the given sign part, the exponent part, and the mantissa part into one
// single floating-point number. Note that `float_combine` assumes that the mantissa is always
// positive. Even if the sign bit of the mantissa part is set, `float_combine` regards it unset.
// The caller must manually negate the mantissa if it is negative. `float_combine` also assumes that
// the result is not NaN. The caller must implement the logic to handle such cases.
module float_combine #(`FLOAT_PARAMS) (
    input                                   sign,
    input       [(EXP_WIDTH + 1) : 0]       exp,
    input       [(MAN_WIDTH + 2) : 0]       man,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    out
);
    wire [(EXP_WIDTH + 1) : 0] exp_offset, man_shift, final_exp;
    wire [MAN_WIDTH : 0] final_man, final_man_shifted_right;
    wire [(MAN_WIDTH + 2) : 0] man_shifted_left;
    
    assign final_exp = exp + exp_offset;
    assign man_shifted_left = man << man_shift;
    assign final_man = man_shifted_left[(MAN_WIDTH + 1) : 1];
    assign final_man_shifted_right = final_man >> ({ { EXP_WIDTH + 1 { 1'b0 } }, 1'b1 } - final_exp);
    
    float_lzc #(
        .INPUT_WIDTH(MAN_WIDTH + 2),
        .OUTPUT_WIDTH(EXP_WIDTH + 2),
        .OUTPUT_STEP(-1),
        .OUTPUT_BIAS(1)
    ) exp_offset_calc (man[(MAN_WIDTH + 1) : 0], exp_offset);

    float_lzc #(
        .INPUT_WIDTH(MAN_WIDTH + 2),
        .OUTPUT_WIDTH(EXP_WIDTH + 2)
    ) man_shift_calc (man[(MAN_WIDTH + 1) : 0], man_shift);

    always @(*) begin
        out[(`FLOAT_WIDTH - 1)] <= sign;
        // If the exponent is negative or 0
        if (final_exp[EXP_WIDTH + 1]
            || final_exp[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b0 } }) begin
            // Set the exponent of the result to 0 and shift the mantissa again
            out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] <= { EXP_WIDTH { 1'b0 } };
            out[(MAN_WIDTH - 1) : 0] <= final_man_shifted_right[(MAN_WIDTH - 1) : 0];
        end else if (final_exp[EXP_WIDTH]
            || final_exp[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If the exponent is greater than or equal to { EXP_WIDTH { 1'b1 } },
            // then the result is infinity
            out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] <= { EXP_WIDTH { 1'b1 } };
            out[(MAN_WIDTH - 1) : 0] <= { MAN_WIDTH { 1'b0 } };
        end else if (final_man[MAN_WIDTH]) begin
            out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] <= final_exp[(EXP_WIDTH - 1) : 0];
            out[(MAN_WIDTH - 1) : 0] <= final_man[(MAN_WIDTH - 1) : 0];
        end else begin
            // The result is 0
            out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] <= { EXP_WIDTH { 1'b0 } };
            out[(MAN_WIDTH - 1) : 0] <= { EXP_WIDTH { 1'b0 } };
        end
    end
endmodule