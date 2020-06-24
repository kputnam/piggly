create or replace function foo()
returns void
language plpgsql
as $$
DECLARE
   gencur refcursor;
   mycur CURSOR FOR SELECT * from pg_database;
   mycur2 SCROLL CURSOR FOR SELECT * from pg_database;
   mycur3 NO SCROLL CURSOR FOR SELECT * from pg_database;
   mycur4 CURSOR (key integer) FOR SELECT * from pg_database where encoding = key;
BEGIN
   return;
END;
$$;
