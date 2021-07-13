module tb_float_mul_add;
	reg [31:0] lhs, rhs;
    shortreal lhs_val, rhs_val;
	wire [31:0] prod, sum;
    shortreal prod_val, sum_val;
    float_mul mul (lhs, rhs, prod);
    float_add add (lhs, rhs, sum);

    function [31:0] abs (input [31:0] in);
        abs = in[31] ? -in : in;
    endfunction

    function isNaN (input [31:0] in);
        isNaN = (in[30:23] == { 8 { 1'b1 } } && in[22:0]);
    endfunction

	always begin
        lhs =  $urandom_range(0, 32'hFFFFFFFF);
        rhs =  $urandom_range(0, 32'hFFFFFFFF);
        lhs_val = $bitstoshortreal(lhs);
        rhs_val = $bitstoshortreal(rhs);
        prod_val = lhs_val * rhs_val;
        sum_val = lhs_val + rhs_val;
        #1;
        if (abs($shortrealtobits(prod_val) - prod) > 1) begin
            if (isNaN($shortrealtobits(prod_val)) != isNaN(prod)) begin
                $display("Mul error: 0x%X * 0x%X (%.6f * %.6f)", lhs, rhs, lhs_val, rhs_val);
                $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(prod_val), prod, prod_val, $bitstoshortreal(prod));
            end
        end
        if (abs($shortrealtobits(sum_val) - sum) > 1) begin
            if (isNaN($shortrealtobits(sum_val)) != isNaN(sum)) begin
                $display("Mul error: 0x%X * 0x%X (%.6f * %.6f)", lhs, rhs, lhs_val, rhs_val);
                $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $shortrealtobits(sum_val), sum, sum_val, $bitstoshortreal(sum));
            end
        end
        #4;
    end
endmodule

module tb_double_mul_add;
	reg [63:0] lhs, rhs;
    real lhs_val, rhs_val;
	wire [63:0] prod, sum;
    real prod_val, sum_val;
    float_mul #(.EXP_WIDTH(11), .MAN_WIDTH(52), .BIAS(-1023)) mul (lhs, rhs, prod);
    float_add #(.EXP_WIDTH(11), .MAN_WIDTH(52), .BIAS(-1023)) add (lhs, rhs, sum);

    function [63:0] abs (input [63:0] in);
        abs = in[63] ? -in : in;
    endfunction

    function isNaN (input [63:0] in);
        isNaN = (in[62:52] == { 11 { 1'b1 } } && in[51:0]);
    endfunction

	always begin
        lhs =  { $urandom_range(0, 32'hFFFFFFFF), $urandom_range(0, 32'hFFFFFFFF) };
        rhs =  { $urandom_range(0, 32'hFFFFFFFF), $urandom_range(0, 32'hFFFFFFFF) };
        lhs_val = $bitstoreal(lhs);
        rhs_val = $bitstoreal(rhs);
        prod_val = lhs_val * rhs_val;
        sum_val = lhs_val + rhs_val;
        #1;
        if (abs($realtobits(prod_val) - prod) > 1) begin
            if (isNaN($realtobits(prod_val)) != isNaN(prod)) begin
                $display("Mul error: 0x%X * 0x%X (%.6f * %.6f)", lhs, rhs, lhs_val, rhs_val);
                $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $realtobits(prod_val), prod, prod_val, $bitstoreal(prod));
            end
        end
        if (abs($realtobits(sum_val) - sum) > 1) begin
            if (isNaN($realtobits(sum_val)) != isNaN(sum)) begin
                $display("Mul error: 0x%X * 0x%X (%.6f * %.6f)", lhs, rhs, lhs_val, rhs_val);
                $display("Expected / Actual: 0x%X / 0x%X (%.6f / %.6f)", $realtobits(sum_val), sum, sum_val, $bitstoreal(sum));
            end
        end
        #4;
    end
endmodule