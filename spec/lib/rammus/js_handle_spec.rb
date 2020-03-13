module Rammus
  RSpec.describe JSHandle, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#evaluate_handle_function' do
      it 'should work' do
        window_handle = page.evaluate_handle_function('() => window').value!
        expect(window_handle).to be_a JSHandle
      end

      it 'should accept object handle as an argument' do
        navigator_handle = page.evaluate_handle_function('() => navigator').value!
        text = page.evaluate_function('e => e.userAgent', navigator_handle).value!
        expect(text).to include 'Mozilla'
      end

      it 'should accept object handle to primitive types' do
        a_handle = page.evaluate_handle_function('() => 5').value!
        is_five = page.evaluate_function('e => Object.is(e, 5)', a_handle).value!
        expect(is_five).to eq true
      end

      it 'should warn on nested object handles' do
        pending 'todo'
        a_handle = page.evaluate_handle_function('() => document.body').value!
        expect do
          page.evaluate_handle_function("opts => opts.elem.querySelector('p')", { elem: a_handle }).value!
        end.to raise_error(/Are you passing a nested JSHandle?/)
      end

      it 'should accept object handle to unserializable value' do
        a_handle = page.evaluate_handle_function('() => Infinity').value!

        expect(page.evaluate_function('e => Object.is(e, Infinity)', a_handle).value!).to eq true
      end

      it 'should use the same JS wrappers' do
        a_handle = page.evaluate_handle_function('() => {
          window.FOO = 123;
          return window;
        }').value!
        expect(page.evaluate_function('e => e.FOO', a_handle).value!).to eq 123
      end
    end

    describe 'JSHandle#get_property' do
      it 'should work' do
        a_handle = page.evaluate_handle_function('() => ({
          one: 1,
          two: 2,
          three: 3
        })').value!
        two_handle = a_handle.get_property 'two'
        expect(two_handle.json_value).to eq 2
      end
    end

    describe 'JSHandle#json_value' do
      it 'should work' do
        a_handle = page.evaluate_handle_function("() => ({foo: 'bar'})").value!
        json = a_handle.json_value
        expect(json).to eq 'foo' => 'bar'
      end

      it 'should not work with dates' do
        date_handle = page.evaluate_handle_function("() => new Date('2017-09-26T00:00:00.000Z')").value!
        json = date_handle.json_value
        expect(json).to eq({})
      end

      it 'should throw for circular objects' do
        window_handle = page.evaluate_handle('window').value!
        expect { window_handle.json_value }.to raise_error(/Object reference chain is too long/)
      end
    end

    describe 'JSHandle.get_properties' do
      it 'should work' do
        a_handle = page.evaluate_handle_function("() => ({
          foo: 'bar'
        })").value!
        properties = a_handle.get_properties
        foo = properties.fetch 'foo'
        expect(foo).to be_a JSHandle
        expect(foo.json_value).to eq 'bar'
      end

      it 'should return even non-own properties' do
        a_handle = page.evaluate_handle_function("() => {
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
        }").value!
        properties = a_handle.get_properties
        expect(properties.fetch('a').json_value).to eq '1'
        expect(properties.fetch('b').json_value).to eq '2'
      end
    end

    describe 'JSHandle#as_element' do
      it 'should work' do
        a_handle = page.evaluate_handle_function('() => document.body').value!
        element = a_handle.as_element
        expect(element).to be_a ElementHandle
      end

      it 'should return null for non-elements' do
        a_handle = page.evaluate_handle_function('() => 2').value!
        element = a_handle.as_element
        expect(element).to be nil
      end

      it 'should return ElementHandle for TextNodes' do
        page.set_content('<div>ee!</div>').wait!
        a_handle = page.evaluate_handle_function("() => document.querySelector('div').firstChild").value!
        element = a_handle.as_element
        expect(element).to be_a ElementHandle
        expect(page.evaluate_function('e => e.nodeType === HTMLElement.TEXT_NODE', element).value!).to eq true
      end

      it 'should work with nullified Node' do
        page.set_content('<section>test</section>').wait!
        page.evaluate_function('() => delete Node').wait!
        handle = page.evaluate_handle_function("() => document.querySelector('section')").value!
        element = handle.as_element
        expect(element).not_to eq nil
      end
    end

    describe 'JSHandle#to_s' do
      it 'should work for primitives' do
        number_handle = page.evaluate_handle_function('() => 2').value!
        expect(number_handle.to_s).to eq 'JSHandle:2'
        string_handle = page.evaluate_handle_function("() => 'a'").value!
        expect(string_handle.to_s).to eq 'JSHandle:a'
      end

      it 'should work for complicated objects' do
        a_handle = page.evaluate_handle_function("() => window").value!
        expect(a_handle.to_s).to eq 'JSHandle@object'
      end

      it 'should work with different subtypes' do
        expect(page.evaluate_handle('(function(){})').value!.to_s).to eq 'JSHandle@function'
        expect(page.evaluate_handle('12').value!.to_s).to eq 'JSHandle:12'
        expect(page.evaluate_handle('true').value!.to_s).to eq 'JSHandle:true'
        # TODO
        #expect((await page.evaluate_handle('undefined')).to_s).to eq 'JSHandle:undefined'
        expect(page.evaluate_handle('"foo"').value!.to_s).to eq 'JSHandle:foo'
        expect(page.evaluate_handle('Symbol()').value!.to_s).to eq 'JSHandle@symbol'
        expect(page.evaluate_handle('new Map()').value!.to_s).to eq 'JSHandle@map'
        expect(page.evaluate_handle('new Set()').value!.to_s).to eq 'JSHandle@set'
        expect(page.evaluate_handle('[]').value!.to_s).to eq 'JSHandle@array'
        # TODO
        # expect((await page.evaluate_handle('null')).to_s).to eq 'JSHandle:null'
        expect(page.evaluate_handle('/foo/').value!.to_s).to eq 'JSHandle@regexp'
        expect(page.evaluate_handle('document.body').value!.to_s).to eq 'JSHandle@node'
        expect(page.evaluate_handle('new Date()').value!.to_s).to eq 'JSHandle@date'
        expect(page.evaluate_handle('new WeakMap()').value!.to_s).to eq 'JSHandle@weakmap'
        expect(page.evaluate_handle('new WeakSet()').value!.to_s).to eq 'JSHandle@weakset'
        expect(page.evaluate_handle('new Error()').value!.to_s).to eq 'JSHandle@error'
        expect(page.evaluate_handle('new Int32Array()').value!.to_s).to eq 'JSHandle@typedarray'
        expect(page.evaluate_handle('new Proxy({}, {})').value!.to_s).to eq 'JSHandle@proxy'
      end
    end
  end
end
