# file: dynamic.rb
class Dynamic
end

%i[foo bar].each do |name|
  Dynamic.define_method(name) do
    "#{name.upcase}!"
  end
end

Dynamic.class_eval "def evald; 'EVALD!'; end"
Dynamic.class_eval "def evald_with_source; 'EVALD!'; end", __FILE__, __LINE__

