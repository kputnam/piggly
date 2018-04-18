CREATE SCHEMA IF NOT EXISTS cas;

DROP TYPE IF EXISTS cas.user CASCADE;
CREATE TYPE cas.user AS
( first_name  varchar
, last_name   varchar
);

CREATE OR REPLACE FUNCTION cas.user_full_name(u cas.user)
RETURNS varchar AS $$ BEGIN
  RETURN u.first_name || ' ' || u.last_name;
END; $$ LANGUAGE plpgsql IMMUTABLE;
