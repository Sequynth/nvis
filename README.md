# nVis

nvis is a matrix viewer for matrices of any size. Its aimed towards MATLAB users that need to asses a lot of higher-dimensional data in their daily workflow. A 2-dimensional slice of the matrix is shown, and higher 

## Design Goals

**Multidimensional**: Visualization should work with matrices independent of their dimensionality. While the display is limited to two dimensions at a time, selecting datasets along the remaining dimensions (e.g. echo, channel, time) should be quick and intuitive. Many available tools are limited to three-dimensional matrices.

**Versatile**: For the development of sequences and especially image reconstruction routines, visual feedback and the ability to quickly assess images, k-spaces, raw-data, sensitivity maps or filters are key. Complex values must be supported, as well as data type such as int or bool; the content of an matrix should not be relevant.

**Dynamic**: Dynamic data is best visualized in motion, while still allowing for easy comparison along different dimensions (e.g. channels).

**Comparative**: Overlaying two images is a simple and intuitive way of comparing two reconstructions form the same data, prediction and ground truth, or the alignment of a ROI to the image.

**Interactive**: Windowing allows for intuitive selection of image contrast in image space as well as k-space. Images with the current contrast can be saved from the GUI or using only command line arguments. This is also true for saving videos or animations.

**Quantitative**: We don’t need the next fully featured image analysis tool, but extracting pixel values and drawing signal and noise ROIs should be supported.

**Lightweight**: matrices containing medical images can require a lot of memory, especially when 3D, multi-channel or functional information are included. The requirements increase further, when data is stored as high-precision complex values. Thus, no additional memory should be required when visualizing the data.

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

`nvis(rand(100, 100, 10), 'dimLabel', {'dx', 'dy', 'time'}`

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
