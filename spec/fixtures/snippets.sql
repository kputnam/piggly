CREATE OR REPLACE FUNCTION piggly_coverage_prog(a integer, b boolean) RETURNS void AS $$
DECLARE
  x   varchar(20);
  y   integer[] := '{}';
BEGIN

  -- IF-THEN
  IF v_user_id <> 0
  THEN
    UPDATE users SET email = v_email WHERE user_id = v_user_id;
  END IF;

  -- IF-THEN-ELSE
  IF parentid IS NULL OR parentid = ''
  THEN
    RETURN fullname;
  ELSE
    RETURN hp_true_filename(parentid) || '/' || fullname;
  END IF;

  -- IF-THEN-ELSE
  IF v_count > 0 THEN
      INSERT INTO users_count(count) VALUES (v_count);
      RETURN 't';
  ELSE
      RETURN 'f';
  END IF;

  -- IF-THEN-ELSIF
  IF number = 0 THEN
      result := 'zero';
  ELSIF number > 0 THEN
      result := 'positive';
  ELSIF number < 0 THEN
      result := 'negative';
  ELSE
      -- hmm, the only other possibility is that the number is null
      result := 'NULL';
  END IF;

  -- nest IF-THEN-ELSE statements
  IF demo_row.sex = 'm' THEN
      pretty_sex := 'man';
  ELSE
      IF demo_row.sex = 'f' THEN
          pretty_sex := 'woman';
      END IF;
  END IF;

  -- simple CASE with search-expression
  CASE x
    WHEN 1, 2 THEN
      msg := 'one or two';
    ELSE
      msg := 'other value than one or two';
  END CASE;

  -- searched CASE with boolean-expression
  CASE
    WHEN x BETWEEN 0 and 10 THEN
      msg := 'value is between zero and ten';
    WHEN x BETWEEN 11 and 20 THEN
      msg := 'value is between eleven and twenty';
  END CASE;

  << labelA >>
  LOOP
    a := a + 1;
    EXIT labelA WHEN a > 10;
  END LOOP labelA;

  LOOP
    b := b + 1
    EXIT WHEN b > 10;
  END LOOP;

  LOOP
      c := c + 1;
      IF c > 10 THEN
          EXIT;
      END IF;
  END LOOP;

  << labelB >>
  BEGIN
    -- some computations
    IF stocks > 100000 THEN
      EXIT labelB; -- causes exit from BEGIN block
    END IF;
    -- computations here will be skipped when stocks > 100000
  END;

  LOOP
      -- some computations
      EXIT WHEN count > 100;
      CONTINUE WHEN count < 50;
      -- some computations for count IN [50 .. 100]
  END LOOP;

  WHILE amount_owed > 0 AND gift_certificate_balance > 0
  LOOP
    -- some computations here
    a := 10;
  END LOOP;

  << labelC >>
  WHILE NOT done LOOP
    -- some computations here
    a := 10;
  END LOOP labelC;

  << labelD >>
  WHILE x NOT IN (1,2,3) LOOP
    CONTINUE labelD WHEN x < 10;
  END LOOP;

  FOR i IN 1..10 LOOP
    --
  END LOOP;

  << labelD >>
  FOR i IN REVERSE 10..1 LOOP
    --
    EXIT labelD WHEN i = 5;
  END LOOP labelD;

  << labelE >>
  FOR i IN REVERSE 10..1 BY 2 LOOP
    --
    CONTINUE labelE;
  END LOOP;

  FOR f IN SELECT *
           FROM foo
           WHERE id > 100
  LOOP
    -- can do some processing home
    RETURN NEXT f; -- return current row of SELECT
  END LOOP;

  FOR t IN EXECUTE 'SELECT * FROM foo' LOOP
    CONTINUE;
  END LOOP;

  BEGIN
    UPDATE tab SET fname = 'J' WHERE lname = 'J';
    x := x + 1;
    y := x / 0;
  EXCEPTION
    WHEN SQLSTATE '22012' THEN
      -- relax, don't do it
    WHEN division_by_zero OR unique_violation THEN
      RAISE NOTICE 'caught a fool';
      RETURN x;
  END;

END $$
  LANGUAGE 'plpgsql' IMMUTABLE;
