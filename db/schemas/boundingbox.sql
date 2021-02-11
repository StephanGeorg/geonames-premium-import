CREATE TABLE ${TABLE_PREFIX}boundingbox (
    geoname_id      INT,
    bboxwest        FLOAT,
    bboxsouth       FLOAT,
    bboxeast        FLOAT,
    bboxnorth       FLOAT,
    way             geometry(Geometry,4326)
);

-- geoNameId	bBoxWest	bBoxSouth	bBoxEast	bBoxNorth

-- geoname_id,bboxwes,bboxsouth,bboxeast,bboxnorth

