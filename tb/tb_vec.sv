`include "vec_macros.vh"

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
    parameter DEPTH = 3;
    parameter VEC_SIZE = 1 << DEPTH;

    shortreal in_val [(VEC_SIZE - 1) : 0];
    shortreal out_val;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] in;
    wire [(`FLOAT_WIDTH - 1) : 0] out;
    vec_sum #(`VEC_PRPG_DEPTH_PARAMS) sum (clk, in, out);

    always begin
        out_val = 0.0;
        for (int i = 0; i < VEC_SIZE; ++i) begin
            in[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            in_val[i] = $bitstoshortreal(in[`VEC_SELECT(i)]);
            out_val += in_val[i];
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
    parameter DEPTH = 3;
    parameter VEC_SIZE = `VEC_DEPTH_SIZE;

    shortreal lhs_val [(VEC_SIZE - 1) : 0];
    shortreal rhs_val [(VEC_SIZE - 1) : 0];
    shortreal out_val;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] lhs;
    reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] rhs;
    wire [(`FLOAT_WIDTH - 1) : 0] out;
    vec_dot #(`VEC_PRPG_DEPTH_PARAMS) dot (clk, lhs, rhs, out);

    always begin
        out_val = 0.0;
        for (int i = 0; i < VEC_SIZE; ++i) begin
            lhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            lhs_val[i] = $bitstoshortreal(lhs[`VEC_SELECT(i)]);
            rhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
            rhs_val[i] = $bitstoshortreal(rhs[`VEC_SELECT(i)]);
            out_val += lhs_val[i] * rhs_val[i];
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
//     shortreal out_val;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] in;
//     wire [(`FLOAT_WIDTH - 1) : 0] out;
//     vec_sum #(`VEC_PRPG_PARAMS) sum (in, out);

//     function [63:0] abs (input [63:0] in);
//         abs = in[63] ? -in : in;
//     endfunction

//     function isNaN (input [63:0] in);
//         isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
//     endfunction

//     always begin
//         out_val = 0.0;
//         for (int i = 0; i < VEC_SIZE; ++i) begin
//             in[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             in_val[i] = $bitstoshortreal(in[`VEC_SELECT(i)]);
//             out_val += in_val[i];
//         end
//         #1;
//         if (abs($shortrealtobits(out_val) - out) > 1) begin
//             if (isNaN($shortrealtobits(out_val)) != isNaN(out)) begin
//                 $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(out_val), out, out_val, $bitstoshortreal(out));
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
//     shortreal out_val;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] lhs;
//     reg [(`VEC_WIDTH(VEC_SIZE) - 1) : 0] rhs;
//     wire [(`FLOAT_WIDTH - 1) : 0] out;
//     vec_dot #(`VEC_PRPG_PARAMS) dot (lhs, rhs, out);

//     function [63:0] abs (input [63:0] in);
//         abs = in[63] ? -in : in;
//     endfunction

//     function isNaN (input [63:0] in);
//         isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
//     endfunction

//     always begin
//         out_val = 0.0;
//         for (int i = 0; i < VEC_SIZE; ++i) begin
//             lhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             lhs_val[i] = $bitstoshortreal(lhs[`VEC_SELECT(i)]);
//             rhs[`VEC_SELECT(i)] = $urandom_range(0, 32'hFFFFFFFF);
//             rhs_val[i] = $bitstoshortreal(rhs[`VEC_SELECT(i)]);
//             out_val += lhs_val[i] * rhs_val[i];
//         end
//         #1;
//         if (abs($shortrealtobits(out_val) - out) > 1) begin
//             if (isNaN($shortrealtobits(out_val)) != isNaN(out)) begin
//                 $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(out_val), out, out_val, $bitstoshortreal(out));
//             end
//         end
//         #4;
//     end
// endmodule