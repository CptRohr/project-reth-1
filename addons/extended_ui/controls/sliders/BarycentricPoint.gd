## Extended UI: Barycentric Point Resource
## Copyright (c) 2026 - ThowsenMedia
## thowsenmedia.itch.io
##
## Defines a single factor/vertex in a barycentric coordinate system.
## Used by XUIBarycentricSlider to represent blend factors (e.g., "Skinny", "Muscular", "Fat").
@tool class_name BarycentricPoint extends Resource

## The name/label for this factor
@export var point_name: String = "Factor"
