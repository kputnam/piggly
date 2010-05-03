CREATE OR REPLACE FUNCTION snippets(a integer, b boolean) RETURNS SETOF pg_namespace AS $$
DECLARE
  x               varchar(20);
  n               integer := 403;
  i               integer;
  ys              integer[] := '{}';
  result          text;
  fooValue        record;
  loopElement     record;
  formattedName   character varying;
  myself          pg_proc%ROWTYPE;
  shareCount      integer := 99999999;
  count           integer;
BEGIN

  -- IF-THEN
  IF a <> 0
  THEN
    SELECT INTO n sum("id") FROM pg_users;
  END IF;
  
  -- IF-THEN-ELSE
  IF a IS NULL OR b::varchar = ''
  THEN
    x := 'bahut badmash!';
  ELSE
    SELECT INTO ys ARRAY(SELECT * FROM generate_series(1, a));
  END IF;
  
  -- IF-THEN-ELSIF
  IF array_upper(ys, 1) = 0 THEN
      result := 'zero';
  ELSIF array_upper(ys, 1) > 0 THEN
      result := 'positive';
  ELSIF array_upper(ys, 1) < 0 THEN
      result := 'negative';
  ELSE
      /* commentary and buffoonary *
       * that spans multiple lines *
       * but does not explain much *
       * about tom foolery jewelry */
      result := 'NULL';
  END IF;
  
  FOR fooValue IN
    SELECT *,
      prolang IN ( SELECT oid
                   FROM pg_language
                   WHERE lanname <> 'plpgsql' ) AS frump
    FROM pg_proc
    WHERE pronamespace IN
      ( SELECT oid
        FROM pg_namespace
        WHERE nspname ILIKE 'pg_%' )
  LOOP
    -- nest IF-THEN-ELSE statements
    IF fooValue.frump THEN
        formattedName := 'man';
    ELSE
        IF fooValue.proretset IS FALSE THEN
            formattedName := 'ULYSSES S GRUMP';
        END IF;
    END IF;
  
    -- simple CASE with search-expression
    CASE a
      WHEN 1, 2 THEN
        result := 'one or two';
      WHEN 3, 4 THEN
        RAISE NOTICE 'I see you baybee';
      ELSE
        result := 'other value than one or two';
    END CASE;
  
    -- searched CASE with boolean-expression
    CASE
      WHEN b IS NULL THEN
        myself := NULL;
      WHEN b BETWEEN 0 and 10 THEN
        myself := fooValue;
      WHEN b BETWEEN 11 and 20 THEN
        myself := fooValue;
    END CASE;
  END LOOP;

  DECLARE
    a integer := 10;
    b integer := 5;
    c integer := 20;
  BEGIN
    << labelA >>
    LOOP
      a := a + 1;
      EXIT labelA WHEN a > 10;
    END LOOP labelA;

    LOOP
      b := b + 1;
      EXIT WHEN b > 10;
      CONTINUE WHEN b > 10;
    END LOOP;

    LOOP
        c := c + 1;
        IF c > 10 THEN
            EXIT;
        END IF;
    END LOOP;
  END;

  << labelB >>
  BEGIN
    -- some computations
    IF shareCount > 100000 THEN
      EXIT labelB; -- causes exit from BEGIN block
    END IF;
    -- computations here will be skipped when stocks > 100000
    RAISE NOTICE 'get outta hyah kid! ya bahthrin me';
  END;

  count := 0;

  WHILE count > 10 AND true
  LOOP
    count := floor(count / 4.0);
  END LOOP;

  << labelC >>
  WHILE NOT n = 10 LOOP
    -- some computations here
    n := 10;
  END LOOP labelC;

  << labelD >>
  WHILE n NOT IN (1,2,3) LOOP
    n := 3;
    CONTINUE labelD WHEN n < 10;
  END LOOP;

  FOR i IN 1 .. 10 LOOP
    SELECT INTO n sum(fuzit) FROM generate_series(1, i) AS fuzit;
    ys[i] = n;
  END LOOP;

  << labelD >>
  FOR i IN REVERSE 10..1 LOOP
    --
    EXIT labelD WHEN i = 5;
  END LOOP labelD;

  << labelE >>
  FOR i IN REVERSE 10..1 BY 2 LOOP
    SELECT INTO n avg(whozit)::integer FROM generate_series(1, i) AS whozit;
    ys[20 - i] := n;
  --CONTINUE labelE;
  END LOOP;

  FOR loopElement IN
    SELECT *
    FROM pg_namespace
    LIMIT 2
  LOOP
    -- can do some processing home
    RETURN NEXT loopElement; -- return current row of SELECT
  END LOOP;

  FOR loopElement IN EXECUTE 'SELECT * FROM pg_namespace' LOOP
    CONTINUE;
  END LOOP;

  BEGIN
    n := n + 1;
    n := n / 0;
  EXCEPTION
    WHEN SQLSTATE '22012' THEN
      -- relax, don't do it
    WHEN division_by_zero OR unique_violation THEN
      RAISE NOTICE 'caught a fool';
  END;

END $$
  LANGUAGE 'plpgsql' IMMUTABLE;
