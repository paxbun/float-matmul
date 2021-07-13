`include "mat_macros.vh"

module tb_float_mat_mul;
    parameter I = 4;
    parameter J = 4;
    parameter K = 4;
    parameter EXP_WIDTH = 8;
    parameter MAN_WIDTH = 23;
    parameter BIAS = -127;

    shortreal mat1_v  [(I - 1) : 0][(J - 1) : 0];
    shortreal mat2_v  [(J - 1) : 0][(K - 1) : 0];
    shortreal matr_v  [(I - 1) : 0][(K - 1) : 0];
    shortreal matr_av [(I - 1) : 0][(K - 1) : 0];

    reg [(`MAT_WIDTH(I, J) - 1) : 0] mat1;
    reg [(`MAT_WIDTH(J, K) - 1) : 0] mat2;
    reg [(`MAT_WIDTH(I, K) - 1) : 0] matr;

    wire [(`FLOAT_WIDTH - 1) : 0] mat1_w [(I - 1) : 0][(J - 1) : 0];
    wire [(`FLOAT_WIDTH - 1) : 0] mat2_w [(J - 1) : 0][(K - 1) : 0];
    wire [(`FLOAT_WIDTH - 1) : 0] matr_w [(I - 1) : 0][(K - 1) : 0];

    mat_mul #(
        `FLOAT_PRPG_BIAS_PARAMS,
        .I(I), .J(J), .K(K)
    ) multiplier (mat1, mat2, matr);

    genvar i, j, k;
    generate
        for (i = 0; i < I; ++i) begin
            for (j = 0; j < J; ++j) begin
                assign mat1_w[i][j] = mat1[`MAT_SELECT(i, j, J)];
            end
        end
        for (j = 0; j < J; ++j) begin
            for (k = 0; k < K; ++k) begin
                assign mat2_w[j][k] = mat2[`MAT_SELECT(j, k, K)];
            end
        end
        for (i = 0; i < I; ++i) begin
            for (k = 0; k < J; ++k) begin
                assign matr_w[i][k] = matr[`MAT_SELECT(i, k, K)];
            end
        end
    endgenerate

    function [63:0] abs (input [63:0] in);
        abs = in[63] ? -in : in;
    endfunction

    function isNaN (input [63:0] in);
        isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
    endfunction

    always begin
        for (int i = 0; i < I; ++i) begin
            for (int j = 0; j < J; ++j) begin
                mat1[`MAT_SELECT(i, j, J)] = $urandom_range(0, 32'hFFFFFFFF);
                mat1_v[i][j] = $bitstoshortreal(mat1[`MAT_SELECT(i, j, J)]);
            end
        end
        for (int j = 0; j < J; ++j) begin
            for (int k = 0; k < K; ++k) begin
                mat2[`MAT_SELECT(j, k, K)] = $urandom_range(0, 32'hFFFFFFFF);
                mat2_v[j][k] = $bitstoshortreal(mat2[`MAT_SELECT(j, k, K)]);
            end
        end
        for (int i = 0; i < I; ++i) begin
            for (int k = 0; k < K; ++k) begin
                matr_v[i][k] = 0.0;
                for (int j = 0; j < J; ++j) begin
                    matr_v[i][k] += mat1_v[i][j] * mat2_v[j][k];
                end
            end
        end
        #1;
        for (int i = 0; i < I; ++i) begin
            for (int k = 0; k < K; ++k) begin
                matr_av[i][k] = $bitstoshortreal(matr[`MAT_SELECT(i, k, K)]);
                if (abs($shortrealtobits(matr_av[i][k]) - matr[`MAT_SELECT(i, k, K)]) > 1) begin
                    if (isNaN($shortrealtobits(matr_av[i][k])) != isNaN(matr[`MAT_SELECT(i, k, K)])) begin
                        $display(
                            "Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)",
                            $shortrealtobits(matr_av[i][k]),
                            matr[`MAT_SELECT(i, k, K)],
                            matr_av[i][k],
                            $bitstoshortreal(matr[`MAT_SELECT(i, k, K)])
                        );
                    end
                end
            end
        end
        #4;
    end
endmodule