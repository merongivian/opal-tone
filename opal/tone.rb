require 'vendor/tone'

module Kernel
  def loop(synth)
    part_loop = Candy::PartLoop.new(synth)
    yield part_loop
    part_loop.execute
  end
end

module Candy
  class PartLoop
    def initialize(synth)
      @synth = synth
      @definitions = []
    end

    def execute
      do_execute do |time, event|
        @synth.trigger_attack_release(event.JS['note'], event.JS['duration'], time)
      end
    end

    def play(note, time, duration)
      @definitions << { note: note, time: time, duration: duration }
    end

    private

    def do_execute(&block)
      part = Tone::Part.new(@definitions) do |time, event|
        block.call(time, event)
      end

      part.start(0)
      part.loop = true

      Tone::Transport.start
    end
  end
end

class Tone
  class Part
    include Native

    alias_native :start
    native_writer :loop

    def initialize(definitions, &block)
      super `new Tone.Part(#{block.to_n}, #{definitions.to_n})`
    end
  end

  class Loop
    include Native

    alias_native :start
    alias_native :stop

    def initialize(interval, &block)
      super `new Tone.Loop(#{block.to_n}, interval)`
    end
  end

  class Transport
    def self.start(time)
      `Tone.Transport.start(time)`
    end

    def self.stop(time)
      `Tone.Transport.stop(time)`
    end
  end

  module Synth
    class Base
      include Native

      alias_native :trigger_attack_release, :triggerAttackRelease
      alias_native :trigger_attack, :triggerAttack
      alias_native :trigger_release, :triggerRelease
    end

    class Basic < Base
      def initialize
        super `new Tone.Synth().toMaster()`
      end
    end

    class AM < Base
      def initialize
        super `new Tone.AMSynth().toMaster()`
      end
    end

    class Duo < Base
      def initialize
        super `new Tone.DuoSynth().toMaster()`
      end
    end

    class FM < Base
      def initialize
        super `new Tone.FMSynth().toMaster()`
      end
    end

    class Membrane < Base
      def initialize
        super `new Tone.MembraneSynth().toMaster()`
      end
    end

    # TODO
    class Metal < Base
      def initialize
        super `new Tone.MetalSynth().toMaster()`
      end
    end

    class Mono < Base
      def initialize
        super `new Tone.MonoSynth().toMaster()`
      end
    end

    # TODO
    class Noise < Base
      def initialize
        super `new Tone.NoiseSynth().toMaster()`
      end
    end

    class Pluck < Base
      def initialize
        super `new Tone.PluckSynth().toMaster()`
      end
    end

    class Poly < Base
      def initialize
        super `new Tone.PolySynth().toMaster()`
      end
    end

    class Simple < Base
      def initialize
        super `new Tone.Synth().toMaster()`
      end
    end
  end
end

$membrane = Tone::Synth::Membrane.new
$synth = Tone::Synth::Basic.new
