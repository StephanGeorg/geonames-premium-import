CREATE TABLE airports (
    iata            character varying(3) COLLATE pg_catalog."default",
    icao            character varying(4) COLLATE pg_catalog."default",
    "name"          TEXT,
    fcode           character varying(10) COLLATE pg_catalog."default",
    admin1_code     TEXT,
    admin2_code     TEXT,
    timezone        TEXT,
    latitude        FLOAT,
    longitude       FLOAT,
    unlocode        character varying(3) COLLATE pg_catalog."default",
    geoname_id      INT,
    city_id	        INT,
    city_name	    TEXT,
    country_code    character varying(3) COLLATE pg_catalog."default",
    active          BOOLEAN
);

-- geoNameId	name	featureCode	countryCode	adminCode1	adminCode2	timeZoneId	latitude	longitude	iata	icao	unlocode	cityId	cityName	isActive

-- geoname_id,"name",fcode,country_code,admin1_code,admin2_code,timezone,latitude,longitude,iata,icao,unlocode,city_id,city_name,active

