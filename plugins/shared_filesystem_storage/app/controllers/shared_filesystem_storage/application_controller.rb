# frozen_string_literal: true

module SharedFilesystemStorage
  # Application controller for SharedFilesystemStorage
  class ApplicationController < ::DashboardController
    # set policy context
    authorization_context 'shared_filesystem_storage'
    # enforce permission checks. This will automatically
    # investigate the rule name.
    authorization_required

    def show
      render inline: "<div id=\"shared_filesystem_storage_react_container\" " \
                     "data-url=#{services.shared_filesystem_storage.elektron.service_url('sharev2')}></div>",
             layout: true,
             content_type: 'text/html'
    end
  end
end
