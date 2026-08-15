## data-raw/datatypes/serialized.R
## Positive examples for the SERIALIZED-text family: JSON objects and arrays as
## they appear packed into a single column. Kept non-spatial so they do not
## overlap the geometry family's GeoJSON examples (GeoJSON is also valid JSON,
## but the specific is_geojson() detector claims those).

json <- c(
  '{"a":1,"b":2}',
  '{"name":"Ada","age":36}',
  '{"id":1,"tags":["x","y","z"]}',
  '{"nested":{"k":"v"},"ok":true}',
  '{"lat":40.7,"lng":-74.0,"label":"nyc"}',
  '[1,2,3,4,5]',
  '["a","b","c"]',
  '[{"k":1},{"k":2}]'
)
