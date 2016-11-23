{div,ul,li,label,abbr} = React.DOM
@ReactFormErrors = React.createClass
  getDefaultProperties: ->
    withNames: true

  render: ->
    if @props.errors
      div className: 'alert alert-error',
        ul null,
          for error,messages of @props.errors
            for message in messages
              if @props.withNames
                li null, "#{error}: #{message}"
              else
                li null, message

    else
      div null


@ReactFormGroup = React.createClass
  getDefaultProps: ->
    colClass: "col-sm-8"

  render: ->
    div className: "form-group select required",
      label className: "select required col-sm-4 control-label", htmlFor: @props.htmlFor,
        if @props.required then abbr(title: "required", '*')
        @props.label
      div className: @props.colClass,
        div className: "input-wrapper", @props.children