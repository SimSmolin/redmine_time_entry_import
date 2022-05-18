
module RedmineTimeEntryImport
  class Hooks  < Redmine::Hook::ViewListener

    # Add stylesheets and javascripts links to all pages
    # (there's no way to add them on specific existing page)
    render_on :view_layouts_base_html_head, :partial => "redmine_time_entry_import/headers"

  end # class
end # module
