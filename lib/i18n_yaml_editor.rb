require "yaml"
require "sequel"

class I18nYamlEditor
  class << self
    attr_accessor :db
  end

  def self.setup_database
    self.db = Sequel.sqlite
    self.db.create_table :keys do
      primary_key :id
      String :key
      String :file
      String :locale
      String :text
    end
  end

  def self.flatten_hash hash, namespace=[], tree={}
    hash.each {|key, value|
      child_ns = namespace.dup << key
      if value.is_a?(Hash)
        flatten_hash value, child_ns, tree
      else
        tree[child_ns.join(".")] = value
      end
    }
    tree
  end

  def self.nest_hash hash
    result = {}
    hash.each {|key, value|
      sub_result = result
      keys = key.split(".")
      keys.each {|k|
        if keys.last == k
          sub_result[k.to_sym] = value
        else
          sub_result = (sub_result[k.to_sym] ||= {})
        end
      }
    }
    result
  end

  def self.startup path
    setup_database
    files = Dir[path + "/**/*.yml"]
    files.each {|file|
      yaml = YAML.load_file(file)
      keys = flatten_hash(yaml)
      keys.each {|key, text|
        locale = key.split(".").first
        db[:keys].insert(
          :key => key,
          :file => file,
          :locale => locale,
          :text => text
        )
      }
    }
  end
end

IYE = I18nYamlEditor