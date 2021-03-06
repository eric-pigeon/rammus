# frozen_string_literal: true

module Rammus
  RSpec.describe 'Dialog', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'should fire event on diaglod' do
      page.on :dialog do |dialog|
        expect(dialog.type).to eq :alert
        expect(dialog.default_value).to eq ''
        expect(dialog.message).to eq 'yo'
        dialog.accept
      end
      page.evaluate("alert('yo')").wait!
    end

    it 'should allow accepting prompts' do
      page.on :dialog do |dialog|
        expect(dialog.type).to eq :prompt
        expect(dialog.default_value).to eq 'yes.'
        expect(dialog.message) .to eq 'question?'
        dialog.accept 'answer!'
      end
      result = page.evaluate_function("() => prompt('question?', 'yes.')").value!
      expect(result).to eq 'answer!'
    end

    it 'should dismiss the prompt' do
      page.on(:dialog, &:dismiss)
      result = page.evaluate_function("() => prompt('question?')").value!
      expect(result).to eq nil
    end
  end
end
