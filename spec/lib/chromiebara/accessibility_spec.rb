module Chromiebara
  RSpec.describe Accessibility, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    def find_focused_node(node)
      return node if node[:focused]

      node.fetch(:children, []).each do |child|
        focused_child = find_focused_node child
        return focused_child unless focused_child.nil?
      end
      nil
    end

    it 'returns accessibility tree' do
      await page.goto server.domain + 'accessibility.html'
      expected = {
        role: 'WebArea',
        name: 'Accessibility Test',
        children: [
          { role: 'text', name: 'Hello World' },
          { role: 'heading', name: 'Inputs', level: 1 },
          { role: 'textbox', name: 'Empty input', focused: true },
          { role: 'textbox', name: 'readonly input', readonly: true },
          { role: 'textbox', name: 'disabled input', disabled: true },
          { role: 'textbox', name: 'Input with whitespace', value: '  ' },
          { role: 'textbox', name: '', value: 'value only' },
          { role: 'textbox', name: 'placeholder', value: 'and a value' },
          { role: 'textbox', name: 'placeholder', value: 'and a value', description: 'This is a description!' },
          { role: 'combobox', name: '', value: 'First Option', children: [
            { role: 'menuitem', name: 'First Option', selected: true },
            { role: 'menuitem', name: 'Second Option' }]
          }
        ]
      }
      expect(page.accessibility.snapshot).to eq expected
    end

    it 'should report uninteresting nodes' do
      await page.set_content "<textarea autofocus>hi</textarea>"

      expected = {
        role: 'textbox',
        name: '',
        value: 'hi',
        focused: true,
        multiline: true,
        children: [{
          role: 'GenericContainer',
          name: '',
          children: [{
            role: 'text', name: 'hi'
          }]
        }]
      }
      expect(find_focused_node(page.accessibility.snapshot interesting_only: false)).to eq expected
    end

    it 'returns roledescription' do
      await page.set_content '<div tabIndex=-1 aria-roledescription="foo">Hi</div>'
      snapshot = page.accessibility.snapshot
      expect(snapshot[:children][0][:roledescription]).to eq 'foo'
    end

    it ' returns orientation' do
      await page.set_content '<a href="" role="slider" aria-orientation="vertical">11</a>'
      snapshot = page.accessibility.snapshot
      expect(snapshot[:children][0][:orientation]).to eq 'vertical'
    end

    it 'returns autocomplete' do
      await page.set_content '<input type="number" aria-autocomplete="list" />'
      snapshot = page.accessibility.snapshot
      expect(snapshot[:children][0][:autocomplete]).to eq 'list'
    end

    it 'returns multiselectable' do
      await page.set_content '<div role="grid" tabIndex=-1 aria-multiselectable=true>hey</div>'
      snapshot = page.accessibility.snapshot
      expect(snapshot[:children][0][:multiselectable]).to eq true
    end

    it 'returns keyshortcuts' do
      await page.set_content '<div role="grid" tabIndex=-1 aria-keyshortcuts="foo">hey</div>'
      snapshot = page.accessibility.snapshot
      expect(snapshot[:children][0][:keyshortcuts]).to eq 'foo'
    end

    context 'filtering child of leaf nodes' do
      it 'should not report text nodes inside controls' do
        content = <<~HTML
        <div role="tablist">
          <div role="tab" aria-selected="true"><b>Tab1</b></div>
          <div role="tab">Tab2</div>
        </div>
        HTML
        await page.set_content content
        expected = {
          role: 'WebArea',
          name: '',
          children: [
            { role: 'tab', name: 'Tab1', selected: true },
            { role: 'tab', name: 'Tab2' }
          ]
        }
        expect(page.accessibility.snapshot).to eq expected
      end

      it 'rich text editable fields should have children' do
        pending 'broken not sure why'
        content = <<~HTML
        <div contenteditable="true">
          Edit this image: <img src="fakeimage.png" alt="my fake image">
        </div>
        HTML
        await page.set_content content

        expected = {
          role: 'GenericContainer',
          name: '',
          value: 'Edit this image: ',
          children: [
            { role: 'text', name: 'Edit this image:' },
            { role: 'img', name: 'my fake image' }
          ]
        }
        snapshot = page.accessibility.snapshot
        expect(snapshot[:children][0]).to eq expected
      end

      it 'rich text editable fields with role should have children' do
        pending 'broken not sure why'
        content = <<~HTML
        <div contenteditable="true" role='textbox'>
          Edit this image: <img src="fakeimage.png" alt="my fake image">
        </div>
        HTML
        await page.set_content content
        expected = {
          role: 'textbox',
          name: '',
          value: 'Edit this image: ',
          children: [
            { role: 'text', name: 'Edit this image:' },
            { role: 'img', name: 'my fake image' }
          ]
        }
        snapshot = page.accessibility.snapshot
        expect(snapshot[:children][0]).to eq expected
      end

      # TODO
      # // Firefox does not support contenteditable="plaintext-only".
      # !FFOX && describe('plaintext contenteditable', function() {
      #   it('plain text field with role should not have children', async function({page}) {
      #     await page.setContent(`
      #     <div contenteditable="plaintext-only" role='textbox'>Edit this image:<img src="fakeimage.png" alt="my fake image"></div>`);
      #     const snapshot = await page.accessibility.snapshot();
      #     expect(snapshot.children[0]).toEqual({
      #       role: 'textbox',
      #       name: '',
      #       value: 'Edit this image:'
      #     });
      #   });
      #   it('plain text field without role should not have content', async function({page}) {
      #     await page.setContent(`
      #     <div contenteditable="plaintext-only">Edit this image:<img src="fakeimage.png" alt="my fake image"></div>`);
      #     const snapshot = await page.accessibility.snapshot();
      #     expect(snapshot.children[0]).toEqual({
      #       role: 'GenericContainer',
      #       name: ''
      #     });
      #   });
      #   it('plain text field with tabindex and without role should not have content', async function({page}) {
      #     await page.setContent(`
      #     <div contenteditable="plaintext-only" tabIndex=0>Edit this image:<img src="fakeimage.png" alt="my fake image"></div>`);
      #     const snapshot = await page.accessibility.snapshot();
      #     expect(snapshot.children[0]).toEqual({
      #       role: 'GenericContainer',
      #       name: ''
      #     });
      #   });
      # });

      it 'non editable textbox with role and tabIndex and label should not have children' do
        content = <<~HTML
        <div role="textbox" tabIndex=0 aria-checked="true" aria-label="my favorite textbox">
          this is the inner content
          <img alt="yo" src="fakeimg.png">
        </div>
        HTML
        await page.set_content content
        expected = {
          role: 'textbox',
          name: 'my favorite textbox',
          value: 'this is the inner content '
        }
        snapshot = page.accessibility.snapshot
        expect(snapshot[:children][0]).to eq expected
      end

      it 'checkbox with and tabIndex and label should not have children' do
        content = <<~HTML
        <div role="checkbox" tabIndex=0 aria-checked="true" aria-label="my favorite checkbox">
          this is the inner content
          <img alt="yo" src="fakeimg.png">
        </div>
        HTML
        await page.set_content content
        expected = {
          role: 'checkbox',
          name: 'my favorite checkbox',
          checked: true
        }

        snapshot = page.accessibility.snapshot
        expect(snapshot[:children][0]).to eq expected
      end

      it 'checkbox without label should not have children' do
        content = <<~HTML
        <div role="checkbox" aria-checked="true">
          this is the inner content
          <img alt="yo" src="fakeimg.png">
        </div>
        HTML
        await page.set_content content
        expected = {
          role: 'checkbox',
          name: 'this is the inner content yo',
          checked: true
        }
        snapshot = page.accessibility.snapshot
        expect(snapshot[:children][0]).to eq expected
      end

      describe 'root option' do
        it 'should work a button' do
          await page.set_content "<button>My Button</button>"

          button = page.query_selector 'button'
          expect(page.accessibility.snapshot root: button).to eq(role: 'button', name: 'My Button')
        end

        it 'should work an input' do
          await page.set_content '<input title="My Input" value="My Value">'

          input = page.query_selector 'input'
          expect(page.accessibility.snapshot(root: input)).to eq(role: 'textbox', name: 'My Input', value: 'My Value')
        end

        it 'should work a menu' do
          content = <<~HTML
          <div role="menu" title="My Menu">
            <div role="menuitem">First Item</div>
            <div role="menuitem">Second Item</div>
            <div role="menuitem">Third Item</div>
          </div>
          HTML
          await page.set_content content

          menu = page.query_selector 'div[role="menu"]'
          expect(page.accessibility.snapshot(root: menu)).to eq({
            role: 'menu',
            name: 'My Menu',
            children: [
              { role: 'menuitem', name: 'First Item' },
              { role: 'menuitem', name: 'Second Item' },
              { role: 'menuitem', name: 'Third Item' }
            ]
          })
        end

        it 'should return null when the element is no longer in DOM' do
          await page.set_content "<button>My Button</button>"
          button = page.query_selector 'button'
          page.query_selector_evaluate_function 'button', 'button => button.remove()'
          expect(page.accessibility.snapshot(root: button)).to eq nil
        end

        it 'should support the interesting_only option' do
          await page.set_content "<div><button>My Button</button></div>"
          div = page.query_selector 'div'
          expect(page.accessibility.snapshot(root: div)).to eq nil
          expect(page.accessibility.snapshot(root: div, interesting_only: false)).to eq({
            role: 'GenericContainer',
            name: '',
            children: [ { role: 'button', name: 'My Button' } ] }
          )
        end
      end
    end
  end
end
