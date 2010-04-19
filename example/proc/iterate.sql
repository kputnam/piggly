-- return each non-null element as a row
create or replace function iterate(items anyarray)
  returns setof anyelement as
$$
declare
  arrayMinIndex  integer := array_lower(items, 1);
  arrayMaxIndex  integer := array_upper(items, 1);
  loopIndex      integer;
begin

  if arrayMinIndex is null
  then
    return;
  end if;

  for loopIndex in arrayMinIndex .. arrayMaxIndex loop
    if items[loopIndex] is not null
    then
      return next items[loopIndex];
    end if;
  end loop;

end;
$$ language plpgsql;
