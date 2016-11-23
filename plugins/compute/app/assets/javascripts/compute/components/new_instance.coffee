{ div,form,textarea,h4,label,span,button,abbr,select,option,p,a,input,abbr } = React.DOM

compute.NewInstance = React.createClass
  displayName: "NewInstance"

  statics:
    formatBytes: (bytes, decimals) ->
      if bytes == 0
        return '0 Byte'
      k = 1000
    # or 1024 for binary
      dm = decimals or 3
      sizes = [
        'Bytes'
        'KB'
        'MB'
        'GB'
        'TB'
        'PB'
        'EB'
        'ZB'
        'YB'
      ]
      i = Math.floor(Math.log(bytes) / Math.log(k))
      parseFloat((bytes / k ** i).toFixed(dm)) + ' ' + sizes[i]

  getInitialState: ->
    errors: null
    loading: false
    instance: {}

  open: () ->
    @setState @getInitialState()
    @refs.modal.open()

  close: () -> @refs.modal.close()
  handleClose: () ->
    @setState @getInitialState()

  handleChange: (e) ->
    name = e.target.name
    value = if e.target.multiple
      values=[]
      for o in e.target.options
        values.push o.value if o.selected
      values
    else
      e.target.value
    instance = @state.instance
    instance["#{ name }"] = value
    @setState instance: instance

  valid: () ->
    @state.instance and
    @state.instance.name and
    @state.instance.security_groups and
    @state.instance.availability_zone_id and
    @state.instance.flavor_id and
    @state.instance.image_id and
    @state.instance.network_ids

  getCurrentValue: (key,defaultValue="") ->
    if @state.instance[key] then @state.instance[key] else defaultValue


  handleSubmit: (e) ->
    e.preventDefault()

    @setState loading: true

    @props.ajaxHelper.post '/',
      data: { server: @state.instance }
      success: (data, textStatus, jqXHR) =>
        @props.handleCreateInstance data
        @setState @getInitialState()
        @close()
      error: ( jqXHR, textStatus, errorThrown)  =>
        @setState errors: jqXHR.responseJSON
      complete: () =>
        @setState loading: false



  render: ->
    React.createElement ReactModal, ref: 'modal', onHidden: @handleClose,
      div className: 'modal-header',
        button type: "button", className: "close", "aria-label": "Close", onClick: @close,
          span "aria-hidden": "true", 'x'
        h4 className: 'modal-title', 'New Server'


      form className: 'form form-horizontal', onSubmit: @handleSubmit,

        div className: 'modal-body',
          unless @props.references
            span null,
              'Loading...'
              span className: 'spinner'
          else
            div null,
              if @state.errors
                React.createElement ReactFormErrors, errors: @state.errors, withNames: false

              if @props.references.keypairs is null or @props.references.keypairs.length==0
                p className: "alert alert-warning",
                  "There are no key pairs defined for your account. Without key pairs you can't access the server via ssh. You can define one "
                  a href: "#", 'here'


              if @props.references.private_networks is null or @props.references.private_networks.length==0
                if @props.permissions.create_private_network
                  a "data-modal": true, className: 'btn btn-primary', href:"#", 'New Private Network'
                else
                  'Please read '
                  a href:"#", target: '_blank', 'how to get a private network.'
              # name
              React.createElement ReactFormGroup, label: "Name", required: true, htmlFor: "name",
                input { className: 'string required form-control', type: "text", name: "name", onChange: @handleChange, value: @getCurrentValue('name')}

              # availbility zone
              React.createElement ReactFormGroup, label: "Availability zone", required: true, htmlFor: "availability_zone_id",
                select className: "select required form-control", name: "availability_zone_id", value: @getCurrentValue('availability_zone_id'), onChange: @handleChange,
                  option value: "", 'Please select'
                  for az in @props.references.availability_zones
                    option key: az.zoneName, value: az.zoneName, az.zoneName
              # security groups
              React.createElement ReactFormGroup, label: "Security groups", required: true, htmlFor: "security_groups",
                select multiple: "multiple", className: "select required form-control", value: @getCurrentValue('security_groups', []), name: "security_groups", onChange: @handleChange,
                  option value: "", ' '
                  for sg in @props.references.security_groups
                    option key: sg.id, value: sg.name, sg.name || sg.description
              # keypairs
              React.createElement ReactFormGroup, label: "Key Pair", required: false, htmlFor: "key_name",
                select className: "select optional form-control", name: "key_name", value: @getCurrentValue('key_name'), onChange: @handleChange,
                  option value: "", ' '
                  for kp in @props.references.keypairs
                    option key: kp.id, value: kp.id, kp.name
              # flavors
              React.createElement ReactFormGroup, label: "Flavor", required: true, htmlFor: "flavor_id",
                select className: "select required form-control", name: "flavor_id", value: @getCurrentValue('flavor_id'), onChange: @handleChange,
                  option value: "", 'Please select'
                  for f in @props.references.flavors
                    option key: f.id, value: f.id, "#{f.name}  (RAM: #{f.ram}MB, VCPUs: #{f.vcpus}, Disk: #{f.disk}GB)"
              # images
              React.createElement ReactFormGroup, label: "Image", required: true, htmlFor: "image_id",
                select className: "select required form-control", name: "image_id", value: @getCurrentValue('image_id'), onChange: @handleChange,
                  option value: "", 'Please select'
                  for i in @props.references.images
                    option key: i.id, value: i.id, "#{i.name} (Size: #{compute.NewInstance.formatBytes(i.size,2)}, Format: #{i.disk_format})"
              # private network
              React.createElement ReactFormGroup, label: "Private Network", required: true, htmlFor: "network_ids",
                select className: "select required form-control", name: "network_ids", value: @getCurrentValue('network_ids'), onChange: @handleChange,
                  option value: "", 'Please select'
                  for n in @props.references.private_networks
                    option key: n.id, value: n.id, "#{n.name} ( #{n.mtu} )"
              # user data
              React.createElement ReactFormGroup, label: "User Data", required: false, htmlFor: "user_data",
                textarea { className: 'text optional form-control', name: "user_data", onChange: @handleChange, value: @getCurrentValue('user_data')}

        div className: 'modal-footer',
          button role: 'cancel', type: 'button', className: 'btn btn-default', onClick: @close, 'Cancel'
          React.createElement ReactModal.SubmitButton, label: "Create", loading: @state.loading, disabled: !@valid()