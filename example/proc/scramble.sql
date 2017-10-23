create or replace function scramble(subject text, out scrambled text, out first char)
  as
$$
begin
  scrambled := substring($1, 1, (random() * length($1))::integer);
  first     := substring($1, 1, 1);
end
$$ language 'plpgsql' stable;

create or replace function scramble(varchar, out text, out char) as $$
  begin
    execute scramble($1::text, $2, $3);
  end
$$ language 'plpgsql' stable;

create or replace function ccramble(subject text)
  returns table(scrambled text, first char)
  as
$$
begin
  scrambled := substring($1, 1, (random() * length($1))::integer);
  first     := substring($1, 1, 1);
end
$$ language 'plpgsql' stable;
