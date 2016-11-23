{ div,form,textarea,h4,label,span,button,abbr,select,option } = React.DOM

compute.ShowInstance = React.createClass
  getInitialState: () ->
    instance: null

  open: (instance) ->
    @setState instance: instance

    @refs.modal.open()

  close: () -> @refs.modal.close()
  handleClose: () -> @setState @getInitialState()

  render: ->
    React.createElement ReactModal, ref: 'modal', onHidden: @handleClose,
      div className: 'modal-header',
        button type: "button", className: "close", "aria-label": "Close", onClick: @close,
          span "aria-hidden": "true", 'x'
        h4 className: 'modal-title', 'New Snapshot'

      div className: 'modal-body',
        if @state.instance
          @state.instance.name

      div className: 'modal-footer',
        button role: 'cancel', type: 'button', className: 'btn btn-default', onClick: @close, 'Cancel'
