{a,div,tr,th,tbody} = React.DOM

compute.Instances = React.createClass

  getInitialState: ->
    references: null
    instances: @props.instances

  componentDidMount: ->
    @loadReferences()

  handleNewInstance:() ->
    @refs.newInstance.open()

  handleCreateInstance: (data) ->
    instances = @state.instances.slice()
    instances.unshift data
    @setState instances: instances

  handleDeleteInstance: (instance) ->
    instances = @state.instances.slice()
    index = instances.indexOf instance
    instances.splice index, 1
    @setState instances: instances

  handleUpdateInstance: (instance, data) ->
    index = @state.instances.indexOf instance
    instances = @state.instances
    instances[index] = data
    @setState instances: instances

  reloadInstance: (instance) ->
    @ajaxHelper().get "/#{instance.id}",
      success: (data, textStatus, jqXHR) =>
        if data.status==404
          @handleDeleteInstance(instance)
        else
          @handleUpdateInstance(instance, data.instance)
      error: ( jqXHR, textStatus, errorThrown)  =>
        console.log(errorThrown) if console



  showInstance:(instance) ->
    @refs.showInstance.open(instance)

  ajaxHelper: () ->
    unless @ajax
      @ajax = new AjaxHelper(@props.root_url)
    @ajax

  loadReferences: () ->
    return if @state.references
    @ajaxHelper().get '/references',
      success: (data, textStatus, jqXHR) =>
        @setState references: data.references
      error: ( jqXHR, textStatus, errorThrown)  =>
        alert(errorThrown)


  render: ->
    React.DOM.div
      className: 'instances-container'

      if @props.permissions.create
        # Modal Overlay for Creating Instance
        div null,
          div className: "toolbar",
            a className: "btn btn-primary btn-lg", href: "#", onClick: @handleNewInstance, 'Create new'
          React.createElement compute.NewInstance,
            ref: 'newInstance'
            references: @state.references
            handleCreateInstance: @handleCreateInstance
            ajaxHelper: @ajaxHelper()

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
              for instance in @state.instances
                React.createElement compute.Instance, key: instance.id, item: instance, references: @state.references, handleShow: @showInstance,
                reloadInstance: @reloadInstance, handleDeleteInstance: @handleDeleteInstance, ajax: @ajaxHelper()

      else
        'You are not authorized to view servers!'
