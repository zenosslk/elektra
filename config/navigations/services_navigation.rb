# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  #navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  navigation.active_leaf_class = 'nav-active-leaf'

  # Specify if item keys are added to navigation items as id. Defaults to true
  # navigation.autogenerate_item_ids = true

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  #navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that
  # will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  #navigation.name_generator = Proc.new {|name, item| "<span>#{name}</span>"}

  # Specify if the auto highlight feature is turned on (globally, for the whole navigation). Defaults to true
  # navigation.auto_highlight = true

  # Specifies whether auto highlight should ignore query params and/or anchors when
  # comparing the navigation items with the current URL. Defaults to true
  #navigation.ignore_query_params_on_auto_highlight = true
  #navigation.ignore_anchors_on_auto_highlight = true

  # If this option is set to true, all item names will be considered as safe (passed through html_safe). Defaults to false.
  #navigation.consider_item_names_as_safe = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>if: -> { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>unless: -> { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>.
    #
    primary.item :compute, 'Compute', nil, html: {class: "fancy-nav-header", 'data-icon': "compute-icon"},
    if: -> {services.available?(:compute,:instances) or services.available?(:image,:os_images) or plugin_available?(:block_storage)} do |compute_nav|
      compute_nav.item :instances, 'Servers', -> {plugin('compute').instances_path}, if: -> { services.available?(:compute,:instances) }, highlights_on: Proc.new { params[:controller][/compute\/instances/] }
      compute_nav.item :block_storage, 'Volumes & Snapshots', -> {plugin('block_storage').volumes_path}, if: -> { plugin_available?(:block_storage) }, highlights_on: Proc.new { params[:controller][/block_storage/] }
      compute_nav.item :images, 'Images', -> {plugin('image').os_images_path}, if: -> { services.available?(:image,:os_images) }, highlights_on: Proc.new { params[:controller][/image\/.*/] }

      # compute_nav.dom_attributes = {class: 'content-list'}
    end


    primary.item :automation, 'Monsoon Automation', nil, html: {class: "fancy-nav-header", 'data-icon': "automation-icon" }, if: -> {services.available?(:automation,:nodes) } do |automation_nav|
      automation_nav.item :automation, 'Automation', -> {plugin('automation').nodes_path}, if: -> { services.available?(:automation,:nodes)}, highlights_on: Proc.new { params[:controller][/automation\/.*/] }

      # automation_nav.dom_attributes = {class: 'content-list'}
    end

   primary.item :hana, 'Bare Metal Data Processing & HANA', nil, html: {class: "fancy-nav-header", 'data-icon': "automation-icon" }, if: -> {services.available?(:bare_metal_hana,:nodes) } do |bare_metal_hana_nav|
     bare_metal_hana_nav.item :bare_metal_hana, 'HANA Servers', -> {plugin('bare_metal_hana').entry_path}, if: -> { services.available?(:bare_metal_hana,:nodes)}, highlights_on: Proc.new { params[:controller][/bare_metal_hana\/.*/] }
   end

    primary.item :api, 'API Access', nil, html: {class: "fancy-nav-header", 'data-icon': "api-icon"},
    if: -> {services.available?(:webconsole)} do |api_nav|
      api_nav.item :web_console, 'Web Console', -> { plugin('webconsole').root_path}, if: -> { services.available?(:webconsole)}, highlights_on: Proc.new { params[:controller][/webconsole\/.*/] }
    api_nav.item :api_endpoints, 'Api Endpoints for Clients', -> { plugin('identity').projects_api_endpoints_path}

      # api_nav.dom_attributes = {class: 'content-list'}
    end

    primary.item :access_management, 'Users & Authorizations', nil,
      html: {class: "fancy-nav-header", 'data-icon': "access_management-icon" },
      if: -> {services.available?(:inquiry,:inquiries) or plugin_available?(:authorization)} do |access_management_nav|
      access_management_nav.item :authorization, 'Project Members', -> {plugin('identity').projects_members_path}, if: -> { plugin_available?(:identity) and current_user.is_allowed?('identity:member_index')}, highlights_on: Proc.new { params[:controller][/members\/.*/] }
      access_management_nav.item :inquiries, 'Request', -> {plugin('inquiry').inquiries_path}, if: -> { services.available?(:inquiry,:inquiries) }, highlights_on: Proc.new { params[:controller][/inquiry\/.*/] }
      # access_management_nav.item :audits, 'Audit', '#'

      # access_management_nav.dom_attributes = {class: 'content-list'}
    end

    primary.item :networking,
                 'Networking & Loadbalancing',
                 nil,
                 html: { class: 'fancy-nav-header', 'data-icon': 'networking-icon' },
                 if: -> { plugin_available?(:networking) || plugin_available?(:loadbalancing) || plugin_available?(:dns_service) } do |networking_nav|
      networking_nav.item :networks,
                          'Networks',
                          -> { plugin('networking').networks_path },
                          if: -> { plugin_available?(:networking) },
                          highlights_on: %r{networking/networks.*}
      networking_nav.item :floating_ips,
                          'Floating IPs',
                          -> { plugin('networking').floating_ips_path },
                          if: -> { plugin_available?(:networking) },
                          highlights_on: %r{networking/floating_ips.*}
      networking_nav.item :security_groups,
                          'Security Groups',
                          -> { plugin('networking').security_groups_path },
                          if: -> { plugin_available?(:networking) },
                          highlights_on: %r{networking/security_groups.*}
      networking_nav.item :loadbalancing,
                          'Loadbalancing',
                          -> { plugin('loadbalancing').entry_path },
                          if: -> { plugin_available?(:loadbalancing) },
                          highlights_on: -> { params[:controller][%r{loadbalancing/.*}] }
      networking_nav.item :dns_service,
                          'DNS',
                          -> { plugin('dns_service').entry_path },
                          if: -> { plugin_available?(:dns_service) },
                          highlights_on: -> { params[:controller][%r{dns_service/.*}] }
    end

    primary.item :storage, 'Storage', nil, html: {class: "fancy-nav-header", 'data-icon': "storage-icon" },
      if: -> { services.available?(:object_storage,:containers) } do |storage_nav|
      storage_nav.item :shared_storage, 'Shared Object Storage', -> {plugin('object_storage').entry_path}, if: -> { services.available?(:object_storage,:containers) }, highlights_on: Proc.new { params[:controller][/object_storage\/.*/] }
      storage_nav.item :shared_filesystem_storage, 'Shared File System Storage', -> {plugin('shared_filesystem_storage').entry_path}, if: -> { services.available?(:shared_filesystem_storage) }, highlights_on: Proc.new { params[:controller][/shared_filesystem_storage\/.*/] }
    #   storage_nav.item :filesystem_storage, 'File System Storage', '#'
    #   storage_nav.item :repositories, 'Repositories', '#'
    #
    #   storage_nav.dom_attributes = {class: 'content-list'}
    end

    primary.item :monitoring, 'Monitoring, Logs, Cost Control', nil,
      html: {class: "fancy-nav-header", 'data-icon': "monitoring-icon" },
      if: -> {services.available?(:resource_management,:resources) or plugin_available?(:monitoring)} do |monitoring_nav|
      # monitoring_nav.item :metrics, 'Metrics', '#'
      # monitoring_nav.item :logs, 'Logs', '#'
      monitoring_nav.item :resource_management, 'Resource Management', -> {plugin('resource_management').resources_path}, if: -> { services.available?(:resource_management,:resources) }, highlights_on: Proc.new { params[:controller][/resource_management\/.*/] }
      monitoring_nav.item :monitoring,          'Monitoring',          -> {plugin('monitoring').entry_path},              if: -> { plugin_available?(:monitoring) }, highlights_on: Proc.new { params[:controller][/monitoring\/.*/] }

      # monitoring_nav.dom_attributes = {class: 'content-list'}
    end

    # primary.item :account, 'Account', nil, html: {class: "fancy-nav-header", 'data-icon': "fa fa-user fa-fw" } do |account_nav|
    #   account_nav.item :credentials, 'Credentials', plugin('identity').credentials_path, if: Proc.new { plugin_available?('identity') }
    #
    #   account_nav.dom_attributes = {class: 'content-list'}
    # end


    # Add an item which has a sub navigation (same params, but with block)
    # primary.item :key_2, 'name', url, options do |sub_nav|
    #   # Add an item to the sub navigation (same params again)
    #   sub_nav.item :key_2_1, 'name', url, options
    # end

    # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # Conditions are part of the options. They are evaluated in the context of the views,
    # thus you can use all the methods and vars you have available in the views.
    # primary.item :key_3, 'Admin', url, class: 'special', if: -> { current_user.admin? }
    # primary.item :key_4, 'Account', url, unless: -> { logged_in? }

    # you can also specify html attributes to attach to this particular level
    # works for all levels of the menu
    primary.dom_attributes = {class: 'fancy-nav', role: 'menu'}

    # You can turn off auto highlighting for a specific level
    #primary.auto_highlight = false
  end
end
