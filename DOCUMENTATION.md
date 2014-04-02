#Plugin to draw regular polyhedra
## Introduction
Initially, the plugin will draw just the five Platonic solids:
- Tetrahedron
- Octahedron
- Cube
- Dodecahedron
- Icosahedron.

## Usage
Install the plugin in the usual way (see notes at [reference needed].

You should now find an extra item in the Draw menu, Polyhedra with a submenu for each shape as listed above.

After clicking on the selected shape, you will be prompted whether to specify the size by the length of one side of the shape, or by its radius (the radius of a circumscribed sphere).

A second prompt will ask for the size, either Side or Radius as previously set.

## Calculations
I tried first to calculate the location of polhedron vertices algebraically, and was able to do so easily for several of them (see code and comments in polyhedra.rb). 

But some of the fomulae given in Wikipedia (e.g., for the location of the vertices of a Tetrahedon centred on the origin) are just wrong, and others were not helpful in locating the centres of other polyhedra.

So I resorted to construction in Sketchup, at a very large scale (unit radius of 1,000,000 inches, with model info set to display five figures after the decimal point), used the Tape Measure tool to scale the model to an exact size of either radius or edge, and used the Dimension tool to measure key dimensions.

Details of how to construct Dodecahedron and Icosahedron, using rectangles with sides in the Golden Ratio, were very helpful [references to go here].





