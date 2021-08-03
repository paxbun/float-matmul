// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`include "../inc/float_macros.vh"

// `float_mul` performs the floating-point number multiplication.
module float_mul #(`FLOAT_BIAS_PARAMS) (
    input       [(`FLOAT_WIDTH - 1) : 0]    lhs,
    input       [(`FLOAT_WIDTH - 1) : 0]    rhs,
    output  reg [(`FLOAT_WIDTH - 1) : 0]    res
);
    wire sign_lhs, sign_rhs;
    wire [(EXP_WIDTH + 1) : 0] exp_lhs, exp_rhs;
    wire [(MAN_WIDTH + 2) : 0] man_lhs, man_rhs;
    float_break #(`FLOAT_PRPG_PARAMS) lhs_break (lhs, sign_lhs, exp_lhs, man_lhs);
    float_break #(`FLOAT_PRPG_PARAMS) rhs_break (rhs, sign_rhs, exp_rhs, man_rhs);

    wire [(EXP_WIDTH + 1) : 0] exp_sum;
    wire [(`FLOAT_WIDTH - 1) : 0] res_value;
    wire [((MAN_WIDTH + 3) * 2 - 1) : 0] man_prod;
    assign exp_sum = exp_lhs + exp_rhs + BIAS;
    assign man_prod = man_lhs * man_rhs;
    float_combine #(`FLOAT_PRPG_PARAMS) res_combine (
        sign_lhs ^ sign_rhs,
        exp_sum,
        man_prod[((MAN_WIDTH + 3) * 2 - 4) : MAN_WIDTH],
        res_value
    );

    always @(*) begin
        // If lhs is NaN or infinity
        if (exp_lhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is neither NaN nor infinity
            if (exp_rhs[(EXP_WIDTH - 1) : 0] != { EXP_WIDTH { 1'b1 } }) begin
                res[`FLOAT_WIDTH - 1] = sign_lhs ^ sign_rhs;
                res[(`FLOAT_WIDTH - 2) : 0] = lhs[(`FLOAT_WIDTH - 2) : 0];
            end else if (man_lhs[(MAN_WIDTH - 1) : 0] || man_rhs[(MAN_WIDTH - 1) : 0]) begin
                // If either lhs or rhs is NaN, the result is NaN too
                res[(`FLOAT_WIDTH - 1) : 0] = 1'b0;
                res[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                res[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b1 } };
            end else begin
                // Infinity otherwise
                res[(`FLOAT_WIDTH - 1) : 0] = sign_lhs ^ sign_rhs;
                res[(`FLOAT_WIDTH - 2) : MAN_WIDTH] = { EXP_WIDTH { 1'b1 } };
                res[(MAN_WIDTH - 1) : 0] = { MAN_WIDTH { 1'b0 } };
            end
        end else if (exp_rhs[(EXP_WIDTH - 1) : 0] == { EXP_WIDTH { 1'b1 } }) begin
            // If rhs is NaN or infinity
            res[`FLOAT_WIDTH - 1] = sign_lhs ^ sign_rhs;
            res[(`FLOAT_WIDTH - 2) : 0] = rhs[(`FLOAT_WIDTH - 2) : 0];
        end else begin
            res = res_value;
        end
    end
endmodule