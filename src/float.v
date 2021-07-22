// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "float_macros.vh"

`define LZC_PARAMS              \
    parameter INPUT_WIDTH = 26, \
    parameter OUTPUT_WIDTH = 5, \
    parameter OUTPUT_STEP = 1,  \
    parameter OUTPUT_BIAS = 0

`define NEGATE(cond, expr) ((cond) ? -(expr) : (expr))

// `float_naive_lzc` counts the number of the leading zeros of the given unsigned integer.
// `float_naive_lzc` assigns `s * n + b` to `out` where `s` is OUTPUT_STEP, `b` is OUTPUT_BIAS, and
// `n` is the number of the leading zeros.
module float_naive_lzc #(`LZC_PARAMS) (
    input       [(INPUT_WIDTH - 1) : 0]     in,
    output  reg [(OUTPUT_WIDTH - 1) : 0]    out
);
    reg [(OUTPUT_WIDTH - 1) : 0] out_list[INPUT_WIDTH  : 0];

    always @(*) begin
        out_list[0] <= OUTPUT_STEP * INPUT_WIDTH + OUTPUT_BIAS;
        out <= out_list[INPUT_WIDTH];
    end
    
    genvar i;
    generate
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            always @(*) begin
                if (in[i]) begin
                    out_list[i + 1] <= OUTPUT_STEP * (INPUT_WIDTH - 1 - i) + OUTPUT_BIAS;
                end else begin
                    out_list[i + 1] <= out_list[i];
                end
            end
        end
    endgenerate
endmodule

// `float_lzc` performs the same operation with that of `float_naive_lzc`, but also uses logical and
// for shorter critical path. Always prefer `float_lzc` to `float_naive_lzc` without any special
// reason.
module float_lzc #(`LZC_PARAMS, parameter GROUP_SIZE = 8) (
    input       [(INPUT_WIDTH - 1) : 0]     in,
    output  reg [(OUTPUT_WIDTH - 1) : 0]    out
);
    parameter NUM_GROUPS = (INPUT_WIDTH + (GROUP_SIZE - 1)) / GROUP_SIZE;
    parameter LAST_GROUP_SIZE = INPUT_WIDTH - (NUM_GROUPS - 1) * GROUP_SIZE;

    wire [(OUTPUT_WIDTH - 1) : 0] group_out[(NUM_GROUPS - 1) : 0];
    reg [(OUTPUT_WIDTH - 1) : 0] out_list[(NUM_GROUPS - 1) : 0];

    always @(*) begin
        out_list[0] <= group_out[0];
        out <= out_list[NUM_GROUPS - 1];
    end

    float_naive_lzc #(
        .INPUT_WIDTH(LAST_GROUP_SIZE),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .OUTPUT_STEP(OUTPUT_STEP),
        .OUTPUT_BIAS(OUTPUT_BIAS + OUTPUT_STEP * (INPUT_WIDTH - LAST_GROUP_SIZE))
    ) lzc_0 (in[(LAST_GROUP_SIZE - 1) : 0], group_out[0]);

    genvar i;
    generate
        for (i = 1; i < NUM_GROUPS; i = i + 1) begin
            wire [(GROUP_SIZE - 1) : 0] current;
            assign current = in[(GROUP_SIZE * i + LAST_GROUP_SIZE - 1) : (GROUP_SIZE * (i - 1) + LAST_GROUP_SIZE)];

            float_naive_lzc #(
                .INPUT_WIDTH(GROUP_SIZE),
                .OUTPUT_WIDTH(OUTPUT_WIDTH),
                .OUTPUT_STEP(OUTPUT_STEP),
                .OUTPUT_BIAS(OUTPUT_BIAS + OUTPUT_STEP * (INPUT_WIDTH - LAST_GROUP_SIZE - i * GROUP_SIZE))
            ) lzc (current, group_out[i]);

            always @(*) begin
                if (current) begin
                    out_list[i] <= group_out[i];
                end else begin
                    out_list[i] <= out_list[i - 1];
                end
            end
        end
    endgenerate
endmodule

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

// `float_mul` performs the floating-point number multiplication.
module float_mul #(`FLOAT_BIAS_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    out
);
    wire sign_lhs, sign_rhs;
    wire [(EXP_WIDTH + 1) : 0] exp_lhs, exp_rhs;
    wire [(MAN_WIDTH + 2) : 0] man_lhs, man_rhs;
    float_break #(`FLOAT_PRPG_PARAMS) lhs_break (lhs, sign_lhs, exp_lhs, man_lhs);
    float_break #(`FLOAT_PRPG_PARAMS) rhs_break (rhs, sign_rhs, exp_rhs, man_rhs);

    wire [(EXP_WIDTH + 1) : 0] exp_sum;
    wire [(`FLOAT_WIDTH - 1) : 0] out_value;
    wire [((MAN_WIDTH + 3) * 2 - 1) : 0] man_prod;
    assign exp_sum = exp_lhs + exp_rhs + BIAS;
    assign man_prod = man_lhs * man_rhs;
    float_combine #(`FLOAT_PRPG_PARAMS) out_combine (
        sign_lhs ^ sign_rhs,
        exp_sum,
        man_prod[((MAN_WIDTH + 3) * 2 - 4) : MAN_WIDTH],
        out_value
    );

    always @(*) begin
        // If lhs is NaN or infinity
        if (exp_lhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is neither NaN nor infinity
            if (exp_rhs[(EXP_WIDTH - 1) : 0] != { EXP_WIDTH { 1'b1 } }) begin
                out[`FLOAT_WIDTH - 1] = sign_lhs ^ sign_rhs;
                out[(`FLOAT_WIDTH - 2) : 0] = lhs[(`FLOAT_WIDTH - 2) : 0];
            end else if (man_lhs[(MAN_WIDTH - 1) : 0] || man_rhs[(MAN_WIDTH - 1) : 0]) begin
                // If either lhs or rhs is NaN, the result is NaN too
                out[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                out[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else begin
                // Infinity otherwise
                out[(`FLOAT_WIDTH - 1) : 0] = sign_lhs ^ sign_rhs;
                out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                out[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b0 } };
            end
        end else if (exp_rhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is NaN or infinity
            out[`FLOAT_WIDTH - 1] = sign_lhs ^ sign_rhs;
            out[(`FLOAT_WIDTH - 2) : 0] = rhs[(`FLOAT_WIDTH - 2) : 0];
        end else begin
            out = out_value;
        end
    end
endmodule

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

// `float_add` performs the floating-point number addition.
module float_add #(`FLOAT_BIAS_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    out
);
    wire [(`FLOAT_WIDTH - 1) : 0] lhs_swapped, rhs_swapped;
    float_swap #(`FLOAT_PRPG_PARAMS) swapper (lhs, rhs, lhs_swapped, rhs_swapped);

    wire sign_lhs, sign_rhs;
    wire [(EXP_WIDTH + 1) : 0] exp_lhs, exp_rhs;
    wire [(MAN_WIDTH + 2) : 0] man_lhs, man_rhs;
    float_break #(`FLOAT_PRPG_PARAMS) lhs_break (lhs_swapped, sign_lhs, exp_lhs, man_lhs);
    float_break #(`FLOAT_PRPG_PARAMS) rhs_break (rhs_swapped, sign_rhs, exp_rhs, man_rhs);

    reg signed [(MAN_WIDTH + 2) : 0] man_lhs_fin, man_rhs_fin;
    always @(*) begin
        man_lhs_fin <= `NEGATE(sign_lhs, man_lhs);
        man_rhs_fin <= `NEGATE(sign_rhs, man_rhs);
    end

    wire [(EXP_WIDTH + 1) : 0] exp_diff;
    assign exp_diff = exp_lhs - exp_rhs;

    wire signed [(MAN_WIDTH + 2) : 0] man_rhs_fin_shifted;
    assign man_rhs_fin_shifted = man_rhs_fin >>> exp_diff;

    wire [(MAN_WIDTH + 2) : 0] man_sum;
    reg [(MAN_WIDTH + 2) : 0] man_sum_fin;
    assign man_sum = man_lhs_fin + man_rhs_fin_shifted;
    always @(*) begin
        man_sum_fin <= `NEGATE(man_sum[(MAN_WIDTH + 2)], man_sum);
    end

    wire [(`FLOAT_WIDTH - 1) : 0] out_value;
    float_combine #(`FLOAT_PRPG_PARAMS) out_combine (
        man_sum[(MAN_WIDTH + 2)],
        exp_lhs,
        man_sum_fin,
        out_value
    );

    always @(*) begin
        // If lhs is NaN or infinity
        if (exp_lhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is neither NaN nor infinity
            if (exp_rhs[(EXP_WIDTH - 1) : 0] != { EXP_WIDTH { 1'b1 } }) begin
                out = lhs_swapped;
            end else if (man_lhs[(MAN_WIDTH - 1) : 0] || man_rhs[(MAN_WIDTH - 1) : 0]) begin
                // If either lhs or rhs is NaN, the result is NaN too
                out[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                out[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else if (sign_lhs != sign_rhs) begin
                // If both lhs and rhs are infinity, the result is NaN if they have different sign
                out[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                out[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                out[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else begin
                // Infinity otherwise
                out = lhs_swapped;
            end
        end else if (exp_rhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is NaN or infinity
            out = rhs_swapped;
        end else begin
            out = out_value;
        end
    end
endmodule

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