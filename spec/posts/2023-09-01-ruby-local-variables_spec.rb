RSpec.describe "POST: Is it possible to conditionally define a local variable in Ruby?" do
  specify do
    if true
      x = 42
    end
    expect(x).to eq(42)
  end

  specify do
    if false
      x = 42
    end
    expect(x).to eq(nil)
  end

  specify do
    if false
      eval("x = 42")
    end
    expect { x }.to raise_error(NameError, /undefined local variable or method `x'/)
  end

  specify do
    if true
      eval("x = 42")
    end
    expect { x }.to raise_error(NameError, /undefined local variable or method `x'/)
  end

  specify do
    if false
      binding.local_variable_set(:x, 42)
    end
    expect { x }.to raise_error(NameError, /undefined local variable or method `x'/)
  end

  specify do
    if true
      binding.local_variable_set(:x, 42)
    end
    expect { x }.to raise_error(NameError, /undefined local variable or method `x'/)
  end

  specify do
    if defined?(x)
      x = true
    end
    expect(x).to eq(nil)
  end

  specify do
    x = true if defined?(x)
    expect(x).to eq(true)
  end

  specify do
    expect(RubyVM::InstructionSequence.compile("if defined?(x); x = true; end").disasm).to eq(<<~ASM)
      == disasm: #<ISeq:<compiled>@<compiled>:1 (1,0)-(1,29)> (catch: false)
      local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
      [ 1] x@0
      0000 putself                                                          (   1)[Li]
      0001 defined                                func, :x, true
      0005 branchunless                           13
      0007 putobject                              true
      0009 dup
      0010 setlocal_WC_0                          x@0
      0012 leave
      0013 putnil
      0014 leave
    ASM
  end

  specify do
    expect(RubyVM::InstructionSequence.compile("x = true if defined?(x)").disasm).to eq(<<~ASM)
      == disasm: #<ISeq:<compiled>@<compiled>:1 (1,0)-(1,23)> (catch: false)
      local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
      [ 1] x@0
      0000 putobject                              true                      (   1)[Li]
      0002 branchunless                           10
      0004 putobject                              true
      0006 dup
      0007 setlocal_WC_0                          x@0
      0009 leave
      0010 putnil
      0011 leave
    ASM
  end
end
