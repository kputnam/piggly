require 'active_record'
require 'test/unit'

=begin
  user$ sudo -s
  root# su - postgres
  postgres$ psql
  postgres=# CREATE ROLE piggly PASSWORD 'md5d99b55537ceac6dbdf5da613b5754d42' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
  postgres=# CREATE DATABASE piggly OWNER piggly ENCODING 'utf8';
  postgres=# \c piggly
  postgres=# CREATE LANGUAGE "plpgsql";
=end

ActiveRecord::Base.establish_connection \
  'adapter'   => 'postgresql',
  'database'  => 'piggly',
  'username'  => 'piggly',
  'password'  => 'secret',
  'host'      => 'localhost'

def connection
  ActiveRecord::Base.connection
end

connection.execute(File.read(File.dirname(__FILE__) + '/../proc/iterate.sql'))
connection.execute(File.read(File.dirname(__FILE__) + '/../proc/scramble.sql'))
connection.execute(File.read(File.dirname(__FILE__) + '/../proc/snippets.sql'))

class IterateTest < Test::Unit::TestCase

  def test_returns_no_rows_from_empty_array
    assert call_iterate([]).empty?
  end

  def test_returns_no_rows_from_one_element_array_with_null_element
    assert call_iterate([nil]).empty?
  end

  def test_returns_one_row_from_one_element_array_with_non_null_element
    assert_equal ['1'], call_iterate(['1'])
  end

  def test_returns_second_element_from_two_element_array_with_one_null_and_one_non_null_element
    assert_equal ['2'], call_iterate([nil, '2'])
  end

  def test_returns_first_element_from_two_element_array_with_one_non_null_and_one_null_element
    assert_equal ['1'], call_iterate(['1', nil])
  end

  def test_returns_both_elements_from_two_element_array_with_non_null_elements
    assert_equal ['1', '2'], call_iterate(['1', '2'])
  end

private

  def call_iterate(argument)
    ActiveRecord::Base.connection.select_values <<-SQL
      SELECT * FROM iterate('{#{argument.map{|x| (x.nil?) ? 'null' : x }.join(',')}}'::varchar[])
    SQL
  end

end
