#!/usr/bin/env bash
set -euo pipefail

ANNOUNCEMENTS_DIR="${1:-_announcements}"

if [[ ! -d "${ANNOUNCEMENTS_DIR}" ]]; then
  echo "[fail] announcements directory not found: ${ANNOUNCEMENTS_DIR}"
  exit 1
fi

ruby - "${ANNOUNCEMENTS_DIR}" <<'RUBY'
require "psych"
require "date"
require "time"

announcements_dir = ARGV.fetch(0)
required_fields = %w[title summary date cta_label cta_url pinned published]
string_fields = %w[title summary cta_label cta_url]
boolean_fields = %w[pinned published]
date_fields = %w[date expires_at]

failed = 0
total = 0
active_pinned = []

Dir.glob(File.join(announcements_dir, "*.md")).sort.each do |path|
  total += 1
  content = File.read(path)
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  unless match
    puts "[fail] #{path}"
    puts "       missing YAML front matter"
    failed += 1
    next
  end

  begin
    data = Psych.safe_load(match[1], permitted_classes: [Date, Time], aliases: false) || {}
  rescue Psych::SyntaxError => e
    puts "[fail] #{path}"
    puts "       invalid YAML front matter: #{e.message.lines.first.strip}"
    failed += 1
    next
  end

  errors = []

  required_fields.each do |field|
    value = data[field]
    if value.nil? || (value.respond_to?(:empty?) && value.empty?)
      errors << "missing required field `#{field}`"
    end
  end

  string_fields.each do |field|
    next unless data.key?(field)
    value = data[field]
    unless value.is_a?(String) && !value.strip.empty?
      errors << "`#{field}` must be a non-empty string"
      next
    end

    if field == "cta_url" && !value.include?("://") && !value.start_with?("/")
      errors << "`cta_url` must start with `/` or be an absolute URL"
    end
  end

  boolean_fields.each do |field|
    next unless data.key?(field)
    value = data[field]
    unless value == true || value == false
      errors << "`#{field}` must be a boolean"
    end
  end

  date_fields.each do |field|
    next unless data.key?(field) && !data[field].nil? && data[field].to_s.strip != ""
    begin
      Time.parse(data[field].to_s)
    rescue ArgumentError
      errors << "`#{field}` must be a valid date/time"
    end
  end

  if data["date"] && data["expires_at"]
    begin
      date_value = Time.parse(data["date"].to_s)
      expires_at_value = Time.parse(data["expires_at"].to_s)
      if expires_at_value <= date_value
        errors << "`expires_at` must be later than `date`"
      end
    rescue ArgumentError
      # Individual date parsing failures are already reported above.
    end
  end

  if data["published"] == true && data["pinned"] == true
    active_pinned << path
  end

  if errors.any?
    puts "[fail] #{path}"
    errors.each { |error| puts "       - #{error}" }
    failed += 1
  end
end

if total.zero?
  puts "[fail] no announcement markdown files found in #{announcements_dir}"
  exit 1
end

if active_pinned.length > 1
  puts "[fail] announcement content check failed: multiple published pinned announcements"
  active_pinned.each { |path| puts "       - #{path}" }
  failed += 1
end

if failed.positive?
  puts "[fail] announcement content check failed (#{failed}/#{total})"
  exit 1
end

puts "[pass] announcement content check: #{total} files"
RUBY
