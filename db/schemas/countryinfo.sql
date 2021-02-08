CREATE TABLE countryinfo (
    iso_alpha2           character varying(2) COLLATE pg_catalog."default" NOT NULL,
    iso_alpha3           character varying(3) COLLATE pg_catalog."default" NOT NULL,
    iso_numeric          INTEGER,
    fips_code            character varying(2) COLLATE pg_catalog."default" NOT NULL,
    country              TEXT,
    capital              TEXT,
    area                 DOUBLE PRECISION, -- square km
    "population"         INTEGER,
    continent            character varying(2) COLLATE pg_catalog."default" NOT NULL,
    tld                  TEXT,
    currency_code        character varying(3) COLLATE pg_catalog."default" NOT NULL,
    currency_name        TEXT,
    phone                TEXT,
    postal               TEXT,
    postal_regex         TEXT,
    languages            TEXT,
    languages_array      text[] COLLATE pg_catalog."default",
    geoname_id           INT,
    neighbours           TEXT,
    neighbours_array     text[] COLLATE pg_catalog."default",
    equivalent_fips_code TEXT
);