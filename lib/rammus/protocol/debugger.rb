module Rammus
  module Protocol
    module Debugger
      extend self

      # Continues execution until specific location is reached.
      #
      # @param location [Location] Location to continue to.
      #
      def continue_to_location(location:, target_call_frames: nil)
        {
          method: "Debugger.continueToLocation",
          params: { location: location, targetCallFrames: target_call_frames }.compact
        }
      end

      # Disables debugger for given page.
      #
      def disable
        {
          method: "Debugger.disable"
        }
      end

      # Enables debugger for the given page. Clients should not assume that the debugging has been
      # enabled until the result for this command is received.
      #
      # @param max_scripts_cache_size [Number] The maximum size in bytes of collected scripts (not referenced by other heap objects) the debugger can hold. Puts no limit if paramter is omitted.
      #
      def enable(max_scripts_cache_size: nil)
        {
          method: "Debugger.enable",
          params: { maxScriptsCacheSize: max_scripts_cache_size }.compact
        }
      end

      # Evaluates expression on a given call frame.
      #
      # @param call_frame_id [Callframeid] Call frame identifier to evaluate on.
      # @param expression [String] Expression to evaluate.
      # @param object_group [String] String object group name to put result into (allows rapid releasing resulting object handles using `releaseObjectGroup`).
      # @param include_command_line_api [Boolean] Specifies whether command line API should be available to the evaluated expression, defaults to false.
      # @param silent [Boolean] In silent mode exceptions thrown during evaluation are not reported and do not pause execution. Overrides `setPauseOnException` state.
      # @param return_by_value [Boolean] Whether the result is expected to be a JSON object that should be sent by value.
      # @param generate_preview [Boolean] Whether preview should be generated for the result.
      # @param throw_on_side_effect [Boolean] Whether to throw an exception if side effect cannot be ruled out during evaluation.
      # @param timeout [Runtime.timedelta] Terminate execution after timing out (number of milliseconds).
      #
      def evaluate_on_call_frame(call_frame_id:, expression:, object_group: nil, include_command_line_api: nil, silent: nil, return_by_value: nil, generate_preview: nil, throw_on_side_effect: nil, timeout: nil)
        {
          method: "Debugger.evaluateOnCallFrame",
          params: { callFrameId: call_frame_id, expression: expression, objectGroup: object_group, includeCommandLineAPI: include_command_line_api, silent: silent, returnByValue: return_by_value, generatePreview: generate_preview, throwOnSideEffect: throw_on_side_effect, timeout: timeout }.compact
        }
      end

      # Returns possible locations for breakpoint. scriptId in start and end range locations should be
      # the same.
      #
      # @param breakpoint_start [Location] Start of range to search possible breakpoint locations in.
      # @param breakpoint_end [Location] End of range to search possible breakpoint locations in (excluding). When not specified, end of scripts is used as end of range.
      # @param restrict_to_function [Boolean] Only consider locations which are in the same (non-nested) function as start.
      #
      def get_possible_breakpoints(breakpoint_start:, breakpoint_end: nil, restrict_to_function: nil)
        {
          method: "Debugger.getPossibleBreakpoints",
          params: { breakpoint_start: breakpoint_start, breakpoint_end: breakpoint_end, restrictToFunction: restrict_to_function }.compact
        }
      end

      # Returns source for the script with given id.
      #
      # @param script_id [Runtime.scriptid] Id of the script to get source for.
      #
      def get_script_source(script_id:)
        {
          method: "Debugger.getScriptSource",
          params: { scriptId: script_id }.compact
        }
      end

      # Returns stack trace with given `stackTraceId`.
      #
      def get_stack_trace(stack_trace_id:)
        {
          method: "Debugger.getStackTrace",
          params: { stackTraceId: stack_trace_id }.compact
        }
      end

      # Stops on the next JavaScript statement.
      #
      def pause
        {
          method: "Debugger.pause"
        }
      end

      # @param parent_stack_trace_id [Runtime.stacktraceid] Debugger will pause when async call with given stack trace is started.
      #
      def pause_on_async_call(parent_stack_trace_id:)
        {
          method: "Debugger.pauseOnAsyncCall",
          params: { parentStackTraceId: parent_stack_trace_id }.compact
        }
      end

      # Removes JavaScript breakpoint.
      #
      def remove_breakpoint(breakpoint_id:)
        {
          method: "Debugger.removeBreakpoint",
          params: { breakpointId: breakpoint_id }.compact
        }
      end

      # Restarts particular call frame from the beginning.
      #
      # @param call_frame_id [Callframeid] Call frame identifier to evaluate on.
      #
      def restart_frame(call_frame_id:)
        {
          method: "Debugger.restartFrame",
          params: { callFrameId: call_frame_id }.compact
        }
      end

      # Resumes JavaScript execution.
      #
      def resume
        {
          method: "Debugger.resume"
        }
      end

      # Searches for given string in script content.
      #
      # @param script_id [Runtime.scriptid] Id of the script to search in.
      # @param query [String] String to search for.
      # @param case_sensitive [Boolean] If true, search is case sensitive.
      # @param is_regex [Boolean] If true, treats string parameter as regex.
      #
      def search_in_content(script_id:, query:, case_sensitive: nil, is_regex: nil)
        {
          method: "Debugger.searchInContent",
          params: { scriptId: script_id, query: query, caseSensitive: case_sensitive, isRegex: is_regex }.compact
        }
      end

      # Enables or disables async call stacks tracking.
      #
      # @param max_depth [Integer] Maximum depth of async call stacks. Setting to `0` will effectively disable collecting async call stacks (default).
      #
      def set_async_call_stack_depth(max_depth:)
        {
          method: "Debugger.setAsyncCallStackDepth",
          params: { maxDepth: max_depth }.compact
        }
      end

      # Replace previous blackbox patterns with passed ones. Forces backend to skip stepping/pausing in
      # scripts with url matching one of the patterns. VM will try to leave blackboxed script by
      # performing 'step in' several times, finally resorting to 'step out' if unsuccessful.
      #
      # @param patterns [Array] Array of regexps that will be used to check script url for blackbox state.
      #
      def set_blackbox_patterns(patterns:)
        {
          method: "Debugger.setBlackboxPatterns",
          params: { patterns: patterns }.compact
        }
      end

      # Makes backend skip steps in the script in blackboxed ranges. VM will try leave blacklisted
      # scripts by performing 'step in' several times, finally resorting to 'step out' if unsuccessful.
      # Positions array contains positions where blackbox state is changed. First interval isn't
      # blackboxed. Array should be sorted.
      #
      # @param script_id [Runtime.scriptid] Id of the script.
      #
      def set_blackboxed_ranges(script_id:, positions:)
        {
          method: "Debugger.setBlackboxedRanges",
          params: { scriptId: script_id, positions: positions }.compact
        }
      end

      # Sets JavaScript breakpoint at a given location.
      #
      # @param location [Location] Location to set breakpoint in.
      # @param condition [String] Expression to use as a breakpoint condition. When specified, debugger will only stop on the breakpoint if this expression evaluates to true.
      #
      def set_breakpoint(location:, condition: nil)
        {
          method: "Debugger.setBreakpoint",
          params: { location: location, condition: condition }.compact
        }
      end

      # Sets instrumentation breakpoint.
      #
      # @param instrumentation [String] Instrumentation name.
      #
      def set_instrumentation_breakpoint(instrumentation:)
        {
          method: "Debugger.setInstrumentationBreakpoint",
          params: { instrumentation: instrumentation }.compact
        }
      end

      # Sets JavaScript breakpoint at given location specified either by URL or URL regex. Once this
      # command is issued, all existing parsed scripts will have breakpoints resolved and returned in
      # `locations` property. Further matching script parsing will result in subsequent
      # `breakpointResolved` events issued. This logical breakpoint will survive page reloads.
      #
      # @param line_number [Integer] Line number to set breakpoint at.
      # @param url [String] URL of the resources to set breakpoint on.
      # @param url_regex [String] Regex pattern for the URLs of the resources to set breakpoints on. Either `url` or `urlRegex` must be specified.
      # @param script_hash [String] Script hash of the resources to set breakpoint on.
      # @param column_number [Integer] Offset in the line to set breakpoint at.
      # @param condition [String] Expression to use as a breakpoint condition. When specified, debugger will only stop on the breakpoint if this expression evaluates to true.
      #
      def set_breakpoint_by_url(line_number:, url: nil, url_regex: nil, script_hash: nil, column_number: nil, condition: nil)
        {
          method: "Debugger.setBreakpointByUrl",
          params: { lineNumber: line_number, url: url, urlRegex: url_regex, scriptHash: script_hash, columnNumber: column_number, condition: condition }.compact
        }
      end

      # Sets JavaScript breakpoint before each call to the given function.
      # If another function was created from the same source as a given one,
      # calling it will also trigger the breakpoint.
      #
      # @param object_id [Runtime.remoteobjectid] Function object id.
      # @param condition [String] Expression to use as a breakpoint condition. When specified, debugger will stop on the breakpoint if this expression evaluates to true.
      #
      def set_breakpoint_on_function_call(object_id:, condition: nil)
        {
          method: "Debugger.setBreakpointOnFunctionCall",
          params: { objectId: object_id, condition: condition }.compact
        }
      end

      # Activates / deactivates all breakpoints on the page.
      #
      # @param active [Boolean] New value for breakpoints active state.
      #
      def set_breakpoints_active(active:)
        {
          method: "Debugger.setBreakpointsActive",
          params: { active: active }.compact
        }
      end

      # Defines pause on exceptions state. Can be set to stop on all exceptions, uncaught exceptions or
      # no exceptions. Initial pause on exceptions state is `none`.
      #
      # @param state [String] Pause on exceptions mode.
      #
      def set_pause_on_exceptions(state:)
        {
          method: "Debugger.setPauseOnExceptions",
          params: { state: state }.compact
        }
      end

      # Changes return value in top frame. Available only at return break position.
      #
      # @param new_value [Runtime.callargument] New return value.
      #
      def set_return_value(new_value:)
        {
          method: "Debugger.setReturnValue",
          params: { newValue: new_value }.compact
        }
      end

      # Edits JavaScript source live.
      #
      # @param script_id [Runtime.scriptid] Id of the script to edit.
      # @param script_source [String] New content of the script.
      # @param dry_run [Boolean] If true the change will not actually be applied. Dry run may be used to get result description without actually modifying the code.
      #
      def set_script_source(script_id:, script_source:, dry_run: nil)
        {
          method: "Debugger.setScriptSource",
          params: { scriptId: script_id, scriptSource: script_source, dryRun: dry_run }.compact
        }
      end

      # Makes page not interrupt on any pauses (breakpoint, exception, dom exception etc).
      #
      # @param skip [Boolean] New value for skip pauses state.
      #
      def set_skip_all_pauses(skip:)
        {
          method: "Debugger.setSkipAllPauses",
          params: { skip: skip }.compact
        }
      end

      # Changes value of variable in a callframe. Object-based scopes are not supported and must be
      # mutated manually.
      #
      # @param scope_number [Integer] 0-based number of scope as was listed in scope chain. Only 'local', 'closure' and 'catch' scope types are allowed. Other scopes could be manipulated manually.
      # @param variable_name [String] Variable name.
      # @param new_value [Runtime.callargument] New variable value.
      # @param call_frame_id [Callframeid] Id of callframe that holds variable.
      #
      def set_variable_value(scope_number:, variable_name:, new_value:, call_frame_id:)
        {
          method: "Debugger.setVariableValue",
          params: { scopeNumber: scope_number, variableName: variable_name, newValue: new_value, callFrameId: call_frame_id }.compact
        }
      end

      # Steps into the function call.
      #
      # @param break_on_async_call [Boolean] Debugger will issue additional Debugger.paused notification if any async task is scheduled before next pause.
      #
      def step_into(break_on_async_call: nil)
        {
          method: "Debugger.stepInto",
          params: { breakOnAsyncCall: break_on_async_call }.compact
        }
      end

      # Steps out of the function call.
      #
      def step_out
        {
          method: "Debugger.stepOut"
        }
      end

      # Steps over the statement.
      #
      def step_over
        {
          method: "Debugger.stepOver"
        }
      end

      def breakpoint_resolved
        'Debugger.breakpointResolved'
      end

      def paused
        'Debugger.paused'
      end

      def resumed
        'Debugger.resumed'
      end

      def script_failed_to_parse
        'Debugger.scriptFailedToParse'
      end

      def script_parsed
        'Debugger.scriptParsed'
      end
    end
  end
end
