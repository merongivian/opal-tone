require 'vendor/tone'

module Kernel
  def part(synth:, &block)
    the_loop = NegaSonic::LoopedEvent::Part.new(synth)
    the_loop.instance_eval(&block)
    the_loop.start
  end

  def sequence(synth:, interval: , &block)
    the_loop = NegaSonic::LoopedEvent::Sequence.new(synth)
    the_loop.instance_eval(&block)
    the_loop.start(interval)
  end

  def pattern(instrument:, interval:, type:, notes:)
    NegaSonic::LoopedEvent::Pattern.new(instrument.synth_node, notes)
                                   .start(interval, type)
  end

  def instrument(name, synth:, &block)
    NegaSonic::Instrument.new(name, synth).tap do |instrument|
      instrument.instance_eval(&block)
      instrument.connect_nodes
    end
  end
end

module NegaSonic
  @instruments = {}

  class << self
    attr_accessor :instruments
  end

  module Nodes
    module Synth
      class << self
        def simple
          @simple ||= Tone::Synth::Simple.new
        end

        def membrane
          @membrane ||= Tone::Synth::Membrane.new
        end

        def am
          @am ||= Tone::Synth::AM.new
        end

        def fm
          @fm ||= Tone::Synth::FM.new
        end

        def duo
          @duo ||= Tone::Synth::Duo.new
        end

        def mono
          @mono ||= Tone::Synth::Mono.new
        end

        def pluck
          @pluck ||= Tone::Synth::Pluck.new
        end

        def poly
          @poly ||= Tone::Synth::Poly.new
        end
      end
    end

    module Effect
      class << self
        def vibrato
          Tone::Effect::Vibrato.new
        end

        def distortion
          Tone::Effect::Distortion.new
        end

        def chorus
          Tone::Effect::Chorus.new
        end

        def tremolo
          Tone::Effect::Tremolo.new
        end

        def feedback_delay
          Tone::Effect::FeedbackDelay.new
        end

        def freeverb
          Tone::Effect::Freeverb.new
        end

        def jc_reverb
          Tone::Effect::JCReverb.new
        end

        def phaser
          Tone::Effect::Phaser.new
        end

        def ping_pong_delay
          Tone::Effect::PingPongDelay.new
        end
      end
    end
  end

  class Instrument
    attr_reader :synth_node

    def initialize(name, synth_type)
      @name = name
      @synth_type = synth_type
      @effects = Effects.new

      @nodes_names = []
    end

    def effects(&block)
      @effects.instance_eval(&block)
    end

    def connect_nodes
      @synth_node = Nodes::Synth.send(@synth_type)
      @nodes_names = [@synth_type, @effects.nodes_names].flatten

      previous_instrument_nodes = NegaSonic.instruments[@name]

      if !previous_instrument_nodes || previous_instrument_nodes != @nodes_names
        @synth_node.chain(*@effects.nodes)
        NegaSonic.instruments[@name] = @nodes_names
      end
    end
  end

  class Effects
    attr_reader :nodes_names

    def initialize
      @nodes_names = []
    end

    def nodes
      @nodes_names.map do |node_name|
        Nodes::Effect.send(node_name)
      end
    end

    def vibrato
      @nodes_names << :vibrato
    end

    def distortion
      @nodes_names << :distortion
    end

    def chorus
      @nodes_names << :chorus
    end

    def tremolo
      @nodes_names << :tremolo
    end

    def feedback_delay
      @nodes_names << :feedback_delay
    end

    def freeverb
      @nodes_names << :freeverb
    end

    def jc_reverb
      @nodes_names << :jc_reverb
    end

    def phaser
      @nodes_names << :phaser
    end

    def ping_pong_delay
      @nodes_names << :ping_pong_delay
    end
  end

  module LoopedEvent
    @events = []

    class << self
      attr_accessor :events

      def dispose_all
        @events.each(&:dispose)
        @events = []
      end

      def start(looped_element)
        looped_element.start(0)
        looped_element.loop = true
        @events << looped_element
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
        LoopedEvent.start(Tone::Event::Part.new @definitions, &block)
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
        LoopedEvent.start(Tone::Event::Sequence.new @segments, duration, &block)
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
        LoopedEvent.start(pattern)
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

      def cancel
        `Tone.Transport.cancel()`
      end
    end
  end

  module Effect
    class Base
      include Native

      alias_native :dispose
      alias_native :connect
      alias_native :to_master
    end

    class Chorus < Base
      def initialize(frequency: 1.5, delay_time: 3.5, depth: 0.7)
        super `new Tone.Chorus(frequency, delay_time, depth)`
      end
    end

    class Vibrato < Base
      def initialize(frequency: 5, depth: 0.1)
        super `new Tone.Vibrato(frequency, depth)`
      end
    end

    class Distortion < Base
      def initialize(value: 0.4)
        super `new Tone.Distortion(value)`
      end
    end

    class Tremolo < Base
      def initialize(frequency: 10, depth: 0.5)
        super `new Tone.Tremolo(frequency, depth)`
      end
    end

    class FeedbackDelay < Base
      def initialize(delay_time: 0.25, feedback: 0.5)
        super `new Tone.FeedbackDelay(delay_time, feedback)`
      end
    end

    class Freeverb < Base
      def initialize(room_size: 0.7, dampening: 3000)
        super `new Tone.Freeverb(room_size, dampening)`
      end
    end

    class JCReverb < Base
      def initialize(room_size: 0.5)
        super `new Tone.JCReverb(room_size)`
      end
    end

    class Phaser < Base
      def initialize(frequency: 0.5, octaves: 3, base_frequency: 350)
        super `new Tone.Phaser(frequency, octaves, base_frequency)`
      end
    end

    class PingPongDelay < Base
      def initialize(delay_time: 0.25, feedback: 1)
        super `new Tone.PingPongDelay(delay_time, feedback)`
      end
    end
  end

  module Synth
    class Base
      include Native

      alias_native :volume
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

