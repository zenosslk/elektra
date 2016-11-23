class @AjaxHelper
  constructor: (rootUrl) ->
    @rootUrl = rootUrl

  @request: (url, method, options={}) ->
    $.ajax
      url: url
      method: method
      dataType: options['dataType'] || 'json'
      data: options['data']
      success: options['success']
      error: options['error']
      complete: ( jqXHR, textStatus) ->
        redirectToUrl = jqXHR.getResponseHeader('Location')
        if redirectToUrl # url is presented
          # Redirect to url
          currentUrl = encodeURIComponent(window.location.href)
          redirectToUrl = redirectToUrl.replace(/after_login=(.*)/g,"after_login=#{currentUrl}")
          window.location = redirectToUrl
        else
          options['complete'](jqXHR, textStatus) if options["complete"]

  get: (path,options={}) -> AjaxHelper.request(@rootUrl+path,'GET',options)
  post: (path,options={}) -> AjaxHelper.request(@rootUrl+path,'POST',options)
  put: (path,options={}) -> AjaxHelper.request(@rootUrl+path,'PUT',options)
  delete: (path,options={}) -> AjaxHelper.request(@rootUrl+path,'DELETE',options)


