module Piggly

  class Installer
    def initialize(config, connection)
      @config, @connection = config, connection
    end

    # @return [void]
    def install(procedures, profile)
      @connection.exec("begin")

      install_support(profile)

      procedures.each do |p|
        begin
          trace(p, profile)
        rescue Parser::Failure
          $stdout.puts $!
        end
      end

      @connection.exec("commit")
    rescue
      @connection.exec("rollback")
      raise
    end

    # @return [void]
    def uninstall(procedures)
      @connection.exec("begin")

      procedures.each{|p| untrace(p) }
      uninstall_support

      @connection.exec("commit")
    rescue
      @connection.exec("rollback")
      raise
    end

    # @return [void]
    def trace(procedure, profile)
      # recompile with instrumentation
      compiler = Compiler::TraceCompiler.new(@config)
      result   = compiler.compile(procedure)
        # result[:tree] - tagged and rewritten parse tree
        # result[:tags] - collection of Tag values in the tree
        # result[:code] - instrumented

      @connection.exec(procedure.definition(result[:code]))
      
      profile.add(procedure, result[:tags], result)
    rescue
      $!.message << "\nError installing traced procedure #{procedure.name} "
      $!.message << "from #{procedure.source_path(@config)}"
      raise
    end

    # @return [void]
    def untrace(procedure)
      @connection.exec(procedure.definition(procedure.source(@config)))
    end

    # Installs necessary instrumentation support
    def install_support(profile)
      @connection.set_notice_processor(&profile.notice_processor(@config))

    # def connection.set_notice_processor
    #   # do nothing: prevent the notice processor from being subverted
    # end

      # install tracing functions
      @connection.exec <<-SQL
        -- Signals that a conditional expression was executed
        CREATE OR REPLACE FUNCTION piggly_cond(message varchar, value boolean)
          RETURNS boolean AS $$
        BEGIN
          IF value THEN
            RAISE WARNING '#{@config.trace_prefix} % t', message;
          ELSE
            RAISE WARNING '#{@config.trace_prefix} % f', message;
          END IF;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      @connection.exec <<-SQL
        -- Generic signal
        CREATE OR REPLACE FUNCTION piggly_signal(message varchar, signal varchar)
          RETURNS void AS $$
        BEGIN
          RAISE WARNING '#{@config.trace_prefix} % %', message, signal;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      @connection.exec <<-SQL
        -- Signals that a (sub)expression was executed. handles '' and NULL value
        CREATE OR REPLACE FUNCTION piggly_expr(message varchar, value varchar)
          RETURNS varchar AS $$
        BEGIN
          RAISE WARNING '#{@config.trace_prefix} %', message;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      @connection.exec <<-SQL
        -- Signals that a (sub)expression was executed. handles all other types
        CREATE OR REPLACE FUNCTION piggly_expr(message varchar, value anyelement)
          RETURNS anyelement AS $$
        BEGIN
          RAISE WARNING '#{@config.trace_prefix} %', message;
          RETURN value;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL

      @connection.exec <<-SQL
        -- Signals that a branch was taken
        CREATE OR REPLACE FUNCTION piggly_branch(message varchar)
          RETURNS void AS $$
        BEGIN
          RAISE WARNING '#{@config.trace_prefix} %', message;
        END $$ LANGUAGE 'plpgsql' VOLATILE;
      SQL
    end

    # Uninstalls instrumentation support
    def uninstall_support
      @connection.set_notice_processor
      @connection.exec "DROP FUNCTION IF EXISTS piggly_cond(varchar, boolean)"
      @connection.exec "DROP FUNCTION IF EXISTS piggly_expr(varchar, varchar)"
      @connection.exec "DROP FUNCTION IF EXISTS piggly_expr(varchar, anyelement)"
      @connection.exec "DROP FUNCTION IF EXISTS piggly_branch(varchar)"
      @connection.exec "DROP FUNCTION IF EXISTS piggly_signal(varchar, varchar)"
    end
  end

end
