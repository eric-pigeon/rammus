module Chromiebara
  module Protocol
    module Database
      extend self

      # Disables database tracking, prevents database events from being sent to the client.
      #
      def disable
        {
          method: "Database.disable"
        }
      end

      # Enables database tracking, database events will now be delivered to the client.
      #
      def enable
        {
          method: "Database.enable"
        }
      end

      def execute_sql(database_id:, query:)
        {
          method: "Database.executeSQL",
          params: { databaseId: database_id, query: query }.compact
        }
      end

      def get_database_table_names(database_id:)
        {
          method: "Database.getDatabaseTableNames",
          params: { databaseId: database_id }.compact
        }
      end

      def add_database
        'Database.addDatabase'
      end
    end
  end
end
