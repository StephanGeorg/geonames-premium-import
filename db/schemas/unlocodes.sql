CREATE TABLE ${TABLE_PREFIX}unlocodes (
    country_code    character varying(2) COLLATE pg_catalog."default" NOT NULL,
    locode          character varying(3) COLLATE pg_catalog."default" NOT NULL,
    "name"          TEXT,
    geoname_id      INT
);

-- countryCode	code	name	geoNameId

-- country_code,locode,\"name\",geoname_id

