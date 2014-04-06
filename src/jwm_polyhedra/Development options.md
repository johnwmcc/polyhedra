#Thoughts on merging pick point and polyhedra, to be able to draw polyhedron at picked origin point.

## Observations
I can rather crudely insert a call to draw a polyhedron into the PickPoint tool
and move it to the picked origin point recorded as a global variable after pick or VCB selection of origin point.
    
    # Set transformation to move shape to picked origin point
    #p "Origin point picked = " +$origin_point.inspect
    vector = Geom::Vector3d.new $origin_point[0], $origin_point[1], $origin_point[2]
    p "vector = " + vector.inspect
    move_to_picked_origin = Geom::Transformation.translation vector   
     
    # Translate to new $origin_point
    mesh.transform! move_to_picked_origin
    # Create faces from the mesh
    container.add_faces_from_mesh(mesh, 0) # smooth constant = 0 for no smoothing


The translation *transform* only works on Point3d, Vector3d or Array objects, not on a container of faces and edges, nor on individual edges or faces.

But the 'immediate action' *transform!* also works on PolygonMesh, so can work for Dodecahedron and Icosahedron as they are.

*transform* also works on a Group. If I could get parametric.rb to create and return the name of the drawn group, I could use just one occurrence of the translation code to do the move.

## Other possible approaches
1. Adapt the code, and do the transformation on the elements (e.g, before drawing the base polygon, and /or other vertices) of simpler polyhedra, before drawing them.

2. I could respecify how Tetrahedron, Cube and Octahedron are drawn, to convert them to polygon meshes, before applying the same transformation.

That would work, but still a bit crude as I have to duplicate the translation for each shape.

3. I could try to generalise the PickPoint tool to be callable from within Polyhedra, rather than the other way round. I could perhaps create a new pickpoint tool that somehow returns the value of the picked point. That would be more generally useful anyway. It would make it easier to change the cursor to match the desired shape or polyhedron to be drawn.

4.
