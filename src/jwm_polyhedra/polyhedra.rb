# Copyright 2014 Trimble Navigation Ltd. and John W. McClenahan
# A plugin to draw regular polyhedra
# License: The MIT License (MIT)
# A plugin to draw parametric regular polyhedra, centred on the origin, of a user-specified radius

# v1.0. Draws all Platonic solids. Parts of the code adapted from Parametric3D Shapes plugin

## Note - it would be nice later to offer the choice of specifying edge length or radius for size.

# Load other required files
require "sketchup.rb"
require File.join(File.dirname(__FILE__), 'parametric.rb')
require File.join(File.dirname(__FILE__), 'mesh_additions.rb')

module CommunityExtensions::Polyhedra
PLUGIN = self # Allows self reference later when calling function in module
### Constants used in construction
#============================================================================
## Tetrahedron
#-------------
# Define constant asin(0.333333) 
#  - angle between radius of solid and radius of base
ASIN_0333 = Math.asin(0.333333333333) # (in radians) = 19.471220614233577 degrees

# Define constant cos((asin(0.333333)) - angle between radius of base and edge of base
COS_ASIN_0333 = Math.cos(ASIN_0333)
#p "Cos(asin(0.3333333)) = " + COS_ASIN_0333.to_s
#p  "asin(0.3333) = " + ASIN_0333.to_s
#============================================================================
## Cube
#------
# Define constant sqrt(3)
SQRT3 = Math.sqrt(3)

## Dodecahedron and Icosahedron
#------------------------------
# Define constant PHI as the Golden Ratio (used in constructing Dodecahedron and Icosahedron)
PHI = (1.0 + Math.sqrt(5.0))/2 # = 1.618033988749895 approx

# Define constants as the lengths of sides of a Golden Section rectangle which fits inside an Icosahedron
#  with circumsphere radius = 1.0 unit
SHORT_SIDE = 0.52573125081 # Mathematical definitions to replace this in due course
LONG_SIDE = 0.85065072264

# Pre-define constant sqrt(2) to save calculation time
SQRT2 = Math.sqrt(2.0)

# Define constants as the lengths of sides of a Golden Section rectangle which defines 
#   location of points of Dodadecahedron of unit radius r (derived from accurate scale drawing:
#   mathematical derivation to replace this in due course. See diagram for definition of a, b, and c)
DDH_A = 0.607061998207
DDH_B = 0.982246946377
DDH_C = 0.794654472292

#=============================================================================
# Find which unit and format the model is using and define unit_length
#   accordingly
#   When LengthUnit = 0
#     LengthFormat 0 = Decimal inches
#     LengthFormat 1 = Architectural (feet and inches)
#     LengthFormat 2 = Engineering (feet)
#     LengthFormat 3 = Fractional (inches)
#   When LengthUnit = 1
#     LengthFormat 0 = Decimal feet
#   When LengthUnit = 2
#     LengthFormat 0 = Decimal mm
#   When LengthUnit = 3
#     LengthFormat 0 = Decimal cm
#   When LengthUnit = 4
#     LengthFormat 0 = Decimal metres

def self.unit_length
  # Get model units (imperial or metric) and length format.
  model = Sketchup.active_model
  manager = model.options
  if provider = manager["UnitsOptions"] # Check for nil value
    length_unit = provider["LengthUnit"] # Length unit value
    length_format = provider["LengthFormat"] # Length format value

    case length_unit
    when 0 ## Imperial units
      if length_format == 1 || length_format == 2
      # model is using Architectural (feet and inches)
      # or Engineering units (feet)
      unit_length = 1.feet
      else
      ## model is using (decimal or fractional) inches
      unit_length = 1.inch
      end # if
    when 1
      ## Decimal feet
      unit_length = 1.feet
    when 2
      ## model is using metric units - millimetres
      unit_length = 10.mm
    when 3
      ## model is using metric units - centimetres
      unit_length = 10.cm
    when 4
      ## model is using metric units - metres
      unit_length =  1.m
    end #end case

  else
    UI.messagebox " Can't determine model units - please set in Window/ModelInfo"
  end # if
end

#=============================================================================

class Tetrahedron < Parametric
# Note: from Wikipedia, radius of circumsphere is sqrt(3/8)*edge_length
# Wikipedia gives coordinates of corners (±1, 0, -1/sqrt(2)), (±1, 0, -1/sqrt(2)) for 
#   tetrahedron centred on the origin with edge_length = 2. This is WRONG. The centre is not
#   midway up between base and apex
# I've redrawn tetrahedron in a circumsphere centred at ORIGIN with unit radius (see diagrams in separate PDF)
# Height from centroid of base triangle to apex is 1.333333 * radius
# From ORIGIN to apex is just the radius
# From centroid of base to ORIGIN is 0.333333 * radius
# Side of triangular face is 2 * (sqrt(1-(1/3)**2) * cos(30 degrees) = 1.632993161856

def create_entities(data, container)

  # Set sizes to draw
  radius = data["radius"].to_l  # Radius

  # Remember values for next use
  @@dimension1 = radius

  # Draw base and define apex point
  base_down_by = -radius/3.0
  triangle = container.add_ngon [0,0, base_down_by], Z_AXIS, radius * COS_ASIN_0333, 3
  # Reverse to get front face outside
  triangle.reverse!
  base = container.add_face triangle
  base_edges = base.edges

  # Create the sides
  apex = [0,0,radius]
  edge1 = nil
  edge2 = nil

  for i in 0..2
    edge = base_edges[i] 
    tetrahedron = container.add_face edge.start.position, edge.end.position, apex
    container.each do |entity|
      if entity.is_a? Sketchup::Face
        entity.reverse!
      end #if
    end #do
  end #for
end

def default_parameters
  # Set starting defaults to one unit_length
  @@unit_length = PLUGIN.unit_length

  # Set other starting defaults if not set
  if !defined? @@dimension1  # then no previous values input
    defaults = { "radius" => @@unit_length }
  else
  # Reuse last inputs as defaults
    defaults = { "radius" => @@dimension1 }
  end # if

  # Return values
  defaults
end

def translate_key(key)
  prompt = key

  case key
  when "radius"
    prompt = "Radius "
  end

  # Return value
  prompt
end

def validate_parameters(data)
  ok = true

  # Return value
  ok
end

end # Class Tetrahedron

#=============================================================================

class Cube < Parametric
# A cube of side s has radius of circumsphere r = s*sqrt(3)/2

# So a cube of radius r has a side of 2*r/sqrt(3), and half the diagonal of the cube's 
#   base is (r/sqrt(3))*sqrt(2)

def create_entities(data, container)

  # Set sizes to draw
  radius = data["radius"].to_l  # Radius

  # Remember values for next use
  @@dimension1 = radius

  # Draw base, reverse it to have it facing outwards, and pushpull it to height
  base_down_by = -radius/SQRT3
  square = container.add_ngon [0,0, base_down_by], Z_AXIS, (radius/SQRT3)*SQRT2, 4
  # Reverse to get front face outside
  square.reverse!
  base = container.add_face square
  base.pushpull 2.0*radius/SQRT3  
  
end

def default_parameters
  # Set starting defaults to one unit_length
  @@unit_length = PLUGIN.unit_length

  # Set other starting defaults if not set
  if !defined? @@dimension1  # then no previous values input
    defaults = { "radius" => @@unit_length }
  else
  # Reuse last inputs as defaults
    defaults = { "radius" => @@dimension1 }
  end # if

  # Return values
  defaults
end

def translate_key(key)
  prompt = key

  case key
  when "radius"
    prompt = "Radius "
  end

  # Return value
  prompt
end

def validate_parameters(data)
  ok = true

  # Return value
  ok
end

end # Class Cube

#=============================================================================

class Octahedron < Parametric

def create_entities(data, container)
  # Octahedron has square centre of the same half-diagonal as the radius of its circumsphere

  # Set sizes to draw
  radius = data["radius"].to_l  # Radius

  # Remember values for next use
  @@dimension1 = radius

  # Draw base and define apex points
  square = container.add_ngon [0,0, 0], Z_AXIS, radius , 4
  top_apex = [0,0,radius]
  bottom_apex = [0,0,-radius]
  
  # Create the faces
  edge1 = nil
  edge2 = nil

  for i in 0..3
    edge = square[i] 
    container.add_face edge.start.position, edge.end.position, top_apex # top half  
    container.add_face edge.start.position, edge.end.position, bottom_apex # bottom_half
    container.each do |entity|
      if entity.is_a? Sketchup::Face
        entity.reverse!
      end #if
    end #do
  end #for
end

def default_parameters
  # Set starting defaults to one unit_length
  @@unit_length = PLUGIN.unit_length

  # Set other starting defaults if not set
  if !defined? @@dimension1  # then no previous values input
    defaults = { "radius" => @@unit_length }
  else
  # Reuse last inputs as defaults
    defaults = { "radius" => @@dimension1 }
  end # if

  # Return values
  defaults
end

def translate_key(key)
  prompt = key

  case key
  when "radius"
    prompt = "Radius "
  end

  # Return value
  prompt
end

def validate_parameters(data)
  ok = true

  # Return value
  ok
end

end # Class Octahedron
#======================================================
class Dodecahedron < Parametric
  
def create_entities(data, container)
  # Set sizes to draw
  radius = data["radius"].to_l  # Radius
  
  # Remember values for next use
  @@dimension1 = radius

  # Golden rectangle locating points on Dodecahedron with unit radius has 
  #   sides of length DDH_LONG_SIDE, DDH_SHORT_SIDE, defined in module initialization above
  
  # Scale size by radius
  short_side = radius*DDH_A # of golden rectangle
  long_side = radius*DDH_B # of golden rectangle
  half_height = radius*DDH_C # of dodecahedron = (DDH_A + DDH_B)/2
  delta = half_height - short_side
  
  # Create an empty mesh
  numpoly = 12 # faces
  numpts = 20 # vertices
  mesh = Geom::PolygonMesh.new(numpts, numpoly)
  
  # Define rotations of 36 and 72 degrees about Z_AXIS
  rotate_minus36 = Geom::Transformation.rotation ORIGIN, Z_AXIS, -36.degrees
  rotate36 = Geom::Transformation.rotation ORIGIN, Z_AXIS, 36.degrees
  rotate72 = Geom::Transformation.rotation ORIGIN, Z_AXIS, 72.degrees
  
  # Define four arrays for base, lower shoulder, upper shoulder and top points
  # We'll later make the sixth point the same as the first to allow iterations to 'wrap around'
  points_base = [6]
  points_lower = [6]
  points_upper = [6]
  points_top = [6]
  
  # Define points as starting vertices of Dodecahedron at each level
  points_base[0] = Geom::Point3d.new(short_side, 0, -half_height) # first base level point{
  points_lower[0] = Geom::Point3d.new(long_side,0, -delta) # first lower 'shoulder' level point
  points_upper[0] = Geom::Point3d.new(long_side,0,delta).transform rotate_minus36 # first upper 'shoulder' level point
  points_top[0] = Geom::Point3d.new(short_side, 0, half_height).transform rotate_minus36 # first top point
  
  # First point in each 'row' is already drawn (i=0): 
  #  just fill in the gaps and add an extra one on top of the first point
  for i in 1..5 
    # base points
    points_base[i] = Geom::Point3d.new(points_base[i-1]).transform rotate72
    # lower 'shoulder' points
    points_lower[i] = Geom::Point3d.new(points_lower[i-1]).transform rotate72
    # upper 'shoulder' points
    points_upper[i] = Geom::Point3d.new(points_upper[i-1]).transform rotate72
    # top points
    points_top[i] = Geom::Point3d.new(points_top[i-1]).transform rotate72
  end

=begin
  # Add base points to container (for initial testing)
  points_base.each do |point|
    if point
      container.add_cpoint point
    end
 # p "Point added " + point.inspect
  end
  points_lower.each do |point|
    if point
      container.add_cpoint point
    end
 # p "Point added " + point.inspect
  end
  points_upper.each do |point|
    if point
      container.add_cpoint point
    end
 # p "Point added " + point.inspect
  end
  points_top.each do |point|
    if point
      container.add_cpoint point
    end
 # p "Point added " + point.inspect
  end
=end

# Create successive faces
  # Base - draw clockwise to face outside down
    mesh.add_polygon points_base[0], points_base[4], points_base[3], points_base[2], points_base[1]

  # First row of surrounding faces
  for i in 0..4
    mesh.add_polygon points_base[i], points_base[i+1], points_lower[i+1], points_upper[i+1], points_lower[i]
  end
    
  # Upper row of surrounding faces
  for i in 0..4
    mesh.add_polygon points_lower[i], points_upper[i+1], points_top[i+1], points_top[i], points_upper[i]
  end

  # Top - draw counter-clockwise to face outside up
  mesh.add_polygon points_top[0], points_top[1], points_top[2], points_top[3], points_top[4]
   
  # Create faces from the mesh
  container.add_faces_from_mesh(mesh, 0) # smooth constant = 0 for no smoothing

end

def default_parameters
  # Set starting defaults to one unit_length
  @@unit_length = PLUGIN.unit_length

  # Set starting defaults if none set
  if !defined? @@dimension1  # then no previous values input
    defaults = { "radius" => @@unit_length }
  else
  # Reuse last inputs as defaults
    defaults = { "radius" => @@dimension1 }
  end # if

  # Return values
  defaults
end

def translate_key(key)
  prompt = key

  case key
  when "radius"
    prompt = "Radius "
  end

  # Return value
  prompt
end

def validate_parameters(data)
  ok = true

  # Return value
  ok
end

end # Class Dodecahedron

#======================================================
class Icosahedron < Parametric
  
def create_entities(data, container)
  # Set sizes to draw
  radius = data["radius"].to_l  # Radius
  
  # Remember values for next use
  @@dimension1 = radius

  # Golden rectangle fitting inside Icosahedron with unit radius has 
  #   sides of length LONG_SIDE, SHORT_SIDE, defined in module initialization above
  
  # Scale size by radius
  long_side = radius*LONG_SIDE 
  short_side = radius*SHORT_SIDE

  # Create an empty mesh
  numpoly = 20 # faces
  numpts = 12 # vertices
  mesh = Geom::PolygonMesh.new(numpts, numpoly)
  
  # Define points as vertices of Icosahedron
  # (I'm sure there's a way to iterate through this, but I haven't worked it out yet)
  points = []
  points[0] = Geom::Point3d.new([long_side,-short_side,0])
  points[1] = Geom::Point3d.new([short_side,0,long_side])
  points[2] = Geom::Point3d.new([long_side,short_side,0]) 
  points[3] = Geom::Point3d.new([0,long_side,short_side])
  points[4] = Geom::Point3d.new([-long_side,short_side,0])
  points[5] = Geom::Point3d.new([-short_side,0,long_side])
  points[6] = Geom::Point3d.new([-long_side,-short_side,0])
  points[7] = Geom::Point3d.new([0,-long_side,short_side])
  points[8] = Geom::Point3d.new([short_side,0,-long_side])
  points[9] = Geom::Point3d.new([0,long_side,-short_side])
  points[10] = Geom::Point3d.new([-short_side,0,-long_side])
  points[11] = Geom::Point3d.new([0,-long_side,-short_side])

  # Add faces from points
  mesh.add_polygon points[0], points[2], points[1]
  mesh.add_polygon points[2], points[3], points[1]
  mesh.add_polygon points[3], points[5], points[1]
  mesh.add_polygon points[3], points[4], points[5]
  mesh.add_polygon points[4], points[6], points[5]
  mesh.add_polygon points[6], points[7], points[5]
  mesh.add_polygon points[7], points[1], points[5]
  mesh.add_polygon points[7], points[0], points[1]
  mesh.add_polygon points[0], points[8], points[2]
  mesh.add_polygon points[2], points[8], points[9]
  mesh.add_polygon points[2], points[9], points[3]
  mesh.add_polygon points[3], points[9], points[4]
  mesh.add_polygon points[9], points[10], points[4]
  mesh.add_polygon points[4], points[10], points[6]
  mesh.add_polygon points[9], points[8], points[10]
  mesh.add_polygon points[6], points[10], points[11]
  mesh.add_polygon points[6], points[11], points[7]
  mesh.add_polygon points[7], points[11], points[0]
  mesh.add_polygon points[11], points[10], points[8]
  mesh.add_polygon points[11], points[8], points[0]
  mesh.add_polygon points[0], points[8], points[2]  

  # Create faces from the mesh
  container.add_faces_from_mesh(mesh, 0) # smooth constant = 0 for no smoothing

end

def default_parameters
  # Set starting defaults to one unit_length

  @@unit_length = PLUGIN.unit_length

  # Set starting defaults if none set
  if !defined? @@dimension1  # then no previous values input
    defaults = { "radius" => @@unit_length }
  else
  # Reuse last inputs as defaults
    defaults = { "radius" => @@dimension1 }
  end # if

  # Return values
  defaults
end

def translate_key(key)
  prompt = key

  case key
  when "radius"
    prompt = "Radius "
  end

  # Return value
  prompt
end

def validate_parameters(data)
  ok = true

  # Return value
  ok
end

end # Class Icosahedron

#=============================================================================

# Add a menu for creating polyhedra
# Checks if this script file has been loaded before in this SU session
unless file_loaded?(__FILE__) # If not, create menu entries
  add_separator_to_menu("Draw")
  shapes_menu = UI.menu("Draw").add_submenu("Polyhedra")
  shapes_menu.add_item("Tetrahedron") { Tetrahedron.new }
  shapes_menu.add_item("Cube") { Cube.new }
  shapes_menu.add_item("Octahedron") { Octahedron.new }
  shapes_menu.add_item("Dodecahedron") { Dodecahedron.new }
  shapes_menu.add_item("Icosahedron") { Icosahedron.new }
  file_loaded(__FILE__)
end

end # module CommunityExtensions::Polyhedra
