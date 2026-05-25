require "securerandom"
require "shellwords"

module DbSync
  module_function

  DEPLOY_PATHS = {
    "integration" => "/var/www/brueschhueslidev",
    "production"  => "/var/www/brueschhuesliprod"
  }.freeze
  REMOTE_STAGES = DEPLOY_PATHS.keys.freeze

  def require_stage!
    stage = ENV["STAGE"] or abort "Usage: STAGE=integration rails db:pull / db:push"
    abort "Unknown stage: #{stage}. Known: #{REMOTE_STAGES.join(', ')}" unless REMOTE_STAGES.include?(stage)
    stage
  end

  def confirm_production!(stage)
    return unless stage == "production"
    print "Wirklich Production überschreiben? Tippe 'yes': "
    abort "Abgebrochen." unless $stdin.gets.to_s.strip == "yes"
  end

  def stage_credentials(stage)
    prefix = "DEPLOY_#{stage.upcase}_"
    {
      host:     ENV.fetch("#{prefix}HOST")   { abort "#{prefix}HOST not set (lokal in .env)" },
      user:     ENV.fetch("#{prefix}USER")   { abort "#{prefix}USER not set (lokal in .env)" },
      env_file: "#{DEPLOY_PATHS.fetch(stage)}/shared/config/env"
    }
  end

  def ssh_target_for(stage)
    cfg = stage_credentials(stage)
    "#{cfg[:user]}@#{cfg[:host]}"
  end

  def parse_db_url(url)
    uri = URI.parse(url)
    { host: uri.host, user: uri.user, password: uri.password,
      database: uri.path.delete_prefix("/") }
  end

  def dump_filename(label)
    "brueschhuesli-#{label}-#{Time.now.strftime('%Y%m%d-%H%M%S')}-#{SecureRandom.hex(4)}.sql"
  end

  def mysqldump_cmd(db)
    "mysqldump --no-create-info --no-tablespaces --replace --single-transaction " \
      "--ignore-table=#{db[:database]}.schema_migrations " \
      "--ignore-table=#{db[:database]}.ar_internal_metadata " \
      "-h #{db[:host]} -u #{db[:user]} #{db[:database]}"
  end

  def mysql_import_cmd(db)
    "mysql -h #{db[:host]} -u #{db[:user]} #{db[:database]}"
  end

  def local_dump(db, path)
    system({"MYSQL_PWD" => db[:password]}, "#{mysqldump_cmd(db)} > #{path}") or
      abort "Fehler beim Dump."
    File.chmod(0o600, path)
  end

  def local_import(db, path)
    system({"MYSQL_PWD" => db[:password]}, "#{mysql_import_cmd(db)} < #{path}") or
      abort "Fehler beim Import."
  end

  PARSE_DB_URL_BASH = <<~'BASH'
    : "${DATABASE_URL:?DATABASE_URL not set in env_file}"
    _rest="${DATABASE_URL#*://}"
    _auth="${_rest%%@*}"
    _hostpath="${_rest#*@}"
    _user_enc="${_auth%%:*}"
    _pass_enc="${_auth#*:}"
    _hostport="${_hostpath%%/*}"
    _dbpath="${_hostpath#*/}"
    _db_enc="${_dbpath%%\?*}"
    DB_HOST="${_hostport%%:*}"
    _decode() { printf '%b' "${1//%/\x}"; }
    DB_USER=$(_decode "$_user_enc")
    DB_PASS=$(_decode "$_pass_enc")
    DB_NAME=$(_decode "$_db_enc")
  BASH

  def remote_dump(ssh, env_file, dump_path)
    run_remote ssh, <<~BASH
      set -eo pipefail
      source "#{env_file}"
      #{PARSE_DB_URL_BASH}
      MYSQL_PWD="$DB_PASS" mariadb-dump --no-create-info --no-tablespaces --replace --single-transaction \\
        --ignore-table="$DB_NAME.schema_migrations" \\
        --ignore-table="$DB_NAME.ar_internal_metadata" \\
        -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" > "#{dump_path}"
      chmod 600 "#{dump_path}"
    BASH
  end

  def remote_import(ssh, env_file, dump_path)
    run_remote ssh, <<~BASH
      set -eo pipefail
      source "#{env_file}"
      #{PARSE_DB_URL_BASH}
      MYSQL_PWD="$DB_PASS" mariadb -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" < "#{dump_path}"
    BASH
  end

  def scp_from_remote(ssh, remote, local) = sh!("scp #{Shellwords.shellescape("#{ssh}:#{remote}")} #{Shellwords.shellescape(local)}")
  def scp_to_remote(local, ssh, remote)   = sh!("scp #{Shellwords.shellescape(local)} #{Shellwords.shellescape("#{ssh}:#{remote}")}")

  def remove_local_file(path)
    File.delete(path) if File.exist?(path)
  end

  def remove_remote_file(ssh, path)
    system("ssh #{Shellwords.shellescape(ssh)} rm -f #{Shellwords.shellescape(path)}")
  end

  def run_remote(ssh, script)
    IO.popen(["ssh", ssh, "bash", "-l", "-s"], "w") { |io| io.write(script) }
    abort "Schritt fehlgeschlagen." unless $?.success?
  end

  def step(label)
    puts "#{label}..."
    yield
  end

  def sh!(cmd)
    system(cmd) or abort "Schritt fehlgeschlagen."
  end
end

namespace :db do
  desc "Pull data from remote stage, replacing local dev DB. Usage: STAGE=integration rails db:pull"
  task :pull => :environment do
    stage      = DbSync.require_stage!
    cfg        = DbSync.stage_credentials(stage)
    ssh_target = DbSync.ssh_target_for(stage)
    local_db   = DbSync.parse_db_url(ENV.fetch("DATABASE_URL"))
    dump_path  = "/tmp/#{DbSync.dump_filename(stage)}"

    begin
      DbSync.step("1/4 Dump auf #{stage} erstellen")   { DbSync.remote_dump(ssh_target, cfg[:env_file], dump_path) }
      DbSync.step("2/4 Dump nach lokal kopieren")      { DbSync.scp_from_remote(ssh_target, dump_path, dump_path) }
      DbSync.step("3/4 Dump in lokale DB importieren") { DbSync.local_import(local_db, dump_path) }
    ensure
      DbSync.step("4/4 Dump-Dateien aufräumen") do
        DbSync.remove_remote_file(ssh_target, dump_path)
        DbSync.remove_local_file(dump_path)
      end
    end

    puts "Done."
  end

  desc "Push local dev data to remote stage, replacing its DB. Usage: STAGE=integration rails db:push"
  task :push => :environment do
    stage      = DbSync.require_stage!
    DbSync.confirm_production!(stage)
    cfg        = DbSync.stage_credentials(stage)
    ssh_target = DbSync.ssh_target_for(stage)
    local_db   = DbSync.parse_db_url(ENV.fetch("DATABASE_URL"))
    dump_path  = "/tmp/#{DbSync.dump_filename('dev')}"

    begin
      DbSync.step("1/4 Dump lokal erstellen")          { DbSync.local_dump(local_db, dump_path) }
      DbSync.step("2/4 Dump nach #{stage} kopieren")   { DbSync.scp_to_remote(dump_path, ssh_target, dump_path) }
      DbSync.step("3/4 Dump auf #{stage} importieren") { DbSync.remote_import(ssh_target, cfg[:env_file], dump_path) }
    ensure
      DbSync.step("4/4 Dump-Dateien aufräumen") do
        DbSync.remove_local_file(dump_path)
        DbSync.remove_remote_file(ssh_target, dump_path)
      end
    end

    puts "Done."
  end
end
