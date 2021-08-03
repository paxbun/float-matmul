`include "../inc/vec_macros.vh"

module tb_float_vec_sum;
    reg clk;
    initial begin
        clk = 1;
    end
    always begin
        #5 clk = ~clk;
    end

    parameter EXP_WIDTH = 8;
    parameter MAN_WIDTH = 23;
    parameter BIAS = -127;
    parameter VEC_SIZE = 13;

    shortreal in_val [(VEC_SIZE - 1) : 0];
    shortreal res_val;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] in;
    wire [(`FLOAT_WIDTH - 1) : 0] res;
    vec_sum #(`VEC_PRPG_PARAMS) sum (clk, in, res);

    always begin
        res_val = 0.0;
        for (int i = 0; i < VEC_SIZE; ++i) begin
            in[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            in_val[i] = $bitstoshortreal(in[`VEC_SELECT(i)]);
            res_val += in_val[i];
        end
        #10;
    end
endmodule

module tb_float_vec_dot;
    reg clk;
    initial begin
        clk = 1;
    end
    always begin
        #5 clk = ~clk;
    end

    parameter EXP_WIDTH = 8;
    parameter MAN_WIDTH = 23;
    parameter BIAS = -127;
    parameter VEC_SIZE = 17;

    shortreal lhs_val [(VEC_SIZE - 1) : 0];
    shortreal rhs_val [(VEC_SIZE - 1) : 0];
    shortreal res_val;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] lhs;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] rhs;
    wire [(`FLOAT_WIDTH - 1) : 0] res;
    vec_dot #(`VEC_PRPG_PARAMS) dot (clk, lhs, rhs, res);

    always begin
        res_val = 0.0;
        for (int i = 0; i < VEC_SIZE; ++i) begin
            lhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            lhs_val[i] = $bitstoshortreal(lhs[`VEC_SELECT(i)]);
            rhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            rhs_val[i] = $bitstoshortreal(rhs[`VEC_SELECT(i)]);
            res_val += lhs_val[i] * rhs_val[i];
        end
        #10;
    end
endmodule

// module tb_float_vec_sum;
//     parameter VEC_SIZE = 11;
//     parameter EXP_WIDTH = 8;
//     parameter MAN_WIDTH = 23;
//     parameter BIAS = -127;

//     shortreal in_val [(VEC_SIZE - 1) : 0];
//     shortreal res_val;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] in;
//     wire [(`FLOAT_WIDTH - 1) : 0] res;
//     vec_sum #(`VEC_PRPG_PARAMS) sum (in, res);

//     function [63:0] abs (input [63:0] in);
//         abs = in[63] ? -in : in;
//     endfunction

//     function isNaN (input [63:0] in);
//         isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
//     endfunction

//     always begin
//         res_val = 0.0;
//         for (int i = 0; i < VEC_SIZE; ++i) begin
//             in[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             in_val[i] = $bitstoshortreal(in[`VEC_SELECT(i)]);
//             res_val += in_val[i];
//         end
//         #1;
//         if (abs($shortrealtobits(res_val) - res) > 1) begin
//             if (isNaN($shortrealtobits(res_val)) != isNaN(res)) begin
//                 $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(res_val), res, res_val, $bitstoshortreal(res));
//             end
//         end
//         #4;
//     end
// endmodule

// module tb_float_vec_dot;
//     parameter VEC_SIZE = 7;
//     parameter EXP_WIDTH = 8;
//     parameter MAN_WIDTH = 23;
//     parameter BIAS = -127;

//     shortreal lhs_val [(VEC_SIZE - 1) : 0];
//     shortreal rhs_val [(VEC_SIZE - 1) : 0];
//     shortreal res_val;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] lhs;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] rhs;
//     wire [(`FLOAT_WIDTH - 1) : 0] res;
//     vec_dot #(`VEC_PRPG_PARAMS) dot (lhs, rhs, res);

//     function [63:0] abs (input [63:0] in);
//         abs = in[63] ? -in : in;
//     endfunction

//     function isNaN (input [63:0] in);
//         isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
//     endfunction

//     always begin
//         res_val = 0.0;
//         for (int i = 0; i < VEC_SIZE; ++i) begin
//             lhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             lhs_val[i] = $bitstoshortreal(lhs[`VEC_SELECT(i)]);
//             rhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             rhs_val[i] = $bitstoshortreal(rhs[`VEC_SELECT(i)]);
//             res_val += lhs_val[i] * rhs_val[i];
//         end
//         #1;
//         if (abs($shortrealtobits(res_val) - res) > 1) begin
//             if (isNaN($shortrealtobits(res_val)) != isNaN(res)) begin
//                 $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(res_val), res, res_val, $bitstoshortreal(res));
//             end
//         end
//         #4;
//     end
// endmodule