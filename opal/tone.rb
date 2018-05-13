require 'vendor/tone'

module Kernel
  def part(synth: simple_synth, &block)
    the_loop = NegaSonic::Looped::Part.new(synth)
    the_loop.instance_eval(&block)
    the_loop.start
  end

  def sequence(synth: simple_synth, interval: , &block)
    the_loop = NegaSonic::Looped::Sequence.new(synth)
    the_loop.instance_eval(&block)
    the_loop.start(interval)
  end

  def pattern(synth: simple_synth, interval:, type:, notes:)
    NegaSonic::Looped::Pattern.new(synth, notes)
                              .start(interval, type)
  end

  def simple_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Simple.new, &block)
  end

  def membrane_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Membrane.new, &block)
  end

  def am_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::AM.new, &block)
  end

  def fm_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::FM.new, &block)
  end

  def duo_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Duo.new, &block)
  end

  def mono_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Mono.new, &block)
  end

  def pluck_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Pluck.new, &block)
  end

  def poly_synth(&block)
    NegaSonic::Synth.with_dsl(Tone::Synth::Poly.new, &block)
  end
end

module NegaSonic
  class Synth
    def self.with_dsl(tone_synth, &block)
      tone_synth.tap do |tone_synth|
        new(tone_synth).instance_eval(&block)
      end
    end

    def initialize(synth)
      @synth = synth
      @effects = Effects.new
    end

    def effects(&block)
      @effects.instance_eval(&block)
      @synth.chain(*@effects.list)
    end
  end

  class Effects
    attr_reader :list

    def initialize
      @list = []
    end

    def vibrato
      @list << Tone::Effect::Vibrato.new
    end

    def distortion
      @list << Tone::Effect::Distortion.new
    end
  end

  module Looped
    @events = []

    class << self
      def start_event(looped_element)
        looped_element.start(0)
        looped_element.loop = true
        @events << looped_element
      end

      def stop_all_events
        @events.each(&:dispose)
        @events = []
      end
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
        Looped.start_event(Tone::Event::Part.new @definitions, &block)
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
        Looped.start_event(Tone::Event::Sequence.new @segments, duration, &block)
      end
    end

    class Pattern
      TYPES = {
        random: 'random',
        random_walk: 'randomWalk',
        random_once: 'randomOnce',
        up: 'up',
        down: 'down',
        up_down: 'upDown',
        down_up: 'downUp',
        alternate_up: 'alternateUp',
        alternate_down: 'alternateDown'
      }

      def initialize(synth, notes = [])
        @synth = synth
        @notes = notes
      end

      def start(duration, type)
        raise 'invalid pattern type' unless TYPES.keys.include?(type)

        do_start(duration, TYPES[type]) do |time, note|
          @synth.trigger_attack_release(note, duration, time)
        end
      end

      private

      def do_start(duration, type, &block)
        pattern = Tone::Event::Pattern.new(@notes, type, &block)
        pattern.interval = duration
        Looped.start_event(pattern)
      end
    end
  end
end

class Tone
  module Event
    class Base
      include Native

      alias_native :start
      alias_native :dispose
      native_writer :loop
    end

    class Pattern < Base
      native_writer :interval

      def initialize(notes, type, &block)
        super `new Tone.Pattern(#{block.to_n}, #{notes.to_n}, type)`
      end
    end

    class Part < Base
      def initialize(definitions, &block)
        super `new Tone.Part(#{block.to_n}, #{definitions.to_n})`
      end
    end

    class Sequence < Base
      def initialize(segments, duration, &block)
        super `new Tone.Sequence(#{block.to_n}, #{segments.to_n}, duration)`
      end
    end

    class Loop < Base
      def initialize(interval, &block)
        super `new Tone.Loop(#{block.to_n}, interval)`
      end
    end
  end

  class Transport
    class << self
      def start(time = nil)
        if time
          `Tone.Transport.start(time)`
        else
          `Tone.Transport.start()`
        end
      end

      def stop(time = nil)
        if time
          `Tone.Transport.stop(time)`
        else
          `Tone.Transport.stop()`
        end
      end
    end
  end

  module Effect
    class Base
      include Native

      alias_native :connect
      alias_native :to_master
    end

    class Chorus < Base
      def initialize
        super `new Tone.Chorus()`
      end
    end

    class Vibrato < Base
      def initialize
        super `new Tone.Vibrato()`
      end
    end

    class Distortion < Base
      def initialize
        super `new Tone.Distortion(0.8)`
      end
    end
  end

  module Synth
    class Base
      include Native

      alias_native :connect
      alias_native :trigger_attack_release, :triggerAttackRelease
      alias_native :trigger_attack, :triggerAttack
      alias_native :trigger_release, :triggerRelease

      def chain(*effects)
        last_node_connected = self

        effects.each do |effect|
          last_node_connected.connect(effect.to_n)
          last_node_connected = effect
        end

        last_node_connected.connect(`Tone.Master`)
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

