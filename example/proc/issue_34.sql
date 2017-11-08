CREATE OR REPLACE FUNCTION issue_34(IN id integer DEFAULT NULL::integer)
  RETURNS TABLE(tag integer, flag boolean, foo integer, bar boolean, baz boolean, quux numeric) AS
$BODY$
BEGIN
-- there be dragons here
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
