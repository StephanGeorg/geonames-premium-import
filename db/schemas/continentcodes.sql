CREATE TABLE ${TABLE_PREFIX}continentcodes (
  code        character varying(2) COLLATE pg_catalog."default" NOT NULL,
  "name"      TEXT,
  geoname_id  INT
);