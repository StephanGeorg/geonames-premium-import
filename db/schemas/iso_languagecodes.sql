CREATE TABLE iso_languagecodes(
  iso_639_3     character varying(4) COLLATE pg_catalog."default" NOT NULL,
  iso_639_2     TEXT,
  iso_639_1     character varying(2) COLLATE pg_catalog."default",
  language_name TEXT
);