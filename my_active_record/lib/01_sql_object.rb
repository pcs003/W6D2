require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns
    all_rows = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        ("#{table_name}")
    SQL

    @columns = all_rows.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}") do
        self.attributes[column]
      end
      define_method("#{column}=") do |val = nil|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    if table_name
      @table_name = table_name
    else
      @table_name = self.to_s.tableize
    end
  end

  def self.table_name
    if @table_name.nil?
      self.to_s.tableize
    else
      @table_name
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        ("#{table_name}")
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |row_hash|
      self.new(row_hash)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        ("#{table_name}")
      WHERE
        id = ?
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    @table_name = nil
    params.each do |key, val|
      attr_name = key.to_sym
      if self.class.columns.include?(attr_name)
        send("#{attr_name}=", val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
    # ...
  end

  def attributes
    @attributes = {} unless @attributes
    @attributes
  end

  def attribute_values
    self.class.columns.map { |col_name| send(col_name) }

  end

  def insert
    col_names = self.class.columns.drop(1).map(&:to_s).join(",")
    question_marks = Array.new(self.class.columns.length - 1, "?").join(",")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
