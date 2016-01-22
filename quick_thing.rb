class What
  include Enumerable
  def each
    yield "face"
    yield "hands"
    yield "feet"
  end
end

puts What.new.take(2)
# face
# hands
