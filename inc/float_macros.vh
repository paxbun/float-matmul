// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`ifndef FLOAT_MACROS_VH
`define FLOAT_MACROS_VH

`define FLOAT_PARAMS parameter EXP_WIDTH = 8, parameter MAN_WIDTH = 23
`define FLOAT_BIAS_PARAMS `FLOAT_PARAMS, parameter BIAS = -127
`define FLOAT_PRPG_PARAMS .EXP_WIDTH(EXP_WIDTH), .MAN_WIDTH(MAN_WIDTH)
`define FLOAT_PRPG_BIAS_PARAMS `FLOAT_PRPG_PARAMS, .BIAS(BIAS)
`define FLOAT_WIDTH (EXP_WIDTH + MAN_WIDTH + 1)

`endif