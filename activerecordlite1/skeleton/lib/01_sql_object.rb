require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    if @columns
      return @columns
    else
      @columns = DBConnection.execute2(<<-SQL).first
        SELECT
          *
        from
          #{self.table_name}
      SQL
      @columns.map! do |name|
        name.to_sym
      end
    end
  end

  def self.finalize!
    self.columns.each do |name_of_column|
      # ||= self.attributes
      define_method("#{name_of_column}") do
        self.attributes[name_of_column]
      end

      define_method("#{name_of_column}=") do |value|
        self.attributes[name_of_column] = value
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    if @table_name.nil?
      # name = self.each_char
      # name.map! do |letter|
      #   if letter == letter.capitalize
      #     letter = "_" + letter
      #   end
      # end.join
      # self.name
      # self.p
      return @table_name = self.name.tableize
    end
    @table_name
  end

  def self.all
    # ...

    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      from
        #{self.table_name}

    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    # ...
    results.map do |result|
      # p result
      # byebug
      self.new(result)
    end

  end

  def self.find(id)
    # ...
    results = DBConnection.execute(<<-SQL,id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    parse_all(results).first
    # return nil if results.nil?
  end

  def initialize(params = {})
    # ...
    params.each do |key,value|
      key= key.to_s
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)

      self.send("#{key}=",value)
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map do |column|
      self.send("#{column}")
    end
  end

  def insert
    # ...

    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    question_marks = (["?"] * columns.count).join(", ")
    # debugger
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

    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    debugger
    question_marks = (["?"] * columns.count).join(", ")
    # debugger
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      UPDATE
        #{self.class.table_name} (#{col_names})
      SET
        (#{question_marks})
      WHERE
        id = ?

    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def save
    # ...
  end
end
