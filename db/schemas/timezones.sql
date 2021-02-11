CREATE TABLE ${TABLE_PREFIX}timezones (
  id            TEXT,
  country_code  character varying(2) COLLATE pg_catalog."default" NOT NULL,
  GMT_offset    NUMERIC(3,1),
  DST_offset    NUMERIC(3,1),
  raw_offset    NUMERIC(3,1)
);