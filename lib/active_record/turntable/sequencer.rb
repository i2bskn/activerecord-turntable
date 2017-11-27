# -*- coding: utf-8 -*-
#
# 採番
#

module ActiveRecord::Turntable
  class Sequencer
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Api
      autoload :Mysql
      autoload :Barrage
    end

    class_attribute :sequence_types
    class_attribute :sequences
    class_attribute :tables

    self.sequence_types = {
      api: Api,
      mysql: Mysql,
      barrage: Barrage,
    }
    self.sequences = {}
    self.tables = {}

    def sequence_name(table_name, primary_key = 'id')
      [table_name, primary_key, "seq"].join("_")
    end

    def release!
      # Release subclasses if necessary
    end

    class << self
      def build(klass, sequence_name = nil, cluster_name = nil)
        sequence_name ||= current_cluster_config_for(cluster_name || klass).sequencers.first
        seq_config = current_cluster_config_for(cluster_name || klass)[:seq][sequence_name]
        seq_type = (seq_config[:seq_type] ? seq_config[:seq_type].to_sym : :mysql)
        tables[klass.table_name] ||= (sequences[sequence_name(klass.table_name, klass.primary_key)] ||= sequence_types[seq_type].new(klass, seq_config))
      end

      def class_for(name_or_class)
        case name_or_class
        when Sequencer
          name_or_class
        else
          const_get("#{name_or_class.to_s.classify}")
        end
      end

      def has_sequencer?(table_name)
        !!tables[table_name]
      end

      def sequence_name(table_name, primary_key = 'id')
        [table_name, primary_key, "seq"].join("_")
      end

      def table_name(seq_name)
        seq_name.split("_").first
      end

      private

        def current_cluster_config_for(klass_or_name)
          cluster_name = if klass_or_name.is_a?(Symbol)
                           klass_or_name
                         else
                           klass_or_name.turntable_cluster_name.to_s
                         end
          ActiveRecord::Base.turntable_configuration.cluster(cluster_name)
        end
    end

    def next_sequence_value(sequence_name)
      raise NotImplementedError
    end

    def current_sequence_value(sequence_name)
      raise NotImplementedError
    end
  end
end
