// Copyright (c) 2021 Chanjung Kim (paxbun). All rights reserved.
// Licensed under the MIT License.

`ifndef MAT_MACROS_VH
`define MAT_MACROS_VH

`include "../inc/vec_macros.vh"

`define MAT_WIDTH(height, width) ((height) * (width) * `FLOAT_WIDTH) 
`define MAT_BEGIN(i, j, width) (((i) * (width) + (j)) * `FLOAT_WIDTH)
`define MAT_SELECT(i, j, width) `MAT_BEGIN(i, j, width) +: `FLOAT_WIDTH

`endif