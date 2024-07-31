module OxAiWorkers
  module Tool
    #
    # Connects to a database, executes SQL queries, and outputs DB schema for Agents to use
    #
    # Gem requirements:
    #     gem "sequel", "~> 5.68.0"
    #
    # Usage:
    #     database = OxAiWorkers::Tool::Database.new(connection_string: "postgres://user:password@localhost:5432/db_name")
    #
    class Database
      extend OxAiWorkers::ToolDefinition
      include OxAiWorkers::DependencyHelper

      define_function :list_tables,
                      description: I18n.t('oxaiworkers.tool.database_tool.list_tables.description')

      define_function :describe_tables,
                      description: I18n.t('oxaiworkers.tool.database_tool.describe_tables.description') do
        property :tables, type: 'string',
                          description: I18n.t('oxaiworkers.tool.database_tool.describe_tables.tables'),
                          required: true
      end

      define_function :dump_schema,
                      description: I18n.t('oxaiworkers.tool.database_tool.dump_schema.description')

      define_function :execute,
                      description: I18n.t('oxaiworkers.tool.database_tool.execute.description') do
        property :input, type: 'string',
                         description: I18n.t('oxaiworkers.tool.database_tool.execute.input'),
                         required: true
      end

      attr_reader :db, :requested_tables, :excluded_tables

      # Establish a database connection
      #
      # @param connection_string [String] Database connection info, e.g. 'postgres://user:password@localhost:5432/db_name'
      # @param tables [Array<Symbol>] The tables to use. Will use all if empty.
      # @param except_tables [Array<Symbol>] The tables to exclude. Will exclude none if empty.
      # @return [Database] Database object
      def initialize(connection_string:, tables: [], exclude_tables: [])
        depends_on 'sequel'

        raise StandardError, 'connection_string parameter cannot be blank' if connection_string.empty?

        @db = Sequel.connect(connection_string)
        @requested_tables = tables
        @excluded_tables = exclude_tables
      end

      # Database Tool: Returns a list of tables in the database
      def list_tables
        db.tables
      end

      # Database Tool: Returns the schema for a list of tables
      #
      # @param tables [String] The tables to describe.
      # @return [String] Database schema for the tables
      def describe_tables(tables:)
        schema = ''
        tables.split(',').each do |table|
          describe_table(table, schema)
        end
        schema
      end

      # Database Tool: Returns the database schema
      #
      # @return [String] Database schema
      def dump_schema
        OxAiWorkers.logger.debug('Dumping schema tables and keys', for: self.class)
        schema = ''
        db.tables.each do |table|
          describe_table(table, schema)
        end
        schema
      end

      def describe_table(table, schema)
        primary_key_columns = []
        primary_key_column_count = db.schema(table).count { |column| column[1][:primary_key] == true }

        schema << "CREATE TABLE #{table}(\n"
        db.schema(table).each do |column|
          schema << "#{column[0]} #{column[1][:type]}"
          if column[1][:primary_key] == true
            schema << ' PRIMARY KEY' if primary_key_column_count == 1
          else
            primary_key_columns << column[0]
          end
          schema << ",\n" unless column == db.schema(table).last && primary_key_column_count == 1
        end
        schema << "PRIMARY KEY (#{primary_key_columns.join(',')})" if primary_key_column_count > 1
        db.foreign_key_list(table).each do |fk|
          schema << ",\n" if fk == db.foreign_key_list(table).first
          schema << "FOREIGN KEY (#{fk[:columns][0]}) REFERENCES #{fk[:table]}(#{fk[:key][0]})"
          schema << ",\n" unless fk == db.foreign_key_list(table).last
        end
        schema << ");\n"
      end

      # Database Tool: Executes a SQL query and returns the results
      #
      # @param input [String] SQL query to be executed
      # @return [Array] Results from the SQL query
      def execute(input:)
        OxAiWorkers.logger.info("Executing \"#{input}\"", for: self.class)

        db[input].to_a
      rescue Sequel::DatabaseError => e
        OxAiWorkers.logger.info(e.message, for: self.class)
        e.message
      end
    end
  end
end
