require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res

    @params = route_params.merge!(req.params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    !!@already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise if already_built_response?
    res.status = 302
    res.location = url
    session.store_session(res)

    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise if already_built_response?
    res.write(content)
    res.header["content-type"] = content_type
    session.store_session(res)

    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.name.underscore
    main_path = File.dirname(__FILE__).split("/")[0..-2].join("/")
    main_path = File.join(main_path, "views", controller_name, "#{template_name}.html.erb")

    content = File.readlines(main_path).map(&:chomp).join

    erb_template = ERB.new(content).result(binding)

    render_content(erb_template, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
  end
end
