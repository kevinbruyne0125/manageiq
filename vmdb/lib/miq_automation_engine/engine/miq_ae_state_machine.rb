module MiqAeEngine
  module MiqAeStateMachine
    def state_runnable?(f)
      return false unless (@workspace.root['ae_state'] == f['name'])
      return false unless (@workspace.root['ae_result'] == 'ok')
      return true
    end

    def initialize_state_maxima_metadata
      @workspace.root['ae_state_started'] = Time.now.utc.to_s  if @workspace.root['ae_state_started'].blank?
      @workspace.root['ae_state_retries'] = 0                  if @workspace.root['ae_state_retries'].blank?
    end

    def reset_state_maxima_metadata
      @workspace.root['ae_state_started'] = ''
      @workspace.root['ae_state_retries'] = 0
    end

    def increment_state_retries
      @workspace.root['ae_state_retries'] = @workspace.root['ae_state_retries'].to_i + 1
    end

    def enforce_state_maxima(f)
      now = Time.now.utc

      unless f['max_retries'].blank?
        if @workspace.root['ae_state_retries'].to_i > f['max_retries'].to_i
          raise "number of retries <#{@workspace.root['ae_state_retries']}> exceeded maximum of <#{f['max_retries']}>"
        end
      end

      unless f['max_time'].blank?
        ae_state_started = Time.parse(@workspace.root['ae_state_started'])
        if ae_state_started + f['max_time'].to_i_with_method <= now
          raise "time in state <#{now - ae_state_started} seconds> exceeded maximum of <#{f['max_time']}>"
        end
      end

    end

    def process_state_step_with_error_handling(f, step = nil)
      begin
        current_state = @workspace.root['ae_state']
        yield
        if @workspace.root['ae_next_state'].present? && current_state != @workspace.root['ae_next_state']
          $miq_ae_logger.warn("Skipping to state #{@workspace.root['ae_next_state']}") 
          @workspace.root['ae_result'] = 'skip' if step == 'on_entry'
        end
      rescue Exception => e
        error_message = "State=<#{f['name']}> running #{step} raised exception: <#{e.message}>"
        $miq_ae_logger.error error_message
        @workspace.root['ae_reason'] = error_message
        @workspace.root['ae_result'] = 'error'
      end
    end

    def process_state(f, message, args)
      Benchmark.current_realtime[:state_count]  += 1
      Benchmark.realtime_block(:state_time) do
        # Initialize the ae_state and ae_result variables, if blank
        @workspace.root['ae_state']  = f['name'] if @workspace.root['ae_state'].blank?
        @workspace.root['ae_result'] = 'ok'      if @workspace.root['ae_result'].blank?
        @workspace.root['ae_next_state'] = ''

        # Do not proceed further unless this state is runnable
        return unless state_runnable?(f)

        # Ensure the metadata to deal with retries and timeouts is initialized
        initialize_state_maxima_metadata

        # Process on_entry method
        process_state_step_with_error_handling(f, 'on_entry') { process_state_method(f, 'on_entry') }

        # Re-verify (in case on-entry method changed anything)
        process_state_step_with_error_handling(f) { process_state_relationship(f, message, args) } if state_runnable?(f)

        # Check the ae_result and set the next state appropriately
        if   @workspace.root['ae_result'] == 'ok'
          $miq_ae_logger.warn "Processed State =[#{f['name']}]"
        elsif @workspace.root['ae_result'] == 'skip'
          $miq_ae_logger.warn "Skipping State =[#{f['name']}]"
          return set_next_state(f, message)
        elsif @workspace.root['ae_result'] == 'retry'
          increment_state_retries
        elsif @workspace.root['ae_result'] == 'error'
          $miq_ae_logger.warn "Error in State=[#{f['name']}]"
          # Process on_error method

          return process_state_step_with_error_handling(f, 'on_error') { 
               process_state_method(f, 'on_error')
               if @workspace.root['ae_result'] == 'continue'
                 $miq_ae_logger.warn "Resetting Error in State=[#{f['name']}]"
                 @workspace.root['ae_result'] = 'ok'
                 set_next_state(f, message)
               end
          }
        end

        
        # Process on_exit method
        process_state_step_with_error_handling(f, 'on_exit') { process_state_method(f, 'on_exit') }
        set_next_state(f, message)
      end
    end

    def process_state_relationship(f, message, args)
      relationship = get_value(f, :aetype_relationship)
      unless relationship.blank? || relationship.lstrip[0,1] == '#'
        $miq_ae_logger.info "Processing State=[#{f['name']}]"
        @workspace.root['ae_state_step'] = 'main'
        enforce_state_maxima(f)
        process_relationship_raw(relationship, message, args, f['name'], f['collect'])
        raise MiqAeException::MiqAeDatastoreError, "empty relationship" unless @rels[f['name']]
        $miq_ae_logger.info "Processed  State=[#{f['name']}] with Result=[#{@workspace.root['ae_result']}]"
      end
    end

    def process_state_method(f, method_name)
      begin
        f[method_name].split(";").each do |method|
          method = substitute_value(method.strip)
          unless method.blank? || method.lstrip[0,1] == '#'
            $miq_ae_logger.info "In State=[#{f['name']}], invoking [#{method_name}] method=[#{method}]"
            @workspace.root['ae_status_state'] = method_name
            @workspace.root['ae_state']        = f['name']
            @workspace.root['ae_state_step'] = method_name
            process_method_raw(method)
          end
        end unless f[method_name].blank?
      rescue MiqAeException::MethodNotFound => err
        raise MiqAeException::MethodNotFound, "In State=[#{f['name']}], #{method_name} #{err.message}"
      end
    end

    def next_state(current, message)
      state_name = @workspace.root['ae_next_state'].present? ? @workspace.root['ae_next_state'] : current
      states = fields(message).collect { |f| f['name'] if f['aetype'] == 'state' }.compact
      validate_state(states)
      index  = states.index(state_name)
      return index.nil? ? nil : @workspace.root['ae_next_state'].blank? ? states[index+1] : states[index]
    end

    def set_next_state(f, message)
      if %w(skip ok).include?(@workspace.root['ae_result'])
        @workspace.root['ae_state'] = next_state(f['name'], message).to_s
        reset_state_maxima_metadata
        $miq_ae_logger.info "Next State=[#{@workspace.root['ae_state']}]"
        @workspace.root['ae_result'] = 'ok'
      end
    end

    def validate_state(states)
      next_state = @workspace.root['ae_next_state']
      if next_state.present? && states.exclude?(next_state)
        $miq_ae_logger.error "Next State=#{next_state} is invalid aborting state machine"
        raise MiqAeException::AbortInstantiation, "Invalid state specified <#{next_state}>"
      end 
    end

  end
end
