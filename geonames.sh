#!/bin/bash

# Globals
PWD="$(pwd)"
WORKPATH=$PWD
TMPPATH="$WORKPATH/tmp"

# Geonames config
# GEONAMES_USERNAME=""
# GEONAMES_PASSWORD=""
GEONAMES_SERVER="https://www.geonames.org"
GEONAMES_COOKIE="geonames_cookie.txt"
GEONAMES_OUTDIR="$WORKPATH/data/geonames"
GEONAMES_FILES=(airports.zip allCountries.zip alternateNamesV2.zip boundingbox.zip userTags.zip admin1CodesASCII.txt admin2Codes.txt countryInfo.txt featureCodes_en.txt iso-languagecodes.txt timeZones.txt unlocode-geonameid.zip)
#GEONAMES_RELEASE=$(date +'%Y%m')
GEONAMES_RELEASE="202102"

# DB config
DBHOST="localhost"
DBPORT="5432"
DBUSER="stephan"
DBPASSWORD=""
DATABASE="geonames"
TABLE_PREFIX="geonames_"
SCHEMA="public"
DROP_TABLES="true"
CREATE_TABLES="true"

# Export DB credentials
export PGOPTIONS="--search_path=${SCHEMA}"
export PGPASSWORD=$DBPASSWORD

# Authenticate and download files
function download () {
  # Get Session Cookie
  wget --save-cookies "$TMPPATH/$GEONAMES_COOKIE" --quiet \
    --keep-session-cookies \
    --post-data 'username='$GEONAMES_USERNAME'&password='$GEONAMES_PASSWORD'&rememberme=1&srv=12' \
    --delete-after \
    "$GEONAMES_SERVER/servlet/geonames?"

  # Download file
  wget --load-cookies "$TMPPATH/$GEONAMES_COOKIE" --quiet --show-progress \
    $1 --directory-prefix="$GEONAMES_OUTDIR/$GEONAMES_RELEASE/"
  
  # Check download success
  if [[ "$?" != 0 ]]; then
    echo "Error: Could not download file"
    exit 1
  fi
}

# Prepare downloaded files
function prepare () {
  cd $GEONAMES_OUTDIR/$GEONAMES_RELEASE 
  if [[ $1 == *.zip ]]
  then
    unzip -u -o -q "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/$1"
    rm "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/$1"
  fi
  # Some of Geonames files need further preperation  
  case "$1" in
    #iso-languagecodes.txt)
    #  mv "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt" "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt.original"
    #  tail -n +2 "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt.original" > "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt";
    #  rm "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt.original"
    #  ;;
    countryInfo.txt)
      mv "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt" "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt.original";
      grep -v '^#' "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt.original" > "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt";
      rm "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt.original"
      ;;
    #timeZones.txt)
    #  mv "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt" "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt.original";
    #  tail -n +2 "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt.original" > "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt";
    #  rm "$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt.original"
    #  ;;
  esac
  cd $WORKPATH
  echo "| $1 has been downloaded";
}

# Download and prepare all premium und public files
function getFiles() {
  for GEONAMESFILE in "${GEONAMES_FILES[@]}"; do
    FILEPATH="$PWD/data/geonames/premium/$GEONAMES_RELEASE/$GEONAMESFILE"
    echo $GEONAMESFILE
    echo $FILEPATH
    # Check extracted file 
    if test -f "$FILEPATH"; then
      echo "Found downloaded file FILEPATH"
      # Check if already prepared
    else
      GEONAMES_FILEURL="$GEONAMES_SERVER/premiumdata/$GEONAMES_RELEASE/$GEONAMESFILE"
      download $GEONAMES_FILEURL
      prepare $GEONAMESFILE
    fi
  done

  # Download public post codes file
  cd $GEONAMES_OUTDIR/$GEONAMES_RELEASE 
  mkdir -p postcodes
  cd postcodes
  wget -N -q "https://download.geonames.org/export/zip/allCountries.zip" -O "postCodes.zip"
  unzip -u -q "postCodes.zip"
  mv -f "allCountries.txt" "../postCodes.txt"
  cd ..
  rm -rf "postcodes"
}

# Drop all tables
function drop_tables() {
  psql -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --quiet << EOF
    DROP TABLE IF EXISTS ${TABLE_PREFIX}geoname CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}alternatename CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}countryinfo CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}iso_languagecodes CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}admin1codesascii CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}admin2codesascii CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}featurecodes CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}timezones CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}continentcodes CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}postalcodes CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}airports CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}unlocodes CASCADE;
    DROP TABLE IF EXISTS ${TABLE_PREFIX}boundingbox CASCADE;
EOF
}

function create_tables() {
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/geoname.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/alternatename.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/countryinfo.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/iso_languagecodes.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/admin1codesascii.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/admin2codesascii.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/featurecodes.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/timezones.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/continentcodes.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/postalcodes.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/airports.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/unlocodes.sql")
EOF
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet << EOF 
  $(TABLE_PREFIX=$TABLE_PREFIX envsubst < "$WORKPATH/db/schemas/boundingbox.sql")
EOF
}

# Initialize DB, functions, extensions and tables
function initDB() {
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet -f "$WORKPATH/db/extensions.sql"
  psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DATABASE --quiet -f "$WORKPATH/db/functions.sql"

  if [[ "$DROP_TABLES" == "true" ]]; then
    drop_tables
  fi

  if [[ "$CREATE_TABLES" == "true" ]]; then
    create_tables
  fi
}

# Copying data from files
function copyData() {  
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}geoname (id,name,ascii_name,alternate_names,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,modified_date) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/allCountries.txt' null as '';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}timezones (country_code,id,GMT_offset,DST_offset,raw_offset) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/timeZones.txt' WITH null as '' DELIMITER E'\t' CSV QUOTE E'\b' HEADER;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}featurecodes (code,name,description) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/featureCodes_en.txt' null as '';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}admin1codesascii (code,name,name_ascii,geoname_id) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/admin1CodesASCII.txt' null as '';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}admin2codesascii (code,name,name_ascii,geoname_id) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/admin2Codes.txt' null as '';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}iso_languagecodes (iso_639_3,iso_639_2,iso_639_1,language_name) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/iso-languagecodes.txt' WITH null as '' DELIMITER E'\t' CSV QUOTE E'\b' HEADER;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,country,capital,area,population,continent,tld,currency_code,currency_name,phone,postal,postal_regex,languages,geoname_id,neighbours,equivalent_fips_code) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/countryInfo.txt' WITH NULL as '' DELIMITER E'\t' CSV QUOTE E'\b' ESCAPE '\';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}alternatename (id,geoname_id,iso_lang,alternate_name,is_preferred_name,is_short_name, is_colloquial,is_historic,\"from\",\"to\") from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/alternateNamesV2.txt' null as '';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}postalcodes (country_code, postal_code,place_name,admin1_name,admin1_code,admin2_name,admin2_code,admin3_name,admin3_code,latitude,longitude,accuracy) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/postCodes.txt' WITH NULL as '' DELIMITER E'\t' CSV QUOTE E'\b';"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}airports (geoname_id,\"name\",fcode,country_code,admin1_code,admin2_code,timezone,latitude,longitude,iata,icao,unlocode,city_id,city_name,active) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/airports.txt' WITH NULL as 'null' DELIMITER E'\t' CSV QUOTE E'\b' HEADER;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}unlocodes (country_code,locode,\"name\",geoname_id) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/unlocode-geonameid.txt' WITH NULL as 'null' DELIMITER E'\t' CSV QUOTE E'\b' HEADER;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "\copy ${TABLE_PREFIX}boundingbox (geoname_id,bboxwest,bboxsouth,bboxeast,bboxnorth) from '$GEONAMES_OUTDIR/$GEONAMES_RELEASE/boundingbox.txt' WITH NULL as 'null' DELIMITER E'\t' CSV QUOTE E'\b' HEADER;"
  # Insert static data
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "INSERT INTO ${TABLE_PREFIX}continentcodes (code, name, geoname_id) VALUES ('AF', 'Africa', 6255146),('AS', 'Asia', 6255147),('EU', 'Europe', 6255148),('NA', 'North America', 6255149),('OC', 'Oceania', 6255150),('SA', 'South America', 6255151),('AN', 'Antarctica', 6255152);"
}

# Finalizing data: constraints, indexes, converting columns, ...
function finalizeData() {
  # Generating indexes
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_countryinfo_geoname_id ON ${TABLE_PREFIX}countryinfo (geoname_id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_alternatename_geoname_id ON ${TABLE_PREFIX}alternatename (geoname_id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_alternatename_iso_lang ON ${TABLE_PREFIX}alternatename (iso_lang);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_postalcodes_country_code_postal_code ON ${TABLE_PREFIX}postalcodes (country_code, postal_code);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_unlocodes_country_code_code_locode ON ${TABLE_PREFIX}unlocodes (country_code, locode);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_airports_iata ON ${TABLE_PREFIX}airports (iata);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_geoname_country ON ${TABLE_PREFIX}geoname USING btree (country COLLATE pg_catalog.\"default\" ASC NULLS LAST) TABLESPACE pg_default;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_geoname_fclass ON ${TABLE_PREFIX}geoname USING btree (fclass COLLATE pg_catalog.\"default\" ASC NULLS LAST) TABLESPACE pg_default;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_geoname_fcode ON ${TABLE_PREFIX}geoname USING btree (fcode COLLATE pg_catalog.\"default\" ASC NULLS LAST) TABLESPACE pg_default;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_geoname_population ON ${TABLE_PREFIX}geoname USING btree (population ASC NULLS LAST) TABLESPACE pg_default;"

  # Adding PRIMARY contraints
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}geoname ADD CONSTRAINT pk_geoname_id PRIMARY KEY (id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}alternatename ADD CONSTRAINT pk_alternatename_id PRIMARY KEY (id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}countryinfo ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}continentcodes ADD CONSTRAINT pk_contintentcode PRIMARY KEY (code);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}timezones ADD CONSTRAINT pk_timezoneid PRIMARY KEY (id);"
  # psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY unlocodes ADD CONSTRAINT pk_country_locode PRIMARY KEY (country_code, locode);"

  # Adding FOREIGN constraints
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}admin1codesascii ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}admin2codesascii ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);" 
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}airports ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}alternatename ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}continentcodes ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}countryinfo ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES ${TABLE_PREFIX}geoname(id);"
  
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}countryinfo ADD CONSTRAINT fk_continent FOREIGN KEY (continent) REFERENCES ${TABLE_PREFIX}continentcodes(code);"

  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}airports ADD CONSTRAINT fk_country_code FOREIGN KEY (country_code) REFERENCES ${TABLE_PREFIX}countryinfo(iso_alpha2);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}postalcodes ADD CONSTRAINT fk_country_code FOREIGN KEY (country_code) REFERENCES ${TABLE_PREFIX}countryinfo(iso_alpha2);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}timezones ADD CONSTRAINT fk_country_code  FOREIGN KEY (country_code) REFERENCES ${TABLE_PREFIX}countryinfo(iso_alpha2);"  
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}unlocodes ADD CONSTRAINT fk_country_code  FOREIGN KEY (country_code) REFERENCES ${TABLE_PREFIX}countryinfo(iso_alpha2);"

  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}airports ADD CONSTRAINT fk_timezone FOREIGN KEY (timezone) REFERENCES ${TABLE_PREFIX}timezones(id);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY ${TABLE_PREFIX}geoname ADD CONSTRAINT fk_timezone FOREIGN KEY (timezone) REFERENCES ${TABLE_PREFIX}timezones(id);"
  # Not available due to inconsistence of data
  # psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY geoname ADD CONSTRAINT fk_country_code FOREIGN KEY (country) REFERENCES countryinfo(iso_alpha2);"
  # psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY airports ADD CONSTRAINT fk_unlocode FOREIGN KEY (country_code, unlocode) REFERENCES unlocodes(country_code, locodes);"
  # psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY unlocodes ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES geoname(id);"
  # psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ONLY boundingbox ADD CONSTRAINT fk_geonameid FOREIGN KEY (geoname_id) REFERENCES geoname(id);"

  # Calculate tsvector indexes
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}geoname SET search_vector = to_tsvector('english', concat_ws(' ', name, ascii_name)) WHERE TRUE;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}alternatename SET search_vector = to_tsvector('english', alternate_name) WHERE TRUE;"

  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX IF NOT EXISTS idx_geoname_search_vector ON ${TABLE_PREFIX}geoname USING gin (search_vector) TABLESPACE pg_default;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX IF NOT EXISTS idx_alternatename_search_vector ON ${TABLE_PREFIX}alternatename USING gin (search_vector) TABLESPACE pg_default;"
  
  # Calculate trigram indexes
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX IF NOT EXISTS idx_geoname_name_trgm_gin ON ${TABLE_PREFIX}geoname USING gin (f_unaccent(\"name\") COLLATE pg_catalog.\"default\" gin_trgm_ops) TABLESPACE pg_default;";
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX IF NOT EXISTS idx_alternatename_alternate_name_trgm_gin ON ${TABLE_PREFIX}alternatename USING gin (f_unaccent(\"alternate_name\") COLLATE pg_catalog."default" gin_trgm_ops) TABLESPACE pg_default;";

  # Calculate geometries and indexes
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}geoname SET center = ST_SETSRID(ST_MakePoint(longitude, latitude), 4326);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_geoname_center ON ${TABLE_PREFIX}geoname USING gist (center);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}postalcodes SET center = ST_SETSRID(ST_MakePoint(longitude, latitude), 4326);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_postalcodes_center ON ${TABLE_PREFIX}postalcodes USING gist (center);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}boundingbox SET way = ST_MakeEnvelope(bboxwest, bboxsouth, bboxeast, bboxnorth, 4326);"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "CREATE INDEX idx_boundingbox_way ON ${TABLE_PREFIX}boundingbox USING gist (way);"

  # Convert data to modern format
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "UPDATE ${TABLE_PREFIX}countryinfo SET neighbours_array = string_to_array(neighbours, ','), languages_array = string_to_array(languages, ',');"

  # Clean data from redundancy
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}geoname DROP COLUMN alternate_names, DROP COLUMN longitude, DROP COLUMN latitude;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}boundingbox DROP COLUMN bboxwest, DROP COLUMN bboxsouth, DROP COLUMN bboxeast, DROP COLUMN bboxnorth;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}airports DROP COLUMN longitude, DROP COLUMN latitude, DROP COLUMN timezone, DROP COLUMN name;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}postalcodes DROP COLUMN longitude, DROP COLUMN latitude;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}countryinfo DROP COLUMN neighbours, DROP COLUMN languages;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}countryinfo RENAME COLUMN neighbours_array TO neighbours;"
  psql -e -U $DBUSER -h $DBHOST -p $DBPORT $DATABASE --command "ALTER TABLE ${TABLE_PREFIX}countryinfo RENAME COLUMN languages_array TO languages;"
}

# Add directories
mkdir -p $TMPPATH
mkdir -p "$GEONAMES_OUTDIR/$GEONAMES_RELEASE"

#getFiles
initDB
copyData
finalizeData
