create or replace function numberedargs(int, int, int, int)
  returns setof varchar as
$$
begin
  return next $1::varchar;
  return next $2::varchar;
  return next $3::varchar;
  return next $4::varchar;
end
$$ language plpgsql;
