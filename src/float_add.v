// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/float_macros.vh"

`define NEGATE(cond, expr) ((cond) ? -(expr) : (expr))

// `float_add` performs the floating-point number addition.
module float_add #(`FLOAT_BIAS_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    res
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

    wire [(`FLOAT_WIDTH - 1) : 0] res_value;
    float_combine #(`FLOAT_PRPG_PARAMS) res_combine (
        man_sum[(MAN_WIDTH + 2)],
        exp_lhs,
        man_sum_fin,
        res_value
    );

    always @(*) begin
        // If lhs is NaN or infinity
        if (exp_lhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is neither NaN nor infinity
            if (exp_rhs[(EXP_WIDTH - 1) : 0] != { EXP_WIDTH { 1'b1 } }) begin
                res = lhs_swapped;
            end else if (man_lhs[(MAN_WIDTH - 1) : 0] || man_rhs[(MAN_WIDTH - 1) : 0]) begin
                // If either lhs or rhs is NaN, the result is NaN too
                res[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                res[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                res[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else if (sign_lhs != sign_rhs) begin
                // If both lhs and rhs are infinity, the result is NaN if they have different sign
                res[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                res[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                res[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else begin
                // Infinity otherwise
                res = lhs_swapped;
            end
        end else if (exp_rhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is NaN or infinity
            res = rhs_swapped;
        end else begin
            res = res_value;
        end
    end
endmodule
