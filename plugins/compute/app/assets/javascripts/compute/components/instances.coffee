{a,div,tr,th,tbody} = React.DOM

compute.Instances = React.createClass
  handleNewInstance:() ->
    alert "new"

  showInstance:(instance) ->
    @refs.showInstance.open(instance)

  render: ->
    React.DOM.div
      className: 'instances-container'

      if @props.permissions.create
        # Modal Overlay for Creating Instance
        div className: "toolbar",
          a className: "btn btn-primary btn-lg", href: "#", onClick: @handleNewInstance, 'Create new'

      if @props.permissions.list
        div null,
          React.createElement compute.ShowInstance,
            ref: 'showInstance'

          React.DOM.table
            className: 'table instances'
            React.DOM.thead null,
              React.DOM.tr null,
                React.DOM.th null, 'Name'
                React.DOM.th null, 'Network'
                React.DOM.th null, 'IPs'
                React.DOM.th null, 'OS'
                React.DOM.th null, 'Size'
                React.DOM.th null, 'Power state'
                React.DOM.th null, 'Status'
                React.DOM.th
                  className: 'snug', null
            React.DOM.tbody null,
              for instance in @props.instances
                React.createElement compute.Instance, key: instance.id, item: instance, images: @props.images, flavors: @props.flavors, handleShow: @showInstance
      else
        'You are not authorized to view servers!'
