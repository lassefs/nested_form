module NestedForm
  module BuilderMixin

    def set_block_for_add(association, &block)
      @block_for_add = {association => block}
    end

    # Adds a link to insert a new associated records. The first argument is the name of the link, the second is the name of the association.
    #
    #   f.link_to_add("Add Task", :tasks)
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_add(:tasks, :class => "add_task", :href => new_task_path) do %>
    #     Add Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_add(*args, &block)
      options = args.extract_options!.symbolize_keys
      association = args.pop
      options[:class] = [options[:class], "add_nested_fields"].compact.join(" ")
      options["data-association"] = association
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      @fields ||= {}
      @template.after_nested_form(association) do
        model_object = object.class.reflect_on_association(association).klass.new
        output = %Q[<script type="text/html" id="#{association}_fields_blueprint">].html_safe

        block_for_add = @block_for_add.is_a?(Hash) && @block_for_add[association].is_a?(Proc) ? @block_for_add[association] : @fields[association][:block]
        output << simple_fields_for(association, model_object, :child_index => "new_#{association}", :wrapper_tag => @fields[association][:wrapper_tag], :wrapper_class => @fields[association][:wrapper_class], &block_for_add)

        #output << simple_fields_for(association, model_object, :child_index => "new_#{association}", :wrapper_tag => @fields[association][:wrapper_tag], :wrapper_class => @fields[association][:wrapper_class], &@fields[association][:block])
        output.safe_concat('</script>')
        output
      end
      @template.link_to(*args, &block)
    end

    # Adds a link to remove the associated record. The first argment is the name of the link.
    #
    #   f.link_to_remove("Remove Task")
    #
    # You can pass HTML options in a hash at the end and a block for the content.
    #
    #   <%= f.link_to_remove(:class => "remove_task", :href => "#") do %>
    #     Remove Task
    #   <% end %>
    #
    # See the README for more details on where to call this method.
    def link_to_remove(*args, &block)
      options = args.extract_options!.symbolize_keys
      options[:class] = [options[:class], "remove_nested_fields"].compact.join(" ")
      args << (options.delete(:href) || "javascript:void(0)")
      args << options
      hidden_field(:_destroy) + @template.link_to(*args, &block)
    end

    def fields_for_with_nested_attributes(association_name, *args)
      # TODO Test this better
      block = args.pop || Proc.new { |fields| @template.render(:partial => "#{association_name.to_s.singularize}_fields", :locals => {:f => fields}) }

      convert = false
      if args[0].is_a?(Array)
        options = args[0].extract_options!
        convert = true
      else
        options = args.extract_options!
      end

      options[:wrapper_tag] ||= 'div'
      options[:wrapper_class] = ' ' << options[:wrapper_class] if options[:wrapper_class]

      if convert
        args[0] << options
      else
        args << options
      end

      @fields ||= {}
      @fields[association_name] = { :block => block, :wrapper_tag => options[:wrapper_tag], :wrapper_class => options[:wrapper_class] }
      super(association_name, *(args << block))
    end

    def fields_for_nested_model(name, object, options, block)
      output = %(<#{options[:wrapper_tag]} class="fields#{options[:wrapper_class]}">).html_safe
      output << super
      output.safe_concat("</#{options[:wrapper_tag]}>")
      output
    end
  end
end
