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
require_dependency 'imports_helper'

module ImportsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      define_method :import_title, instance_method(:import_title)
      define_method :import_partial_prefix, instance_method(:import_partial_prefix)
      alias_method :options_for_mapping_select, :options_for_mapping_select_with_patch
      alias_method :mapping_select_tag, :mapping_select_tag_with_patch
      alias_method :date_format_options, :date_format_options_with_patch
    end
  end

  module InstanceMethods

    def import_title
      l(:"label_import_#{import_partial_prefix}")
    end

    def import_partial_prefix
      @import.class.name.sub('Import', '').underscore.pluralize
    end

    def options_for_mapping_select_with_patch(import, field, options={})
      tags = "".html_safe
      blank_text = options[:required] ? "-- #{l(:actionview_instancetag_blank_option)} --" : "&nbsp;".html_safe
      tags << content_tag('option', blank_text, :value => '')
      tags << options_for_select(import.columns_options, import.mapping[field]) unless options[:only_values]
      if values = options[:values]
        tags << content_tag('option', '--', :disabled => true)
        tags << options_for_select(values.map {|text, value| [text, "value:#{value}"]}, import.mapping[field] || options[:default_value])
      end
      tags
    end

    def mapping_select_tag_with_patch(import, field, options={})
      name = "import_settings[mapping][#{field}]"
      select_tag name, options_for_mapping_select(import, field, options), :id => "import_mapping_#{field}",
                 :disabled => options[:disabled]
    end

    # Returns the options for the date_format setting
    def date_format_options_with_patch
      Import::DATE_FORMATS.map do |f|
        format = f.delete('%').gsub(/[dmY]/) do
          {'d' => 'DD', 'm' => 'MM', 'Y' => 'YYYY'}[$&]
        end
        [format, f]
      end
    end
  end
end