## data-raw/datatypes/geometry.R
## Positive examples for the STRUCTURED geometry family: WKT literals across the
## common OGC geometry types, with spaced/unspaced openings, a Z dimensionality
## tag, a collection, and an EMPTY geometry.

wkt_geometry <- c(
  "POINT (30 10)",
  "POINT(30 10)",
  "LINESTRING (30 10, 10 30, 40 40)",
  "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))",
  "MULTIPOINT ((10 40), (40 30), (20 20), (30 10))",
  "MULTILINESTRING ((10 10, 20 20), (40 40, 30 30))",
  "MULTIPOLYGON (((30 20, 45 40, 10 40, 30 20)))",
  "POINT Z (30 10 5)",
  "GEOMETRYCOLLECTION (POINT (4 6), LINESTRING (4 6, 7 10))",
  "POINT EMPTY"
)

## GeoJSON geometries, features, and collections
geojson <- c(
  '{"type":"Point","coordinates":[30,10]}',
  '{"type":"LineString","coordinates":[[30,10],[10,30],[40,40]]}',
  '{"type":"Polygon","coordinates":[[[30,10],[40,40],[20,40],[10,20],[30,10]]]}',
  '{"type":"MultiPoint","coordinates":[[10,40],[40,30],[20,20]]}',
  '{"type":"MultiPolygon","coordinates":[[[[30,20],[45,40],[10,40],[30,20]]]]}',
  '{"type":"Feature","geometry":{"type":"Point","coordinates":[125.6,10.1]},"properties":{"name":"x"}}',
  '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[0,0]},"properties":{}}]}',
  '{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[0,0]}]}'
)

## WKB / EWKB (hex): LE/BE 2D points, a linestring, and an EWKB point with SRID
wkb <- c(
  "0101000000000000000000f03f000000000000f03f",
  "00000000013ff00000000000003ff0000000000000",
  "010200000002000000000000000000000000000000000000000000000000000000000000000000f03f000000000000f03f",
  "0103000000000000000000000000000000000000000000000000000000000000000000000000f03f",
  "0101000020e6100000000000000000f03f000000000000f03f"
)
