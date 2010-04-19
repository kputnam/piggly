module Piggly
  class Installer

    def self.trace_proc(path)
      cache = Piggly::TraceCompiler.cache(path)

      # install instrumented code
      connection.exec cache['code.sql']

      # map tag messages to tag objects
      Profile.add(path, cache['tags'], cache)
    end

    def self.untrace_proc(file)
      connection.exec File.read(file)
    end

    def self.install_trace
      # record trace messages
      connection.set_notice_processor(&Profile.notice_processor)

      # install tracing functions
      connection.exec <<-SQL
        -- signals that a conditional expression was executed
        CREATE OR REPLACE FUNCTION piggly_cond(message varchar, value boolean)
          RETURNS boolean AS $$
        BEGIN
          IF value THEN
            RAISE WARNING '#{Config.trace_prefix} % t', message;
          ELSE
            RAISE WARNING '#{Config.trace_prefix} % f', message;
          END IF;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      connection.exec <<-SQL
        -- generic signal
        CREATE OR REPLACE FUNCTION piggly_signal(message varchar, signal varchar)
          RETURNS void AS $$
        BEGIN
          RAISE WARNING '#{Config.trace_prefix} % %', message, signal;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      connection.exec <<-SQL
        -- signals that a (sub)expression was executed. handles '' and NULL value
        CREATE OR REPLACE FUNCTION piggly_expr(message varchar, value varchar)
          RETURNS varchar AS $$
        BEGIN
          RAISE WARNING '#{Config.trace_prefix} %', message;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      connection.exec <<-SQL
        -- signals that a (sub)expression was executed. handles all other types
        CREATE OR REPLACE FUNCTION piggly_expr(message varchar, value anyelement)
          RETURNS anyelement AS $$
        BEGIN
          RAISE WARNING '#{Config.trace_prefix} %', message;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      connection.exec <<-SQL
        -- signals that a branch was taken
        CREATE OR REPLACE FUNCTION piggly_branch(message varchar)
          RETURNS void AS $$
        BEGIN
          RAISE WARNING '#{Config.trace_prefix} %', message;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL
    end

    def self.uninstall_trace
      connection.set_notice_processor
      connection.exec "DROP FUNCTION IF EXISTS piggly_cond(varchar, boolean);"
      connection.exec "DROP FUNCTION IF EXISTS piggly_expr(varchar, varchar);"
      connection.exec "DROP FUNCTION IF EXISTS piggly_expr(varchar, anyelement);"
      connection.exec "DROP FUNCTION IF EXISTS piggly_branch(varchar);"
    end

    def self.connection
      ActiveRecord::Base.connection.raw_connection
    end

  end
end
