require 'spec_helper'
require 'string/indent'

#----------------------------------------------------------------

def check_emit(line)
  out = mock("output stream")
  out.should_receive(:puts).with(line)
      
  e = StringUtils::Emitter.new(out)
  e.emit(line)
end    

#----------------------------------------------------------------

module IndentSpec
  describe StringUtils::Emitter do
    it "should emit strings verbatim" do
      check_emit('abcd def')
      check_emit('       	slkdj sld ksj ldksl d\nslkdflskjsdf\nsdljfksj\n')
    end

    it "should increase the whitespace prefix if #indent is called" do
      line = "sldkjfs slkdf sl l"

      out = mock('output stream')

      e = StringUtils::Emitter.new(out, 2)
      e.indent do
        out.should_receive(:puts).with("  #{line}")
        e.emit(line)

        out.should_receive(:puts).with("    #{line}")
        e.indent do
          e.emit(line)

          out.should_receive(:puts).with("      #{line}")
          e.indent {e.emit(line)}

          out.should_receive(:puts).with("    #{line}")
          e.emit(line)
        end
        out.should_receive(:puts).with("  #{line}")
        e.emit(line)
      end
      out.should_receive(:puts).with(line)
      e.emit(line)
    end

    it "should decrease the whitespace prefix if #undent is called" do
      line = "lksjd flskd lfs dls lkdjsl"
      
      out = mock('output stream')

      e = StringUtils::Emitter.new(out, 2)
      e.indent do
        e.indent do
          e.indent do
            e.undent do
              e.undent do
                out.should_receive(:puts).with("  #{line}")
                e.emit(line)
              end
            end
            out.should_receive(:puts).with("      #{line}")
            e.emit(line)
          end
        end
      end
      out.should_receive(:puts).with(line)
      e.emit(line)
    end

    it "should raise an exception if undent is called too many times" do
      line = "lksjd flskd lfs dls lkdjsl"
      
      out = mock('output stream')

      e = StringUtils::Emitter.new(out, 2)
      e.indent do
        e.indent do
          e.indent do
            e.undent do
              e.undent do
                e.undent do
                  expect do
                    e.undent {}
                  end.to raise_error(RuntimeError, /undent called too often/)
                end
              end
            end
          end
        end
      end
    end

    it "should allow different amount of whitespace per indentation step" do
      line = "sldkjfs slkdf sl l"

      out = mock('output stream')

      e = StringUtils::Emitter.new(out, 3)
      e.indent do
        out.should_receive(:puts).with("   #{line}")
        e.emit(line)

        out.should_receive(:puts).with("      #{line}")
        e.indent do
          e.emit(line)

          out.should_receive(:puts).with("         #{line}")
          e.indent {e.emit(line)}

          out.should_receive(:puts).with("      #{line}")
          e.emit(line)
        end
        out.should_receive(:puts).with("   #{line}")
        e.emit(line)
      end
      out.should_receive(:puts).with(line)
      e.emit(line)
    end
  end
end
