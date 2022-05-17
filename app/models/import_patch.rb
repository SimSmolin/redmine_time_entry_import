# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2022  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
require 'csv'
require_dependency 'issue'

module ImportPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      define_method :extend_object, instance_method(:extend_object)
      alias_method :set_default_settings, :set_default_settings_with_patch
      alias_method :filepath, :filepath_with_patch
      alias_method :file_exists?, :file_exists_with_patch?
      alias_method :add_callback, :add_callback_with_patch
      alias_method :run, :run_with_patch
      alias_method :read_rows, :read_rows_with_patch
      alias_method :build_object, :build_object_with_patch

      def self.layout
        'base'
      end

      def self.menu_item
        nil
      end

      def self.authorized?(user, project)
        user.admin?
      end

    end
  end

  module InstanceMethods
    DATE_FORMATS = [
      '%Y-%m-%d',
      '%d/%m/%Y',
      '%m/%d/%Y',
      '%Y/%m/%d',
      '%d.%m.%Y',
      '%d-%m-%Y'
    ]
    AUTO_MAPPABLE_FIELDS = {}

    def set_default_settings_with_patch(options={})
      separator = lu(user, :general_csv_separator)
      encoding = lu(user, :general_csv_encoding)
      if file_exists?
        begin
          content = File.read(filepath, 256)

          separator = [',', ';'].max_by {|sep| content.count(sep)}

          guessed_encoding = Redmine::CodesetUtil.guess_encoding(content)
          encoding =
            (guessed_encoding && (
              Setting::ENCODINGS.detect {|e| e.casecmp?(guessed_encoding)} ||
                Setting::ENCODINGS.detect {|e| Encoding.find(e) == Encoding.find(guessed_encoding)}
            )) || lu(user, :general_csv_encoding)
        rescue => e
        end
      end
      wrapper = '"'

      date_format = lu(user, "date.formats.default", :default => "foo")
      date_format = DATE_FORMATS.first unless DATE_FORMATS.include?(date_format)

      self.settings.merge!(
        'separator' => separator,
        'wrapper' => wrapper,
        'encoding' => encoding,
        'date_format' => date_format,
        'notifications' => '0'
      )

      if options.key?(:project_id) && !options[:project_id].blank?
        # Do not fail if project doesn't exist
        begin
          project = Project.find(options[:project_id])
          self.settings.merge!('mapping' => {'project_id' => project.id})
        rescue; end
      end
    end

    # Returns the full path of the file to import
    # It is stored in tmp/imports with a random hex as filename
    def filepath_with_patch
      if filename.present? && /\A[0-9a-f]+\z/.match?(filename)
        File.join(Rails.root, "tmp", "imports", filename)
      else
        nil
      end
    end

    # Returns true if the file to import exists
    def file_exists_with_patch?
      filepath.present? && File.exist?(filepath)
    end

    # Adds a callback that will be called after the item at given position is imported
    def add_callback_with_patch(position, name, *args)
      settings['callbacks'] ||= {}
      settings['callbacks'][position] ||= []
      settings['callbacks'][position] << [name, args]
      save!
    end

    # Imports items and returns the position of the last processed item
    def run_with_patch(options={})
      max_items = options[:max_items]
      max_time = options[:max_time]
      current = 0
      imported = 0
      resume_after = items.maximum(:position) || 0
      interrupted = false
      started_on = Time.now

      read_items do |row, position|
        if (max_items && imported >= max_items) || (max_time && Time.now >= started_on + max_time)
          interrupted = true
          break
        end
        if position > resume_after
          item = items.build
          item.position = position
          item.unique_id = row_value(row, 'unique_id') if use_unique_id?

          if object = build_object(row, item)
            if object.save
              item.obj_id = object.id
            else
              item.message = object.errors.full_messages.join("\n")
            end
          end

          item.save!
          imported += 1

          extend_object(row, item, object) if object.persisted?
          do_callbacks(use_unique_id? ? item.unique_id : item.position, object)
        end
        current = position
      end

      if imported == 0 || interrupted == false
        if total_items.nil?
          update_attribute :total_items, current
        end
        update_attribute :finished, true
        remove_file
      end

      current
    end

    def read_rows_with_patch
      return unless file_exists?

      csv_options = {:headers => false}
      csv_options[:encoding] = settings['encoding'].to_s.presence || 'UTF-8'
      csv_options[:encoding] = 'bom|UTF-8' if csv_options[:encoding] == 'UTF-8'
      separator = settings['separator'].to_s
      csv_options[:col_sep] = separator if separator.size == 1
      wrapper = settings['wrapper'].to_s
      csv_options[:quote_char] = wrapper if wrapper.size == 1

      CSV.foreach(filepath, **csv_options) do |row|
        yield row if block_given?
      end
    end

    # Builds a record for the given row and returns it
    # To be implemented by subclasses
    def build_object_with_patch(row, item)
    end

    # Extends object with properties, that may only be handled after it's been
    # persisted.
    def extend_object(row, item, object)
    end

    def use_unique_id?
      mapping['unique_id'].present?
    end

  end
end
