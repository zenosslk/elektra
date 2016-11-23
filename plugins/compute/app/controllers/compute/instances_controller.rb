module Compute
  class InstancesController < Compute::ApplicationController
    def index
      if @scoped_project_id
        @instances = services.compute.servers
        @instances.each do |instance|
          instance.permissions = {
            get: current_user.is_allowed?("compute:instance_get", target: {scoped_domain_name: @scoped_domain_name}),
            delete: current_user.is_allowed?("compute:instance_delete", target: {scoped_domain_name: @scoped_domain_name}),
            update: current_user.is_allowed?("compute:instance_update", target: {scoped_domain_name: @scoped_domain_name})
          }
        end

        @permissions = {
          list: current_user.is_allowed?("compute:instance_list"),
          create: current_user.is_allowed?("compute:instance_create", target: {scoped_domain_name: @scoped_domain_name}),
          create_private_network: current_user.is_allowed?("networking:network_private_create")
        }

        # get/calculate quota data
        cores = 0
        ram = 0
        @instances.each do |i|
          flavor = i.flavor_object
          if flavor
            cores += flavor.vcpus.to_i
            ram += flavor.ram.to_i
          end
        end

        @quota_data = services.resource_management.quota_data([
          {service_name: :compute, resource_name: :instances, usage: @instances.length},
          {service_name: :compute, resource_name: :cores, usage: cores},
          {service_name: :compute, resource_name: :ram, usage: ram}
        ])

      end

    end

    def references
      render json: { references: {
        flavors: services.compute.flavors,
        images: services.image.images,
        availability_zones: services.compute.availability_zones,
        security_groups: services.networking.security_groups(tenant_id: @scoped_project_id),
        private_networks: (services.networking.project_networks(@scoped_project_id).delete_if { |n| n.attributes["router:external"]==true } if services.networking.available?),
        keypairs: services.compute.keypairs.collect { |kp| Hashie::Mash.new({id: kp.name, name: kp.name}) }
      }}
    end

    def console
      @instance = services.compute.find_server(params[:id])
      @console = services.compute.vnc_console(params[:id])
      respond_to do |format|
        format.html { render action: :console, layout: 'compute/console' }
        format.json { render json: {url: @console.url} }
      end
    end

    # update instance table row (ajax call)
    def update_item
      @instance = services.compute.find_server(params[:id]) rescue nil
      @target_state = params[:target_state]

      respond_to do |format|
        format.js do
          if @instance and @instance.power_state.to_s!=@target_state
            @instance.task_state||=task_state(@target_state)
          end
        end
      end
    end

    def create
      @instance = services.compute.new_server
      params[:server][:security_groups] = (params[:server][:security_groups] || {}).delete_if { |sg| sg.empty? }
      @instance.attributes=params[@instance.model_name.param_key]

      @instance.network_ids = [@instance.network_ids] unless @instance.network_ids.is_a?(Array)
      @instance.network_ids = @instance.network_ids.collect{|id| {id: id}}

      if @instance.save
        @instance = services.compute.find_server(@instance.id)

        @instance.permissions = {
          get: current_user.is_allowed?("compute:instance_get", target: {scoped_domain_name: @scoped_domain_name}),
          delete: current_user.is_allowed?("compute:instance_delete", target: {scoped_domain_name: @scoped_domain_name}),
          update: current_user.is_allowed?("compute:instance_update", target: {scoped_domain_name: @scoped_domain_name})
        }
        render json: @instance
      else
        render json: @instance.errors, status: :unprocessable_entity
      end
    end

    def show
      begin
        instance = services.compute.find_server(params[:id])

        if instance
          instance.permissions = {
            get: current_user.is_allowed?("compute:instance_get", target: {scoped_domain_name: @scoped_domain_name}),
            delete: current_user.is_allowed?("compute:instance_delete", target: {scoped_domain_name: @scoped_domain_name}),
            update: current_user.is_allowed?("compute:instance_update", target: {scoped_domain_name: @scoped_domain_name})
          }
        end
        render json: { instance: instance, status: 200 }

      rescue Core::ServiceLayer::Errors::ApiError => e
        if e.respond_to?(:type) and e.type=="NotFound"
          render json: {"error": e.message, status: 404}, status: :ok
        else
          render json: {"error": e.message}, status: :unprocessable_entity
        end
      rescue => e
        render json: {"error": e.message}, status: :unprocessable_entity
      end
    end

    def new_floatingip
      @instance = services.compute.find_server(params[:id])
      collect_available_ips

      @floating_ip = Networking::FloatingIp.new(nil)
    end

    def attach_floatingip
      @instance_port = services.networking.ports(device_id: params[:id]).first
      @floating_ip = Networking::FloatingIp.new(nil, params[:floating_ip])

      success = begin
        @floating_ip = services.networking.attach_floatingip(params[:floating_ip][:ip_id], @instance_port.id)
        if @floating_ip.port_id
          true
        else
          false
        end
      rescue => e
        @floating_ip.errors.add('message', e.message)
        false
      end

      if success
        audit_logger.info(current_user, "has attached", @floating_ip, "to instance", params[:id])

        respond_to do |format|
          format.html { redirect_to instances_url }
          format.js {
            @instance = services.compute.find_server(params[:id])
            addresses = @instance.addresses[@instance.addresses.keys.first]
            addresses ||= []
            addresses << {
                "addr" => @floating_ip.floating_ip_address,
                "OS-EXT-IPS:type" => "floating"
            }
            @instance.addresses[@instance.addresses.keys.first] = addresses
          }
        end
      else
        collect_available_ips
        render action: :new_floatingip
      end
    end

    def detach_floatingip
      begin
        floating_ips = services.networking.project_floating_ips(@scoped_project_id, floating_ip_address: params[:floating_ip]) rescue []
        @floating_ip = services.networking.detach_floatingip(floating_ips.first.id)
      rescue => e
        flash.now[:error] = "Could not detach Floating IP. Error: #{e.message}"
      end

      respond_to do |format|
        format.html {
          sleep(3)
          redirect_to instances_url
        }
        format.js {
          if @floating_ip and @floating_ip.port_id.nil?
            @instance = services.compute.find_server(params[:id])
            addresses = @instance.addresses[@instance.addresses.keys.first]
            if addresses and addresses.is_a?(Array)
              addresses.delete_if { |values| values["OS-EXT-IPS:type"]=="floating" }
            end
            @instance.addresses[@instance.addresses.keys.first] = addresses
          end
        }
      end
    end

    def new_size
      @instance = services.compute.find_server(params[:id])
      @flavors = services.compute.flavors
    end

    def resize
      @close_modal=true
      execute_instance_action('resize', params[:server][:flavor_id])
    end

    def new_snapshot
    end

    def create_image
      @close_modal=true
      execute_instance_action('create_image', params[:snapshot][:name])
    end

    def confirm_resize
      execute_instance_action
    end

    def revert_resize
      execute_instance_action
    end

    def stop
      execute_instance_action
    end

    def start
      execute_instance_action
    end

    def pause
      execute_instance_action
    end

    def suspend
      execute_instance_action
    end

    def resume
      execute_instance_action
    end

    def reboot
      execute_instance_action
    end

    def terminate
      execute_instance_action
    end


    private

    def collect_available_ips
      @networks = {}
      @available_ips = []
      services.networking.project_floating_ips(@scoped_project_id).each do |fip|
        if fip.fixed_ip_address.nil?
          unless @networks[fip.floating_network_id]
            @networks[fip.floating_network_id] = services.networking.network(fip.floating_network_id)
          end
          @available_ips << fip
        end
      end
    end

    def execute_instance_action(action=action_name, options=nil)
      @instance = services.compute.find_server(params[:id]) rescue nil

      if @instance and (@instance.task_state || '')!='deleting'
        options.nil? ? @instance.send(action) : @instance.send(action, options)
      end

      head :ok
    end

  end
end
