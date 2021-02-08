CREATE TABLE postalcodes (
  country_code character varying(2) COLLATE pg_catalog."default" NOT NULL,
  postal_code  TEXT,
  place_name   TEXT,
  admin1_name  TEXT,
  admin1_code  TEXT,
  admin2_name  TEXT,
  admin2_code  TEXT,
  admin3_name  TEXT,
  admin3_code  TEXT,
  latitude     FLOAT,
  longitude    FLOAT,
  accuracy     SMALLINT,
  center       geometry(Geometry,4326)
);