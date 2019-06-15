module Chromiebara
  RSpec.describe Frame, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Frame#execution_context' do
      it 'should work' do
        page.goto server.empty_page
        attach_frame page, 'frame1', server.empty_page
        expect(page.frames.length).to eq 2
        frame1, frame2 = page.frames
        context1 = frame1.execution_context
        context2 = frame2.execution_context
        expect(context1).not_to be_nil
        expect(context2).not_to be_nil
        expect(context1 != context2).to eq true
        expect(context1.frame).to eq frame1
        expect(context2.frame).to eq frame2

        context1.evaluate_function '() => window.a = 1'
        context2.evaluate_function '() => window.a = 2'
        a1 = context1.evaluate_function '() => window.a'
        a2 = context2.evaluate_function '() => window.a'
        expect(a1).to eq  1
        expect(a2).to eq 2
      end
    end

    describe 'Frame#evaluate_handle_function' do
      it 'should work' do
        page.goto server.empty_page
        main_frame = page.main_frame
        window_handle = main_frame.evaluate_handle_function '() => window'
        expect(window_handle).not_to be_nil
      end
    end

    describe 'Frame.evaluate_function' do
      it 'should throw for detached frames' do
        frame1 = attach_frame page, 'frame1', server.empty_page
        detach_frame page, 'frame1'
        expect { frame1.evaluate_function '() => 7 * 8' }
          .to raise_error(/Execution Context is not available in detached frame/)
      end
    end

    describe 'Frame Management' do
      it 'should handle nested frames' do
        page.goto server.domain + 'frames/nested-frames.html'
        expect(dump_frames(page.main_frame)).to eq([
          'http://localhost:<PORT>/frames/nested-frames.html',
          '    http://localhost:<PORT>/frames/two-frames.html (2frames)',
          '        http://localhost:<PORT>/frames/frame.html (uno)',
          '        http://localhost:<PORT>/frames/frame.html (dos)',
          '    http://localhost:<PORT>/frames/frame.html (aframe)'
        ]);
      end

      it 'should send events when frames are manipulated dynamically' do
        page.goto server.empty_page
        # validate frame_attached events
        attached_frames = []
        page.on :frame_attached, -> (frame) { attached_frames << frame }
        attach_frame page, 'frame1', './assets/frame.html'
        expect(attached_frames.length).to eq 1
        expect(attached_frames[0].url).to include '/assets/frame.html'

        # validate frame_navigated events
        navigated_frames = []
        page.on :frame_navigated, -> (frame) { navigated_frames << frame }
        navigate_frame page, 'frame1', './empty.html'
        expect(navigated_frames.length).to eq 1
        expect(navigated_frames[0].url).to eq server.empty_page

        # validate frame_detached events
        detached_frames = []
        page.on :frame_detached, -> (frame) { detached_frames << frame }
        detach_frame page, 'frame1'
        expect(detached_frames.length).to eq 1
        expect(detached_frames[0].is_detached?).to eq true
      end

      it 'should send "frame_navigated" when navigating on anchor URLs' do
        page.goto server.empty_page
        await Promise.all(
          wait_event(page, :frame_navigated),
          page.goto(server.empty_page + '#foo')
        )
        expect(page.url).to eq server.empty_page + '#foo'
      end

      it 'should persist main_frame on cross-process navigation' do
        page.goto server.empty_page
        main_frame = page.main_frame
        page.goto server.cross_process_domain + 'empty.html'
        expect(page.main_frame == main_frame).to eq true
      end

      it 'should not send attach/detach events for main frame' do
        has_events = false
        page.on :frame_attached, -> (frame) { has_events = true }
        page.on :frame_detached, -> (frame) { has_events = true }
        page.goto server.empty_page
        expect(has_events).to eq false
      end

      it 'should detach child frames on navigation' do
        attached_frames = []
        detached_frames = []
        navigated_frames = []
        page.on :frame_attached, -> (frame) { attached_frames << frame }
        page.on :frame_detached, -> (frame) { detached_frames << frame }
        page.on :frame_navigated, -> (frame) { navigated_frames << frame }
        page.goto server.domain + 'frames/nested-frames.html'
        expect(attached_frames.length).to eq 4
        expect(detached_frames.length).to eq 0
        expect(navigated_frames.length).to eq 5

        attached_frames = []
        detached_frames = []
        navigated_frames = []
        page.goto server.empty_page
        expect(attached_frames.length).to eq 0
        expect(detached_frames.length).to eq 4
        expect(navigated_frames.length).to eq 1
      end

      it 'should support framesets' do
        attached_frames = []
        detached_frames = []
        navigated_frames = []
        page.on :frame_attached, -> (frame) { attached_frames << frame }
        page.on :frame_detached, -> (frame) { detached_frames << frame }
        page.on :frame_navigated, -> (frame) { navigated_frames << frame }
        page.goto server.domain + 'frames/frameset.html'
        expect(attached_frames.length).to eq 4
        expect(detached_frames.length).to eq 0
        expect(navigated_frames.length).to eq 5

        attached_frames = []
        detached_frames = []
        navigated_frames = []
        page.goto server.empty_page
        expect(attached_frames.length).to eq 0
        expect(detached_frames.length).to eq 4
        expect(navigated_frames.length).to eq 1
      end

      it 'should report frame from-inside shadow DOM' do
        page.goto server.domain + 'shadow.html'
        function = <<~JAVASCRIPT
        async url => {
          const frame = document.createElement('iframe');
          frame.src = url;
          document.body.shadowRoot.appendChild(frame);
          await new Promise(x => frame.onload = x);
        }
        JAVASCRIPT
        page.evaluate_function function, server.empty_page
        expect(page.frames.length).to eq 2
        expect(page.frames[1].url).to eq server.empty_page
      end

      it 'should report frame.name' do
        attach_frame page, 'theFrameId', server.empty_page
        function = <<~JAVASCRIPT
        url => {
          const frame = document.createElement('iframe');
          frame.name = 'theFrameName';
          frame.src = url;
          document.body.appendChild(frame);
          return new Promise(x => frame.onload = x);
        }
        JAVASCRIPT
        page.evaluate_function function, server.empty_page
        expect(page.frames[0].name).to eq ''
        expect(page.frames[1].name).to eq 'theFrameId'
        expect(page.frames[2].name).to eq 'theFrameName'
      end

      it 'should report frame.parent' do
        attach_frame page, 'frame1', server.empty_page
        attach_frame page, 'frame2', server.empty_page
        expect(page.frames[0].parent_frame).to eq nil
        expect(page.frames[1].parent_frame).to eq page.main_frame
        expect(page.frames[2].parent_frame).to eq page.main_frame
      end

      it 'should report different frame instance when frame re-attaches' do
        frame1 = attach_frame page, 'frame1', server.empty_page
        page.evaluate_function "() => {
          window.frame = document.querySelector('#frame1');
          window.frame.remove();
        }"
        expect(frame1.is_detached?).to eq true
        frame2, _ = await Promise.all(
          wait_event(page, :frame_attached),
          page.evaluate_function("() => document.body.appendChild(window.frame)")
        )
        expect(frame2.is_detached?).to eq false
        expect(frame1).not_to eq frame2
      end

      def dump_frames(frame, indentation = '')
        description = frame.url.gsub(/:\d{4}\//, ':<PORT>/')
        description += " (#{frame.name})" unless frame.name == ''
        result = [indentation + description]
        frame.child_frames.each { |child| result.concat dump_frames(child, '    ' + indentation) }
        result
      end

      def navigate_frame(page, frame_id, url)
        function = <<~JAVASCRIPT
        function navigateFrame(frameId, url) {
          const frame = document.getElementById(frameId);
          frame.src = url;
          return new Promise(x => frame.onload = x);
        }
        JAVASCRIPT
        page.evaluate_function function, frame_id, url
      end
    end
  end
end
