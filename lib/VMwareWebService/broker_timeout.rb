module Timeout
  def timeout(sec, klass = nil)   #:yield: +sec+
    return yield(sec) if sec == nil or sec.zero?
    exception = klass || Class.new(ExitException)
    state_lock = Mutex.new
    state = :sleeping
    toid = Class.new.object_id
    $vim_log.debug "************** TIMEOUT(#{toid}) Enter"
    begin
      begin
        x = Thread.current
        y = Thread.start {
          begin
            sleep sec
          rescue => e
            state_lock.synchronize do
              if state == :sleeping
                state = :exception
                $vim_log.debug "************** TIMEOUT(#{toid}) state -> #{state}"
                x.raise e
              end
            end
          else
            state_lock.synchronize do
              if state == :sleeping
                state = :timeout
                $vim_log.debug "************** TIMEOUT(#{toid}) state -> #{state}"
                x.raise exception, "execution expired"
              end
            end
          end
        }
        rv = yield(sec)
        state_lock.synchronize do
          if state == :sleeping
            state = :returned_from_yield
            $vim_log.debug "************** TIMEOUT(#{toid}) state -> #{state}"
            return rv
          end
        end
      ensure
        state_lock.synchronize do
          if state == :sleeping || state == :returned_from_yield
            state = :killing
            $vim_log.debug "************** TIMEOUT(#{toid}) state -> #{state}"
            if y
              $vim_log.debug "************** TIMEOUT(#{toid}) Killing"
              y.kill
              y.join # make sure y is dead.
            end
          end
        end
        $vim_log.debug "************** TIMEOUT(#{toid}) Exit state = #{state}"
      end
    rescue exception => e
      rej = /\A#{Regexp.quote(__FILE__)}:#{__LINE__-4}\z/o
      (bt = e.backtrace).reject! {|m| rej =~ m}
      level = -caller(CALLER_OFFSET).size
      while THIS_FILE =~ bt[level]
        bt.delete_at(level)
        level += 1
      end
      raise if klass            # if exception class is specified, it
                                # would be expected outside.
      raise Error, e.message, e.backtrace
    end
  end

  module_function :timeout
end
