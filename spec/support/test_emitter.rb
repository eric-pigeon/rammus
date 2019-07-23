class TestEmitter
  include Rammus::EventEmitter

  def initialize
    super
  end

  def public_emit(event, data)
    emit event, data
  end
end
