module TreeNode
  class AssignedServerRole < Node
    set_attributes(:title, :image, :klass) do
      title = @options[:tree] == :servers_by_role_tree ?
          "<strong>#{_('Server')}: #{ERB::Util.html_escape(@object.name)} [#{@object.id}]</strong>" :
          "<strong>Role: #{ERB::Util.html_escape(@object.server_role.description)}</strong>"

      if @object.master_supported?
        priority = case @object.priority
                   when 1
                     _("primary, ")
                   when 2
                     _("secondary, ")
                   else
                     ""
                   end
      end
      if @object.active? && @object.miq_server.started?
        image = '100/on.png'
        title += _(" (%{priority}active, PID=%{number})") % {:priority => priority, :number => @object.miq_server.pid}
      else
        if @object.miq_server.started?
          image = '100/suspended.png'
          title += _(" (%{priority}available, PID=%{number})") % {:priority => priority, :number => @object.miq_server.pid}
        else
          image = '100/off.png'
          title += _(" (%{priority}unavailable)") % {:priority => priority}
        end
        klass = "red" if @object.priority == 1
      end
      if @options[:parent_kls] == "Zone" && @object.server_role.regional_role?
        klass = "opacity"
      end

      [title.html_safe, image, klass]
    end
  end
end
