require 'vendor/tone'

module Kernel
  def part(synth: :simple)
    the_loop = Candy::Looped::Part.new(Kernel.send(synth))
    yield the_loop
    the_loop.start
  end

  def sequence(synth: :simple, duration: )
    the_loop = Candy::Looped::Sequence.new(Kernel.send(synth))
    yield the_loop
    the_loop.start(duration)
  end

  def simple
    Tone::Synth::Simple.new
  end

  def membrane
    Tone::Synth::Membrane.new
  end

  def am
    Tone::Synth::AM.new
  end

  def fm
    Tone::Synth::FM.new
  end

  def duo
    Tone::Synth::Duo.new
  end

  def mono
    Tone::Synth::Mono.new
  end

  def pluck
    Tone::Synth::Pluck.new
  end

  def poly
    Tone::Synth::Poly.new
  end
end

module Candy
  module Looped
    def self.start(looped_element)
      looped_element.start(0)
      looped_element.loop = true

      Tone::Transport.start
    end

    class Part
      def initialize(synth)
        @synth = synth
        @definitions = []
      end

      def start
        do_start do |time, event|
          @synth.trigger_attack_release(event.JS['note'], event.JS['duration'], time)
        end
      end

      def play(note, time, duration)
        @definitions << { note: note, time: time, duration: duration }
      end

      private

      def do_start(&block)
        Looped.start(Tone::Part.new @definitions, &block)
      end
    end

    class Sequence
      def initialize(synth, segments = [])
        @synth = synth
        @segments = segments
      end

      def start(duration)
        do_start(duration) do |time, note|
          @synth.trigger_attack_release(note, duration, time)
        end
      end

      def play(*notes)
        @segments << notes
      end

      private

      def do_start(duration, &block)
        Looped.start(Tone::Sequence.new @segments, duration, &block)
      end
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

  class Sequence
    include Native

    alias_native :start
    native_writer :loop

    def initialize(segments, duration, &block)
      super `new Tone.Sequence(#{block.to_n}, #{segments.to_n}, duration)`
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

