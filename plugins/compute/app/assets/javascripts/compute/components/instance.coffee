{a,tr,td,div,p,i,span,br,button,ul,li} = React.DOM

compute.Instance = React.createClass
  statics:
    NO_STATE: 0
    RUNNING: 1
    BLOCKED: 2
    PAUSED: 3
    SHUT_DOWN: 4
    SHUT_OFF: 5
    CRASHED: 6
    SUSPENDED: 7
    FAILED: 8
    BUILDING: 9


    powerStateLabel: (state) ->
      switch state
        when compute.Instance.RUNNING then "Running"
        when compute.Instance.BLOCKED then "Blocked"
        when compute.Instance.PAUSED then "Paused"
        when compute.Instance.SHUT_DOWN then "Shut down"
        when compute.Instance.SHUT_OFF then "Shut off"
        when compute.Instance.CRASHED then "Crashed"
        when compute.Instance.SUSPENDED then "Suspended"
        when compute.Instance.FAILED then "Failed"
        when compute.Instance.BUILDING then "Building"
        else 'Unknown'

    actionTargetStates:
      "stop": ["SHUTOFF","ERROR"]
      "start": ["ACTIVE","ERROR"]
      "terminate": ["DELETED"]
      "reboot": ["ACTIVE", "ERROR"]
      "suspend": ["SUSPENDED", "ERROR"]
      "pause": ["PAUSED", "ERROR"]
      "create": ["ACTIVE","ERROR","BUILDING"]


  getInitialState: ->
    target_state: null


  handleTerminate: (e) ->
    ReactConfirmDialog.ask 'Are you sure?',
      #validationTerm: @props.shareNetwork.name
      description: 'Would you like to terminate this server?'
      confirmLabel: 'Yes, delete it!'
    .then => @handleAction(e,"terminate")
    .fail -> null

  handleAction:(e,actionName) ->
    e.preventDefault()
    @setState target_state: compute.Instance.actionTargetStates[actionName]
    @props.ajax.put "/#{@props.item.id}/#{actionName}",
      complete: => @reload()

  reload: ->
    @props.reloadInstance(@props.item)

  componentDidMount: ->
    if compute.Instance.powerStateLabel(@getPowerState())=="Unknown"
      @setState target_state: compute.Instance.actionTargetStates["create"]
      setTimeout( @reload, 2000)

  componentWillUpdate: (nextProps, nextState) ->
    if @state.target_state
      if @state.target_state.indexOf(nextProps.item.status)>=0
        @setState target_state: null
      else
        setTimeout( @reload, 2000)

  getImageName: ->
    return (span className: 'spinner') unless (@props.references and @props.item.image)
    imageId = @props.item.image.id

    for image in @props.references.images
      return image.name if image.id==imageId
     "unknown"

  getFlavorName: ->
    return (span className: 'spinner') unless (@props.references and @props.item.flavor)
    flavorId = @props.item.flavor.id
    for flavor in @props.references.flavors
      return flavor.name if flavor.id==flavorId
    "unknown"

  renderIPs: () ->
    return (span className: 'spinner') unless @props.item.addresses

    for network_name, ip_values of @props.item.addresses
      div key: network_name,
        if ip_values and ip_values.length>0
          div className: "list-group borderless",
            for values in ip_values
              p className: "list-group-item-text", key: values["addr"],
                if values["OS-EXT-IPS:type"]=='floating'
                  i className: "fa fa-globe fa-fw", " "
                else if values["OS-EXT-IPS:type"]=='fixed'
                  i className: "fa fa-desktop fa-fw", null
                values["addr"]
                span className: "info-text", " "+values["OS-EXT-IPS:type"]

  getPowerState: ->
    @props.item['OS-EXT-STS:power_state']

  getTaskState: ->
    (@props.item['OS-EXT-STS:task_state'] || "").replace("_", " ")


  renderState:()->
    item = @props.item
    status = item.status || ""
    span (if item.fault then {"data-toggle": "tooltip", "data-placement": "left", title: item.fault["message"]} else null),
      span null, (if @getTaskState() then @getTaskState() else (status.charAt(0).toUpperCase() + status.slice(1).toLowerCase()) ) + ' '
      if item.fault
        i className: 'fa fa-info-circle'

  render: ->
    console.log "render instance #{@props.item.name}", @getPowerState(), @props.item.status, @getTaskState()
    tr null,
      td null,
        if @props.item.name
          a {href: '#', onClick: (e) => @props.handleShow(@props.item)}, @props.item.name
        else
          span className: 'spinner'
      td null,
        if @props.item.addresses then Object.keys(@props.item.addresses).join(', ') else span className: 'spinner'
      td className: "snug-nowrap", @renderIPs()
      td null, @getImageName()
      td null, @getFlavorName()
      td null, compute.Instance.powerStateLabel(@getPowerState())
      td style: {width: '140px'},
        span className: 'spinner' if @state.target_state
        @renderState()
      td { className: "snug" },
        if @props.item.permissions.delete or @props.item.permissions.update
          div { className: 'btn-group' },
            button { className: 'btn btn-default btn-sm dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', 'aria-expanded': true},
              span {className: 'fa fa-cog' }

            ul { className: 'dropdown-menu dropdown-menu-right', role: "menu" },
              if @props.item.permissions.get and @props.item.status=='ACTIVE'
                li null,
                  a target: '_blank', href: "#{@props.ajax.rootUrl}/#{@props.item.id}/console", "VNC Console"

              if @props.item.permissions.update and [compute.Instance.SUSPENDED,compute.Instance.PAUSED,compute.Instance.SHUT_DOWN,compute.Instance.SHUT_OFF].indexOf(@getPowerState())>=0
                li null,
                  a { href: '#', onClick: (e) => @handleAction(e,'start') }, 'Start'
              if @props.item.permissions.update and @getPowerState()==compute.Instance.RUNNING
                li null,
                  a { href: '#', onClick: (e) => @handleAction(e,'stop') }, 'Stop'
              if @props.item.permissions.update and @getPowerState()==compute.Instance.RUNNING
                li null,
                  a { href: '#', onClick: (e) => @handleAction(e,'reboot') }, 'Reboot'
#              if @props.item.permissions.update and @getPowerState()==compute.Instance.RUNNING
#                li null,
#                  a { href: '#', onClick: (e) => @handleAction(e,'pause') }, 'Pause'
              if @props.item.permissions.update and @getPowerState()==compute.Instance.RUNNING
                li null,
                  a { href: '#', onClick: (e) => @handleAction(e,'suspend') }, 'Suspend'
              if @props.item.permissions.delete
                li { className: 'divider'}, null
              if @props.item.permissions.delete
                li null,
                  a { href: '#', onClick: @handleTerminate }, 'Terminate'

