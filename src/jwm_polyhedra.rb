# Copyright 2014 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that creates regular polyhedron objects.  More info at
# https://github.com/johnmcc/my-polyhedra


require "sketchup.rb"
require "extensions.rb"

module CommunityExtensions
  module Polyhedra

    # Create the extension.
    loader = File.join(File.dirname(__FILE__), "jwm_polyhedra", "polyhedra.rb")
    extension = SketchupExtension.new("Polyhedra Tool", loader)
    extension.description = "Regular Polyhedra sample script from SketchUp.com"
    extension.version     = "0.1"
    extension.creator     = "SketchUp"
    extension.copyright   = "2014, Trimble Navigation Limited and " <<
                            "John W McClenahan"

    # Register the extension with so it show up in the Preference panel.
    Sketchup.register_extension(extension, true)

  end # module Polyhedra
end # module CommunityExtensions
