require "json"
require "set"
require "fileutils"

packages_json_path = ARGV[0]

def format_filename(string)
  string.gsub("/", "-").gsub("::", "/") + ".md"
end

PackageData = Struct.new(:name, :include_paths, :recursive_include, :files, :references, :constants, :external_references, :depend_package_names)

packages = JSON.parse(File.read(packages_json_path)).map do |row|
  PackageData.new(*row.values)
end

dependent = packages.each_with_object({}) do |package, obj|
  package.depend_package_names.each do |name|
    obj[name] ||= Set.new
    obj[name].add(package.name)
  end
end
dependent_package_names = dependent.transform_values { |v| v.to_a.sort }

top_100 = packages.sort_by { |pkg| -pkg.depend_package_names.size }.take(100). \
  map { |pkg| "- [#{pkg.name}](packages/#{format_filename(pkg.name)}) with #{pkg.depend_package_names.size} dependencies" }.join("\n")

md = <<~MARKDOWN
---
id: introduction
title: Introduction
slug: /
---

# Packages

## Top 100 packages by the num of depend package

#{ top_100 }

MARKDOWN

File.write("docs/index.md", md)
FileUtils.mkdir_p("docs/packages")

packages.each do |package|
  filename = format_filename(package.name)
  files = package.files.map { |f| "- #{f}" }.join("\n")
  depend_packages = package.depend_package_names.map do |n|
    "- [#{n}](#{format_filename(n)})"
  end.join("\n")

  dependent_packages = nil
  if dependent_package_names[package.name]
    dependent_packages = dependent_package_names[package.name].map do |n|
      "- [#{n}](#{format_filename(n)})"
    end.join("\n")
  end

  md = <<~MARKDOWN
  # #{package.name}

  ## Depend to

  #{ depend_packages }

  ## Depended by

  #{ dependent_packages ? dependent_packages : "This package isn't depended by any package." }

  ## Included files

  #{ files }

  MARKDOWN

  target_dir = File.dirname(filename)
  unless Dir.exist?(target_dir)
    FileUtils.mkdir_p(target_dir)
  end
  File.write("docs/packages/#{filename}", md)
end
