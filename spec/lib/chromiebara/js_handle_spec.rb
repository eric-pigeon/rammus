module Chromiebara
  RSpec.describe JSHandle, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#evaluate_handle_function' do
      it 'should work' do
        window_handle = await page.evaluate_handle_function '() => window'
        expect(window_handle).to be_a JSHandle
      end

      it 'should accept object handle as an argument' do
        navigator_handle = await page.evaluate_handle_function '() => navigator'
        text = await page.evaluate_function 'e => e.userAgent', navigator_handle
        expect(text).to include 'Mozilla'
      end

      it 'should accept object handle to primitive types' do
        a_handle = await page.evaluate_handle_function '() => 5'
        is_five = await page.evaluate_function 'e => Object.is(e, 5)', a_handle
        expect(is_five).to eq true
      end

      it 'should warn on nested object handles' do
        pending 'no idea'
        a_handle = await page.evaluate_handle_function '() => document.body'
        expect do
          await page.evaluate_handle_function "opts => opts.elem.querySelector('p')", { elem: a_handle }
        end.to raise_error(/Are you passing a nested JSHandle?/)
      end

      it 'should accept object handle to unserializable value' do
        a_handle = await page.evaluate_handle_function '() => Infinity'

        expect(await page.evaluate_function 'e => Object.is(e, Infinity)', a_handle).to eq true
      end

      it 'should use the same JS wrappers' do
        a_handle = await page.evaluate_handle_function '() => {
          window.FOO = 123;
          return window;
        }'
        expect(await page.evaluate_function 'e => e.FOO', a_handle).to eq 123
      end
    end

    describe 'JSHandle#get_property' do
      it 'should work' do
        a_handle = await page.evaluate_handle_function '() => ({
          one: 1,
          two: 2,
          three: 3
        })'
        two_handle = a_handle.get_property 'two'
        expect(two_handle.json_value).to eq 2
      end
    end

    describe 'JSHandle#json_value' do
      it 'should work' do
        a_handle = await page.evaluate_handle_function "() => ({foo: 'bar'})"
        json = a_handle.json_value
        expect(json).to eq 'foo' => 'bar'
      end

      it 'should not work with dates' do
        date_handle = await page.evaluate_handle_function "() => new Date('2017-09-26T00:00:00.000Z')"
        json = date_handle.json_value
        expect(json).to eq({})
      end

      it 'should throw for circular objects' do
        window_handle = await page.evaluate_handle 'window'
        expect { window_handle.json_value }.to raise_error(/Object reference chain is too long/)
      end
    end

    describe 'JSHandle.get_properties' do
      it 'should work' do
        a_handle = await page.evaluate_handle_function "() => ({
          foo: 'bar'
        })"
        properties = a_handle.get_properties
        foo = properties.fetch 'foo'
        expect(foo).to be_a JSHandle
        expect(foo.json_value).to eq 'bar'
      end

      it 'should return even non-own properties' do
        a_handle = await page.evaluate_handle_function "() => {
          class A {
            constructor() {
              this.a = '1';
            }
          }
          class B extends A {
            constructor() {
              super();
              this.b = '2';
            }
          }
          return new B();
        }"
        properties = a_handle.get_properties
        expect(properties.fetch('a').json_value).to eq '1'
        expect(properties.fetch('b').json_value).to eq '2'
      end
    end

    describe 'JSHandle#as_element' do
      it 'should work' do
        a_handle = await page.evaluate_handle_function '() => document.body'
        element = a_handle.as_element
        expect(element).to be_a ElementHandle
      end

      it 'should return null for non-elements' do
        a_handle = await page.evaluate_handle_function '() => 2'
        element = a_handle.as_element
        expect(element).to be nil
      end

      it 'should return ElementHandle for TextNodes' do
        await page.set_content '<div>ee!</div>'
        a_handle = await page.evaluate_handle_function "() => document.querySelector('div').firstChild"
        element = a_handle.as_element
        expect(element).to be_a ElementHandle
        expect(await page.evaluate_function 'e => e.nodeType === HTMLElement.TEXT_NODE', element).to eq true
      end

      it 'should work with nullified Node' do
        await page.set_content '<section>test</section>'
        await page.evaluate_function '() => delete Node'
        handle = await page.evaluate_handle_function "() => document.querySelector('section')"
        element = handle.as_element
        expect(element).not_to eq nil
      end
    end

    describe 'JSHandle#to_s' do
      it 'should work for primitives' do
        number_handle = await page.evaluate_handle_function '() => 2'
        expect(number_handle.to_s).to eq 'JSHandle:2'
        string_handle = await page.evaluate_handle_function "() => 'a'"
        expect(string_handle.to_s).to eq 'JSHandle:a'
      end

      it 'should work for complicated objects' do
        a_handle = await page.evaluate_handle_function "() => window"
        expect(a_handle.to_s).to eq 'JSHandle@object'
      end

      it 'should work with different subtypes' do
        expect((await page.evaluate_handle('(function(){})')).to_s).to eq 'JSHandle@function'
        expect((await page.evaluate_handle('12')).to_s).to eq 'JSHandle:12'
        expect((await page.evaluate_handle('true')).to_s).to eq 'JSHandle:true'
        # TODO
        #expect((await page.evaluate_handle('undefined')).to_s).to eq 'JSHandle:undefined'
        expect((await page.evaluate_handle('"foo"')).to_s).to eq 'JSHandle:foo'
        expect((await page.evaluate_handle('Symbol()')).to_s).to eq 'JSHandle@symbol'
        expect((await page.evaluate_handle('new Map()')).to_s).to eq 'JSHandle@map'
        expect((await page.evaluate_handle('new Set()')).to_s).to eq 'JSHandle@set'
        expect((await page.evaluate_handle('[]')).to_s).to eq 'JSHandle@array'
        # TODO
        # expect((await page.evaluate_handle('null')).to_s).to eq 'JSHandle:null'
        expect((await page.evaluate_handle('/foo/')).to_s).to eq 'JSHandle@regexp'
        expect((await page.evaluate_handle('document.body')).to_s).to eq 'JSHandle@node'
        expect((await page.evaluate_handle('new Date()')).to_s).to eq 'JSHandle@date'
        expect((await page.evaluate_handle('new WeakMap()')).to_s).to eq 'JSHandle@weakmap'
        expect((await page.evaluate_handle('new WeakSet()')).to_s).to eq 'JSHandle@weakset'
        expect((await page.evaluate_handle('new Error()')).to_s).to eq 'JSHandle@error'
        expect((await page.evaluate_handle('new Int32Array()')).to_s).to eq 'JSHandle@typedarray'
        expect((await page.evaluate_handle('new Proxy({}, {})')).to_s).to eq 'JSHandle@proxy'
      end
    end
  end
end
