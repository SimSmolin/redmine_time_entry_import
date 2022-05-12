require 'redmine'

# require_relative 'helpers/custom_fields_helper_add'
# require_relative 'helpers/issues_helper_add'

require_relative 'app/controllers/imports_controller_patch'
require_relative 'app/models/time_entry_import'
require_relative 'app/models/user_import.rb'
require_relative 'app/helpers/imports_helper_patch.rb'
require_relative 'app/models/issue_import_patch.rb'

# ActionDispatch::Callbacks.to_prepare do                for Rails 5.0 -- deprecated TODO sim need testing
# ActiveSupport::Reloader.to_prepare do                  for Rails 5.1
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader

reloader.to_prepare do
  Import.send :include, ImportPatch
  IssueImport.send :include, IssueImportPatch
  ImportsController.send :include, ImportsControllerPatch
  ImportsHelper.send :include, ImportsHelperPatch
end

Redmine::Plugin.register :redmine_time_entry_import do
  name 'Import Time Entry records from file plugin'
  author 'Sergey Melnikov'
  description 'This is a plugin for Redmine. Allow control download time entry records from file'
  version '0.0.1'
  url 'https://github.com/SimSmolin/redmine_time_entry_import.git'
  author_url 'https://github.com/SimSmolin'

  project_module :time_tracking do
    permission :log_time_for_other_users, {}, :require => :loggedin
  end

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
