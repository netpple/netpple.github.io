#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a targets=(
  "${ROOT_DIR}/_layouts"
  "${ROOT_DIR}/_includes"
  "${ROOT_DIR}/_posts"
  "${ROOT_DIR}/_docs"
  "${ROOT_DIR}/pages"
)

matches="$(
  rg -n '%H:%m' "${targets[@]}" || true
)"

if [[ -n "${matches}" ]]; then
  echo "[fail] legacy date format token remains in source"
  printf '%s\n' "${matches}"
  exit 1
fi

missing_series_labels="$(
  ROOT_DIR="${ROOT_DIR}" ruby <<'RUBY'
require "yaml"
require "date"

root = ENV.fetch("ROOT_DIR")
missing = []

Dir[File.join(root, "_docs/**/*.md")].sort.each do |path|
  next if File.basename(path) == "index.md"

  content = File.read(path)
  front_matter = content.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n/m)
  relative_path = path.delete_prefix("#{root}/")

  unless front_matter
    missing << "#{relative_path} (missing front matter)"
    next
  end

  data = YAML.safe_load(front_matter[1], permitted_classes: [Date, Time], aliases: true) || {}
  label = data.is_a?(Hash) ? data["label"] : nil

  if label.nil? || label.to_s.strip.empty?
    missing << relative_path
  end
end

puts missing.join("\n")
RUBY
)"

if [[ -n "${missing_series_labels}" ]]; then
  echo "[fail] unlabeled series entry source files remain"
  printf '%s\n' "${missing_series_labels}"
  exit 1
fi

landing_pages_with_labels="$(
  ROOT_DIR="${ROOT_DIR}" ruby <<'RUBY'
require "yaml"
require "date"

root = ENV.fetch("ROOT_DIR")
invalid = []

Dir[File.join(root, "_docs/**/index.md")].sort.each do |path|
  content = File.read(path)
  front_matter = content.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n/m)
  relative_path = path.delete_prefix("#{root}/")

  unless front_matter
    invalid << "#{relative_path} (missing front matter)"
    next
  end

  data = YAML.safe_load(front_matter[1], permitted_classes: [Date, Time], aliases: true) || {}
  label = data.is_a?(Hash) ? data["label"] : nil

  next if label.nil? || label.to_s.strip.empty?

  invalid << "#{relative_path} (label: #{label})"
end

puts invalid.join("\n")
RUBY
)"

if [[ -n "${landing_pages_with_labels}" ]]; then
  echo "[fail] series landing source files must not define entry labels"
  printf '%s\n' "${landing_pages_with_labels}"
  exit 1
fi

echo "[pass] source format check"
