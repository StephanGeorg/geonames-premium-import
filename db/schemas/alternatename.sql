CREATE TABLE ${TABLE_PREFIX}alternatename (
    id                INT,
    geoname_id        INT,
    iso_lang          TEXT,
    alternate_name    TEXT,
    is_preferred_name BOOLEAN,
    is_short_name     BOOLEAN,
    is_colloquial     BOOLEAN,
    is_historic       BOOLEAN,
    "from"            TEXT,
    "to"              TEXT
);