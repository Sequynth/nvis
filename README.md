# nVis

nvis is a matrix viewer for matrices of any size. Its aimed towards MATLAB users that need to asses a lot of higher-dimensional data in their daily workflow.

## Features

**Multidimensional**: Visualization works for matrices independent of their dimensionality. While the display is limited to two dimensions at a time, selecting datasets along the remaining dimensions is done via sliders.

**Versatile**: Supports complex valued data, all numeric datatypes and gpuArrays.

**Dynamic**: nvis allows navigating through the matrix data, while one dimension is contiuously looped.

**Comparative**: Two input matrices can be displayed simultaneously.

**Interactive**: Colormap limits (windowing) can be adjusted by moving the mouse (windowing).

**Quantitative**: Two regions of interest (ROIs) can be drawn. One for signal (mean value is calculated) and one for noise (standard deviation is calculated).

**Lightweight**: nvis does not create a memory copy of the inputs in order to reduce RAM load incase of large matrices.

## Examples

nvis can be called with one

`nvis(A)`

or two input matrices

`nvis(A, B)`

B must have the same size as A. Except: A and B can differ in size along one or more dimensions, as long as either A or B are singleton. E.g.

`nvis(rand(100, 100, 10, 1), rand(100, 100, 1, 5))`

For dimensions where all input matrices are singleton, no slider is shown.

The limits of the colormap can be changed with `center` and `width` values. These can also be varied interactively by pressing middle or right mouse button on the canvas and dragging the mouse.

Matrix dimensions can be labelled:

`nvis(rand(100, 100, 10), 'dimLabel', {'dx', 'dy', 'time'})`

Values along each dimension can be labelled with any string. When providing an empty matrix `[]`, the values are enumerated, e.g. `1:size(..., 1)`.

`nvis(rand(100, 100, 10), 'dimVal', {[],[], 0.1*(1:10)})`

For complex data, either the absolute value, phase, real- or imaginary part can be displayed. It is also possible to show the 2D Fourier transform of the currently selected slice.

The shown image/animation can also be saved to file. Either from the GUI, or - without opening the GUI -- from the command line.

`nvis(imageMat,'CW',[0.5,1],'Colormap','parula','SaveImage','image.png')`
`nvis(imageMat,'CW',[0.5,1],'Colormap',parula(32),'fps',60,'SaveVideo','animation.gif')`

By default, the matrix is displayed as a square. To set the aspect ratio according to the matrix size, use

`nvis(A, 'aspectRatio', 'image')`

More instructions are documented under

`help nvis`
