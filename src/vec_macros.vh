// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`ifndef VEC_MACROS_VH
`define VEC_MACROS_VH

`include "float_macros.vh"

`define VEC_PARAMS `FLOAT_BIAS_PARAMS, parameter VEC_SIZE = 32
`define VEC_PRPG_PARAMS `FLOAT_PRPG_BIAS_PARAMS, .VEC_SIZE(VEC_SIZE)
`define VEC_DEPTH_PARAMS `FLOAT_BIAS_PARAMS, parameter DEPTH = 3
`define VEC_DEPTH_SIZE (1 << DEPTH)
`define VEC_PRPG_DEPTH_PARAMS `FLOAT_PRPG_BIAS_PARAMS, .DEPTH(DEPTH)
`define VEC_WIDTH(size) ((size) * `FLOAT_WIDTH)
`define VEC_BEGIN(idx) ((idx) * `FLOAT_WIDTH)
`define VEC_SELECT(idx) `VEC_BEGIN(idx) +: `FLOAT_WIDTH

`endif