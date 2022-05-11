require 'redmine'
# require 'i18n'
# require 'role'

#
# require_relative 'helpers/custom_fields_helper_add'
# require_relative 'helpers/issues_helper_add'

require_relative 'app/controllers/imports_controller_patch'
require_relative 'app/models/time_entry_import'
require_relative 'app/models/user_import.rb'
require_relative 'app/helpers/imports_helper_patch.rb'
require_relative 'app/models/issue_import_patch.rb'
# require_relative 'lib/time_entry_query_patch'
# require_relative 'lib/query_patch'
# require_relative 'lib/timelog_controller_patch'
# require_relative 'lib/issues_controller_patch'
# require_relative 'lib/redmine/field_format_patch'
# require_relative 'lib/redmine/helpers_timereport_patch'
# require_relative 'lib/role_patch'

# ActionDispatch::Callbacks.to_prepare do                for Rails 5.0 -- deprecated TODO sim need testing
# ActiveSupport::Reloader.to_prepare do                  for Rails 5.1
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader

reloader.to_prepare do
  Import.send :include, ImportPatch
  IssueImport.send :include, IssueImportPatch
  ImportsController.send :include, ImportsControllerPatch
  ImportsHelper.send :include, ImportsHelperPatch
#   Query.send :include, QueryPatch
#   TimeEntryCustomField.send :include, TimeEntryCustomFieldPatch
#   TimeEntry.send :include, TimeEntryPatch
#   TimeEntryQuery.send :include, TimeEntryQueryPatch
#   TimelogController.send :include, TimelogControllerPatch
#   Redmine::FieldFormat::Base.send :include, RedmineFieldFormatPath
#   QueryCustomFieldColumn.send :include, QueryCustomFieldColumnPatch
#   Role.send :include, RolePatch
#   Issue.send :include, IssuePatch
#   IssueQuery.send :include, IssueQueryPatch
#   #  Redmine::Helpers::TimeReport.send :include, RedmineHelpersTimeReportPath
end

Redmine::Plugin.register :redmine_time_entry_import do
  name 'Import Time Entry records from file plugin'
  author 'Sergey Melnikov'
  description 'This is a plugin for Redmine. Allow control download time entry records from file'
  version '0.0.1'
  url 'https://github.com/SimSmolin/redmine_time_entry_import.git'
  author_url 'https://github.com/SimSmolin'

  # Rails.configuration.to_prepare do
  #   IssuesController.send(:helper, RedmineHrBulkTimeentryHelper)
  # end
  # Rails.configuration.to_prepare do
  #   TimelogController.send(:helper, CustomFieldsHelperAdd)
  #   IssuesController.send(:helper, CustomFieldsHelperAdd)
  #   IssuesController.send(:helper, IssuesHelperAdd)
  # end
  require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

  if Rails::VERSION::MAJOR >= 3
    ActionDispatch::Callbacks.to_prepare do
      require_dependency 'redmine_time_entry_import/hooks'
    end
  else
    Dispatcher.to_prepare :redmine_time_entry_import do
      require_dependency 'redmine_time_entry_import/hooks'
    end
  end

end
