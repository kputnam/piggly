require 'active_record'
require 'spec'

=begin
  user$ sudo -s
  root# su - postgres
  postgres$ psql
  postgres=# CREATE ROLE piggly PASSWORD 'md5d99b55537ceac6dbdf5da613b5754d42' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
  postgres=# CREATE DATABASE piggly OWNER piggly ENCODING 'utf8';
  postgres=# \c piggly
  postgres=# CREATE LANGUAGE "plpgsql";
  postgres=# \i proc/iterate.sql
  postgres=# \i proc/snippets.sql
  postgres=# \i proc/scramble.sql
=end

ActiveRecord::Base.establish_connection \
  'adapter'   => 'postgresql',
  'database'  => 'piggly',
  'username'  => 'piggly',
  'password'  => 'secret',
  'host'      => 'localhost',
  'port'      => '5432'

def connection
  ActiveRecord::Base.connection
end

def call_iterate(argument)
  connection.select_values <<-SQL
    SELECT * FROM iterate('{#{argument.map{|x| (x.nil?) ? 'null' : x }.join(',')}}'::varchar[])
  SQL
end

def call_snippets(a, b)
  connection.select_values <<-SQL
    SELECT * FROM snippets(#{connection.quote a}, #{connection.quote b})
  SQL
end

def call_scramble(text)
  connection.select_values <<-SQL
    SELECT * FROM scramble(#{connection.quote text})
  SQL
end

describe "iterate" do

  context "with empty array" do
    it "should return no rows" do
      call_iterate([]).should be_empty
    end
  end

  context "with one-element array" do
    context "where the element is null" do
      it "should return no rows" do
        call_iterate([nil]).should be_empty
      end
    end

    context "where the element is non-null" do
      before { @argument = ['1'] }

      it "should return one row" do
        call_iterate(@argument).should have(1).thing
      end

      it "should return the first element" do
        call_iterate(@argument).should == @argument
      end
    end
  end

  context "with two-element array" do
    context "where only the first element is null" do
      before { @argument = [nil, '2'] }

      it "should return one row" do
        call_iterate(@argument).should have(1).thing
      end

      it "should return the second element" do
        call_iterate(@argument).should == [@argument.last]
      end
    end

    context "where only the second element is null" do
      before { @argument = ['1', nil] }

      it "should return one row" do
        call_iterate(@argument).should have(1).thing
      end

      it "should return the first element" do
        call_iterate(@argument).should == [@argument.first]
      end
    end

    context "where both elements are null" do
      before { @argument = [nil, nil] }

      it "should return no rows" do
        call_iterate(@argument).should be_empty
      end
    end

    context "where both elements are non-null" do
      before { @argument = ['1', '2'] }

      it "should return two rows" do
        call_iterate(@argument).should have(2).things
      end

      it "should return first and second elements in order" do
        call_iterate(@argument).should == @argument
      end
    end
  end

end

describe "snippets" do
  it "wrecklessly cpu cycles" do
    call_snippets(nil, nil)
  end
end

describe "scramble" do
  it "performs magnificently" do
    call_scramble('boo hiss')
  end
end
