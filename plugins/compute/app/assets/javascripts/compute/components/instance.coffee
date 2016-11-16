{tr,td,div,p,i,span,br} = React.DOM

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


  getImageName: ->
    imageId = @props.item.image.id
    for image in @props.images
      return image.name if image.id==imageId
     "unknown"

  getFlavorName: ->
    flavorId = @props.item.flavor.id
    for flavor in @props.flavors
      return flavor.name if flavor.id==flavorId
    "unknown"

  renderIPs: (item) ->
    for network_name, ip_values of item.addresses
      div key: ip_values,
        if ip_values and ip_values.length>0
          div className: "list-group borderless",
            for values in ip_values
              p className: "list-group-item-text", key: values,
                if values["OS-EXT-IPS:type"]=='floating'
                  i className: "fa fa-globe fa-fw", " "
                else if values["OS-EXT-IPS:type"]=='fixed'
                  i className: "fa fa-desktop fa-fw", null
                values["addr"]
                span className: "info-text", " "+values["OS-EXT-IPS:type"]

  getPowerState: ->
    @props.item['OS-EXT-STS:power_state']

  getPowerStateName: ->
    switch @getPowerState()
      when compute.Instance.RUNNING then "Running"
      when compute.Instance.BLOCKED then "Blocked"
      when compute.Instance.PAUSED then "Paused"
      when compute.Instance.SHUT_DOWN then "Shut down"
      when compute.Instance.SHUT_OFF then "Shut off"
      when compute.Instance.CRASHED then "Crashed"
      when compute.Instance.SUSPENDED then "Suspended"
      when compute.Instance.FAILED then "Failed"
      when compute.Instance.BUILDING then "Building"
      else 'No State'


  renderState:()->
    item = @props.item
    span (if item.fault then {"data-toggle": "tooltip", "data-placement": "left", title: item.fault["message"]} else null),
      span null, (if item.task_state then item.task_state else item.status) + ' '
      if item.fault
        i className: 'fa fa-info-circle'


  render: ->
    tr null,
      td null,
        a href: '#', (onClick: () => @props.handleShow(@props.item)), @props.item.name
      td null, Object.keys(@props.item.addresses).join(', ') if @props.item.addresses
      td className: "snug-nowrap", @renderIPs(@props.item)
      td null, @getImageName()
      td null, @getFlavorName()
      td null, @getPowerStateName()
      td null, @renderState()
      td null, ' '


