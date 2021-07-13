# Arbitrary precision floating-point matrix multiplication implementation

## Project structure

* `src/`: Contains module implementations and headers.
  - `float.v` & `float_macros.vh`: Implmements the floating-point addition and the multiplication.
  - `vec.v` & `vec_macros.vh`: Implements the vector addition and the dot product.
  - `mat.v` & `mat_macros.vh`: Implements the matrix multiplication.
* `tb/`: Contains testbenches.

## Common module parameters (See `*_macros.vh`)

* `EXP_WIDTH`: Number of exponent bits
* `MAN_WIDTH`: Number of mantissa bits
* `BIAS`: The bias of the exponent (e.g. -127 in IEEE 754 FP32 format, -1023 in IEEE 754 FP64 format)
* `VEC_SIZE`: Number of elements in the vector

## Macros (See `*_macros.vh`)

* `FLOAT_WIDTH`: Total number of bits to represent one single floating-point number
* `VEC_WIDTH(size)`: Total number of bits to represent one single vector with the size `size`
* `VEC_SELECT(idx)`: The bit range assigned to the element with the given index `idx`
* `MAT_WIDTH(height, width)`: Total number of bits to represent one single matrix with `height` rows and `width` columns
* `MAT_SELECT(i, j)`: The bit range assigned to the element `M_ij`