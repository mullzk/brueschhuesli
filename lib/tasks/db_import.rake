namespace :db do
  desc "Import data from Heroku PostgreSQL (HEROKU_DATABASE_URL) into local MySQL"
  task import_from_postgres: :environment do
    require 'pg'

    heroku_url = ENV.fetch("HEROKU_DATABASE_URL") { abort "HEROKU_DATABASE_URL not set" }

    pg = PG.connect(heroku_url)
    mysql = ActiveRecord::Base.connection
    mysql.execute("SET FOREIGN_KEY_CHECKS = 0")

    tables = pg.exec(<<~SQL).to_a.map { |r| r["tablename"] }
      SELECT tablename FROM pg_tables
      WHERE schemaname = 'public'
        AND tablename NOT IN ('ar_internal_metadata', 'schema_migrations')
      ORDER BY tablename
    SQL
    puts "Tables found in source: #{tables.join(', ')}"

    tables.each do |table|
      result = pg.exec("SELECT * FROM #{table}")
      rows = result.to_a
      puts "#{table}: #{rows.size} rows"
      next if rows.empty?

      mysql.execute("TRUNCATE TABLE `#{table}`")

      columns = rows.first.keys
      col_list = columns.map { |c| "`#{c}`" }.join(", ")

      rows.each_slice(200) do |batch|
        values = batch.map do |row|
          vals = columns.map do |col|
            val = row[col]
            case val
            when nil    then "NULL"
            when "t"    then "1"
            when "f"    then "0"
            else             mysql.quote(val)
            end
          end
          "(#{vals.join(', ')})"
        end
        mysql.execute("INSERT INTO `#{table}` (#{col_list}) VALUES #{values.join(', ')}")
      end
    end

    pg.close
    puts "Import complete."
  end
end
